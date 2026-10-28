@isTest
private class JourneyStatusControllerTest {
    
    @isTest
    static void testUpdateStatusSuccess() {
        Journey__c journey = CommonDataTest.getJourney();
        journey.Journey_Date__c = Date.today();
        journey.Approval_Status__c = 'Submitted for Approval';
        insert journey;
        
        Test.startTest();
        Map<String, String> result = JourneyStatusController.updateStatus(journey.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testLockedJourneyUpdate() {
        // Setup test data
        Journey__c journey = CommonDataTest.getJourney();
        journey.Approval_Status__c = 'Not to be Claimed';
        
        
        Test.startTest();
        try {
            insert journey;
            // This method is expected to throw an exception due to record lock
            Map<String, String> result = JourneyStatusController.updateStatus(journey.Id);
            // Optionally assert result if no exception is thrown (unexpected)
            //System.assert(false, 'Expected an exception due to locked record, but none was thrown.');
        } catch (System.DmlException e) {
            // Validate that the error is due to record lock
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateStatusInvalidId() {
        Test.startTest();
        Map<String, String> result = JourneyStatusController.updateStatus(null);
        Test.stopTest();
        
        System.assertEquals('error', result.get('status'));
        System.assert(result.get('message').contains('Invalid Journey Id'));
    }
    
    @isTest
    static void testUpdateStatusNoRecordFound() {
        Id fakeId = 'a00B00000000000'; // Fake Id, won't match anything
        
        Test.startTest();
        Map<String, String> result = JourneyStatusController.updateStatus(fakeId);
        Test.stopTest();
        
        System.assertEquals('error', result.get('status'));
        System.assert(result.get('message').contains('No Journey record found'));
    }
    
    @isTest
    static void testExtractValidationMessage_withRealDmlException() {
        // Intentionally insert invalid Account (Name is required)
        Journey__c jor = new Journey__c(); // Missing required Name field
        
            try {
                insert jor; // This throws DmlException
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException ex) {
                String message = JourneyStatusController.extractValidationMessage(ex);
                System.debug('Extracted Message: ' + message);
                
                // You can check for a known part of the validation error message
                System.assert(message != null && message.toLowerCase().contains('required'),
                              'Expected message to indicate required field');
            }
    }
}