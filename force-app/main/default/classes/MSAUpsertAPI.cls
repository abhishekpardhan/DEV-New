@RestResource(urlMapping='/MSACreate/*')
global with sharing class MSAUpsertAPI {
    
    //Wrapper class to send the response in JSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        //String compositeKey;
        String accountId;
        String oppId;
        Boolean isCreated;
        Boolean isSuccess;
    }
    
    //Wrapper class to parse the JSON
    global class jsonWrap {
        public String Account_Name;
        //public String Region;
        public String Vertical;
        public String Sub_Vertical;
        public String Propel_MSACode;
        public String Propel_Key;
        public String Contact_Person_Name;
        public String Phone;
        public String Mobile;
        public String Email;
        public String Customer_Type;
        public String PAN;
        public String Opportunity_Name;
        public String Opportunity_Type;
        public Decimal X3PL_Potential;
        public String GST_Number;
        public Boolean GST_Exempted;
        public String TAN_Number;
        public Boolean TAN_Exempted;
        public String BILLING_STREET;
        public String BILLING_CITY;
        public String BILLING_COUNTRY;
        public String BILLING_ZIP_POSTAL_CODE;
        public String BILLING_STATE  ;
        public Date CLOSE_DATE;
        public String INSURANCE;
        public Decimal MONTHLY_POTENTIAL_AIR;
        public Decimal MONTHLY_POTENTIAL_SURFACE;
        public Decimal Charged_wt_waybill;
        public Decimal Value_of_goods_waybill;
        public String TYPE_OF_PACKAGING;
        public String WEBSITE;
        public Date CREATED_DATE;
        public String CORPORATE_OFFICE_LOCATION;
        public Integer Opp_Code;
    }
    
    //Post request to create Prospect customer within SFDC
    @HttpPost
    
    global static void createCustomer(List<MSAUpsertAPI.jsonWrap> accRecords) {
        System.debug('accRecords-------------->'+accRecords);
        try{     Opportunity__c[] opplist = new Opportunity__c[]{};
            for(MSAUpsertAPI.jsonWrap i : accRecords) {
                Account newAccount = new Account(Name = i.Account_Name, 
                                                 Region__c = 'Delhi',
                                                 Vertical__c = i.Vertical,
                                                 Sub__c = i.Sub_Vertical,
                                                 Propel_MSACode__c = i.Propel_MSACode,
                                                 Propel_Key__c = i.Propel_Key,
                                                 Contact_Person_Name__c = i.Contact_Person_Name,
                                                 Phone = i.Phone,
                                                 Mobile_No__c = i.Mobile,
                                                 Email__c = i.Email,
                                                 Type__c = i.Customer_Type,
                                                 Pan_No__c = i.PAN);
                Database.UpsertResult resultsacc = Database.upsert(newAccount,Account.Fields.Propel_MSACode__c, false);
                System.debug('resultsacc----->'+resultsacc);
                System.debug('newAccount Id------->'+newAccount.id);
                //Database.SaveResult resultsacc = Database.Insert(newAccount, false);
                integer namelen = i.Opportunity_Name.length();
                system.debug('length: ' +namelen);
                String namecut = i.Opportunity_Name.abbreviate(80);
                system.debug('namecut: ' +namecut);
                Opportunity__c Opp = new Opportunity__c (Name = namecut,
                                                         Name__c = i.Opportunity_Name,
                                                         Customer_Type__c = i.Opportunity_Type,
                                                         //X3PL_Potential__c = i.X3PL_Potential,
                                                         GST_Number__c = i.GST_Number,
                                                         Type__c = i.Customer_Type,      
                                                         Gst_Exempted__c = i.GST_Exempted,
                                                         TAN_No__c = i.TAN_Number,
                                                         TAN_Exempted__c = i.TAN_Exempted,
                                                         Billing_Street__c = i.BILLING_STREET,
                                                         Billing_City__c = 'Others',
                                                         Other_City__c = i.BILLING_CITY,
                                                         Billing_Country__c = i.BILLING_COUNTRY,
                                                         Billing_Zip_Postal_Code__c = i.BILLING_ZIP_POSTAL_CODE,
                                                         Billing_State__c = i.BILLING_STATE,
                                                         Close_Date__c = i.CLOSE_DATE,
                                                         Insurance__c = i.INSURANCE,
                                                         // Monthly_Potential_Air__c = i.MONTHLY_POTENTIAL_AIR,
                                                         // As per discussion, set the default value because the customer potential would not be clear.
                                                         Monthly_Potential_Air__c = 1,
                                                         Monthly_Potential_Surface__c = 1,
                                                         X3PL_Potential__c = 1,
                                                         // Monthly_Potential_Surface__c = i.MONTHLY_POTENTIAL_SURFACE,
                                                         Avg_wt_of_consignment_Kg__c = i.Charged_wt_waybill,
                                                         Value_of_Goods_Kg__c = i.Value_of_goods_waybill,
                                                         Type_of_Packaging__c = i.TYPE_OF_PACKAGING,
                                                         Website__c = i.WEBSITE,
                                                         Corporate_Office_Location__c = i.CORPORATE_OFFICE_LOCATION,
                                                         Account__c = newAccount.ID,
                                                         Opp_Code__c = i.Opp_Code,
                                                        Vertical__c = i.Vertical,
                                                 		Sub_Vertical__c = i.Sub_Vertical);
                
                opplist.add(Opp);                                             
            }
            System.debug('opplist-------->'+opplist);
            //the below field is inrtoduced break the recursive cycle to call MSA Push API. 
            cls_RecursiveHandler.bol_FlagToStopMSAPushAPI = true;
            
            Database.UpsertResult[] results = Database.upsert(opplist,Opportunity__c.Fields.Opp_Code__c, false);
            System.debug('results------->'+results);
            //Database.SaveResult[] results = Database.Insert(opplist, false);
            List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
            for(Integer index = 0, size = results.size(); index < size; index++) {
                JsonUpsertResult resultRow = new JsonUpsertResult();
                resultRow.oppId = results[index].getId();
                resultRow.accountId = opplist[index].Account__c;
                //    resultRow.isCreated = results[index].isCreated();
                resultRow.isSuccess = results[index].isSuccess();
                resultRow.Errors =  results[index].getErrors();
                lstJsonUpsertResult.add(resultRow);
                System.debug('lstJsonUpsertResult------>'+lstJsonUpsertResult);
            }
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
           }
        catch(Exception e){
            String name = 'MSA';
            String ClassName = 'MSAUpsertAPI';
            System.debug('Exception------>'+e);
            ExceptionHandling.Exception( name, ClassName, e);
        }
    }
}