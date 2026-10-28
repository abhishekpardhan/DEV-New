/**
 * @File Name          : SafexpressWaybillEnquiryActionTest.cls
 * @Description        : Test class for SafexpressWaybillEnquiryAction invocable action.
 * @Author             : Rohit Deshmukh
 * @Last Modified By   : Rohit Deshmukh
 * @Last Modified On   : 14-Oct-2026
**/
@isTest
private class SafexpressWaybillEnquiryActionTest {

    @testSetup static void setupTestData() {
        String endpoint = 'https://api.safexpress.com/track';
        Safex_API__c safexApi = TestDataFactory.createSafexAPI(
            ConstantUtility.WAY_BILL_API_NAME, 'test', 'basic', null, null, endpoint, 'testUser', 'testPassword'
        );
        insert safexApi;
    }

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{ "status": "Ok", "data": { "waybillNo": "100042313601", "dlvryCity": "LUCKNOW", "dlvryDate": "17-Jun-2021", "track": [ { "eventDate": "17-Jun-2021 13:15:02", "eventDescr": "Waybill Delivered", "websiteMsg": "Waybill Delivered" } ] } }');
            return res;
        }
    }

    private class NotFoundMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{ "status": "Not Found", "message": "Record not found" }');
            return res;
        }
    }

    private class InvalidJsonMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('INVALID_JSON_RESPONSE');
            return res;
        }
    }

    @isTest
    static void testGetWaybillStatus_Success() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        SafexpressWaybillEnquiryAction.Request req = new SafexpressWaybillEnquiryAction.Request();
        req.waybillNumber = '100042313601';

        Test.startTest();
        List<SafexpressWaybillEnquiryAction.Output> outputs = SafexpressWaybillEnquiryAction.getWaybillStatus(
            new List<SafexpressWaybillEnquiryAction.Request>{ req }
        );
        Test.stopTest();

        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        System.assertEquals(1, outputs.size(), 'Should return 1 output');
        System.assertEquals('SUCCESS', outputs[0].waybillStatus, 'Status should be SUCCESS');
        System.assertEquals('Delivered', outputs[0].currentStatus, 'Current status should be Delivered');
        System.assertNotEquals(null, outputs[0].waybillCard, 'Waybill card should be populated');
        System.assertEquals('LUCKNOW', outputs[0].waybillCard.deliveryLocation, 'Delivery location should match dlvryCity');
        System.assertEquals('17-Jun-2021', outputs[0].waybillCard.deliveredOn, 'Delivered on date should be populated');
    }

    @isTest
    static void testGetWaybillStatus_BlankInput() {
        SafexpressWaybillEnquiryAction.Request req = new SafexpressWaybillEnquiryAction.Request();
        req.waybillNumber = '';

        Test.startTest();
        List<SafexpressWaybillEnquiryAction.Output> outputs = SafexpressWaybillEnquiryAction.getWaybillStatus(
            new List<SafexpressWaybillEnquiryAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Should return 1 output');
        System.assertEquals('VALIDATION_ERROR', outputs[0].waybillStatus, 'Status should be VALIDATION_ERROR');
        System.assertEquals('Waybill Number Required', outputs[0].waybillCard.headerTitle, 'Header title should indicate requirement');
    }

    @isTest
    static void testGetWaybillStatus_NotFound() {
        Test.setMock(HttpCalloutMock.class, new NotFoundMock());

        SafexpressWaybillEnquiryAction.Request req = new SafexpressWaybillEnquiryAction.Request();
        req.waybillNumber = '999999999999';

        Test.startTest();
        List<SafexpressWaybillEnquiryAction.Output> outputs = SafexpressWaybillEnquiryAction.getWaybillStatus(
            new List<SafexpressWaybillEnquiryAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Should return 1 output');
        System.assertEquals('NOT_FOUND', outputs[0].waybillStatus, 'Status should be NOT_FOUND');
        System.assertEquals('No Record Found', outputs[0].waybillCard.headerTitle, 'Header title should indicate not found');
    }

    @isTest
    static void testGetWaybillStatus_InvalidJson() {
        Test.setMock(HttpCalloutMock.class, new InvalidJsonMock());

        SafexpressWaybillEnquiryAction.Request req = new SafexpressWaybillEnquiryAction.Request();
        req.waybillNumber = '100042313601';

        Test.startTest();
        List<SafexpressWaybillEnquiryAction.Output> outputs = SafexpressWaybillEnquiryAction.getWaybillStatus(
            new List<SafexpressWaybillEnquiryAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Should return 1 output');
        System.assertEquals('API_ERROR', outputs[0].waybillStatus, 'Status should handle deserialization failure as API_ERROR');
        System.assertEquals('Tracking Service Unavailable', outputs[0].waybillCard.headerTitle, 'Header title should indicate service unavailability');
    }

    @isTest
    static void testGetWaybillStatus_CalloutException() {
        SafexpressWaybillEnquiryAction.Request req = new SafexpressWaybillEnquiryAction.Request();
        req.waybillNumber = '100042313601';

        Test.startTest();
        List<SafexpressWaybillEnquiryAction.Output> outputs = SafexpressWaybillEnquiryAction.getWaybillStatus(
            new List<SafexpressWaybillEnquiryAction.Request>{ req }
        );
        Test.stopTest();

        System.assertNotEquals(null, outputs, 'Outputs should not be null');
    }
}