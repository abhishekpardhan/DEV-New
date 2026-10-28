/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : Freshservice_UtilClass
 * Author          : <Rishank Bhardwaj>
 * Created Date    : Jul 2, 2026
 * Last Modified By: <Rishank Bhardwaj>
 * Last Modified On: Jul 7, 2026
 * Description     : This class implements Freshservice ticket creation entry point
 *                   from Salesforce LWC and prevents duplicate/running API requests
 *                   using API_Logger__c request hash, similar to OTRS.
 *
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jul 2, 2026  │ <YourName>   │ Initial version
 *  Jul 3, 2026  │ <YourName>   │ Added API hash/running protection before Queueable enqueue
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
public with sharing class Freshservice_UtilClass {

    public static Boolean skipFreshserviceCaseSync = false;
    public static Boolean allowFreshserviceCaseClosure = false;

    // Create Freshservice ticket request.
    @AuraEnabled
    public static String createFreshserviceTicket(Id recordId) {
        ReturnInfo returnInfo = new ReturnInfo();

        try {
            if (recordId == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Case Id';
                return JSON.serialize(returnInfo);
            }

            Case cseObj = getCaseForFreshservice(recordId);

            if (cseObj == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Case Id';
                return JSON.serialize(returnInfo);
            }

            // if (String.isNotBlank(cseObj.Fresh_Service_Ticket_No__c)) {
            //     returnInfo.message = 'This Case is already sent to Freshservice System. Ticket Number is ' + cseObj.Fresh_Service_Ticket_No__c;
            //     return JSON.serialize(returnInfo);
            // }
            if (String.isNotBlank(cseObj.Fresh_Service_Ticket_No__c)) {
                returnInfo.type = 'SKIP';
                return JSON.serialize(returnInfo);
            }

            Boolean isPostDeliveryEscalation = FreshserviceHelper.isPostDeliveryEscalationCase(cseObj);
            String requestBody = FreshserviceHelper.buildServiceCatalogBody(isPostDeliveryEscalation ? FreshserviceQueueable.buildPostDeliveryEscalationRequest(cseObj) : FreshserviceQueueable.buildWaybillEscalationRequest(cseObj));

            API_Logger__c apiLogger = new API_Logger__c(Request_Hash__c = LoggerUtil.createFreshserviceRequestHash(requestBody));

            LoggerUtil.createOrUpdateAPILog(
                apiLogger,
                true,
                isPostDeliveryEscalation ? 'Freshservice Post Delivery Escalation' : 'Freshservice Waybill Escalation',
                isPostDeliveryEscalation ? '/api/v2/service_catalog/items/258/place_request' : '/api/v2/service_catalog/items/242/place_request',
                requestBody,
                null,
                null
            );

            if (String.isBlank(apiLogger.Request_Hash__c)) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Freshservice request hash could not be generated.';
                return JSON.serialize(returnInfo);
            }

            if ([SELECT COUNT() FROM API_Logger__c WHERE Request_Hash__c = :apiLogger.Request_Hash__c AND CreatedDate = TODAY] == 1) {
                System.enqueueJob(new FreshserviceQueueable(new Set<Id>{recordId}, apiLogger.Id));
                returnInfo.type = 'SUCCESS';
                return JSON.serialize(returnInfo);
            }

            returnInfo.type = 'ERROR';
            returnInfo.message = 'Please wait, Freshservice API is running';
            return JSON.serialize(returnInfo);

        } catch (Exception exp) {
            returnInfo.type = 'ERROR';
            returnInfo.message = exp.getMessage();
            logError('createFreshserviceTicket', exp, null);
            return JSON.serialize(returnInfo);
        }
    }

    // Sync Case changes to Freshservice.
    public static void syncMappedCaseUpdatesToFreshservice(List<Case> newList, Map<Id, Case> oldMap) {
        if (skipFreshserviceCaseSync || newList == null || newList.isEmpty()) {
            return;
        }

        Map<Id, String> caseIdToUpdateBody = new Map<Id, String>();
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

        for (Case newCase : newList) {
            try {
                if (newCase == null || newCase.Id == null || String.isBlank(newCase.Fresh_Service_Ticket_No__c)) {
                    continue;
                }

                String updateBody = FreshserviceHelper.buildTicketUpdateBody(newCase, oldMap == null ? null : oldMap.get(newCase.Id));

                if (String.isNotBlank(updateBody)) {
                    caseIdToUpdateBody.put(newCase.Id, updateBody);
                }

            } catch (Exception exp) {
                errorLogs.add(LoggerUtil.buildErrorLog(
                    'Freshservice_UtilClass',
                    'syncMappedCaseUpdatesToFreshservice',
                    exp.getTypeName(),
                    exp.getMessage(),
                    exp.getStackTraceString(),
                    newCase == null ? null : String.valueOf(newCase.Id)
                ));
            }
        }

        saveErrorLogs(errorLogs);

        if (!caseIdToUpdateBody.isEmpty()) {
            System.enqueueJob(new FreshserviceQueueable(caseIdToUpdateBody));
        }
    }

    // Fetch Freshservice ticket details.
    @AuraEnabled
    public static String getFreshserviceTicketDetails(Id recordId) {
        ReturnInfo returnInfo = new ReturnInfo();

        try {
            if (recordId == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Case Id';
                return JSON.serialize(returnInfo);
            }

            Case cseObj = getCaseForFreshserviceStatus(recordId);

            if (cseObj == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Case Id';
                return JSON.serialize(returnInfo);
            }

            if (String.isBlank(cseObj.Fresh_Service_Ticket_No__c)) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Freshservice Ticket Not Found On Case';
                return JSON.serialize(returnInfo);
            }

            Long ticketId = FreshserviceHelper.extractTicketIdFromFormattedValue(cseObj.Fresh_Service_Ticket_No__c);

            if (ticketId == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Freshservice Ticket Number: ' + cseObj.Fresh_Service_Ticket_No__c;
                return JSON.serialize(returnInfo);
            }

            FreshserviceWrapper.CreateTicketResponse fsResponse = FreshserviceHelper.getTicket(ticketId);

            if (fsResponse == null || fsResponse.ticket == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Freshservice ticket detail not found.';
                return JSON.serialize(returnInfo);
            }

            Map<String, Object> ticketDetail = buildFreshserviceTicketDetail(fsResponse.ticket, cseObj);
            ticketDetail.put('Articles', fsResponse.articles);

            returnInfo.type = 'SUCCESS';
            returnInfo.message = JSON.serialize(new Map<String, Object>{
                'message' => 'success',
                'response' => new Map<String, Object>{'TicketDetail' => ticketDetail}
            });

            return JSON.serialize(returnInfo);

        } catch (Exception exp) {
            returnInfo.type = 'ERROR';
            returnInfo.message = exp.getMessage();
            logError('getFreshserviceTicketDetails', exp, null);
            return JSON.serialize(returnInfo);
        }
    }

    // Update Case Freshservice status.
    @AuraEnabled
    public static String updateFreshserviceStatus(String freshserviceStatus, Id recordId) {
        ReturnInfo returnInfo = new ReturnInfo();

        try {
            if (recordId == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Case Id';
                return JSON.serialize(returnInfo);
            }

            Case cseObj = getCaseForFreshserviceStatus(recordId);

            if (cseObj == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Case Id';
                return JSON.serialize(returnInfo);
            }

            String caseFreshserviceStatus = String.isNotBlank(freshserviceStatus) && freshserviceStatus.toLowerCase().contains('closed') ? 'Closed' : 'Open';
            Case caseToUpdate = new Case(Id = recordId, OTRS_Request_Status__c = caseFreshserviceStatus);
            caseToUpdate.Status = caseFreshserviceStatus == 'Closed' ? ConstantUtility.COMPLETED : 'Open';

            try {
                skipFreshserviceCaseSync = true;
                allowFreshserviceCaseClosure = true;
                TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
                update caseToUpdate;
            } finally {
                TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);
                skipFreshserviceCaseSync = false;
                allowFreshserviceCaseClosure = false;
            }

            returnInfo.type = 'SUCCESS';
            returnInfo.message = 'SUCCESS';
            return JSON.serialize(returnInfo);

        } catch (Exception exp) {
            returnInfo.type = 'ERROR';
            returnInfo.message = exp.getMessage();
            logError('updateFreshserviceStatus', exp, null);
            return JSON.serialize(returnInfo);
        }
    }

    // Create Freshservice ticket reply.
    @AuraEnabled
    public static String createFreshserviceReply(String ticketNumber, Id recordId, String body) {
        ReturnInfo returnInfo = new ReturnInfo();

        try {
            if (recordId == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Case Id';
                return JSON.serialize(returnInfo);
            }

            if (String.isBlank(body)) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Comment cannot be blank.';
                return JSON.serialize(returnInfo);
            }

            Case cseObj = getCaseForFreshserviceStatus(recordId);

            if (cseObj == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Case Id';
                return JSON.serialize(returnInfo);
            }

            String finalTicketNumber = String.isNotBlank(ticketNumber) ? ticketNumber : cseObj.Fresh_Service_Ticket_No__c;

            if (String.isBlank(finalTicketNumber)) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Freshservice Ticket Not Found On Case';
                return JSON.serialize(returnInfo);
            }

            Long ticketId = FreshserviceHelper.extractTicketIdFromFormattedValue(finalTicketNumber);

            if (ticketId == null) {
                returnInfo.type = 'ERROR';
                returnInfo.message = 'Invalid Freshservice Ticket Number: ' + finalTicketNumber;
                return JSON.serialize(returnInfo);
            }

            Map<String, Object> articleObj = FreshserviceHelper.createReplyAsArticle(ticketId, body);

            returnInfo.type = 'SUCCESS';
            returnInfo.message = JSON.serialize(new Map<String, Object>{
                'message' => 'success',
                'response' => new Map<String, Object>{
                    'Article' => articleObj,
                    'ArticleID' => articleObj.get('ArticleId')
                }
            });

            return JSON.serialize(returnInfo);

        } catch (Exception exp) {
            returnInfo.type = 'ERROR';
            returnInfo.message = exp.getMessage();
            logError('createFreshserviceReply', exp, null);
            return JSON.serialize(returnInfo);
        }
    }

    // Fetch Case creation fields.
    private static Case getCaseForFreshservice(Id recordId) {
        List<Case> caseList = [SELECT Id, Subject, ContactEmail, Fresh_Service_Ticket_No__c, Service_Region__c, OTRS_Remarks__c, WaybillNo__c, Sub_Type__c, CaseNumber
                               FROM Case WHERE Id = :recordId LIMIT 1];

        return caseList.isEmpty() ? null : caseList[0];
    }

    // Fetch Case status fields.
    private static Case getCaseForFreshserviceStatus(Id recordId) {
        List<Case> caseList = [SELECT Id, Subject, SuppliedEmail, SuppliedPhone, ContactEmail, Contact.Email, Contact.Phone, Contact.MobilePhone, Owner.Name, CreatedDate, CaseNumber, LastModifiedDate, Fresh_Service_Ticket_No__c, Case_Type__c, Main_Category__c, Sub_Category__c, Issue_Type__c, Service_Region__c, Sub_Type__c
                               FROM Case WHERE Id = :recordId LIMIT 1];

        return caseList.isEmpty() ? null : caseList[0];
    }

    // Build modal ticket payload.
    private static Map<String, Object> buildFreshserviceTicketDetail(FreshserviceWrapper.Ticket ticket, Case cseObj) {
        Map<String, Object> ticketDetail = new Map<String, Object>();
        String customerEmail = firstNotBlank(new List<String>{cseObj.ContactEmail, cseObj.SuppliedEmail, cseObj.Contact == null ? null : cseObj.Contact.Email});

        ticketDetail.put('tnumber', ticket.id == null ? cseObj.Fresh_Service_Ticket_No__c : 'FSC-' + String.valueOf(ticket.id));
        ticketDetail.put('title', firstNotBlank(new List<String>{cseObj.Subject, ticket.subject}));
        ticketDetail.put('queue', firstNotBlank(new List<String>{getTicketCustomFieldValue(ticket, 'group_name'), 'Freshservice'}));
        ticketDetail.put('type', firstNotBlank(new List<String>{cseObj.Case_Type__c, ticket.type}));
        ticketDetail.put('state', getFreshserviceStatusLabel(ticket.status));
        ticketDetail.put('priority', getFreshservicePriorityLabel(ticket.priority));
        ticketDetail.put('CreatedForCustomer', customerEmail);
        ticketDetail.put('CreatedByCustomer', customerEmail);
        ticketDetail.put('CustomerEmail', customerEmail);
        ticketDetail.put('MainCategory', cseObj.Main_Category__c);
        ticketDetail.put('SubCategory', firstNotBlank(new List<String>{cseObj.Sub_Category__c, cseObj.Sub_Type__c}));
        ticketDetail.put('IssueType', cseObj.Issue_Type__c);
        ticketDetail.put('AltPhone', firstNotBlank(new List<String>{cseObj.Contact == null ? null : cseObj.Contact.MobilePhone, cseObj.Contact == null ? null : cseObj.Contact.Phone, cseObj.SuppliedPhone}));
        ticketDetail.put('Region', firstNotBlank(new List<String>{cseObj.Service_Region__c, getTicketCustomFieldValue(ticket, 'sr_service_region'), getTicketCustomFieldValue(ticket, 'service_region')}));
        ticketDetail.put('Impact', firstNotBlank(new List<String>{getTicketCustomFieldValue(ticket, 'impact'), 'High'}));
        ticketDetail.put('Owner', firstNotBlank(new List<String>{getTicketCustomFieldValue(ticket, 'agent_name'), cseObj.Owner == null ? null : cseObj.Owner.Name}));
        ticketDetail.put('CreateTime', formatDateTimeForDisplay(cseObj.CreatedDate));
        ticketDetail.put('ModifiedTime', formatDateTimeForDisplay(cseObj.LastModifiedDate));

        return ticketDetail;
    }

    // Return first populated value.
    private static String firstNotBlank(List<String> values) {
        if (values == null) {
            return '';
        }

        for (String value : values) {
            if (String.isNotBlank(value)) {
                return value;
            }
        }

        return '';
    }

    // Read Freshservice custom field.
    private static String getTicketCustomFieldValue(FreshserviceWrapper.Ticket ticket, String fieldName) {
        if (ticket == null || ticket.custom_fields == null || String.isBlank(fieldName) || !ticket.custom_fields.containsKey(fieldName)) {
            return '';
        }

        Object value = ticket.custom_fields.get(fieldName);
        return value == null ? '' : String.valueOf(value);
    }

    // Format datetime for UI.
    private static String formatDateTimeForDisplay(Datetime value) {
        return value == null ? '' : value.format('dd/MM/yyyy, h:mm a');
    }

    // Convert status code label.
    private static String getFreshserviceStatusLabel(Integer statusCode) {
        if (statusCode == null || statusCode == 2) {
            return 'Open';
        }

        if (statusCode == 3) {
            return 'Pending';
        }

        if (statusCode == 4) {
            return 'Resolved';
        }

        if (statusCode == 5) {
            return 'Closed';
        }

        return String.valueOf(statusCode);
    }

    // Convert priority code label.
    private static String getFreshservicePriorityLabel(Integer priorityCode) {
        if (priorityCode == null) {
            return '';
        }

        if (priorityCode == 1) {
            return 'Low';
        }

        if (priorityCode == 2) {
            return 'Medium';
        }

        if (priorityCode == 3) {
            return 'High';
        }

        if (priorityCode == 4) {
            return 'Urgent';
        }

        return String.valueOf(priorityCode);
    }

    // Save collected error logs.
    private static void saveErrorLogs(List<Error_Log__c> errorLogs) {
        if (errorLogs == null || errorLogs.isEmpty()) {
            return;
        }

        try {
            LoggerUtil.createErrorLogs(errorLogs);
        } catch (Exception logExp) {
            // Ignore logging failure.
        }
    }

    // Log Freshservice utility error.
    private static void logError(String methodName, Exception exp, String recordId) {
        try {
            LoggerUtil.createErrorLog('Freshservice_UtilClass', methodName, exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), recordId);
        } catch (Exception logExp) {
            // Ignore logging failure.
        }
    }

    // Wrap LWC response data.
    public class ReturnInfo {
        @AuraEnabled public String type = 'ERROR';
        @AuraEnabled public String message;
    }
}