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

    }

    // Exercise the remaining queueable routes in the insert trigger context.
    @isTest
    static void testAfterInsertOtherOperationTypes() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9800000004', 'ITHANDLER04');
        insert c;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        insert new List<Integration_Transaction__c>{
            TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_Enterprise_UpdateCase),
            TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_iConnect_UpdateCase),
            TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_Proton_UpdateCase)
        };
        Test.stopTest();
    }

    @isTest
    static void testAfterInsertPincodeLookup() {
        Lead lead = LeadAssignmentServiceTest.sampleLead('201301');
        TriggerHandler.bypass('LeadTriggerHandler');
        insert lead;
        TriggerHandler.clearBypass('LeadTriggerHandler');

        Integration_Transaction__c it = TestDataFactory.createIntegrationTransaction(lead.Id, System.Label.OperationType_PropelI_PincodeLookup);
        it.Object_Name__c = 'Lead';
        it.Status__c = 'Draft';
        it.Request__c = '{"pincode":"201301"}';

        Test.setMock(HttpCalloutMock.class, PincodeApiMock.success(1));
        Test.startTest();
        insert it;
        Test.stopTest();
    }

    // Seed without routing on insert, then exercise all active retry routes in one update.
    @isTest
    static void testAfterUpdateRetryRoutes() {
        Case c = TestDataFactory.createWaybillEnquiryCase('9800000005', 'ITHANDLER05');
        insert c;
        Lead lead = LeadAssignmentServiceTest.sampleLead('201301');
        TriggerHandler.bypass('LeadTriggerHandler');
        insert lead;
        TriggerHandler.clearBypass('LeadTriggerHandler');

        Integration_Transaction__c propel = TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_PropelI_CaseCreation);
        Integration_Transaction__c enterprise = TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_Enterprise_UpdateCase);
        Integration_Transaction__c enquiry = TestDataFactory.createIntegrationTransaction(c.Id, System.Label.OperationType_Enterprise_EnquiryCaseStatus);
        Integration_Transaction__c pincode = TestDataFactory.createIntegrationTransaction(lead.Id, System.Label.OperationType_PropelI_PincodeLookup);
        pincode.Object_Name__c = 'Lead';
        pincode.Status__c = 'Draft';
        pincode.Request__c = '{"pincode":"201301"}';
        Integration_Transaction__c slack = TestDataFactory.createIntegrationTransaction(c.Id, 'SLACK_POST_MESSAGE');
        slack.Status__c = 'Draft';
        slack.Request__c = '{}';

        List<Integration_Transaction__c> rows = new List<Integration_Transaction__c>{propel, enterprise, enquiry, pincode, slack};
        TriggerHandler.bypass('IntegrationTransactionHandler');
        insert rows;
        TriggerHandler.clearBypass('IntegrationTransactionHandler');
        for (Integration_Transaction__c row : rows) row.No_of_Retries__c = 1;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        Test.startTest();
        update rows;
        Test.stopTest();
    }
}