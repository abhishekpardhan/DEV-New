@IsTest
private class LeadReviveControllerTest {
    /**
     * Creates a Lead with the minimum standard required fields.
     */
    private static Lead createLead(String lastName, String status, String approvalStatus) {
        Lead leadRecord = new Lead(
            LastName = lastName,
            Company = 'Test Company',
            Status = status,
            Approval_Status__c = approvalStatus
        );
        return leadRecord;
    }

    /**
     * Assigns a Permission Set that grants the Lead_Revive custom permission.
     *
     * Prerequisite:
     * At least one assignable Permission Set must grant the Lead_Revive
     * custom permission in the target org.
     */
    private static void assignLeadRevivePermission() {
        CustomPermission customPermission = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Lead_Revive' 
                                             LIMIT 1];
        Set<Id> permissionSetIds = new Set<Id>();
        for (SetupEntityAccess accessRecord : [SELECT ParentId FROM SetupEntityAccess 
                                               WHERE SetupEntityId = :customPermission.Id]) {
                                                   permissionSetIds.add(accessRecord.ParentId);
                                               }

        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Id IN :permissionSetIds 
                                              AND IsOwnedByProfile = false];
        System.assert(!permissionSets.isEmpty(), 'Configure an assignable Permission Set that grants the Lead_Revive custom permission.');
        Id permissionSetId = permissionSets[0].Id;
        Id currentUserId = UserInfo.getUserId();
        List<PermissionSetAssignment> existingAssignments = [SELECT Id FROM PermissionSetAssignment 
                                                             WHERE AssigneeId = :currentUserId 
                                                             AND PermissionSetId = :permissionSetId LIMIT 1];
        if (existingAssignments.isEmpty()) {
            PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = currentUserId, PermissionSetId = permissionSetId);
            insert assignment;
        }
    }

    /**
     * Verifies that null and empty inputs return an empty result list.
     */
    @IsTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        List<String> nullResult = LeadReviveController.reviveLeads(null);
        List<String> emptyResult = LeadReviveController.reviveLeads(new List<Id>());
        Test.stopTest();
        System.assertEquals(0, nullResult.size(), 'Null input should return an empty result list.');
        System.assertEquals(0, emptyResult.size(), 'Empty input should return an empty result list.');
    }

    /**
     * Verifies that users without the custom permission are denied.
     *
     * Run this test with a user who does not receive Lead_Revive
     * through their profile or assigned permission sets.
     */
    @IsTest
    static void testPermissionDenied() {
        Lead leadRecord = createLead('Permission Denied', ConstantUtility.Dropped, ConstantUtility.Approved);
        insert leadRecord;
        User testUser = createUserWithoutLeadRevivePermission();
        System.runAs(testUser) {
            Test.startTest();
            List<String> results = LeadReviveController.reviveLeads(new List<Id>{ leadRecord.Id });
            Test.stopTest();
            System.assertEquals(1, results.size(), 'One result should be returned for one input ID.');
            System.assertEquals(ConstantUtility.PERMISSION_ERROR, results[0], 'The user without permission should receive the permission error.');
        }
    }

    /**
     * Creates a test user using the current user's profile.
     */
    private static User createUserWithoutLeadRevivePermission() {
        Profile profileRecord = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Revive',
            Alias = 'revive',
            Email = 'revive.' + uniqueSuffix + '@example.com',
            Username = 'revive.' + uniqueSuffix + '@example.com',
            ProfileId = profileRecord.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        return testUser;
    }

    /**
     * Verifies that an eligible Approved + Dropped Lead is revived.
     */
    @IsTest
    static void testReviveApprovedDroppedLead() {
        assignLeadRevivePermission();
        Lead leadRecord = createLead('Approved Dropped', ConstantUtility.Dropped, ConstantUtility.Approved);
        leadRecord.Lead_Drop_Reason__c = 'Test drop reason';
        leadRecord.Please_Specify__c = 'Test specification';
        insert leadRecord;
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(new List<Id>{ leadRecord.Id });
        Test.stopTest();
        System.assertEquals(1, results.size(), 'One result should be returned.');
        System.assertEquals(ConstantUtility.SUCCESS_MESSAGE, results[0], 'The eligible Lead should be revived successfully.');
        Lead revivedLead = [SELECT Status, Approval_Status__c, Lead_Drop_Reason__c, Please_Specify__c FROM Lead 
                            WHERE Id = :leadRecord.Id];
        System.assertEquals(ConstantUtility.ACTIVE, revivedLead.Status, 'The Lead status should be changed to Active.');
        System.assertEquals(null, revivedLead.Approval_Status__c, 'Approval status should be cleared.');
        System.assertEquals(null, revivedLead.Lead_Drop_Reason__c, 'Lead drop reason should be cleared.');
        System.assertEquals(null, revivedLead.Please_Specify__c, 'Please Specify should be cleared.');
    }
    /**
     * Verifies that a Lead dropped by the Central Desk is eligible.
     */
    @IsTest
    static void testReviveCentralDeskDroppedLead() {
        assignLeadRevivePermission();
        Lead leadRecord = createLead('Central Desk Dropped', ConstantUtility.Dropped_By_Central_Desk, null);
        insert leadRecord;
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(new List<Id>{ leadRecord.Id });
        Test.stopTest();
        System.assertEquals(ConstantUtility.SUCCESS_MESSAGE, results[0], 'A Central Desk-dropped Lead should be revived successfully.');

        Lead revivedLead = [SELECT Status, Approval_Status__c FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals(ConstantUtility.ACTIVE, revivedLead.Status, 'The Lead should become Active.');
        System.assertEquals(null, revivedLead.Approval_Status__c, 'Approval status should be cleared.');
    }

    /**
     * Verifies that an ineligible Lead returns the configured error.
     */
    @IsTest
    static void testIneligibleLead() {
        assignLeadRevivePermission();
        Lead leadRecord = createLead('Ineligible Lead', ConstantUtility.ACTIVE, null);
        insert leadRecord;
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(new List<Id>{ leadRecord.Id });
        Test.stopTest();
        System.assertEquals(1, results.size(), 'One result should be returned.');
        System.assertEquals(ConstantUtility.INELIGIBLE_ERROR, results[0], 'A Lead that does not meet the eligibility criteria should be rejected.');
        Lead unchangedLead = [SELECT Status FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals(ConstantUtility.ACTIVE, unchangedLead.Status, 'An ineligible Lead should not be modified.');
    }

    /**
     * Verifies that an invalid ID returns the configured error.
     */
    @IsTest
    static void testInvalidRecordId() {
        assignLeadRevivePermission();
        Account accountRecord = new Account(Name = 'Invalid Lead ID Test');
        insert accountRecord;
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(new List<Id>{ accountRecord.Id });
        Test.stopTest();
        System.assertEquals(1, results.size(), 'One result should be returned.');
        System.assertEquals(ConstantUtility.INVALID_ID_ERROR, results[0], 'A non-Lead ID should return the invalid ID error.');
    }

    /**
     * Verifies that a null ID is handled and its position is preserved.
     */
    @IsTest
    static void testNullIdInInputList() {
        assignLeadRevivePermission();
        Lead leadRecord = createLead('Valid Lead', ConstantUtility.ACTIVE, null);
        insert leadRecord;
        List<Id> inputIds = new List<Id>{null, leadRecord.Id};
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(inputIds);
        Test.stopTest();
        System.assertEquals(2, results.size(), 'The output size should match the input size.');
        System.assertEquals(ConstantUtility.INVALID_ID_ERROR, results[0], 'The null ID should return the invalid ID error.');
        System.assertEquals(ConstantUtility.INELIGIBLE_ERROR, results[1], 'The valid but ineligible Lead should return the ineligible error.');
    }

    /**
     * Verifies that a deleted Lead returns the not-found error.
     */
    @IsTest
    static void testLeadNotFound() {
        assignLeadRevivePermission();
        Lead leadRecord = createLead('Deleted Lead', ConstantUtility.ACTIVE, null);
        insert leadRecord;
        Id deletedLeadId = leadRecord.Id;
        delete leadRecord;
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(new List<Id>{ deletedLeadId });
        Test.stopTest();
        System.assertEquals(1, results.size(),'One result should be returned.');
        System.assertEquals(ConstantUtility.NOT_FOUND_ERROR, results[0], 'A deleted Lead should return the not-found error.');
    }

    /**
     * Verifies that duplicate IDs preserve their positions in the output.
     */
    @IsTest
    static void testDuplicateLeadIds() {
        assignLeadRevivePermission();
        Lead leadRecord = createLead('Duplicate Lead', ConstantUtility.Dropped, ConstantUtility.Approved);
        insert leadRecord;
        List<Id> inputIds = new List<Id>{leadRecord.Id, leadRecord.Id};
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(inputIds);
        Test.stopTest();
        System.assertEquals(2, results.size(), 'The result must preserve duplicate input positions.');
        System.assertEquals(ConstantUtility.SUCCESS_MESSAGE, results[0], 'The first occurrence should report success.');
        System.assertEquals(ConstantUtility.SUCCESS_MESSAGE, results[1], 'The duplicate occurrence should return the same Lead result.');
        Lead revivedLead = [SELECT Status FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals(ConstantUtility.ACTIVE, revivedLead.Status, 'The duplicate ID should not prevent the Lead from being revived.');
    }

    /**
     * Verifies bulk processing of 200 Leads with mixed eligibility.
     */
    @IsTest
    static void testBulkMixedEligibility() {
        assignLeadRevivePermission();
        List<Lead> leadsToInsert = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            if (Math.mod(i, 2) == 0) {
                leadsToInsert.add(createLead('Eligible ' + i, ConstantUtility.Dropped, ConstantUtility.Approved));
            } else {
                leadsToInsert.add(createLead('Ineligible ' + i, ConstantUtility.ACTIVE, null));
            }
        }
        insert leadsToInsert;
        List<Id> inputIds = new List<Id>();
        for (Lead leadRecord : leadsToInsert) {
            inputIds.add(leadRecord.Id);
        }
        Test.startTest();
        List<String> results = LeadReviveController.reviveLeads(inputIds);
        Test.stopTest();
        System.assertEquals(200, results.size(), 'The controller should return one message per input ID.');
        Integer successCount = 0;
        Integer ineligibleCount = 0;
        for (Integer i = 0; i < results.size(); i++) {
            if (Math.mod(i, 2) == 0) {
                System.assertEquals(ConstantUtility.SUCCESS_MESSAGE, results[i], 'Eligible Leads should be revived.');
                successCount++;
            } else {
                System.assertEquals(ConstantUtility.INELIGIBLE_ERROR, results[i], 'Ineligible Leads should not be revived.');
                ineligibleCount++;
            }
        }
        System.assertEquals(100, successCount, 'Exactly 100 Leads should be revived.');
        System.assertEquals(100, ineligibleCount, 'Exactly 100 Leads should be rejected as ineligible.');
        Integer activeLeadCount = [SELECT COUNT() FROM Lead WHERE Id IN :inputIds AND Status = :ConstantUtility.ACTIVE];
        System.assertEquals(200, activeLeadCount, 'All 200 Leads should have Active status after processing.');
    }
}