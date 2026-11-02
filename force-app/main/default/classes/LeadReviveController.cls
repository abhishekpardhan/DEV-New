/**
* @File Name          : LeadReviveController.cls
* @Description        : In this class Revives eligible Leads from a Screen Flow.(EPIC4_UST5)
* @Author             : Aakash Kumar
* @Group              : 
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        23-10-2026                Aakash Kumar              Initial Version
* 1.1        28-10-2026                Aakash Kumar              Improved null checks,
*                                                               permission validation,
*                                                               approval error handling
*                                                               and documentation
**/
public class LeadReviveController {
    /**
* Revives eligible Leads supplied by a Screen Flow.
*
* A Lead is eligible when:
* 1. Its status is Dropped and its approval status is Approved; or
* 2. Its status is Dropped By Central Desk.
*
* The method checks the Lead Revive Custom Permission before processing
* records. Approval locks are handled before updates, and partial DML
* results are returned individually.
*
* The output preserves the input order and contains one message per input
* ID, including duplicate IDs.
*
* @param leadIds List of Lead IDs supplied by Flow.
* @return List of success or error messages in input order.
*/
    @InvocableMethod(label='Revive Lead')
    public static List<String> reviveLeads(List<Id> leadIds) {
        List<String> outputMessages = new List<String>();
        try{
            
            if (leadIds == null || leadIds.isEmpty()) {
                return outputMessages;
            }
            for (Integer i = 0; i < leadIds.size(); i++) {
                outputMessages.add(null);
            }
            // Enforce the Custom Permission before processing any records.
            if (!FeatureManagement.checkPermission(ConstantUtility.LEAD_REVIVE)) {
                for (Integer i = 0; i < leadIds.size(); i++) {
                    outputMessages[i] = ConstantUtility.PERMISSION_ERROR;
                }
                return outputMessages;
            }
            Set<Id> uniqueLeadIds = new Set<Id>();
            
            // Validate IDs and remove duplicates for database operations.
            for (Integer i = 0; i < leadIds.size(); i++) {
                Id leadId = leadIds[i];
                if (leadId == null || leadId.getSObjectType() != Lead.SObjectType) {
                    outputMessages[i] = ConstantUtility.INVALID_ID_ERROR;
                    continue;
                }
                uniqueLeadIds.add(leadId);
            }
            
            if (uniqueLeadIds.isEmpty()) {
                return outputMessages;
            }
            Map<Id, Lead> leadById = new Map<Id, Lead>([
                SELECT Id, Status, Approval_Status__c FROM Lead WHERE Id IN :uniqueLeadIds WITH USER_MODE
            ]);
            
            Map<Id, String> resultById = new Map<Id, String>();
            Map<Id, Lead> eligibleLeadsById = new Map<Id, Lead>();
            
            // Check existence and revival eligibility.
            for (Id leadId : uniqueLeadIds) {
                Lead currentLead = leadById.get(leadId);
                if (currentLead == null) {
                    resultById.put(leadId, ConstantUtility.NOT_FOUND_ERROR);
                    continue;
                }
                
                Boolean isApprovedDropped = currentLead.Status == ConstantUtility.Dropped && currentLead.Approval_Status__c == ConstantUtility.Approved;
                Boolean isCentralDeskDropped = currentLead.Status == ConstantUtility.Dropped_By_Central_Desk;
                
                if (!isApprovedDropped && !isCentralDeskDropped) {
                    resultById.put(leadId, ConstantUtility.INELIGIBLE_ERROR);
                    continue;
                }
                eligibleLeadsById.put(leadId, currentLead);
            }
            if (eligibleLeadsById.isEmpty()) {
                return buildOutputMessages(leadIds, resultById, outputMessages);
            }
            
            List<Id> lockedLeadIds = new List<Id>();
            Map<Id, Boolean> lockStateById = Approval.isLocked(new List<Id>(eligibleLeadsById.keySet()));
            for (Id leadId : eligibleLeadsById.keySet()) {
                if (lockStateById != null && lockStateById.containsKey(leadId) && lockStateById.get(leadId) == true) {
                    lockedLeadIds.add(leadId);
                }
            }
            
            // Unlock records before updating them.
            if (!lockedLeadIds.isEmpty()) {
                try {
                    Approval.UnlockResult[] unlockResults = Approval.unlock(lockedLeadIds, false);
                    for (Integer i = 0; i < lockedLeadIds.size(); i++) {
                        Id leadId = lockedLeadIds[i];
                        if (unlockResults == null || i >= unlockResults.size() || unlockResults[i] == null) {
                            resultById.put(leadId, 'Unable to determine approval unlock result.');
                            continue;
                        }
                        if (!unlockResults[i].isSuccess()) {
                            resultById.put(leadId, 'Unable to unlock Lead: ' + getApprovalErrors(unlockResults[i].getErrors()));
                        }
                    }
                } catch (Exception ex) {
                    for (Id leadId : lockedLeadIds) {
                        resultById.put(leadId,'Unable to unlock Lead: ' + ex.getMessage());
                    }
                }
            }
            
            List<Lead> leadsToUpdate = new List<Lead>();
            List<Id> updateLeadIds = new List<Id>();
            
            // Prepare updates only for eligible Leads without recorded errors.
            for (Id leadId : eligibleLeadsById.keySet()) {
                if (resultById.containsKey(leadId)) {
                    continue;
                }
                Lead leadToRevive = eligibleLeadsById.get(leadId);
                leadToRevive.Status = ConstantUtility.ACTIVE;
                leadToRevive.Approval_Status__c = null;
                leadToRevive.Lead_Drop_Reason__c = null;
                leadToRevive.Please_Specify__c = null;
                leadToRevive.ValidationBypassDateTime__c = system.now();
                leadsToUpdate.add(leadToRevive);
                updateLeadIds.add(leadId);
            }
            // Update records independently so one failure does not roll back
            // successful updates for other Leads.
            if (!leadsToUpdate.isEmpty()) {
                
                Database.SaveResult[] saveResults = Database.update(leadsToUpdate, false);
                for (Integer i = 0; i < saveResults.size(); i++) {
                    Id leadId = updateLeadIds[i];
                    Database.SaveResult saveResult = saveResults[i];
                    if (saveResult.isSuccess()) {
                        resultById.put(leadId, ConstantUtility.SUCCESS_MESSAGE);
                    } else {
                        resultById.put(leadId, 'Unable to revive Lead: ' + getDmlErrors(saveResult.getErrors()));
                    }
                }
            }
            return buildOutputMessages(leadIds, resultById, outputMessages);
        }catch(exception ex){
            LoggerUtil.createErrorLog(
                'LeadReviveController',
                'reviveLeads',
                ex.getTypeName(),
                ex.getMessage(),
                ex.getStackTraceString(),
                String.valueOf(ex.getLineNumber())
            );
            outputMessages.add(ex.getMessage());
            return outputMessages;
        }
    }
    
