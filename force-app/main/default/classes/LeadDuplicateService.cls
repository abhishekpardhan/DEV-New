/**
* @File Name          : LeadDuplicateService.cls
* @Description        : In this class checkPAN method checks the Duplicate PAN on Lead on Account.(EPIC4_UST6)
* @Author             : Aakash Kumar
* @Group              : 
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        26-10-2026                Aakash Kumar                   Initial Version
**/
public without sharing class LeadDuplicateService {
    /**
* Checks eligible Leads for duplicate PAN values against existing Leads
* and qualifying Accounts. Duplicate records are rejected using addError().
*
* Validation is skipped when the running user has the configured
* duplicate-exemption permission.
*
* @param newLeads Leads being inserted or updated.
* @param oldMap   Previous versions of Leads during updates; null on insert.
*/
    public static void checkPan(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        // Allow explicitly exempted users to bypass PAN duplicate validation.
        if (FeatureManagement.checkPermission(ConstantUtility.LEAD_DUPLICATE_EXEMPTION)) {
            return;
        }
        // Defensive check: exit when there are no records to process.
        if (newLeads == null || newLeads.isEmpty()) {
            return;
        }
        try{
            List<Lead> eligibleLeads = new List<Lead>();
            Set<String> pans = new Set<String>();
            Set<Id> currentIds = new Set<Id>();
            for (Lead currentLead : newLeads) {
                if (currentLead == null) {
                    continue;
                }
                // Collect existing record IDs for update processing.
                // Newly inserted Leads do not have IDs at this stage.
                if (currentLead.Id != null) {
                    currentIds.add(currentLead.Id);
                }
                // PAN duplicate validation is not applicable when PAN is blank.
                // Any mandatory PAN requirement should be handled separately.
                if (String.isBlank(currentLead.PAN_Number__c)) {
                    continue;
                }
                
                // On insert, oldMap is null and every populated PAN is eligible.
                // On update, only records whose PAN value has changed are eligible.
                Boolean shouldCheck = oldMap == null;
                if (oldMap != null && currentLead.Id != null) {
                    Lead oldLead = oldMap.get(currentLead.Id);
                    shouldCheck = oldLead != null && currentLead.PAN_Number__c != oldLead.PAN_Number__c;
                }
                if (!shouldCheck) {
                    continue;
                }
                
                eligibleLeads.add(currentLead);
                
                // Normalize the PAN before using it as a lookup key.
                pans.add(String.isBlank(currentLead.PAN_Number__c) ? null : currentLead.PAN_Number__c.trim().toUpperCase());
            }
            if (eligibleLeads.isEmpty() || pans.isEmpty()) {
                return;
            }
            
            // Keeps the first eligible Lead encountered for each normalized PAN.
            // Subsequent eligible Leads with the same PAN receive an error.
            Map<String, Lead> firstLeadByPan = new Map<String, Lead>();
            
            for (Lead currentLead : eligibleLeads) {
                String normalizedPan = String.isBlank(currentLead.PAN_Number__c) ? null : currentLead.PAN_Number__c.trim().toUpperCase();
                
                if (firstLeadByPan.containsKey(normalizedPan)) {
                    // Reject the subsequent Lead because another eligible Lead in this transaction already has the same normalized PAN.
                    // The first Lead is retained in the map for further comparisons.
                    currentLead.addError(ConstantUtility.DUPLICATE_PAN_ERROR_MESSAGE_PREFIX + 'another Lead in this save, owner ' + 'cannot be resolved before insert.');
                } else {
                    // Register the first eligible Lead encountered for this PAN.
                    firstLeadByPan.put(normalizedPan, currentLead);
                }
            }
            
            // Groups existing Leads by normalized PAN so matching records can be retrieved efficiently without querying inside a processing loop.
            Map<String, List<Lead>> existingLeadsByPan = new Map<String, List<Lead>>();
            
            // Query Leads matching the PAN values collected earlier.
            // Current transaction records are excluded to prevent them from being treated as independent existing database duplicates.
            for (Lead existingLead : [SELECT Id, Owner.Name,Company, PAN_Number__c,GST_Number__c,FirstName, LastName FROM Lead 
                                      WHERE PAN_Number__c IN :pans AND Id NOT IN :currentIds]) {
                                          String normalizedPan = String.isBlank(existingLead.PAN_Number__c) ? null : existingLead.PAN_Number__c.trim().toUpperCase();
                                          if (!existingLeadsByPan.containsKey(normalizedPan)) {
                                              existingLeadsByPan.put(normalizedPan, new List<Lead>());
                                          }
                                          existingLeadsByPan.get(normalizedPan).add(existingLead);
                                      }
            Map<String, List<Account>> existingAccountsByPan = new Map<String, List<Account>>();
            for (Account existingAccount : [ SELECT Id, AccountNumber, Name, Owner.Name, Pan_No__c, 
                                            RecordType.DeveloperName FROM Account WHERE Pan_No__c IN :pans 
                                            AND RecordType.DeveloperName IN (:ConstantUtility.PROSPECT_CUSTOMER_RT,:ConstantUtility.SFX_CUSTOMER_RT)] ) {
                                                String normalizedPan = String.isBlank(existingAccount.Pan_No__c) ? null : existingAccount.Pan_No__c.trim().toUpperCase();
                                                if (!existingAccountsByPan.containsKey(normalizedPan)) {
                                                    existingAccountsByPan.put(normalizedPan, new List<Account>());
                                                }
                                                existingAccountsByPan.get(normalizedPan).add(existingAccount);
                                            }
            for (Lead currentLead : eligibleLeads) {
                String normalizedPan = String.isBlank(currentLead.PAN_Number__c) ? null : currentLead.PAN_Number__c.trim().toUpperCase();
                List<Lead> matchingLeads = existingLeadsByPan.get(normalizedPan);
                if (matchingLeads != null && !matchingLeads.isEmpty()) {
                    Lead duplicateLead = matchingLeads[0];
                    String leadName = String.isNotBlank(duplicateLead.FirstName)  ? duplicateLead.FirstName + ' ' + duplicateLead.LastName : duplicateLead.LastName;
                    currentLead.addError(ConstantUtility.DUPLICATE_PAN_ERROR_MESSAGE_PREFIX + leadName +', Owner '  + duplicateLead.Owner.Name + '.');
                    continue;
                }
                List<Account> matchingAccounts = existingAccountsByPan.get(normalizedPan);
                
                if (matchingAccounts != null && !matchingAccounts.isEmpty()) {
                    Account duplicateAccount = matchingAccounts[0];
                    String accountNumber = String.isNotBlank(duplicateAccount.AccountNumber)  ? duplicateAccount.AccountNumber : duplicateAccount.Name;
                    currentLead.addError(ConstantUtility.DUPLICATE_PAN_ERROR_MESSAGE_PREFIX + accountNumber + ', owner ' + duplicateAccount.Owner.Name + '.');
                }
            }
        }catch(exception ex){
            LoggerUtil.createErrorLog(
                'LeadDuplicateService',
                'checkPan',
                ex.getTypeName(),
                ex.getMessage(),
                ex.getStackTraceString(),
                String.valueOf(ex.getLineNumber())
            );
        }
    }
}