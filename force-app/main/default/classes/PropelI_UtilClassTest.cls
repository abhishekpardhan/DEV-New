/**
 * @File Name          : PropelI_UtilClassTest.cls
 * @Description        : PropelI_UtilClassTest is the test class for PropelI_UtilClass apex class
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 04-11-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        04-11-2021                Deepak                   Initial Version
**/

@isTest
public class PropelI_UtilClassTest {

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
        apiPreBookings.add(TestDataFactory.createPropelIApiRecord(ConstantUtility.PROPEL_PRE_BOOKING_API_TOKEN_NAME, 'test', 'basic', 'test', 'test', endpoint, 'testUser', 'testPassword'));
        apiPreBookings.add(TestDataFactory.createPropelIApiRecord(ConstantUtility.PROPEL_PRE_BOOKING_API_NAME, 'test', 'basic', 'test', 'test', endpoint, 'testUser', 'testPassword'));
        insert apiPreBookings;


        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        insert cases;

    }
    static testMethod void propelCreateTicketTest() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockAccessToken());
        PropelI_UtilClass.propelCreateTicket(caseObj.Id);
        Test.stopTest();
    }
    static testMethod void updateCaseTest() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        PropelI_UtilClass.updateCase(caseObj.Id, 12345);
        Test.stopTest();
    }


}