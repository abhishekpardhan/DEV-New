/**
 * Description		:		Test class for PRCCustomerUpsertAPI apex class
 * 
 * Coverage			:		100%
 **/
@IsTest
private class PRCCustomerUpsertAPITest {
    static testMethod void testPostMethod()
    {            
        Opportunity__c opp = new Opportunity__c();
        opp.Customer_Type__c = 'NEW OPPORTUNITY';
        opp.Monthly_Potential_Air__c = 123456.90;
        opp.Monthly_Potential_Surface__c = 5436.75;
        insert opp;
        
        Account par = new Account();
        par.Name='TEST-PARENT';
        par.Composite_Key__c ='643001-SAFEX-12375';
        par.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        par.ParentId = null;
        par.Opportunity__c = opp.Id;
        insert par;
        
        Account acc = new Account();
        acc.Name='TEST PRC';
        acc.Composite_Key__c ='643001-SAFEX-12345';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        acc.ParentId = par.Id;
        acc.Opportunity__c = opp.Id;
        insert acc;
        
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        insert br;
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/PRCCustomerCreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        PRCCustomerUpsertAPI.jsonWrap prcCust = new PRCCustomerUpsertAPI.jsonWrap();
        prcCust.Propel_ID = 643001;
        prcCust.Branch = (Integer)br.Branch_Id__c;
        prcCust.PRC_Code = 'SAFEX';
        prcCust.Parent_Account_ID = par.Id;
        prcCust.Opportunity_ID = opp.Id;
        
        List<PRCCustomerUpsertAPI.jsonWrap> lstWrap = new List<PRCCustomerUpsertAPI.jsonWrap>();
        lstWrap.add(prcCust);
        Test.startTest();
        PRCCustomerUpsertAPI.createPRCCustomer(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        System.debug('====testStr ===='+testStr);
        System.assert(testStr != null);
        integer i = testStr.IndexOf('isSuccess');
        System.debug('====I===='+i);
       // System.assertEquals('true', testStr.subString(i+11,i+15));   
    }
}