/**
 * @File Name          : PropelI_UtilClass.cls
 * @Description        : This class will have all the methods related Propel-i APIs, Parent class name : PropelI_PreBookingWrapper.cls
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 20-08-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0       20-08-2021                Deepak                   Initial Version
**/

public class PropelI_UtilClass {


    /** =================================== CREATE TICKET METHODS ========================================= */

    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is send the request from salesforce to Propel-i to create new pre-booking Request
    @Date            : 27/09/2021
    */

    @AuraEnabled
    public static String propelCreateTicket(String recordId) {
        ReturnInfo returnInfo = new ReturnInfo();
        try {
            String authorisationKey = getAccessToken();
            if (authorisationKey != null) {
                returnInfo = processPreBooking(recordId, authorisationKey);
            } else {
                returnInfo.message = ConstantUtility.INVALID_ACCESS_TOKEN_ERROR;
                returnInfo.type = ConstantUtility.ERROR;
            }
        } catch (Exception exp) {
            System.debug('Exception Message :: ' + exp.getMessage() + ' Class Name : PropelI_UtilClass at :: ' + exp.getStackTraceString());
            returnInfo.message = returnInfo.message != null ? returnInfo.message : exp.getMessage();
            returnInfo.type = ConstantUtility.ERROR;
            LoggerUtil.createErrorLog('PropelI_UtilClass', 'propelCreateTicket', exp.getTypeName(), returnInfo.message, exp.getStackTraceString(), null);
        }
        return JSON.serialize(returnInfo);
    }


