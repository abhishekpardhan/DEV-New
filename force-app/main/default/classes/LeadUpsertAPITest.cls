/**
 * Description      :       Test class for LeadUpsertAPI apex class
 * 
 * Coverage         :       97%
 **/
@IsTest
private class LeadUpsertAPITest {
    static testMethod void testPostMethod()
    {
        Account acc = new Account();
        acc.Name='Test';
        acc.Composite_Key__c ='SAFEX324-12345';
        insert acc;
        
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        insert br;
        
        Lead__c ld = new Lead__c();
        ld.RecordTypeId = Schema.SObjectType.Lead__c.getRecordTypeInfosByName().get('Credit Lead').getRecordTypeId();
//        ld.RecordTypeId = '0120l0000002F6qAAE';
        ld.Phone__c  = '2245432100';
        ld.Email__c = 'md@safex.com';
        ld.Rating__c  = 'SAFEX324';
        ld.Booking_Branch__c = br.id;
        ld.Source__c = 'Employee';
        ld.Assignment_Date__c = Date.today();
        ld.Rating__c = 'Normal';
        ld.Region__c = 'MUMBAI';
        ld.Country__c =  'INDIA';
//        ld.Campaign_Name__c = SObjectType.Lead__c.Fields.Campaign_Name__c.PicklistValues[0].getValue();
       // ld.Campaign_Name__c = 'SIAM';    
        insert ld;        
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/SFXPaymentCreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        LeadUpsertAPI.jsonWrap ldJsn = new LeadUpsertAPI.jsonWrap();
        ldJsn.Lead_Name = 'ABP';
     //   ldJsn.Campaign_Name = 'Zero Billing';
        ldJsn.Country = 'INDIA';
        
        List<LeadUpsertAPI.jsonWrap> lstWrap = new List<LeadUpsertAPI.jsonWrap>();
        lstWrap.add(ldJsn);
        Test.startTest();
        LeadUpsertAPI.createLead(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        System.debug('====testStr ===='+testStr);
        System.assert(testStr != null);
        integer i = testStr.IndexOf('isSuccess');
        System.debug('====I===='+i);
        System.assertEquals('true', testStr.subString(i+11,i+15));
        
    }

}