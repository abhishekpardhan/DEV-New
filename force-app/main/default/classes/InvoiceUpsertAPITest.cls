@IsTest
private class InvoiceUpsertAPITest {
    static testMethod void testPostMethod()
    {
        Account acc = new Account();
        acc.Name='Test';
        acc.Composite_Key__c ='SAFEX324-12345';
        insert acc;
        
        Branch_Master__c brch = new Branch_Master__c();
        brch.Branch_ID__c  = 12345;
        insert brch;
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/SFXInvoiceCreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        InvoiceUpsertAPI.jsonWrap inn = new InvoiceUpsertAPI.jsonWrap();
        inn.Bill_Number = 'WQR346';
        inn.Propel_ID = 65432;
        inn.Customer_Contract_Code = 'SAFEX324';
        inn.Bill_Branch_ID = 12345 ;
        
        List<InvoiceUpsertAPI.jsonWrap> lstWrap = new List<InvoiceUpsertAPI.jsonWrap>();
        lstWrap.add(inn);
        Test.startTest();
        InvoiceUpsertAPI.createInvoice(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        
        System.assert(testStr != null);
        System.assertEquals('65432', testStr.subString((testStr.IndexOf('propelId')+10),(testStr.IndexOf('propelId')+15)));
        
    }

}