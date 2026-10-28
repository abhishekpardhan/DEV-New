@isTest
public class OTRSCalloutJobTest {
    private static Id loggerId;
    private static Id caseId;
    public class MockOTRSCalloutResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"response":[{"TicketNumber":"OTRS-12345"}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void setupTestData() {
        API_Logger__c logger = new API_Logger__c(API_Name__c = 'Test Logger', Request_Hash__c = 'hash123');
        insert logger;
        loggerId = logger.Id;
        Case testCase = new Case(Status = 'New', Origin = 'Phone');
        insert testCase;
        caseId = testCase.Id;
    }

    @isTest
    static void testExecuteOTRSCalloutJob() {
        Test.setMock(HttpCalloutMock.class, new MockOTRSCalloutResponse());
        Blob requestBody = Blob.valueOf('{"key":"value"}');
        String endpoint = 'https://example.com/api';
        String contentLength = String.valueOf(requestBody.toString().length());
        String contentType = 'application/json';

        Test.startTest();
        OTRSCalloutJob job = new OTRSCalloutJob(
            loggerId,
            'CreateTicket',
            endpoint,
            requestBody,
            contentLength,
            contentType,
            caseId
        );
        System.enqueueJob(job);
        Test.stopTest();
         Id caseObjId = [Select Id from Case limit 1].Id;
        Case updatedCase = [SELECT OTRS_Ticket_No__c FROM Case WHERE Id = :caseObjId];
        
    }
}