/**
* @File Name          : UpdateCaseApi.cls
* @Description        : This class will used to update Cases in salesforce using API.
* @Author             : Shubham Rastogi
* @Group              : Salesforce Team 
* @Last Modified By   : Shubham Rastogi
* @Last Modified On   : 20/09/2021
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        18/07/2023                Shubham Rastogi                   Initial Version
Source attribute identify the calling system. When Request is initiated from PropelI, source will be blank.
**/
@RestResource(urlMapping='/iConnectUpdateSupportCase/*')
global with sharing class iConnectCaseUpdateAPI {
    
    /**
@Author          : Shubham Rastogi
@Company         : Cloud Certitude
@Description     : This method is used to create salesforce support Case in salesforce from external system
@Date            : 13/09/2021
*/
    @HttpPost
    global static void updateCase() {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        RestRequest request = RestContext.request; //RestRequest for the Apex REST method
        String requestBody = request.requestBody != null ? request.requestBody.toString() : '';
        try {
            case newCase;
            if (!String.isBlank(requestBody)) {
                RequestWrapper requestWrapper = (RequestWrapper) System.JSON.deserialize(requestBody, RequestWrapper.class);
               
                if (requestWrapper != null ) {
                    String fieldCheckMessage = checkFields(requestWrapper);
                    if (fieldCheckMessage == null && isNullOrBlankString(requestWrapper.source)) {
                        Case caseObj = updateCase(requestWrapper);
                        if (caseObj != null) {
                            responseWrapper = createResponse(ConstantUtility.SUCCESS.toLowerCase(), 'Data Updated Successfully', null);
                        } else {
                            responseWrapper = createResponse(ConstantUtility.ERROR.toLowerCase(), ConstantUtility.UPDATE_FAILED, ConstantUtility.NO_RECORD_FOUND);
                        }
                    }
                    else if (fieldCheckMessage == null && requestWrapper.source == 'IConnect'){
                        List<Case> cases = [
                            SELECT Booking_Status__c,Booking_Request_Type_Id__c,Customer_Reference_Number__c,Reschedule_Date__c,Reschedule_Reason__c,Cancel_Reason__c,Booking_Last_Updated_Date__c,
                            WaybillNo__c, Origin
                            FROM Case
                            WHERE /*PropelI_PreBooking_Id__c =: requestWrapper.preBookingRequestId AND*/ CaseNumber =:requestWrapper.safexpReferenceNumber LIMIT 1
                        ];
                        if (!cases.isEmpty()) {
                            Case caseRec = new Case();
                            caseRec.Id =  cases[0].Id;
                            caseRec.Origin_Version__c = requestWrapper.originVersion;
                            //caseRec.Cancel_Reason__c = requestWrapper.cancelreason;
                            update caseRec;
                            List<String> casesList = new List<String>();
                            casesList.add(caseRec.Id);
                            IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
                            createITLogObject.objectName = 'Case'; 
                            createITLogObject.recordIdList = casesList;
                            createITLogObject.operationType = System.Label.OperationType_PropelI_CaseCancellation; 
                          
                            IntegrationUtility.createIntegrationTransaction(createITLogObject); 
                            responseWrapper = createResponse(ConstantUtility.SUCCESS.toLowerCase(), 'Request Recieved Successfully', null);
                            
                        }
                    }
                    else {
                        responseWrapper = createResponse(fieldCheckMessage, ConstantUtility.ERROR.toLowerCase(), null);
                    }
                } else {
                    responseWrapper = createResponse(ConstantUtility.ERROR.toLowerCase(), ConstantUtility.UPDATE_FAILED, ConstantUtility.INVALID_REQUEST_BODY);
                }
            } else {
                responseWrapper = createResponse(ConstantUtility.ERROR.toLowerCase(), ConstantUtility.UPDATE_FAILED, ConstantUtility.INVALID_REQUEST_BODY);
            }
        } catch (exception exp) {
            System.debug('Exception Message :: ' + exp.getMessage() + ' AT ' + exp.getStackTraceString());
            responseWrapper = createResponse(ConstantUtility.ERROR.toLowerCase(), ConstantUtility.UPDATE_FAILED, exp.getMessage());
            LoggerUtil.createErrorLog('UpdateCaseApi', 'updateCase', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        LoggerUtil.createAPILog('UpdateCaseApi', 'TO Salesforce', requestBody, JSON.serialize(responseWrapper), null);
        if (!Test.isRunningTest()) {
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
        }
        
    }
    
    /**
	@Author          : Shubham Rastogi
	@Company         : Cloud Certitude
	@Description     : This method is used to create the response in Wrapper format
	@Date            : 17-07-2023
	*/
    public static ResponseWrapper createResponse(String message, String status, String error) {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        responseWrapper.msg = message;
        responseWrapper.status = status;
        responseWrapper.error = error;
        return responseWrapper;
    }
    global class ResponseWrapper {
        global String msg;
        global String status;
        global String error;
        
    }
    
    public static Case updateCase(RequestWrapper requestWrapper) {   
        // Updated By - K SANSI, SCI-163
        // replaced where clouse condition from Safexperience_Reference_Number__c to PropelI_PreBooking_Id__c
        List<Case> cases = [
            SELECT Booking_Status__c,Booking_Request_Type_Id__c,Customer_Reference_Number__c,Reschedule_Date__c,Reschedule_Reason__c,Cancel_Reason__c,Booking_Last_Updated_Date__c,
            WaybillNo__c, Origin
            FROM Case
            WHERE /*PropelI_PreBooking_Id__c =: requestWrapper.preBookingRequestId AND*/ CaseNumber =:requestWrapper.safexpReferenceNumber LIMIT 1
        ];         
        if (!cases.isEmpty()) {
            
            Case caseRec = new Case();
            caseRec.Id =  cases[0].Id;
            caseRec.Origin =  cases[0].Origin;
            caseRec.Booking_Status__c = !isNullOrBlankString(requestWrapper.bookingStatus) ? getPicklistValue(String.valueOf(requestWrapper.bookingStatus)) : cases[0].Booking_Status__c;
            caseRec.Customer_Reference_Number__c = !isNullOrBlankString(requestWrapper.safexpReferenceNumber) ? requestWrapper.safexpReferenceNumber : cases[0].Customer_Reference_Number__c;
            caseRec.WaybillNo__c = !isNullOrBlankString(requestWrapper.waybillNo) ? requestWrapper.waybillNo : cases[0].WaybillNo__c;
            caseRec.Reschedule_Reason__c = !isNullOrBlankString(requestWrapper.reschereason) ? requestWrapper.reschereason : cases[0].Reschedule_Reason__c;
            caseRec.Cancel_Reason__c = !isNullOrBlankString(requestWrapper.cancelreason) ? requestWrapper.cancelreason : cases[0].Cancel_Reason__c;
            
            if(!isNullOrBlankString(requestWrapper.preBookingRequestId)){
                caseRec.PropelI_PreBooking_Id__c = requestWrapper.preBookingRequestId;
            }
            //updated by Deepika || IBM || SAC-667
            if(!isNullOrBlankString(requestWrapper.waybillPickupDate)){
            	caseRec.WaybillPickupDate__c = getDate(requestWrapper.waybillPickupDate);
            }
            if(!isNullOrBlankString(requestWrapper.lastupdatedate)){
                caseRec.Booking_Last_Updated_Date__c = getDate(requestWrapper.lastupdatedate);
            }
            if(!isNullOrBlankString(requestWrapper.rescheduledate)){
                caseRec.Reschedule_Date__c = getDate(requestWrapper.rescheduledate);
            }
            
            caseRec.Status = 'In Progress';
            
            if(requestWrapper.bookingStatus == 'PICKED'){
                caseRec.Status = 'Completed';
            }
            if(caseRec.Booking_Status__c == getPicklistValue('CANCEL')){
                caseRec.Status = 'Cancelled';
            }
            /*if(caseRec.Booking_Status__c == getPicklistValue('BOOKING ASSIGNED')){
                caseRec.Booking_Branch__c = requestWrapper.bookingBranch;
            }*/
            
            if(!isNullOrBlankString(requestWrapper.bookingBranch)){
                caseRec.Booking_Branch__c = requestWrapper.bookingBranch;
            } 
            
            if(!isNullOrBlankString(caseRec.WaybillNo__c)){
                caseRec.Status = 'Completed';
            }
            TriggerHandler.bypass('CaseTrigger');
          
            update caseRec;
            TriggerHandler.clearBypass('CaseTrigger');
            
            List<String> casesList = new List<String>();
            casesList.add(caseRec.Id);
            
            if(caseRec.Origin == 'iConnect' && !casesList.isEmpty() && isNullOrBlankString(requestWrapper.source)){
                IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
                createITLogObject.objectName = 'Case'; 
                createITLogObject.recordIdList = casesList;
                createITLogObject.operationType = System.Label.OperationType_iConnect_UpdateCase; 
              
                IntegrationUtility.createIntegrationTransaction(createITLogObject); 
                //System.enqueueJob(new IConnectUpdateAPIQueueable(casesList));
            }
            
                         
            // update case to proton
            //updated by Himanshi: IBM for @Jira ticket: SAC-652   
       
          if(caseRec.Origin == 'Reverse Pickup' && !casesList.isEmpty()){
                IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
                createITLogObject.objectName = 'Case'; 
                createITLogObject.recordIdList = casesList;
                createITLogObject.operationType = System.Label.OperationType_Proton_UpdateCase; 
                IntegrationUtility.createIntegrationTransaction(createITLogObject); 
            }
            
            return caseRec;
        }
        return null;
    }
    
    /**
	Wrapper Class to request parsing
	*/
    public class RequestWrapper {
        public String caseType;
        public String preBookingRequestId;    //123
        public String bookingStatus;    //10
        public String safexpReferenceNumber;    //123
        public String waybillNo;    //5656565656
        public String rescheduledate;    //23/12/2021
        public String reschereason;    //Test reson
        public String cancelreason;    //cancel reason
        public String lastupdatedate;    //23/12/2021
        public String bookingBranch;
        public String waybillPickupDate;  //updated by Deepika || IBM || SAC-667
        public String source;
        public String originVersion;

    }
    
    public  static  Date getDate(String dateString){
        Integer dd = Integer.valueOf(String.valueOf(dateString).split('/')[0]);
        Integer month = Integer.valueOf(String.valueOf(dateString).split('/')[1]);
        Integer yyyy = Integer.valueOf(String.valueOf(dateString).split('/')[2]);
        return Date.newInstance(yyyy,month,dd);
    }
    public static String checkFields(RequestWrapper requestWrapper) {
        // Universal check for all type cases
        if ((isNullOrBlankString(requestWrapper.safexpReferenceNumber) || isNullOrBlankString(requestWrapper.preBookingRequestId)) && requestWrapper.source!= 'iConnect') {
            return ConstantUtility.REQUIRED_FIELD_MISSING;
        }
        if (isNullOrBlankString(requestWrapper.safexpReferenceNumber) && requestWrapper.source== 'iConnect') {
            return ConstantUtility.REQUIRED_FIELD_MISSING;
        }    
        if(isNullOrBlankString(requestWrapper.cancelreason) && requestWrapper.bookingStatus == 'CANCEL'){
            return ConstantUtility.REQUIRED_FIELD_MISSING;
        }
        if((isNullOrBlankString(requestWrapper.rescheduledate) || isNullOrBlankString(requestWrapper.reschereason)) && requestWrapper.bookingStatus == 'RE_SCHEDULED'){
            return ConstantUtility.REQUIRED_FIELD_MISSING;
        }
        if(isNullOrBlankString(requestWrapper.bookingBranch) && requestWrapper.bookingStatus == 'BOOKING ASSIGNED'){
            return ConstantUtility.REQUIRED_FIELD_MISSING;
        }
        
        return null;
    }
    public static string getPicklistValue(String value){
        if(value == 'BOOKING CREATED'){
            return '2629';
        }else if(value == 'BOOKING ASSIGNED'){
            return '2630';
        }else if(value == 'RE_SCHEDULED'){
            return '2638';
        }else if(value == 'PICKED'){
            return '2632';
        }else if(value == 'CANCEL'){
            return '2633';
        }
        return null;
    }
    
    public static Boolean isNullOrBlankString(String input) {
        return String.isBlank(input)
            || 'null'.equalsIgnoreCase(input.trim());
    }
}