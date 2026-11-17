@IsTest
private class LeadReviveControllerTest {
   
    // ---------------------------------------------------------
    // 6. INVALID RECORD ID
    // ---------------------------------------------------------

    @IsTest
    static void testInvalidRecordId() {
        Account accountRecord = new Account(Name = 'Invalid Lead ID Test');

        insert accountRecord;
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(new List<Id>{ accountRecord.Id });
        Test.stopTest();
        System.assertEquals(1, results.size());
    }
    

    
    @isTest
    static void testReviveMethod(){
        List<Id> leadIds = new List<Id>();
        Lead l = CommonDataTest.getLead('Permission Denied', ConstantUtility.ACTIVE, ConstantUtility.Approved, null);
        insert l;
        l.Status = 'Dropped';
        l.Lead_Drop_Reason__c = 'FTL Customer';
        update l;
        leadIds.add(l.Id);
        LeadReviveController.reviveLeads(leadIds);
    }
    
    @isTest
    static void testNotDroppedLead(){
        List<Id> leadIds = new List<Id>();
        Lead l = CommonDataTest.getLead('Permission Denied', ConstantUtility.ACTIVE, ConstantUtility.Approved, null);
        insert l;
        leadIds.add(l.Id);
        LeadReviveController.reviveLeads(leadIds);
    }
    
    @IsTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        List<String> nullResults = LeadReviveController.reviveLeads(null);
        List<String> emptyResults = LeadReviveController.reviveLeads(new List<Id>());
        Test.stopTest();
        System.assertEquals(0, nullResults.size());
    }
    
    @IsTest
    static void testDuplicateLeadIds() {
        Lead leadRecord = CommonDataTest.getLead('Permission Denied', ConstantUtility.ACTIVE, ConstantUtility.Approved, null);
        insert leadRecord;
        List<Id> inputIds = new List<Id>{leadRecord.Id, leadRecord.Id};
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(inputIds);
        Test.stopTest();
        System.assertEquals(2, results.size(), 'The result must preserve duplicate input positions.');
    }
    @IsTest
    static void testApprovalUnlockCatchBlock() {
        Lead leadRecord = CommonDataTest.getLead('Unlock Exception Lead', ConstantUtility.ACTIVE, ConstantUtility.Approved, null);
        insert leadRecord;
        Approval.LockResult[] lockResults = Approval.lock(new List<Id>{leadRecord.Id});
        System.assert(lockResults[0].isSuccess(), 'Lead should be locked successfully.');
        Test.startTest();
        LeadReviveController.forceUnlockException = true;
        List<String> results = LeadReviveController.reviveLeads(new List<Id>{leadRecord.Id});
        LeadReviveController.forceUnlockException = false;
        Test.stopTest();
    }
    
    @IsTest
    static void testMainExceptionCatchBlock() {
        Lead leadRecord = CommonDataTest.getLead('Main Exception Lead', ConstantUtility.ACTIVE, ConstantUtility.Approved, null);
        insert leadRecord;
        Test.startTest();
        LeadReviveController.forceMainException = true;
        List<String> results = LeadReviveController.reviveLeads(new List<Id>{leadRecord.Id});
        LeadReviveController.forceMainException = false;
        Test.stopTest();
        System.assertEquals(2, results.size());
    }
}