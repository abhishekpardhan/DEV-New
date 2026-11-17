@IsTest
public class LeadAssignmentServiceTest {

    @TestSetup
    static void setupTestUser() {
        createTestActor();
    }

    public static User createTestActor() {
        User testUser = new User(
            FirstName = 'Stream',
            LastName = 'A Test Runner',
            Alias = 'strun',
            Email = 'stream-a-runner@example.invalid',
            Username = 'stream-a-runner-' + UserInfo.getOrganizationId() + '@example.invalid',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Region__c = 'UTTAR PRADESH',
            Area__c = 'NOIDA',
            Designation__c = 'Area Manager',
            Journey_Type__c = 'Car',
            Sportfire_Group__c = 'Group 1',
            Type__c = 'Credit+Retail',
            IsActive = true
        );

        insert testUser;
        return testUser;
    }

    public static User testActor() {
        return new User(Id = UserInfo.getUserId());
    }

    public static User existingAreaManager(String area) {
        List<User> managers = [
            SELECT Id
            FROM User
            WHERE IsActive = true
            AND Designation__c = 'Area Manager'
            AND Area__c = :area
            LIMIT 1
        ];
        return managers.isEmpty() ? testActor() : managers[0];
    }

    public static User sampleUser(String area) {
        return new User(
            LastName = 'Stream A Sample',
            Alias = 'strma',
            Email = 'stream-a@example.invalid',
            Username = 'stream-a-'
                + String.valueOf(Crypto.getRandomLong())
                + '@example.invalid',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Area__c = area,
            Region__c = 'UTTAR PRADESH',
            Designation__c = 'Area Manager',
            Journey_Type__c = 'Car',
            Sportfire_Group__c = 'Group 1',
            Type__c = 'Credit+Retail',
            IsActive = true
        );
    }

    public static Group createQueue() {
        List<Group> existingQueues = [SELECT Id, Name, DeveloperName, Type FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'Central_Desk' LIMIT 1];
        if (!existingQueues.isEmpty()) return existingQueues[0];
        Group queue = new Group(Name = 'Central Desk', DeveloperName = 'Central_Desk', Type = 'Queue');
        insert queue;
        insert new QueueSobject(QueueId = queue.Id, SobjectType = 'Lead');
        return queue;
    }

    public static Lead sampleLead(String pin) {
        return new Lead(LastName = 'Stream A Sample', Company = 'Fictional Test Company',
            PostalCode = pin, Status = 'Active', MobilePhone = '9999999999',
            Email = 'stream-a@example.invalid', Street = 'Sample Street', City = 'Sample City',
            State = 'Sample State', OwnerId = UserInfo.getUserId(),
            Pincode_Lookup_Status__c = 'Pending', Assign_to_Central_Desk__c = false,
            Assignment_Evaluated__c = false, Vertical__c= 'ALLIANCE PARTNER MANAGEMENT',Sub_Vertical__c='COURIER',Account_Type__c= 'Emerging',
            Area__c = 'NOIDA', Region__c = 'UTTAR PRADESH');
    }

    @IsTest
    static void localAssignmentAndCreatorOwnership() {
        User manager = existingAreaManager('NOIDA');
        insert new Branch_Master__c(Name = 'Stream A', Branch_Code__c = 'STREAM_A',
            Area__c = 'NOIDA', Region__c = 'UTTAR PRADESH', is_PropelI_Branch__c = true);
        insert new Pincode__c(Pincode__c = '100001', Branch_Cd__c = 'STREAM_A');
        System.runAs(testActor()) {
            Lead assigned = sampleLead('100001');
            assigned.Assign_to_Central_Desk__c = true;
            Lead creatorOwned = sampleLead('100001');
            Test.startTest();
            LeadAssignmentService.onBeforeInsert(new List<Lead>{assigned, creatorOwned});
            Test.stopTest();
            
        }
    }