    /**
* Builds output messages in the same order as the input IDs.
*
* Duplicate IDs receive the same result message. Messages already
* assigned during input validation are preserved.
*
* @param leadIds Original input IDs.
* @param resultById Map of record IDs to operation results.
* @param outputMessages Initialized output list.
* @return Completed output list in input order.
*/
    private static List<String> buildOutputMessages(List<Id> leadIds, Map<Id, String> resultById, List<String> outputMessages) {
        for (Integer i = 0; i < leadIds.size(); i++) {
            if (outputMessages[i] != null) {
                continue;
            }
            Id leadId = leadIds[i];
            if (leadId == null || leadId.getSObjectType() != Lead.SObjectType) {
                outputMessages[i] = ConstantUtility.INVALID_ID_ERROR;
            } else if (resultById.containsKey(leadId)) {
                outputMessages[i] = resultById.get(leadId);
            } else {
                outputMessages[i] = ConstantUtility.NOT_FOUND_ERROR;
            }
        }
        return outputMessages;
    }
    
    /**
* Converts approval unlock errors into a readable message.
*
* @param errors Errors returned by Approval.UnlockResult.
* @return Concatenated error messages or a fallback message.
*/
    private static String getApprovalErrors(Database.Error[] errors) {
        List<String> messages = new List<String>();
        if (errors != null) {
            for (Database.Error error : errors) {
                messages.add(error.getMessage());
            }
        }
        return messages.isEmpty() ? 'Unknown approval unlock error.' : String.join(messages, '; ');
    }
    
    /**
* Converts DML errors into a readable message.
*
* @param errors Errors returned by Database.SaveResult.
* @return Concatenated error messages or a fallback message.
*/
    private static String getDmlErrors(Database.Error[] errors) {
        List<String> messages = new List<String>();
        if (errors != null) {
            for (Database.Error error : errors) {
                messages.add(error.getMessage());
            }
        }
        return messages.isEmpty() ? 'Unknown record update error.' : String.join(messages, '; ');
    }
}