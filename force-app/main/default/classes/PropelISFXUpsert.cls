/*********************************************************************************************
**Author: Safexpress.com
**Description: this is API is exposed to Propel-I system to upsert the SFX, Offering, Service Line, Rate Card, Branches and Billing Information. 
**JIRA Ticket: https://safexpress.atlassian.net/browse/SAC-513
**Test Class:  
**History: 
**Modified Date:   29-03-2024               
**Description: 
**Modified By: Raghav
*************************************************************************************************** */

@RestResource(urlMapping='/SFX_RATECreate/*')
global with sharing class PropelISFXUpsert extends ExceptionHandling.wrap_ErrorsHandling {
    
    global String message;	//Request Successfully completed
    global cls_data data;
    global String status;
    
    global class cls_data {
        public jsonWrapSFX[] responseData;
        public cls_referenceData referenceData;
    }
    global class cls_referenceData {
    }
    
    //Wrapper class to send the response in JSON format
    global class JsonUpsertResult {
        List<Database.Error> Errors;  
        String SFXId;
        Boolean isCreated;
        Boolean isSuccess;
    }
    
    //Wrapper class to parse the JSON
    global class jsonWrapSFX {
        public String Propel_MSACode;
        public string Msa_name;
        public String Propel_Key;
        public String Account_Id;
        public String SFXCode;
        public Integer id;
        public Date Contract_Sign_date;
        public Date Contract_Start_date;
        public Date Contract_Expiry_date;
        public String Direct_Pickup;
        public String Delivery_Hold;
        public String Status;
        public String Business_Type;
        public String Service_line;
        public String Opportunity;
        public String CompSfxOffer;
        public String GstNumber; 
        public String CustomerRating; 
        public List<jsonWrapOffering> Offerings;
        public List<jsonWrapBilling> Billing_Info;
    }
    
    // Set the response body.
    global class APIResponse extends cls_APIResponse
    {
        List<Database.Error> Errors;
        global  String BillingInformationId; 
        global String  MSA;
        global String SFX;
        global  Date SF_CreatedDate; 
        global  Date SF_LastModifiedDate;        
    }
    
    // Wrapper class for service offering. 
    global class jsonWrapOffering {
        public String Service_Offering;
        public list<jsonWrapRATE> Rate_card;
    }
    // Wrapper class for rate card. 
    global class jsonWrapRATE {
        public string rate_card_name;
        public Integer id;
        public Date Sign_date;
        public Date Start_date;
        public Date End_date;
        public Integer Base_location;
        public string Status; 
        public String SFXCode;
        public String CustomerRating;    
        public list<jsonWrapBranch> assign_branch; 
    }
    // Wrapper class for assigned bracnhes. 
    global class jsonWrapBranch {
        
        public Integer MDM_branch_id;
        public Integer assign_branch_id;
        public Integer Billing_Branch; 
        public Integer Billing_State_id;
        public Integer Submission_branch;
        public Integer Collection_branch;
        public String BILLING_STREET;
        public String BILLING_CITY;
        public String BILLING_COUNTRY;
        public String BILLING_ZIP_POSTAL_CODE;
        public String BILLING_STATE;
        public Integer Minimum_Billing;
        public String E_Bill_id;
        public String Comm_bill_email;
        public String GST;
        public String TAN;
        // public String PAN;
        public String Multiple_Emails;
        public String GB_Category;
        public Integer Monthly_Potential;
        public String Credit_Risk; 
        public Date Effective_date;
        public Date expiry_date;
        public String Booking_hold;
        public String Booking_Hold_Reason;
        public String delivery_hold;
        public String delivery_hold_reason;         
    }
    
    // Wrapper class for billing level.
    global class jsonWrapBilling {
        public String Billing_Level;
        public String Billing_type;
        public String SFX_no;
        public String Rate_card_no;
        public String MSA;
        public Date Start_date;
        public String alias_name;
        public Date End_date;
        public Integer Billing_config_id;
        Public String Status;    
        public List<wrapBillinglineItems> billing_by;
    }
    
    // Wrapper class for billing line items. 
    global class wrapBillinglineItems{
        
        public String Billing_by_id;// Unique field, used to upsert the record. 
        public Integer Assign_billing_branch_id;
        public String State_id;
        public Integer Billing_Branch;
        public Integer Submission_branch;
        public Integer Collection_branch;
        public String Billing_address;
        public Integer Minimum_Billing;
        public String Comm_bill_email;
        public Integer Monthly_Potential;
        public Integer Credit_Risk;  
        Public String Status;
        public String Gb_Ctgy;
        public Date last_bill_dt;
        public String Freight_MIS;
        public String Freight_Type;
        public String e_Bill; 
        public String POD_Sharing;
    }    
    //Post request to create SFX customer within SFDC
    @HttpPost
    global static void createCustomer() 
    {
        try
        {
            // API Request.
            RestRequest req=RestContext.request;
            //RestResponse res=RestContext.response;
            string rr= req.requestBody.ToString();
            //// System.debug('Request Body rr:' +rr);
            // List of exceptions. 
            List<APIResponse> lst_APIResponses = new List<APIResponse>();   
            // Get the record type Id of SFX.  
            String SFXRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
            // Get the record type Id of rate card. 
            String RateRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
            // Get the record type Id of service offering. 
            String OfferingRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
            // Get the record type Id of assign branch. 
            String AssignBranchRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
            List<Account> branchlist = new list<Account>();
            //set of SFX to delete the branch records. 
            Set<String> setSFXAccount = new Set<String>();
            List<Billing_Information__c> billinginfolist = new list<Billing_Information__c>();
            // List of response. 
            List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
            PropelISFXUpsert.jsonWrapSFX sfxJSON = (PropelISFXUpsert.jsonWrapSFX) System.JSON.deserialize(rr,PropelISFXUpsert.jsonWrapSFX.class); 
            
            // System.debug('sfxJSON-->'+sfxJSON);
            cls_referenceData clsReferenceObj = new cls_referenceData();
            cls_data clsDataObj = new cls_data();
            clsDataObj.referenceData = clsReferenceObj;
            clsDataObj.responseData = new List<jsonWrapSFX>{sfxJSON};
                
            PropelISFXUpsert requestObj = new PropelISFXUpsert();
            requestObj.message = 'Request Message';
            requestObj.status = 'SUCCESS';
            requestObj.data = clsDataObj;
            
            rr= JSON.serialize(requestObj);
            
            List<JsonUpsertResult> responseList = updateCustomer(rr);
            
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseList));
            
            RestContext.response.statusCode = 200;
            
        } catch(Exception e) {
            String name = 'SFX';
            String ClassName = 'SFX_RATE_UpsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);
        }
    }
    // Wrapper to bind the service accounts. 
    global class wrap_ServicesAccount
    {
        String Service_Offering; 
        String SFXCode;
        String MSA;
        wrap_ServicesAccount(String Service_Offering, String MSA, String SFXCode){
            this.Service_Offering = Service_Offering; 
            this.SFXCode = SFXCode;
            this.MSA = MSA;
        } 
    }
    // Wrapper class to bind the rate cards. 
    global class wrap_RateCard
    {
        String rate_card_name;
        String Service_Offering; 
        Integer id;
        Date Sign_date;
        Date Start_date;
        Date End_date;
        Integer Base_location;
        String Status; 
        String SFXCode; 
        wrap_RateCard(String rate_card_name, String Service_Offering, Integer id, Date Sign_date, Date Start_date, Date End_date, Integer Base_location, String Status, String SFXCode)
        {
            this.rate_card_name = rate_card_name;
            this.Service_Offering = Service_Offering;
            this.id =id;
            this.Sign_date =  Sign_date;
            this.Start_date = Start_date;
            this.End_date = End_date;
            this.Base_location = Base_location;
            this.Status = Status;
            this.SFXCode =SFXCode;
        }
    }
    // warpper to bind the rate card branches. 
    global class wrap_Branches{
        
        Integer assign_branch_id;
        String MSA;
        String SFXCode;
        String Rate_Card; 
        String Service_Offering;
        Integer id;
        Integer MDM_branch_id;
        Date Effective_date;
        String Booking_hold;
        String delivery_hold;
        Date expiry_date;
        String Booking_Hold_Reason;
        String delivery_hold_reason;
        
        wrap_Branches(Integer id, Integer assign_branch_id, String MSA, String SFXCode, String Rate_Card, String Service_Offering, Integer MDM_branch_id, Date Effective_date, String Booking_hold, String delivery_hold,  Date expiry_date, String Booking_Hold_Reason, String delivery_hold_reason)
        {
            this.id = id;
            this.assign_branch_id = assign_branch_id;
            this.MSA = MSA;
            this.SFXCode = SFXCode;
            this.Rate_Card = Rate_Card;
            this.Service_Offering =Service_Offering;
            this.MDM_branch_id = MDM_branch_id; 
            this.Effective_date = Effective_date;
            this.Booking_hold = Booking_hold;
            this.delivery_hold = delivery_hold;
            this.expiry_date = expiry_date ;
            this.Booking_Hold_Reason = Booking_Hold_Reason;
            this.delivery_hold_reason = delivery_hold_reason;
        }
    }
    
    // Billing line item wrapper to upsert the records. 
    global class warp_BillinglineItems
    {
        String MSA;
        String SFX;
        String Billing_level;
        String RateCard;
        String Billing_by_id;// Unique field, used to upsert the record. 
        Integer Assign_billing_branch_id;
        String State_id;
        Integer Billing_Branch;
        Integer Submission_branch;
        Integer Collection_branch;
        String Billing_address;
        Integer Minimum_Billing;
        String Comm_bill_email;
        Integer Monthly_Potential;
        Integer Credit_Risk;
        String Status;
        String Gb_Ctgy;
        Date last_bill_dt;
        String Freight_MIS;
        String Freight_Type;
        String e_Bill;
        String POD_Sharing;
        
        warp_BillinglineItems(String RateCard, String MSA, String SFX, String Billing_level, String Billing_by_id, Integer Assign_billing_branch_id, 
                              Integer Billing_Branch, Integer Submission_branch,Integer Collection_branch, String Billing_address, Integer Minimum_Billing, String Comm_bill_email, Integer Monthly_Potential, Integer Credit_Risk, String Gb_Ctgy, Date last_bill_dt,
                              String Freight_MIS,String Freight_Type,String e_Bill, String POD_Sharing) {
                                  
                              	this.RateCard  = RateCard;
                                this.MSA = MSA;
                                this.SFX = SFX;
                                this.Billing_level = Billing_level;
                                this.Billing_by_id = Billing_by_id;
                                this.Assign_billing_branch_id = Assign_billing_branch_id;
                                this.State_id = State_id;
                                this.Billing_Branch = Billing_Branch;
                                this.Submission_branch = Submission_branch;
                                this.Collection_branch = Collection_branch;
                                this.Billing_address = Billing_address;
                                this.Minimum_Billing = Minimum_Billing;
                                this.Comm_bill_email = Comm_bill_email;
                                this.Monthly_Potential = Monthly_Potential;
                                this.Credit_Risk = Credit_Risk;
                                this.Gb_Ctgy = Gb_Ctgy;
                                this.last_bill_dt = last_bill_dt;
                                this.Freight_MIS = Freight_MIS;
                                this.Freight_Type = Freight_Type;
                                this.e_Bill = e_Bill;
                                this.POD_Sharing = POD_Sharing;
            
        						}
        
        warp_BillinglineItems(jsonWrapBilling eachBillingInfo, wrapBillinglineItems eachBillingLineItem){
            
            this.RateCard  = eachBillingInfo.Rate_card_no;
            this.MSA = eachBillingInfo.MSA;
            this.SFX = eachBillingInfo.SFX_no;
            this.Billing_level = eachBillingInfo.Billing_Level;
            this.Billing_by_id = eachBillingLineItem.Billing_by_id;
            this.Assign_billing_branch_id = eachBillingLineItem.Assign_billing_branch_id;
            this.State_id = eachBillingLineItem.State_id;
            this.Billing_Branch = eachBillingLineItem.Billing_Branch;
            this.Submission_branch = eachBillingLineItem.Submission_branch;
            this.Collection_branch = eachBillingLineItem.Collection_branch;
            this.Billing_address = eachBillingLineItem.Billing_address;
            this.Minimum_Billing = eachBillingLineItem.Minimum_Billing;
            this.Comm_bill_email = eachBillingLineItem.Comm_bill_email;
            this.Monthly_Potential = eachBillingLineItem.Monthly_Potential;
            this.Credit_Risk = eachBillingLineItem.Credit_Risk;
            this.Status = eachBillingLineItem.Status;
            this.Gb_Ctgy = eachBillingLineItem.Gb_Ctgy;
            this.last_bill_dt = eachBillingLineItem.last_bill_dt;
            this.Freight_MIS = eachBillingLineItem.Freight_MIS;
            this.Freight_Type = eachBillingLineItem.Freight_Type;
            this.e_Bill = eachBillingLineItem.e_Bill;
            this.POD_Sharing = eachBillingLineItem.POD_Sharing;
        }
    }
    
    
    global static List<JsonUpsertResult> updateCustomer(String rr) 
    {
        List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
        List<APIResponse> lst_APIResponses = new List<APIResponse>(); 
        if(String.isNotEmpty(rr) && String.isNotBlank(rr))
        {
            try
            {
                // Get the record type Id of SFX.  
                String SFXRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
                // System.debug('SFXRecordTypeID--->'+SFXRecordTypeID);
                // Get the record type Id of rate card. 
                String RateRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
                // System.debug('RateRecordTypeID--->'+RateRecordTypeID);
                // Get the record type Id of service offering. 
                String OfferingRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
                // System.debug('OfferingRecordTypeID--->'+OfferingRecordTypeID);
                // Get the record type Id of assign branch. 
                String AssignBranchRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
                // System.debug('AssignBranchRecordTypeID---->'+AssignBranchRecordTypeID);
                List<Account> branchlist = new list<Account>();
                //set of SFX to delete the branch records. 
                Set<String> setSFXAccount = new Set<String>();
                List<Billing_Information__c> billinginfolist = new list<Billing_Information__c>();
                // List of response. 
                
                PropelISFXUpsert sfxPropelIJSON = (PropelISFXUpsert) System.JSON.deserialize(rr,PropelISFXUpsert.class); 
                // System.debug('sfxPropelIJSON------>'+sfxPropelIJSON);
                if(sfxPropelIJSON != null && sfxPropelIJSON.data.responseData != null && sfxPropelIJSON.data.responseData.size() > 0 && sfxPropelIJSON.status == 'SUCCESS')
                { 
                    Set<String> setMSACodes = new Set<String>();
                    for(jsonWrapSFX sfxJSON :  sfxPropelIJSON.data.responseData )
                    {
                        setMSACodes.add(sfxJSON.Propel_MSACode);
                    }
                     System.debug('setMSACodes----->'+setMSACodes);
                    if( ! setMSACodes.isEmpty())
                    {
                        List<Account> lstMSAAccounts = [SELECT id, name, Propel_MSACode__c from Account where Propel_MSACode__c IN : setMSACodes];
                         System.debug('lstMSAAccounts----->'+lstMSAAccounts);
                        Map<String, Account> mapMSAIds = new Map<String, Account>();
                        List<Account> msaToUpdate = new List<Account>();
                        if(! lstMSAAccounts.isEmpty())
                        {
                            for(Account eachAccId: lstMSAAccounts)
                                mapMSAIds.put(eachAccId.Propel_MSACode__c, eachAccId);
                        }
                        // System.debug('mapMSAIds---->'+mapMSAIds); 
                        if(! mapMSAIds.isEmpty())
                        {
                            jsonWrapSFX sfxJSON = sfxPropelIJSON.data.responseData[0];
                            String sfxNo;                                 
                            // Insert/ Update the SFX records.                    
                            Account sfxAccount = new Account(Name =  sfxJSON.Msa_name +'  ('+sfxJSON.SFXCode + ')',
                                                             SFX_Code__c = sfxJSON.SFXCode,
                                                             Propeli_Id__c = sfxJSON.id,
                                                             Propel_key__c= sfxJSON.Propel_Key,
                                                             ParentId = mapMSAIds.get(sfxJSON.Propel_MSACode).Id,
                                                             RecordTypeID = SFXRecordTypeID,
                                                             Contract_Sign_Date__c = sfxJSON.Contract_Sign_Date,
                                                             Contract_Effective_Date__c = sfxJSON.Contract_Start_date,
                                                             Contract_Expiry_date__c = sfxJSON.Contract_Expiry_date, 
                                                             Direct_Pickup__c = sfxJSON.Direct_Pickup,
                                                             Delivery_Hold__c = sfxJSON.Delivery_Hold, 
                                                             Status__c = sfxJSON.Status,
                                                             Business_Type__c = sfxJSON.Business_Type,
                                                             Service_line__c = sfxJSON.Service_line,
                                                             GST__c = sfxJSON.GstNumber,   
                                                             Customer_Category__c = sfxJSON.CustomerRating,
                                                             opportunity__c = sfxJSON.Opportunity
                                                             
                                                            );
                            sfxNo = sfxJSON.SFXCode;
                            if(mapMSAIds.containsKey(sfxJSON.Propel_MSACode) && mapMSAIds.get(sfxJSON.Propel_MSACode).Name != sfxJSON.Msa_name){
                                mapMSAIds.get(sfxJSON.Propel_MSACode).Name = sfxJSON.Msa_name;
                                msaToUpdate.add(mapMSAIds.get(sfxJSON.Propel_MSACode));
                            }
                            setSFXAccount.add(sfxJSON.SFXCode);                                 
                            // System.debug('setSFXAccount----->'+setSFXAccount);
                            // System.debug('sfxJSON:  ' +sfxJSON);
                            // System.debug('sfxAccount-->'+sfxAccount);
                            Database.UpsertResult resultsacc = Database.upsert(sfxAccount, Account.SFX_Code__c,false);
                            List<ExceptionHandling.wrap_ErrorsHandling> lstExceptions = new List<ExceptionHandling.wrap_ErrorsHandling>();
                            Boolean isSFXUpserted = TRUE; 
                            JsonUpsertResult sfxErrors = new JsonUpsertResult();
                            sfxErrors.Errors = resultsacc.getErrors();
                            sfxErrors.isCreated = resultsacc.isCreated();
                            sfxErrors.isSuccess = resultsacc.isSuccess();
                            sfxErrors.SFXId = sfxJSON.SFXCode;
                            lstJsonUpsertResult.add(sfxErrors);
                            String str_ErrorMessage; 
                            For(Database.Error eachError : resultsacc.getErrors())
                            {
                                str_ErrorMessage = eachError.getMessage() + ':' + eachError.getStatusCode();
                            }
                            
                            if(!resultsacc.isSuccess())
                            {
                                lstExceptions.add(new ExceptionHandling.wrap_ErrorsHandling(sfxJSON.Propel_MSACode,sfxJSON.SFXCode, str_ErrorMessage, '901','temp_PropelISFXUpsert', 'Account:SFX' ));
                                
                            }
                            // System.debug('lstExceptions------------------->'+lstExceptions);
                            //delete the previous branch records.                                 
                            // If the SFX record is successfully insert/ updated.
                            Map<String, wrap_ServicesAccount> map_ServiceAccount = new Map<String, wrap_ServicesAccount>();
                            Map<String, wrap_RateCard> map_RateCards = new Map<String, wrap_RateCard>();
                            Map<String, wrap_Branches> map_Branches = new Map<String, wrap_Branches>();
                            // Set to capture all base locations and MDM branch Id; 
                            Set<Integer> setBranchMasterCode = new Set<Integer>();
                            // System.debug('resultsacc.isSuccess()----------------->'+resultsacc.isSuccess());
                            // System.debug('isSFXUpserted----------------------->'+isSFXUpserted);
                            if(resultsacc.isSuccess())
                            {
                                // Iterate SFX services
                                for(jsonWrapOffering eachService : sfxJSON.Offerings)
                                {
                                    map_ServiceAccount.put(eachService.Service_Offering + '-' + sfxJSON.SFXCode, new wrap_ServicesAccount(eachService.Service_Offering, sfxJSON.Propel_MSACode, sfxJSON.SFXCode));
                                    // Iterate rate cards.
                                    for(jsonWrapRate eachRateCard : eachService.Rate_card)
                                    {
                                        setBranchMasterCode.add(eachRateCard.Base_location);
                                        map_RateCards.put(sfxJSON.SFXCode+':'+eachService.Service_Offering+':'+eachRateCard.Id, new wrap_RateCard(eachRateCard.rate_card_name, eachService.Service_Offering, eachRateCard.id, eachRateCard.Sign_date, eachRateCard.Start_date, eachRateCard.End_date, eachRateCard.Base_location, eachRateCard.Status, sfxJSON.SFXCode));
                                        //iterate the branches. 
                                        for(jsonWrapBranch eachAssignedBranch : eachRateCard.assign_branch)
                                        {
                                            setBranchMasterCode.add(eachAssignedBranch.MDM_branch_id);
                                            map_Branches.put(sfxJSON.SFXCode+':'+eachService.Service_Offering+':'+eachRateCard.Id+':'+eachAssignedBranch.assign_branch_id, 
                                                             new wrap_Branches(eachRateCard.Id, eachAssignedBranch.assign_branch_id, sfxJSON.Propel_MSACode, sfxJSON.SFXCode, eachRateCard.rate_card_name, eachService.Service_Offering, eachAssignedBranch.MDM_branch_id, eachAssignedBranch.Effective_date, eachAssignedBranch.Booking_hold, eachAssignedBranch.delivery_hold,  eachAssignedBranch.expiry_date, eachAssignedBranch.Booking_Hold_Reason, eachAssignedBranch.delivery_hold_reason));
                                        }
                                    }
                                }
                                // System.debug('map_ServiceAccount---------------->'+map_ServiceAccount);
                                // System.debug('map_RateCards------------------>'+map_RateCards);
                                // System.debug('map_Branches------------->'+map_Branches);
                                // System.debug('setBranchMasterCode--------------->'+setBranchMasterCode);
                                if(! map_ServiceAccount.isEmpty())
                                {
                                    List<Account> lst_ServiceAccountToUpsrt = new List<Account>();
                                    for(wrap_ServicesAccount eachServiceAcc : map_ServiceAccount.values())
                                    {
                                        Account servcAcc = new Account();
                                        servcAcc.Name = eachServiceAcc.Service_Offering;
                                        servcAcc.Service_Offering__c = eachServiceAcc.Service_Offering;
                                        servcAcc.ParentId =  sfxAccount.Id;
                                        servcAcc.Comp__c = eachServiceAcc.Service_Offering + '-' + eachServiceAcc.SFXCode;
                                        servcAcc.RecordTypeID = OfferingRecordTypeID;
                                        lst_ServiceAccountToUpsrt.add(servcAcc);
                                    }
                                    // System.debug('lst_ServiceAccountToUpsrt-------------------->'+lst_ServiceAccountToUpsrt);
                                    Database.UpsertResult[] arr_resultServiceAccount = Database.upsert(lst_ServiceAccountToUpsrt, Account.Comp__c,false);
                                    Set<Id> setUpdatedServiceAcc = new Set<Id>();
                                    for(Integer index = 0, size = arr_resultServiceAccount.size();  index < size ; index++)
                                    {
                                        if(arr_resultServiceAccount[index].isSuccess())
                                            setUpdatedServiceAcc.add(arr_resultServiceAccount[index].getId());
                                        for(Database.Error eachErr: arr_resultServiceAccount[index].getErrors())
                                        {
                                            str_ErrorMessage = eachErr.getMessage() + ':' + eachErr.getStatusCode();
                                            lstExceptions.add(new ExceptionHandling.wrap_ErrorsHandling(sfxJSON.Propel_MSACode,sfxJSON.SFXCode, str_ErrorMessage, '901','temp_PropelISFXUpsert', 'Account:SFX' ));        
                                        }
                                    }
                                    // System.debug('setUpdatedServiceAcc-------------------->'+setUpdatedServiceAcc);
                                    if(! setUpdatedServiceAcc.isEmpty()) 
                                    {
                                        List<Account> lstAccServices = [Select id, Comp__c from Account where Id IN: setUpdatedServiceAcc];
                                        // System.debug('lstAccServices------------>'+lstAccServices);
                                        Map<String, Id> mapServiceAccountId = new Map<String, Id>();
                                        if(! lstAccServices.isEmpty())
                                        {
                                            for(Account eachAccount : lstAccServices)
                                            {
                                                mapServiceAccountId.put(eachAccount.Comp__c, eachAccount.id);
                                            }
                                        }
                                        // System.debug('mapServiceAccountId--------------->'+mapServiceAccountId);
                                        if(! map_RateCards.isEmpty())
                                        {
                                            // Pull out the branch id from Branch Master table.
                                            List<Branch_Master__c> lst_BranchMasters = [Select id, PropelI_Branch_ID__c from Branch_Master__c where PropelI_Branch_ID__c IN : setBranchMasterCode  limit 9999];
                                            // System.debug('lst_BranchMasters------------>'+lst_BranchMasters); 
                                            Map<Decimal, Id> map_BranchMasterIds = new Map<Decimal, Id>();
                                            if(! lst_BranchMasters.isEmpty())
                                            {
                                                for(Branch_Master__c eachBranchMaster : lst_BranchMasters)
                                                {
                                                    map_BranchMasterIds.put(eachBranchMaster.PropelI_Branch_ID__c, eachBranchMaster.Id);
                                                }
                                            }
                                            // System.debug('map_BranchMasterIds-------------->'+map_BranchMasterIds);
                                            List<Account> lst_RateCardAccountToUpsrt = new List<Account>();
                                            
                                            Map<String,Id> mapSFXCodebaseLoc = new Map<String,Id>();  //SAC -1182
                                            for(wrap_RateCard eachRateCard : map_RateCards.values())
                                            {
                                                Account newRateCard = new Account();  
                                                newRateCard.Name = eachRateCard.rate_card_name;
                                                newRateCard.rate_card_id__c = eachRateCard.id;
                                                newRateCard.Rate_card_start_date__c = eachRateCard.Start_date;
                                                newRateCard.Rate_card_end_date__c = eachRateCard.End_date;
                                                newRateCard.Status__c = eachRateCard.Status;
                                                newRateCard.RecordTypeID  = RateRecordTypeID;
                                                // Start SAC -1182 - By Priyanka Goel
                                                if(map_BranchMasterIds != null && map_BranchMasterIds.containsKey(Decimal.valueOf(eachRateCard.Base_location))) {
                                                    newRateCard.Base_Location__c = map_BranchMasterIds.get(Decimal.valueOf(eachRateCard.Base_location));  
                                                    mapSFXCodebaseLoc.put(eachRateCard.SFXCode,map_BranchMasterIds.get(Decimal.valueOf(eachRateCard.Base_location)));  
                                                }
                                                // End SAC -1182 - By Priyanka Goel	
                                                
                                                if(! mapServiceAccountId.isEmpty() && mapServiceAccountId.keySet().size() > 0 && mapServiceAccountId.keySet().contains(eachRateCard.Service_Offering + '-' + eachRateCard.SFXCode))
                                                    newRateCard.ParentId = mapServiceAccountId.get(eachRateCard.Service_Offering + '-' + eachRateCard.SFXCode);
                                                newRateCard.Composite_Key__c = eachRateCard.id + '-' + eachRateCard.Service_Offering + '-' + eachRateCard.SFXCode;
                                                lst_RateCardAccountToUpsrt.add(newRateCard);
                                            }
                                            // System.debug('lst_RateCardAccountToUpsrt--------------->'+lst_RateCardAccountToUpsrt);
                                            // Start SAC -1182 - By Priyanka Goel
                                            if (mapSFXCodebaseLoc.keySet().contains(sfxAccount.SFX_Code__c)) {
                                                sfxAccount.Base_Location__c = mapSFXCodebaseLoc.get(sfxAccount.SFX_Code__c);
                                                update sfxAccount;
                                            }
                                            // End SAC -1182 - By Priyanka Goel
                                            Database.UpsertResult[] arr_resultRateCardAccounts = Database.upsert(lst_RateCardAccountToUpsrt, Account.Composite_Key__c,false);
                                            Set<Id> setUpdatedRateCardAcc = new Set<Id>();
                                            for(Integer index = 0, size = arr_resultRateCardAccounts.size();  index < size ; index++)
                                            {
                                                if(arr_resultRateCardAccounts[index].isSuccess())
                                                    setUpdatedRateCardAcc.add(arr_resultRateCardAccounts[index].getId());
                                                
                                                for(Database.Error eachErr: arr_resultRateCardAccounts[index].getErrors())
                                                {
                                                    str_ErrorMessage = eachErr.getMessage() + ':' + eachErr.getStatusCode();
                                                    lstExceptions.add(new ExceptionHandling.wrap_ErrorsHandling(sfxJSON.Propel_MSACode,sfxJSON.SFXCode, str_ErrorMessage, '901','temp_PropelISFXUpsert', 'Account:SFX' ));
                                                }
                                            }
                                            // System.debug('setUpdatedRateCardAcc---------------->'+setUpdatedRateCardAcc);
                                            List<Account> lstAccRateCards = [Select id, Composite_Key__c from Account where Id IN: setUpdatedRateCardAcc];
                                            // System.debug('lstAccRateCards------------>'+lstAccRateCards);
                                            Map<String, Id> mapRateCardAccountId = new Map<String, Id>();
                                            if(! lstAccRateCards.isEmpty())
                                            {
                                                for(Account eachRateCardAccount : lstAccRateCards)
                                                {
                                                    mapRateCardAccountId.put(eachRateCardAccount.Composite_Key__c, eachRateCardAccount.id);
                                                }
                                            }
                                            // System.debug('mapRateCardAccountId--------------->'+mapRateCardAccountId);
                                            // upsert the branches record. 
                                            if(! map_Branches.isEmpty())
                                            {
                                                List<Account> lst_BranchAccountToUpsert = new List<Account>();
                                                for(wrap_Branches eachBranch : map_Branches.values())
                                                {
                                                    Account newBranchAcc = new Account();
                                                    newBranchAcc.Name = 'ASSIGN BRANCH:'+ eachBranch.Rate_card + '-'+eachBranch.SFXCode;
                                                    newBranchAcc.AssignBranch_ID__c = String.valueOf(eachBranch.assign_branch_id);
                                                    newBranchAcc.Effective_Date__c = eachBranch.Effective_date;
                                                    newBranchAcc.Booking_hold__c= eachBranch.Booking_hold;
                                                    newBranchAcc.Booking_Hold_Reason__c = eachBranch.Booking_Hold_Reason;
                                                    newBranchAcc.Delivery_Hold__c= eachBranch.delivery_hold;
                                                    newBranchAcc.Delivery_Hold_Reason__c= eachBranch.delivery_hold_reason;
                                                    newBranchAcc.Expiry_Date__c = eachBranch.expiry_date;
                                                    newBranchAcc.RecordTypeID = AssignBranchRecordTypeID;
                                                    if(map_BranchMasterIds != null && map_BranchMasterIds.containsKey(Decimal.valueOf(eachBranch.MDM_branch_id)))
                                                        newBranchAcc.Billing_Branch__c = map_BranchMasterIds.get(Decimal.valueOf(eachBranch.MDM_branch_id));
                                                    if(! mapRateCardAccountId.isEmpty() && mapRateCardAccountId.keySet().size() > 0 && mapRateCardAccountId.keySet().contains(eachBranch.id + '-' + eachBranch.Service_Offering + '-' + eachBranch.SFXCode))
                                                        newBranchAcc.ParentId = mapRateCardAccountId.get(eachBranch.id + '-' + eachBranch.Service_Offering + '-' + eachBranch.SFXCode);
                                                    
                                                    newBranchAcc.CompBranch__c = String.valueOf(eachBranch.assign_branch_id) + '-' + eachBranch.id + '-' + eachBranch.Service_Offering + '-' + eachBranch.SFXCode;  
                                                    lst_BranchAccountToUpsert.add(newBranchAcc);
                                                    
                                                }
                                                // System.debug('lst_BranchAccountToUpsert-------------->'+lst_BranchAccountToUpsert);
                                                Database.UpsertResult[] arr_resultBrancheAccounts = Database.upsert(lst_BranchAccountToUpsert, Account.CompBranch__c,false);
                                                // System.debug('arr_resultBrancheAccounts----------->'+arr_resultBrancheAccounts);
                                                for(Integer index = 0, size = arr_resultBrancheAccounts.size();  index < size ; index++)
                                                {
                                                    for(Database.Error eachErr: arr_resultBrancheAccounts[index].getErrors())
                                                    {
                                                        str_ErrorMessage = eachErr.getMessage() + ':' + eachErr.getStatusCode();
                                                        lstExceptions.add(new ExceptionHandling.wrap_ErrorsHandling(sfxJSON.Propel_MSACode,sfxJSON.SFXCode, str_ErrorMessage, '901','temp_PropelISFXUpsert', 'Account:SFX' ));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                            // System.debug('sfxJSON.Billing_Info---->'+sfxJSON.Billing_Info);
                            // block to upsert the billing information. 
                            String MSANo;
                            String Billing_level;
                            String SFX;
                            String BillingBy;
                            String alias_name;
                            Date Start_Date;
                            Id BillingInfoId; 
                            List<Billing_Information__c> lst_BillingInformations = new List<Billing_Information__c>();
                            List<warp_BillinglineItems> lst_BillLineItems = new List<warp_BillinglineItems>();
                            List<Billing_line_Item__c> lst_BillingItemstoUpdate = new List<Billing_line_Item__c>();
                            Map<Decimal, Id> map_BranchMasterIds = new Map<Decimal, Id>();
                            Set<String> lst_SFXs = new Set<String>();
                            Set<Integer> setBranchMasterIds = new Set<Integer>();
                            for(jsonWrapBilling eachBillingInfo : sfxJSON.Billing_Info)
                            {
                                lst_SFXs.add(eachBillingInfo.SFX_no);
                                MSANo = eachBillingInfo.MSA;
                                Billing_level = eachBillingInfo.Billing_Level;
                                SFX = eachBillingInfo.SFX_no;
                                BillingBy = eachBillingInfo.Billing_type;
                                alias_name =eachBillingInfo.alias_name;
                                Start_Date = eachBillingInfo.Start_Date;
                                
                                // Iterating the billing line items. 
                                // System.debug('eachBillingInfo.billing_by--->'+eachBillingInfo.billing_by);
                                for(wrapBillinglineItems eachBillingLineItem : eachBillingInfo.billing_by)
                                {
                                    // System.debug('eachBillingLineItem-->'+eachBillingLineItem);
                                    if(eachBillingLineItem.Billing_Branch != null)                                                       
                                        setBranchMasterIds.add(eachBillingLineItem.Billing_Branch);                                        	
                                    if(eachBillingLineItem.Submission_branch != null)                                            
                                        setBranchMasterIds.add(eachBillingLineItem.Submission_branch);                                         	
                                    if(eachBillingLineItem.Collection_branch != null)                                            
                                        setBranchMasterIds.add(eachBillingLineItem.Collection_branch); 
                                        lst_BillLineItems.add(new warp_BillinglineItems(eachBillingInfo, eachBillingLineItem));
                                    
                                    
                                }
                                
                                
                            }
                            System.debug('lst_SFXs---------------------------------->'+lst_SFXs);
                             System.debug('lst_BillLineItems------------------------->'+lst_BillLineItems);
                            if(! setBranchMasterIds.isEmpty())
                            {
                                List<Branch_Master__c> lstBranchMaster = [SELECT id,PropelI_Branch_ID__c  from Branch_Master__c where PropelI_Branch_ID__c IN :setBranchMasterIds  limit 9999];
                                // System.debug('lstBranchMaster--------->'+lstBranchMaster);
                                if(! lstBranchMaster.isEmpty())
                                {
                                    for(Branch_Master__c eachBranchMaster : lstBranchMaster)
                                    {
                                        map_BranchMasterIds.put(eachBranchMaster.PropelI_Branch_ID__c,eachBranchMaster.Id);
                                    }
                                }
                            }
                            
                            // pull MSA records to associate 
                            if(! lst_SFXs.isEmpty())
                            {
                                List<Account> lstSFXAccount = [Select id, SFX_Code__c from Account where SFX_Code__c IN : lst_SFXs limit 9999];
                                // Created map to keep the account id's against of SFX code.
                                Map<String, Id> mapSFXAccounts = new Map<String, Id>();
                                if(! lstSFXAccount.isEmpty())
                                {
                                    for(Account eachSFXAccount : lstSFXAccount)
                                    {
                                        mapSFXAccounts.put(eachSFXAccount.SFX_Code__c, eachSFXAccount.Id);
                                    }
                                }
                                 System.debug('mapSFXAccounts-------------------->'+mapSFXAccounts);
                                
                                List<Billing_Line_Item__c> lineItems = new List<Billing_Line_Item__c>();
                                // SAC-9 - Added By K SANSI - IBM, Mark existing Billing information to in-active
                                
                                for(Billing_Line_Item__c item: [Select Id, Name, IsActive__c, Composite_key__c From  Billing_Line_Item__c where Billing_Information__r.SFX__c In: mapSFXAccounts.values()]){
                                    item.IsActive__c = false;
                                    lineItems.add(item);
                                }
                                
                                if(! lineItems.isEmpty()){
                                    Database.upsertResult[] billLineItemRecUpsrt = Database.upsert(lineItems, Billing_Line_Item__c.Fields.Composite_key__c, false);
                                    for(Integer index = 0, size = billLineItemRecUpsrt.size(); index < size; index++) {
                                        // Each API request response. 
                                        APIResponse cls_APIResponse = new APIResponse();
                                        cls_APIResponse.Errors = billLineItemRecUpsrt[index].getErrors(); 
                                        BillingInfoId = billLineItemRecUpsrt[index].getId();
                                        cls_APIResponse.BillingInformationId = billLineItemRecUpsrt[index].getId();
                                        cls_APIResponse.isCreated = billLineItemRecUpsrt[index].isCreated();
                                        
                                        if(cls_APIResponse.isCreated)
                                            cls_APIResponse.StatusMessage = 'The Billing Line Item record has been created successfully in SFDC.' ;
                                        else
                                            cls_APIResponse.StatusMessage = 'The Billing Line Item record has been updated successfully in SFDC.';
                                        cls_APIResponse.StatusCode = '200';    
                                        cls_APIResponse.isSuccess = billLineItemRecUpsrt[index].isSuccess();
                                        lst_APIResponses.add(cls_APIResponse);
                                        for(Database.Error eachErr: billLineItemRecUpsrt[index].getErrors())
                                        {
                                            str_ErrorMessage = eachErr.getMessage() + ':' + eachErr.getStatusCode();
                                            lstExceptions.add(new ExceptionHandling.wrap_ErrorsHandling(sfxJSON.Propel_MSACode,sfxJSON.SFXCode, str_ErrorMessage, '901','PropelISFXUpsert', 'Account:SFX' ));
                                        }
                                    }
                                }
                                
                                if(! mapSFXAccounts.isEmpty())
                                {
                                    // SAC-9 - Added By K SANSI - IBM, Mark existing Billing information to in-active
                                    // get all existing Billing information via composite key 
                                    
                                    List<String> sfxList = new List<String>(); 
                                    Map<String, Billing_Information__c> existingBillingInfoMap = new Map<String, Billing_Information__c>();
                                    for(jsonWrapBilling eachBillingInfo : sfxJSON.Billing_Info)
                                    {	    
                                        sfxList.add(eachBillingInfo.Sfx_no);
                                    } 
                                    if(sfxList.size() > 0){
                                        for(Billing_Information__c existingBillingInfo : [SELECT Id, Composite_key__c, MSA__c, SFX_no__c FROM Billing_Information__c 
                                                                                          WHERE SFX_no__c IN : sfxList]){
                                                                                              existingBillingInfo.IsActive__c = false;
                                                                                              existingBillingInfoMap.put(existingBillingInfo.Composite_key__c,existingBillingInfo);
                                                                                          }
                                    }
                                    Map<String,Billing_Information__c> cmpBillingInfo = new Map<String,Billing_Information__c>();
                                    for(jsonWrapBilling eachBillingInfo : sfxJSON.Billing_Info)
                                    {
                                        Billing_Information__c upsert_BillRec = new Billing_Information__c();
                                        upsert_BillRec.Billing_Level__c = eachBillingInfo.Billing_Level;
                                        upsert_BillRec.Billing_Type__c = eachBillingInfo.Billing_type; 
                                        upsert_BillRec.MSA__c = eachBillingInfo.MSA;
                                        upsert_BillRec.SFX_no__c = eachBillingInfo.Sfx_no;
                                        upsert_BillRec.Start_Date__c = eachBillingInfo.Start_date;
                                        upsert_BillRec.End_Date__c = eachBillingInfo.End_date;
                                        upsert_BillRec.Alias_name__c = eachBillingInfo.alias_name;
                                        upsert_BillRec.Rate_Card_no__c = eachBillingInfo.Rate_card_no;
                                        upsert_BillRec.Billing_Config_Id__c = eachBillingInfo.Billing_Config_Id;
                                        upsert_BillRec.Name = 'Billing Info:' + eachBillingInfo.MSA+':'+ eachBillingInfo.Sfx_no;
                                        if(eachBillingInfo.Status == 'ACTIVE'){ 
                                            upsert_BillRec.IsActive__c = True;
                                        }else{
                                            upsert_BillRec.IsActive__c = False;
                                        }
                                        
                                        if( String.isNotBlank(eachBillingInfo.Billing_Level) && eachBillingInfo.Billing_Level.equalsIgnoreCase('RATE CARD'))
                                            upsert_BillRec.Composite_key__c = eachBillingInfo.MSA + '::' + eachBillingInfo.Sfx_no+ '::' + eachBillingInfo.Rate_card_no;
                                        else   
                                            upsert_BillRec.Composite_key__c = eachBillingInfo.MSA + '::' + eachBillingInfo.Sfx_no; 
                                        if(mapSFXAccounts.keySet() != null && mapSFXAccounts.keySet().contains(eachBillingInfo.Sfx_no))    
                                            upsert_BillRec.SFX__c = mapSFXAccounts.get(eachBillingInfo.Sfx_no);
                                        
                                        // Added By Raghav SAC-513
                                        if (!cmpBillingInfo.containsKey(upsert_BillRec.Composite_key__c)){
                                            // System.debug('CmpBillingInfo--->'+CmpBillingInfo);
                                            CmpBillingInfo.put(upsert_BillRec.Composite_key__c,upsert_BillRec);
                                        }
                                        else if (upsert_BillRec.IsActive__c){
                                            // System.debug('CmpBillingInfo1--->'+CmpBillingInfo);
                                            //CmpBillingInfo.get(upsert_BillRec.Composite_key__c).IsActive__c = True;
                                            CmpBillingInfo.put(upsert_BillRec.Composite_key__c,upsert_BillRec);
                                            
                                        }
                                        
                                        if(existingBillingInfoMap.containsKey(upsert_BillRec.Composite_key__c)){
                                            existingBillingInfoMap.remove(upsert_BillRec.Composite_key__c);
                                        }
                                        
                                    } 
                                    if(existingBillingInfoMap.size() > 0){
                                        lst_BillingInformations.addAll(existingBillingInfoMap.values());
                                    }
                                    if(CmpBillingInfo.size()>0){
                                        lst_BillingInformations.addAll(CmpBillingInfo.values());
                                        // System.debug('lst_BillingInformations----->'+lst_BillingInformations);
                                    }
                                }
                            }
                            Set<Id> setBillingInformationIds = new Set<Id>();
                            // System.debug('lst_BillingInformations------------->'+lst_BillingInformations);
                            if(! lst_BillingInformations.isEmpty())
                            {
                                // upsert the Billing information records. 
                                Database.upsertResult[] billInformt = Database.upsert(lst_BillingInformations,Billing_Information__c.Fields.Composite_key__c, false);
                                // System.debug('billInformt---------->'+billInformt);
                                // System.debug('billInformt.getId()--------->'+billInformt.size());
                                
                                for(Integer index = 0, size = billInformt.size(); index < size; index++) {
                                    // Each API request response. 
                                    APIResponse cls_APIResponse = new APIResponse();
                                    cls_APIResponse.Errors = billInformt[index].getErrors(); 
                                    setBillingInformationIds.add(billInformt[index].getId());
                                    cls_APIResponse.BillingInformationId = billInformt[index].getId();
                                    cls_APIResponse.MSA = lst_BillingInformations[index].MSA__c;
                                    cls_APIResponse.SFX = lst_BillingInformations[index].SFX_no__c;
                                    cls_APIResponse.isCreated = billInformt[index].isCreated();
                                    if(cls_APIResponse.isCreated)
                                        cls_APIResponse.StatusMessage = 'The Billing record has been created successfully in SFDC.' ;
                                    else
                                        cls_APIResponse.StatusMessage = 'The Billing record has been updated successfully in SFDC.';
                                    cls_APIResponse.StatusCode = '200';    
                                    cls_APIResponse.isSuccess = billInformt[index].isSuccess();
                                    lst_APIResponses.add(cls_APIResponse);
                                    for(Database.Error eachErr: billInformt[index].getErrors())
                                    {
                                        str_ErrorMessage = eachErr.getMessage() + ':' + eachErr.getStatusCode();
                                        lstExceptions.add(new ExceptionHandling.wrap_ErrorsHandling(lst_BillingInformations[index].MSA__c,lst_BillingInformations[index].SFX_no__c, str_ErrorMessage, '901','temp_PropelISFXUpsert', 'Account:SFX' ));
                                    }
                                    
                                }
                            }
                            // System.debug('setBillingInformationIds---------------->'+setBillingInformationIds);
                            if(! setBillingInformationIds.isEmpty())
                            {
                                //pull the billing information which are being processed in this transaction. 
                                List<Billing_Information__c> lstUpsrtedBillingInfo = [Select Composite_key__c, id from Billing_Information__c where id IN : setBillingInformationIds limit 9999];
                                // System.debug('lstUpsrtedBillingInfo-------------->'+lstUpsrtedBillingInfo);
                                Map<String, Id> mapBillingInfoIds = new Map<String, Id>();
                                if(! lstUpsrtedBillingInfo.isEmpty())
                                {
                                    for(Billing_Information__c eachBillInfo : lstUpsrtedBillingInfo)
                                    {
                                        mapBillingInfoIds.put(eachBillInfo.Composite_key__c, eachBillInfo.Id);
                                    }
                                }
                                // System.debug('mapBillingInfoIds----->'+mapBillingInfoIds);
                                if(! mapBillingInfoIds.isEmpty())
                                {
                                    // Iterate billing line items information.
                                    for(warp_BillinglineItems eachBillLineItem : lst_BillLineItems)
                                    {
                                        // System.debug('eachBillLineItem-->'+eachBillLineItem);
                                        
                                        Billing_Line_Item__c upsertBillingLineItems = new Billing_Line_Item__c();
                                        
                                        upsertBillingLineItems.Billing_By_Id__c = eachBillLineItem.Billing_by_id;
                                        upsertBillingLineItems.Assign_billing_branch_id__c = eachBillLineItem.Assign_billing_branch_id;
                                        upsertBillingLineItems.State_Id__c = eachBillLineItem.State_id;
                                        
                                        upsertBillingLineItems.Billing_Address__c = eachBillLineItem.Billing_address;
                                        upsertBillingLineItems.Minimum_Billing__c = eachBillLineItem.Minimum_Billing;
                                        upsertBillingLineItems.Comm_Bill_Email__c = eachBillLineItem.Comm_bill_email;
                                        upsertBillingLineItems.Monthly_Potential__c = eachBillLineItem.Monthly_Potential;
                                        upsertBillingLineItems.Credit_Risk__c = eachBillLineItem.Credit_Risk;
                                        upsertBillingLineItems.Green_Book__c = eachBillLineItem.Gb_Ctgy;
                                        upsertBillingLineItems.Last_Bill_Date__c = eachBillLineItem.last_bill_dt;
                                        upsertBillingLineItems.Freight_MIS__c = eachBillLineItem.Freight_MIS;
                                        upsertBillingLineItems.e_Bill__c = eachBillLineItem.e_Bill;
                                        upsertBillingLineItems.POD_Sharing__c = eachBillLineItem.POD_Sharing;
                                        // if(eachBillLineItem.Freight_MIS == 'Yes'){
                                        //     upsertBillingLineItems.Freight_Type__c	= eachBillLineItem.Freight_Type;
                                        // }
                                        if(eachBillLineItem.Status == 'ACTIVE'){
                                            upsertBillingLineItems.IsActive__c = True;
                                        }else{
                                            upsertBillingLineItems.IsActive__c = False;
                                        }
                                        
                                        if(map_BranchMasterIds != null && ! map_BranchMasterIds.isEmpty())
                                        {
                                            
                                            if(eachBillLineItem.Submission_branch != null && map_BranchMasterIds.keySet().contains(eachBillLineItem.Submission_branch))
                                                upsertBillingLineItems.Submission_Branch__c = map_BranchMasterIds.get(eachBillLineItem.Submission_branch);
                                            if(eachBillLineItem.Collection_branch != null && map_BranchMasterIds.keySet().contains(eachBillLineItem.Collection_branch))
                                                upsertBillingLineItems.Collection_Branch__c = map_BranchMasterIds.get(eachBillLineItem.Collection_branch);
                                            
                                            if(eachBillLineItem.Billing_Branch != null && map_BranchMasterIds.keySet().contains(eachBillLineItem.Billing_Branch))
                                                upsertBillingLineItems.Billing_Branch__c = map_BranchMasterIds.get(eachBillLineItem.Billing_Branch);
                                        }
                                        
                                        
                                        String str_billingCompositeKey = eachBillLineItem.MSA +  '::' + eachBillLineItem.SFX + '::' + eachBillLineItem.RateCard; 
                                        String str_BillingSFXCompositeKey = eachBillLineItem.MSA +  '::' + eachBillLineItem.SFX;
                                        // System.debug('str_billingCompositeKey-------------->'+str_billingCompositeKey);
                                        // System.debug('str_BillingSFXCompositeKey---------->'+str_BillingSFXCompositeKey);
                                        Boolean isBillingInformationExist =  false;
                                        if(String.isNotBlank(eachBillLineItem.Billing_Level) && eachBillLineItem.Billing_Level.equalsIgnoreCase('RATE CARD'))
                                        {
                                            if(mapBillingInfoIds != null && mapBillingInfoIds.keySet().contains(str_billingCompositeKey))
                                            {
                                                upsertBillingLineItems.Billing_Information__c = mapBillingInfoIds.get(str_billingCompositeKey); 
                                                isBillingInformationExist = true; 
                                                // Composite key with the combination of MSA, SFX, Rate Card and Billing BY Id.  
                                                upsertBillingLineItems.Composite_Key__c = str_billingCompositeKey + '::' + eachBillLineItem.Billing_by_id; 
                                            }
                                            
                                        }
                                        else{
                                            
                                            if(mapBillingInfoIds != null && mapBillingInfoIds.keySet().contains(str_BillingSFXCompositeKey))
                                            {
                                                isBillingInformationExist = true; 
                                                upsertBillingLineItems.Billing_Information__c = mapBillingInfoIds.get(str_BillingSFXCompositeKey); 
                                                // Composite key with the combination of MSA, SFX, Rate Card and Billing BY Id.  
                                                upsertBillingLineItems.Composite_Key__c = str_BillingSFXCompositeKey+ '::' + eachBillLineItem.Billing_by_id; 
                                                
                                            }
                                            
                                        }
                                        // System.debug('isBillingInformationExist--------------------->'+isBillingInformationExist);
                                        if(isBillingInformationExist)
                                            lst_BillingItemstoUpdate.add(upsertBillingLineItems);
                                    }
                                }
                                
                                // System.debug('lst_BillingItemstoUpdate----------------->'+lst_BillingItemstoUpdate);
                                if(! lst_BillingItemstoUpdate.isEmpty())
                                {
                                    // upsert the Billing information records. 
                                    Database.upsertResult[] billLineItemRecUpsrt = Database.upsert(lst_BillingItemstoUpdate,Billing_Line_Item__c.Fields.Composite_key__c, false);
                                    for(Integer index = 0, size = billLineItemRecUpsrt.size(); index < size; index++) {
                                        // Each API request response. 
                                        APIResponse cls_APIResponse = new APIResponse();
                                        cls_APIResponse.Errors = billLineItemRecUpsrt[index].getErrors(); 
                                        BillingInfoId = billLineItemRecUpsrt[index].getId();
                                        cls_APIResponse.BillingInformationId = billLineItemRecUpsrt[index].getId();
                                        cls_APIResponse.isCreated = billLineItemRecUpsrt[index].isCreated();
                                        if(cls_APIResponse.isCreated)
                                            cls_APIResponse.StatusMessage = 'The Payment record has been created successfully in SFDC.' ;
                                        else
                                            cls_APIResponse.StatusMessage = 'The Payment record has been updated successfully in SFDC.';
                                        cls_APIResponse.StatusCode = '200';    
                                        cls_APIResponse.isSuccess = billLineItemRecUpsrt[index].isSuccess();
                                        lst_APIResponses.add(cls_APIResponse);
                                        for(Database.Error eachErr: billLineItemRecUpsrt[index].getErrors())
                                        {
                                            str_ErrorMessage = eachErr.getMessage() + ':' + eachErr.getStatusCode();
                                            lstExceptions.add(new ExceptionHandling.wrap_ErrorsHandling(sfxJSON.Propel_MSACode,sfxJSON.SFXCode, str_ErrorMessage, '901','temp_PropelISFXUpsert', 'Account:SFX' ));
                                        }
                                    }
                                    //Update upload SFX table records. 
                                    List<Temp_SFX_Upload__c> lstTempSFXUpdate = [SELECT Id,SFX__c,Is_Uploaded__c from Temp_SFX_Upload__c where SFX__c =: sfxNo]; 
                                    // System.debug('lstTempSFXUpdate------>'+lstTempSFXUpdate);
                                    if(! lstTempSFXUpdate.isEmpty())
                                    {
                                        lstTempSFXUpdate[0].Is_Uploaded__c = true;
                                        update lstTempSFXUpdate;
                                    }
                                }
                                
                            }
                            
                            // Capture the exception if any occurred. 
                            if(! lstExceptions.isEmpty())
                            {
                                ExceptionHandling.dataExceptionHandler(lstExceptions);
                            } 
                            if(Test.isRunningTest())
                            {
                                throw new dmlException();
                            }
                            
                            
                            if(!msaToUpdate.isEmpty()){
                                update msaToUpdate;
                            }
                        }
                        
                    }
                    
                }
            }catch(Exception e)
            {
                String name = 'SFX';
                String ClassName = 'SFX_RATE_UpsertAPI';
                ExceptionHandling.Exception( name, ClassName, e);
            }
            
        }
        
        return lstJsonUpsertResult;
    }
}