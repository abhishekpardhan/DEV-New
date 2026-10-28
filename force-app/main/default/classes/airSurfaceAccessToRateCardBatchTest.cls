@istest
public class airSurfaceAccessToRateCardBatchTest {
    
    static testMethod void testMethod1() {
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        String rcRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.RecordTypeId = rcRecordTypeId;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.Submission__c = true;
        accteam.Relationship__c = true;
        //accteam.RecordTypeId = rcRecordTypeId;
        accteam.Account__c = objSfx.Id;
        //accteam.BDM__c=us.Id;
        accTeam.BDMPropelI__c=us.Id;
        insert accteam;
        
        Test.StartTest();
        airSurfaceAccessToRateCardBatch objSubTask = new airSurfaceAccessToRateCardBatch();
        Database.executeBatch(objSubTask);
        Test.stopTest();      
    }
    
    static testMethod void testMethod2() {
        Test.StartTest();
        Database.BatchableContext BC;
        airSurfaceAccessToRateCardBatch objSubTask = new airSurfaceAccessToRateCardBatch();
        objSubTask.execute(BC,null);
        Test.stopTest();  
    }
}