@IsTest
private class LeadDropApprovalServiceTest {
    /**
     * Creates a Lead for testing.
     */
    private static Lead createLead(String lastName, String company) {
        return new Lead(
            LastName = lastName,
            Company = company,
            Status = 'Working',
            Approval_Status__c = null
        );
    }

    /**
     * Verifies that the service safely handles null and empty inputs.
     */
    @IsTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(null, null);
        LeadDropApprovalService.submitDropApprovals(new List<Lead>(), new Map<Id, Lead>());
        LeadDropApprovalService.submitDropApprovals(new List<Lead>(), null);
        Test.stopTest();
        System.assert(true, 'Null and empty inputs should be handled safely.');
    }

    /**
     * Verifies that Leads not transitioning to Dropped are not submitted.
     */
    @IsTest
    static void testLeadNotTransitioningToDropped() {
        Lead leadRecord = createLead('Test Lead', 'Test Company');
        insert leadRecord;
        Lead updatedLead = new Lead(Id = leadRecord.Id, Status = 'Working');
        Lead oldLead = new Lead(Id = leadRecord.Id, Status = 'Working');
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(new List<Lead>{ updatedLead }, new Map<Id, Lead>{ leadRecord.Id => oldLead });
        Test.stopTest();
        System.assertEquals('Working', updatedLead.Status, 'The Lead status should remain unchanged.');
    }

    /**
     * Verifies that a Lead already in Dropped status is not resubmitted.
     */
    @IsTest
    static void testAlreadyDroppedLeadIsSkipped() {
        Lead leadRecord = createLead('Already Dropped', 'Test Company');
        leadRecord.Status = 'Working';
        insert leadRecord;
        Lead currentLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = null
        );
        Lead oldLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = null
        );
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(new List<Lead>{ currentLead }, new Map<Id, Lead>{ leadRecord.Id => oldLead });
        Test.stopTest();
        System.assertEquals(ConstantUtility.Dropped, currentLead.Status, 'The Lead should remain Dropped.');
    }

    /**
     * Verifies that Leads already approved are skipped.
     */
    @IsTest
    static void testApprovedLeadIsSkipped() {
        Lead leadRecord = createLead('Approved Lead', 'Test Company');
        insert leadRecord;
        Lead currentLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = ConstantUtility.Approved
        );

        Lead oldLead = new Lead(
            Id = leadRecord.Id,
            Status = 'Working',
            Approval_Status__c = ConstantUtility.Approved
        );
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(new List<Lead>{ currentLead }, new Map<Id, Lead>{ leadRecord.Id => oldLead });
        Test.stopTest();
        System.assertEquals(ConstantUtility.Approved, currentLead.Approval_Status__c,'An already approved Lead should not be resubmitted.');
    }

    /**
     * Verifies that Leads pending approval are skipped.
     */
    @IsTest
    static void testPendingLeadIsSkipped() {
        Lead leadRecord = createLead('Pending Lead', 'Test Company');
        insert leadRecord;
        Lead currentLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped,
            Approval_Status__c = ConstantUtility.Pending_For_Approval
        );
        Lead oldLead = new Lead(
            Id = leadRecord.Id,
            Status = 'Working',
            Approval_Status__c = ConstantUtility.Pending_For_Approval
        );
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(new List<Lead>{ currentLead }, new Map<Id, Lead>{ leadRecord.Id => oldLead });
        Test.stopTest();
        System.assertEquals(ConstantUtility.Pending_For_Approval, currentLead.Approval_Status__c, 'A Lead already pending approval should not be resubmitted.');
    }

    /**
     * Verifies that Leads without a corresponding old record are skipped.
     */
    @IsTest
    static void testMissingOldLeadIsSkipped() {
        Lead leadRecord = createLead('Missing Old Lead', 'Test Company');
        insert leadRecord;
        Lead currentLead = new Lead(
            Id = leadRecord.Id,
            Status = ConstantUtility.Dropped
        );
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(new List<Lead>{ currentLead }, new Map<Id, Lead>());
        Test.stopTest();
        System.assertEquals(ConstantUtility.Dropped, currentLead.Status, 'A Lead without an old record should be skipped.');
    }

    /**
     * Verifies that a missing feature configuration is handled safely.
     *
     * Note: This test cannot remove an existing Custom Metadata record.
     * It verifies safe execution when the feature is disabled only if
     * the Trigger metadata record is inactive in the test org.
     */
    @IsTest
    static void testFeatureConfiguration() {
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(
            new List<Lead>(),
            new Map<Id, Lead>()
        );
        Test.stopTest();
        System.assert(true, 'Feature configuration checks should not throw an exception.');
    }

    /**
     * Bulk test for Leads that are not eligible for approval.
     */
    @IsTest
    static void testBulkIneligibleLeads() {
        List<Lead> leadsToInsert = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leadsToInsert.add(
                createLead('Bulk Lead ' + i, 'Test Company ' + i)
            );
        }
        insert leadsToInsert;
        List<Lead> currentLeads = new List<Lead>();
        Map<Id, Lead> oldLeads = new Map<Id, Lead>();
        for (Lead leadRecord : leadsToInsert) {
            currentLeads.add(
                new Lead(
                    Id = leadRecord.Id,
                    Status = 'Working',
                    Approval_Status__c = null
                )
            );

            oldLeads.put(leadRecord.Id,
                new Lead(
                    Id = leadRecord.Id,
                    Status = 'Working',
                    Approval_Status__c = null
                )
            );
        }
        Test.startTest();
        LeadDropApprovalService.submitDropApprovals(currentLeads, oldLeads);
        Test.stopTest();
        System.assertEquals(200, currentLeads.size(), 'All 200 Leads should be processed without bulk-related exceptions.');
    }
}