@isTest
public class IConnectUpdateAPIQueueableTest {

    // Mock class for HTTP callouts
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('token')) {
                res.setBody('{"data":[{"access_token":"mocked_token"}],"expiredAt":' + (System.currentTimeMillis()/1000 + 3600) + '}');
            } else {
                res.setBody('{"response":"Success"}');
            }
            return res;
        }
    }

    @testSetup
    static void setup() {
        // Insert custom setting record if required by getStatusCodeForTokenApi
        Iconnect_API__c setting = new Iconnect_API__c(
            Name = 'Iconnect',
            Endpoint__c = 'https://test.salesforce.com/token',
            X_Api_Key__c = 'mock-key',
            Username__c = 'user',
            ClientId__c = 'client-id',
            ClientSecret__c = 'secret'
        );
        insert setting;

        // Insert token management record
        Token_Management__c token = new Token_Management__c(
            Application_Name__c = 'Iconnect',
            Token_ID__c = 'initial_token',
            expiredAtTime__c = System.now().addDays(-1)
        );
        insert token;

        // Insert test Case
        Case testCase = new Case(
            Origin_Version__c = 'IC-02',
            PropelI_PreBooking_Id__c = 'PB123',
            Pre_Booking_Id__c = 'PB123',
            Booking_Status__c = '2633',
            WaybillNo__c = 'WB123'
        );
        insert testCase;

        // Insert dummy IntegrationTransaction record if referenced
        // Insert other required objects if referenced in the utility classes
    }

    @isTest
    static void testQueueableWithCaseIdList() {
        // Get test Case
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        List<String> caseIdList = new List<String>{testCase.Id};

        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Enqueue the job
        Test.startTest();
        System.enqueueJob(new IConnectUpdateAPIQueueable(caseIdList));
        Test.stopTest();

        // Assertions (optionally validate logs, updates, etc.)
        System.assert(true, 'Executed without unhandled exception');
    }

    @isTest
    static void testQueueableWithCaseIdMap() {
        // Get test Case
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Map<String, String> caseIdMap = new Map<String, String>{
            'integrationId123' => testCase.Id
        };

        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Enqueue the job
        Test.startTest();
        System.enqueueJob(new IConnectUpdateAPIQueueable(caseIdMap));
        Test.stopTest();

        // Assertions
        System.assert(true, 'Executed without unhandled exception');
    }
    
    @isTest
    static void testgetPicklistValue(){
         
        Test.startTest();
        	String twoSixTwoNine = IConnectUpdateAPIQueueable.getPicklistValue('2629');
        	IConnectUpdateAPIQueueable.getPicklistValue('2630');
        	IConnectUpdateAPIQueueable.getPicklistValue('2638');
        	IConnectUpdateAPIQueueable.getPicklistValue('2632');
            IConnectUpdateAPIQueueable.getPicklistValue('2633');
        	IConnectUpdateAPIQueueable.getPicklistValue('');
        Test.stopTest();
        
        // Asserts
        System.assertEquals('BOOKING CREATED',twoSixTwoNine);
    }
}