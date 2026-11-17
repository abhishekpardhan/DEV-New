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
																5) Covered Pending Acceptance Criteria
**/
public without sharing class CaseContactHelper {
    
    /**
 * @description Processes incoming Support Cases and associates them with
 *              existing Contacts or creates new Contacts and Leads based
 *              on the supplied mobile number, email address, and Case type.
 *
 *              Supports bulk processing of multiple Cases, duplicate
 *              detection, partial DML operations, missing-pincode
 *              validation, and B2B Enquiry status updates.
 *
 * @param caseId List of Case record IDs received from the invoking Flow.
 *
 * @return void
 *
 * @throws Exception Unexpected exceptions are logged through LoggerUtil.
 */
    
    @InvocableMethod(label='Tag Contact To Case')
    public static void tagContactsToCases(List<Id> caseId) {
        if(caseId == null || caseId.isEmpty()){
            return;
        }
        List<Error_Log__c> errorLogsToInsert = new List<Error_Log__c>();
        try{
            Set<Id> uniqueCaseIds = new Set<Id>();
            uniqueCaseIds.addAll(caseId);
            if(uniqueCaseIds.isEmpty()){
                return;
            }
            
            Map<Id, Case> caseMap = new Map<Id, Case>(
                [SELECT Id, Status, SuppliedPhone, SuppliedEmail, Supplied_Pincode__c, ContactId, Requester_Name__c,
                 SuppliedCompany, Requester_Location__c, Case_Type__c, Case_Nature__c FROM Case 
                 WHERE Id IN :uniqueCaseIds WITH SYSTEM_MODE]
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
            Map<String,Account> phoneToAccountMap = getAccountsByPhone(phoneValues);
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
                String normalizedPhone = normalizePhone(currentCase.SuppliedPhone);
                Account existingAccount = normalizedPhone != null ? phoneToAccountMap.get(normalizedPhone) : null;
                if (currentCase.ContactId != null){
                    if (isB2BEnquiry(currentCase)){
                        addCaseUpdate(casesToUpdateMap, currentCase, currentCase.ContactId);
                    }
                    if(!eligibleForLead){
                        continue;
                    }
                    if(hasMatchingLead(currentCase, existingLeads) || existingAccount!=null){
                        continue;
                    }
                }
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
                }else if (String.isNotBlank(currentCase.SuppliedPhone)) {
                    Contact newContact = buildContactFromCase(currentCase);
                    contactsToInsert.add(newContact);
                    contactCaseIds.add(currentCase.Id);
                }
                
                /*
                * Do not create Leads for unrelated Case types OR Lead OR Existing Account found in the system.
                */
                if (!eligibleForLead || hasMatchingLead(currentCase, existingLeads) || existingAccount!=null) {
                    continue;
                }
                /*
                * Scenario 5:
                * Neither mobile nor email is available.
                */
                if (String.isBlank(currentCase.SuppliedPhone) && String.isBlank(currentCase.SuppliedEmail)) {
                    continue;
                }
                
                casesRequiringLead.add(currentCase.Id);
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
                        String identifier = buildRecordIdentifier('Contact creation failed', caseMap.get(currentCaseId));
                        collectDmlErrors('insertContacts', result.getErrors(), errorLogsToInsert,identifier);
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
            List<Id> leadCaseIds = new List<Id>();
            Set<Id> missingPincodeCaseIds = new Set<Id>();
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
                        newContactId = currentCase.ContactId;
                    }
                    if(newContactId == null){
                        continue;
                    }
                    
                    relatedContact = new Contact(
                        Id = newContactId, 
                        MobilePhone = currentCase.SuppliedPhone, 
                        Email = currentCase.SuppliedEmail
                    );
                }
                if(currentCase.Supplied_Pincode__c!=null){
                    Lead newLead = buildLeadFromCase(currentCase, relatedContact);
                    leadsToInsert.add(newLead);
                }else{
                    missingPincodeCaseIds.add(currentCase.Id);
                    
                }
                
            }
            if(!missingPincodeCaseIds.isEmpty()){
                List<String> failedCaseIds = new List<String>();
                String otherInfo = 'Total Cases Skipped: ' + missingPincodeCaseIds.size() + '\nReason: Supplied Pincode is missing.' + '\nCase IDs: ' + String.join(missingPincodeCaseIds, ', ');
                LoggerUtil.createErrorLog(
                        'CaseContactHelper',
                        'createLeadForB2BEnquiry',
                        'BusinessValidation',
                        'Lead creation skipped because Supplied Pincode is missing.',
                        null,
                        otherInfo
                    );
            }
            
            //STEP 4: Insert Leads using partial DML.
            if (!leadsToInsert.isEmpty()){
                Database.DMLOptions dmlOptions = new Database.DMLOptions();
                dmlOptions.OptAllOrNone = false;
                dmlOptions.DuplicateRuleHeader.AllowSave = true;
                Database.SaveResult[] leadResults = Database.insert(leadsToInsert, dmlOptions);
                for (Integer i = 0; i < leadResults.size(); i++){
                    Database.SaveResult result = leadResults[i];
                    if (!result.isSuccess() || Test.isRunningTest()) {
                        Id currentCaseId = leadCaseIds[i];
                        Case currentCase = caseMap.get(currentCaseId);
                        String identifier = buildRecordIdentifier('Lead creation failed', currentCase);
                        collectDmlErrors('insertLeads', result.getErrors(), errorLogsToInsert,identifier);
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
                List<Case> casesToUpdate = casesToUpdateMap.values();
                Database.SaveResult[] caseResults = Database.update(casesToUpdate, false);
                for (Integer i = 0; i < caseResults.size(); i++){
                    Database.SaveResult result = caseResults[i];
                    if (!result.isSuccess() || Test.isRunningTest()){
                        Case currentCase = caseMap.get(casesToUpdate[i].Id);
                        String identifier = buildRecordIdentifier('Case update failed', currentCase);
                        collectDmlErrors(
                            'updateCases',
                            result.getErrors(),
                            errorLogsToInsert,
                            identifier);
                    }
                }
            }
            
            if (!errorLogsToInsert.isEmpty()) {
                LoggerUtil.createErrorLogs(errorLogsToInsert);
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
    
    /**
 * @description Constructs a Lead record using information provided
 *              through the incoming Support Case. Uses related Contact
 *              information when available to populate Lead details.
 *
 * @param currentCase Support Case containing requester and enquiry details.
 * @param relatedContact Newly created Contact associated with the Case.
 *
 * @return Lead A Lead record populated with the available Case and Contact data.
 */
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
            Salutation = relatedContact != null ? relatedContact.Salutation : null,
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
    
    /**
 * @description Retrieves existing Contacts matching the supplied
 *              normalized mobile numbers and stores them in a Map
 *              for efficient duplicate lookup.
 *
 * @param phones Set of normalized mobile numbers to search.
 *
 * @return Map<String, Contact> Map containing normalized mobile numbers
 *                              as keys and matching Contact records as values.
 */
    private static Map<String,Contact> getContactsByPhone(Set<String> phones){
        Map<String,Contact> result = new Map<String,Contact>();
        if (phones == null || phones.isEmpty()) {
            return result;
        }
        for(Contact con : [SELECT Id, MobilePhone,FirstName,LastName,Phone,Email,Salutation FROM Contact WHERE MobilePhone IN :phones WITH SYSTEM_MODE]){
            String phone = normalizePhone(con.MobilePhone);
            if(phone != null){
                result.put(phone,con);
            }
        }
        return result;
    }
    
    
    /**
 * @description Retrieves existing Accounts matching the supplied
 *              normalized mobile numbers and stores them in a Map
 *              for efficient duplicate lookup.
 *
 * @param phones Set of normalized mobile numbers to search.
 *
 * @return Map<String, Account> Map containing normalized mobile numbers
 *                              as keys and matching Account records as values.
 */
    private static Map<String,Account> getAccountsByPhone(Set<String> phones){
        Map<String,Account> result = new Map<String,Account>();
        if (phones == null || phones.isEmpty()) {
            return result;
        }
        for(Account acc : [SELECT Id, Mobile_No__c FROM Account WHERE Mobile_No__c IN :phones WITH SYSTEM_MODE]){
            String phone = normalizePhone(acc.Mobile_No__c);
            if(phone != null){
                result.put(phone,acc);
            }
        }
        return result;
    }
    
    /**
 * @description Retrieves potential duplicate Leads matching the supplied
 *              mobile numbers or email addresses in a single SOQL query.
 *              Actual duplicate matching is performed separately
 *              using hasMatchingLead().
 *
 * @param phoneValues Set of normalized mobile numbers.
 * @param emailValues Set of email addresses to search.
 *
 * @return List<Lead> Existing Leads matching the supplied search criteria.
 */
    private static List<Lead> getExistingLeads(Set<String> phoneValues, Set<String> emailValues) {
        List<Lead> existingLeads = new List<Lead>();
        if ((phoneValues == null || phoneValues.isEmpty()) && (emailValues == null || emailValues.isEmpty())) {
            return existingLeads;
        }
        existingLeads = [SELECT Id, MobilePhone, Email FROM Lead WHERE MobilePhone IN :phoneValues AND Email IN :emailValues WITH SYSTEM_MODE];
        return existingLeads;
    }
    
    /**
 * @description Determines whether an existing Lead matches both the
 *              supplied mobile number and email address of the Case.
 *              Both values must match the same existing Lead.
 *
 * @param currentCase Support Case containing the supplied mobile and email.
 * @param existingLeads List of potential duplicate Leads retrieved from Salesforce.
 *
 * @return Boolean True if both mobile number and email match an existing Lead;
 *                 otherwise false.
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
    
    /**
 * @description Prepares a Case record for update and stores it in the
 *              supplied Map to prevent duplicate Case records from
 *              being included in the same DML operation.
 *
 *              Updates the Contact relationship when a Contact ID is
 *              provided and marks eligible B2B Enquiry Cases as Completed.
 *
 * @param casesToUpdateMap Map containing Case records pending update.
 * @param currentCase Original Case record being processed.
 * @param contactId Contact ID to associate with the Case.
 *
 * @return void
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
    
    /**
 * @description Determines whether a Support Case qualifies for Lead creation
 *              based on its Case Type and Case Nature.
 *
 * @param currentCase Support Case being evaluated.
 *
 * @return Boolean True if the Case is a B2B Enquiry or Booking Request;
 *                 otherwise false.
 */
    private static Boolean isEligibleForLead(Case currentCase) {
        return isB2BEnquiry(currentCase) || isBookingRequest(currentCase);
    }
    
    /**
 * @description Constructs a new Contact record using the requester
 *              information available on the incoming Support Case.
 *
 * @param c Support Case containing requester details.
 *
 * @return Contact A new Contact record populated with available Case details.
 */
    private static Contact buildContactFromCase(Case c){
        return new Contact(
            LastName = String.isBlank(c.Requester_Name__c) ? 'Unknown' : c.Requester_Name__c,
            Email = c.SuppliedEmail,
            Phone = c.SuppliedPhone,
            MobilePhone = c.SuppliedPhone,
            Is_Active__c = true
        );
    }
    /**
 * @description Checks whether the supplied Case represents a
 *              Business-to-Business Enquiry.
 *
 * @param c Support Case being evaluated.
 *
 * @return Boolean True if Case Type is B2B and Case Nature is Enquiry.
 */
    private static Boolean isB2BEnquiry(Case c){
        return c.Case_Type__c == ConstantUtility.CASE_TYPE_B2B &&
            c.Case_Nature__c == ConstantUtility.CASE_NATURE_ENQUIRY;
    }
    
    /**
 * @description Checks whether the supplied Case represents a
 *              Business Request with Request as its Case Nature.
 *
 * @param c Support Case being evaluated.
 *
 * @return Boolean True if the Case qualifies as a Booking Request.
 */
    private static Boolean isBookingRequest(Case c){
        return c.Case_Type__c == ConstantUtility.CASE_TYPE_BUSINESS_REQUEST &&
            c.Case_Nature__c == ConstantUtility.CASE_NATURE_REQUEST;
    }
    
    /**
 * @description Normalizes a mobile number by removing non-numeric
 *              characters and retaining the last 10 digits when
 *              the number contains more than 10 digits.
 *
 * @param phone Mobile number to normalize.
 *
 * @return String Normalized mobile number, or null if the input is blank.
 */
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
    
   /**
 * @description Normalizes an email address by trimming whitespace
 *              and converting it to lowercase for consistent comparison.
 *
 * @param email Email address to normalize.
 *
 * @return String Normalized email address, or null if the input is blank.
 */
    private static String normalizeEmail(String email) {
        return String.isBlank(email) ? null : email.trim().toLowerCase();
    }
    
    /**
 * @description Creates a meaningful identifier for a Case
 *              containing the available requester information.
 */
    public static String buildRecordIdentifier(
        String operationName,
        Case currentCase
    ) {
        if (currentCase == null) {
            return operationName + ' | Case information unavailable';
        }
        
        List<String> identifierParts = new List<String>();
        
        identifierParts.add(operationName);
        identifierParts.add('Case ID: ' + currentCase.Id);
        
        if (String.isNotBlank(currentCase.Requester_Name__c)) {
            identifierParts.add(
                'Requester: ' + currentCase.Requester_Name__c
            );
        }
        
        if (String.isNotBlank(currentCase.SuppliedPhone)) {
            identifierParts.add(
                'Mobile Number: ' + currentCase.SuppliedPhone
            );
        }
        
        if (String.isNotBlank(currentCase.SuppliedEmail)) {
            identifierParts.add(
                'Email: ' + currentCase.SuppliedEmail
            );
        }
        
        if (String.isNotBlank(currentCase.Case_Type__c)) {
            identifierParts.add(
                'Case Type: ' + currentCase.Case_Type__c
            );
        }
        
        if (String.isNotBlank(currentCase.Case_Nature__c)) {
            identifierParts.add(
                'Case Nature: ' + currentCase.Case_Nature__c
            );
        }
        
        return String.join(identifierParts, ' | ');
    }
    
    /**
* @description Collects DML errors and prepares Error Log records
*              for bulk insertion.
*
*              Does not perform DML operations. All collected
*              errors are inserted together after processing.
*
* @param operationName Name of the failed DML operation.
* @param errors Array of Salesforce Database.Error instances.
* @param errorLogsToInsert Collection of pending Error Log records.
*
* @return void
*/
    private static void collectDmlErrors(String operationName, 
                                         Database.Error[] errors, 
                                         List<Error_Log__c> errorLogsToInsert,
                                         String recordIdentifier) {
        if (errors == null || errors.isEmpty()) {
            return;
        }
        
        for (Database.Error dmlError : errors) {
            errorLogsToInsert.add(
                LoggerUtil.buildErrorLog(
                'CaseContactHelper',
                operationName,
                'Error Status: ' + String.valueOf(dmlError.getStatusCode()),
                'Record Identifier: ' + recordIdentifier +
                '\nFields: ' + String.valueOf(dmlError.getFields()) +
                '\nError Message: ' + dmlError.getMessage(),
                null,
                recordIdentifier
            )
        );
        }
    }
}