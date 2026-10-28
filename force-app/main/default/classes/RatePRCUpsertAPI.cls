@RestResource(urlMapping='/PRCCreate/*')
global with sharing class RatePRCUpsertAPI {
    
    //Wrapper class to send the response in JSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;  
        String PRCId;
        Boolean isCreated;
        Boolean isSuccess;
    }
    
    //Wrapper class to parse the JSON
    global class jsonWrapPRC {
    public String Propel_MSACode;
        public String Msa_name;
        public String Propel_Key;
        public Integer id;
        public String Account_Id;
        public String prcCode;
                 public String Status;
        public Date Contract_Sign_date;
        public Date Contract_Start_date;
        public Date Contract_Expiry_date;
        public String Rate_card_applicable;
        public String Delivery_Hold;
        public String Business_Type;
        public String Service_line;
        public String Opportunity;
        public list<jsonWrapOffering> Offerings;
       // public List<jsonWrapBilling> Billing_Info;
        }
    
    global class jsonWrapOffering{
        public String Service_Offering;
        public list<jsonWrapRateEntity> prc_ratecard_entity;
    }
    
    global class jsonWrapRateEntity{
        public String entity_name;
        public String entity_type;
        public Integer id;
        public Boolean to_pay_flag;
        public Boolean paid_flag;
        public Date sign_date;
        public Date start_date;
        public Date end_date;
        public Integer base_location;
        public String status;
        public list<jsonWrapBranch> assign_branch; 
        //public String payment_mode;              
    }
    
    global class jsonWrapBranch{
        public Integer branch_id;
        public String tan_num;
        public String gst_num;
        public Date effective_date;
        public Date expiry_date;
        public String booking_hold;
        public String booking_hold_reason;
        public String delivery_hold;
        public String delivery_hold_reason;
        public String bill_to_addr; 
    }
    
     /*  global class jsonWrapBilling{
        public String payment_terms;
        public String gst_invoice_to;
        public String addr;
        public String gst_invoice_frequency;
        public String gstinNum;
        public String name;
    public Integer pincode;
        public String relation;
    }*/
    
    //Post request to create PRC customer within SFDC
    @httpPost
            global static void createCustomer() {
                try{
                RestRequest req=RestContext.request;
                RestResponse res=RestContext.response;
                string rr= req.requestBody.ToString();
                system.debug('Request Body rr:' +rr);
                
        String PRCRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        String RateRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        String OfferingRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        String AssignBranchRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
                List <Account> branchlist = new list<Account>();
                //List <Billing_Information__c> billinginfolist = new list<Billing_Information__c>();
               
                RatePRCUpsertAPI.jsonWrapPRC Jp = (RatePRCUpsertAPI.jsonWrapPRC) System.JSON.deserialize(rr,RatePRCUpsertAPI.jsonWrapPRC.class);                    
                Account newAccount = new Account(Name = Jp.PRCCode,
                                     PRC_Code__c = Jp.prcCode,
                                     Propeli_Id__c = Jp.id,
                           //Propel_MSACode__c = Jp.Propel_MSACode,
                             Propel_key__c= Jp.Propel_Key,
                             ParentId = Jp.Account_Id,
                                     RecordTypeID = PRCRecordTypeID,
                                     Contract_Sign_Date__c = Jp.Contract_Sign_date,
                                     Contract_Effective_Date__c = Jp.Contract_Start_date,
                                     Contract_Expiry_date__c = Jp.Contract_Expiry_date,
                                     Rate_Card_Applicable__c = Jp.Rate_card_applicable,           
                                     Delivery_Hold__c = Jp.Delivery_Hold,            
                                     Business_Type__c = Jp.Business_Type,
                                     Service_line__c = Jp.Service_line,
                                                 Status__c = Jp.Status,
                                     Opportunity__c = Jp.Opportunity);
                               system.debug('Jp:  ' +Jp);
               Database.UpsertResult resultsacc = Database.upsert(newAccount, Account.PRC_Code__c,false);
               list<JsonUpsertResult> resp = new list<JsonUpsertResult>();
               JsonUpsertResult JsonUpsertResult1 = new JsonUpsertResult();
               JsonUpsertResult1.Errors = resultsacc.getErrors(); 
               JsonUpsertResult1.PRCId = newAccount.Id;
               JsonUpsertResult1.isCreated  = resultsacc.isCreated();
               JsonUpsertResult1.isSuccess  = resultsacc.isSuccess();
                resp.add(JsonUpsertResult1);
              RestContext.response.addHeader('Content-Type', 'application/json');
             RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
                 system.debug(+newAccount); 
                
                for(jsonWrapOffering Jp1 : Jp.Offerings){
                system.debug(+Jp1.Service_Offering); 
                
                Account newOffering = new Account(Name = Jp1.Service_Offering,
                Service_Offering__c = Jp1.Service_Offering,
                RecordTypeID = OfferingRecordTypeID,                                  
                ParentId = newAccount.Id,
                Comp__c = Jp1.Service_Offering + '-' + Jp.prcCode);
              Database.UpsertResult resultsoff = Database.upsert(newOffering, Account.Comp__c,false);
                              
                    for(jsonWrapRateEntity Jp2 : Jp1.prc_ratecard_entity) {
                    Account newRate = new Account(Name = Jp2.entity_name,
                                                Entity_Type__c = Jp2.entity_type,
                                                rate_card_id__c = Jp2.id,
                                               // Payment_Mode__c = Jp2.payment_mode,
                                          RecordTypeID = RateRecordTypeID,
                                                To_Pay_Flag__c = Jp2.to_pay_flag,
                                                paidFlag__c = Jp2.paid_flag, 
                                                Sign_date__c = Jp2.sign_date,
                                                Rate_card_start_date__c = Jp2.start_date,
                                                Rate_card_end_date__c = Jp2.end_date,
                                                Status__c = Jp2.Status,
                                                ParentId = newOffering.id,
                                                Composite_Key__c = Jp2.id + '-' + Jp1.Service_Offering + '-' + Jp.prcCode);
                    if(!(Jp2.base_location == null))
                    newRate.Base_Location__r = new Branch_Master__c(PropelI_Branch_ID__c = Jp2.base_location);
                   // ratecardlist.add(newRate);
                Database.UpsertResult resultRC = Database.upsert(newRate,Account.Fields.Composite_Key__c, false);
                        system.debug('Rate Card: '+newRate);
                   // system.debug('ratecardlist' +ratecardlist);
                    
                for(jsonWrapBranch Jp3 : Jp2.assign_branch) {
                    Account newBranch = new Account(Name = 'Assign Branch:' + Jp2.entity_name + '-' + Jp.prcCode,
                                                RecordTypeID = AssignBranchRecordTypeID,
                                                Propel_Assign_Branch_Id__c = Jp3.branch_id,
                                                TAN__c = Jp3.tan_num,
                                                GST__c = Jp3.gst_num,
                                                Branch_Effective_Date__c = Jp3.effective_date,
                                                Expiry_Date__c = Jp3.expiry_date,
                                                Booking_hold__c = Jp3.booking_hold,
                                                Booking_Hold_Reason__c = Jp3.booking_hold_reason,
                                                Delivery_Hold__c = Jp3.delivery_hold,
                                                Delivery_Hold_Reason__c = Jp3.delivery_hold_reason,
                                                Bill_To_Address__c = Jp3.bill_to_addr,    
                                                CompBranch__c = String.valueOf(Jp3.branch_id) + '-' + Jp2.id + '-' + Jp1.Service_Offering + '-' + Jp.prcCode,  
                                                ParentId = newRate.id);

                    if(!(Jp3.branch_id == null))
                    newBranch.assign_branch_id__r = new Branch_Master__c(PropelI_Branch_ID__c = Jp3.branch_id);
                    system.debug('newBranch:  '+newBranch);
                    branchlist.add(newBranch);
                   // system.debug('branchlist:  ' +branchlist);
                }
                   Database.UpsertResult[] resultBr = Database.upsert(branchlist,Account.Fields.CompBranch__c, false);
                   system.debug('branchlist:  ' +branchlist);  
                    }
                }
                }catch(Exception e){
            String name = 'PRC';
            String ClassName = 'RatePRCUpsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);
                  }
               }
}