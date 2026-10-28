@isTest
public class AccountTotalInvoiceUpdateBatch_Test {
    static testMethod void testMethod1() {
        Test.startTest();

        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
        
        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.account__c = objSfx.Id;
        objInv.Out_Total_Amount__c = 122232;
        objInv.Status_LID__c = 292;
        objInv.Date_Total_Amount__c = Date.today(); 
        insert objInv;
        
        Invoice__c objInv1 = CommonDataTest.getInvoice();
        objInv1.account__c = objSfx.Id;
        objInv1.Out_Total_Amount__c = 9898;
        objInv1.Status_LID__c = 292;
        objInv1.Date_Total_Amount__c = Date.today(); 
        insert objInv1;
        
        String query = 'select Id from account where Id in (select account__c from invoice__c where Status_LID__c = 292)';
        AccountTotalInvoiceUpdateBatch objAcc = new AccountTotalInvoiceUpdateBatch(query);    
        database.executebatch(objAcc);
        Test.stopTest(); 
    }
}