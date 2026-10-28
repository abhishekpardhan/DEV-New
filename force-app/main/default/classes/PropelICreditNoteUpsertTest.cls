/**
 * Description    :    Test class for PropelICreditNoteUpsertTest apex class
 * 
 * Coverage      :    82%
 **/
@istest
public class PropelICreditNoteUpsertTest {
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
        
     /*    Invoice__c inv1 = new Invoice__c();
       inv1.Propel_ID__c  = 54321;
        inv1.Bill_Due_Date__c = Date.today();
        inv1.Customer_Contract_Code__c = 'SAFEX324';
        inv1.Bill_Branch__c = br.id;
        inv1.Collection_Branch__c = br.id;
        inv1.Sub_Branch_Master__c = br.id;
        inv1.Account__c = acc.id;
        inv1.Bill_From_Date__c = Date.today();
        inv1.Bill_To_Date__c = Date.today();
        inv1.Submission_Date__c = Date.today();
        inv1.Bill_Number__c = 'INV/06/8971';
        inv1.Charged_Freight_Amount__c =
        inv1.Charged_ST_Amount__c =  6778.50;
        inv1.Charged_Total_Amount__c = 674590.85;
        inv1.Out_Oct_Amount__c = 768.00;	
        inv1.Out_Total_Amount__c = 7483900.00;
        inv1.Status_LID__c = 98765;
        insert inv1;  
*/        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/PropelICreditNoteUpsert';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
       
        PropelICreditNoteUpsert.jsonWrap picn=new PropelICreditNoteUpsert.jsonWrap();
        picn.id=54321;
        picn.Bill_ID = inv.Propel_ID__c;
        picn.Bill_Number = '210201000003';
        
        PropelICreditNoteUpsert.jsonWrap picn1=new PropelICreditNoteUpsert.jsonWrap();
        picn1.id=54321;
        picn1.Bill_ID = inv.Propel_ID__c;
        picn1.Bill_Number = '2102371141231';
        
        PropelICreditNoteUpsert.jsonWrap picn2=new PropelICreditNoteUpsert.jsonWrap();
        picn2.id=54321;
        picn2.Bill_ID = inv.Propel_ID__c;
        picn2.Bill_Number = '';
        
        PropelICreditNoteUpsert.jsonWrap picn3=new PropelICreditNoteUpsert.jsonWrap();
       // picn3.id ;
        picn3.Bill_ID = inv.Propel_ID__c;
        picn3.Bill_Number = '2102371141231';
                          
            List<PropelICreditNoteUpsert.jsonWrap> lstWrap=new list<PropelICreditNoteUpsert.jsonWrap>();
        lstWrap.add(picn);
        lstWrap.add(picn1);
        lstWrap.add(picn2);
        lstWrap.add(picn3);
        Test.startTest();
        PropelICreditNoteUpsert.createDebitNote(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        System.assert(testStr != null);
    }
        

}