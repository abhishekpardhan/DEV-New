@IsTest
private class ReplanOverdueTasksBatchTest {
    @TestSetup
    static void setupTestData() {

        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
		
        Branch_Master__c bm = new Branch_Master__c();
        bm.Name = 'Test Branch1';
        insert bm;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Branch__c = bm.Id;
        
        insert objSfx;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
        mapping.Account__c = objSfx.Id;
        mapping.PropelI_BDM__c = us.Id; 
        mapping.CCD__c = true;
        mapping.Collection__c = true;
        mapping.PropelI_Composite_Key__c = us.Id+'::'+objSfx.Id;
        insert mapping;
        
        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.Account__c = objSfx.Id;
        objSfx.Billing_Level__c = 'MSA';
        objInv.NAM_Propeli_BDM_Mapping__c = mapping.Id;
        insert objInv;                
        
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.National4__c = true;
        accteam.Collection__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDMPropelI__c=us.Id;
        accteam.PropelI_Composite_Key__c = us.Id+'::'+objSfx.Id;
        insert accteam;
             
        
        Invoice__c objInv1 = CommonDataTest.getInvoice();
        objInv1.Account__c = objSfx.Id;
        objInv1.NAM_Propeli_BDM_Mapping__c = mapping.Id;
        objSfx.Billing_Level__c = 'MSA';
        objInv1.BDM_Email_IDs__c = 'test@gmail.com';

        insert objInv1;
        
        Task objTask = CommonDataTest.getCollectionTask();
        objTask.Remaining_Payment_Tentative_Date__c = Date.today();
        objTask.WhatId = objInv.id;
        insert objTask;

    }

    @IsTest
    static void testBatchSuccessfulExecution() {
        Test.startTest();
        ReplanOverdueTasksBatch schedulableBatch =
            new ReplanOverdueTasksBatch();
        schedulableBatch.execute((SchedulableContext)null);
        Test.stopTest();
    }


    @IsTest
    static void testBatchFailedUpdate() {


        ReplanOverdueTasksBatch batch =
            new ReplanOverdueTasksBatch();

        List<Task> scope = new List<Task>();
        scope.add([SELECT Id, Status, Remaining_Payment_Tentative_Date__c FROM Task LIMIT 1]);

        Test.startTest();
        batch.execute(
            (Database.BatchableContext)null,
            scope
        );

        batch.finish((Database.BatchableContext)null);

        Test.stopTest();

    }
}