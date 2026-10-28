@isTest
public class GetInvoiceUrlTest {
    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"output": "https://traveldesk.safexpress.com/PodSnsdWS/displayInvoice.jsp?invoice=220400000270531","status": "success"}');
            return res;
        }
    }
    private class MockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"output": "https://traveldesk.safexpress.com/PodSnsdWS/displayInvoice.jsp?invoice=220400000270531","status": "error"}');
            return res;
        }
    }
    @testSetup static void createTestData() {
        String endpoint = 'www.google.com';
        Safex_API__c safexApi = TestDataFactory.createSafexAPI(ConstantUtility.INVOICE_URL_API_NAME, 'test', 'basic', null,null, endpoint, 'testUser', 'testPassword');
        insert safexApi;
    }
    static testMethod void getWayBillStatusTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        List<String> strings =  new List<String>();
        strings.add('95713989');
        getInvoiceUrl.getInvoiceUrl(strings);
        Test.stopTest();
    }
    static testMethod void getWayBillStatusTestError() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockError());
        List<String> strings =  new List<String>();
        strings.add('95713989');
        getInvoiceUrl.getInvoiceUrl(strings);
        Test.stopTest();
    }
    static testMethod void getWayBillStatusTestErrorWithOutToken() {
        Test.startTest();
        Database.delete([SELECT Id FROM Safex_API__c]);
        Test.setMock(HttpCalloutMock.class, new Mock());
        List<String> strings =  new List<String>();
        strings.add('95713989');
        getInvoiceUrl.getInvoiceUrl(strings);
        Test.stopTest();
    }

}