/**
* Description		:	   Controller for 'nottoBeClaimed' LWC
* Created By       :       Deepika thakur
* Created Date     :       24th March, 2025
* Last Modified on :
* Jira Ticket      :       https://safexpress.atlassian.net/browse/SAC-1197
**/
public with sharing class JourneyStatusController {
    @AuraEnabled
    public static Map<String, String> updateStatus(Id journeyId) {
        Map<String, String> response = new Map<String, String>();

        if (journeyId == null) {
            return getErrorResponse('Invalid Journey Id.');
        }

        try {
            List<Journey__c> journeyList = [SELECT Id, Approval_Status__c FROM Journey__c WHERE Id = :journeyId LIMIT 1];

            if (journeyList.isEmpty()) {
                return getErrorResponse('No Journey record found for the provided Id.');
            }

            Journey__c journey = journeyList[0];

            if (journey.Approval_Status__c == 'Not to be Claimed') {
                return getErrorResponse('This Journey record is already locked for updates.');
            }

            // Update journey status
            journey.Approval_Status__c = 'Not to be Claimed';
            update journey;

            response.put('status', 'success');
            response.put('message', 'Journey status updated successfully to "Not to be Claimed"');
        } catch (DmlException dmlEx) {
            String errorMessage = extractValidationMessage(dmlEx);
            return getErrorResponse(errorMessage);
        } catch (Exception ex) {
            return getErrorResponse('An unexpected error occurred: ' + ex.getMessage());
        }

        return response;
    }

    // Helper method to extract only the relevant validation error message
    public static String extractValidationMessage(DmlException dmlEx) {
        // Extract the first DML error message
        if (dmlEx.getNumDml() > 0) {
            return dmlEx.getDmlMessage(0); // Get first validation error message
        }
        return 'Failed to update the Journey status: ' + dmlEx.getMessage();
    }

    // Helper method to create a consistent error response
    private static Map<String, String> getErrorResponse(String message) {
        Map<String, String> errorResponse = new Map<String, String>();
        errorResponse.put('status', 'error');
        errorResponse.put('message', message);
        return errorResponse;
    }
}