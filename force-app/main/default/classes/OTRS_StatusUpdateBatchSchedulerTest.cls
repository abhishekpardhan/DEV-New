/**
 * @File Name          : OTRS_StatusUpdateBatchSchedulerTest.cls
 * @Description        : OTRS_StatusUpdateBatchSchedulerTest is the test class for OTRS_StatusUpdateBatchScheduler and OTRS_StatusUpdateBatch apex classes
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 01-11-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        01-11-2021                Deepak                   Initial Version
**/

@IsTest
private class OTRS_StatusUpdateBatchSchedulerTest {

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"status":201,"message":"success","response":{"TicketDetail":{"id":"94237","tnumber":"211000763","title":"00001257-Complaint-POD-POD Credit","queue":"Postmaster","type":"Incident","state":"Closed","priority":"P3 normal","CreatedForCustomer":"Nitesh Mishra","CreatedByCustomer":"Nitesh Mishra","CustomerEmail":"nitesh.mishra@safexpress.com","MainCategory":"Customer Escalation","SubCategory":"Delivery Process Request","IssueType":"","AltPhone":"8860522420","Region":"Corporate Office","Impact":"High","Owner":"Admin OTRS","CreateTime":"2021-08-23 15:45:58","ModifiedTime":"2021-08-23 15:45:58","Articles":[{"ArticleId":"515252","From":"\" Nitesh Mishra\" <nitesh.mishra@safexpress.com>","To":"Postmaster","Subject":"00001257-Complaint-POD-POD Credit","Body":"sf","updateTime":"2021-08-23 15:45:58","Attachment":[]}]}}}');
            return res;
        }
    }
    @testSetup static void createTestData() {

        Safex_API__c safexApi = TestDataFactory.createSafexAPI(ConstantUtility.OTRS_TICKET_DETAIL_API_NAME, 'test', 'password', 't1','t2', 'wwww.google.com', 'test', 'test');
        insert safexApi;

        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        cases[0].WaybillNo__c = '12345678';
        cases[0].OTRS_Ticket_No__c = '12345678';

        insert cases;

    }
    static testMethod void executeTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        SchedulableContext sc = null;
        OTRS_StatusUpdateBatchScheduler tsc = new OTRS_StatusUpdateBatchScheduler();
        tsc.execute(sc);
        Test.stopTest();
    }

}