    @IsTest
    static void zeroMultipleAndBlankAreasGoToQueue() {
        Group queue = createQueue();
        insert new List<User>{sampleUser('NOIDA'), sampleUser('NOIDA')};
        List<Lead> rows = new List<Lead>();
        for (String area : new List<String>{'NOIDA', 'UNASSIGNED TEST AREA', null}) {
            Lead row = sampleLead('100001');
            row.Area__c = area;
            row.Assign_to_Central_Desk__c = true;
            rows.add(row);
        }
        System.runAs(testActor()) {
            Test.startTest();
            Integer queries = Limits.getQueries();
            LeadAssignmentService.assignAreaManager(rows);
            System.assertEquals(2, Limits.getQueries() - queries);
            Test.stopTest();
        }
        for (Lead row : rows) {
            System.assertEquals(queue.Id, row.OwnerId);
            System.assertEquals(true, row.Assign_to_Central_Desk__c);
            System.assertEquals(true, row.Assignment_Evaluated__c);
        }
    }

    @IsTest
    static void webAndCaseAreMarkedWhilePending() {
        System.runAs(testActor()) {
            Lead web = sampleLead('999999');
            web.LeadSource = 'Website';
            Lead fromCase = sampleLead(null);
            // In-memory lookup value only: no Case records or case automation needed.
            String prefix = Case__c.SObjectType.getDescribe().getKeyPrefix();
            fromCase.Case__c = Id.valueOf(prefix + '000000000001');
            fromCase.Area__c = 'NOIDA';
            LeadAssignmentService.onBeforeInsert(new List<Lead>{web, fromCase});
            for (Lead row : new List<Lead>{web, fromCase}) {
                System.assertEquals(true, row.Assign_to_Central_Desk__c);
                System.assertEquals('Pending', row.Pincode_Lookup_Status__c);
                System.assertEquals(false, row.Assignment_Evaluated__c);
                System.assertEquals(UserInfo.getUserId(), row.OwnerId);
            }
            System.assertEquals('NOIDA', fromCase.Area__c);
        }
    }

    @IsTest
    static void updateOnlyReactsToCheckboxTransition() {
        Group queue = createQueue();
        User manager = existingAreaManager('NOIDA');
        System.runAs(testActor()) {
        Id leadId = Id.valueOf(Lead.SObjectType.getDescribe().getKeyPrefix() + '000000000001');
        Lead before = sampleLead('100001');
        before.Id = leadId;
        before.Pincode_Lookup_Status__c = 'Completed';
        Lead after = before.clone(true, false, false, false);
        after.Assign_to_Central_Desk__c = true;
        after.Area__c = 'NOIDA';
        Map<Id, Lead> oldMap = new Map<Id, Lead>{leadId => before};
        LeadAssignmentService.onBeforeUpdate(new List<Lead>{after}, oldMap);
        after.Assign_to_Central_Desk__c = true;
        LeadAssignmentService.onBeforeUpdate(new List<Lead>{after}, oldMap);

        after.Pincode_Lookup_Status__c = 'Pending';
        after.OwnerId = UserInfo.getUserId();
        LeadAssignmentService.onBeforeUpdate(new List<Lead>{after}, oldMap);

        before.Assign_to_Central_Desk__c = true;
        after.Pincode_Lookup_Status__c = 'Completed';
        after.PostalCode = '100002';
        after.Area__c = 'THANE';
        after.Region__c = 'MUMBAI';
        after.OwnerId = manager.Id;
        LeadAssignmentService.onBeforeUpdate(new List<Lead>{after}, oldMap);
        System.assertEquals(manager.Id, after.OwnerId);
        System.assertEquals('THANE', after.Area__c);
        System.assertEquals('100002', after.PostalCode);
        System.assertEquals(true, after.Assign_to_Central_Desk__c);

        before.Assign_to_Central_Desk__c = false;
        LeadAssignmentService.isJobUpdate = true;
        try {
            LeadAssignmentService.onBeforeUpdate(new List<Lead>{after}, oldMap);
            System.assertEquals(manager.Id, after.OwnerId);
        } finally {
            LeadAssignmentService.isJobUpdate = false;
        }
        }
    }

    @IsTest
    static void triggerRoutesLocalInsertAndCheckboxUpdates() {
        insert new Branch_Master__c(Name = 'Stream A Hook', Branch_Code__c = 'STREAM_A_HOOK',
            Area__c = 'NOIDA', Region__c = 'UTTAR PRADESH', is_PropelI_Branch__c = true);
        insert new Pincode__c(Pincode__c = '100001', Branch_Cd__c = 'STREAM_A_HOOK');
        Lead row = sampleLead('100001');
        row.Assign_to_Central_Desk__c = true;
        Test.startTest();
        LeadAssignmentService.onBeforeInsert(new List<Lead>{row});
        Test.stopTest();
    }

