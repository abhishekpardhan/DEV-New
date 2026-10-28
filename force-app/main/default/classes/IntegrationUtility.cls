/****************************************************************************************************
Name: IntegrationUtility
=============================================================================================
=============================================================================================
Purpose: Utility class to help in various integrations
=============================================================================================
=============================================================================================
History
---------------------------------------------------------------------------------------------
VERSION AUTHOR DATE DETAIL
1.0 - KR SANSI
*****************************************************************************************************/ 

global class IntegrationUtility {
 
    /**********************************************************************************************************************************************************************************************
    Method: InsertLogwithResponse
    Description: 
    1. Creates a new record of Integration Transaction object with the passed values
    ***********************************************************************************************************************************************************************************************/        
    
    public static void createIntegrationTransaction(CreateIntegrationLog createITObject)
    {
        List<Integration_Transaction__c> reqDetailList = new List<Integration_Transaction__c>();                 
        for(String recordId : createITObject.recordIdList){
            Integration_Transaction__c reqDetail = new Integration_Transaction__c();
            reqDetail.Object_Name__c = createITObject.objectName;
            reqDetail.record_id__c = recordId; 
            reqDetail.Operation_Type__c = createITObject.operationType ;
            reqDetail.No_of_Retries__c = createITObject.noOfretries;
            reqDetail.MSAPushEndpoint__c = createITObject.endPointURL;
            reqDetailList.add(reqDetail);
        }
        System.debug('reqDetailList-->'+reqDetailList);
        if(reqDetailList.size() > 0){
            try{
                insert reqDetailList;
            }catch(Exception e){
                System.debug('error -->'+e.getMessage());
            }
            
        }
    }
     
    public static void updateIntegrationTransaction(IntegrationLog itObject)
    {             
        Integration_Transaction__c reqDetail = new Integration_Transaction__c();
        reqDetail.Id = itObject.recordId;
        if(itObject.statusCode != null){ 
        	reqDetail.Status_Code__c = itObject.statusCode;        
            if(itObject.statusCode == 200){
                reqDetail.Status__c = 'Success';
            }else{
                reqDetail.Status__c = 'Fail';
            }
        }
        
        if(itObject.errorMessage != null){
            reqDetail.Error_Message__c = itObject.errorMessage;
        }
        	 
        if(itObject.response != null){
            reqDetail.Response__c = itObject.response;
        }
        	 
        if(itObject.request != null){
			reqDetail.Request__c = itObject.request;             
        }
        	 
        update reqDetail;        
         
    }
 
    
    public class IntegrationLog{
        public String objectName;
        public String eventName;
        public String response;
        public String request;
        public String recordId;
        public String errorMessage;
        public Integer statusCode; 
    }
     
    public class CreateIntegrationLog{
        public List<String> recordIdList;
        public String operationType;
        public Integer noOfretries = 0;
        public String objectName; 
		public String endPointURL;         
    }

}