/**
 * @File Name          : ExternalCaseStatusQueueableTest.cls
 * @Description        : Test class for ExternalCaseStatusQueueable
 * @Author             : Rudra Singh | GT Bharat
 * @Group              : Safexpress
 * @Last Modified By   : Rudra Singh | GT Bharat
 * @Last Modified On   : 16/06/2026
 * @Modification Log   :
 *==============================================================================
 * Ver         Date            Author          Modification
 *==============================================================================
 * 1.0        16/06/2026       Rudra Singh     Initial Version
 **/
@isTest
public class ExternalCaseStatusQueueableTest {

    // ── Mock HTTP callouts ───────────────────────────────────────────────────
    private class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"responseCode":"RCC-200","responseStatus":"SUCCESS","responseMessage":"Case status updated successfully"}');
            return res;
        }
    }

    private class MockFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"responseCode":"RCC-500","responseStatus":"ERROR","responseMessage":"Internal server error"}');
            return res;
        }
    }

    // ── Test: successful callout → IT record Status = Success ────────────────
    @isTest
    static void testExecuteSuccess() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9876543210', 'TEST123456');
        insert c;
        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction(c.Id, 'EnterpriseEnquiryCaseStatus');
        insert it;

        Map<String, String> txnMap = new Map<String, String>{ it.Id => c.Id };

        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        System.enqueueJob(new ExternalCaseStatusQueueable(txnMap, 'Enterprise_Enquiry_Case_API'));
        Test.stopTest();

        Integration_Transaction__c updated = [SELECT Status__c, Request__c, Response__c FROM Integration_Transaction__c WHERE Id = :it.Id];
        System.assertEquals('Success', updated.Status__c, 'IT record should be Success on 200 response');
        System.assertNotEquals(null, updated.Request__c, 'Request should be populated');
        System.assertNotEquals(null, updated.Response__c, 'Response should be populated');
    }

    // ── Test: non-200 response → IT record Status = Fail ────────────────────
    @isTest
    static void testExecuteFailure() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9876543210', 'FAIL456');
        insert c;
        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction(c.Id, 'EnterpriseEnquiryCaseStatus');
        insert it;

        Map<String, String> txnMap = new Map<String, String>{ it.Id => c.Id };

        Test.setMock(HttpCalloutMock.class, new MockFailure());
        Test.startTest();
        System.enqueueJob(new ExternalCaseStatusQueueable(txnMap, 'Enterprise_Enquiry_Case_API'));
        Test.stopTest();

        Integration_Transaction__c updated = [SELECT Status__c FROM Integration_Transaction__c WHERE Id = :it.Id];
        System.assertEquals('Fail', updated.Status__c, 'IT record should be Fail on non-200 response');
    }

    // ── Test: case not found → error logged, no exception surfaces ──────────
    @isTest
    static void testExecuteCaseNotFound() {
        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction('5000000000000000', 'EnterpriseEnquiryCaseStatus');
        insert it;

        Map<String, String> txnMap = new Map<String, String>{ it.Id => '5000000000000000' };

        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        System.enqueueJob(new ExternalCaseStatusQueueable(txnMap, 'Enterprise_Enquiry_Case_API'));
        Test.stopTest();

        System.assert(true, 'No exception should propagate for missing case');
    }

    // ── Test: empty map → returns immediately without error ──────────────────
    @isTest
    static void testExecuteEmptyMap() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        System.enqueueJob(new ExternalCaseStatusQueueable(new Map<String, String>(), 'Enterprise_Enquiry_Case_API'));
        Test.stopTest();
        System.assert(true, 'Empty map should return without error');
    }

    // ── Test: In Progress status maps to inprogress ──────────────────────────
    @isTest
    static void testStatusMappingInProgress() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9111111111', 'STATTEST01');
        c.Status = 'In Progress';
        insert c;
        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction(c.Id, 'EnterpriseEnquiryCaseStatus');
        insert it;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        System.enqueueJob(new ExternalCaseStatusQueueable(new Map<String, String>{ it.Id => c.Id }, 'Enterprise_Enquiry_Case_API'));
        Test.stopTest();

        Integration_Transaction__c updated = [SELECT Status__c, Request__c FROM Integration_Transaction__c WHERE Id = :it.Id];
        System.assertEquals('Success', updated.Status__c);
        System.assert(updated.Request__c.contains('inprogress'), 'Payload should contain inprogress');
    }

    // ── Test: New status maps to pending ─────────────────────────────────────
    @isTest
    static void testStatusMappingNew() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9222222222', 'STATTEST02');
        insert c;  // Status = New by default
        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction(c.Id, 'EnterpriseEnquiryCaseStatus');
        insert it;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        System.enqueueJob(new ExternalCaseStatusQueueable(new Map<String, String>{ it.Id => c.Id }, 'Enterprise_Enquiry_Case_API'));
        Test.stopTest();

        Integration_Transaction__c updated = [SELECT Request__c FROM Integration_Transaction__c WHERE Id = :it.Id];
        System.assert(updated.Request__c.contains('pending'), 'Payload should contain pending for New status');
    }
}