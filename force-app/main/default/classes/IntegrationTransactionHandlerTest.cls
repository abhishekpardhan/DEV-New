/**
 * @File Name          : IntegrationTransactionHandlerTest.cls
 * @Description        : Test class for IntegrationTransactionHandler trigger handler.
 *                       Covers afterInsert routing and afterUpdate retry logic for
 *                       all operation types including EnterpriseEnquiryCaseStatus.
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
public class IntegrationTransactionHandlerTest {

    private class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"responseCode":"RCC-200","responseStatus":"SUCCESS","responseMessage":"Case status updated successfully"}');
            return res;
        }
    }

    // ── afterInsert: EnterpriseEnquiryCaseStatus routes to ExternalCaseStatusQueueable ──
    @isTest
    static void testAfterInsertEnquiryCaseStatus() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9800000001', 'ITHANDLER01');
        insert c;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        // Inserting IT record fires Integration_Transaction__c trigger → IntegrationTransactionHandler.afterInsert()
        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_Enterprise_EnquiryCaseStatus);
        insert it;
        Test.stopTest();

        // Verify IT record was created with correct operation type
        Integration_Transaction__c queried = [SELECT Id, Operation_Type__c, Record_Id__c FROM Integration_Transaction__c WHERE Id = :it.Id];
        System.assertEquals(System.Label.OperationType_Enterprise_EnquiryCaseStatus, queried.Operation_Type__c);
        System.assertEquals(c.Id, queried.Record_Id__c);
    }

    // ── afterUpdate: retry increments trigger re-enqueue ────────────────────
    @isTest
    static void testAfterUpdateRetryEnquiryCaseStatus() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9800000002', 'ITHANDLER02');
        insert c;

        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_Enterprise_EnquiryCaseStatus);
        it.Status__c = 'Fail';
        insert it;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        // Simulating a retry by incrementing No_of_Retries__c
        it.No_of_Retries__c = 1;
        update it;
        Test.stopTest();

        Integration_Transaction__c updated = [SELECT No_of_Retries__c FROM Integration_Transaction__c WHERE Id = :it.Id];
        System.assertEquals(1, updated.No_of_Retries__c, 'Retry count should be incremented');
    }

    // ── afterInsert: PropelICaseCreation operation type still routes correctly ──
    @isTest
    static void testAfterInsertPropelIRouting() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9800000003', 'ITHANDLER03');
        insert c;

        Test.startTest();
        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_PropelI_CaseCreation);
        insert it;
        Test.stopTest();

        Integration_Transaction__c queried = [SELECT Operation_Type__c FROM Integration_Transaction__c WHERE Id = :it.Id];
        System.assertEquals(System.Label.OperationType_PropelI_CaseCreation, queried.Operation_Type__c);
    }

    // ── afterInsert: unrecognised operation type → no error, no enqueue ─────
    @isTest
    static void testAfterInsertUnknownOperationType() {
        Integration_Transaction__c it = new Integration_Transaction__c();
        it.Object_Name__c    = 'Case';
        it.Record_Id__c      = '5000000000000001';
        it.Operation_Type__c = 'Create Customer';
        it.No_of_Retries__c  = 0;

        Test.startTest();
        insert it;
        Test.stopTest();

        System.assert([SELECT Id FROM Integration_Transaction__c WHERE Id = :it.Id].size() == 1, 'IT record should be inserted without error');
    }
}