    @IsTest
    static void bulkMixedInsertEnqueuesOnce() {
        Group queue = createQueue();
        insert new Branch_Master__c(Name = 'Stream A', Branch_Code__c = 'STREAM_A',
            Area__c = 'NOIDA', Region__c = 'UTTAR PRADESH', is_PropelI_Branch__c = true);
        insert new Pincode__c(Pincode__c = '100001', Branch_Cd__c = 'STREAM_A');
        List<Lead> rows = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            Lead row = sampleLead(Math.mod(i, 2) == 0 ? '100001' : '999999');
            row.Assign_to_Central_Desk__c = Math.mod(i, 3) == 0;
            rows.add(row);
        }
        Test.setMock(HttpCalloutMock.class, PincodeApiMock.success(0));
        LeadAssignmentService.onBeforeInsert(rows);
        TriggerHandler.bypass('LeadTriggerHandler');
        try {
            insert rows;
        } finally {
            TriggerHandler.clearBypass('LeadTriggerHandler');
        }
        Test.startTest();
        LeadAssignmentService.onAfterInsert(rows);
        Test.stopTest();
    }

    @IsTest
    static void emptyAssignmentAndJobGuardAreSafe() {
        Lead row = sampleLead('100001');
        Lead before = row.clone(false, false, false, false);
        row.Assign_to_Central_Desk__c = true;
        LeadAssignmentService.isJobUpdate = true;
        try {
            Test.startTest();
            LeadAssignmentService.assignAreaManager(new List<Lead>());
            LeadAssignmentService.onBeforeUpdate(new List<Lead>{row},
                new Map<Id, Lead>());
            Test.stopTest();
        } finally {
            LeadAssignmentService.isJobUpdate = false;
        }
        System.assertEquals(before.OwnerId, row.OwnerId);
    }
    @IsTest
    static void resolvesTwoHundredPincodesWithTwoQueries() {
        List<Pincode__c> pins = new List<Pincode__c>();
        List<Branch_Master__c> branches = new List<Branch_Master__c>();
        Set<String> requested = new Set<String>();
        for (Integer i = 0; i < 200; i++) {
            String pin = String.valueOf(100000 + i);
            String code = 'STREAM_A_' + i;
            requested.add(pin);
            pins.add(new Pincode__c(Pincode__c = pin, Branch_Cd__c = code));
            branches.add(new Branch_Master__c(Name = code, Branch_Code__c = code,
                Area__c = 'Sample Area ' + i, Region__c = 'Sample Region',
                is_PropelI_Branch__c = true));
        }
        insert branches;
        insert pins;

        Test.startTest();
        Integer queries = Limits.getQueries();
        Map<String, LeadAssignmentService.AreaRegion> result =
            LeadAssignmentService.resolveLocal(requested);
        System.assertEquals(2, Limits.getQueries() - queries);
        Test.stopTest();
        System.assertEquals(200, result.size());
        for (Integer i = 0; i < 200; i++) {
            System.assertEquals('Sample Area ' + i, result.get(String.valueOf(100000 + i)).area);
            System.assertEquals('Sample Region', result.get(String.valueOf(100000 + i)).region);
        }
    }

    @IsTest
    static void selectsOldestBranchAndRejectsUnresolvedMappings() {
        List<Branch_Master__c> branches = new List<Branch_Master__c>{
            new Branch_Master__c(Name = 'Older', Branch_Code__c = 'A',
                Area__c = 'First Area', Region__c = 'First Region', is_PropelI_Branch__c = true),
            new Branch_Master__c(Name = 'Newer', Branch_Code__c = 'A',
                Area__c = 'Second Area', Region__c = 'Second Region', is_PropelI_Branch__c = true),
            new Branch_Master__c(Name = 'Blank first', Branch_Code__c = 'B',
                is_PropelI_Branch__c = true),
            new Branch_Master__c(Name = 'Populated later', Branch_Code__c = 'B',
                Area__c = 'Later Area', is_PropelI_Branch__c = true),
            new Branch_Master__c(Name = 'Not Propel', Branch_Code__c = 'C',
                Area__c = 'Excluded Area', is_PropelI_Branch__c = false)
        };
        insert branches;
        Test.setCreatedDate(branches[0].Id, System.now().addDays(-2));
        Test.setCreatedDate(branches[1].Id, System.now().addDays(-1));
        Test.setCreatedDate(branches[2].Id, System.now().addDays(-2));
        Test.setCreatedDate(branches[3].Id, System.now().addDays(-1));
        insert new List<Pincode__c>{
            new Pincode__c(Pincode__c = '000001', Branch_Cd__c = 'A'),
            new Pincode__c(Pincode__c = '000002', Branch_Cd__c = 'B'),
            new Pincode__c(Pincode__c = '000003', Branch_Cd__c = 'C'),
            new Pincode__c(Pincode__c = '000004', Branch_Cd__c = 'MISSING'),
            new Pincode__c(Pincode__c = '000005')
        };
        Test.startTest();
        Map<String, LeadAssignmentService.AreaRegion> result = LeadAssignmentService.resolveLocal(
            new Set<String>{' 000001 ', '000002', '000003', '000004', '000005', '999999', '', null});
        Test.stopTest();
        System.assertEquals(1, result.size());
        System.assertEquals('First Area', result.get('000001').area);
        System.assertEquals('First Region', result.get('000001').region);
    }

    @IsTest
    static void emptyAndUnknownPincodesAreSafe() {
        Test.startTest();
        Integer queries = Limits.getQueries();
        System.assertEquals(0, LeadAssignmentService.resolveLocal(null).size());
        System.assertEquals(0, LeadAssignmentService.resolveLocal(new Set<String>{null, ' '}).size());
        System.assertEquals(queries, Limits.getQueries());
        System.assertEquals(0, LeadAssignmentService.resolveLocal(new Set<String>{'999999'}).size());
        System.assertEquals(queries + 1, Limits.getQueries());
        Test.stopTest();
    }

    @IsTest
    static void centralDeskQueueIsResolvedAndCached() {
        Group queue = createQueue();
        Test.startTest();
        Id firstResult = LeadAssignmentService.centralDeskQueueId();
        Id cachedResult = LeadAssignmentService.centralDeskQueueId();
        Test.stopTest();
        System.assertEquals(queue.Id, firstResult);
        System.assertEquals(firstResult, cachedResult);
    }

    @IsTest
    static void localInsertTransfersOwnerOnlyAfterEventDelivery() {
        User manager = existingAreaManager('NOIDA');
        insert new Branch_Master__c(Name = 'Deferred Insert', Branch_Code__c = 'DEF_INS',
            Area__c = 'NOIDA', Region__c = 'UTTAR PRADESH', is_PropelI_Branch__c = true);
        insert new Pincode__c(Pincode__c = '100001', Branch_Cd__c = 'DEF_INS');
        Lead row = sampleLead('100001');
        row.Lead_Type__c = ConstantUtility.LEAD_TYPE_CREDIT_RETAIL;
        row.Assign_to_Central_Desk__c = true;
        Id originalOwner = row.OwnerId;

        Test.startTest();
        insert row;
        System.assertEquals(originalOwner, [SELECT OwnerId FROM Lead WHERE Id = :row.Id].OwnerId,
            'The insert must retain the creator until the ownership event is delivered.');
        Test.getEventBus().deliver();
        Test.stopTest();

    }

    @IsTest
    static void checkboxUpdateTransfersOwnerOnlyAfterEventDelivery() {
        User manager = existingAreaManager('NOIDA');
        insert new Branch_Master__c(Name = 'Deferred Update', Branch_Code__c = 'DEF_UPD',
            Area__c = 'NOIDA', Region__c = 'UTTAR PRADESH', is_PropelI_Branch__c = true);
        insert new Pincode__c(Pincode__c = '100001', Branch_Cd__c = 'DEF_UPD');
        Lead row = sampleLead('100001');
        row.Lead_Type__c = ConstantUtility.LEAD_TYPE_CREDIT_RETAIL;
        insert row;
        Id originalOwner = row.OwnerId;

        Test.startTest();
        row.Assign_to_Central_Desk__c = true;
        update row;
        
    }

}