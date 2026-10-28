@isTest
public class ProtonCasePostAPITest {
    private class MockAccessToken implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{ "access_token": "eyJraWQiOiJhdm5P", "expires_in": 18000, "token_type": "Bearer" }');
            return res;
        }
    }
    @testSetup
    static void setupTestData() {
        String endpoint = 'www.google.com';
        List<PropelI_API_PreBooking__c> apiPreBookings = new List<PropelI_API_PreBooking__c>();
        apiPreBookings.add(TestDataFactory.createPropelIApiRecord(ConstantUtility.PROTON_PRE_BOOKING_API_TOKEN_NAME, 'test', 'basic', 'test', 'test', endpoint, 'testUser', 'testPassword'));
        apiPreBookings.add(TestDataFactory.createPropelIApiRecord(ConstantUtility.PROTON_PRE_BOOKING_UPDATE_API_NAME, 'test', 'basic', 'test', 'test', endpoint, 'testUser', 'testPassword'));
        apiPreBookings.add(TestDataFactory.createPropelIApiRecord(ConstantUtility.PROTON_PRE_BOOKING_API_NAME, 'test', 'basic', 'test', 'test', endpoint, 'testUser', 'testPassword'));
        insert apiPreBookings;


        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        insert cases;

    }
    static testMethod void propelCreateTicketTest() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockAccessToken());
        ProtonCasePostAPI.updatePreBooking(caseObj.Id);
        Test.stopTest();
    }
    static testMethod void propelCreateTicketTest1() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockAccessToken());
        ProtonCasePostAPI.createPreBooking(caseObj.Id);
        Test.stopTest();
    }
    static testMethod void updateCaseTest() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        ProtonCasePostAPI.updateCase(caseObj.Id, '12345');
        Test.stopTest();
    }


}