/**
* @File Name          : CreateCaseApi.cls
* @Description        : This class will used to create complain Cases in salesforce using API.
* @Author             : Shubham
* @Group              : Safexpress
* @Last Modified By   : Shubham
* @Last Modified On   : 30/01/2021
**/
@RestResource(urlMapping='/CreateComplainCaseAPI/*')
global with sharing class CreateComplainCaseAPI {
     
    
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
 case caseObj = createNewCase(requestWrapper);
 responseWrapper = createResponse(ConstantUtility.CASE_CREATED_SUCCESS, ConstantUtility.SUCCESS.toLowerCase(), caseObj.CaseNumber);
          }
           // responseWrapper = createResponse('Sucess', '200','00001411'); 
           }
        }catch(exception exp){
            responseWrapper = createResponse(exp.getMessage(), ConstantUtility.ERROR.toLowerCase(), null);
            LoggerUtil.createErrorLog('CreateComplainCaseAPI','createCase', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        LoggerUtil.createAPILog('CreateComplainCaseAPI', 'TO Salesforce', requestBody, JSON.serialize(responseWrapper), null);
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

    global class RequestWrapper {
        global String caseNature;
        global String caseType;
        global String subType;
        global String Description;
        global String emailId;
        global String Phone;
        global String Name;
        global String source;
    }

    public static Case createNewCase(RequestWrapper requestWrapper) {
        
        List<Contact> contacts = new List<Contact>();
        contacts = [SELECT Id FROM Contact WHERE MobilePhone = :requestWrapper.Phone /*AND Email = :requestWrapper.emailId*/ LIMIT 1];
        if (contacts.size() == 0) {
            Contact contact = new Contact();
            contact.LastName = requestWrapper.Name;
            contact.Email = requestWrapper.emailId;
            contact.MobilePhone = requestWrapper.Phone;
            insert contact;
            contacts.add(contact);
        }
        Case newCaseObj = new Case();
        newCaseObj.ContactId = contacts[0].Id ;
        newCaseObj.Case_Nature__c = requestWrapper.caseNature;
        newCaseObj.Case_Type__c = requestWrapper.caseType;
        newCaseObj.Sub_Type__c = requestWrapper.subType;
        newCaseObj.Description = requestWrapper.Description;
        newCaseObj.Origin = requestWrapper.source;
        

        insert newCaseObj;
        newCaseObj = [SELECT Id,CaseNumber FROM Case WHERE Id = :newCaseObj.Id LIMIT 1];
        return newCaseObj;
    }
   
}