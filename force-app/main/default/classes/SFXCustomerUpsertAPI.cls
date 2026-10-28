/**
 * Description		:		Rest resource to create SFX customer(Accounts) in SFDC via third party system
 * Created By       :       
 * Created Date     :       
 * Release          :       March, 2020
 * Last Modified on :       March 23, 2020
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 							https://safexpress.atlassian.net/browse/SD-566
 **/
@RestResource(urlMapping='/SFXCustCreate/*')
global with sharing class SFXCustomerUpsertAPI {
      
    //Wrapper class to send the response in JSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        String compositeKey;
        Boolean isCreated;
        Boolean isSuccess;
    }
    
    //Wrapper class to parse the JSON come in response
    global class jsonWrap {
        public String Name;
        public Integer Propel_ID;
        public String SFX_Code;
        public String Customer_Type;
        public String Customer_Type_Description;
        public Integer Booking_Branch_ID;
        public Integer Collection_Branch_ID;
        public Integer Submission_Branch_ID;
        public Integer Base_Location;
        public Date Contract_Effective_Date;
        public Date Contract_Expiry_Date;
        public Date Contract_Sign_Date;
        public Date Effective_Date;
        public Date Expiry_Date;
        public ID Parent_Account_ID;
        public ID Opportunity_ID;
        public String Primary_Address1;
        public String Primary_Address2;
        public String Primary_Address3;
        public String Primary_Address4;
        public String Primary_City;
        public String Primary_State;
        public String Primary_Country;
        public String Primary_Pincode;
        public String Billing_Address1;
        public String Billing_Address2;
        public String Billing_Address3;
        public String Billing_Address4;
        public String Billing_City;
        public String Billing_State;
        public String Billing_Country;
        public String Billing_Pincode;
        public String Type;
        public String Blocked;
        public String Incremental_Clause;
        public Boolean To_Pay_Flag;
        
    }
    
    //Post request to create SFX customer within SFDC
    @HttpPost
    
        global static void createCustomer(List<SFXCustomerUpsertAPI.jsonWrap> accRecords) {
       try{
            List<Account> accts = new List<Account>();
        String SFXRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
            for(SFXCustomerUpsertAPI.jsonWrap i : accRecords) {
                try{    Account newAccount = new Account(Name = i.Name + ' (' + i.SFX_Code + ')', 
                                     Propel_ID__c = i.Propel_ID,
                                     SFX_Code__c = i.SFX_Code,
                                     Customer_Type__c = i.Customer_Type,
                                     Customer_Type_Description__c = i.Customer_Type_Description,
                                     Contract_Effective_Date__c = i.Contract_Effective_Date,
                                     Contract_Expiry_Date__c = i.Contract_Expiry_Date,
                                     Contract_Sign_Date__c = i.Contract_Sign_Date,
                                     Effective_Date__c = i.Effective_Date,
                                     Expiry_Date__c = i.Expiry_Date,
                                     parentId = i.Parent_Account_ID,
                                     Opportunity__c = i.Opportunity_ID,
                                     Composite_Key__c = i.SFX_Code + '-' + String.valueOf(i.Booking_Branch_ID),                                     
                                     RecordTypeID = SFXRecordTypeID,
                                     ShippingStreet = i.Primary_Address1 + ',' + i.Primary_Address2 + ',' + i.Primary_Address3 + ',' + i.Primary_Address4,
                                     ShippingCity = i.Primary_City,
                                     ShippingState = i.Primary_State,
                                     ShippingCountry = i.Primary_Country,
                                     ShippingPostalCode = i.Primary_Pincode,
                                     BillingStreet = i.Billing_Address1 + ',' + i.Billing_Address2 + ',' + i.Billing_Address3 + ',' + i.Billing_Address4,
                                     BillingCity = i.Billing_City,
                                     BillingState = i.Billing_State,
                                     BillingCountry = i.Billing_Country,
                                     BillingPostalCode = i.Billing_Pincode,
                                     Type__c = i.Type,
                                     Blocked__c = i.Blocked,
                                     Incremental_Clause__c = i.Incremental_Clause,
                                     To_Pay_Flag__c = i.To_Pay_Flag,
                                     Is_Propel_Account__c = True   // Modified as part of the JIRA SAC-122 to identify if the account is created by propel system.              
                                     );
                if(!(i.Base_Location == null))
                    newAccount.Base_Location__r = new Branch_Master__c(Branch_ID__c = i.Base_Location);
                if(!(i.Booking_Branch_ID == null))
                    newAccount.Booking_Branch__r = new Branch_Master__c(Branch_ID__c = i.Booking_Branch_ID);
                if(!(i.Submission_Branch_ID == null))
                    newAccount.Submission_Branch__r = new Branch_Master__c(Branch_ID__c = i.Submission_Branch_ID);
                if(!(i.Collection_Branch_ID == null))
                    newAccount.Collection_Branch__r = new Branch_Master__c(Branch_ID__c = i.Collection_Branch_ID);
                accts.add(newAccount);
                   }
            catch(exception e)
            {
            String name = 'SFX Customer for loop';
            String ClassName = 'SFXCustomerUpsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);
                   }
                system.debug('List of accounts: '+accts);
            }
           system.debug('Size of List:'+ accts.size());
        Database.UpsertResult[] results = Database.upsert(accts, Account.Fields.Composite_Key__c, false);
        List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
        for(Integer index = 0, size = results.size(); index < size; index++) {
        JsonUpsertResult resultRow = new JsonUpsertResult();
        resultRow.Errors =  results[index].getErrors();
                system.debug('resultRow.Errors: '+resultRow.Errors);
        resultRow.SFId = results[index].getId();
                system.debug('resultRow.SFId: '+resultRow.SFId);
        resultRow.CompositeKey = accts[index].Composite_Key__c;
        resultRow.isCreated = results[index].isCreated();
                system.debug('isCreated: '+resultRow.isCreated);
        resultRow.isSuccess = results[index].isSuccess();
                system.debug('isSuccess: '+resultRow.isSuccess);
        lstJsonUpsertResult.add(resultRow);
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
        }catch(Exception e){ // Added by shubham Girdhar reffering jira ticket: SD-417
String name = 'SFX Customer';
            String ClassName = 'SFXCustomerUpsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);            
        }
    }
}