/**
 * @File Name          : CancelPreBookingAPITest.cls
 * @Description        : This Test class id for CancelPreBookingAPI.cls
 * @Author             : Deepika
 * @Group              : IBM
 * @Last Modified By   : Deepika
 * @Last Modified On   : 15-05-2024
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        15-05-2024               Deepika                   Initial Version
**/
@isTest
public class CancelPreBookingAPITest {
    
 private class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"message": "PreBooking request Cancelled successfully","data": 946553,"status": "SUCCESS"}');
            return res;
        }
    }
    
    
     private class MockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(400);
            res.setBody('{"message": "ERROR","status": "FAILURE","errors": {"error": [{"code": "VAL_BKG_60018","description": "No prebooking request found for the case number"}]}}');
            return res;
        }
    }
    
    private class MockServerError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(500);
            res.setBody('{"message": "ERROR","status": "FAILURE","errors": {"error": [{"code": "VAL_BKG_60018","description": "No prebooking request found for the case number"}]}}');
            return res;
        }
    }
    
    @testSetup
    static void setupTestData() {
        String endpoint = 'www.google.com';
        Safex_API__c safexApi = TestDataFactory.createSafexAPI(ConstantUtility.CHANGE_CASE_STATUS_TO_CANCEL_API, 'test', 'basic', 'test', 'test', endpoint, 'testUser', 'testPassword');
     
        List<Safex_API__c> safexApis = new List<Safex_API__c>();
        safexApis.add(safexApi);
        insert safexApis;


        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        insert cases;

    }
     static testMethod void testSuccessMethod() {
        Test.startTest();
        Case caseObj = [SELECT Id, Cancel_Reason__c FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        CancelPreBookingAPI.cancelCaseStatus('9090909',caseObj.Id,caseObj.Cancel_Reason__c);
        Test.stopTest();
    }
        static testMethod void testErrorMethod() {
        Test.startTest();
        Case caseObj = [SELECT Id,Cancel_Reason__c FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockError());
        CancelPreBookingAPI.cancelCaseStatus('9090909',caseObj.Id,caseObj.Cancel_Reason__c);
        Test.stopTest();
    }
     static testMethod void testExceptionMethod() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockError());
        CancelPreBookingAPI.cancelCaseStatus('9090909',null, null);
        Test.stopTest();
    }
    
    static testMethod void testServerErrorMethod() {
        Test.startTest();
        Case caseObj = [SELECT Id,Cancel_Reason__c FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockServerError());
        CancelPreBookingAPI.cancelCaseStatus('9090909',caseObj.Id, caseObj.Cancel_Reason__c);
        Test.stopTest();
    }
    static testMethod void testUpdateCaseStatus(){
        Test.startTest();
        Case ca = new Case();
        ca.Subject = 'request';
        ca.Origin = 'IConnect';
        ca.Description = 'testing description';
        ca.Status ='In Progress';
        ca.SuppliedEmail = 'adarshranjan@safexpress.com';
        ca.Case_Nature__c = 'request';
        insert ca;
        CancelPreBookingAPI.updateCaseStatus(ca.Id,'DELAYED_DELIVERY');
        Test.stopTest();

    }
}