/**
* @File Name          : CreateCaseApi.cls
* @Description        : This class will used to create Cases in proton using API.
* @Author             : Shubham
* @Group              : Safexpress
* @Last Modified By   : Shubham
* @Last Modified On   : 30/01/2021
**/
public class ProtonCasePostAPI{
    // method to send new case to proton
    @Future(callout=true)
    public static void updatePreBooking(String recordId) { //, String authorisationKey)
        //   string returnInfo = '';
        List<case> updateCase = new List<case>();
        List<PropelI_API_PreBooking__c> protonApis = QueryUtil.getPropelApiInfo(ConstantUtility.PROTON_PRE_BOOKING_UPDATE_API_NAME);
        if (protonApis.size() > 0 && protonApis[0].Endpoint__c != null && protonApis[0].x_api_key__c != null && protonApis[0].userid__c != null) {
            String requestBody = getProtonCaseBody(recordId);
            //    Case caseObj = QueryUtil.getCaseObject(recordId);
            system.debug('JSON:'+ requestBody);
            String endpoint = protonApis[0].Endpoint__c ;
            HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.POST, 'authorization', getProtonAccessToken(), requestBody, ConstantUtility.APPLICATION_JSON, null);
            httpRequest.setHeader('userid', protonApis[0].userid__c);
            httpRequest.setHeader('x-api-key', protonApis[0].x_api_key__c);
            // Sending the API Request
            HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, ConstantUtility.PROPEL_PRE_BOOKING_API_NAME);
            System.debug('httpResponse getBody' + httpResponse);
            System.debug('httpResponse getBody' + httpResponse.getBody());
            if (httpResponse.getStatusCode() != null) {
                system.debug('$$$$$$'+httpResponse.getStatusCode());
                
                
                //  if (httpResponse.getStatusCode() == 200 || httpResponse.getStatusCode() == 400 || httpResponse.getStatusCode() == 502) {
                PreBookingResponseWrapper bookingResponseWrapper = (PreBookingResponseWrapper) JSON.deserialize(httpResponse.getBody(), PreBookingResponseWrapper.class);
                //System.debug(bookingResponseWrapper);
                if (bookingResponseWrapper != null && bookingResponseWrapper.data != null ) {
                    // SUCCESS Condition
                    //     returnInfo.type = ConstantUtility.SUCCESS;
                    //     returnInfo.message = bookingResponseWrapper.message ;
                    //    updateCase(recordId, bookingResponseWrapper.data);
                    //   caseObj.Pre_Booking_Id__c = bookingResponseWrapper.data;
                    //    updateCase.add(caseObj);
                    //    return 'Sucess';
                } else {
                    String errors = '';
                    //     for (cls_error error : bookingResponseWrapper.errors.error) {
                    //         errors += error.description;
                    //      }
                    //     returnInfo.message = errors;
                    //     System.debug(errors);
                    //     returnInfo.type = ConstantUtility.ERROR;
                }
                LoggerUtil.createAPILog('PropelI_UtilClass', 'Create Booking Request, Propel - I', requestBody, httpResponse.getBody(), null);
                //   return returnInfo;
            }
            //    returnInfo.message = ConstantUtility.GETTING_ERROR_FROM_API;
            //  throw new AuraHandledException(returnInfo.message);
            //  update caseObj;
        }
        // returnInfo.message = ConstantUtility.INCOMPLETE_API_INFO_MESSAGE;
        // throw new AuraHandledException(returnInfo.message);
        //update updateCase;
    } 
    @Future(callout=true)
    public static void createPreBooking(String recordId) {  //, String authorisationKey
        //   string returnInfo = '';
        List<PropelI_API_PreBooking__c> protonApis = QueryUtil.getPropelApiInfo(ConstantUtility.PROTON_PRE_BOOKING_API_NAME);
        if (protonApis.size() > 0 && protonApis[0].Endpoint__c != null && protonApis[0].x_api_key__c != null && protonApis[0].userid__c != null) {
            String requestBody = getProtonCaseBody(recordId);
            system.debug('JSON:'+ requestBody);
            String endpoint = protonApis[0].Endpoint__c ;
            HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.POST, 'authorization', getProtonAccessToken(), requestBody, ConstantUtility.APPLICATION_JSON, null);
            httpRequest.setHeader('userid', protonApis[0].userid__c);
            httpRequest.setHeader('x-api-key', protonApis[0].x_api_key__c);
            // Sending the API Request
            HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, ConstantUtility.PROPEL_PRE_BOOKING_API_NAME);
            System.debug('httpResponse getBody' + httpResponse);
            System.debug('httpResponse getBody' + httpResponse.getBody());
            if (httpResponse.getStatusCode() != null) {
                system.debug('$$$$$$'+httpResponse.getStatusCode());
                
                
                //  if (httpResponse.getStatusCode() == 200 || httpResponse.getStatusCode() == 400 || httpResponse.getStatusCode() == 502) {
                PreBookingResponseWrapper bookingResponseWrapper = (PreBookingResponseWrapper) JSON.deserialize(httpResponse.getBody(), PreBookingResponseWrapper.class);
                //System.debug(bookingResponseWrapper);
                if (bookingResponseWrapper != null && bookingResponseWrapper.data != null ) {
                    // SUCCESS Condition
                    //     returnInfo.type = ConstantUtility.SUCCESS;
                    //     returnInfo.message = bookingResponseWrapper.message ;
                    system.debug('##########'+bookingResponseWrapper.data);
                    system.debug('##########'+recordid);
                    updateCase(recordId, bookingResponseWrapper.data);
                    
                    //    return 'Sucess';
                } else {
                    String errors = '';
                    //     for (cls_error error : bookingResponseWrapper.errors.error) {
                    //         errors += error.description;
                    //      }
                    //     returnInfo.message = errors;
                    //     System.debug(errors);
                    //     returnInfo.type = ConstantUtility.ERROR;
                }
                LoggerUtil.createAPILog('PropelI_UtilClass', 'Create Booking Request, Propel - I', requestBody, httpResponse.getBody(), null);
                //   return returnInfo;
            }
            //    returnInfo.message = ConstantUtility.GETTING_ERROR_FROM_API;
            //  throw new AuraHandledException(returnInfo.message);
        }
        // returnInfo.message = ConstantUtility.INCOMPLETE_API_INFO_MESSAGE;
        // throw new AuraHandledException(returnInfo.message);
    }    
    
    public static void updateCase(String recordId, String preBookingId) {
        Case caseObj = QueryUtil.getCaseObject(recordId);
        caseObj.Pre_Booking_Id__c = preBookingId;
        caseObj.Booking_Status__c = ConstantUtility.BOOKING_CREATED;
        TriggerHandler.bypass('CaseTrigger');
        update caseObj;
        TriggerHandler.clearBypass('CaseTrigger');
        
    }
    
    public static string getProtonCaseBody(String caseid){
        Case caseObj = QueryUtil.getCaseObject(caseid);
        User creator = [Select id, name, Email, AD_Id__c from User where id =: caseObj.CreatedById];
        ProtonCaseWrapper prCase = new ProtonCaseWrapper();
        prCase.tokenNo = null;
        prCase.emailId = caseObj.ContactEmail;
        //      prCase.contactAltNo = 'create this new field';
        prCase.contactNo = caseObj.ContactMobile != null ? caseObj.ContactMobile : '';
        sYSTEM.debug('vvvvvvvvvvvvvvvvvvvvv'+ caseObj.ContactMobile);
        prCase.contactName = caseObj.Contact.Name != null ? caseObj.Contact.Name : '';
        prCase.wayblNo = caseObj.WaybillNo__c != null ? caseObj.WaybillNo__c : '';
        prCase.emailId = caseobj.ContactEmail != null ? caseobj.ContactEmail : '';
        prCase.toPincode = caseObj.Consignee_Pincode__c != null ? caseObj.Consignee_Pincode__c : '' ;
        prCase.currentRemarks = getLatestCaseComment(caseid);
        prCase.fullRemarks =    caseObj.Description + getCaseComment(caseid);
        prCase.pickupCompleteDate  = caseObj.LastModifiedDate != null ? string.valueOf(caseObj.LastModifiedDate) : null ;
        system.debug('###################### '+ prCase.pickupCompleteDate );
        prCase.tokenStatus  = caseObj.Status != null ? caseObj.Status : '';
        prCase.consignorAddress  = caseObj.Consignor_Address_Line_1__c +'\n'+ caseObj.Consignor_Address_Line_2__c + '\n'+caseObj.Consignor_Address_Line_3__c + '\n'+caseObj.Consignor_City__c +'\n'+ caseObj.Consignor_Pincode__c +'\n'+ caseObj.Consignor_State__c ;
        prCase.consigneeAddress  = caseObj.Consignee_Address_Line_1__c + '\n'+ caseObj.Consignee_Address_Line_2__c + '\n'+ caseObj.Consignee_Address_Line_3__c + '\n'+ caseObj.Consignee_City__c + '\n'+caseObj.Consignee_Pincode__c+ '\n'+ caseObj.Consignee_State__c ;
        prCase.fromLocation  = caseObj.Origin_City__c != null ? caseObj.Origin_City__c : '';
        prCase.toLocation  = caseObj.Destination_City__c != null ? caseObj.Destination_City__c : '' ; 
        prCase.consignorPincode  = caseObj.Consignor_Pincode__c != null ? caseObj.Consignor_Pincode__c : '' ; 
        prCase.consigneePincode  = caseObj.Consignee_Pincode__c != null ? caseObj.Consignee_Pincode__c : '' ;
        prCase.mode  = caseobj.Transport_Mode__c != null ? caseobj.Transport_Mode__c : '' ;
        prCase.pickupDateTime  = caseObj.PickUp_Date__c != null ? string.valueOf(getDateTimeValue(caseObj.PickUp_Date__c)) : '' ;
        system.debug('$$$$$$$$$$$$$$$$$$$$ '+ prCase.pickupDateTime);
        prCase.product  = caseObj.Product_Type__c != null ? caseObj.Product_Type__c: '' ;
        prCase.contains  = caseObj.Product_Type__c != null ? caseObj.Product_Type__c: '' ;
        prCase.numOfPcs  = caseObj.Total_Package_Count__c != null ? caseObj.Total_Package_Count__c : null ;
        prCase.weightInKg  = caseObj.Total_Weight__c != null ? caseObj.Total_Weight__c : null;
        prCase.mop  = caseObj.Mode_Of_Payment__c != null ? caseObj.Mode_Of_Payment__c : '' ;
        prCase.consigneeName  = caseObj.Consignee_Name__c != null ? caseObj.Consignee_Name__c : '' ;
        prCase.creatorEmailId  = creator.Email != null ? creator.Email : '';
        prCase.creatorUserId  = creator.AD_Id__c !=null ? creator.AD_Id__c : '';
        prCase.salesForceCaseId  = caseObj.CaseNumber != null ? caseObj.CaseNumber : '';
        return JSON.serialize(prCase);
    }
    public static Datetime getDateTimeValue (date d){
        datetime dt = d;
        return d; 
    }
    
    public static string getCaseComment (string CaseId){
        string fullremarks = '';
        List<CaseComment> comments = [SELECT CommentBody,CreatedById,CreatedBy.name,CreatedDate,Id,IsDeleted,IsPublished,LastModifiedById,LastModifiedDate,ParentId,SystemModstamp FROM CaseComment where ParentId =:caseId order by CreatedDate ASC ];
        if(comments.size() > 0){
            for(CaseComment com : comments){
                fullremarks = fullremarks +'\n-------'+ com.CreatedBy.name+'('+ com.CreatedDate+')-------\n'+com.CommentBody;
            }
            return fullremarks;
        }
        return '';
    }
    public static string getLatestCaseComment (string CaseId){
        
        List<CaseComment> comments = [SELECT CommentBody,CreatedById,CreatedBy.name,CreatedDate,Id,IsDeleted,IsPublished,LastModifiedById,LastModifiedDate,ParentId,SystemModstamp FROM CaseComment where ParentId =:caseId order by CreatedDate DESC ];
        if(comments.size() > 0){
            return comments[0].CommentBody;
        }
        return '';
    }
    
    public class ProtonCaseWrapper {
        public String tokenNo;
        public String wayblNo;
        public String contactName;
        public String contactNo;
        //     public String contactAltNo;
        public String emailId;
        public String toPincode;
        public String currentRemarks;
        public String fullRemarks;
        public String pickupCompleteDate;
        public String tokenStatus;
        public String consignorAddress;
        public String consigneeAddress;
        public String fromLocation;
        public String toLocation;
        public String consignorPincode;
        public String consigneePincode;
        public String mode;
        public String pickupDateTime;
        public String product;
        public String contains;
        public Decimal numOfPcs;
        public Decimal weightInKg;
        public String mop;
        public Object loadId;
        public String consigneeName;
        public String creatorEmailId;
        public String creatorUserId;
        public String salesForceCaseId;
    }
    
    public static ProtonCaseWrapper parse(String json) {
        return (ProtonCaseWrapper) System.JSON.deserialize(json, ProtonCaseWrapper.class);
    }
    public class PreBookingResponseWrapper {
        public String message;
        public String data;
        public String responseId;
        public String status;    //SUCCESS
    }
    public class ReturnInfo {
        @AuraEnabled public String type = ConstantUtility.ERROR;
        @AuraEnabled public String message;
    }
    // method to generate Token
     
    public static String getProtonAccessToken() {
        List<PropelI_API_PreBooking__c> propelIApis = QueryUtil.getPropelApiInfo(ConstantUtility.PROTON_PRE_BOOKING_API_TOKEN_NAME);
        //system.debug(propelIApis.size());
        if (propelIApis.size() > 0 && propelIApis[0].Endpoint__c != null && propelIApis[0].Username__c != null && propelIApis[0].Password__c != null) {
            Blob headerValue = Blob.valueOf(propelIApis[0].Username__c + ':' + propelIApis[0].Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            String requestBody = 'grant_type=' + propelIApis[0].grant_type__c + '&scope=' + propelIApis[0].scope__c;
            HttpRequest httpRequest = HttpUtility.getHttpRequest(propelIApis[0].Endpoint__c, ConstantUtility.POST, 'authorization', authorizationHeader, requestBody, ConstantUtility.APPLICATION_JSON, null);
            httpRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, null);
            
            if (httpResponse.getStatusCode() == 200 && httpResponse.getBody() != null) {
                system.debug('########:'+ httpResponse.getStatusCode() );
                system.debug('########:'+ httpResponse.getBody() );
                PropelI_UtilClass.TokenResponseWrapper responseWrapper = (PropelI_UtilClass.TokenResponseWrapper) JSON.deserialize(httpResponse.getBody(), PropelI_UtilClass.TokenResponseWrapper.class);
                if (responseWrapper != null && responseWrapper.access_token != null) {
                    return responseWrapper.access_token;
                    //   system.debug('$$$$$$$$$$$$$:'+ Token);
                }
            }
        }
        return null;
        
    }
    
}