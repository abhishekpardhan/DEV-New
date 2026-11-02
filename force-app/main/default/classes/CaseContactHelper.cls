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
* 1.3        22-10-2026                Aakash Kumar             Replaced Custom Lead Object with Standard Lead Object (EPIC4_UST11)
* 1.4        30-10-2026                Aakash Kumar             Implementing the New Scenarios: (EPIC4_UST11)
*                                                               Pickup/B2B Support Case created:
                                                                1) Mobile Number Found: No new Contact is created; 
                                                                the existing Contact is linked to the Case.
                                                                2) Mobile Number Not Found: A new Contact and Lead are created, and the Case is linked to the Lead.
                                                                3) Both Mobile Number and Email Found: No new Lead is created.
                                                                4) Mobile Number and Email  Not Available: A new Lead is created.
**/
public class CaseContactHelper {
    
    @InvocableMethod(label='Tag Contact To Case')
    public static void tagContactsToCases(List<Id> caseId) {
        if(caseId == null || caseId.isEmpty()){
            return;
        }
        try{
            Set<Id> uniqueCaseIds = new Set<Id>();
            uniqueCaseIds.addAll(caseId);
            if(uniqueCaseIds.isEmpty()){
                return;
            }
            
            Map<Id, Case> caseMap = new Map<Id, Case>(
                [SELECT Id, Status, SuppliedPhone, SuppliedEmail, Supplied_Pincode__c, ContactId, Requester_Name__c,
                 SuppliedCompany, Requester_Location__c, Case_Type__c, Case_Nature__c FROM Case 
                 WHERE Id IN :uniqueCaseIds]
            );
            
            if (caseMap.isEmpty()){
                return;
            }
            
            /*
            * Collect mobile numbers and email addresses
            * for bulk Contact and Lead lookups.
            */
            Set<String> phoneValues = new Set<String>();
            Set<String> emailValues = new Set<String>();
            
            for (Case currentCase : caseMap.values()){
                if (String.isNotBlank(currentCase.SuppliedPhone)){
                    String normalizedPhone = normalizePhone(currentCase.SuppliedPhone);
                    if (normalizedPhone != null) {
                        phoneValues.add(normalizedPhone);
                    }
                }
                if (String.isNotBlank(currentCase.SuppliedEmail)) {
                    emailValues.add(currentCase.SuppliedEmail.trim());
                }
            }
            
            Map<String, Contact> phoneToContactMap = getContactsByPhone(phoneValues);
            List<Lead> existingLeads = getExistingLeads(phoneValues, emailValues);
            
            /*
            * Track all pending operations.
            * Maps prevent duplicate Case updates and retain
            * the Case-to-Contact relationship for partial DML.
            */
            Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
            List<Contact> contactsToInsert = new List<Contact>();
            List<Id> contactCaseIds = new List<Id>();
            Set<Id> casesRequiringLead = new Set<Id>();
            
            /*
            * STEP 1: Determine which records need to be created.
            */
            for (Case currentCase : caseMap.values()){
                Boolean eligibleForLead = isEligibleForLead(currentCase);
                /*
                * Preserve the existing Contact relationship.
                * B2B Enquiry Cases must still be completed.
                */
                
                if (currentCase.ContactId != null){
                    if (isB2BEnquiry(currentCase)){
                        addCaseUpdate(casesToUpdateMap, currentCase, currentCase.ContactId);
                    }
                    continue;
                }
                String normalizedPhone = normalizePhone(currentCase.SuppliedPhone);
                /*
                * Scenario 1:
                * Mobile matches an existing Contact.
                *
                * Link the existing Contact.
                * Do not create another Contact or Lead.
                */
                
                Contact existingContact = normalizedPhone != null ? phoneToContactMap.get(normalizedPhone) : null;
                if (existingContact != null){
                    addCaseUpdate(casesToUpdateMap, currentCase, existingContact.Id);
                    continue;
                }
                /*
                * Do not create Leads for unrelated Case types.
                */
                if (!eligibleForLead) {
                    continue;
                }
                /*
                * Scenario 5:
                * Neither mobile nor email is available.
                */
                if (String.isBlank(currentCase.SuppliedPhone) && String.isBlank(currentCase.SuppliedEmail)) {
                    continue;
                }
                /*
                * Scenario 3:
                * An existing Lead matches both the supplied
                * mobile number and email address.
                *
                * Do not create a duplicate Contact or Lead
                * for this Case.
                */
                
                if (hasMatchingLead(currentCase, existingLeads)) {
                    continue;
                }
                /*
                * Scenario 2:
                * Mobile is supplied, but no Contact matches.
                *
                * Create a Contact and then create its Lead
                * after the Contact insert succeeds.
                */
                
                if (String.isNotBlank(currentCase.SuppliedPhone)) {
                    Contact newContact = buildContactFromCase(currentCase);
                    contactsToInsert.add(newContact);
                    contactCaseIds.add(currentCase.Id);
                    casesRequiringLead.add(currentCase.Id);
                    continue;
                }
                /*
                * Scenario 4:
                * Mobile is unavailable, but email is supplied.
                *
                * Create a Lead directly without creating
                * a Contact solely for this Case.
                */
                if (String.isNotBlank(currentCase.SuppliedEmail)) {
                    casesRequiringLead.add(currentCase.Id);
                }
            }
            
            /*
            * STEP 2: Insert new Contacts using partial DML.
            */
            Map<Id, Id> caseToContactId = new Map<Id, Id>();
            if (!contactsToInsert.isEmpty()){
                Database.SaveResult[] contactResults = Database.insert(contactsToInsert, false);
                for (Integer i = 0; i < contactResults.size(); i++){
                    Database.SaveResult result = contactResults[i];
                    Id currentCaseId = contactCaseIds[i];
                    if (result.isSuccess()) {
                        Id newContactId = result.getId();
                        caseToContactId.put(currentCaseId, newContactId);
                        Case currentCase = caseMap.get(currentCaseId);
                        addCaseUpdate(casesToUpdateMap, currentCase, newContactId);
                    }else {
                        logDmlErrors('insertContacts', result.getErrors());
                    }
                }
            }
            
            /*
            * STEP 3: Prepare Leads.
            *
            * A Lead requiring a newly created Contact is
            * eligible only when the Contact insert succeeded.
            *
            * Cases without a mobile number can create Leads
            * directly when an email address is available.
            */
            List<Lead> leadsToInsert = new List<Lead>();
            for (Id currentCaseId : casesRequiringLead){
                Case currentCase = caseMap.get(currentCaseId);
                if (currentCase == null){
                    continue;
                }
                Contact relatedContact;
                if (String.isNotBlank(currentCase.SuppliedPhone)){
                    Id newContactId = caseToContactId.get(currentCaseId);
                    
                    //Do not create a Lead if its required Contact could not be inserted.
                    if (newContactId == null) {
                        continue;
                    }
                    relatedContact = new Contact(
                        Id = newContactId, 
                        MobilePhone = currentCase.SuppliedPhone, 
                        Email = currentCase.SuppliedEmail
                    );
                }
                Lead newLead = buildLeadFromCase(currentCase, relatedContact);
                leadsToInsert.add(newLead);
            }
            
            //STEP 4: Insert Leads using partial DML.
            if (!leadsToInsert.isEmpty()){
                Database.DMLOptions dmlOptions = new Database.DMLOptions();
                dmlOptions.OptAllOrNone = false;
                dmlOptions.DuplicateRuleHeader.AllowSave = true;
                Database.SaveResult[] leadResults = Database.insert(leadsToInsert, dmlOptions);
                for (Integer i = 0; i < leadResults.size(); i++){
                    Database.SaveResult result = leadResults[i];
                    if (!result.isSuccess()) {
                        logDmlErrors('insertLeads', result.getErrors());
                    }
                }
            }
            
            /*
            * STEP 5: Update Cases once per Case.
            *
            * This also preserves the existing B2B Enquiry
            * status transition to Completed.
            */
            if (!casesToUpdateMap.isEmpty()){
                Database.SaveResult[] caseResults = Database.update(casesToUpdateMap.values(), false);
                for (Database.SaveResult result : caseResults){
                    if (!result.isSuccess()) {
                        logDmlErrors('updateCases', result.getErrors());
                    }
                }
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
    
    // Method used to creade a new Lead from the Incoming Case
    private static Lead buildLeadFromCase(Case currentCase, Contact relatedContact) {
        String requesterName = String.isNotBlank(currentCase.Requester_Name__c) ? currentCase.Requester_Name__c.trim() : null;
        String firstName;
        String lastName;
        
        if (requesterName != null) {
            Integer firstSpace = requesterName.indexOf(' ');
            if (firstSpace > 0) {
                firstName = requesterName.substring(0, firstSpace);
                lastName = requesterName.substring(firstSpace + 1).trim();
            } else {
                lastName = requesterName;
            }
        }
        
        if (relatedContact != null) {
            if (String.isBlank(firstName)) {
                firstName = relatedContact.FirstName;
            }
            if (String.isBlank(lastName)) {
                lastName = relatedContact.LastName;
            }
        }
        if (String.isBlank(lastName)) {
            lastName = 'Unknown';
        }
        
        String companyName;
        if (String.isNotBlank(currentCase.SuppliedCompany)) {
            companyName = currentCase.SuppliedCompany;
        } else if (String.isNotBlank(requesterName)) {
            companyName = requesterName;
        } else if (relatedContact != null && String.isNotBlank(relatedContact.LastName)) {
            companyName = relatedContact.LastName;
        } else {
            companyName = 'Unknown';
        }
        
        Lead newLead = new Lead(
            FirstName = firstName,
            LastName = lastName,
            Company = companyName,
            Email = String.isNotBlank(currentCase.SuppliedEmail) ? currentCase.SuppliedEmail.trim() : null,
            MobilePhone = String.isNotBlank(currentCase.SuppliedPhone) ? currentCase.SuppliedPhone.trim() : null,
            Phone = relatedContact != null ? relatedContact.MobilePhone : null,
            Street = currentCase.Requester_Location__c,
            PostalCode = currentCase.Supplied_Pincode__c,
            LeadSource = ConstantUtility.LEAD_SOURCE_SAFEXPERIENCE,
            Lead_Type__c = ConstantUtility.LEAD_TYPE_CREDIT_RETAIL,
            Case__c = currentCase.Id,
            Status = ConstantUtility.LEAD_STATUS_ACTIVE,
            Assign_to_Central_Desk__c = true
        );
        if (relatedContact != null) {
            newLead.Salutation = relatedContact.Salutation;
        }
        return newLead;
    }
    
    // Method to fetch contacts by phone numbers and return a map of normalized phone to contact
    private static Map<String,Contact> getContactsByPhone(Set<String> phones){
        Map<String,Contact> result = new Map<String,Contact>();
        if(phones.isEmpty()){
            return result;
        }
        for(Contact con : [SELECT Id, MobilePhone,FirstName,LastName,Phone,Email,Salutation FROM Contact 
                           WHERE MobilePhone IN :phones]){
            String phone = normalizePhone(con.MobilePhone);
            if(phone != null){
                result.put(phone,con);
            }
        }
        return result;
    }
    
    /*
    * Retrieves potential duplicate Leads in a single query.
    *
    * The matching rule is evaluated in memory to ensure that
    * both mobile and email match the same existing Lead.
    */
    private static List<Lead> getExistingLeads(Set<String> phoneValues, Set<String> emailValues) {
        List<Lead> existingLeads = new List<Lead>();
        if ((phoneValues == null || phoneValues.isEmpty()) && (emailValues == null || emailValues.isEmpty())) {
            return existingLeads;
        }
        if (phoneValues == null || phoneValues.isEmpty()) {
            existingLeads = [SELECT Id, MobilePhone, Email FROM Lead WHERE Email IN :emailValues];
        } else if (emailValues == null || emailValues.isEmpty()) {
            existingLeads = [SELECT Id, MobilePhone, Email FROM Lead WHERE MobilePhone IN :phoneValues];
        } else {
            existingLeads = [SELECT Id, MobilePhone, Email FROM Lead WHERE MobilePhone IN :phoneValues OR Email IN :emailValues];
        }
        return existingLeads;
    }
    
    /*
    * Returns true only when an existing Lead matches
    * both the supplied mobile number and email address.
    */
    private static Boolean hasMatchingLead(Case currentCase, List<Lead> existingLeads) {
        String casePhone = normalizePhone(currentCase.SuppliedPhone);
        String caseEmail = normalizeEmail(currentCase.SuppliedEmail);
        if (casePhone == null || caseEmail == null) {
            return false;
        }
        for (Lead existingLead : existingLeads) {
            String leadPhone = normalizePhone(existingLead.MobilePhone);
            String leadEmail = normalizeEmail(existingLead.Email);
            if (casePhone == leadPhone &&
                caseEmail == leadEmail) {
                    return true;
                }
        }
        return false;
    }
    
    /*
    * Adds a Case update to a map to prevent duplicate
    * Case records from being included in the same DML.
    */
    private static void addCaseUpdate(Map<Id, Case> casesToUpdateMap, Case currentCase, Id contactId) {
        Case caseUpdate = new Case(Id = currentCase.Id);
        if (contactId != null) {
            caseUpdate.ContactId = contactId;
        }
        if (isB2BEnquiry(currentCase)) {
            caseUpdate.Status = ConstantUtility.COMPLETED;
        }
        casesToUpdateMap.put(currentCase.Id, caseUpdate);
    }
    
    /*
    * Determines whether a Case is eligible for Lead creation.
    */
    private static Boolean isEligibleForLead(Case currentCase) {
        return isB2BEnquiry(currentCase) || isBookingRequest(currentCase);
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
    
    // Method to Check if Case is Booking Request Enquiry or Not
    private static Boolean isBookingRequest(Case c){
        return c.Case_Type__c == ConstantUtility.CASE_TYPE_BUSINESS_REQUEST &&
            c.Case_Nature__c == ConstantUtility.CASE_NATURE_REQUEST;
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
    
    /*
    * Normalizes email addresses for comparison.
    */
    private static String normalizeEmail(String email) {
        return String.isBlank(email) ? null : email.trim().toLowerCase();
    }
    
    /*
    * Logs individual DML errors without aborting
    * successful records in the same operation.
    */
    private static void logDmlErrors(String operationName, Database.Error[] errors) {
        for (Database.Error dmlError : errors) {
            LoggerUtil.createErrorLog(
                'CaseContactHelper',
                operationName,
                String.valueOf(dmlError.getStatusCode()),
                'Fields: ' + String.valueOf(dmlError.getFields()) +
                '; Message: ' + dmlError.getMessage(),
                null,
                null
            );
        }
    }
}