/**
 * @File Name          : ExternalCaseStatusQueueable.cls
 * @Description        : Generic Queueable to push Salesforce Case status updates to an external system.
 *                       Caller passes the Named Credential name, making this reusable across integrations.
 *                       Currently used by CaseTriggerHandler for Enterprise App Waybill Enquiry cases.
 * @Author             : Rudra Singh | GT Bharat
 * @Group              : Safexpress
 * @Last Modified By   : Rudra Singh
 * @Last Modified On   : 12/06/2026
 * @Modification Log   :
 *==============================================================================
 * Ver         Date            Author          Modification
 *==============================================================================
 * 1.0        12/06/2026       Rudra Singh     Initial Version
 **/
public with sharing class ExternalCaseStatusQueueable implements Queueable, Database.AllowsCallouts {

    private Map<String, String> txnToCaseMap;
    private String namedCredential;

    public ExternalCaseStatusQueueable(Map<String, String> txnToCaseMap, String namedCredential) {
        this.txnToCaseMap   = txnToCaseMap;
        this.namedCredential = namedCredential;
    }

    public void execute(QueueableContext context) {
        if (txnToCaseMap == null || txnToCaseMap.isEmpty()) {
            return;
        }

        String integrationTxnId;
        String caseId;
        for (String txnId : txnToCaseMap.keySet()) {
            integrationTxnId = txnId;
            caseId           = txnToCaseMap.get(txnId);
            break;
        }

        try {
            List<Case> cases = [
                SELECT Id, CaseNumber, Status
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            if (cases.isEmpty()) {
                LoggerUtil.createErrorLog(
                    'ExternalCaseStatusQueueable', 'execute',
                    'No Case Found', 'No Case record found for Id: ' + caseId,
                    null, caseId
                );
            } else {
                String mappedStatus = mapStatus(cases[0].Status);

                if (mappedStatus != null) {
                    CaseStatusPayload payload = new CaseStatusPayload();
                    payload.sfdcCaseNumber = cases[0].CaseNumber;
                    payload.status         = mappedStatus;
                    payload.solutionRemark = null;

                    HttpRequest req = new HttpRequest();
                    req.setEndpoint('callout:' + namedCredential);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    req.setHeader('tracker-id', cases[0].CaseNumber);
                    req.setTimeout(20000);
                    req.setBody(JSON.serialize(payload));

                    Http http = new Http();
                    HttpResponse res = http.send(req);

                    if (integrationTxnId != null) {
                        IntegrationUtility.IntegrationLog updateLog = new IntegrationUtility.IntegrationLog();
                        updateLog.recordId   = integrationTxnId;
                        updateLog.request    = req.getBody();
                        updateLog.response   = res.getBody();
                        updateLog.statusCode = res.getStatusCode();
                        IntegrationUtility.updateIntegrationTransaction(updateLog);
                    }

                    if (res.getStatusCode() != 200) {
                        LoggerUtil.createAPILog(
                            'ExternalCaseStatusQueueable',
                            'callout:' + namedCredential,
                            req.getBody(), res.getBody(), res.getStatusCode()
                        );
                    }
                }
            }
        } catch (Exception ex) {
            LoggerUtil.createErrorLog(
                'ExternalCaseStatusQueueable', 'execute',
                ex.getTypeName(), ex.getMessage(), ex.getStackTraceString(), caseId
            );
        }

        txnToCaseMap.remove(integrationTxnId);
        if (!txnToCaseMap.isEmpty()) {
            System.enqueueJob(new ExternalCaseStatusQueueable(txnToCaseMap, namedCredential));
        }
    }

    private static String mapStatus(String sfStatus) {
        switch on sfStatus {
            when 'New', 'Created'         { return 'pending'; }
            when 'In Progress'            { return 'inprogress'; }
            when 'Completed', 'Cancelled' { return 'closed'; }
            when else                     { return null; }
        }
    }

    private class CaseStatusPayload {
        public String sfdcCaseNumber;
        public String status;
        public String solutionRemark;
    }
}