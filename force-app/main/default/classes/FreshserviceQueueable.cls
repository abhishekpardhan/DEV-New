public without sharing class FreshserviceQueueable implements Queueable, Database.AllowsCallouts {

    private static final Integer CREATE_MODE_CHUNK_SIZE = 40;
    private static final Integer UPDATE_MODE_CHUNK_SIZE = 80;
    private static final Integer MAX_RETRY_ATTEMPT = 2;

    private Set<Id> caseIds = new Set<Id>();
    private Id loggerId;
    private Boolean isUpdateMode = false;
    private Boolean isCaseLinkMode = false;
    private Map<Id, String> caseIdToUpdateBody = new Map<Id, String>();
    private Set<Id> deferredCreateRetryIds = new Set<Id>();
    private Map<Id, String> deferredUpdateRetryMap = new Map<Id, String>();
    private Map<Id, String> caseIdToTicketNumber = new Map<Id, String>();
    private Integer retryAttempt = 0;

    // Initialize create mode queue.
    public FreshserviceQueueable(Set<Id> caseIds) {
        this(caseIds, null, 0);
    }

    // Initialize create with logger.
    public FreshserviceQueueable(Set<Id> caseIds, Id loggerId) {
        this(caseIds, loggerId, 0);
    }

    // Initialize create with retry.
    public FreshserviceQueueable(Set<Id> caseIds, Id loggerId, Integer retryAttempt) {
        this.caseIds = caseIds == null ? new Set<Id>() : new Set<Id>(caseIds);
        this.loggerId = loggerId;
        this.retryAttempt = retryAttempt == null ? 0 : retryAttempt;
    }

    // Initialize create chain.
    private FreshserviceQueueable(Set<Id> caseIds, Id loggerId, Integer retryAttempt, Set<Id> deferredCreateRetryIds, Map<Id, String> caseIdToTicketNumber) {
        this.caseIds = caseIds == null ? new Set<Id>() : new Set<Id>(caseIds);
        this.loggerId = loggerId;
        this.retryAttempt = retryAttempt == null ? 0 : retryAttempt;
        this.deferredCreateRetryIds = deferredCreateRetryIds == null ? new Set<Id>() : new Set<Id>(deferredCreateRetryIds);
        this.caseIdToTicketNumber = caseIdToTicketNumber == null ? new Map<Id, String>() : new Map<Id, String>(caseIdToTicketNumber);
    }

    // Initialize update mode queue.
    public FreshserviceQueueable(Map<Id, String> caseIdToUpdateBody) {
        this(caseIdToUpdateBody, 0);
    }

    // Initialize update with retry.
    public FreshserviceQueueable(Map<Id, String> caseIdToUpdateBody, Integer retryAttempt) {
        this.caseIdToUpdateBody = caseIdToUpdateBody == null ? new Map<Id, String>() : new Map<Id, String>(caseIdToUpdateBody);
        this.isUpdateMode = true;
        this.retryAttempt = retryAttempt == null ? 0 : retryAttempt;
    }

    // Initialize update chain.
    private FreshserviceQueueable(Map<Id, String> caseIdToUpdateBody, Integer retryAttempt, Map<Id, String> deferredUpdateRetryMap) {
        this.caseIdToUpdateBody = caseIdToUpdateBody == null ? new Map<Id, String>() : new Map<Id, String>(caseIdToUpdateBody);
        this.deferredUpdateRetryMap = deferredUpdateRetryMap == null ? new Map<Id, String>() : new Map<Id, String>(deferredUpdateRetryMap);
        this.isUpdateMode = true;
        this.retryAttempt = retryAttempt == null ? 0 : retryAttempt;
    }

    // Initialize Case link retry.
    private FreshserviceQueueable(Map<Id, String> caseIdToTicketNumber, Integer retryAttempt, Boolean isCaseLinkMode) {
        this.caseIdToTicketNumber = caseIdToTicketNumber == null ? new Map<Id, String>() : new Map<Id, String>(caseIdToTicketNumber);
        this.isCaseLinkMode = isCaseLinkMode;
        this.retryAttempt = retryAttempt == null ? 0 : retryAttempt;
    }

    // Execute queueable process.
    public void execute(QueueableContext context) {
        if (isCaseLinkMode) {
            retryCaseTicketUpdates();
            return;
        }

        if (isUpdateMode) {
            if (!caseIdToUpdateBody.isEmpty()) {
                updateFreshserviceTickets();
            }
            return;
        }

        if (!caseIds.isEmpty()) {
            createFreshserviceTickets();
        }
    }

    // Create Freshservice tickets.
    private void createFreshserviceTickets() {
        Set<Id> currentCaseIds = getCurrentCaseIds(CREATE_MODE_CHUNK_SIZE);
        Set<Id> remainingCaseIds = getRemainingCaseIds(currentCaseIds);
        Set<Id> retryableCaseIds = new Set<Id>(deferredCreateRetryIds);
        Map<Id, String> createdTicketNumbers = new Map<Id, String>();
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

        List<Case> caseList = [
            SELECT Id, CaseNumber, Subject, ContactEmail, Fresh_Service_Ticket_No__c, Service_Region__c,
                   OTRS_Remarks__c, WaybillNo__c, Sub_Type__c
            FROM Case
            WHERE Id IN :currentCaseIds
            AND Fresh_Service_Ticket_No__c = NULL
        ];

        for (Case c : caseList) {
            try {
                if (String.isNotBlank(FreshserviceHelper.findDuplicateTicketByWaybill(c.WaybillNo__c))) {
                    continue;
                }

                String ticketNo = FreshserviceHelper.getServiceRequestNumber(
                    FreshserviceHelper.isPostDeliveryEscalationCase(c)
                        ? FreshserviceHelper.placePostDeliveryEscalationRequest(buildPostDeliveryEscalationRequest(c))
                        : FreshserviceHelper.placeWaybillEscalationRequest(buildWaybillEscalationRequest(c))
                );

                if (String.isBlank(ticketNo)) {
                    throw new CalloutException('Freshservice service request number missing.');
                }

                createdTicketNumbers.put(c.Id, ticketNo);

            } catch (Exception exp) {
                if (isRetryableException(exp) && retryAttempt < MAX_RETRY_ATTEMPT) {
                    retryableCaseIds.add(c.Id);
                } else {
                    addErrorLog(errorLogs, 'createFreshserviceTickets', exp, String.valueOf(c.Id));
                }
            }
        }

        Map<Id, String> pendingCaseTicketUpdates = new Map<Id, String>(caseIdToTicketNumber);
        pendingCaseTicketUpdates.putAll(saveCaseTicketUpdates(createdTicketNumbers, false, errorLogs));

        saveErrorLogs(errorLogs);
        enqueueNextCreateJobIfNeeded(remainingCaseIds, retryableCaseIds, pendingCaseTicketUpdates);
    }

    // Update Freshservice tickets.
    private void updateFreshserviceTickets() {
        Map<Id, String> currentUpdateMap = getCurrentUpdateBodyMap(UPDATE_MODE_CHUNK_SIZE);
        Map<Id, String> remainingUpdateMap = getRemainingUpdateBodyMap(currentUpdateMap.keySet());
        Map<Id, String> retryableUpdateMap = new Map<Id, String>(deferredUpdateRetryMap);
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

        Map<Id, Case> caseMap = new Map<Id, Case>([
            SELECT Id, Fresh_Service_Ticket_No__c
            FROM Case
            WHERE Id IN :currentUpdateMap.keySet()
            AND Fresh_Service_Ticket_No__c != NULL
        ]);

        for (Id caseId : currentUpdateMap.keySet()) {
            Case cseObj = caseMap.get(caseId);

            if (cseObj == null) {
                continue;
            }

            try {
                Long ticketId = FreshserviceHelper.extractTicketIdFromFormattedValue(cseObj.Fresh_Service_Ticket_No__c);
                String updateBody = currentUpdateMap.get(caseId);

                if (ticketId == null || String.isBlank(updateBody)) {
                    continue;
                }

                FreshserviceHelper.updateTicket(ticketId, updateBody);

            } catch (Exception exp) {
                if (isRetryableException(exp) && retryAttempt < MAX_RETRY_ATTEMPT) {
                    retryableUpdateMap.put(caseId, currentUpdateMap.get(caseId));
                } else {
                    addErrorLog(errorLogs, 'updateFreshserviceTickets', exp, String.valueOf(caseId));
                }
            }
        }

        saveErrorLogs(errorLogs);
        enqueueNextUpdateJobIfNeeded(remainingUpdateMap, retryableUpdateMap);
    }

    // Retry Salesforce ticket link.
    private void retryCaseTicketUpdates() {
        if (caseIdToTicketNumber.isEmpty()) {
            return;
        }

        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        Map<Id, String> failedUpdates = saveCaseTicketUpdates(caseIdToTicketNumber, retryAttempt >= MAX_RETRY_ATTEMPT, errorLogs);

        saveErrorLogs(errorLogs);

        if (!failedUpdates.isEmpty() && retryAttempt < MAX_RETRY_ATTEMPT) {
            try {
                System.enqueueJob(new FreshserviceQueueable(failedUpdates, retryAttempt + 1, true));
            } catch (Exception exp) {
                logEnqueueError('retryCaseTicketUpdates', exp);
            }
        }
    }

    // Chain next create job.
    private void enqueueNextCreateJobIfNeeded(Set<Id> remainingCaseIds, Set<Id> retryableCaseIds, Map<Id, String> pendingCaseTicketUpdates) {
        try {
            if (!remainingCaseIds.isEmpty()) {
                System.enqueueJob(new FreshserviceQueueable(remainingCaseIds, loggerId, retryAttempt, retryableCaseIds, pendingCaseTicketUpdates));
                return;
            }

            if (!retryableCaseIds.isEmpty() && retryAttempt < MAX_RETRY_ATTEMPT) {
                System.enqueueJob(new FreshserviceQueueable(retryableCaseIds, loggerId, retryAttempt + 1, new Set<Id>(), pendingCaseTicketUpdates));
                return;
            }

            if (!pendingCaseTicketUpdates.isEmpty()) {
                System.enqueueJob(new FreshserviceQueueable(pendingCaseTicketUpdates, 1, true));
            }

        } catch (Exception exp) {
            logEnqueueError('enqueueNextCreateJobIfNeeded', exp);
        }
    }

    // Chain next update job.
    private void enqueueNextUpdateJobIfNeeded(Map<Id, String> remainingUpdateMap, Map<Id, String> retryableUpdateMap) {
        try {
            if (!remainingUpdateMap.isEmpty()) {
                System.enqueueJob(new FreshserviceQueueable(remainingUpdateMap, retryAttempt, retryableUpdateMap));
                return;
            }

            if (!retryableUpdateMap.isEmpty() && retryAttempt < MAX_RETRY_ATTEMPT) {
                System.enqueueJob(new FreshserviceQueueable(retryableUpdateMap, retryAttempt + 1, new Map<Id, String>()));
            }

        } catch (Exception exp) {
            logEnqueueError('enqueueNextUpdateJobIfNeeded', exp);
        }
    }

    // Get current create chunk.
    private Set<Id> getCurrentCaseIds(Integer chunkSize) {
        Set<Id> currentIds = new Set<Id>();

        for (Id caseId : caseIds) {
            if (currentIds.size() >= chunkSize) {
                break;
            }

            currentIds.add(caseId);
        }

        return currentIds;
    }

    // Get remaining create ids.
    private Set<Id> getRemainingCaseIds(Set<Id> currentIds) {
        Set<Id> remainingIds = new Set<Id>(caseIds);
        remainingIds.removeAll(currentIds);
        return remainingIds;
    }

    // Get current update chunk.
    private Map<Id, String> getCurrentUpdateBodyMap(Integer chunkSize) {
        Map<Id, String> currentMap = new Map<Id, String>();

        for (Id caseId : caseIdToUpdateBody.keySet()) {
            if (currentMap.size() >= chunkSize) {
                break;
            }

            currentMap.put(caseId, caseIdToUpdateBody.get(caseId));
        }

        return currentMap;
    }

    // Get remaining update map.
    private Map<Id, String> getRemainingUpdateBodyMap(Set<Id> currentIds) {
        Map<Id, String> remainingMap = new Map<Id, String>(caseIdToUpdateBody);

        for (Id caseId : currentIds) {
            remainingMap.remove(caseId);
        }

        return remainingMap;
    }

    // Save Salesforce ticket links.
    private static Map<Id, String> saveCaseTicketUpdates(Map<Id, String> ticketNumbers, Boolean logFailures, List<Error_Log__c> errorLogs) {
        Map<Id, String> failedUpdates = new Map<Id, String>();

        if (ticketNumbers == null || ticketNumbers.isEmpty()) {
            return failedUpdates;
        }

        List<Case> updates = new List<Case>();
        List<Id> updateIds = new List<Id>();

        for (Id caseId : ticketNumbers.keySet()) {
            updates.add(new Case(Id = caseId, Fresh_Service_Ticket_No__c = ticketNumbers.get(caseId)));
            updateIds.add(caseId);
        }

        try {
            TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
            Database.SaveResult[] results = Database.update(updates, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    continue;
                }

                failedUpdates.put(updateIds[i], ticketNumbers.get(updateIds[i]));

                if (logFailures) {
                    errorLogs.add(
                        LoggerUtil.buildErrorLog(
                            'FreshserviceQueueable',
                            'saveCaseTicketUpdates',
                            'Database.Error',
                            getSaveResultErrorMessage(results[i]),
                            null,
                            String.valueOf(updateIds[i])
                        )
                    );
                }
            }

        } catch (Exception exp) {
            failedUpdates.putAll(ticketNumbers);

            if (logFailures) {
                addErrorLog(errorLogs, 'saveCaseTicketUpdates', exp, null);
            }

        } finally {
            TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);
        }

        return failedUpdates;
    }

    // Build DML error message.
    private static String getSaveResultErrorMessage(Database.SaveResult result) {
        List<String> messages = new List<String>();

        for (Database.Error error : result.getErrors()) {
            messages.add(String.valueOf(error.getStatusCode()) + ': ' + error.getMessage());
        }

        return String.join(messages, ' | ');
    }

    // Collect queue error log.
    private static void addErrorLog(List<Error_Log__c> errorLogs, String methodName, Exception exp, String recordId) {
        errorLogs.add(
            LoggerUtil.buildErrorLog(
                'FreshserviceQueueable',
                methodName,
                exp.getTypeName(),
                exp.getMessage(),
                exp.getStackTraceString(),
                recordId
            )
        );
    }

    // Save collected error logs.
    private static void saveErrorLogs(List<Error_Log__c> errorLogs) {
        if (errorLogs == null || errorLogs.isEmpty()) {
            return;
        }

        try {
            LoggerUtil.createErrorLogs(errorLogs);
        } catch (Exception exp) {
            // Ignore logging failure.
        }
    }

    // Log Queueable enqueue error.
    private static void logEnqueueError(String methodName, Exception exp) {
        try {
            LoggerUtil.createErrorLog('FreshserviceQueueable', methodName, exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        } catch (Exception logExp) {
            // Ignore logging failure.
        }
    }

    // Check retryable callout error.
    private static Boolean isRetryableException(Exception exp) {
        if (exp == null || String.isBlank(exp.getMessage())) {
            return false;
        }

        String message = exp.getMessage().toLowerCase();

        return message.contains('raw_status=429') ||
               message.contains('raw_status=500') ||
               message.contains('raw_status=502') ||
               message.contains('raw_status=503') ||
               message.contains('raw_status=504') ||
               message.contains('read timed out') ||
               message.contains('timeout') ||
               message.contains('callout');
    }

    // Build direct ticket request.
    public static FreshserviceWrapper.CreateTicketRequest buildCreateTicketRequest(Case c) {
        FreshserviceWrapper.CreateTicketRequest req = new FreshserviceWrapper.CreateTicketRequest();

        req.source = 10;
        req.status = 2;
        req.workspace_id = 5;
        req.priority = 2;
        //req.email = String.isNotBlank(c.SuppliedEmail) ? c.SuppliedEmail : 'rudra.singh@safexpress.com';
        req.email = String.isNotBlank(c.SuppliedEmail) ? c.SuppliedEmail : 'null';
        req.subject = String.isNotBlank(c.Subject) ? c.Subject : 'Salesforce Case - ' + String.valueOf(c.Id);
        req.description = String.isNotBlank(c.Description) ? c.Description : 'undefined description';
        req.type = String.isNotBlank(c.Case_Type__c) ? c.Case_Type__c : 'Incident';
        req.custom_fields.put('main_category', String.isNotBlank(c.Main_Category__c) ? c.Main_Category__c : 'Application Support - Propel');
        req.custom_fields.put('subcategory', String.isNotBlank(c.Sub_Type__c) ? c.Sub_Type__c : 'Undefined-subcategory');
        req.custom_fields.put('issue_type', String.isNotBlank(c.Issue_Type__c) ? c.Issue_Type__c : 'Undefined-issue_type');
        req.custom_fields.put('service_region', String.isNotBlank(c.Service_Region__c) ? c.Service_Region__c : 'Undefined-service_region');

        return req;
    }

    // Build waybill escalation request.
    public static FreshserviceWrapper.ServiceCatalogRequest buildWaybillEscalationRequest(Case c) {
        FreshserviceWrapper.ServiceCatalogRequest req = new FreshserviceWrapper.ServiceCatalogRequest();

        req.itemId = 242;
        req.email = String.isNotBlank(c.ContactEmail) ? c.ContactEmail : 'null';
        req.requested_for = 'sfdc.admin@safexpress.com';
        req.custom_fields.put('impact', 'High');
        req.custom_fields.put('service_region', String.isNotBlank(c.Service_Region__c) ? c.Service_Region__c : 'Corporate Office');
        req.custom_fields.put('waybill_number', String.isNotBlank(c.WaybillNo__c) ? c.WaybillNo__c : '');
        req.custom_fields.put('subject', String.isNotBlank(c.Subject) ? c.Subject : 'Waybill Escalation From Salesforce');
        req.custom_fields.put('remarks', String.isNotBlank(c.OTRS_Remarks__c) ? c.OTRS_Remarks__c : 'Waybill Escalation From Salesforce trigger');
        req.custom_fields.put('source', 'Service Cloud');
        req.custom_fields.put('salesforce_ticket_number', c.CaseNumber);

        return req;
    }

    // Build post delivery request.
    public static FreshserviceWrapper.ServiceCatalogRequest buildPostDeliveryEscalationRequest(Case c) {
        FreshserviceWrapper.ServiceCatalogRequest req = new FreshserviceWrapper.ServiceCatalogRequest();

        req.itemId = 258;
        req.email = String.isNotBlank(c.ContactEmail) ? c.ContactEmail : 'requester@safexpress.com';
        req.requested_for = 'sfdc.admin@safexpress.com';
        req.custom_fields.put('waybill_number', String.isNotBlank(c.WaybillNo__c) ? c.WaybillNo__c : '');
        req.custom_fields.put('remarks', String.isNotBlank(c.OTRS_Remarks__c) ? c.OTRS_Remarks__c : 'Post Delivery Escalation From Salesforce');
        req.custom_fields.put('source', 'Service Cloud');
        req.custom_fields.put('impact', 'High');
        req.custom_fields.put('salesforce_ticket_number', c.CaseNumber);
        req.custom_fields.put('service_region',
    String.isNotBlank(c.Service_Region__c)
        ? c.Service_Region__c : 'Corporate Office');

req.custom_fields.put('subject',
    String.isNotBlank(c.Subject)
        ? c.Subject : 'Post Delivery Escalation From Salesforce');

        return req;
    }
}