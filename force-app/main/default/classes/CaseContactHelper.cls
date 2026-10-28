/**
* @File Name          : CaseContactHelper.cls
* @Description        : In this class Updating support case created from web form and tag with contact(SAC-1640)
* @Author             : Manshi Joshi
* @Group              : IBM
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        15-07-2025                Manshi                   Initial Version
* 1.1        11-02-2026                Rudra Singh              As per latest on contact we use MobilePhone Field instead of phone
* 1.2        12-03-2026                Abhishek Pardhan         Added logic to create lead for B2B enquiry cases and also update case status to completed if Case is a B2B enquiry (SAC-1480)
* 1.3        22-10-2026                Aakash Kumar             Replaced Custom Lead Object with Standard Lead Objec
**/
public class CaseContactHelper {
    
    @InvocableMethod(label='Tag Contact To Case')
    public static void tagContactsToCases(List<Id> caseId) {
        
        if(caseId == null || caseId.isEmpty()){
            return;
        }
        
        try{
            Map<Id,Case> caseMap = new Map<Id,Case>(
                [SELECT Id, Status, SuppliedPhone, SuppliedEmail,Supplied_Pincode__c, ContactId, Requester_Name__c,
                 SuppliedCompany,Requester_Location__c, Case_Type__c, Case_Nature__c, Origin, Sub_Type__c FROM Case 
                 WHERE Id IN :caseId]
            );
            Set<String> phoneNumbers = new Set<String>();
            for(Case c : caseMap.values()){
                String phone = normalizePhone(c.SuppliedPhone);
                if(phone != null){
                    phoneNumbers.add(phone);
                }
            }
            
            Map<String,Contact> phoneToContactMap = getContactsByPhone(phoneNumbers);
            
            List<Contact> contactsToInsert = new List<Contact>();
            Map<Id,Contact> caseToNewContact = new Map<Id,Contact>();
            List<Case> casesToUpdate = new List<Case>();
            Set<Id> contactIdsForLead = new Set<Id>();
            
            for(Case c : caseMap.values()){
                String phone = normalizePhone(c.SuppliedPhone);
                if(c.ContactId == null){
                    Contact existingContact = phoneToContactMap.get(phone);
                    if(existingContact != null){
                        casesToUpdate.add(buildCaseUpdate(c, existingContact.Id));
                        if(isB2BEnquiry(c)){
                            contactIdsForLead.add(existingContact.Id);
                        }
                        caseMap.get(c.Id).ContactId = existingContact.Id;
                    }else{
                        Contact newContact = buildContactFromCase(c);
                        contactsToInsert.add(newContact);
                        caseToNewContact.put(c.Id,newContact);
                    }
                }else{
                    if(isB2BEnquiry(c)){
                        contactIdsForLead.add(c.ContactId);
                        casesToUpdate.add(new Case(
                            Id = c.Id,
                            Status = ConstantUtility.COMPLETED
                        ));
                    }
                }
            }
            
            if(!contactsToInsert.isEmpty()){
                insert contactsToInsert;
                
                for(Id cId : caseToNewContact.keySet()){
                    Contact con = caseToNewContact.get(cId);
                    Case c = caseMap.get(cId);
                    if(con.Id != null){
                        casesToUpdate.add(buildCaseUpdate(c, con.Id));
                        if(isB2BEnquiry(c)){
                            contactIdsForLead.add(con.Id);
                        }
                        caseMap.get(cId).ContactId = con.Id;
                    }
                }
            }
            
            if(!casesToUpdate.isEmpty()){
                update casesToUpdate;
            }
            if(!contactIdsForLead.isEmpty()){
                createLeadFromContact(contactIdsForLead, caseMap);
            }
            
        }catch(Exception e){
            LoggerUtil.createErrorLog(
                'CaseContactHelper',
                'tagContactsToCases',
                e.getTypeName(),
                e.getMessage(),
                e.getStackTraceString(),
                null
            );
        }
    }
    
