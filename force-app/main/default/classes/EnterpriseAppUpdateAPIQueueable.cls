public with sharing class EnterpriseAppUpdateAPIQueueable implements Queueable, Database.AllowsCallouts {

    private Map<String, String> caseIdMap = new Map<String, String>();

    public EnterpriseAppUpdateAPIQueueable(Map<String, String> caseIdMap) {
        this.caseIdMap = caseIdMap;
    }

    public void execute(QueueableContext context) {

        if (caseIdMap == null || caseIdMap.isEmpty()) {
            return;
        }

        String currentCaseId;
        String integrationTransactionId;

        if(this.caseIdMap.size() > 0){ 
            for(String integrationId : this.caseIdMap.keySet()){
                currentCaseId = this.caseIdMap.get(integrationId);
                integrationTransactionId = integrationId;
                break;
            }
        }

        try {

            List<Case> caseRec = [
                SELECT Id, CaseNumber, Pre_Booking_Id__c, Booking_Status__c, WaybillNo__c
                FROM Case 
                WHERE Id = :currentCaseId
            ]; 

            if(caseRec.isEmpty()) {
                LoggerUtil.createErrorLog(
                    'EnterpriseAppUpdateAPIQueueable',
                    'Update Status Enterprise App',
                    'No Case Record Found',
                    'No Case record found for Id: ' + currentCaseId,
                    null,
                    currentCaseId
                );
            } else {
                DataWrapper wrapData = new DataWrapper();
                wrapData.caseNo = caseRec[0].CaseNumber;
                wrapData.reqNo = caseRec[0].Pre_Booking_Id__c;
                wrapData.status = mapStatus(caseRec[0].Booking_Status__c);
                wrapData.waybill = caseRec[0].WaybillNo__c;
    
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:Enterprise_API');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('tracker-id', caseRec[0].CaseNumber +':'+ caseRec[0].WaybillNo__c);
                req.setTimeout(20000);
                req.setBody(JSON.serialize(wrapData));
    
                Http http = new Http();
                HttpResponse res = http.send(req);
    
                System.debug('Status Code: ' + res.getStatusCode());
                System.debug(' req.getBody() >>' +  req.getBody());
                System.debug('Response: ' + res.getBody());
                if(integrationTransactionId != null){    
                    IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
                    updateITLogObject.recordId = integrationTransactionId;
                    updateITLogObject.request = req.getBody();
                    updateITLogObject.response = res.getBody(); 
                    updateITLogObject.statusCode = res.getStatusCode(); 
                    IntegrationUtility.updateIntegrationTransaction(updateITLogObject); 
                }
    
                if (res.getStatusCode() != 200) {
                    LoggerUtil.createAPILog(
                        'EnterpriseAppUpdateAPIQueueable',
                        'callout:Enterprise_API',
                        req.getBody(),
                        res.getBody(),
                        res.getStatusCode()
                    );
                }
            }

        } catch (Exception ex) {

            LoggerUtil.createErrorLog(
                'EnterpriseAppUpdateAPIQueueable',
                'Update Status Enterprise App',
                ex.getTypeName(),
                ex.getMessage(),
                ex.getStackTraceString(),
                currentCaseId
            );
        }

        this.caseIdMap.remove(integrationTransactionId);
        if (!this.caseIdMap.isEmpty()) {
            System.enqueueJob(new EnterpriseAppUpdateAPIQueueable(this.caseIdMap));
        }
    }

    private static String mapStatus(String value) {
        switch on value {
            when '2629' { return 'BOOKING CREATED'; }
            when '2630' { return 'BOOKING ASSIGNED'; }
            when '2638' { return 'RE_SCHEDULED'; }
            when '2632' { return 'PICKED'; }
            when '2633' { return 'CANCELLED'; }
            when else   { return null; }
        }
    }

    public class DataWrapper {
        public String caseNo;
        public String reqNo;
        public String status;
        public String waybill;
    }
}