public class RefreshBookingRequest {
    public static Integer MAX_RETRIES = Integer.valueOf(Label.Max_Retries);
    
	@AuraEnabled(cacheable=false)
   	//public List<DataWrapper> dataWrapperList = new List<DataWrapper>();
    public static void fetchITRecord(String caseId){
        Map<String, String> propelIAPIMap = new Map<String, String>();
        List<Integration_Transaction__c> iTrecord = [SELECT Id, Operation_Type__c, Record_Id__c,No_of_Retries__c FROM Integration_Transaction__c
                                                     WHERE Record_Id__c =: caseId AND Operation_Type__c='PropelICaseCreation' ORDER BY CreatedDate DESC LIMIT 1 ];
        system.debug('iTrecordList--->' + iTrecord);
        
        
        if (iTrecord.size() == 0) {
            System.debug('IT record not found for caseId: ' + caseId);
            List<String> casesList = new List<String>();
            casesList.add(caseId);
            system.debug('casesList--->'+casesList);
            IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
            createITLogObject.objectName = 'Case'; 
            createITLogObject.recordIdList = casesList;
            createITLogObject.operationType = System.Label.OperationType_PropelI_CaseCreation; 
            System.debug('createITLogObject-->'+createITLogObject);
            IntegrationUtility.createIntegrationTransaction(createITLogObject);
        }
        else{
            
            Map<String, String> newPropeliAPIMap = new Map<String, String>();
            
            propeliAPIMap.put(iTrecord[0].Id, iTrecord[0].Record_Id__c);
            
            /*PreBookingAPIQueueable newPropelIQueueableObj = new PreBookingAPIQueueable(newPropeliAPIMap);
System.enqueueJob(newPropelIQueueableObj);*/
            
            //Integer retryCount = 0;
            Integer retryCount = iTrecord[0].No_of_Retries__c != null ? iTrecord[0].No_of_Retries__c.intValue() : 0;
            
            if(retryCount < MAX_RETRIES) {
                /* IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
updateITLogObject.recordId = iTrecord[0].id;
IntegrationUtility.updateIntegrationTransaction(updateITLogObject); 
system.debug('updateITLogObject-->'+updateITLogObject);*/
                retryCount++;
                system.debug('retryCount---->'+retryCount);
                iTrecord[0].No_of_Retries__c = retryCount;
                system.debug('iTrecord.No_of_Retries__c---->'+iTrecord[0].No_of_Retries__c);
                update iTrecord;
                
            }
            else{
                throw new AuraHandledException('Maximum retry attempts reached');
            }
        }
        
    }
  
}