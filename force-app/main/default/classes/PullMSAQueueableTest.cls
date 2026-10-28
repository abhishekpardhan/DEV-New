/*********************************************************************************************
**Author: K SANSI - IBM, 29-11-2023
**Description: Test Class of PullMSAQueueable
**JIRA Ticket: SAC-271
*/
@isTest
public class PullMSAQueueableTest {

    private class MockHttpPropelITokenResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            String jsonResponse =  '{"grant_type":"client_credentials", "scope":"sfdc/server"}';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setHeader('username','unittesting');
            objResponse.setHeader('password','unittesting123');
            objResponse.setBody(jsonResponse);
            objResponse.setStatusCode(200);
            return objResponse;
        }
    } 
    
    @testSetup
    public static void setup(){
             
        // Create MSA account
        Account acc1 = new Account();        
        acc1.RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Customer').getRecordTypeId();
        acc1.SFX_Code__c = 'ABC123';
        acc1.Propel_MSACode__c = 'PropelMSACodeTest';
        //acc1.ParentId = acc2.Id;
		acc1.Name = 'ABC';       
        insert acc1;
           
        // Create SFX account
        Account acc2 = new Account();        
        acc2.RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Actual_SFX').getRecordTypeId();
        acc2.SFX_Code__c = 'DEF456';
        acc2.Name = 'XYZ';
        acc2.ParentId = acc1.Id;
        insert acc2;
    }
    
    @isTest
    public static void testExecuteMultipleAccounts() {     	
         
        String RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Customer').getRecordTypeId();
        List<Account> acctlst = [Select Id,ParentId,SFX_Code__c from Account where RecordtypeId =: RecordTypeId];        
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new MockHttpPropelITokenResponse()); 
        Id jobId = System.enqueueJob(new PullMSAQueueable(acctlst)); 
        Test.stopTest();        
    }
        
    @isTest
    public static void testUpdateMSA() {
        
        // Define test data
        String RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Customer').getRecordTypeId();
        List<Account> acctlst = [Select Id,ParentId,SFX_Code__c,Propel_MSACode__c from Account where RecordtypeId =: RecordTypeId];        

        String startDate = String.valueOf(Date.today().addDays(-1));
        String endDate = String.valueOf(Date.today().addDays(1));
        List<String> msaCodes = new List<String>{acctlst[0].Propel_MSACode__c};   
        Test.setMock(HttpCalloutMock.class, new MockHttpPropelITokenResponse());     
        test.startTest();
        PullMSAQueueable.updateMSA(startDate, endDate, msaCodes);
        test.stopTest();      
    }
    
}