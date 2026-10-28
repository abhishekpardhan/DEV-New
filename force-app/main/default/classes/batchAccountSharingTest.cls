@isTest 
public class batchAccountSharingTest {
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

                   
        Test.StartTest();
        batchAccountSharing objaccshar = new batchAccountSharing();
        database.executebatch(objaccshar);
        Test.stopTest();      
    }

}