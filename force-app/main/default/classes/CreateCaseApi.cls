/**
 * @File Name          : CreateCaseApi.cls
 * @Description        : This class will used to create Cases in salesforce using API.
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Rudra Singh | GT Bharat
 * @Last Modified On   : 12/06/2026
 * @Modification Log   :
 *==============================================================================
 * Ver         Date            Author                  Modification
 *==============================================================================
 * 1.0        13/09/2021       Deepak                  Initial Version
 * 2.0        08/06/2026       Sahil Jain              Added Waybill Enquiry case type support for
 *                                                     Enterprise App (/CreateSupportCase endpoint)
 * 3.0        12/06/2026       Rudra Singh             Fixed Complaint duplicate check — scoped by
 *                                                     Case_Nature__c to prevent cross-type blocking;
 *                                                     fixed Description double-assignment (chatDetails
 *                                                     was overwritten by remarks); removed dead code
 *                                                     (unused caseFieldMap and case newCase variables)
**/
@RestResource(urlMapping='/CreateSupportCase/*')
global with sharing class CreateCaseApi {

    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to create salesforce support Case in salesforce from external system
    @Date            : 13/09/2021
    */
     /**
    @Author          : Sahil Jain
    @Company         : Grand Throtan
    @Description     : This method is used to create salesforce support Case in salesforce from external system
    @Date            : 08/06/2026
    */
    @HttpPost
    global static void createCase() {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        RestRequest request = RestContext.request; //RestRequest for the Apex REST method
        String requestBody = request.requestBody != null ? request.requestBody.toString() : '';
        try {
            if (!String.isBlank(requestBody)) {
                RequestWrapper requestWrapper = (RequestWrapper) System.JSON.deserialize(requestBody, RequestWrapper.class);


                if (requestWrapper != null) {
                    String fieldCheckMessage = checkFields(requestWrapper);
                    if (fieldCheckMessage == null) {
                        List<Case> existingCases = new List<Case>();
                        Date pickupDate;
                        String caseNature = requestWrapper.caseNature;
                        String caseType = requestWrapper.caseType;
                        String subType = requestWrapper.subType;
                        String source = requestWrapper.source;
                        
                        
                        if(requestWrapper.pickDateTime !=null){
                              pickupDate = Date.valueOf(requestWrapper.pickDateTime);
                        }
                        
                        String wayBillNumber = requestWrapper.wayBillNumber;

                        if(caseType == ConstantUtility.CASE_TYPE_BOOKING_REQUEST){
                            existingCases = [
                                    SELECT Id,ContactMobile,CaseNumber
                                    FROM Case
                                    WHERE ContactMobile = :requestWrapper.requesterPhone
                                    AND Origin_Pincode__c = :requestWrapper.fromPincode AND Destination_PinCode__c = :requestWrapper.toPincode
                                    AND Case_Type__c = :ConstantUtility.CASE_TYPE_BOOKING_REQUEST
                                    AND IsClosed = false AND  PickUp_Date__c = :pickupDate
                                    LIMIT 1
                            ];
                        }
                        else if(caseNature == ConstantUtility.CASE_NATURE_COMPLAINT){
                            existingCases = [
                                    SELECT Id,ContactMobile,CaseNumber
                                    FROM Case
                                    WHERE ContactMobile = :requestWrapper.requesterPhone
                                    AND WaybillNo__c = :wayBillNumber
                                    AND Case_Nature__c = :ConstantUtility.CASE_NATURE_COMPLAINT
                                    AND IsClosed = false
                                    LIMIT 1
                            ];
                        }
                        else if(requestWrapper.caseNature==ConstantUtility.CASE_NATURE_ENQUIRY && requestWrapper.caseType==ConstantUtility.CASE_TYPE_WAYBILL_ENQUIRY && requestwrapper.subType==ConstantUtility.CASE_SUB_TYPE_OTHERS ){
                             existingCases = [
                                    SELECT Id,ContactMobile,CaseNumber
                                    FROM Case
                                    WHERE ContactMobile = :requestWrapper.requesterPhone
                                    AND WaybillNo__c = :wayBillNumber
                                    AND RecordTypeId= : ConstantUtility.ENQUIRY_SUPPORT_CASE_RECORDTYPE_ID
                                    AND IsClosed = false 
                                    LIMIT 1
                            ];

                        }
                    
                        if (existingCases.size() > 0) {
                            responseWrapper = createResponse(ConstantUtility.DUPLICATE_CASE_FOUND, ConstantUtility.SUCCESS.toLowerCase(), existingCases[0].CaseNumber);
                        } else {
                            system.debug('requestWrapper-->'+requestWrapper);
                            Case caseObj = createNewCase(requestWrapper);
                            responseWrapper = createResponse(ConstantUtility.CASE_CREATED_SUCCESS, ConstantUtility.SUCCESS.toLowerCase(), caseObj.CaseNumber);
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
            newCaseObj.Case_Nature__c = requestWrapper.caseNature;
            newCaseObj.Case_Type__c = requestWrapper.caseType;
            newCaseObj.Sub_Type__c = requestWrapper.subType;
            newCaseObj.Consignor_Name__c = requestWrapper.requesterName;
            newCaseObj.Consignor_Phone__c = requestWrapper.requesterPhone;
            newCaseObj.Consignor_Email__c = requestWrapper.emailId;
            newCaseObj.Description = requestWrapper.chatDetails != null ? requestWrapper.chatDetails : '';
            if (requestWrapper.remarks != null && requestWrapper.remarks != '') {
                newCaseObj.Description += (newCaseObj.Description != '' ? '\n' : '') + requestWrapper.remarks;
            }
            newCaseObj.WaybillNo__c = requestWrapper.wayBillNumber;
            newCaseObj.Origin = requestWrapper.source;
            newCaseObj.Status = ConstantUtility.NEW_STATUS;
            newCaseObj.ContactId = contacts[0].Id ;
            newCaseObj.RecordTypeId = ConstantUtility.ENQUIRY_SUPPORT_CASE_RECORDTYPE_ID;
        if(requestWrapper.caseNature!=ConstantUtility.CASE_NATURE_ENQUIRY && requestWrapper.caseType!=ConstantUtility.CASE_TYPE_WAYBILL_ENQUIRY && requestwrapper.subType!=ConstantUtility.CASE_SUB_TYPE_OTHERS && requestWrapper.source!=ConstantUtility.CASE_ORIGIN_ENTERPRISE_APP){
           newCaseObj.RecordTypeId = ConstantUtility.BOOKING_REQUEST_SUPPORT_CASE_RECORDTYPE_ID;
            newCaseObj.Consignor_Address_Line_1__c = requestWrapper.requesterAddress;
            newCaseObj.Origin_Pincode__c = requestWrapper.fromPincode;
            newCaseObj.Consignor_Pincode__c = requestWrapper.fromPincode;
            newCaseObj.Destination_PinCode__c = requestWrapper.toPincode;
            newCaseObj.Consignee_Pincode__c = requestWrapper.toPincode;
            newCaseObj.Pickup_Type__c = requestWrapper.pickType;
            newCaseObj.Total_Weight__c = requestWrapper.weight;
            newCaseObj.Origin_Address__c = requestWrapper.fromLocn;
            newCaseObj.From_Location__c = requestWrapper.fromLocn;
            newCaseObj.To_Location__c = requestWrapper.toPincode;
            newCaseObj.Destination_Address__c = requestWrapper.toPincode;
            newCaseObj.PickUp_Date__c = Date.valueOf(requestWrapper.pickDateTime);
            newCaseObj.PickUp_To_Time__c = String.valueOf(Datetime.valueOf(requestWrapper.pickDateTime).time());
            newCaseObj.Total_Package_Count__c = requestWrapper.numOfPices;
        }
        
       
       
      
       
        
       
        //newCaseObj.Subject = (String) caseMap.get('subject') != null ? (String) caseMap.get('subject') : null;
        insert newCaseObj;
        newCaseObj = [SELECT Id,CaseNumber FROM Case WHERE Id = :newCaseObj.Id LIMIT 1];
        return newCaseObj;
    }
    /**
       @Author          : Deepak
       @Company         : TechMatrix Consulting
       @Description     : This method is used to create the response in Wrapper format
       @Date            : 13-09-2021
   */
    public static ResponseWrapper createResponse(String message, String status, String case_number) {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        responseWrapper.message = message;
        responseWrapper.status = status;
        responseWrapper.case_number = case_number;
        return responseWrapper;
    }

    global class ResponseWrapper {
        global String message;
        global String status;
        global String case_number;
      
    }

    global class RequestWrapper {
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
        global String emailId;
        global String pickType;
        global Decimal weight;
        global String chatDetails;
        global String source;
        global String remarks;
        global String wayBillNumber;

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
       /* if (requestWrapper.caseType == ConstantUtility.CASE_TYPE_BOOKING_REQUEST && (isNullOrBlankString(requestWrapper.requesterName) ||
                isNullOrBlankString(requestWrapper.requesterPhone) || isNullOrBlankString(requestWrapper.requesterAddress) ||
                isNullOrBlankString(requestWrapper.pickDateTime) || requestWrapper.numOfPices == null ||
                isNullOrBlankString(requestWrapper.fromLocn) || isNullOrBlankString(requestWrapper.toLocn) ||
                isNullOrBlankString(requestWrapper.fromPincode) || isNullOrBlankString(requestWrapper.toPincode) ||
                isNullOrBlankString(requestWrapper.emailId) || isNullOrBlankString(requestWrapper.pickType) ||
                requestWrapper.weight == null || isNullOrBlankString(requestWrapper.chatDetails))) {
            return ConstantUtility.INCOMPLETE_BOOKING_INFORMATION;
        }*/
        // check for Booking request
       /* if (requestWrapper.caseType == ConstantUtility.CASE_TYPE_POD && (requestWrapper.wayBillNumber == null || requestWrapper.wayBillNumber == '')) {
            return ConstantUtility.WAYBILL_NUMBER_MISSING;
        }*/
        return null;
    }

    public static Boolean isNullOrBlankString(String input) {
        return input == null || input == '' ;
    }
}