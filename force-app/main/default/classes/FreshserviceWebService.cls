/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : FreshserviceWebService
 * Author          : <Rishank Bhardwaj>
 * Created Date    : Aug 5, 2026
 * Last Modified By: <Rishank Bhardwaj>
 * Last Modified On: Aug 5, 2026
 * Description     : This class implements for update the case in salesforce
 *
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 5, 2026  │ <Rishank Bhardwaj>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@RestResource(urlMapping='/salesforce/caseupdate/v1')
global without sharing class FreshserviceWebService {

    public static Boolean skipOutboundSync = false;

    // Update Salesforce Case.
    @HttpPost
    global static void updateCase() {
        String requestBody = null;
        if (RestContext.request.requestBody != null) {
            requestBody = RestContext.request.requestBody.toString();
        }

        try {
            if (String.isBlank(requestBody)) {
                sendResponse(400, false, 'Request Body can not be Blank', null, null);
                return;
            }

            FreshserviceWrapper.CaseUpdateRequest request;

            try {
                Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                request = new FreshserviceWrapper.CaseUpdateRequest();

                if (requestMap.get('ticketNumber') != null) {
                    request.ticketNumber = String.valueOf(requestMap.get('ticketNumber'));
                }

                if (requestMap.get('createdDate') != null) {
                    request.createdDate = Date.valueOf(String.valueOf(requestMap.get('createdDate')));
                }

                if (requestMap.get('fields') != null) {
                    request.fields = (Map<String, Object>) requestMap.get('fields');
                }

            } catch (Exception exp) {
                sendResponse(400, false, 'Invalid JSON request body: ' + exp.getMessage(), null, null);
                return;
            }

            if (String.isBlank(request.ticketNumber)) {
                sendResponse(400, false, 'Ticket number cannot be blank.', null, null);
                return;
            }

            if (request.fields == null || request.fields.isEmpty()) {
                sendResponse(400, false, 'Case fields cannot be blank.', null, null);
                return;
            }

            String ticketNumber = request.ticketNumber.trim();
            String freshserviceTicketNumber = ticketNumber.toUpperCase().startsWith('FSC-') ? ticketNumber : 'FSC-' + ticketNumber;
            List<Case> cases;

            if (request.createdDate == null) {
                cases = [SELECT Id FROM Case
                         WHERE CaseNumber = :ticketNumber OR Fresh_Service_Ticket_No__c = :freshserviceTicketNumber LIMIT 2];
            } else {
                Date createdDate = request.createdDate;
                cases = [SELECT Id FROM Case
                         WHERE (CaseNumber = :ticketNumber OR Fresh_Service_Ticket_No__c = :freshserviceTicketNumber) AND DAY_ONLY(CreatedDate) = :createdDate LIMIT 2];
            }

            if (cases.isEmpty()) {
                sendResponse(404, false, 'No case found with this ticket: ' + ticketNumber, null, null);
                return;
            }

            if (cases.size() > 1) {
                sendResponse(409, false, 'Multiple cases found with this ticket number ' + ticketNumber, null, null);
                return;
            }

            Map<String, Schema.SObjectField> caseFields = Schema.SObjectType.Case.fields.getMap();
            Case caseRecord = cases[0];
            List<String> updatedFields = new List<String>();

            for (String requestFieldName : request.fields.keySet()) {
                if (String.isBlank(requestFieldName)) {
                    throw new IllegalArgumentException('Case field name cannot be blank.');
                }

                String fieldName = requestFieldName.trim();

                if (!caseFields.containsKey(fieldName)) {
                    throw new IllegalArgumentException('Invalid Salesforce Case field: ' + fieldName);
                }

                Schema.DescribeFieldResult fieldDescribe = caseFields.get(fieldName).getDescribe();

                if (!fieldDescribe.isUpdateable()) {
                    throw new IllegalArgumentException('Salesforce Case field is not updateable: ' + fieldName);
                }

                try {
                    caseRecord.put(fieldName, convertFieldValue(request.fields.get(requestFieldName), fieldDescribe.getType()));
                } catch (Exception exp) {
                    throw new IllegalArgumentException('Invalid value for Salesforce Case field: ' + fieldName);
                }

                updatedFields.add(fieldName);
            }

            try {
                Freshservice_UtilClass.skipFreshserviceCaseSync = true;
                update caseRecord;
            } finally {
                Freshservice_UtilClass.skipFreshserviceCaseSync = false;
            }

            sendResponse(200, true, 'Case updated successfully.', caseRecord.Id, updatedFields);

        } catch (IllegalArgumentException exp) {
            sendResponse(400, false, exp.getMessage(), null, null);

        } catch (DmlException exp) {
            logError(exp);
            sendResponse(400, false, exp.getDmlMessage(0), null, null);

        } catch (Exception exp) {
            logError(exp);
            sendResponse(500, false, 'Unable to update Salesforce Case.', null, null);
        }
    }

    // Convert requested field value.
    private static Object convertFieldValue(Object value, Schema.DisplayType fieldType) {
        if (value == null) {
            return null;
        }

        String stringValue = String.valueOf(value).trim();

        if (fieldType == Schema.DisplayType.Boolean) {
            if (stringValue.toLowerCase() != 'true' && stringValue.toLowerCase() != 'false') {
                throw new IllegalArgumentException('Invalid Boolean value.');
            }

            return Boolean.valueOf(stringValue);
        }

        if (fieldType == Schema.DisplayType.Date) {
            return Date.valueOf(stringValue);
        }

        if (fieldType == Schema.DisplayType.DateTime) {
            return (Datetime) JSON.deserialize(JSON.serialize(stringValue), Datetime.class);
        }

        if (fieldType == Schema.DisplayType.Integer) {
            return Integer.valueOf(removeDecimalValue(stringValue));
        }

        if (fieldType == Schema.DisplayType.Double) {
            return Decimal.valueOf(stringValue);
        }

        return stringValue;
    }

    // Remove decimal value.
    private static String removeDecimalValue(String value) {
        return value.contains('.') ? value.substring(0, value.indexOf('.')) : value;
    }

    // Log web service error.
    private static void logError(Exception exp) {
        try {
            LoggerUtil.createErrorLog('FreshserviceWebService', 'updateCase', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        } catch (Exception logExp) {
            // Ignore logging failure.
        }
    }

    // Send web service response.
    private static void sendResponse(Integer statusCode, Boolean success, String message, Id caseId, List<String> updatedFields) {
        FreshserviceWrapper.CaseUpdateResponse response = new FreshserviceWrapper.CaseUpdateResponse();
        response.success = success;
        response.message = message;
        response.caseId = caseId;

        if (updatedFields != null) {
            response.updatedFields.addAll(updatedFields);
        }

        RestContext.response.statusCode = statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }
}