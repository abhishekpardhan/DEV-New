/**
 * Description		:		Rest resource for Upserting the Leads records within SFDC 
 * Created By       :       Shubham Girdhar
 * Created Date     :       
 * Release          :       18th August, 2019
 * Last Modified on :       8th August, 2019
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
@RestResource(urlMapping='/LeadCreate/*')
global with sharing class LeadUpsertAPI {
    
    //Wrapper class to send the response in jSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        String Lead_Name;
        Boolean isSuccess;
    }
    
    //Wrapper class to store substring of JSONString
    global class jsonWrap {
        public String Lead_Name;
        public String Contact_Person_Name;
        public String Phone;
        public String Email;
        public String Rating;
        public String Source;
        public String Campaign_Name;
        public String Lead_Type;
        public String Vertical;
        public String Sub_Vertical;
        public String Description;
        public String Country;
        public String City;
        public String State;
        public String Address;
        public String Zip_Code;
        public String Region;
        public String Token_Number;
        public Integer Branch;
    }
    
    //POST request method to upsert leads within SFDC
    @HttpPost
    global static void createLead(List<LeadUpsertAPI.jsonWrap> leadRecords) {
        try{    Lead__c[] leads = new Lead__c[]{};
            Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.AllowSave = false;
          dml.OptAllOrNone = false;
            for(LeadUpsertAPI.jsonWrap i : leadRecords) {
                Lead__c newLead = new Lead__c(Name = i.Lead_Name, 
                                     Contact_Person_Name__c  = i.Contact_Person_Name,
                                     Phone__c = i.Phone,
                                     Email__c = i.Email,
                                     Rating__c  = i.Rating,
                                     Source__c = i.Source,
                                     Campaign_Name__c = i.Campaign_Name,
                                     Status__c = 'Active',
                                     Type__c = i.Lead_Type,
                                     Vertical__c = i.Vertical,
                                     Sub_Vertical__c = i.Sub_Vertical,
                                     Description__c = i.Description,
                                     Country__c = i.Country,
                                     City__c = i.City,
                                     State__c = i.State,
                                     Street__c = i.Address,
                                     ZIP_Postal_Code__c = i.ZIP_Code,
                                     Assigned_to_Central_Desk__c = true,
                                     Region__c = i.Region,
                                     Token_Number__c = i.Token_Number);
                if(!(i.Branch == null))
                    newLead.Booking_Branch__r = new Branch_Master__c(Branch_ID__c = i.Branch);
                leads.add(newLead);
            }
        Database.SaveResult[] results = Database.insert(leads, dml);
 
        List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
        for(Integer index = 0, size = results.size(); index < size; index++) {
        JsonUpsertResult resultRow = new JsonUpsertResult();
        resultRow.Errors =  results[index].getErrors();
        resultRow.SFId = results[index].getId();
        resultRow.Lead_Name = leads[index].Name;
        resultRow.isSuccess = results[index].isSuccess();
        lstJsonUpsertResult.add(resultRow);
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
    }catch(Exception e){ // Added by shubham Girdhar reffering jira ticket: SD-417
        String name = 'Lead';
            String ClassName = 'LeadUpsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);            
    }
    }
}