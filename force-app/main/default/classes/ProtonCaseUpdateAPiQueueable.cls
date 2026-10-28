/**
@Author          : Himanshi Dang
@Company         : IBM
@Jira ticket     : SAC-652
Created to update IT record when case origin is 'Reverse pickup'
*/
public class ProtonCaseUpdateAPiQueueable implements Queueable, Database.AllowsCallouts{
    public Map<String, String> caseIdMap = new Map<String, String>();
    
    public ProtonCaseUpdateAPiQueueable(Map<String, String> caseIdMap){
        this.caseIdMap = caseIdMap ;  
    }
    public void execute(QueueableContext context) {
        
        String caseId;
        String integrationTransactionId;
        System.debug('this.caseIdMap-->'+this.caseIdMap);
        System.debug('this.caseIdMap-->'+this.caseIdMap.size());
        
        if(this.caseIdMap.size() > 0){ 
            for(String integrationId : this.caseIdMap.keySet()){
                caseId = this.caseIdMap.get(integrationId);
                integrationTransactionId = integrationId;
                break;
            }
        }
        
        String tokenEndpoint = system.label.ProtonApiTokenEndPoint;
        String username = system.label.ProtonCaseUpdateApiUsername;
        String password = system.label.ProtonCaseUpdateApiPassword;
        String protonEndpoint = system.label.ProtonCaseUpdateApiEndPoint;
        String tokenAuth;
        
        if(tokenEndpoint != null && username != null && password != null){
            JSONGenerator genAuth = JSON.createGenerator(true);
            genAuth.writeStartObject();
            genAuth.writeStringField('grant_type', 'client_credentials');
            genAuth.writeStringField('scope', 'authtest/waybillapps');
            genAuth.writeEndObject();
            String jsonAuthString = genAuth.getAsString(); 
            if(Test.isRunningTest()){
                tokenAuth = 'testToken';
            }else{ 
                HttpResponse res = cls_PropelICallout.propelITokenCallout(username, password,'POST',jsonAuthString, tokenEndpoint);                
                if(res.getStatusCode() == 200)
                {
                    JsonParser2 tokenRes = (JsonParser2)JSON.deserialize(res.getBody(), JsonParser2.class);
                    tokenAuth = tokenRes.access_token;
                    
                }
            }
        system.debug('tokenAuth-->'+tokenAuth);
        
            Case caseRec = [Select Id, CaseNumber, PickUp_Date__c, WaybillNo__c FROM Case where Id =: caseId] ;
            ProtonRequestWrapper protonObject = new ProtonRequestWrapper();
            protonObject.sfdcCaseNo = caseRec.CaseNumber;
            protonObject.waybillNumber = caseRec.WaybillNo__c;
            protonObject.updatedBy = 'Salesforce';
            protonObject.pickupDate = String.valueOf(Date.today());
            
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(protonEndpoint);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type','application/json');
            httpReq.setHeader('Authorization',tokenAuth);
            httpReq.setTimeout(120000);
            httpReq.setbody(JSON.serialize(protonObject));
            System.debug('body-->'+JSON.serialize(protonObject)); 
            
            Http htp = new Http();
            HttpResponse response = new HttpResponse();
             
            response = htp.send(httpReq);
            
            System.debug(response.getBody());
            
            if(response.getStatusCode() != 200){
                LoggerUtil.createAPILog('ProtonCaseUpdateAPiQueueable', protonEndpoint, JSON.serialize(protonObject), response.getBody(), response.getStatusCode());
            }else{
                IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
                updateITLogObject.recordId = integrationTransactionId;
                updateITLogObject.request = httpReq.getBody();
                updateITLogObject.response = response.getBody(); 
                IntegrationUtility.updateIntegrationTransaction(updateITLogObject); 
                system.debug('updateITLogObject-->'+updateITLogObject);
            }
            
            if(this.caseIdMap.size() > 0){
                String removeId = this.caseIdMap.remove(integrationTransactionId);
                System.debug('this.caseIdMap-->'+this.caseIdMap);
                if(this.caseIdMap.size() > 0){
                    System.enqueueJob(new ProtonCaseUpdateAPiQueueable(this.caseIdMap));
                } 
            }   
        }
    }
    
    public class JsonParser2 {
        public String access_token;
    } 
    
}