/**
* @File Name          : CancelPreBookingAPI.cls
* @Description        : This class will have all the methods related to Cancel case Booking APIs
* @Author             : Deepika
* @Group              : IBM
* @Last Modified By   : Deepika
* @Last Modified On   : 27-05-2024
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        15-05-2024               Deepika                   Initial Version
**/
public class CancelPreBookingAPI {
    
    
    /** =================================== CANCLE CASE STATUS METHODS ========================================= */
    /**
@Author          : Deepika
@Company         : IBM
@Description     : This method is used to send the request from salesforce to change the case status to CANCEL
@Date            : 15-05-2024     
*/
    
    @AuraEnabled(cacheable=false)
    public static String cancelCaseStatus(String recordId, String caseId, String selectedReason) {
        ReturnInfo returnInfo = new ReturnInfo();
        List<String> caseIdList ;
        String tokenEndpoint = system.label.PropeliTokenEndpoint;
        String username = system.label.Propeli_Username;
        String password = system.label.Propeli_Password;
        String apiKey = system.label.PropelIPreBookingAPIKey;
        String preBookingCancelEndpoint = system.label.PropelIPreBookingEndpoint+'/updatePrebookingRequestForCase';
        String tokenAuth;
        //System.debug('selectedReason '+caseId + ' : '+selectedReason);
        try{
            if (caseId == null) {
                returnInfo.message = 'ConstantUtility.INVALID_CASE_ID';
                throw new AuraHandledException(returnInfo.message);
            }
            if(tokenEndpoint != null && username != null && password != null){
                JSONGenerator genAuth = JSON.createGenerator(true);
                genAuth.writeStartObject();
                genAuth.writeStringField('grant_type', 'client_credentials');
                genAuth.writeStringField('scope', 'propeli-test/booking');
                genAuth.writeStringField('x-apikey', apiKey);
                genAuth.writeEndObject();
                String jsonAuthString = genAuth.getAsString(); 
                
                HttpResponse res = cls_PropelICallout.propelITokenCallout(username, password,'POST',jsonAuthString, tokenEndpoint);
                
                if(res.getStatusCode() == 200)
                {
                    JsonParser2 tokenRes = (JsonParser2)JSON.deserialize(res.getBody(), JsonParser2.class);
                    tokenAuth = tokenRes.access_token;
                }
            }
            if(Test.isRunningTest()){
                tokenAuth = 'testtoken';
            }
            //System.debug('httpResponse : '+tokenAuth);
            //if(tokenAuth!=null){
            List<Case> caseToUpdate = new List<Case>();                             
            RequestBody requestBody = new requestBody();
            requestBody.safexperienceReferenceNumber =  caseId;//'00846952';00616855
            requestBody.updateOperation = 'CANCEL';
            requestBody.updateOperationReason = selectedReason;
            
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(preBookingCancelEndpoint);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type','application/json');
            httpReq.setHeader('userId', username);
            httpReq.setHeader('x-api-key', apiKey);
            httpReq.setHeader('Authorization', tokenAuth);
            httpReq.setHeader('scope', 'propeli-test/booking');
            httpReq.setTimeout(120000);
            httpReq.setbody(JSON.serialize(requestBody));
            
            HttpResponse httpResponse = HttpUtility.makeCallout(httpReq, ConstantUtility.CHANGE_CASE_STATUS_TO_CANCEL_API);
            System.debug('httpResponse : '+httpResponse.getBody());
            ResponseWrapper wrapper = (ResponseWrapper)JSON.deserialize(httpResponse.getBody(), ResponseWrapper.Class);
            if(httpResponse.getStatusCode() == 200){
                updateCaseStatus(recordId, selectedReason);
            }    
            if(httpResponse.getStatusCode() == 200 || httpResponse.getStatusCode() == 400){
                returnInfo.message = httpResponse.getBody();
                returnInfo.type = (httpResponse.getStatusCode() == 200) ? ConstantUtility.SUCCESS : ConstantUtility.ERROR ;
                return JSON.serialize(returnInfo);
            }else {
                LoggerUtil.createAPILog('PreBooking Cancel API<<<<<>>>>>>>', preBookingCancelEndpoint, JSON.serialize(requestBody), httpResponse.getBody(), httpResponse.getStatusCode());                                        
                returnInfo.message = ConstantUtility.GETTING_ERROR_FROM_API;
                throw new AuraHandledException(returnInfo.message);
            }
            //}
            //returnInfo.message = ConstantUtility.INCOMPLETE_API_INFO_MESSAGE;
            //throw new AuraHandledException(returnInfo.message);
        } catch(exception exp) {
            returnInfo.message = returnInfo.message != null ? returnInfo.message : exp.getMessage();
            returnInfo.type = ConstantUtility.ERROR;
            LoggerUtil.createErrorLog('PropelIPreBookingAPI', 'Update PropelI PreBooking API', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        return JSON.serialize(returnInfo);
    }
    Public static void updateCaseStatus(String recordId, String cancellationReason){
       Case cseObj =  new Case();
        cseObj.Id = recordId;
        cseObj.Cancel_Reason__c = cancellationReason;
        cseObj.Status = 'Cancelled';
        cseObj.Booking_Status__c = '2633'; //'CANCEL'
        TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
        update cseObj;
        //TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);  
        //System.debug('casesList cseObj : '+cseObj);

        List<Case> caseList = [SELECT Id, Origin FROM Case WHERE Id =: recordId LIMIT 1];
        List<String> casesList = new List<String>();
        casesList.add(recordId);
        if(!casesList.isEmpty()&&caseList.get(0).Origin == 'IConnect'){
            IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
            createITLogObject.objectName = 'Case'; 
            createITLogObject.recordIdList = casesList;
            createITLogObject.operationType = System.Label.OperationType_iConnect_UpdateCase; 
            IntegrationUtility.createIntegrationTransaction(createITLogObject);
        }
    }
    
    /**  ================================== RETURN RESPONSE WRAPPER TO LWC COMPONENT ========================================= */
    public class ReturnInfo {
        @AuraEnabled public String type = ConstantUtility.ERROR;
        @AuraEnabled public String message;
    }
    
    
    Public class JsonParser2 {
        public String access_token;
        public String token_type;
        public String expires_in;
    } 
    
    
    Public class ResponseWrapper{
        public string message;
        public string data;
        public string status;
        public JSONError errors;
    }
    
    Public class JSONError{
        public List<ErrorWrapper> error;
    }
    
    Public class ErrorWrapper{
        public String code;
        public string description;
    }
    
    Public class RequestBody{
        public string safexperienceReferenceNumber;//default
        public string updateOperation;
        public string updateOperationReason;
    }
    
}