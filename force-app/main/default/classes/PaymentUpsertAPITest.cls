/**
 * Description		:		Test class for PaymentUpsertAPI apex class
 * 
 * Coverage			:		100%
 **/
@IsTest
private class PaymentUpsertAPITest {
    static testMethod void testPostMethod()
    {
        Account acc = new Account();
        acc.Name='Test';
        acc.Composite_Key__c ='SAFEX324-12345';
        insert acc;
        
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        insert br;
        
        Invoice__c inv = new Invoice__c();
        inv.Propel_ID__c  = 54321;
        inv.Bill_Due_Date__c = Date.today();
        inv.Customer_Contract_Code__c = 'SAFEX324';
        inv.Bill_Branch__c = br.id;
        inv.Collection_Branch__c = br.id;
        inv.Sub_Branch_Master__c = br.id;
        inv.Account__c = acc.id;
        inv.Bill_From_Date__c = Date.today();
        inv.Bill_To_Date__c = Date.today();
        inv.Submission_Date__c = Date.today();
        inv.Bill_Number__c = 'INV/06/8971';
        inv.Charged_Freight_Amount__c =
        inv.Charged_ST_Amount__c =  6778.50;
        inv.Charged_Total_Amount__c = 674590.85;
        inv.Out_Oct_Amount__c = 768.00;
        inv.Out_Total_Amount__c = 7483900.00;
        inv.Status_LID__c = 98765;
        insert inv;        
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/SFXPaymentCreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        PaymentUpsertAPI.jsonWrap pmt = new PaymentUpsertAPI.jsonWrap();
        pmt.Bill_ID = 54321;
        pmt.Bill_Number = 'Bill256';
        pmt.Receipt_Number = 'Recpt031';
        
        List<PaymentUpsertAPI.jsonWrap> lstWrap = new List<PaymentUpsertAPI.jsonWrap>();
        lstWrap.add(pmt);
        Test.startTest();
        PaymentUpsertAPI.createPayment(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();        
        System.assert(testStr != null);
        integer i = testStr.IndexOf('isCreated');        
        System.assertEquals('true', testStr.subString(i+11,i+15));
        
    }

}