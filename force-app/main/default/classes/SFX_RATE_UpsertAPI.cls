@RestResource(urlMapping='/InactiveSFX_RATECreate/*')
global with sharing class SFX_RATE_UpsertAPI {
      
    //Wrapper class to send the response in JSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;  
        String SFXId;
     // String RCId;
        Boolean isCreated;
        Boolean isSuccess;
    }
    
    //Wrapper class to parse the JSON
    global class jsonWrapSFX {
        public String Propel_MSACode;
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
        public List<jsonWrapOffering> Offerings;
        public List<jsonWrapBilling> Billing_Info;
      }
    
      global class jsonWrapOffering {
        public String Service_Offering;
        public list<jsonWrapRATE> Rate_card;
        }

        global class jsonWrapRATE {
        public string rate_card_name;
        public Integer id;
        public Date Sign_date;
        public Date Start_date;
        public Date End_date;
        public Integer Base_location;
        public string Status; 
        public String SFXCode;
        public list<jsonWrapBranch> assign_branch; 
    }
        global class jsonWrapBranch {
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
    
        global class jsonWrapBilling {
        public String Billing_Level;
        public String Rate_card_no;
        public String SFX_no;
        public String msa;
        public Date Start_date;
        public Date End_date;
        public String alias_name;
        }
    
          
    //Post request to create SFX customer within SFDC
    @HttpPost
            global static void createCustomer() {
                try{
                RestRequest req=RestContext.request;
                RestResponse res=RestContext.response;
                
                string rr= req.requestBody.ToString();
                system.debug('Request Body rr:' +rr);
                
        String SFXRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        String RateRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        String OfferingRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        String AssignBranchRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
                List <Account> branchlist = new list<Account>();
                List <Billing_Information__c> billinginfolist = new list<Billing_Information__c>();
                SFX_RATE_UpsertAPI.jsonWrapSFX Jp = (SFX_RATE_UpsertAPI.jsonWrapSFX) System.JSON.deserialize(rr,SFX_RATE_UpsertAPI.jsonWrapSFX.class);                    
                Account newAccount = new Account(Name = Jp.SFXCode,
                                     SFX_Code__c = Jp.SFXCode,
                                     Propeli_Id__c = Jp.id,
                          // Propel_MSACode__c = Jp.Propel_MSACode,
                             Propel_key__c= Jp.Propel_Key,
                             ParentId = Jp.Account_Id,
                                     RecordTypeID = SFXRecordTypeID,
                                     Contract_Sign_Date__c = Jp.Contract_Sign_Date,
                                     Contract_Effective_Date__c = Jp.Contract_Start_date,
                                     Contract_Expiry_date__c = Jp.Contract_Expiry_date, 
                                     Direct_Pickup__c = Jp.Direct_Pickup,
                                     Delivery_Hold__c = Jp.Delivery_Hold, 
                                     Status__c = Jp.Status,
                                     Business_Type__c = Jp.Business_Type,
                                     Service_line__c = Jp.Service_line,
                                     Opportunity_IDs__c = Jp.Opportunity ,
                                     Opportunity__c =  Jp.Opportunity 
                                     );
               system.debug('Jp:  ' +Jp);
       //Database.UpsertResult resultsacc = Database.upsert(newAccount,Account.Fields.Propel_MSACode__c, false);
               Database.UpsertResult resultsacc = Database.upsert(newAccount, Account.SFX_Code__c,false);
                   list<JsonUpsertResult> resp = new list<JsonUpsertResult>();
               JsonUpsertResult JsonUpsertResult1 = new JsonUpsertResult();
               JsonUpsertResult1.Errors = resultsacc.getErrors(); 
               JsonUpsertResult1.SFXId = newAccount.Id;
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
                Comp__c = Jp1.Service_Offering + '-' + Jp.SFXCode);
              Database.UpsertResult resultsoff = Database.upsert(newOffering, Account.Comp__c,false);
                                                             
                for(jsonWrapRate Jp2 : Jp1.Rate_card) {
                    Account newRate = new Account(Name = Jp2.rate_card_name,
                                                rate_card_id__c = Jp2.id,
                                          RecordTypeID = RateRecordTypeID,
                                             //AKK   Sign_date__c = Jp2.Sign_date,
                                                Rate_card_start_date__c = Jp2.Start_date,
                                                Rate_card_end_date__c = Jp2.End_date,
                                              //  Base_Location__c = Jp2.Base_Location,
                                                Status__c = Jp2.Status,
                                                ParentId = newOffering.id,
                                                Composite_Key__c = Jp2.id + '-' + Jp1.Service_Offering + '-' + Jp.SFXCode);
                    if(!(Jp2.Base_Location == null))
                    newRate.Base_Location__r = new Branch_Master__c(PropelI_Branch_ID__c = Jp2.Base_Location);
                   // ratecardlist.add(newRate);
                Database.UpsertResult resultRC = Database.upsert(newRate,Account.Fields.Composite_Key__c, false);
                   // system.debug('ratecardlist' +ratecardlist);
                                    
                for(jsonWrapBranch Jp3 : Jp2.assign_branch) {
                    Account newBranch = new Account(Name = 'Assign Branch:' + Jp2.rate_card_name + '-' + Jp.SFXCode,
                                                BillingStreet = Jp3.BILLING_STREET,
                                                BillingCity = Jp3.BILLING_CITY,
                                                BillingState = Jp3.BILLING_STATE,
                                                BillingCountry = Jp3.BILLING_COUNTRY,
                                                BillingPostalCode = Jp3.BILLING_ZIP_POSTAL_CODE,
                                                Minimum_Billing__c = Jp3.Minimum_Billing,
                                                E_Bill_id__c = Jp3.E_Bill_id,
                                                Effective_Date__c = Jp3.Effective_date,
                                                Booking_hold__c= Jp3.Booking_hold,
                                                Booking_Hold_Reason__c = Jp3.Booking_Hold_Reason,
                                                Delivery_Hold__c= Jp3.delivery_hold,
                                                Delivery_Hold_Reason__c= Jp3.delivery_hold_reason,
                                                Expiry_Date__c = Jp3.expiry_date,
                                                Monthly_Potential__c = Jp3.Monthly_Potential,
                                                Comm_bill_email__c = Jp3.Comm_bill_email,
                                                RecordTypeID = AssignBranchRecordTypeID,
                                                GST__c = Jp3.GST,
                                                Billing_State_Id__c = Jp3.Billing_State_id,
                                                AssignBranch_ID__c = String.valueOf(Jp3.assign_branch_id),
                                                CompBranch__c = String.valueOf(Jp3.assign_branch_id) + '-' + Jp2.id + '-' + Jp1.Service_Offering + '-' + Jp.SFXCode,  
                                                ParentId = newRate.id);
                    if(!(Jp3.Billing_Branch == null))
                    newBranch.Billing_Branch__r = new Branch_Master__c(PropelI_Branch_ID__c = Jp3.Billing_Branch); 
                    if(!(Jp3.Submission_Branch == null))
                    newBranch.Submission_Branch__r = new Branch_Master__c(PropelI_Branch_ID__c = Jp3.Submission_Branch);
                    if(!(Jp3.Collection_Branch == null))
                    newBranch.Collection_Branch__r = new Branch_Master__c(PropelI_Branch_ID__c = Jp3.Collection_Branch);
                   // if(!(Jp3.Collection_Branch == null))// As this is received as Propel-I assigned branch record id not branch master record id in SFDC. 
                    //newBranch.assign_branch_id__r = new Branch_Master__c(PropelI_Branch_ID__c = Jp3.assign_branch_id); 
                    system.debug('newBranch:  '+newBranch);
                    // Database.UpsertResult resultBr = Database.upsert(newBranch,Account.Fields.CompBranch__c, false);
                    branchlist.add(newBranch);
                   // system.debug('branchlist:  ' +branchlist); 
                }
                 Database.UpsertResult[] resultBr = Database.upsert(branchlist,Account.Fields.CompBranch__c, false);
                   system.debug('branchlist:  ' +branchlist);

                } 
                }
                System.debug('Jp.Billing_Info---->'+Jp.Billing_Info);
                System.debug('newAccount----->'+newAccount);
              for(jsonWrapBilling JJ : Jp.Billing_Info){
              System.debug('Billing Information Block!!');
                    Billing_Information__c BI = new Billing_Information__c(Name = 'Billing Info:' + JJ.SFX_no + '-' + JJ.msa,
                                                          Billing_Level__c = JJ.Billing_Level,
                                                          Rate_Card_no__c = JJ.Rate_Card_no,
                                                          SFX_no__c = JJ.SFX_no,
                                                          SFX__c = newAccount.Id,                 
                                                          MSA__c = JJ.msa,
                                                          Start_Date__c = JJ.Start_Date,
                                                          End_Date__c = JJ.End_Date,
                                                          Alias_name__c = JJ.alias_name,
                                                          //Akshay(27/10): As the Rate card is receiving as blank and not allowing to insert the billing records, therefore, used MSA instead of Rate card. 
                                                         // Composite_key__c = JJ.SFX_no + '-' + JJ.Rate_Card_no); 
                                                         Composite_key__c = JJ.SFX_no + '-' + JJ.msa); 
                                                         billinginfolist.add(BI );
                }
                   Database.UpsertResult[] resultBI = Database.upsert(billinginfolist,Billing_Information__c.Fields.Composite_key__c, false); 
                   for(Integer i = 0; i < resultBI.size(); i++) 
                   {
                        if(resultBI[i].isSuccess()) 
                        {
                            if(resultBI[i].isCreated()) {
                                System.debug(billinginfolist[i].Composite_key__c+' was created');
                            } else {
                                System.debug(billinginfolist[i].Composite_key__c+' was updated');
                            }     
                        }
                        if (!resultBI.get(i).isSuccess())
                        {
                            Database.Error err = resultBI.get(i).getErrors().get(0);
                            System.debug('Error - '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields());
                        }
                    }
                }catch(Exception e){
            String name = 'SFX';
            String ClassName = 'SFX_RATE_UpsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);
                }
            }

}