@IsTest
private class LeadDropApprovalServiceTest {
    private static Lead createLead(String lastName, String company) {
        return new Lead(
            LastName = lastName,
            Company = company,
            Status = 'Active',
            Approval_Status__c = null,
            MobilePhone = '9282932829',
            Email = 'test@mail.com',
            Street = 'Test Street',
            City = 'Test City',
            State = 'Test State',
            PostalCode = '283992'
        );
    }
    
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
        Lead newLead = createLead('Dropped', 'Test Company');
        newLead.Status = 'Active';
        insert newLead;
        newLead.LastName = 'Test Update';
        Test.startTest();
        update newLead;
        Test.stopTest();
    }
    
    @IsTest
    static void testAlreadyDroppedLeadIsSkipped() {
        Lead leadRecord = createLead('Already Dropped', 'Test Company');
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
        Lead leadRecord = createLead('Already Dropped', 'Test Company');
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
        Lead leadRecord = createLead('Pending Lead', 'Test Company');
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
}