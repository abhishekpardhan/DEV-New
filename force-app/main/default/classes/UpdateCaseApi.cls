/**
 * @File Name          : UpdateCaseApi.cls
 * @Description        : This class will used to update Cases in salesforce using API.
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 20/09/2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        20/09/2021                Deepak                   Initial Version
**/
@RestResource(urlMapping='/UpdateSupportCase/*')
global with sharing class UpdateCaseApi {

    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
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
                System.debug(requestWrapper);
                if (requestWrapper != null && requestWrapper.preBookingRequestId != null) {
                    Case caseObj = updateCase(requestWrapper);
                    if (caseObj != null) {
                        responseWrapper = createResponse(ConstantUtility.SUCCESS.toLowerCase(), 'Data Updated Successfully', null);
                    } else {
                        responseWrapper = createResponse(ConstantUtility.ERROR.toLowerCase(), ConstantUtility.UPDATE_FAILED, ConstantUtility.NO_RECORD_FOUND);
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
       @Author          : Deepak
       @Company         : TechMatrix Consulting
       @Description     : This method is used to create the response in Wrapper format
       @Date            : 13-09-2021
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
        List<Case> cases = [
                SELECT Booking_Status__c,Booking_Request_Type_Id__c,Customer_Reference_Number__c,Reschedule_Date__c,Reschedule_Reason__c,Cancel_Reason__c,Booking_Last_Updated_Date__c,
                        WaybillNo__c
                FROM Case
                WHERE Pre_Booking_Id__c = :String.valueOf(requestWrapper.preBookingRequestId)
                LIMIT 1
        ];
        if (cases.size() > 0) {
            cases[0].Booking_Status__c = requestWrapper.bookingStatus != null ? String.valueOf(requestWrapper.bookingStatus) : cases[0].Booking_Status__c;
            cases[0].Booking_Request_Type_Id__c = requestWrapper.lkpBookingRequestTypeId != null ? String.valueOf(requestWrapper.lkpBookingRequestTypeId) : cases[0].Booking_Request_Type_Id__c;
            cases[0].Customer_Reference_Number__c = requestWrapper.safexpReferenceNumber != null ? requestWrapper.safexpReferenceNumber : cases[0].Customer_Reference_Number__c;
            cases[0].WaybillNo__c = requestWrapper.waybillNo != null ? String.valueOf(requestWrapper.waybillNo) : cases[0].WaybillNo__c;
            cases[0].Reschedule_Reason__c = requestWrapper.reschereason != null ? String.valueOf(requestWrapper.reschereason) : cases[0].Reschedule_Reason__c;
            cases[0].Cancel_Reason__c = requestWrapper.cancelreason != null ? String.valueOf(requestWrapper.cancelreason) : cases[0].Cancel_Reason__c;
            if(requestWrapper.lastupdatedate !=null ){
                cases[0].Booking_Last_Updated_Date__c = getDate(requestWrapper.lastupdatedate);
            }
            if(requestWrapper.rescheduledate !=null){
                cases[0].Reschedule_Date__c = getDate(requestWrapper.rescheduledate);
            }
            if(cases[0].Booking_Status__c == ConstantUtility.BOOKING_CANCEL){
                cases[0].Status = ConstantUtility.CANCELLED;
            }
            if(cases[0].Booking_Status__c == ConstantUtility.BOOKING_ASSIGNED){
                cases[0].Booking_Branch__c = requestWrapper.bookingBranch;
            }
            if(cases[0].WaybillNo__c != null){
                cases[0].Status = ConstantUtility.COMPLETED;
            }
            update cases;
            return cases[0];
        }
        return null;
    }

    /**
    Wrapper Class to request parsing
    */
    public class RequestWrapper {
        public Integer preBookingRequestId;    //123
        public Integer lkpBookingRequestTypeId;    //321
        public Integer bookingStatus;    //10
        public String safexpReferenceNumber;    //123
        public String waybillNo;    //5656565656
        public String rescheduledate;    //23/12/2021
        public String reschereason;    //Test reson
        public String cancelreason;    //cancel reason
        public String lastupdatedate;    //23/12/2021
        public String bookingBranch;

    }

    public  static  Date getDate(String dateString){
        Integer dd = Integer.valueOf(String.valueOf(dateString).split('/')[0]);
        Integer month = Integer.valueOf(String.valueOf(dateString).split('/')[1]);
        Integer yyyy = Integer.valueOf(String.valueOf(dateString).split('/')[2]);
        return Date.newInstance(yyyy,month,dd);
    }
}