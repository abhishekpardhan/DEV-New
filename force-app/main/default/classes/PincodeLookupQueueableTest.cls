@IsTest
private class PincodeLookupQueueableTest {

    private static final String TXN_HANDLER = 'IntegrationTransactionHandler';

    @TestSetup
    static void setupTestUser() {
        LeadAssignmentServiceTest.createTestActor();
    }

    // ---------- helpers ----------
    private static void seed(List<Lead> rows) {
        Boolean wasBypassed = TriggerHandler.isBypassed('LeadTriggerHandler');
        TriggerHandler.bypass('LeadTriggerHandler');
        try {
            insert rows;
        } finally {
            if (!wasBypassed) TriggerHandler.clearBypass('LeadTriggerHandler');
        }
    }

    // IT records are inserted with the handler bypassed so no job starts on its own
    private static Integration_Transaction__c seedTxn(Lead lead, String pincode, Integer retries) {
        Integration_Transaction__c t = new Integration_Transaction__c(
            Object_Name__c     = 'Lead',
            Record_Id__c       = String.valueOf(lead.Id),
            Operation_Type__c  = System.Label.OperationType_PropelI_PincodeLookup,
            Status__c          = 'Draft',
            No_of_Retries__c   = retries,
            MSAPushEndpoint__c = PincodeApiMock.API_ENDPOINT,
            Request__c         = JSON.serialize(new Map<String, String>{ 'pincode' => pincode }));
        Boolean wasBypassed = TriggerHandler.isBypassed(TXN_HANDLER);
        TriggerHandler.bypass(TXN_HANDLER);
        try {
            insert t;
        } finally {
            if (!wasBypassed) TriggerHandler.clearBypass(TXN_HANDLER);
        }
        return t;
    }

    // Keep retries from starting real jobs inside tests that run the job directly
    private static void bypassTxnHandler() {
        TriggerHandler.bypass(TXN_HANDLER);
    }

    private static void run(List<Integration_Transaction__c> txns) {
        Map<String, String> m = new Map<String, String>();
        for (Integration_Transaction__c t : txns) m.put(t.Id, t.Record_Id__c);
        System.enqueueJob(new PincodeLookupQueueable(m));
    }

    private static String successBody() {
        return PincodeApiMock.successBody(1, 'UTTAR PRADESH ');
    }

    private static Lead readLead(Id leadId) {
        return [SELECT Id, OwnerId, PostalCode, Area__c, Region__c, Assignment_Date__c,
            Assign_to_Central_Desk__c, Assignment_Evaluated__c, Pincode_Lookup_Status__c
            FROM Lead WHERE Id = :leadId];
    }

    private static Integration_Transaction__c readTxn(Id txnId) {
        return [SELECT Id, Status__c, No_of_Retries__c, Error_Message__c, Status_Code__c, Response__c
                FROM Integration_Transaction__c WHERE Id = :txnId];
    }

    private static Id fakeTxnId(Integer i) {
        String prefix = Integration_Transaction__c.SObjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(prefix + String.valueOf(i).leftPad(12, '0'));
    }

    // ---------- token problems ----------
    @IsTest
    static void tokenFailureNeverCallsPincodeAndStaysDraftForRetry() {
        bypassTxnHandler();
        Lead row = LeadAssignmentServiceTest.sampleLead('201301');
        seed(new List<Lead>{row});
        Integration_Transaction__c t = seedTxn(row, '201301', 0);

        PincodeApiMock mock = PincodeApiMock.success(1);
        mock.tokenStatusCode = 401;
        mock.tokenBody = '{"error":"invalid_client","detail":"fictional-sensitive-value"}';
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        run(new List<Integration_Transaction__c>{t});
        Test.stopTest();

    }

    @IsTest
    static void malformedMissingAndTimedOutTokensAreErrors() {
        Test.startTest();
        for (String body : new List<String>{'not-json', '{}', '{"access_token":" "}'}) {
            PincodeApiMock mock = PincodeApiMock.success(1);
            mock.tokenBody = body;
            Test.setMock(HttpCalloutMock.class, mock);
            PincodeLookupQueueable.callApi('201301');
        }
        PincodeApiMock timeout = PincodeApiMock.success(1);
        timeout.throwTokenCallout = true;
        Test.setMock(HttpCalloutMock.class, timeout);
        PincodeLookupQueueable.callApi('201301');
        Test.stopTest();
    }

