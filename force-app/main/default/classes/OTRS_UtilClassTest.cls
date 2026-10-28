/**
 * @File Name          : OTRS_UtilClassTest.cls
 * @Description        : OTRS_UtilClassTest is the test class for OTRS_UtilClass apex class
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
public class OTRS_UtilClassTest {

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            //System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{ "status": 201, "message": "success", "response": [ { "ArticleID": 513969, "TicketNumber": 211000517, "TicketID": 93988 } ] }');
            return res;
        }
    }
    
    private class MockDuplicate implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            //System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"status":201,"message":"success","docStatus":"No"}');
            return res;
        }
    }
    
    // FOR Update the ticket on case
    private class MockUpdate implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{ "status": 201, "message": "success", "response": [ { "ArticleID": 513969, "TicketNumber": 211000517, "TicketID": 93988 } ] }');
            return res;
        }
    }
    // to get the OTRS STATUS
    private class MockGetDetails implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{ "status": 201, "message": "success", "response": [ { "ArticleID": 513969, "TicketNumber": 211000517, "TicketID": 93988 } ] }');
            return res;
        }
    }
    @testSetup
    static void setupTestData() {
        String endpoint = 'www.google.com';
        Safex_API__c safexApi = TestDataFactory.createSafexAPI(ConstantUtility.OTRS_CREATE_TICKET_API_NAME, 'test', 'basic', 'test', 'test', endpoint, 'testUser', 'testPassword');
        Safex_API__c safexApi2 = TestDataFactory.createSafexAPI(ConstantUtility.OTRS_ARTICLE_UPDATE_API_NAME, 'test', 'basic', 'test2', 'test', endpoint, 'testUser2', 'testPassword2');
        Safex_API__c safexApi3 = TestDataFactory.createSafexAPI(ConstantUtility.OTRS_TICKET_DETAIL_API_NAME, 'test', 'basic', 'test', 'test', endpoint, 'testUser', 'testPassword');

        List<Safex_API__c> safexApis = new List<Safex_API__c>();
        safexApis.add(safexApi);
        safexApis.add(safexApi2);
        safexApis.add(safexApi3);
        insert safexApis;


        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        insert cases;

    }
    static testMethod void OTRSCreateTicketTest() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.setMock(HttpCalloutMock.class, new MockDuplicate());
        OTRS_UtilClass.OTRSCreateTicket(caseObj.Id);
        Test.stopTest();
    }
    static testMethod void updateOTRSTicketOnCaseTest() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        //Test.setMock(HttpCalloutMock.class, new Mock());
        OTRS_UtilClass.updateOTRSTicketOnCase('232323', String.valueOf(caseObj.Id));
        Test.stopTest();
    }

    static testMethod void OTRSArticleUpdateTest() {
        Test.startTest();
        List<Safex_API__c> wayApiInfo = QueryUtil.getSafexApiInfo(ConstantUtility.OTRS_ARTICLE_UPDATE_API_NAME);
        System.debug('wayApiInfo :TEST ' + wayApiInfo);
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockUpdate());
        OTRS_UtilClass.OTRSArticleUpdate('232323', String.valueOf(caseObj.Id), 'Test');
        Test.stopTest();
    }
    static testMethod void OTRSGetTicketDetailsTest1() {
        Test.startTest();
        Case caseObj = [SELECT Id,OTRS_Ticket_No__c FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockGetDetails());
        OTRS_UtilClass.OTRSGetTicketDetails(caseObj.Id);
        Test.stopTest();
    }
    static testMethod void OTRSGetTicketDetailsTest2() {
        Test.startTest();
        Case caseObj = [SELECT Id,OTRS_Ticket_No__c FROM Case LIMIT 1];
        caseObj.OTRS_Ticket_No__c = '232323';
        update caseObj;
        Test.setMock(HttpCalloutMock.class, new MockGetDetails());
        OTRS_UtilClass.OTRSGetTicketDetails(caseObj.Id);
        Test.stopTest();
    }

    static testMethod void updateOtrsStatusTest() {
        Test.startTest();
        Case caseObj = [SELECT Id,OTRS_Ticket_No__c FROM Case LIMIT 1];
        OTRS_UtilClass.updateOtrsStatus(ConstantUtility.OPEN, caseObj.Id);
        Test.stopTest();
    }

    static testMethod void withoutAPICredTest() {
        Test.startTest();
        List<Safex_API__c> safexApis = [SELECT Id FROM Safex_API__c];
        delete safexApis;
        Case caseObj = [SELECT Id,OTRS_Ticket_No__c FROM Case LIMIT 1];
        OTRS_UtilClass.OTRSCreateTicket(caseObj.Id);
        OTRS_UtilClass.OTRSGetTicketDetails(caseObj.Id);
        OTRS_UtilClass.OTRSArticleUpdate('232323', String.valueOf(caseObj.Id), 'Test');

        Test.stopTest();
    }


}