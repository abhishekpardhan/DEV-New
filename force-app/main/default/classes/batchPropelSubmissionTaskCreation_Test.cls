/**
 * Description		:		Test class for batchSubmissionTaskCreation apex class
 * 
 * Coverage			:		
 **/
@istest
public class batchPropelSubmissionTaskCreation_Test {
    
    static testMethod void testMethod1() {
               
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.Submission__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
     
        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.account__c = objSfx.Id;
        insert objInv;
        
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(objInv.Id, yesterday);
        
        Test.StartTest();
        batchPropelSubmissionTaskCreation objSubTask = new batchPropelSubmissionTaskCreation();
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, objSubTask );
        Test.stopTest();      
    }


}