    /**
      @Author          : Deepak
      @Company         : TechMatrix Consulting
      @Description     : This method is used get the authorisation key from propel-i System
      @Date            : 27/09/2021
    */
    public static String getAccessToken() {
        List<PropelI_API_PreBooking__c> propelIApis = QueryUtil.getPropelApiInfo(ConstantUtility.PROPEL_PRE_BOOKING_API_TOKEN_NAME);
        if (propelIApis.size() > 0 && propelIApis[0].Endpoint__c != null && propelIApis[0].Username__c != null && propelIApis[0].Password__c != null) {
            Blob headerValue = Blob.valueOf(propelIApis[0].Username__c + ':' + propelIApis[0].Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            String requestBody = 'grant_type=' + propelIApis[0].grant_type__c + '&scope=' + propelIApis[0].scope__c;
            HttpRequest httpRequest = HttpUtility.getHttpRequest(propelIApis[0].Endpoint__c, ConstantUtility.POST, 'authorization', authorizationHeader, requestBody, ConstantUtility.APPLICATION_JSON, null);
            httpRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, null);
            //System.debug('httpResponse getBody' + httpResponse);
            //System.debug('httpResponse getBody' + httpResponse.getBody());
            if (httpResponse.getStatusCode() == 200 && httpResponse.getBody() != null) {
                TokenResponseWrapper responseWrapper = (TokenResponseWrapper) JSON.deserialize(httpResponse.getBody(), TokenResponseWrapper.class);
                if (responseWrapper != null && responseWrapper.access_token != null) {
                    return responseWrapper.access_token;
                }
            }
        }
        return null;
    }
    /**
        @Author          : Deepak
        @Company         : TechMatrix Consulting
        @Description     : This method is used to process th sf data to propel-I
        @Date            : 27/09/2021
        */
    public static ReturnInfo processPreBooking(String recordId, String authorisationKey) {
        ReturnInfo returnInfo = new ReturnInfo();
        List<PropelI_API_PreBooking__c> propelIApis = QueryUtil.getPropelApiInfo(ConstantUtility.PROPEL_PRE_BOOKING_API_NAME);
        if (propelIApis.size() > 0 && propelIApis[0].Endpoint__c != null && propelIApis[0].x_api_key__c != null && propelIApis[0].userid__c != null) {
            String requestBody = getPreBookingRequestBody(recordId);
            String endpoint = propelIApis[0].Endpoint__c ;
            HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.POST, 'authorization', authorisationKey, requestBody, ConstantUtility.APPLICATION_JSON, null);
            httpRequest.setHeader('userid', propelIApis[0].userid__c);
            httpRequest.setHeader('x-api-key', propelIApis[0].x_api_key__c);
            // Sending the API Request
            HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, ConstantUtility.PROPEL_PRE_BOOKING_API_NAME);
            System.debug('httpResponse getBody' + httpResponse);
            System.debug('httpResponse getBody' + httpResponse.getBody());
            if (httpResponse.getStatusCode() != null) {
                //  if (httpResponse.getStatusCode() == 200 || httpResponse.getStatusCode() == 400 || httpResponse.getStatusCode() == 502) {
                PreBookingResponseWrapper bookingResponseWrapper = (PreBookingResponseWrapper) JSON.deserialize(httpResponse.getBody(), PreBookingResponseWrapper.class);
                //System.debug(bookingResponseWrapper);
                if (bookingResponseWrapper != null && bookingResponseWrapper.data != null && bookingResponseWrapper.data.responseData != null) {
                    // SUCCESS Condition
                    returnInfo.type = ConstantUtility.SUCCESS;
                    returnInfo.message = bookingResponseWrapper.message + ' with Id ' + bookingResponseWrapper.data.responseData;
                    updateCase(recordId, bookingResponseWrapper.data.responseData);
                    return returnInfo;
                } else {
                    String errors = '';
                    for (cls_error error : bookingResponseWrapper.errors.error) {
                        errors += error.description;
                    }
                    returnInfo.message = errors;
                    System.debug(errors);
                    returnInfo.type = ConstantUtility.ERROR;
                }
                LoggerUtil.createAPILog('PropelI_UtilClass', 'Create Booking Request, Propel - I', requestBody, httpResponse.getBody(), null);
                return returnInfo;
            }
            returnInfo.message = ConstantUtility.GETTING_ERROR_FROM_API;
            throw new AuraHandledException(returnInfo.message);
        }
        returnInfo.message = ConstantUtility.INCOMPLETE_API_INFO_MESSAGE;
        throw new AuraHandledException(returnInfo.message);
    }

    /**
      @Author          : Deepak
      @Company         : TechMatrix Consulting
      @Description     : This method is create the request blob body for OTRS Create Ticket.
      @Date            : 27/09/2021
      */
    public static String getPreBookingRequestBody(String recordId) {

        Case caseObj = QueryUtil.getCaseObject(recordId);
        String msaOCode ;
        msaOCode = caseObj.SFX__c != null ? caseObj.SFX__r.MSA__c : null;
        msaOCode = caseObj.PRC__c != null ? caseObj.PRC__r.MSA__c : null;

        String sfxPrcCode;


        PropelI_PreBookingWrapper preBookingWrapper = new PropelI_PreBookingWrapper();
        preBookingWrapper.bookingChannel = caseObj.Origin;// 'WEB'; // caseObj.Origin != null ? caseObj.Origin : '';
        preBookingWrapper.branchCode = caseObj.Business_Type__c != ConstantUtility.BUSINESS_TYPE_RETAIL_NON_PRC && caseObj.Origin_Branch_Code__c != null ? caseObj.Origin_Branch_Code__c : '';
        preBookingWrapper.businessType = caseObj.Business_Type__c != null ? caseObj.Business_Type__c : '';


        preBookingWrapper.commercialId = caseObj.Commercial_Id__c != null ? Integer.valueOf(caseObj.Commercial_Id__c) : null;

        preBookingWrapper.customerReferenceNumber = caseObj.Customer_Reference_Number__c != null ? caseObj.Customer_Reference_Number__c : null;

        preBookingWrapper.customerType = caseObj.Customer_Type__c != null ? caseObj.Customer_Type__c : '';

        preBookingWrapper.msaCode = msaOCode != null ? msaOCode : null; 
        // preBookingWrapper.msaCode = 900738;

        preBookingWrapper.pickupDate = caseObj.PickUp_Date__c != null ? String.valueOf(caseObj.PickUp_Date__c) : '';
        // MAPPING OF TIME FROM TIME SLOT
        if (caseObj.PickUp_Time__c != null && ConstantUtility.TIME_SLOT_MAP.containsKey(caseObj.PickUp_Time__c)) {
            preBookingWrapper.pickupTime = ConstantUtility.TIME_SLOT_MAP.get(caseObj.PickUp_Time__c);
        }
        preBookingWrapper.productCategoryName = caseObj.Product_Type__c;
        preBookingWrapper.rateCard = caseObj.Rate_Card__c != null ? String.valueOf(caseObj.Rate_Card__c) : '';
        preBookingWrapper.safexperienceReferenceNumber = Integer.valueOf(caseObj.CaseNumber);
        preBookingWrapper.safexperienceRemarks = caseObj.Safexperience_Remarks__c != null ? caseObj.Safexperience_Remarks__c : '';
        preBookingWrapper.serviceOffering = caseObj.Transport_Mode__c != null ? caseObj.Transport_Mode__c : '';
        sfxPrcCode = caseObj.SFX__c != null ? caseObj.SFX__r.Name : caseObj.PRC__r.Name;
        preBookingWrapper.sfxPrcCode = sfxPrcCode;
        // preBookingWrapper.sfxPrcCode = 'SFX00000029';

        preBookingWrapper.source = caseObj.Origin;
        preBookingWrapper.source = 'ServiceCloud';

        preBookingWrapper.totalPackageCount = caseObj.Total_Package_Count__c != null ? Integer.valueOf(caseObj.Total_Package_Count__c) : null;
        preBookingWrapper.totalWeight = caseObj.Total_Weight__c != null ? Integer.valueOf(caseObj.Total_Weight__c) : null;


        /** CONSIGNEE INFORMATION  */
        PropelI_PreBookingWrapper.cls_addrBook consigneeAddrBook = new PropelI_PreBookingWrapper.cls_addrBook();
        consigneeAddrBook.addr1 = caseObj.Consignee_Address_Line_1__c != null ? caseObj.Consignee_Address_Line_1__c : '';
        consigneeAddrBook.addr2 = caseObj.Consignee_Address_Line_2__c != null ? caseObj.Consignee_Address_Line_2__c : '';
        consigneeAddrBook.addr3 = caseObj.Consignee_Address_Line_3__c != null ? caseObj.Consignee_Address_Line_3__c : '';
        consigneeAddrBook.pincode = caseObj.Consignee_Pincode__c != null ? Integer.valueOf(caseObj.Consignee_Pincode__c) : null;
        PropelI_PreBookingWrapper.cls_consignee consignee = new PropelI_PreBookingWrapper.cls_consignee();
        consignee.addrBook = consigneeAddrBook;
        consignee.email = caseObj.Consignee_Email__c != null ? caseObj.Consignee_Email__c : '';
        consignee.gstinNum = caseObj.Consignee_GSTIN_Number__c != null ? caseObj.Consignee_GSTIN_Number__c : '';
        consignee.id = caseObj.Consignee_Id__c != null ? Integer.valueOf(caseObj.Consignee_Id__c) : null;
        consignee.mob = caseObj.Consignee_Phone__c != null ? caseObj.Consignee_Phone__c : '';
        consignee.name = caseObj.Consignee_Name__c != null ? caseObj.Consignee_Name__c : '';
        consignee.panNum = caseObj.Consignee_PAN_Number__c != null ? caseObj.Consignee_PAN_Number__c : '';
        consignee.tanNum = caseObj.Consignee_TAN_Number__c != null ? caseObj.Consignee_TAN_Number__c : '';
        preBookingWrapper.consignee = consignee;

        /** CONSIGNOR INFORMATION  */
        PropelI_PreBookingWrapper.cls_addrBook consignorAddrBook = new PropelI_PreBookingWrapper.cls_addrBook();
        consignorAddrBook.addr1 = caseObj.Consignor_Address_Line_1__c != null ? caseObj.Consignor_Address_Line_1__c : '';
        consignorAddrBook.addr2 = caseObj.Consignor_Address_Line_2__c != null ? caseObj.Consignor_Address_Line_2__c : '';
        consignorAddrBook.addr3 = caseObj.Consignor_Address_Line_3__c != null ? caseObj.Consignor_Address_Line_3__c : '';
        consignorAddrBook.pincode = caseObj.Consignor_Pincode__c != null ? Integer.valueOf(caseObj.Consignor_Pincode__c) : null;
        PropelI_PreBookingWrapper.cls_consignor consignor = new PropelI_PreBookingWrapper.cls_consignor();
        consignor.addrBook = consignorAddrBook;
        consignor.email = caseObj.Consignor_Email__c != null ? caseObj.Consignor_Email__c : '';
        consignor.gstinNum = caseObj.Consignor_GSTIN_Number__c != null ? caseObj.Consignor_GSTIN_Number__c : '';
        consignor.id = caseObj.Consignor_Id__c != null ? Integer.valueOf(caseObj.Consignor_Id__c) : null;
        consignor.mob = caseObj.Consignor_Phone__c != null ? caseObj.Consignor_Phone__c : '';
        consignor.name = caseObj.Consignor_Name__c != null ? caseObj.Consignor_Name__c : '';
        consignor.panNum = caseObj.Consignor_PAN_Number__c != null ? caseObj.Consignor_PAN_Number__c : '';
        consignor.tanNum = caseObj.Consignor_TAN_Number__c != null ? caseObj.Consignor_TAN_Number__c : '';
        preBookingWrapper.consignor = consignor;


        return JSON.serialize(preBookingWrapper);
    }

    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is create the request blob body for OTRS Create Ticket.
    @Date            : 27/09/2021
    */
    public static void updateCase(String recordId, Integer preBookingId) {
        Case caseObj = QueryUtil.getCaseObject(recordId);
        caseObj.Pre_Booking_Id__c = String.valueOf(preBookingId);
        caseObj.Booking_Status__c = ConstantUtility.BOOKING_CREATED;
        TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
        update caseObj;
        TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);

    }
    /**  ========================== RETURN RESPONSE WRAPPER TO LWC COMPONENT ============================= */
    public class TokenResponseWrapper {
        public String access_token ;
        public Integer expires_in;
        public String token_type;
    }

    /**  ================================== RETURN RESPONSE WRAPPER FROM PRE-BOOKING API ====================================== */

    public class PreBookingResponseWrapper {
        public String message;
        public cls_data data;
        public cls_errors errors;
        public String status;    //SUCCESS
    }
    public class cls_data {
        public Integer responseData;    //932218
    }
    public class cls_errors {
        public cls_error[] error;
    }
    public class cls_error {
        public String code;    //VAL_PBR_7009
        public String description;    //Duplicate Safexperience Reference number not allowed.
    }


    /**  ========================== RETURN RESPONSE WRAPPER TO LWC COMPONENT ============================= */
    public class ReturnInfo {
        @AuraEnabled public String type = ConstantUtility.ERROR;
        @AuraEnabled public String message;
    }
}