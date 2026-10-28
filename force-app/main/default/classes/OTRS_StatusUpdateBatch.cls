/**
 * @File Name          : OTRS_StatusUpdateBatch.cls
 * @Description        : This class is used to update the the cases with Waybill Information based on OTRS Ticket Number
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 02-08-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        02-08-2021                Deepak                   Initial Version
**/
global class OTRS_StatusUpdateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public Safex_API__c safexApi;
    public Boolean isJobAborted = false;

    public OTRS_StatusUpdateBatch() {
        List<Safex_API__c> wayApiInfo = QueryUtil.getSafexApiInfo(ConstantUtility.OTRS_TICKET_DETAIL_API_NAME);
        if (wayApiInfo.size() > 0 && wayApiInfo[0].Endpoint__c != null && wayApiInfo[0].Access_Key__c != null) {
            safexApi = wayApiInfo[0];
        }
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
                SELECT Id,OTRS_Request_Status__c,OTRS_Remarks__c,OTRS_Ticket_No__c,Sub_Type__c,Status
                FROM Case
                WHERE OTRS_Ticket_No__c != null AND OTRS_Request_Status__c != :ConstantUtility.closed
                AND IsClosed = false
        ]);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {


            /** Condition check for API configuration */
            if (safexApi == null) {
                isJobAborted = true;
                System.abortJob(bc.getJobId());
            }

            List<Case> caseToUpdate = new List<Case>();
            List<Case> cases = (List<Case>) scope; // TypeCasting to sObject to Case
            System.debug(cases.size());
            /* Iteration on the Case Object*/
            for (Case caseObj : cases) {
                String endpoint = safexApi.Endpoint__c + '?access_key=' + safexApi.Access_Key__c + '&' + 'ticketNo=' + caseObj.OTRS_Ticket_No__c;
                HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.GET, null, null, null, null, null);
                HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, ConstantUtility.OTRS_TICKET_DETAIL_API_NAME);
                System.debug('httpResponse getBody' + httpResponse.getBody());
                System.debug('httpResponse getBody' + httpResponse.getStatusCode());
                if (httpResponse.getStatusCode() == 200) {
                    String status = getStatus(httpResponse.getBody());
                    if (status != null) {
                        caseObj.OTRS_Request_Status__c = status ;
                        if( caseObj.OTRS_Request_Status__c == ConstantUtility.OTRS_STATUS_CLOSE ){ //|| caseObj.OTRS_Request_Status__c == 'Close Successful'
                            if(!String.isBlank(caseObj.Sub_Type__c) && caseObj.Sub_Type__c == 'Short / Part Shipment' || caseObj.Sub_Type__c == 'Pilferred' || caseObj.Sub_Type__c == 'Damage' || caseObj.Sub_Type__c == 'Delivery not done' || caseObj.Sub_Type__c == 'Interchange' || caseObj.Sub_Type__c == 'Wrong Delivery'){
                                system.debug('sub-type'+caseObj.Sub_Type__c);
                            }else{
                                system.debug('cseObj.Status'+caseObj.Status);
                                caseObj.Status = ConstantUtility.COMPLETED;
                            }
                            //caseObj.Status = ConstantUtility.COMPLETED ;
                        }
                        caseToUpdate.add(caseObj);
                        System.debug('Case Added');
                    }
                }
            }
            if (caseToUpdate.size() > 0) {
                TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
                update caseToUpdate;
                System.debug(caseToUpdate[0]);
                TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);
            }
        } catch (Exception exp) {
            LoggerUtil.createErrorLog('OTRS_StatusUpdateBatch', 'Execute', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), 'Batch Fail');
        }

    }
    public void finish(Database.BatchableContext bc) {
        if (isJobAborted) {
            LoggerUtil.createErrorLog('UpdateOtrsStatusBatch', 'OTRS-Status Update', 'Batch Aborted', ConstantUtility.INCOMPLETE_API_INFO_MESSAGE, null, null);
        }
        System.debug('UpdateOtrsStatusBatch Finished');
    }

    /**
      @Author          : Deepak
      @Company         : TechMatrix Consulting
      @Description     : This method is used to parse the response and return the state of the OTRS ticket
      @Date            : 03/08/2021
    */
    public static String getStatus(String responseString) {
        String status;
        JSONParser parser = JSON.createParser(responseString);
        Boolean isSuccess = false;
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                parser.nextValue();
                /*if (parser.getCurrentName() == 'status' && parser.getIntegerValue() == 201) {
                    isSuccess = true;
                }*/
                if (parser.getCurrentName() == 'state' && parser.getText() != '' && parser.getText() != null) { //isSuccess && 
                    //System.debug(parser.getCurrentName());
                    //System.debug(parser.getText());
                    status = (parser.getText()).containsIgnoreCase(ConstantUtility.CLOSED) ? ConstantUtility.CLOSED : ConstantUtility.OPEN;
                    break;
                }
            }
        }
        return status;
    }
}