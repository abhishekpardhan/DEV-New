//Helper class for Contact Trigger
//JIRA ticket: https://safexpress.atlassian.net/browse/SD-453
//Last Modified: Shubham Girdhar on 06/01/2020

public class triggerContactHelper {
    
    //Method to create new leads in the system if the Lead Source on contact is Directory
    public static void createLeads(list<contact> lstContacts ,Set<Id> idsOwner){
        
        List<String> EmailList = new List<String>();
        try{
            List<lead__c> lstLeads = new List<lead__c>();
            List<String> StateList = new List<String>();
            Map<Id,Id> mapOwnerToCampaign = new Map<Id,Id>(); 
            List<Event__c> EveList = [Select Id,Campaign__c,ownerId from Event__c where ownerId IN : idsOwner and Status__c != 'Cancelled' and CheckIn_Date__c !=null and CheckOut_Date__c = null and Campaign__c !=null]; 
            if(EveList.size() > 0){
                for(Event__c objEve : EveList){                
                    mapOwnerToCampaign.put(objEve.ownerId,objEve.Campaign__c);
                }
            }
            
            
            Schema.DescribeFieldResult statefieldResult = Lead__c.State__c.getDescribe();
            for( Schema.PicklistEntry state : statefieldResult.getPicklistValues())
            {
                StateList.add(state.getValue());
            } 
            for(contact c: lstContacts){
                Lead__c ld = new Lead__c();
                ld.Name = c.Lead__c;
                ld.Contact_Person_Name__c = c.FirstName + ' ' +c.LastName;
                ld.Email__c = c.Email;
                ld.Source__c = c.LeadSource;
                //ld.Country__c = c.ContentDocumentLink.Checksum;
                ld.Street__c = c.MailingStreet;
                ld.Zip_Postal_Code__c = c.MailingPostalCode;
                ld.Phone__c = c.Phone;
                ld.Mobile_No__c = c.MobilePhone;
                ld.Type__c = c.Lead_Type__c;
                ld.Description__c = c.Details__c;
                ld.call_Needed__c = c.Call_Needed__c;
                ld.Status__c = 'Active';
                ld.Contact_Person_Title__c = c.Title;
                ld.organization_Website__c = c.Company_Website__c;
                if(StateList.size() > 0 && StateList.contains(c.Contact_State__c)){ //Added by Monika
                    ld.State__c = c.Contact_State__c; //Added by Monika
                }
                if(!String.isBlank(ld.Type__c)){
                    ld.Assigned_to_Central_Desk__c = true;
                }
                if(mapOwnerToCampaign.Size() > 0 && mapOwnerToCampaign.get(c.ownerId) != null){
                    ld.Campaign__c = mapOwnerToCampaign.get(c.ownerId);
                }else{
                    ld.Status__c = 'Non Validate';
                }
                lstLeads.add(ld);
                
                EmailList.add(c.Email);
            }
            insert lstLeads;
            /*  if(!lstLeads.isEmpty()){
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.AllowSave = true;
Database.SaveResult[] results = Database.insert(lstLeads, dml);        
}*/
            /* }catch(Exception e){
System.debug('<<< error message >>>'+e.getMessage());
System.debug('<<< error line number >>>'+e.getLineNumber());
String name = 'Zero Keyboard';
String ClassName = 'ZeroKeyboardApp';
ExceptionHandling.Exception( name, ClassName, e);
} */
            
            list<Lead__c> LeadList = new list<Lead__c>();
            LeadList = [Select Id, name, Email__c from Lead__c Where Email__c IN : EmailList];
            for (contact co : lstContacts){
                
                for (Lead__c ld : LeadList){ 
                    
                    if(ld.Email__c == co.Email){
                        
                        copyFile.CopyFileFromRecord1to2(co.Id, ld.Id);
                    }
                }
            }
        }catch(Exception e){
            String name = 'Zero Keyboard';
            String ClassName = 'triggerContactHelper';
            ExceptionHandling.Exception( name, ClassName, e);
        } 
        
    }
    
    public static void removeAccountContactRelation(List<Contact> newContactList, Map<Id, Contact> oldMap){
        List<String> inActiveContactIdList = new List<String>();
        for(Contact con : newContactList){
            if(con.Is_Active__c == false && oldMap.get(con.Id).Is_Active__c == true){
                inActiveContactIdList.add(con.Id);
            }
        }
        List<AccountContactRelation> acrList = [SELECT Id FROM AccountContactRelation WHERE ContactId IN : inActiveContactIdList AND IsDirect = false];
        try{
            delete acrList;
            List<Contact> updateContactList = new List<Contact>();
            for(Contact con : newContactList){
                if(con.Is_Active__c == false && oldMap.get(con.Id).Is_Active__c == true){
                    Contact cont = new Contact(Id=con.Id, AccountId = null);
                    updateContactList.add(cont);
                }
            }
            update updateContactList;
        } catch(Exception exp){
            System.debug('Contact relation not deleted'+exp.getMessage());
        }
        
    }
    
    //SAC-938 || Deepika 
   //Update BY Sahil Jain SAC-2052 Enhance Contact Inactivation Logic
   /* public static void checkContactRelationship(List<Contact> newContactList) {
        // Collect Contact Ids from Business_Detail__c
        Set<Id> relatedContactIds = new Set<Id>();
        List<Business_Detail__c> businessDetailsList = [
            SELECT Pickup_Contact__c, Submission_Contact__c, Collection_Contact__c, BIR_Contacts__c
            FROM Business_Detail__c
            WHERE Pickup_Contact__c IN :newContactList 
            OR Submission_Contact__c IN :newContactList
            OR Collection_Contact__c IN :newContactList
            OR BIR_Contacts__c IN :newContactList
        ];
        
        for (Business_Detail__c businessDetail : businessDetailsList) {
            if (businessDetail.Pickup_Contact__c != null) relatedContactIds.add(businessDetail.Pickup_Contact__c);
            if (businessDetail.Submission_Contact__c != null) relatedContactIds.add(businessDetail.Submission_Contact__c);
            if (businessDetail.Collection_Contact__c != null) relatedContactIds.add(businessDetail.Collection_Contact__c);
            if (businessDetail.BIR_Contacts__c != null) relatedContactIds.add(businessDetail.BIR_Contacts__c);
        }
        
        // Collect Contact Ids from Contract__c
        List<Contract__c> contractList = [
            SELECT Customer_Signed_by_Customer__c
            FROM Contract__c
            WHERE Customer_Signed_by_Customer__c IN :newContactList
        ];
        for (Contract__c contract : contractList) {
            if (contract.Customer_Signed_by_Customer__c != null) relatedContactIds.add(contract.Customer_Signed_by_Customer__c);
        }
        
        // Collect Contact Ids from Contact_Billing_Line_Item__c
        List<Contact_Billing_Line_Item__c> contactBillingList = [
            SELECT Contact__c
            FROM Contact_Billing_Line_Item__c
            WHERE Contact__c IN :newContactList
        ];
        for (Contact_Billing_Line_Item__c billingItem : contactBillingList) {
            if (billingItem.Contact__c != null) relatedContactIds.add(billingItem.Contact__c);
        }
        
        // Add error to corresponding records in Trigger.new
        for (Contact contact : newContactList) {
            if (relatedContactIds.contains(contact.Id)) {
                // contact.addError('Please unlink the contact from Business Details, Contracts, and Contact Billing Line Items before deactivating.');
            }
        }
    }*/
    
    
}