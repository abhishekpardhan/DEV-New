public class PreBookingAPIQueueable implements Queueable, Database.AllowsCallouts {
    //public List<String> caseIdList ;
    public Map<String, String> caseIdMap = new Map<String, String>();
    
    /*public PreBookingAPIQueueable(List<String> caseIdList){
        this.caseIdList = caseIdList ;  
    }*/
    public PreBookingAPIQueueable(Map<String, String> caseIdMap){
        this.caseIdMap = caseIdMap ;  
    }
    public void execute(QueueableContext context) {
        
        String tokenEndpoint = system.label.PropeliTokenEndpoint;
        String username = system.label.Propeli_Username;
        String password = system.label.Propeli_Password;
        String apiKey = system.label.PropelIPreBookingAPIKey;
        String preBookingEndpoint = system.label.PropelIPreBookingEndpoint;
        String tokenAuth;
        String caseId;
        String integrationTransactionId;
        for(String integrationId : this.caseIdMap.keySet()){
            caseId = this.caseIdMap.get(integrationId);
            integrationTransactionId = integrationId;
            break;
        } 
        try{
            
            if(tokenEndpoint != null && username != null && password != null){
                JSONGenerator genAuth = JSON.createGenerator(true);
                genAuth.writeStartObject();
                genAuth.writeStringField('grant_type', 'client_credentials');
                genAuth.writeStringField('scope', 'propeli-test/booking');
                genAuth.writeStringField('x-apikey', apiKey);
                genAuth.writeEndObject();
                String jsonAuthString = genAuth.getAsString(); 
                //System.debug('jsonAuthString------------------------>'+jsonAuthString);
                
                HttpResponse res = cls_PropelICallout.propelITokenCallout(username, password,'POST',jsonAuthString, tokenEndpoint);
                //system.debug('res body ==>'+res.getBody());
                system.debug(res.getStatusCode());
                if(res.getStatusCode() == 200)
                {
                    //System.debug('htpTokenRes.getBody()--------------->'+res.getBody());
                    jsonParser2 tokenRes = (jsonParser2)JSON.deserialize(res.getBody(), jsonParser2.class);
                    //System.debug('tokenRes.access_token----------->'+tokenRes.access_token);
                    tokenAuth = tokenRes.access_token;
                    //system.debug('tokenAuth----->'+tokenAuth);
                }
            }
            system.debug(tokenAuth);
            if(Test.isRunningTest()){
                tokenAuth = 'testTokenValue';
            }
            List<Case> caseToUpdate = new List<Case>();
            List<Case> caseToUpdateNotFailure = new List<Case>();
            
            // Update y - KSANSI(IBM), removed loop calling and maked as chaining of queueable job
            //String caseId = this.caseIdList[0];
            
            Case caseRec = [Select Id, Status, CaseNumber, Business_Type__c,Transport_Mode__c, PropelI_PreBooking_Id__c, Consignee_Address_Line_1__c, Consignee_Pincode__c, Consignee_Email__c, 
                                Consignee_Phone__c, Consignee_Name__c, Consignor_Address_Line_1__c, Consignor_Pincode__c, Consignor_Email__c, Consignor_Dealer_Code__c,
                                Consignor_Phone__c, Consignor_Name__c, PickUp_Date__c, PickUp_To_Time__c, Pickup_Type__c, MSA_Code__c, Ewaybills__c, 
                                Safexperience_Reference_Number__c, Safexperience_Remarks__c, SFX_PRC_Code__c, Total_Package_Count__c, 
                                Total_Weight__c, Pre_Booking_Id__c, Consignee_GSTIN_Number__c, Consignee_Dealer_Code__c, Consignor_GSTIN_Number__c, Pre_Booking_Count__c,
                                Mode_Of_Payment__c, requesterType__c, consigneeType__c, fileURL__c, Origin,
                                Consignor_Address_Line_2__c, Consignor_Address_Line_3__c,
                                Consignee_Address_Line_2__c, Consignee_Address_Line_3__c, 
                            	Pickup_Initiator_Email__c, Pickup_Initiator_Phone__c, Provisional_Waybill_No__c,Customer_Reference_Number__c
                                from Case where Id /*In: caseIdList*/=:caseId];
            
                
                                    
            //consignee details
            Address consigneeAddress = new Address();
            consigneeAddress.addr1 = caseRec.Consignee_Address_Line_1__c; 
            consigneeAddress.addr2 = caseRec.Consignee_Address_Line_2__c;
            consigneeAddress.addr3 = caseRec.Consignee_Address_Line_3__c;
            
            consigneeAddress.pinCode = caseRec.Consignee_Pincode__c;
            
            ConsigneeDetails consignee = new ConsigneeDetails();
            consignee.addrBook = consigneeAddress;
            consignee.email = caseRec.Consignee_Email__c;
            consignee.mob = caseRec.Consignee_Phone__c;
            consignee.name = caseRec.Consignee_Name__c;
            consignee.gstinNum = caseRec.Consignee_GSTIN_Number__c;
            consignee.dealerCode = caseRec.Consignee_Dealer_Code__c;
            consignee.isBothCneeCnorFlag = caseRec.consigneeType__c;
            
            //consignor details
            Address consignorAddress = new Address();
            consignorAddress.addr1 = caseRec.Consignor_Address_Line_1__c; 
            consignorAddress.addr2 = caseRec.Consignor_Address_Line_2__c;
            consignorAddress.addr3 = caseRec.Consignor_Address_Line_3__c;
            consignorAddress.pinCode = caseRec.Consignor_Pincode__c;
            
            ConsignorDetails consignor = new ConsignorDetails();
            consignor.addrBook = consignorAddress;
            consignor.email = caseRec.Consignor_Email__c;
            consignor.mob = caseRec.Consignor_Phone__c;
            consignor.name = caseRec.Consignor_Name__c;
            consignor.gstinNum = caseRec.Consignor_GSTIN_Number__c;
            consignor.dealerCode = caseRec.Consignor_Dealer_Code__c;
            consignor.isBothCneeCnorFlag = caseRec.requesterType__c;
            
            RequestBody requestBody = new requestBody();
            requestBody.bookingChannel = caseRec.Origin;
            requestBody.businessType = caseRec.Business_Type__c != null ? caseRec.Business_Type__c.toUpperCase() : null;
            requestBody.consignee = consignee;
            requestBody.consignor = consignor;
            requestBody.customerType = caseRec.Business_Type__c != null ? caseRec.Business_Type__c.toUpperCase() : null;
            
            String timevalue = caseRec.PickUp_To_Time__c;
            system.debug(timevalue);
            requestBody.pickupTime = timevalue != null? timevalue.split('\\.')[0] : '';
            
            requestBody.pickupDate = String.valueOf(caseRec.PickUp_Date__c);
            requestBody.pickupType = caseRec.Pickup_Type__c;
            requestBody.safexperienceReferenceNumber = caseRec.Safexperience_Reference_Number__c;
            requestBody.safexperienceRemarks = caseRec.Safexperience_Remarks__c;
            requestBody.serviceOffering = caseRec.Transport_Mode__c;
            requestBody.sfxPrcCode = caseRec.SFX_PRC_Code__c;
            requestBody.totalPackageCount = Integer.valueOf(caseRec.Total_Package_Count__c);
            requestBody.totalWeight = Integer.valueOf(caseRec.Total_Weight__c);
            requestBody.iConnectReqId = caseRec.Pre_Booking_Id__c;
            requestBody.msaCode = caseRec.MSA_Code__c;
            requestBody.ewaybills = caseRec.Ewaybills__c;
            requestBody.branchCode = '';
            requestBody.modeofPaymentType = caseRec.Mode_Of_Payment__c;
            requestBody.fileURL = caseRec.fileURL__c;
            requestBody.provisionalWaybillNumber = caseRec.Provisional_Waybill_No__c;
            requestBody.customerReferenceNumber = caseRec.Customer_Reference_Number__c;
            
            requestBody.pickupInitiatorEmail = caseRec.Pickup_Initiator_Email__c;
            requestBody.pickupInitiatorPhone = caseRec.Pickup_Initiator_Phone__c;
            
            
            system.debug('Sending to PropelI =>'+JSON.serialize(requestBody));
            
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(preBookingEndpoint);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type','application/json');
            httpReq.setHeader('userId', username);
            httpReq.setHeader('x-api-key', apiKey);
            httpReq.setHeader('Authorization', tokenAuth);
            httpReq.setHeader('scope', 'propeli-test/booking');
            httpReq.setTimeout(120000);
            httpReq.setbody(JSON.serialize(requestBody));
            
            system.debug(httpReq);
            
            
            Http htp = new Http();
            HttpResponse res = htp.send(httpReq);
            
            system.debug(res.getStatusCode());
            system.debug(res.getBody());
            
            // Updated K SANSI - SCI-164, chnaged the condition
            /*if(res.getStatusCode() != 200 && res.getStatusCode() != 201 && res.getStatusCode() != 202 && res.getStatusCode() != 204){
LoggerUtil.createAPILog('PreBooking API', preBookingEndpoint, JSON.serialize(requestBody), res.getBody(), res.getStatusCode());
}else{
ResponseWrapper wrapper = (ResponseWrapper)JSON.deserialize(res.getBody(), ResponseWrapper.Class);

Case caseObj = new case();
caseObj.Id = caseRec.Id;
caseObj.PropelI_PreBooking_Id__c = String.valueOf(wrapper.data.responseData);
caseObj.Status = 'In Progress';
caseObj.Booking_Status__c = '2629';
caseToUpdate.add(caseObj);
}*/
            
            
            
            if(res.getStatusCode() == 200){
                
                ResponseWrapper wrapper = (ResponseWrapper)JSON.deserialize(res.getBody(), ResponseWrapper.Class);
                System.debug('wrapper.data.preBookingId-->'+wrapper);
                Case caseObj = new case();
                caseObj.Id = caseRec.Id;
                caseObj.Origin = caseRec.Origin;
                caseObj.PropelI_PreBooking_Id__c = String.valueOf(wrapper.data.preBookingId);
                
                if(String.isNotBlank(String.valueOf(wrapper.data.bookingStatus))){
                    caseObj.Booking_Status__c = getPicklistValue(String.valueOf(wrapper.data.bookingStatus));                                            
                }else{
                    //Booking created
                    //caseObj.Booking_Status__c = '2629';
                }
                if(String.isNotBlank(String.valueOf(wrapper.data.bookingBranch))){
                    caseObj.Booking_Branch__c = String.valueOf(wrapper.data.bookingBranch);   
                    String branchNameTrimmed = caseObj.Booking_Branch__c.trim();
                    List<Branch_Master__c> branches = [ SELECT Id FROM Branch_Master__c
                                                        WHERE Name = :branchNameTrimmed AND is_PropelI_Branch__c = True
                                                        LIMIT 1
                                                    ];
                    if (!branches.isEmpty()) {
                       caseObj.BookingBranch__c = branches[0].Id;
                    }                                         
                }                
                
                caseObj.Status = 'In Progress';
                //caseObj.Booking_Status__c = '2629';
                caseToUpdate.add(caseObj); 
                caseToUpdateNotFailure.add(caseObj);
                System.debug('caseObj-->'+caseObj);
                
            }else{
                // Update the failure count 
                Case caseObj = new case();
                caseObj.Id = caseRec.Id;
                caseObj.Pre_Booking_Count__c = caseRec.Pre_Booking_Count__c != null ? (caseRec.Pre_Booking_Count__c + 1) : 1;                                        
                caseToUpdate.add(caseObj); 
                LoggerUtil.createAPILog('PreBooking API', preBookingEndpoint, JSON.serialize(requestBody), res.getBody(), res.getStatusCode());                                        
            }
             
            if(!caseToUpdate.isEmpty()){
                TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
                try{
                    update caseToUpdate;
                    IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
                    updateITLogObject.recordId = integrationTransactionId;
                    updateITLogObject.request = httpReq.getBody();
                    updateITLogObject.response = res.getBody();
                    updateITLogObject.statusCode = res.getStatusCode();
                    IntegrationUtility.updateIntegrationTransaction(updateITLogObject);            
                }catch(Exception e){
                    // update Integration log record
                    IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
                    updateITLogObject.recordId = integrationTransactionId;
                    updateITLogObject.request = httpReq.getBody();
                    updateITLogObject.response = res.getBody();
                    updateITLogObject.errorMessage = e.getMessage();
                    updateITLogObject.statusCode = res.getStatusCode();
                    IntegrationUtility.updateIntegrationTransaction(updateITLogObject);  
            		            
                }
                
                TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);
                 
            }
            List<String> cases = new List<String>();
            List<Id> enterpriseCases = new List<Id>();
            // Updated By - K SANSI - SCI-164, we need to send back to iConnect cases only
            // added check for only iConnect origin 
            //for(Case caseRec : caseToUpdate){
            System.debug('caseToUpdateNotFailure-->'+caseToUpdateNotFailure);
            for(Case caseRecord : caseToUpdateNotFailure){
                System.debug('caseRec.Origin-->'+caseRecord.Origin);
                if(caseRecord.Origin == 'IConnect' && String.isNotBlank(caseRecord.Booking_Branch__c)){
                    cases.add(caseRecord.Id);
                } else if(caseRecord.Origin.toLowerCase() == 'enterprise app'){
                    enterpriseCases.add(caseRecord.Id);
                }                
            }
            System.debug('cases-->'+cases);
            if(!cases.isEmpty()){  
                callIConnectUpdateAPI(JSON.serialize(cases));
                //System.enqueueJob(new IConnectUpdateAPIQueueable(cases));
            }
            if(!enterpriseCases.isEmpty()){
                callEnterpriseAppUpdateAPI(enterpriseCases);
            }
            
            List<Integration_Transaction__c> listReqDetail = [SELECT Id, Record_Id__c, No_of_Retries__c, Status_Code__c, Status__c, isProcessing__c FROM Integration_Transaction__c WHERE Id =: integrationTransactionId];
            if(!listReqDetail.isEmpty()) {
                listReqDetail[0].isProcessing__c = false;
                //listReqDetail[0].No_of_Retries__c = listReqDetail[0].No_of_Retries__c + 1;
                update listReqDetail;
            }
            
            String removeId = this.caseIdMap.remove(integrationTransactionId);
            if(this.caseIdMap.size() > 0){
                
                System.enqueueJob(new PreBookingAPIQueueable(this.caseIdMap));
            }    
            /*List<String> newCaseIdList = this.caseIdList;
            newCaseIdList.remove(0);
            
            if(newCaseIdList.size() > 0){
                System.enqueueJob(new PreBookingAPIQueueable(newCaseIdList));
            }*/
            
        } catch (exception exp) {
            List<Integration_Transaction__c> listReqDetail = [SELECT Id, Record_Id__c, No_of_Retries__c, Status_Code__c, Status__c, isProcessing__c FROM Integration_Transaction__c WHERE Id =: integrationTransactionId];
            if(!listReqDetail.isEmpty()) {
                listReqDetail[0].isProcessing__c = false;
                //listReqDetail[0].No_of_Retries__c = listReqDetail[0].No_of_Retries__c + 1;
                update listReqDetail;
            }
            system.debug('exp.getMessage()'+exp.getMessage());
            LoggerUtil.createErrorLog('PropelIPreBookingAPI', 'Update PropelI PreBooking API', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    
    @Future(callout=true)
    public static void callIConnectUpdateAPI(String cases) {
        List<Object> casesObj = (List<Object>)JSON.deserializeUntyped(cases);
        List<String> caseList = new List<String>();
        for (Object cases1 : casesObj) {
            caseList.add((String) cases1);
        }
        System.enqueueJob(new IConnectUpdateAPIQueueable(caseList));
    }

    @Future(callout=true)
    public static void callEnterpriseAppUpdateAPI(List<Id> casesList) {
        IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
        createITLogObject.objectName = 'Case'; 
        createITLogObject.recordIdList = casesList;
        createITLogObject.operationType = System.Label.OperationType_Enterprise_UpdateCase; 
        IntegrationUtility.createIntegrationTransaction(createITLogObject);
    }
    
    Public class jsonParser2 {
        public String access_token;
        public String token_type;
        public String expires_in;
    } 
    
    
    public class ResponseWrapper{
        public string message;
        public string status;
        public JSONError errors;
        public Record data;
    }
    
    public class  Record{
        public integer preBookingId;
        public String bookingStatus;
        public String bookingBranch;
    }
    Public class JSONError{
        public List<ErrorWrapper> error;
    }
    
    public class ErrorWrapper{
        public String code;
        public string description;
    }
    
    Public class RequestBody{
        public string bookingChannel;//default
        public string businessType;
        public ConsigneeDetails consignee;
        public ConsignorDetails consignor;
        public String customerReferenceNumber;//No
        public String customerType;
        public String documentType;//default
        public String modeofPaymentType;//default
        public Integer msaCustId;//No
        public String msaCode;
        public String pickupTime;
        public String pickupDate;
        public String pickupType;
        public Integer productCategoryId;//No
        public String safexperienceReferenceNumber;
        public String safexperienceRemarks;//No
        public String serviceOffering;//default
        public String sfxPrcCode;
        public String source;//No
        public Integer sourceBookingId;//No
        public Integer totalPackageCount;
        public Integer totalWeight;
        public String waybillNo;
        public String provisionalWaybillNumber;
        public String weightSlabType;//No
        public String branchCode;//No
        public String rateCard;//No
        public String commercialId;//No
        public String iConnectReqId;
        public String ewaybills;
        public String fileURL;
        
        public String pickupInitiatorEmail;
        public String pickupInitiatorPhone;
        
    }
    
    public class ConsigneeDetails{
        public Address addrBook;
        public Integer consigneeId;//No
        public Integer crtByBranchId;//No
        public String dealerCode;//No
        public String descr;//No
        public String email;
        public String gstinNum;//No
        public Integer id;//No
        public Integer lkpConsigntypeId;//No
        public String mob;
        public Integer msaCustId;//No
        public String name;
        public String panNum;//No
        public String phone;
        public Integer status;//No
        public String tanNum;//No
        public String isBothCneeCnorFlag;
        
    }
    
    public class ConsignorDetails{
        public Address addrBook;
        public Integer consignorId;//No
        public Integer crtByBranchId;//No
        public String dealerCode;//
        public String descr;//No
        public String email;
        public String gstinNum;//No
        public Integer id;//No
        public Integer lkpConsigntypeId;//No
        public String mob;
        public Integer msaCustId;//No
        public String name;
        public String panNum;//No
        public String phone;
        public Integer status;//No
        public String tanNum;//No
        public String isBothCneeCnorFlag;
    }
    public class Address{
        public String addr1;
        public String addr2;//No
        public String addr3;//No
        public string description;//No
        public String id;//No
        public String pincode; 
        
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
}