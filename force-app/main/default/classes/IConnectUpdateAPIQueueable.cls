public class IConnectUpdateAPIQueueable implements Queueable, Database.AllowsCallouts {
    public List<String> caseIdList = new List<String>();
    public Map<String, String> caseIdMap = new Map<String, String>();
    
    public IConnectUpdateAPIQueueable(List<String> caseIdList){
        this.caseIdList = caseIdList ;  
    }
    public IConnectUpdateAPIQueueable(Map<String, String> caseIdMap){
        this.caseIdMap = caseIdMap ;  
    }
    public void execute(QueueableContext context) {
        string endpoint = System.label.IConnect_Endpoint;
        string endpoint1 = System.label.IConnect_Endpoint1;
        string empClientId = System.label.IConnect_Client_Id;
        
        try{
            Wrapper records = new Wrapper();
            List<DataWrapper> dataList = new List<DataWrapper>();
            
            // Update y - KSANSI(IBM), removed loop calling and maked as chaining of queueable job
            //String caseId = this.caseIdList[0];
            String caseId;
            String integrationTransactionId;
            System.debug('this.caseIdMap-->'+this.caseIdMap);
            System.debug('this.caseIdMap-->'+this.caseIdMap.size());
            System.debug('this.caseIdList-->'+this.caseIdList);
            System.debug('this.caseIdList-->'+this.caseIdList.size());
            if(this.caseIdMap.size() > 0){ 
                for(String integrationId : this.caseIdMap.keySet()){
                    caseId = this.caseIdMap.get(integrationId);
                    integrationTransactionId = integrationId;
                    break;
                }
            }else if(caseIdList.size() > 0){
                caseId = this.caseIdList[0];
            }
            
            String OriginVersion;
            for(Case caseRec : [Select Id, Origin_Version__c, CaseNumber, PropelI_PreBooking_Id__c, Pre_Booking_Id__c, Booking_Status__c, WaybillNo__c,
                                BookingBranch__r.Branch_Code__c, BookingBranch__c, BookingBranch__r.PropelI_Branch_ID__c, BookingBranch__r.Email__c, BookingBranch__r.Phone__c
                                FROM Case where Id /*In: caseIdList*/=:caseId]){
                System.debug('caseRec-->'+caseRec);  
                OriginVersion = caseRec.Origin_Version__c != null ? caseRec.Origin_Version__c : '';
                DataWrapper wrapData = new DataWrapper();
                wrapData.caseNo = caseRec.CaseNumber;
                wrapData.requestNo = caseRec.Pre_Booking_Id__c;
                wrapData.propelI_Branch_ID = caseRec.BookingBranch__r.PropelI_Branch_ID__c;
                wrapData.branch_Code = caseRec.BookingBranch__r.Branch_Code__c;
                wrapData.email = caseRec.BookingBranch__r.Email__c;
                wrapData.phone = caseRec.BookingBranch__r.Phone__c;
                wrapData.status = getPicklistValue(caseRec.Booking_Status__c);                    
                if(caseRec.Booking_Status__c == '2633'){
                    wrapData.Status = 'CANCELLED';
                }                    
                System.debug('wrapData-->'+wrapData);   
                wrapData.waybill = caseRec.WaybillNo__c;
                dataList.add(wrapData);
            }
            records.pickupRequest = dataList;
            List<Token_Management__c> token = [Select Token_ID__c,expiredAtTime__c From Token_Management__c where Application_Name__c = 'Iconnect' limit 1];
            HttpRequest httpReq;
            Http htp = new Http();
            HttpResponse res;
            if(!token.isEmpty() && OriginVersion != '' && OriginVersion == 'IC-02' && System.now() >= token[0].expiredAtTime__c) {
                
                Map<String,Object> newMap = getStatusCodeForTokenApi();
                List<Object> data =  (List<Object>) newMap.get('data'); 
                Long epochTime = (Long)newMap.get('expiredAt');
                Long epochTimeMillis = epochTime * 1000;
                
                DateTime dt = DateTime.newInstance(epochTimeMillis);
                System.debug('Converted DateTime: ' + dt);
                String accessToken;
                for (Object dataIte : data){
                    Map<String, Object> dataMapIte = (Map<String, Object>) dataIte;
                    accessToken = (String) dataMapIte.get('access_token');
                }
                if(!token.isEmpty()) {
                    token[0].Token_ID__c = accessToken;
                    token[0].expiredAtTime__c = dt;
                }
                httpReq = getHttpRequest(OriginVersion,endpoint1,endpoint,empClientId,records,accessToken);
                res = htp.send(httpReq);
                update token[0];
            }
            else {
                httpReq = getHttpRequest(OriginVersion,endpoint1,endpoint,empClientId,records,token[0].Token_ID__c);
                res = htp.send(httpReq);
            }
            
            system.debug(res.getStatusCode());
            system.debug(res.getBody());
            
            if(integrationTransactionId != null){    
                IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
                updateITLogObject.recordId = integrationTransactionId;
                updateITLogObject.request = httpReq.getBody();
                updateITLogObject.response = res.getBody(); 
                IntegrationUtility.updateIntegrationTransaction(updateITLogObject); 
            }
            if(res.getStatusCode() != 200){
                LoggerUtil.createAPILog('IConnectPostUpdateAPI', endpoint, JSON.serialize(records), res.getBody(), res.getStatusCode());
            }
            // Although propelI will send single case, self calling is done considering future scenario when this job accept multiple cases.
            
            if(this.caseIdList.size() > 0){
                System.debug('this.caseIdList-->'+this.caseIdList);
                List<String> newCaseIdList = this.caseIdList ;
                newCaseIdList.remove(0);
                if(newCaseIdList.size() > 0){
                    System.enqueueJob(new IConnectUpdateAPIQueueable(newCaseIdList));
                }
                
            }else if(this.caseIdMap.size() > 0){
                String removeId = this.caseIdMap.remove(integrationTransactionId);
                System.debug('this.caseIdMap-->'+this.caseIdMap);
                if(this.caseIdMap.size() > 0){
                    System.enqueueJob(new IConnectUpdateAPIQueueable(this.caseIdMap));
                } 
            }
                      
            
        } catch(exception exp){
            system.debug('exp.getMessage()'+exp.getMessage());
            LoggerUtil.createErrorLog('IConnectPostUpdateAPI', 'Update Status IConnect', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    
    public static HttpRequest getHttpRequest(String OriginVersion, String endpoint1, String endpoint, String empClientId, Wrapper records, String accessToken) {
        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type','application/json');
        if (OriginVersion != '' && OriginVersion == 'IC-02') {
            /*Iconnect_API__c iconnectAPICustomSetting = Iconnect_API__c.getValues('Iconnect');
            String accessToken = '';
            accessToken += iconnectAPICustomSetting.Access_Token__c != null ? iconnectAPICustomSetting.Access_Token__c : '';
            accessToken += iconnectAPICustomSetting.Access_Token1__c != null ? iconnectAPICustomSetting.Access_Token1__c : '';*/
            httpReq.setEndpoint(endpoint1);
            httpReq.setHeader('authorize',accessToken);
        }
        else {
            httpReq.setEndpoint(endpoint);
            httpReq.setHeader('CLIENT_EMP_ID', empClientId);
        }
        httpReq.setbody(JSON.serialize(records));
        
        system.debug(httpReq);
        return httpReq;
    }
    
    public static Map<String,Object> getStatusCodeForTokenApi() {
        Iconnect_API__c iconnectAPICustomSetting = Iconnect_API__c.getValues('Iconnect');
        String endpoint = iconnectAPICustomSetting.Endpoint__c;
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endpoint);
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type','application/json');
        httpReq.setHeader('x-api-key', iconnectAPICustomSetting.X_Api_Key__c);
        
        String body = '{"username":"'+iconnectAPICustomSetting.Username__c+'","clientId":"'+iconnectAPICustomSetting.ClientId__c+'","clientSecret":"'+iconnectAPICustomSetting.ClientSecret__c+'"}';
        httpReq.setbody(body);
        
        system.debug(httpReq);
        
        
        Http htp = new Http();
        HttpResponse res = htp.send(httpReq);
        
        system.debug(res.getStatusCode());
        system.debug(res.getBody());
        Map<String,Object> newMap = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
        
        System.debug(newMap.get('data'));
        /*List<Object> data =  (List<Object>) newMap.get('data'); 
        Long epochTime = (Long)newMap.get('expiredAt');
        Long epochTimeMillis = epochTime * 1000;
        
        DateTime dt = DateTime.newInstance(epochTimeMillis);
        System.debug('Converted DateTime: ' + dt);
		Map<String,DateTime> mapOfAccesstokenAndExpiretime = new Map<String,DateTime>();
        String accessToken;
        for (Object dataIte : data){
            Map<String, Object> dataMapIte = (Map<String, Object>) dataIte;
            accessToken = (String) dataMapIte.get('access_token');
        }
        mapOfAccesstokenAndExpiretime.put(accessToken,dt);*/
        return newMap;
    }
    
    public static string getPicklistValue(String value){
        if(value == '2629'){
            return 'BOOKING CREATED';
        }else if(value == '2630'){
            return 'BOOKING ASSIGNED';
        }else if(value == '2638'){
            return 'RE_SCHEDULED';
        }else if(value == '2632'){
            return 'PICKED';
        }else if(value == '2633'){
            return 'CANCEL';
        }
        return null;
    }
    public class Wrapper{
        public List<DataWrapper> pickupRequest;
    }
    public class DataWrapper{
        public string caseNo;
        public string requestNo;
        public string status;
        public string waybill;
        public string phone;
        public string email;
        public Decimal propelI_Branch_ID;
        public string branch_Code;
    }
}