/**
* @File Name          : CreateCaseApi.cls
* @Description        : This class will used to create complain Cases in salesforce using API.
* @Author             : Shubham
* @Group              : Safexpress
* @Last Modified By   : Shubham
* @Last Modified On   : 30/01/2021
**/
@RestResource(urlMapping='/CreateItRequestCaseAPI/*')
global with sharing class CreateItRequestCaseAPI {
     
    
    @HttpPost
    global static void createCase() {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        RestRequest request = RestContext.request; 
        String requestBody = request.requestBody != null ? request.requestBody.toString() : '';
        System.debug('########'+ request);
        System.debug('@@@@@@@@@@'+ requestBody);
     try{
        if(!String.isBlank(requestBody)){
     RequestWrapper requestWrapper = (RequestWrapper) System.JSON.deserialize(requestBody, RequestWrapper.class);
          if(requestWrapper != null){
            Account[] sfxAccount = [Select id, name , Booking_Branch__c,Booking_Branch__r.name, SFX_Code__c  from Account where SFX_Code__c  =: requestWrapper.sfx AND Booking_Branch__r.name =: requestWrapper.branch  limit 1];
         if( sfxAccount.size() > 0){
            case__c caseObj = createNewCase(requestWrapper);
            responseWrapper = createResponse(ConstantUtility.CASE_CREATED_SUCCESS, ConstantUtility.SUCCESS.toLowerCase(), caseObj.Name);
         }else{
            responseWrapper = createResponse('No SFX account find with this SFX and booking branch combination', ConstantUtility.ERROR.toLowerCase(), null);
         }
            
          }
           // responseWrapper = createResponse('Sucess', '200','00001411'); 
           }
        }catch(exception exp){
            responseWrapper = createResponse(exp.getMessage(), ConstantUtility.ERROR.toLowerCase(), null);
            LoggerUtil.createErrorLog('CreateItRequestCaseAPI','createCase', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        LoggerUtil.createAPILog('CreateItRequestCaseAPI', 'TO Salesforce', requestBody, JSON.serialize(responseWrapper), null);
            if(!Test.isRunningTest()){
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
        }

     }

     public static ResponseWrapper createResponse(String message, String status, String case_number) {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        responseWrapper.message = message;
        responseWrapper.status = status;
        responseWrapper.case_number = case_number;
        return responseWrapper;
    }
    global class ResponseWrapper {
        global String message;
        global String status;
        global String case_number;
        
    }

    public class requestWrapper {
        public String sfx;
        public String branch;
        public String type;
        public String subType;
        public String relatedTo;
        public String name;
        public String mobileNo;
        public String email;
        public String remarks;    
    }
         
    public static Case__c createNewCase(RequestWrapper requestWrapper) {
        Id sfxAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        Account sfxAccount = [Select id, name , Booking_Branch__c,Booking_Branch__r.name, SFX_Code__c  from Account where SFX_Code__c  =: requestWrapper.sfx AND Booking_Branch__r.name =: requestWrapper.branch and recordtypeid =: sfxAccountId limit 1];
        Case__c newCase = new Case__c();
        newCase.Account__c = sfxAccount.id;
        newCase.Customer_Case_Type__c = requestWrapper.type;
        newCase.Case_Sub_Type__c = requestWrapper.subType;
        newCase.Related_to__c = requestWrapper.relatedTo;
        newCase.Customer_Contact_Person_Name__c = requestWrapper.name;
        newCase.Customer_Mobile_Number__c = requestWrapper.mobileNo;
        newCase.Customer_Contact_Email__c = requestWrapper.email;
        newCase.Customer_Remarks__c = requestWrapper.remarks;
        newCase.recordtypeid = '0127F000000ywkjQAA';
        insert newCase;
        
        newCase = [SELECT Id,Name FROM Case__c WHERE Id = :newCase.Id LIMIT 1];
        return newCase;
        
    }
   
}