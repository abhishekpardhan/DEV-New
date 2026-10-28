/**
* @File Name          : CreateCaseApi.cls
* @Description        : This class will used to create Cases in salesforce using API.
* @Author             : Shubham
* @Group              : Safexpress
* @Last Modified By   : Shubham
* @Last Modified On   : 30/01/2021
**/
@RestResource(urlMapping='/ProtonUpdateSupportCase/*')
global with sharing class ProtonCaseUpdateAPI {
    

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
                
                
                if (requestWrapper != null) {
                    String fieldCheckMessage = checkFields(requestWrapper);
                    if (fieldCheckMessage == null) {
                        List<Case> existingCases = new List<Case>();
                        Date pickupDate = Date.valueOf(requestWrapper.pickDateTime);
                        String caseNature = requestWrapper.caseNature;
                        String caseType = requestWrapper.caseType;
                        String wayBillNumber = requestWrapper.wayBillNumber;
                        
                        if(caseType == ConstantUtility.CASE_TYPE_BOOKING_REQUEST){
               /*             existingCases = [
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
                                AND IsClosed = false
                                LIMIT 1
                            ];
                        }
                        if (existingCases.size() > 0) {
                            responseWrapper = createResponse(ConstantUtility.DUPLICATE_CASE_FOUND, ConstantUtility.SUCCESS.toLowerCase(), existingCases[0].CaseNumber);
                        } else {
*/
                            Case caseObj = createNewCase(requestWrapper);
                            responseWrapper = createResponse(ConstantUtility.CASE_UPDATED_SUCCESS, ConstantUtility.SUCCESS.toLowerCase(), caseObj.CaseNumber);
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
        Case newCaseObj = [SELECT Subject,Description,CaseNumber,ContactMobile,OTRS_Remarks__c,OTRS_Request_Status__c,OTRS_Ticket_No__c, WaybillNo__c, Sub_Type__c,Origin,Consignee_Name__c,Transport_Mode__c,Product_Type__c,Consignee_Address_Line_1__c,Consignee_Address_Line_2__c,Consignee_Address_Line_3__c,Consignee_Pincode__c,Consignee_Id__c,Consignee_Email__c,Consignee_GSTIN_Number__c,Consignee_Phone__c,Consignee_PAN_Number__c,Consignee_TAN_Number__c,Consignor_Name__c,SFX__r.MSA__c,PRC__r.MSA__c,SFX__c,PRC__c,SFX__r.Name,PRC__r.Name, Consignor_Address_Line_1__c,Consignor_Address_Line_2__c,Consignor_Address_Line_3__c,Consignor_Pincode__c,Consignor_Id__c,Consignor_Email__c,Consignor_GSTIN_Number__c,Consignor_Phone__c,Consignor_PAN_Number__c,Consignor_TAN_Number__c,Booking_Channel__c,Origin_Branch__c,Business_Type__c,Commercial_Id__c,Customer_Reference_Number__c,Customer_Type__c,Consignor_MSA_Cust_Id__c,PickUp_Date__c,PickUp_Time__c,Product_Category_Id__c,Rate_Card__c,Safexperience_Reference_Number__c,Safexperience_Remarks__c,Service_Offering__c,SFX_PRC_Code__c,Source_Booking_Id__c,Total_Package_Count__c,Total_Weight__c,Origin_Branch_Code__c,Main_Category__c,Sub_Category__c,Issue_Type__c,CreatedById,ContactPhone,ContactId,ContactEmail,LastModifiedDate,status,Consignor_City__c, Consignee_City__c,Consignee_State__c,Consignor_State__c,No_of_Pcs__c,Mode_Of_Payment__c,Contact.Name,Origin_City__c,Destination_City__c FROM Case WHERE CaseNumber = :requestWrapper.caseNumber LIMIT 1];
        newCaseObj.status = requestWrapper.status;
        newCaseObj.ContactId = contacts[0].Id ;
        newCaseObj.Case_Nature__c = requestWrapper.caseNature;
        newCaseObj.Case_Type__c = requestWrapper.caseType;
        newCaseObj.Sub_Type__c = requestWrapper.subType;
        newCaseObj.Consignor_Name__c = requestWrapper.requesterName;
        newCaseObj.Consignor_Address_Line_1__c = requestWrapper.fromLocn;  //requestWrapper.fromLocn
        newCaseObj.Consignor_Phone__c = requestWrapper.requesterPhone;
        newCaseObj.Origin_Pincode__c = requestWrapper.fromPincode;
        newCaseObj.Consignor_Pincode__c = requestWrapper.fromPincode;
        newCaseObj.Destination_PinCode__c = requestWrapper.toPincode;
        newCaseObj.Consignee_Pincode__c = requestWrapper.toPincode;
        newCaseObj.Consignor_Email__c = requestWrapper.emailId;
        newCaseObj.Mode_Of_Payment__c = ProtonCreateCaseAPI.checkValue(requestWrapper.mop);
        newCaseObj.Transport_Mode__c = ProtonCreateCaseAPI.checkValue(requestWrapper.mode);
        newCaseObj.Pickup_Type__c = requestWrapper.pickType;
        newCaseObj.Total_Weight__c = requestWrapper.weight;
        newCaseObj.Origin = requestWrapper.source;
       // newCaseObj.Description = requestWrapper.chatDetails;
        newCaseObj.Origin_Address__c = requestWrapper.fromLocn;
        newCaseObj.From_Location__c = requestWrapper.fromLocn;
        newCaseObj.To_Location__c = requestWrapper.toPincode;
        newCaseObj.Destination_Address__c = requestWrapper.toPincode;
        
        newCaseObj.PickUp_Date__c = Date.valueOf(requestWrapper.pickDateTime);
        newCaseObj.PickUp_To_Time__c = String.valueOf(Datetime.valueOf(requestWrapper.pickDateTime).time());
        newCaseObj.Total_Package_Count__c = requestWrapper.numOfPices;
        newCaseObj.Description = requestWrapper.remarks;
        newCaseObj.WaybillNo__c = requestWrapper.wayBillNumber;

        update newCaseObj;
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
    global class ResponseWrapper {
        global String message;
        global String status;
        global String case_number;
        
    }
    
    global class RequestWrapper {
        global String status;
        global String caseNumber;
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
        global String mop;
        global String mode;
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