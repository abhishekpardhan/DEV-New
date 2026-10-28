/**
* @File Name          : GetWayBillStatusAPI.cls
* @Description        : GetWayBillStatusAPI class take waybill no. as input and return back complete status of Waybill No.
* @Author             : Deepak
* @Group              : Techmatrix
* @Last Modified By   : Deepak
* @Last Modified On   : 07-07-2021
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        07-07-2021                Deepak                   Initial Version
**/

public class GetWayBillStatusAPI {
    
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used to get information form the wayBill system
@Date            : 07/07/2021
@Modified        : 28/03/2024, KR SANSI, SAC-511, method overload for update the Waybill number afetr verifying from propelI System
*/
    @AuraEnabled
    public static String getWayBillInfo(String waybillNo) {
        return getWayBillInfo(waybillNo, '', false);
    }
    
    @AuraEnabled
    public static String getWayBillInfo(String waybillNo, String recordId, Boolean isUpdate) {
        System.debug('waybillNo-->'+waybillNo);
        System.debug('recordId-->'+recordId);
        System.debug('isUpdate-->'+isUpdate);
        try {
            List<Safex_API__c> wayApiInfo = QueryUtil.getSafexApiInfo(ConstantUtility.WAY_BILL_API_NAME);
            system.debug('testing->'+wayApiInfo);
            system.debug('testing->'+ QueryUtil.getSafexApiInfo(ConstantUtility.WAY_BILL_API_NAME));
            if (wayApiInfo.size() > 0 && wayApiInfo[0].Endpoint__c != null && wayApiInfo[0].Username__c != null && wayApiInfo[0].Password__c != null) {
                String endpoint = wayApiInfo[0].Endpoint__c + waybillNo;
                Blob headerValue = Blob.valueOf(wayApiInfo[0].Username__c + ':' + wayApiInfo[0].Password__c);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.GET, 'Authorization', authorizationHeader, null, ConstantUtility.APPLICATION_JSON, null);
                // Sending the API Request
                HttpResponse httpResponse = HttpUtility.makeCallout(httpRequest, ConstantUtility.WAY_BILL_API_NAME);
                System.debug('httpResponse getStatusCode' + httpResponse.getStatusCode());
                System.debug('httpResponse getBody' + httpResponse.getBody());
                // Added by RC
                
                System.debug('===responseWrapper.body.message=='+httpResponse.getBody());
                System.debug('===responseWrapper.body.message=='+httpResponse.getBody().contains('Not Found'));
                if (httpResponse.getStatusCode() == 200) {
                    
                    if(isUpdate == true && !httpResponse.getBody().contains('Not Found')){
                        
                        List<UserRecordAccess> uraList = [SELECT RecordId FROM UserRecordAccess
                                                          WHERE UserId =: UserInfo.getUserId()
                                                          AND RecordId =: recordId  
                                                          AND HasEditAccess = true];
                        if(uraList.size() == 0){
                            System.debug('not access');
                            WayBillResponseWrapper response = new WayBillResponseWrapper();
                            response.message = 'Not updated : You do not have permission to update Waybill number';
                            return JSON.serialize(response);                             
                        }                        
                        System.debug('===update case--');
                        String updateResponse = updateWayBillNummber(waybillNo, recordId);
                        if(updateResponse != 'success'){
                            WayBillResponseWrapper response1 = new WayBillResponseWrapper();
                            response1.message = updateResponse;
                            return JSON.serialize(response1);   
                        }
                    }     
                    WayBillResponseWrapper responseWrapper = (WayBillResponseWrapper) System.JSON.deserialize(httpResponse.getBody(), WayBillResponseWrapper.class);
                    return JSON.serialize(responseWrapper);      
                }
                throw new AuraHandledException(ConstantUtility.GETTING_ERROR_FROM_API);
            }
            throw new AuraHandledException(ConstantUtility.INCOMPLETE_API_INFO_MESSAGE);
        } catch (Exception exp) {
            System.debug(' Exception Message ::' + exp.getMessage() + ' Class Name : GetWaybillStatusAPI at Line ::' + exp.getLineNumber());
            LoggerUtil.createErrorLog('GetWaybillStatusAPI', 'getWayBillInfo', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
            throw new AuraHandledException(exp.getMessage());
        }
    }
    
    /**
@Author          : KR SANSI
@Company         : IBM
@Description     : This method is used toupdate wayBill number
@Date            : 28/03/2024	 
*/
    
    
    public static String updateWayBillNummber(String waybillNo, String recordId){
        System.debug('waybillNo-->'+waybillNo);
        System.debug('recordId-->'+recordId);
        Case cas = new Case(Id = recordId, WaybillNo__c =  waybillNo);
        try {
            update cas;
            return 'success';
        } catch (Exception exp) {
            System.debug(' Exception Message ::' + exp.getMessage() + ' Class Name : GetWaybillStatusAPI at Line ::' + exp.getLineNumber());
            //LoggerUtil.createErrorLog('GetWaybillStatusAPI', 'updateWayBillNummber', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
            //throw new AuraHandledException(exp.getMessage());
            return exp.getMessage();
        }    
    }
    
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used to get List of Cases form the wayBill number
@Date            : 13/09/2021
*/
    @AuraEnabled
    public static String getCases(String waybillNo, Integer recordLimit) {
        try {
            List<Case> cases = new List<Case>();
            if(waybillNo !=null) {
                cases = [SELECT CaseNumber,Status,Subject,Case_Type__c,Case_Nature__c FROM Case WHERE WaybillNo__c = :waybillNo ORDER BY CaseNumber DESC LIMIT :recordLimit];
                if (cases.size() > 0) {
                    return JSON.serialize(cases);
                }
            }
            return null;
        } catch (Exception exp) {
            System.debug(' Exception Message ::' + exp.getMessage() + ' Class Name : GetWaybillStatusAPI at Line ::' + exp.getLineNumber());
            LoggerUtil.createErrorLog('GetWaybillStatusAPI', 'getCases', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
            throw new AuraHandledException(exp.getMessage());
        }
    }
    
    
}