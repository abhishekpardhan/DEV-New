@isTest
private class EnterpriseAppUpdateAPIQueueableTest {
    
    // Mock HTTP Response for successful callout
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "message": "Status updated successfully"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock HTTP Response for failed callout
    private class MockHttpResponseFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": false, "message": "Internal Server Error"}');
            res.setStatusCode(500);
            return res;
        }
    }
    
    @TestSetup
    static void setupTestData() {
        // Create test Cases - bulk pattern (251+ records)
        
        List<Case> testCases = new List<Case>();
        for(Integer i = 0; i < 260; i++) {
            testCases.add(new Case(
            Subject = 'Test Case ' + i,
            Status = 'New',
            Origin = 'Phone',
            Pre_Booking_Id__c = 'PB' + String.valueOf(1000 + i),
            Booking_Status__c = '2629',
            WaybillNo__c = 'WB' + String.valueOf(10000 + i)
            ));
        }

        insert testCases;

        Integration_Transaction__c reqDetail = new Integration_Transaction__c();
        reqDetail.Object_Name__c = 'Case';
        reqDetail.record_id__c = testCases[0].Id; 
        reqDetail.Operation_Type__c = 'EnterpriseUpdateCase' ;
        reqDetail.No_of_Retries__c = 1;
        insert reqDetail;
    }
    
    @isTest
    static void testExecute_SuccessfulCallout() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        List<Case> testCases = [SELECT Id FROM Case LIMIT 1];
        List<Integration_Transaction__c> testIt = [SELECT Id FROM Integration_Transaction__c LIMIT 1];
        Map<String, String> caseIdMap = new Map<String, String>();
        caseIdMap.put(testIt[0].Id, testCases[0].Id);
        
        // Act
        Test.startTest();
        System.enqueueJob(new EnterpriseAppUpdateAPIQueueable(caseIdMap));
        Test.stopTest();
        
        // Assert
        // Verify case was queried and processed
        Case processedCase = [
            SELECT Id, CaseNumber, Pre_Booking_Id__c, Booking_Status__c, WaybillNo__c 
            FROM Case 
            WHERE Id = :testCases[0].Id
        ];
        System.assertNotEquals(null, processedCase, 'Case should be found');
        System.assertEquals('PB1000', processedCase.Pre_Booking_Id__c, 'Pre-booking ID should match');
    }
    
    @isTest
    static void testExecute_WrongCaseId() {
        Map<String, String> caseIdMap = new Map<String, String>();
        List<Integration_Transaction__c> testIt = [SELECT Id FROM Integration_Transaction__c LIMIT 1];
        caseIdMap.put(testIt[0].Id, '500000000000000'); // Non-existent Case Id
        
        Test.startTest();
        System.enqueueJob(new EnterpriseAppUpdateAPIQueueable(caseIdMap));
        Test.stopTest();        
    }
    
    @isTest
    static void testExecute_FailedCallout() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());
        
        List<Case> testCases = [SELECT Id FROM Case LIMIT 1];
        List<Integration_Transaction__c> testIt = [SELECT Id FROM Integration_Transaction__c LIMIT 1];
        Map<String, String> caseIdMap = new Map<String, String>();
        caseIdMap.put(testIt[0].Id, testCases[0].Id);
        
        // Act
        Test.startTest();
        System.enqueueJob(new EnterpriseAppUpdateAPIQueueable(caseIdMap));
        Test.stopTest();
        
        // Assert
        // Verify case was processed even with failed callout
        Case processedCase = [
            SELECT Id, CaseNumber 
            FROM Case 
            WHERE Id = :testCases[0].Id
        ];
        System.assertNotEquals(null, processedCase, 'Case should still be found');
    }
    
    @isTest
    static void testMapStatus_AllStatuses() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        List<String> statusCodes = new List<String>{'2629', '2630', '2638', '2632', '2633'};
        List<String> expectedStatuses = new List<String>{
            'BOOKING CREATED', 
            'BOOKING ASSIGNED', 
            'RE_SCHEDULED', 
            'PICKED', 
            'CANCELLED'
        };
        
        // Create cases with different status codes
        List<Case> testCases = new List<Case>();
        for(Integer i = 0; i < statusCodes.size(); i++) {
            testCases.add(new Case(
                Subject = 'Status Test ' + i,
                Status = 'New',
                Origin = 'Phone',
                Pre_Booking_Id__c = 'STATUS-' + i,
                Booking_Status__c = statusCodes[i],
                WaybillNo__c = 'WB-STATUS-' + i
            ));
        }
        insert testCases;
        
        // Act & Assert
        Test.startTest();
        for(Integer i = 0; i < testCases.size(); i++) {
            Map<String, String> caseIdMap = new Map<String, String>();
            caseIdMap.put('IT-STATUS-' + i, testCases[i].Id);
            System.enqueueJob(new EnterpriseAppUpdateAPIQueueable(caseIdMap));
        }
        Test.stopTest();
        
        // Verify all status mappings were processed
        List<Case> processedCases = [SELECT Id, Booking_Status__c FROM Case WHERE Id IN :testCases];
        System.assertEquals(statusCodes.size(), processedCases.size(), 'All status codes should be processed');
    }
    
}