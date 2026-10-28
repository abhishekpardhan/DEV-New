public class PreBookingAPISchedulable implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        System.debug('PreBookingAPISchedulable');
        List<Integration_Transaction__c> listReqDetail = [SELECT Id, Record_Id__c, No_of_Retries__c, Status_Code__c, Status__c, isProcessing__c 
                                                          FROM Integration_Transaction__c 
                                                          WHERE Status__c = 'Fail' AND No_of_Retries__c < 3 AND Operation_Type__c = 'PropelICaseCreation'];
         
        Map<String, String> caseIdMap = new Map<String, String>();
        for(Integration_Transaction__c reqDetail : listReqDetail) {
            reqDetail.isProcessing__c = true; 
            reqDetail.No_of_Retries__c = reqDetail.No_of_Retries__c + 1;
            caseIdMap.put(reqDetail.Id, reqDetail.Record_Id__c);
        }
        update listReqDetail;
        /*PreBookingAPIQueueable propelIQueueableObj = new PreBookingAPIQueueable(caseIdMap);
        System.enqueueJob(propelIQueueableObj);*/
    }
    
}