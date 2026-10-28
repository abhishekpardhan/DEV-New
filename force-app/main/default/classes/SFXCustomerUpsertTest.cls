/**
 * Description		:		Test class for SFXCustomerUpsertAPI apex class
 * 
 * Coverage			:		98%
 **/
@IsTest
private class SFXCustomerUpsertTest{
    static testMethod void testPostMethod()
    {
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        insert br;
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/SFXCustomerCreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        SFXCustomerUpsertAPI.jsonWrap cust = new SFXCustomerUpsertAPI.jsonWrap();
        cust.SFX_Code = 'SAFEX773';
        cust.Booking_Branch_ID = 12345;
        cust.Collection_Branch_ID = 12345;
        cust.Submission_Branch_ID = 12345;
        
        List<SFXCustomerUpsertAPI.jsonWrap> lstWrap = new List<SFXCustomerUpsertAPI.jsonWrap>();
        lstWrap.add(cust);
        Test.startTest();
        SFXCustomerUpsertAPI.createCustomer(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        System.assert(testStr != null);
        integer i = testStr.IndexOf('compositeKey');        
        System.assertEquals('SAFEX773-12345', testStr.subString(i+15,i+29));
        
    }

}