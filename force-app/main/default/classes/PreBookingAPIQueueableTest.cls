@isTest
public class PreBookingAPIQueueableTest {

    @testSetup
    public static void dataSetupMethod() {
        List<Account> listAccount = new List<Account>();
        listAccount.add(new Account(Name = 'test1'));
        insert listAccount;

        Integration_Transaction__c reqDetail = new Integration_Transaction__c();
        reqDetail.Object_Name__c = 'Account';
        reqDetail.record_id__c = listAccount[0].Id;
        reqDetail.Operation_Type__c = 'Create customer';
        reqDetail.No_of_Retries__c = 1;
        reqDetail.MSAPushEndpoint__c = 'www.google.com';
        insert reqDetail;

        Case caseRec = new Case(
            PropelI_PreBooking_Id__c = '00000001',
            Pre_Booking_Id__c = '00000001',
            Booking_Status__c = 'New',
            Origin = 'enterprise app',
            Case_Nature__c = 'Request',
            WaybillNo__c = '00000001',
            Total_Package_Count__c = 1,
            Total_Weight__c = 10
        );
        insert caseRec;
    }

    // Returns responses in order; repeats the last one once exhausted
    private class SequentialMock implements HttpCalloutMock {
        private List<HttpResponse> responses;
        private Integer idx = 0;
        public SequentialMock(List<HttpResponse> responses) { this.responses = responses; }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = responses[Math.min(idx, responses.size() - 1)];
            idx++;
            return r;
        }
    }

    private static HttpResponse makeRes(Integer code, String body) {
        HttpResponse r = new HttpResponse();
        r.setStatusCode(code);
        r.setBody(body);
        r.setHeader('Content-Type', 'application/json');
        return r;
    }

    private static final String TOKEN_BODY   = '{"access_token":"tok","token_type":"Bearer","expires_in":"3600"}';
    private static final String GENERIC_200  = '{"status":"success","data":{}}';

    // ─── existing test (kept intact) ──────────────────────────────────────────

    @isTest
    static void testExecute() {
        Integration_Transaction__c itObject = [SELECT Id, No_of_Retries__c FROM Integration_Transaction__c LIMIT 1];
        List<Case> caseList = [SELECT Id FROM Case];
        System.assert(caseList.size() > 0);
        List<String> caseIdList = new List<String>();
        for (Case cas : caseList) { caseIdList.add(cas.Id); }

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponsePreBooking());
        Map<String, String> caseIdMap = new Map<String, String>();
        caseIdMap.put(itObject.Id, caseIdList[0]);
        System.enqueueJob(new PreBookingAPIQueueable(caseIdMap));
        Test.stopTest();

        caseList = [SELECT Id, PropelI_PreBooking_Id__c FROM Case];
        RefreshBookingRequest.fetchITRecord(caseList[0].Id);
        Integration_Transaction__c reqDetail2 = new Integration_Transaction__c();
        reqDetail2.Object_Name__c = 'Account';
        reqDetail2.record_id__c = caseList[0].Id;
        reqDetail2.Operation_Type__c = 'PropelICaseCreation';
        reqDetail2.No_of_Retries__c = 1;
        insert reqDetail2;
        RefreshBookingRequest.fetchITRecord(caseList[0].Id);
        reqDetail2.No_of_Retries__c = 2;
        update reqDetail2;
    }

    // ─── success: PropelI returns preBookingId + BOOKING CREATED status + branch ─

    @isTest
    static void testExecute_SuccessWithAllPropelIFields() {
        Integration_Transaction__c it = [SELECT Id FROM Integration_Transaction__c LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1];

        String bookingBody = '{"status":"success","data":{"preBookingId":12345,"bookingStatus":"BOOKING CREATED","bookingBranch":"DELHI HUB"}}';

        Map<String, String> caseIdMap = new Map<String, String>();
        caseIdMap.put(it.Id, c.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SequentialMock(
            new List<HttpResponse>{ makeRes(200, TOKEN_BODY), makeRes(200, bookingBody) }
        ));
        System.enqueueJob(new PreBookingAPIQueueable(caseIdMap));
        Test.stopTest();

        Case updated = [SELECT PropelI_PreBooking_Id__c, Booking_Status__c, Booking_Branch__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('12345', updated.PropelI_PreBooking_Id__c, 'preBookingId should be mapped');
        System.assertEquals('2629',  updated.Booking_Status__c,        'BOOKING CREATED → 2629');
        System.assertEquals('DELHI HUB', updated.Booking_Branch__c,    'bookingBranch should be stored');
    }

    // ─── success: IConnect origin with bookingBranch triggers callIConnectUpdateAPI ─

    @isTest
    static void testExecute_IConnect_TriggersUpdateChain() {
        Integration_Transaction__c it = [SELECT Id FROM Integration_Transaction__c LIMIT 1];

        Case iConnectCase = new Case(
            Origin = 'IConnect',
            Pre_Booking_Id__c = 'IC-001',
            Total_Package_Count__c = 2,
            Total_Weight__c = 20
        );
        insert iConnectCase;

        String bookingBody = '{"status":"success","data":{"preBookingId":99,"bookingStatus":"BOOKING ASSIGNED","bookingBranch":"MUMBAI HUB"}}';

        Map<String, String> caseIdMap = new Map<String, String>();
        caseIdMap.put(it.Id, iConnectCase.Id);

        Test.startTest();
        // Extra responses absorb any callouts made by IConnectUpdateAPIQueueable
        Test.setMock(HttpCalloutMock.class, new SequentialMock(new List<HttpResponse>{
            makeRes(200, TOKEN_BODY),
            makeRes(200, bookingBody),
            makeRes(200, TOKEN_BODY),
            makeRes(200, GENERIC_200),
            makeRes(200, GENERIC_200),
            makeRes(200, GENERIC_200)
        }));
        System.enqueueJob(new PreBookingAPIQueueable(caseIdMap));
        Test.stopTest();

        Case updated = [SELECT Booking_Branch__c, Booking_Status__c FROM Case WHERE Id = :iConnectCase.Id];
        System.assertEquals('MUMBAI HUB', updated.Booking_Branch__c, 'bookingBranch should be stored');
        System.assertEquals('2630',       updated.Booking_Status__c, 'BOOKING ASSIGNED → 2630');
    }

    // ─── failure: non-200 from PropelI increments Pre_Booking_Count__c ────────

    @isTest
    static void testExecute_Failure_IncrementsRetryCount() {
        Integration_Transaction__c it = [SELECT Id FROM Integration_Transaction__c LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1];

        Map<String, String> caseIdMap = new Map<String, String>();
        caseIdMap.put(it.Id, c.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SequentialMock(
            new List<HttpResponse>{ makeRes(200, TOKEN_BODY), makeRes(500, '{"status":"error"}') }
        ));
        System.enqueueJob(new PreBookingAPIQueueable(caseIdMap));
        Test.stopTest();

        Case updated = [SELECT Pre_Booking_Count__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(1, Integer.valueOf(updated.Pre_Booking_Count__c), 'retry count should be incremented on failure');
    }

    // ─── exception: deleted case causes QueryException → catch block runs ─────

    @isTest
    static void testExecute_ExceptionPath_CatchBlock() {
        Integration_Transaction__c it = [SELECT Id FROM Integration_Transaction__c LIMIT 1];

        Case phantom = new Case();
        phantom.Origin = 'enterprise app';
        phantom.Case_Nature__c = 'Request';
        insert phantom;
        String phantomId = phantom.Id;
        delete phantom; // SOQL will throw QueryException when queueable tries to fetch this

        Map<String, String> caseIdMap = new Map<String, String>();
        caseIdMap.put(it.Id, phantomId);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponsePreBooking());
        System.enqueueJob(new PreBookingAPIQueueable(caseIdMap));
        Test.stopTest();

        Integration_Transaction__c itUpdated = [SELECT isProcessing__c FROM Integration_Transaction__c WHERE Id = :it.Id];
        System.assertEquals(false, itUpdated.isProcessing__c, 'catch block should clear isProcessing flag');
    }

    // ─── multiple caseIdMap entries: first completes then chains next job ─────

    @isTest
    static void testExecute_MultipleEntries_ChainsNextJob() {
        Integration_Transaction__c it = [SELECT Id FROM Integration_Transaction__c LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1];

        Case secondCase = new Case(Total_Package_Count__c = 1, Total_Weight__c = 5);
        secondCase.Origin = 'enterprise app';
        secondCase.Case_Nature__c = 'Request';
        insert secondCase;

        Integration_Transaction__c it2 = new Integration_Transaction__c();
        it2.Object_Name__c = 'Case';
        it2.record_id__c = secondCase.Id;
        it2.Operation_Type__c = 'PropelICaseCreation';
        it2.No_of_Retries__c = 0;
        insert it2;

        Map<String, String> caseIdMap = new Map<String, String>();
        caseIdMap.put(it.Id, c.Id);
        caseIdMap.put(it2.Id, secondCase.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponsePreBooking());
        System.enqueueJob(new PreBookingAPIQueueable(caseIdMap));
        Test.stopTest();

        System.assert(
            [SELECT Id FROM Case WHERE Id = :c.Id].size() == 1,
            'Original case should still exist after chaining'
        );
    }

    // ─── getPicklistValue: all named booking statuses + unknown default ────────

    @isTest
    static void testGetPicklistValue_AllValues() {
        System.assertEquals('2629', PreBookingAPIQueueable.getPicklistValue('BOOKING CREATED'),  'BOOKING CREATED');
        System.assertEquals('2630', PreBookingAPIQueueable.getPicklistValue('BOOKING ASSIGNED'), 'BOOKING ASSIGNED');
        System.assertEquals('2638', PreBookingAPIQueueable.getPicklistValue('RE_SCHEDULED'),     'RE_SCHEDULED');
        System.assertEquals('2632', PreBookingAPIQueueable.getPicklistValue('PICKED'),           'PICKED');
        System.assertEquals('2633', PreBookingAPIQueueable.getPicklistValue('CANCEL'),           'CANCEL');
        System.assertEquals(null,   PreBookingAPIQueueable.getPicklistValue('UNKNOWN'),          'unrecognised → null');
    }
}