    // Method to create lead from contact for B2B enquiry cases
    public static void createLeadFromContact(Set<Id> contactIds, Map<Id,Case> caseMap){
        List<String> errorMessages = new List<String>();
        List<Lead> leadsToInsert = new List<Lead>();
        Map<Id,Contact> contactMap = new Map<Id,Contact>(
            [SELECT Id, Salutation, Name, Email, MobilePhone, Phone,FirstName,LastName
             FROM Contact
             WHERE Id IN :contactIds]
        );
        for(Case c : caseMap.values()){
            if(c.ContactId == null || !contactMap.containsKey(c.ContactId)){
                continue;
            }
                Contact con = contactMap.get(c.ContactId);
                String requesterName = c.Requester_Name__c != null ? c.Requester_Name__c.trim() : null;
                Integer firstSpace = requesterName != null ? requesterName.indexOf(' ') : -1;
                Lead lead = new Lead(
                    FirstName = requesterName != null && firstSpace > 0 ? requesterName.substring(0, firstSpace) : (requesterName == null ? con.FirstName : null),
                    LastName = requesterName != null ? (firstSpace > 0 ? requesterName.substring(firstSpace + 1).trim() : requesterName) : con.LastName,
                    Company = c.SuppliedCompany != null ? c.SuppliedCompany : c.Requester_Name__c,
                    Salutation = con.Salutation,
                    Email = c.SuppliedEmail != null ? c.SuppliedEmail : con.Email,
                    MobilePhone = con.MobilePhone,
                    Phone = con.Phone,
                    Street = c.Requester_Location__c,
                    PostalCode = c.Supplied_Pincode__c,
                    LeadSource = ConstantUtility.LEAD_SOURCE_SAFEXPERIENCE,
                    Lead_Type__c = ConstantUtility.LEAD_TYPE_CREDIT_RETAIL,
                    Case__c = c.Id,
                    Status = ConstantUtility.LEAD_STATUS_ACTIVE	,
                    Assign_to_Central_Desk__c = true
                );
                leadsToInsert.add(lead);
        }
        if(!leadsToInsert.isEmpty()){
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.SaveResult[] results = Database.insert(leadsToInsert, dml);
            for(Database.SaveResult result : results) {
                if(result.isSuccess()) {
                    System.debug('Successfully inserted Accounts : ' + result.getId());
                } else {
                    // iterate over the failed ones
                    for(Database.Error error : result.getErrors()) {
                        system.debug(error.getMessage());
                        ExceptionHandling.Exception( 'createLeadFromContact', 'CaseContactHelper', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                    }
                }
            }
        }
    }
    
    // Method to fetch contacts by phone numbers and return a map of normalized phone to contact
    private static Map<String,Contact> getContactsByPhone(Set<String> phones){
        Map<String,Contact> result = new Map<String,Contact>();
        if(phones.isEmpty()){
            return result;
        }
        for(Contact con : [
            SELECT Id, MobilePhone,FirstName,LastName,Phone,Email,Salutation
            FROM Contact
            WHERE MobilePhone IN :phones
        ]){
            String phone = normalizePhone(con.MobilePhone);
            if(phone != null){
                result.put(phone,con);
            }
        }
        return result;
    }
    
    // Method to build contact record from case details
    private static Contact buildContactFromCase(Case c){
        return new Contact(
            LastName = String.isBlank(c.Requester_Name__c) ? 'Unknown' : c.Requester_Name__c,
            Email = c.SuppliedEmail,
            Phone = c.SuppliedPhone,
            MobilePhone = c.SuppliedPhone,
            Is_Active__c = true
        );
    }
    
    // Method to Prepare the Case Record for Update
    private static Case buildCaseUpdate(Case c, Id contactId){
        return new Case(
            Id = c.Id,
            ContactId = contactId,
            Status = isB2BEnquiry(c) ? ConstantUtility.COMPLETED : c.Status
        );
    }
    // Method to Check if Case if B2B Enquiry or Not
    private static Boolean isB2BEnquiry(Case c){
        return c.Case_Type__c == ConstantUtility.CASE_TYPE_B2B && 
            c.Case_Nature__c == ConstantUtility.CASE_NATURE_ENQUIRY;
    }
    
    // Method to normalize phone number by removing non-numeric characters and keeping last 10 digits if length exceeds 10
    private static String normalizePhone(String phone){
        if(String.isBlank(phone)){
            return null;
        }
        phone = phone.replaceAll('[^0-9]', '');
        if(phone.length() > 10){
            phone = phone.substring(phone.length() - 10);
        }
        
        return phone;
    }  
}