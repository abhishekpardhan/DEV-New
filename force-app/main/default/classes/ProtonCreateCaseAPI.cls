/**
* @File Name          : CreateCaseApi.cls
* @Description        : This class will used to create Cases in salesforce using API.
* @Author             : Shubham
* @Group              : Safexpress
* @Last Modified By   : Adarsh
* @Last Modified On   : 02/02/2023
**/
@RestResource(urlMapping='/ProtonCreateSupportCase/*')
global with sharing class ProtonCreateCaseAPI {

    @HttpPost
    global static void createCase() {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        RestRequest request = RestContext.request; //RestRequest for the Apex REST method
        String requestBody = request.requestBody != null ? request.requestBody.toString() : '';
        try {
            case newCase;
            if (!String.isBlank(requestBody)) {
                Map<String, Object> caseFieldMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestBody.toString());
                RequestWrapper requestWrapper = (RequestWrapper) System.JSON.deserialize(requestBody, RequestWrapper.class);
                //system.debug('requestWrapper'+requestWrapper);
                if (requestWrapper != null) {
                    String fieldCheckMessage = checkFields(requestWrapper);
                    if (fieldCheckMessage == null) {
                        List<Case> existingCases = new List<Case>();
                        Date pickupDate = Date.valueOf(requestWrapper.pickDateTime);
                        String caseNature = requestWrapper.caseNature;
                        String caseType = requestWrapper.caseType;
                        String wayBillNumber = requestWrapper.wayBillNumber;
                        String requestNo = requestWrapper.reqNo;
                        system.debug('requestNo=='+requestNo);
                        
                        if(caseType == ConstantUtility.CASE_TYPE_BOOKING_REQUEST){
                            existingCases = [
                                SELECT Id,CaseNumber,Pre_Booking_Id__c
                                FROM Case
                                WHERE Pre_Booking_Id__c  = :requestWrapper.reqNo
                                LIMIT 1
                            ];
                        }
                        if (existingCases.size() > 0) {
                            responseWrapper = createResponse(ConstantUtility.DUPLICATE_CASE_FOUND+' and reqNo is '+requestWrapper.reqNo, 'duplicate', existingCases[0].CaseNumber);
                            system.debug('responseWrapper line 51=='+responseWrapper);
                        } else {
                            Case caseObj = createNewCase(requestWrapper);
                            responseWrapper = createResponse(ConstantUtility.CASE_CREATED_SUCCESS, ConstantUtility.SUCCESS.toLowerCase(), caseObj.CaseNumber);
                            system.debug('responseWrapper'+responseWrapper);
                            system.debug('CaseNumber'+caseObj.CaseNumber);
                        }
                    } else {
                        responseWrapper = createResponse(fieldCheckMessage, ConstantUtility.ERROR.toLowerCase(), null);
                    }
                } else {
                    responseWrapper = createResponse(ConstantUtility.INVALID_REQUEST_BODY, ConstantUtility.ERROR.toLowerCase(), null);
                }
            } else {
                responseWrapper = createResponse(ConstantUtility.INVALID_REQUEST_BODY, ConstantUtility.ERROR.toLowerCase(), null);
            }
        } catch (exception exp) {
            system.debug('exp.getMessage()'+exp.getMessage());
            responseWrapper = createResponse(exp.getMessage(), ConstantUtility.ERROR.toLowerCase(), null);
            LoggerUtil.createErrorLog('CreateCaseApi', 'createCase', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        LoggerUtil.createAPILog('CreateCaseApi', 'TO Salesforce', requestBody, JSON.serialize(responseWrapper), null);
        if(!Test.isRunningTest()){
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
        }
    }
    public static Case createNewCase(RequestWrapper requestWrapper) {

        List<Contact> contacts = new List<Contact>();
        contacts = [SELECT Id FROM Contact WHERE MobilePhone = :requestWrapper.requesterPhone /*AND Email = :requestWrapper.emailId*/ LIMIT 1];
        if (contacts.size() == 0) {
            Contact contact = new Contact();
            contact.LastName = requestWrapper.requesterName;
            contact.Email = requestWrapper.emailId;
            contact.MobilePhone = requestWrapper.requesterPhone;
            insert contact;
            contacts.add(contact);
        }
        Case newCaseObj = new Case();
       // newCaseObj.CaseNumber = requestWrapper.CaseNumber;
        newCaseObj.Status = ConstantUtility.NEW_STATUS;
        newCaseObj.ContactId = contacts[0].Id ;
        newCaseObj.Case_Nature__c = requestWrapper.caseNature;
        newCaseObj.Case_Type__c = requestWrapper.caseType;
        newCaseObj.Sub_Type__c = requestWrapper.subType;
        newCaseObj.Consignor_Name__c = requestWrapper.requesterName;
        newCaseObj.Consignee_Name__c = requestWrapper.consigneeName;  // added by Shubham 
        newCaseObj.Consignor_Address_Line_1__c = requestWrapper.fromLocn;  //requestWrapper.fromLocn edited by Shubham
        newCaseObj.Consignee_Address_Line_1__c = requestWrapper.toLocn; // added by Shubham
        newCaseObj.Consignor_Phone__c = requestWrapper.requesterPhone; // added by Shubham
        newCaseObj.Origin_Pincode__c = requestWrapper.fromPincode;
        newCaseObj.Consignor_Pincode__c = requestWrapper.fromPincode;
        newCaseObj.Destination_PinCode__c = requestWrapper.toPincode;
        newCaseObj.Consignee_Pincode__c = requestWrapper.toPincode;
        newCaseObj.Consignor_Email__c = requestWrapper.emailId;
        newCaseObj.Pickup_Type__c = requestWrapper.pickType;
        newCaseObj.Total_Weight__c = requestWrapper.weight;
        newCaseObj.Origin = requestWrapper.source;
        newCaseObj.Mode_Of_Payment__c = checkValue(requestWrapper.mop);
        newCaseObj.Transport_Mode__c = checkValue(requestWrapper.mode);
        newCaseObj.Description = requestWrapper.chatDetails;
        newCaseObj.Origin_Address__c = requestWrapper.fromLocn;
        newCaseObj.From_Location__c = requestWrapper.fromLocn;
        newCaseObj.Pre_Booking_Id__c = requestWrapper.reqNo;
        newCaseObj.To_Location__c = requestWrapper.toPincode;        
        newCaseObj.Destination_Address__c = requestWrapper.toPincode;
        newCaseObj.PickUp_Date__c = Date.valueOf(requestWrapper.pickDateTime);
        newCaseObj.PickUp_To_Time__c = String.valueOf(Datetime.valueOf(requestWrapper.pickDateTime).time());
        newCaseObj.Total_Package_Count__c = requestWrapper.numOfPices;
        newCaseObj.Description = requestWrapper.remarks;
        newCaseObj.WaybillNo__c = requestWrapper.wayBillNumber;
        //newCaseObj.Subject = (String) caseMap.get('subject') != null ? (String) caseMap.get('subject') : null;
        insert newCaseObj;
 		//Database.UpsertResult resultsacc = Database.upsert(newCaseObj, requestWrapper.CaseNumber ,false);
        newCaseObj = [SELECT Id,CaseNumber FROM Case WHERE Id = :newCaseObj.Id LIMIT 1];
        return newCaseObj;
    }

    public static ResponseWrapper createResponse(String message, String status, String case_number) {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        responseWrapper.message = message;
        responseWrapper.status = status;
        responseWrapper.case_number = case_number;
        return responseWrapper;
    }
    public static string checkValue (String value){
        If(value == 'TO-PAY'){
            return 'To Pay';
        }else if( value == 'PAID'){
            return 'Paid';
        }else if( value == 'CREDIT'){
            return 'Credit';
        }else if( value == 'SURFACE'){
            return 'Surface';
        }else if( value == 'AIR'){
            return 'Air';
        }else{
            return '';
        }
    }
    global class ResponseWrapper {
        global String message;
        global String status;
        global String case_number;

    }

    global class RequestWrapper {
//global Integer CaseNumber;
        global String caseNature;
        global String caseType;
        global String subType;
        global String requesterName;
        global String requesterPhone;
        global String requesterAddress;
        global String pickDateTime;
        global Integer numOfPices;
        global String fromLocn;
        global String toLocn;
        global String fromPincode;
        global String toPincode;
        global String mop;
        global String mode;
        global String emailId;
        global String pickType;
        global Decimal weight;
        global String chatDetails;
        global String source;
        global String remarks;
        global String wayBillNumber;
        global String consigneeName;
        global String reqNo;
    }
    public static String checkFields(RequestWrapper requestWrapper) {
        // Universal check for all type cases
        if (isNullOrBlankString(requestWrapper.caseNature) || isNullOrBlankString(requestWrapper.caseType) ||
                isNullOrBlankString(requestWrapper.subType) || isNullOrBlankString(requestWrapper.remarks) ||
                isNullOrBlankString(requestWrapper.source)) {
            return ConstantUtility.REQUIRED_FIELD_MISSING;
        }
        // check for Booking request
        System.debug('requestWrapper ' + requestWrapper);
        if (requestWrapper.caseType == ConstantUtility.CASE_TYPE_BOOKING_REQUEST && (isNullOrBlankString(requestWrapper.requesterName) ||
                isNullOrBlankString(requestWrapper.requesterPhone) || isNullOrBlankString(requestWrapper.requesterAddress) ||
                isNullOrBlankString(requestWrapper.pickDateTime) || 
                isNullOrBlankString(requestWrapper.fromLocn) || 
                isNullOrBlankString(requestWrapper.fromPincode) || 
                isNullOrBlankString(requestWrapper.emailId)  )) {
            return ConstantUtility.INCOMPLETE_BOOKING_INFORMATION;
        }
        // check for Booking request
        if (requestWrapper.caseType == ConstantUtility.CASE_TYPE_POD && (requestWrapper.wayBillNumber == null || requestWrapper.wayBillNumber == '')) {
            return ConstantUtility.WAYBILL_NUMBER_MISSING;
        }
        return null;
    }

    public static Boolean isNullOrBlankString(String input) {
        return input == null || input == '' ;
    }
}
//}