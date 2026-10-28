/**
* @File Name          : LeadDropApprovalService.cls
* @Description        : In this class Submits Leads for drop approval when their Status changes to Dropped.(EPIC4_UST5)
* @Author             : Aakash Kumar
* @Group              : 
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        23-10-2026                Aakash Kumar                   Initial Version
**/
public class LeadDropApprovalService {
    /*Called from the after-update event of LeadTriggerHandler.
     * @param newList Updated Lead records.
     * @param oldMap  Previous versions of the Lead records.
     */
    public static void submitDropApprovals(List<Lead> newList, Map<Id, Lead> oldMap) {
        if (TriggerUtility.byPassTrigger) {
            return;
        }
        if (!isFeatureEnabled()) {
            return;
        }
        if (newList == null || newList.isEmpty() || oldMap == null) {
            return;
        }
        List<Id> leadIds = new List<Id>();
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        for (Lead currentLead : newList) {
            Lead oldLead = oldMap.get(currentLead.Id);
            if (oldLead == null) {
                continue;
            }
            if (currentLead.Status != ConstantUtility.Dropped || oldLead.Status == ConstantUtility.Dropped) {
                continue;
            }
            if(Approval.isLocked(currentLead.Id)){
                continue;
            }
            if (currentLead.Approval_Status__c == ConstantUtility.Approved 
                || currentLead.Approval_Status__c == ConstantUtility.Pending_For_Approval) {
                continue;
            }
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(currentLead.Id);
            request.setSubmitterId(UserInfo.getUserId());
            request.setProcessDefinitionNameOrId(ConstantUtility.APPROVAL_PROCESS_NAME);
            request.setSkipEntryCriteria(false);
            requests.add(request);
            leadIds.add(currentLead.Id);
        }
        if (requests.isEmpty()) {
            return;
        }
        List<Approval.ProcessResult> results = Approval.process(requests, false);
        for (Integer i = 0; i < results.size(); i++) {
            Approval.ProcessResult result = results[i];
            if (result.isSuccess()) {
                continue;
            }
            Id failedLeadId = leadIds[i];
            Lead triggerLead = Trigger.newMap.containsKey(failedLeadId) ? (Lead) Trigger.newMap.get(failedLeadId) : null;
            if (triggerLead == null) {
                continue;
            }
            List<String> errorMessages = new List<String>();
            for (Database.Error approvalError : result.getErrors()) {
                errorMessages.add(approvalError.getMessage());
            }

            String errorMessage = errorMessages.isEmpty() ? 'Unknown approval submission error.' : String.join(errorMessages, '; ');
            triggerLead.addError(
                'The drop request could not be submitted for approval: ' +
                errorMessage
            );
        }
    }

    /**
     * Checks whether the Lead Drop Approval feature is enabled.
     */
    private static Boolean isFeatureEnabled() {
        Org_Setting__mdt setting = Org_Setting__mdt.getInstance('Trigger');
        if (setting == null) {
            return false;
        }
        return setting.Is_active__c;
    }
}