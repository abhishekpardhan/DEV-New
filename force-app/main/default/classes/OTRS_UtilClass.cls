/**
* @File Name          : OTRS_UtilClass.cls
* @Description        : This class will have all the methods related OTRS APIs
* @Author             : Deepak
* @Group              : Techmatrix
* @Last Modified By   : Deepak
* @Last Modified On   : 12-07-2021
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        12-07-2021                Deepak                   Initial Version
**/

public class OTRS_UtilClass {
    
    /** =================================== CREATE TICKET METHODS ========================================= */
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is send the request from salesforce to OTRS to create new Ticket
@Date            : 12/07/2021
*/
    @AuraEnabled
    public static String OTRSCreateTicket(String recordId) {
        
        ReturnInfo returnInfo = new ReturnInfo();
        try {
            if (recordId == null) {
                returnInfo.message = ConstantUtility.INVALID_CASE_ID;
                throw new AuraHandledException(returnInfo.message);
            }
            List<Safex_API__c> wayApiInfo = QueryUtil.getSafexApiInfo(ConstantUtility.OTRS_CREATE_TICKET_API_NAME);
            if (wayApiInfo.size() > 0 && wayApiInfo[0].Endpoint__c != null && wayApiInfo[0].Access_Key__c != null && wayApiInfo[0].Customer_User_Login__c != null) {
                Case cseObj = QueryUtil.getCaseObject(recordId);
                HttpResponse httpres = getDuplicateTicket(wayApiInfo[0].Access_Key__c,cseObj.WaybillNo__c);
                String docStatus = '';
                Integer tnumber;
                Map<String,Object> responseMap = new Map<String,Object>();
                if(httpres.getStatusCode() == 200) {
                    responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpres.getBody());
                    System.debug(responseMap.get('docStatus'));
                    docStatus = (String)responseMap.get('docStatus');   
                }
                if (docStatus != '' && docStatus == 'No') {
                    String endpoint = wayApiInfo[0].Endpoint__c + '?access_key=' + wayApiInfo[0].Access_Key__c + '&' + 'CustomerUserLogin=' + wayApiInfo[0].Customer_User_Login__c;
                    System.debug(endpoint);
                    Blob requestBodyBlob = getOTRSCreateTicketRequestBody(recordId, wayApiInfo[0].Customer_User_Login__c);
                    System.debug('requestBodyBlob'+requestBodyBlob);
                    String contentLength = String.valueOf(requestBodyBlob.size());
                    system.debug('contentLength'+contentLength);
                    String contentType = HttpFormBuilder.GetContentType();
                    system.debug('contentType'+contentType);
                    HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.POST, 'Accept', ConstantUtility.APPLICATION_JSON, null, ConstantUtility.APPLICATION_JSON, requestBodyBlob);
                    // Setting other params
                    httpRequest.setHeader('Content-Length', contentLength);
                    httpRequest.setHeader('Content-Type', contentType);  
                    // string requestBody = ;
                    Integer jsonStartIndex = httpRequest.getBody().indexOf('Ticket');
                    String jsonPart = httpRequest.getBody().substring(jsonStartIndex);  
                    String hash = HttpUtility.createHashMap(jsonPart);
                    System.debug('hash-->'+hash);
                    //list<API_Logger__c> duplicateApiLogger = new list<API_Logger__c>();
                   // duplicateApiLogger = [select Id from api_logger__c where Request_Hash__c =:hash And CreatedDate = TODAY];
                    HttpResponse httpResponse;
                    //if(duplicateApiLogger.size() == 0){
                       /*httpResponse = HttpUtility.makeCallout(httpRequest, ConstantUtility.OTRS_CREATE_TICKET_API_NAME); 
System.debug('httpResponse getBody' + httpResponse.getBody());
if (httpResponse.getStatusCode() == 200) {
returnInfo.message = httpResponse.getBody();
returnInfo.type = ConstantUtility.SUCCESS;
return JSON.serialize(returnInfo);
}*/
                        
                        // Step 1: Log Request (Insert)
                        Id loggerId = LoggerUtil.createOrUpdateAPILog(new API_Logger__c(), true, ConstantUtility.OTRS_CREATE_TICKET_API_NAME, httpRequest.getEndpoint(),httpRequest.getBody(), null, null);
                        String requestHash = [SELECT Request_Hash__c FROM API_Logger__c WHERE Id = :loggerId].Request_Hash__c;
                        List<API_Logger__c> loggers = [SELECT Id,Request_Hash__c FROM API_Logger__c WHERE Request_Hash__c =:requestHash And CreatedDate = TODAY];
                        if(String.isnotEmpty(requestHash) && loggers.size()==1){
                            System.enqueueJob(new OTRSCalloutJob(
                                loggerId,
                                ConstantUtility.OTRS_CREATE_TICKET_API_NAME,
                                endpoint, requestBodyBlob, contentLength, contentType,recordId
                            ));
                            returnInfo.message = 'Please wait, OTRS API is enqueued';
                            returnInfo.type = ConstantUtility.SUCCESS;
                            return JSON.serialize(returnInfo);
                        }   
                   // }
                    else if(!loggers.isEmpty() || loggers[0].Request_Hash__c != null || loggers.size()>1){
                        returnInfo.message = 'Please wait, OTRS API is running';
                        return JSON.serialize(returnInfo);
                    }
                    returnInfo.message = ConstantUtility.GETTING_ERROR_FROM_API;
                    throw new AuraHandledException(returnInfo.message);
                    
                }
                else if(docStatus != '' && docStatus == 'Yes') {
                    // Get the 'response' map
                    Map<String, Object> responseDetails = (Map<String, Object>)responseMap.get('response');
                    // Get the 'TicketDetail' map
                    Map<String, Object> ticketDetail = (Map<String, Object>)responseDetails.get('TicketDetail');
                    // Get the 'tnumber'
                    tnumber = (Integer)ticketDetail.get('tnumber');
                    System.debug('tnumber-->'+tnumber);
                    String tnumberStr = String.valueOf(tnumber);
                    returnInfo.message = tnumberStr + ' ticket number already exist in OTRS.';
                    returnInfo.type = ConstantUtility.SUCCESS;
                    updateOTRSTicketOnCase(tnumberStr,recordId);
                    return JSON.serialize(returnInfo);
                    //throw new AuraHandledException(returnInfo.message);
                    
                }
            }
            returnInfo.message = ConstantUtility.INCOMPLETE_API_INFO_MESSAGE;
            throw new AuraHandledException(returnInfo.message);
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : OTRS_UtilClass at Line :: ' + exp.getLineNumber());
            returnInfo.message = returnInfo.message != null ? returnInfo.message : exp.getMessage();
            returnInfo.type = ConstantUtility.ERROR;
            LoggerUtil.createErrorLog('OTRS_UtilClass', 'OTRSCreateTicket', exp.getTypeName(), returnInfo.message, exp.getStackTraceString(), null);
        }
        return JSON.serialize(returnInfo);
    }
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is create the request blob body for OTRS Create Ticket.
@Date            : 12/07/2021
*/
    public static Blob getOTRSCreateTicketRequestBody(String recordId, String requesterUserId) {
        Case cseObj = QueryUtil.getCaseObject(recordId);
        OTRS_CreateTicketRequestWrapper wrapper = new OTRS_CreateTicketRequestWrapper();
        wrapper.Ticket = new OTRS_CreateTicketRequestWrapper.cls_Ticket();
        wrapper.Ticket.Title = cseObj.Subject != null ? cseObj.Subject : '';
        wrapper.Ticket.CustomerUser = requesterUserId;
        wrapper.Article = new OTRS_CreateTicketRequestWrapper.cls_Article();
        wrapper.Article.Subject = cseObj.Subject != null ? cseObj.Subject : '' + '-' + Datetime.now();
        wrapper.Article.Body = cseObj.Description ;
        wrapper.DynamicField = new List<OTRS_CreateTicketRequestWrapper.cls_DynamicField>();
        
        /**  For MainCategory */
        OTRS_CreateTicketRequestWrapper.cls_DynamicField obj = new OTRS_CreateTicketRequestWrapper.cls_DynamicField();
        obj.Name = 'MainCategory';
        obj.Value = cseObj.Main_Category__c; // Static Value
        wrapper.DynamicField.add(obj);
        /**  For SubCategory */
        obj = new OTRS_CreateTicketRequestWrapper.cls_DynamicField();
        obj.Name = 'SubCategory';
        obj.Value = cseObj.Sub_Category__c; // Static Value
        obj.Value = 'null';
        wrapper.DynamicField.add(obj);
        /**  For IssueType */
        obj = new OTRS_CreateTicketRequestWrapper.cls_DynamicField();
        obj.Name = 'IssueType';
        obj.Value = 'null';
        // obj.Value = cseObj.Issue_Type__c != null ? cseObj.Issue_Type__c : '';  // Rebooking // Redirection // DODCancellation // AddressChange
        wrapper.DynamicField.add(obj);
        /**  For Phone2 */
        obj = new OTRS_CreateTicketRequestWrapper.cls_DynamicField();
        obj.Name = 'Phone2';
        obj.Value = cseObj.ContactMobile;
        wrapper.DynamicField.add(obj);
        /**  For Region */
        obj = new OTRS_CreateTicketRequestWrapper.cls_DynamicField();
        obj.Name = 'Region';
        obj.Value = 'Central'; // Static Value
        wrapper.DynamicField.add(obj);
        /**  For TImpact */
        obj = new OTRS_CreateTicketRequestWrapper.cls_DynamicField();
        obj.Name = 'TImpact';
        obj.Value = 'High'; // Static Value
        wrapper.DynamicField.add(obj);
        /**  For WayBillNumber */
        obj = new OTRS_CreateTicketRequestWrapper.cls_DynamicField();
        obj.Name = 'DocumentNo';
        obj.Value = cseObj.WaybillNo__c;
        wrapper.DynamicField.add(obj);
        
        System.debug(JSON.serialize(wrapper)); //OTRS_UtilClass.getOTRSCreateTicketRequestBody('500C5000002GrnmIAC','safeforce1');
        String form64 = HttpFormBuilder.append('data', JSON.serialize(wrapper));
        //adding documents body with file parameter if we are sending the files as well
        //  blob formBlob= HttpFormBuilder.makeBlobWithFile('file',aa.Body,aa.Name,form64);
        Blob formBlob = EncodingUtil.base64Decode(form64);
        system.debug(formBlob);
        
        return formBlob;
    }
    @AuraEnabled
    public static String updateOTRSTicketOnCase(String otrsTicketNumber, String recordId) {
        ReturnInfo returnInfo = new ReturnInfo();
        try {
            Case cseObj = QueryUtil.getCaseObject(recordId);
            cseObj.OTRS_Ticket_No__c = otrsTicketNumber;
            TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
            update cseObj;
            TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);
            returnInfo.type = ConstantUtility.SUCCESS;
            returnInfo.message = ConstantUtility.SUCCESS;
            return JSON.serialize(returnInfo);
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : OTRS_UtilClass at Line :: ' + exp.getLineNumber());
            returnInfo.message = returnInfo.message != null ? returnInfo.message : exp.getMessage();
            returnInfo.type = ConstantUtility.ERROR;
            LoggerUtil.createErrorLog('OTRS_UtilClass', 'updateOTRSTicketOnCase', exp.getTypeName(), returnInfo.message, exp.getStackTraceString(), null);
        }
        return JSON.serialize(returnInfo);
    }
    
    /** ================================== ARTICLE UPDATE METHODS ========================================= */
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used send the article to the OTRS system and return the response
@Date            : 12/07/2021
*/
    @AuraEnabled
    public static String OTRSArticleUpdate(String ticketNumber, String recordId, String body) {
        ReturnInfo returnInfo = new ReturnInfo();
        //ticketNumber = '211000159';
        try {
            Case cseObj = QueryUtil.getCaseObject(recordId);
            List<Safex_API__c> wayApiInfo = QueryUtil.getSafexApiInfo(ConstantUtility.OTRS_ARTICLE_UPDATE_API_NAME);
            
            if (wayApiInfo.size() > 0 && wayApiInfo[0].Endpoint__c != null && wayApiInfo[0].Access_Key__c != null && wayApiInfo[0].Customer_User_Login__c != null) {
                
                String endpoint = wayApiInfo[0].Endpoint__c+'?CustomerUserLogin='+wayApiInfo[0].Customer_User_Login__c+'&access_key='+wayApiInfo[0].Access_Key__c;
                Blob requestBodyBlob = getOTRSArticleUpdateRequestBody(cseObj.Subject, body, ticketNumber);
                String contentLength = String.valueOf(requestBodyBlob.size());
                String contentType = HttpFormBuilder.GetContentType();
                HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.POST, 'Accept', ConstantUtility.APPLICATION_JSON, null, ConstantUtility.APPLICATION_JSON, requestBodyBlob);
                // Setting other params
                httpRequest.setHeader('Content-Length', contentLength);
                httpRequest.setHeader('Content-Type', contentType);
                //httpRequest.setHeader('access_key', wayApiInfo[0].Access_Key__c);
                //httpRequest.setHeader('AgentUserLogin', wayApiInfo[0].Agent_User_Login__c);
                // Sending the API Request
                HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, ConstantUtility.OTRS_ARTICLE_UPDATE_API_NAME);
                System.debug('httpResponse getBody ' + httpResponse.getBody());
                if (httpResponse.getStatusCode() == 200) {
                    returnInfo.type = ConstantUtility.SUCCESS;
                    returnInfo.message = httpResponse.getBody();
                    return JSON.serialize(returnInfo);
                }
                returnInfo.message = ConstantUtility.GETTING_ERROR_FROM_API;
                throw new AuraHandledException(returnInfo.type);
            }
            returnInfo.message = ConstantUtility.INCOMPLETE_API_INFO_MESSAGE;
            throw new AuraHandledException(returnInfo.type);
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : OTRS_UtilClass at Line :: ' + exp.getLineNumber());
            returnInfo.message = returnInfo.message != null ? returnInfo.message : exp.getMessage();
            returnInfo.type = ConstantUtility.ERROR;
            LoggerUtil.createErrorLog('OTRS_UtilClass', 'OTRSArticleUpdate', exp.getTypeName(), returnInfo.message, exp.getStackTraceString(), null);
        }
        return JSON.serialize(returnInfo);
    }
    
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is create the request blob body for OTRS Article Update.
@Date            : 12/07/2021
*/
    public static Blob getOTRSArticleUpdateRequestBody(String subject, String body, String ticketNumber) {
        subject = 'Comment from service cloud';
        String form64 = '';
        form64 += HttpFormBuilder.append('data', '{"Article":{"Subject":"' + subject + '","Body":"' + body + '","ContentType":"text/plain; charset=utf8"}}');
        form64 += HttpFormBuilder.append('ticketNo', ticketNumber);
        // Can add more parameters and values
        
        //adding documents body with file parameter if we are sending the files as well
        // blob formBlob= HttpFormBuilder.makeBlobWithFile('file',aa.Body,aa.Name,form64);
        
        Blob formBlob = EncodingUtil.base64Decode(form64);
        return formBlob;
    }
    /** ================================== TICKET DETAILS METHODS ========================================= */
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used send the article to the OTRS system and return the response
@Date            : 12/07/2021
*/
    @AuraEnabled
    public static String OTRSGetTicketDetails(String recordId) {
        System.debug('recordId287--->'+recordId);
        ReturnInfo returnInfo = new ReturnInfo();
        try {
            if (recordId == null) {
                returnInfo.message = ConstantUtility.INVALID_CASE_ID;
                throw new AuraHandledException(returnInfo.message);
            }
            Case cseObj = QueryUtil.getCaseObject(recordId);
            if (cseObj.OTRS_Ticket_No__c == null) {
                returnInfo.message = ConstantUtility.OTRS_TICKET_NOT_FOUND;
                throw new AuraHandledException(returnInfo.message);
            }
            String ticketNumber = cseObj.OTRS_Ticket_No__c; // Assigning the Ticket Number
            List<Safex_API__c> wayApiInfo = QueryUtil.getSafexApiInfo(ConstantUtility.OTRS_TICKET_DETAIL_API_NAME);
            if (wayApiInfo.size() > 0 && wayApiInfo[0].Endpoint__c != null && wayApiInfo[0].Access_Key__c != null) {
                String endpoint = wayApiInfo[0].Endpoint__c + '?access_key=' + wayApiInfo[0].Access_Key__c + '&' + 'ticketNo=' + ticketNumber;
                HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.GET, null, null, null, null, null);
                // Sending the API Request
                HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, ConstantUtility.OTRS_TICKET_DETAIL_API_NAME);
                System.debug('httpResponse getStatusCode' + httpResponse.getStatusCode());
                System.debug('httpResponse getBody' + httpResponse.getBody());
                if (httpResponse.getStatusCode() == 200) {
                    returnInfo.type = ConstantUtility.SUCCESS;
                    returnInfo.message = httpResponse.getBody();
                    return JSON.serialize(returnInfo);
                }
                returnInfo.message = ConstantUtility.GETTING_ERROR_FROM_API;
                throw new AuraHandledException(returnInfo.message);
            }
            returnInfo.message = ConstantUtility.INCOMPLETE_API_INFO_MESSAGE;
            throw new AuraHandledException(returnInfo.message);
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : OTRS_UtilClass at Line :: ' + exp.getLineNumber());
            returnInfo.message = returnInfo.message != null ? returnInfo.message : exp.getMessage();
            returnInfo.type = ConstantUtility.ERROR;
            LoggerUtil.createErrorLog('OTRS_UtilClass', 'OTRSArticleUpdate', exp.getTypeName(), returnInfo.message, exp.getStackTraceString(), null);
        }
        return JSON.serialize(returnInfo);
    }
    @AuraEnabled
    public static String updateOtrsStatus(String otrsStatus, String recordId) {
        ReturnInfo returnInfo = new ReturnInfo();
        try {
            Case cseObj = QueryUtil.getCaseObject(recordId);
            cseObj.OTRS_Request_Status__c = otrsStatus;
            if(cseObj.OTRS_Request_Status__c == ConstantUtility.OTRS_STATUS_CLOSE ){ //cseObj.OTRS_Request_Status__c == 'Close Successful' ||
                if(!String.isBlank(cseObj.Sub_Type__c) && cseObj.Sub_Type__c == 'Short / Part Shipment' || cseObj.Sub_Type__c == 'Pilferred' || cseObj.Sub_Type__c == 'Damage' || cseObj.Sub_Type__c == 'Delivery not done' || cseObj.Sub_Type__c == 'Interchange' || cseObj.Sub_Type__c == 'Wrong Delivery'){
                    system.debug('sub-type'+cseObj.Sub_Type__c);
                }else{
                    system.debug('cseObj.Status'+cseObj.Status);
                    cseObj.Status = ConstantUtility.COMPLETED;
                }
            }
            TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
            update cseObj;
            TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);
            returnInfo.type = ConstantUtility.SUCCESS;
            returnInfo.message = ConstantUtility.SUCCESS;
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : OTRS_UtilClass at Line :: ' + exp.getLineNumber());
            returnInfo.message = returnInfo.message != null ? returnInfo.message : exp.getMessage();
            returnInfo.type = ConstantUtility.ERROR;
            LoggerUtil.createErrorLog('OTRS_UtilClass', 'OTRSArticleUpdate', exp.getTypeName(), returnInfo.message, exp.getStackTraceString(), null);
        }
        return JSON.serialize(returnInfo);
    }
    
    /**  ================================== RETURN RESPONSE WRAPPER TO LWC COMPONENT ========================================= */
    public class ReturnInfo {
        @AuraEnabled public String type = ConstantUtility.ERROR;
        @AuraEnabled public String message;
    }
    
    public static HTTPResponse getDuplicateTicket(String accessKey, String wayBillNo) {
        String OTRS_DuplicateAPI = System.Label.OTRS_Duplicate_Check_API;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(OTRS_DuplicateAPI + accessKey+'&documentNo='+wayBillNo+'&mainCat=WaybillEscalation&subCat=null&issueType=null');
        req.setMethod('GET');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getStatusCode() + ': ' + res.getBody());
        return res;
    }
    
}