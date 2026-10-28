/**
 * Description		:		Test class for InvoiceDeleteBatch apex class
 * 
 * Coverage			:		81%
 **/
@isTest 
public class InvoiceDeleteBatchTest{
    static testMethod void testMethod1() {
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
        
        User usAM = CommonDataTest.getUserAM();
        insert usAM;
        
        User us =  CommonDataTest.getUserBdm();
        us.ManagerId = usAM.Id;
        insert us;
        
        Id recordsTypeTask = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
       
        Account_Team__c accteam = new Account_Team__c();
        accteam.Submission__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
        
        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.account__c = objSfx.Id;
        objInv.Out_Total_Amount__c = 0;
        objInv.Date_Total_Amount__c = Date.today(); 
        insert objInv;
     
        Test.startTest();
        InvoiceDeleteBatch objInvBatch = new InvoiceDeleteBatch();    
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, objInvBatch);
        Test.stopTest();    }
}