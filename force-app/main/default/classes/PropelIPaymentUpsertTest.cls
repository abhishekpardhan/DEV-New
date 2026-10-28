/**
 * Description    :    Test class for PropelIPaymentUpsertTest apex class
 * 
 * Coverage      :    80%
 **/
@istest
public class PropelIPaymentUpsertTest {
    @istest static void testPostMethod()
    {  
        Account acc = new Account();
        acc.Name='Test';
        acc.Composite_Key__c ='SAFEX324-12345';
        insert acc;
        
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        insert br;
        
         Invoice__c inv = new Invoice__c();
        inv.Name = '210201000003';
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
        inv.Bill_Number__c = '210201000003';
        inv.Charged_Freight_Amount__c =
        inv.Charged_ST_Amount__c =  6778.50;
        inv.Charged_Total_Amount__c = 674590.85;
        inv.Out_Oct_Amount__c = 768.00;	
        inv.Out_Total_Amount__c = 7483900.00;
        inv.Status_LID__c = 98765;
        insert inv; 
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/PropelIPaymentUpsert';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        PropelIPaymentUpsert.jsonWrap pay=new PropelIPaymentUpsert.jsonWrap();
        pay.Bill_ID= 54321;
        pay.Bill_Number='210201000003';
        pay.Receipt_Number = 'Recpt031';
        pay.Application_Doc_Id= 213245; 
        
        PropelIPaymentUpsert.jsonWrap pay1=new PropelIPaymentUpsert.jsonWrap();
        pay1.Bill_ID= 54321;
        pay1.Bill_Number='';
        pay1.Receipt_Number = 'Recpt031';
        pay1.Application_Doc_Id= 213245;
        
        PropelIPaymentUpsert.jsonWrap pay2=new PropelIPaymentUpsert.jsonWrap();
        pay2.Bill_ID= 54321;
        pay2.Bill_Number='210201000003';
        pay2.Receipt_Number = 'Recpt031';
        pay2.Application_Doc_Id= null;
        
         PropelIPaymentUpsert.jsonWrap pay3=new PropelIPaymentUpsert.jsonWrap();
        pay3.Bill_ID= 54321;
        pay3.Bill_Number=null;
        pay3.Receipt_Number = 'Recpt031';
        pay3.Application_Doc_Id= 213245; 
        
        List<PropelIPaymentUpsert.jsonWrap> lstWrap=new list<PropelIPaymentUpsert.jsonWrap>();
        lstWrap.add(pay);
        lstWrap.add(pay1);
        lstWrap.add(pay2);
        Test.startTest();
        PropelIPaymentUpsert.jsonWrap.createPayment(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        System.assert(testStr != null);

}
}