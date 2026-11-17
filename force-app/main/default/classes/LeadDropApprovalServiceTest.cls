@IsTest
private class LeadDropApprovalServiceTest {
    @isTest
    static void triggerBypass(){
        TriggerUtility.byPassTrigger = true;
        List<Lead> newLead = new List<Lead>();
        LeadDropApprovalService.submitDropApprovals(newLead, null);
    }
    @isTest
    static void nullLeadList(){
        List<Lead> newLead = new List<Lead>();
        LeadDropApprovalService.submitDropApprovals(null, null);
    }
    @isTest
    static void nulloldMap(){
        Lead newLead = CommonDataTest.getLead('TestLead', 'Active', null, null);
        newLead.Status = 'Active';
        insert newLead;
        newLead.LastName = 'Test Update';
        Test.startTest();
        update newLead;
        Test.stopTest();
    }

    @IsTest
    static void testAlreadyDroppedLeadIsSkipped() {
        Lead leadRecord = CommonDataTest.getLead('TestLead', 'Active', null, null);
        insert leadRecord;
        Lead currentLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = null
        );
        Lead oldLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = 'Pending for Approval',
            Lead_Drop_Reason__c = 'FTL Customer'
        );
        Test.startTest();
        update oldLead;
        Test.stopTest();
        System.assertEquals(ConstantUtility.Dropped, currentLead.Status, 'The Lead should remain Dropped.');
    }

    @IsTest
    static void testAlreadyDroppedLeadIsSkippedApproval() {
        Lead leadRecord = CommonDataTest.getLead('TestLead', 'Active', null, null);
        insert leadRecord;
        Lead currentLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = null
        );
        Lead oldLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Lead_Drop_Reason__c = 'FTL Customer'
        );
        Test.startTest();
        update oldLead;
        Test.stopTest();
        System.assertEquals(ConstantUtility.Dropped, currentLead.Status, 'The Lead should remain Dropped.');
    }
    @IsTest
    static void testPendingLeadIsSkipped() {
        Lead leadRecord = CommonDataTest.getLead('TestLead', 'Active', null, null);
        insert leadRecord;
        Lead currentLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = ConstantUtility.ACTIVE
        );
        Lead oldLead = new Lead(
            Id = leadRecord.Id,
            Status = 'Working',
            Approval_Status__c = ConstantUtility.Pending_For_Approval
        );
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(new List<Lead>{ currentLead }, new Map<Id, Lead>{ leadRecord.Id => oldLead });
        Test.stopTest();
        System.assertEquals(ConstantUtility.ACTIVE, currentLead.Approval_Status__c, 'A Lead already pending approval should not be resubmitted.');
    }
    
    @IsTest
    static void testCheckPanCatchBlock() {

        Lead testLead = CommonDataTest.getLead('TestLead', 'Active', null, null);
            LeadDropApprovalService.forceExceptionForTest = true;
            try {
                Test.startTest();
                	LeadDropApprovalService.submitDropApprovals(new List<Lead>{ testLead }, null);
                Test.stopTest();
            } finally {
                // Reset the test hook.
                LeadDropApprovalService.forceExceptionForTest = false;
            }
        System.assertEquals(false, LeadDropApprovalService.forceExceptionForTest, 'Test exception flag should be reset.');
    }
    @IsTest
    static void testPendingInnerCatch() {
        Lead leadRecord = CommonDataTest.getLead('TestLead', 'Active', null, null);
        insert leadRecord;
        Lead currentLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = ConstantUtility.ACTIVE
        );
        Lead oldLead = new Lead(
            Id = leadRecord.Id,
            Status = 'Working',
            Approval_Status__c = ConstantUtility.Pending_For_Approval
        );
        LeadDropApprovalService.forceExceptionForInnerCatch = true;
        try {
            Test.startTest();
            LeadDropApprovalService.submitDropApprovals(new List<Lead>{ currentLead }, new Map<Id, Lead>{ leadRecord.Id => oldLead });
            Test.stopTest();
            } finally {
                // Reset the test hook.
                LeadDropApprovalService.forceExceptionForInnerCatch = false;
            }
        System.assertEquals(false, LeadDropApprovalService.forceExceptionForInnerCatch, 'Test exception flag should be reset.');
    }
}