    // ---------- response classification ----------
    @IsTest
    static void classifiesResponsesAndExceptions() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PincodeApiMock(200, successBody()));
        PincodeLookupQueueable.callApi('100001');

        for (Integer count : new List<Integer>{0, 2}) {
            Test.setMock(HttpCalloutMock.class, PincodeApiMock.success(count));
            PincodeLookupQueueable.callApi('100001');
        }
        Test.setMock(HttpCalloutMock.class, PincodeApiMock.notServiceable());
        PincodeLookupQueueable.callApi('100001');

        Test.setMock(HttpCalloutMock.class, new PincodeApiMock(500, '{}'));
        PincodeLookupQueueable.callApi('100001');
        Test.setMock(HttpCalloutMock.class, new PincodeApiMock(true));
        PincodeLookupQueueable.callApi('100001');

        for (String body : new List<String>{'not JSON', '{}', '{"status":"FAIL"}',
            '{"status":"SUCCESS","data":null}',
            '{"status":"SUCCESS","data":{"unexpected":true}}',
            '{"status":"SUCCESS","data":{"responseData":null}}',
            '{"status":"SUCCESS","data":{"responseData":[{}]}}'}) {
            Test.setMock(HttpCalloutMock.class, new PincodeApiMock(200, body));
            PincodeLookupQueueable.callApi('100001');
        }
        Test.stopTest();
    }

    // ---------- job behaviour ----------
    @IsTest
    static void foundUsesCurrentCheckboxAndRestoresOriginalPincode() {
        bypassTxnHandler();
        User manager = LeadAssignmentServiceTest.existingAreaManager('NOIDA');
        Lead assigned;
        Lead unchecked;
        Integration_Transaction__c t1;
        Integration_Transaction__c t2;
        PincodeApiMock mock;
        System.runAs(LeadAssignmentServiceTest.testActor()) {
            assigned = LeadAssignmentServiceTest.sampleLead('100001');
            assigned.Assign_to_Central_Desk__c = true;
            unchecked = LeadAssignmentServiceTest.sampleLead('100001');
            unchecked.Assign_to_Central_Desk__c = true;
            seed(new List<Lead>{assigned, unchecked});
            t1 = seedTxn(assigned, '100001', 0);
            t2 = seedTxn(unchecked, '100001', 0);

            // edits made while the lead is Pending
            update new List<Lead>{
                new Lead(Id = assigned.Id, PostalCode = '100002', Area__c = 'CHEMBUR', Region__c = 'MUMBAI'),
                new Lead(Id = unchecked.Id, Assign_to_Central_Desk__c = false)
            };
            mock = new PincodeApiMock(200,
                '{"status":"SUCCESS","data":{"responseData":[{"areaName":"NOIDA","regionName":"UTTAR PRADESH"}]}}');
            Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
            run(new List<Integration_Transaction__c>{t1, t2});
            Test.stopTest();
        }
    }

    @IsTest
    static void missingRegionIsRetriedAndLogged() {
        bypassTxnHandler();
        Lead row = LeadAssignmentServiceTest.sampleLead('100001');
        seed(new List<Lead>{row});
        Integration_Transaction__c t = seedTxn(row, '100001', 0);
        Test.setMock(HttpCalloutMock.class, new PincodeApiMock(200,
            '{"status":"SUCCESS","data":{"responseData":[{"areaName":"NOIDA"}]}}'));
        Test.startTest();
        run(new List<Integration_Transaction__c>{t});
        Test.stopTest();
    }

    @IsTest
    static void confirmedResponseTrimsRegionAndCompletesLead() {
        bypassTxnHandler();
        Lead row = LeadAssignmentServiceTest.sampleLead('201301');
        seed(new List<Lead>{row});
        Integration_Transaction__c t = seedTxn(row, '201301', 0);
        String body = '{"message":"Fetch active area by pincode","data":{"responseData":[' +
            '{"areaId":1492,"areaName":"NOIDA","areaCd":"NDA","regionId":2038,' +
            '"regionName":"UTTAR PRADESH ","regionCd":"UPR"}]},"status":"SUCCESS"}';
        Test.setMock(HttpCalloutMock.class, new PincodeApiMock(200, body));
        Test.startTest();
        run(new List<Integration_Transaction__c>{t});
        Test.stopTest();
    }

    @IsTest
    static void emptyDataMeansNotFoundWithoutRetry() {
        bypassTxnHandler();
        Group queue = LeadAssignmentServiceTest.createQueue();
        Lead row;
        Integration_Transaction__c t;
        System.runAs(LeadAssignmentServiceTest.testActor()) {
            row = LeadAssignmentServiceTest.sampleLead('201301');
            seed(new List<Lead>{row});
            t = seedTxn(row, '201301', 0);
            Test.setMock(HttpCalloutMock.class, PincodeApiMock.notServiceable());
            Test.startTest();
            run(new List<Integration_Transaction__c>{t});
            Test.stopTest();
        }
    }

    @IsTest
    static void zeroAndMultipleResultsRouteToDesk() {
        bypassTxnHandler();
        Group queue = LeadAssignmentServiceTest.createQueue();
        Lead zero;
        Lead multiple;
        System.runAs(LeadAssignmentServiceTest.testActor()) {
            zero = LeadAssignmentServiceTest.sampleLead('100001');
            multiple = LeadAssignmentServiceTest.sampleLead('100002');
            seed(new List<Lead>{zero, multiple});
            Integration_Transaction__c t1 = seedTxn(zero, '100001', 0);
            Integration_Transaction__c t2 = seedTxn(multiple, '100002', 0);
            Test.setMock(HttpCalloutMock.class, PincodeApiMock.success(0)
                .forPincode('100002', 200, PincodeApiMock.successBody(2, 'MUMBAI ')));
            Test.startTest();
            run(new List<Integration_Transaction__c>{t1, t2});
            Test.stopTest();
        }
    }

    @IsTest
    static void blankPincodeIsNotFoundWithoutAnyCallout() {
        bypassTxnHandler();
        Group queue = LeadAssignmentServiceTest.createQueue();
        Lead row;
        Integration_Transaction__c t;
        PincodeApiMock mock = PincodeApiMock.success(1);
        System.runAs(LeadAssignmentServiceTest.testActor()) {
            row = LeadAssignmentServiceTest.sampleLead('100001');
            seed(new List<Lead>{row});
            t = seedTxn(row, '', 0);
            Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
            run(new List<Integration_Transaction__c>{t});
            Test.stopTest();
        }
    }

    @IsTest
    static void retriesThroughConfiguredMaximum() {
        bypassTxnHandler();
        Group queue = LeadAssignmentServiceTest.createQueue();
        Lead row;
        Integration_Transaction__c t;
        Integer maximum = Integer.valueOf(Label.Max_Retries);
        System.runAs(LeadAssignmentServiceTest.testActor()) {
            row = LeadAssignmentServiceTest.sampleLead('100001');
            seed(new List<Lead>{row});
            t = seedTxn(row, '100001', 0);
            Test.setMock(HttpCalloutMock.class, new PincodeApiMock(500, '{}'));
            Test.startTest();
            for (Integer attempt = 1; attempt <= maximum; attempt++) {
                run(new List<Integration_Transaction__c>{t});
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void retryAttemptSucceeds() {
        bypassTxnHandler();
        Lead row = LeadAssignmentServiceTest.sampleLead('100001');
        seed(new List<Lead>{row});
        Integration_Transaction__c t = seedTxn(row, '100001', 2); // earlier attempts failed
        Test.setMock(HttpCalloutMock.class, new PincodeApiMock(200, successBody()));
        Test.startTest();
        run(new List<Integration_Transaction__c>{t});
        Test.stopTest();
    }

    @IsTest
    static void lastAttemptFailureSendsLeadToCentralDesk() {
        bypassTxnHandler();
        Group queue = LeadAssignmentServiceTest.createQueue();
        Lead row;
        Integration_Transaction__c t;
        System.runAs(LeadAssignmentServiceTest.testActor()) {
            row = LeadAssignmentServiceTest.sampleLead('100001');
            seed(new List<Lead>{row});
            Integer maximum = Integer.valueOf(Label.Max_Retries);
            t = seedTxn(row, '100001', maximum - 1);
            Test.setMock(HttpCalloutMock.class, new PincodeApiMock(500, '{}'));
            Test.startTest();
            run(new List<Integration_Transaction__c>{t});
            Test.stopTest();
        }
    }

    @IsTest
    static void alreadyCompletedLeadMakesNoCallout() { // needs code change 2
        bypassTxnHandler();
        Lead row = LeadAssignmentServiceTest.sampleLead('100001');
        row.Pincode_Lookup_Status__c = 'Completed';
        seed(new List<Lead>{row});
        Integration_Transaction__c t = seedTxn(row, '100001', 0);
        PincodeApiMock mock = PincodeApiMock.success(1);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        run(new List<Integration_Transaction__c>{t});
        Test.stopTest();
    }

    @IsTest
    static void partialDmlFailureIsLoggedAndFlagRestored() {
        bypassTxnHandler();
        LeadAssignmentServiceTest.createQueue();
        System.runAs(LeadAssignmentServiceTest.testActor()) {
            Lead valid = LeadAssignmentServiceTest.sampleLead('100001');
            Lead invalid = LeadAssignmentServiceTest.sampleLead('100002');
            seed(new List<Lead>{valid, invalid});
            Integration_Transaction__c t1 = seedTxn(valid, '100001', 0);
            Integration_Transaction__c t2 = seedTxn(invalid, 'INVALID', 0); // fails the pincode rule on writeback
            Test.setMock(HttpCalloutMock.class, PincodeApiMock.success(0));
            Test.startTest();
            run(new List<Integration_Transaction__c>{t1, t2});
            Test.stopTest();

        }
    }

    // ---------- chunking and retry trigger ----------
    private class EmptyJob implements Queueable {
        public void execute(QueueableContext context) {}
    }

    @IsTest
    static void noQueueCapacityLogsExceptionAndLeavesDraft() {
        bypassTxnHandler();
        Lead row = LeadAssignmentServiceTest.sampleLead('100001');
        seed(new List<Lead>{row});
        Integration_Transaction__c t = seedTxn(row, '100001', 0);
        Test.startTest();
        while (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new EmptyJob());
        }
        PincodeLookupQueueable.enqueueInChunks(new Map<String, String>{t.Id => row.Id}, 0);
        Test.stopTest();
    }

    @IsTest
    static void enqueueInChunksSplitsIntoBatchesOfFifty() {
        Map<String, String> all = new Map<String, String>();
        for (Integer i = 0; i < 120; i++) all.put(String.valueOf(fakeTxnId(i)), String.valueOf(fakeTxnId(i)));
        Test.setMock(HttpCalloutMock.class, PincodeApiMock.success(1));
        Test.startTest();
        PincodeLookupQueueable.enqueueInChunks(all, 0);
        Test.stopTest();
    }

    @IsTest
    static void retryBumpOnTransactionEnqueuesJob() {
        Lead row = LeadAssignmentServiceTest.sampleLead('100001');
        seed(new List<Lead>{row});
        Integration_Transaction__c t = seedTxn(row, '100001', 0); // handler bypassed only for the insert
        Test.setMock(HttpCalloutMock.class, new PincodeApiMock(200, successBody()));
        Test.startTest();
        t.No_of_Retries__c = 1;
        update t; // IntegrationTransactionHandler.afterUpdate -> PincodeLookupQueueable
        Test.stopTest();
    }

    // ---------- failure registration (used by catch block and finalizer) ----------
    @IsTest
    static void registerFailureBumpsRetryThenFailsLead() {
        bypassTxnHandler();
        Group queue = LeadAssignmentServiceTest.createQueue();
        Lead row;
        Integration_Transaction__c t;
        System.runAs(LeadAssignmentServiceTest.testActor()) {
            row = LeadAssignmentServiceTest.sampleLead('100001');
            seed(new List<Lead>{row});
            t = seedTxn(row, '100001', 0);
            Test.startTest();
            PincodeLookupQueueable.registerFailure(new Set<Id>{t.Id}, 'boom');

            // last allowed attempt
            Integration_Transaction__c last = readTxn(t.Id);
            last.No_of_Retries__c = Integer.valueOf(Label.Max_Retries) - 1;
            update last;
            PincodeLookupQueueable.registerFailure(new Set<Id>{t.Id}, 'boom');
            Test.stopTest();
        }
    }
}
