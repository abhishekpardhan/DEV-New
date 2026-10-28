/**
* @File Name          : LeadReviveController.cls
* @Description        : In this class Revives eligible Leads from a Screen Flow.(EPIC4_UST5)
* @Author             : Aakash Kumar
* @Group              : 
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        23-10-2026                Aakash Kumar                   Initial Version
**/
public with sharing class LeadReviveController {
    /* Returns one result message for each input Id, in input order.
     * @param leadIds List of Lead record IDs supplied by Flow.
     * @return List of success or error messages.
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
        
        if (!FeatureManagement.checkPermission('Lead_Revive')) {
            for (Integer i = 0; i < leadIds.size(); i++) {
                outputMessages[i] = ConstantUtility.PERMISSION_ERROR;
            }
            return outputMessages;
        }
        
        Set<Id> uniqueLeadIds = new Set<Id>();
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
            SELECT Id, Status, Approval_Status__c FROM Lead WHERE Id IN :uniqueLeadIds
        ]);
        
        Map<Id, String> resultById = new Map<Id, String>();
        Map<Id, Lead> eligibleLeadsById = new Map<Id, Lead>();
       
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
        if (!lockedLeadIds.isEmpty()) {
            Approval.UnlockResult[] unlockResults = Approval.unlock(lockedLeadIds, false);
            for (Integer i = 0; i < unlockResults.size(); i++) {
                Id leadId = lockedLeadIds[i];
                if (unlockResults[i].isSuccess()) {
                    continue;
                }
                resultById.put(leadId, 'Unable to unlock Lead: ' + getApprovalErrors(unlockResults[i].getErrors()));
            }
        }
        List<Lead> leadsToUpdate = new List<Lead>();
        List<Id> updateLeadIds = new List<Id>();
        for (Id leadId : eligibleLeadsById.keySet()) {
            if (resultById.containsKey(leadId)) {
                continue;
            }
            Lead leadToRevive = eligibleLeadsById.get(leadId);
            leadToRevive.Status = ConstantUtility.ACTIVE;
            leadToRevive.Approval_Status__c = null;
            leadToRevive.Lead_Drop_Reason__c = null;
            leadToRevive.Please_Specify__c = null;
            leadsToUpdate.add(leadToRevive);
            updateLeadIds.add(leadId);
        }
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
            system.debug(ex.getMessage());
            system.debug(ex.getLineNumber());
            return outputMessages;
        }
    }

    /**
     * Builds the output while preserving input order and duplicates.
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
     * Formats approval unlock errors.
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
     * Formats record update errors.
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