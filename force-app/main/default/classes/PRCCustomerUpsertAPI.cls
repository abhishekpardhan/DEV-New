/**
 * Description      :       Rest resource to create the Parent Account records within SFDC
 * Created By       :       Shubham Girdhar
 * Created Date     :       
 * Release          :       18th August, 2019
 * Last Modified on :       8th August, 2019
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
@RestResource(urlMapping='/PRCCustCreate/*')
global with sharing class PRCCustomerUpsertAPI {
    
    //Wrapper class to send the response in the JSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        String compositeKey;
        Boolean isCreated;
        Boolean isSuccess;
    }
    
    //Wrapper class to parse JSON String
    global class jsonWrap {
        public String Name;
        public Integer Propel_ID;
        public String PRC_Code;
        public Integer Branch;
        public String TIN_NO;
        public String Address1;
        public String Address2;
        public String State;
        public String District;
        public String City;
        public String Country;
        public String Zip_Code;
        public String Phone;
        public String Mobile_No;
        public String Email;
        public String CST_No;
        public String Status;
        public String Segment;
        public String Sub_Segment;
        public Integer Monthly_Potential_Surface;
        public Integer Monthly_Potential_Air;
        public String Created_By;
        public Date Created_Date;
        public String Updated_By;
        public Date Updated_Date;
        public String Product;
        public String By_Railway_Parcel;
        public String Consignee_Type;
        public Date Effective_Date;
        public Date Expiry_Date;
        public String Nature_Of_Business;
        public String Major_Consignee_Details;
        public String Org_Type;
        public String PAN_No;
        public String Present_Service_Provider;
        public String SFX_Code;
        public String Website;
        public String Major_Consignee_Names;
        public ID Parent_Account_ID;
        public ID Opportunity_ID;
    }
    
    //POST request method to create 'PRC Customer' type accounts within SFDC
    @HttpPost
    global static void createPRCCustomer(List<PRCCustomerUpsertAPI.jsonWrap> prcRecords) {
    System.debug('prcRecords----------------->'+prcRecords);
       try{ Account[] accts = new Account[]{};
            String PRCRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
            for(PRCCustomerUpsertAPI.jsonWrap i : prcRecords) {
                Account newAccount = new Account(Name = i.Name + ' (' + i.PRC_Code + ')', 
                                     Propel_ID__c = i.Propel_ID,
                                     PRC_Code__c = i.PRC_Code,
                                     TIN_No__c = i.TIN_No,
                                     BillingStreet = i.Address1 + ',' + i.Address2 + ',' + i.District,
                                     BillingState = i.State,
                                     BillingCity = i.City,
                                     BillingCountry = i.Country,
                                     BillingPostalCode = i.Zip_Code,
                                     Phone = i.Phone,
                                     Mobile_No__c = i.Mobile_No,
                                     Email__c = i.Email,
                                     CST_No__c = i.CST_No,
                                     RecordTypeID = PRCRecordTypeID,
                                     Status__c = i.Status,
                                     Segment__c = i.Segment,
                                     Sub_Segment__c = i.Sub_Segment,
                                     Monthly_Potential_Surface__c = i.Monthly_Potential_Surface,
                                     Monthly_Potential_Air__c = i.Monthly_Potential_Air,
                                     Propel_Created_By__c = i.Created_By,
                                     Propel_Created_Date__c = i.Created_Date,
                                     Propel_Updated_By__c = i.Updated_By,
                                     Propel_Updated_Date__c = i.Updated_Date,
                                     Product__c = i.Product,
                                     By_Railway_Parcel__c = i.By_Railway_Parcel,
                                     Consignee_Type__c = i.Consignee_Type,
                                     Effective_Date__c = i.Effective_Date,
                                     Expiry_Date__c = i.Expiry_Date,
                                     Nature_Of_Business__c = i.Nature_Of_Business,
                                     Major_Consignee_Details__c = i.Major_Consignee_Details,
                                     Org_Type__c = i.Org_Type,
                                     PAN_No__c = i.PAN_No,
                                     Present_Service_Provider__c = i.Present_Service_Provider,
                                     SFX_Code__c = i.SFX_Code,
                                     Website = i.Website,
                                     Major_Consignee_Name__c = i.Major_Consignee_Names,
                                     Composite_Key__c = i.Propel_ID + '-' + i.PRC_Code + '-' + String.valueOf(i.Branch),
                                     parentId = i.Parent_Account_ID,
                                     Opportunity__c = i.Opportunity_ID,
                                     Type__c = 'Retail');
                if(!(i.Branch == null))
                    newAccount.Branch__r = new Branch_Master__c(Branch_ID__c= i.Branch);
                accts.add(newAccount);
            }
        Database.UpsertResult[] results = Database.upsert(accts, Account.Fields.Composite_Key__c, false);
 
        List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
        for(Integer index = 0, size = results.size(); index < size; index++) {
        JsonUpsertResult resultRow = new JsonUpsertResult();
        resultRow.Errors =  results[index].getErrors();
        resultRow.SFId = results[index].getId();
        resultRow.CompositeKey = accts[index].Composite_Key__c;
        resultRow.isCreated = results[index].isCreated();
        resultRow.isSuccess = results[index].isSuccess();
        lstJsonUpsertResult.add(resultRow);
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
       }Catch(Exception e){ // Added by shubham Girdhar reffering jira ticket: SD-417
            String name = 'PRC Customer';
            String ClassName = 'PRCCustomerUpsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);

       }
    }
}