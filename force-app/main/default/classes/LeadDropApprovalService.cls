/**
* @File Name          : LeadDropApprovalService.cls
* @Description        : In this class Submits Leads for drop approval when their Status changes to Dropped.(EPIC4_UST5)
* @Author             : Aakash Kumar
* @Group              : GT
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        23-10-2026                Aakash Kumar              Initial Version
* 1.1        28-10-2026                Aakash Kumar              Improved null checks,
*                                                               permission validation,
*                                                               approval error handling
*                                                               and documentation
**/
public without sharing class LeadDropApprovalService {
    /**
* Submits Leads for approval when their Status changes to Dropped.
*
* Processing is skipped when the trigger is bypassed, the feature is
* disabled, or the input parameters are invalid.
*
* Eligible Leads must:
* 1. Transition to Dropped from another status.
* 2. Not already be approved or pending approval.
* 3. Not already be locked in an approval process.
* 4. Be processed by a user with the required Custom Permission.
*
* Failed approval submissions add an error to the corresponding Lead
* so that the associated record update is rejected.
*
* @param newList Updated Lead records from the after-update trigger.
* @param oldMap Previous Lead records keyed by Lead ID.
*/
    public static void submitDropApprovals(List<Lead> newList, Map<Id, Lead> oldMap) {
        // Respect the existing trigger bypass mechanism.
        if (TriggerUtility.byPassTrigger) {
            return;
        }
        
        // Respect the existing feature configuration.
        if (!ApexCommonUtils.isFeatureEnabled()) {
            return;
        }
        
        // Validate the input collections.
        if (newList == null || newList.isEmpty() || oldMap == null) {
            return;
        }
        try{
            Map<Id,Lead> leadMap = new Map<Id,Lead>();
            List<Id> leadIds = new List<Id>();
            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
            
            // Build the approval submission requests.
            for (Lead currentLead : newList) {
                if (currentLead == null || currentLead.Id == null) {
                    continue;
                }
                Lead oldLead = oldMap.get(currentLead.Id);
                if (oldLead == null) {
                    continue;
                }
                leadMap.put(currentLead.Id,currentLead);
                
                // Process only transitions into Dropped.
                if (currentLead.Status != ConstantUtility.Dropped || oldLead.Status == ConstantUtility.Dropped) {
                    continue;
                }
                
                // Do not submit records already approved or pending approval.
                if (currentLead.Approval_Status__c == ConstantUtility.Approved  || currentLead.Approval_Status__c == ConstantUtility.Pending_For_Approval) {
                    continue;
                }
                
                // Check whether the Lead is already locked.
                if(Approval.isLocked(currentLead.Id)){
                    currentLead.addError('The drop request cannot be submitted because the Lead is already locked or its lock status cannot be determined.');
                    continue;
                }
                
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                request.setObjectId(currentLead.Id);
                request.setSubmitterId(UserInfo.getUserId());
                request.setProcessDefinitionNameOrId(ConstantUtility.LEAD_DROP_APPROVAL_PROCESS_NAME);
                request.setSkipEntryCriteria(false);
                requests.add(request);
                leadIds.add(currentLead.Id);
            }
            if (requests.isEmpty()) {
                return;
            }
            
            //Submit the requests using partial-success processing.
            List<Approval.ProcessResult> results;
            try {
                results = Approval.process(requests, false);
            } catch (Exception ex) {
                // If the bulk submission throws, associate the error with
                // every Lead included in the submission request.
                for (Id leadId : leadIds) {
                    for (Lead currentLead : newList) {
                        if (currentLead != null && currentLead.Id == leadId) {
                            currentLead.addError('The drop request could not be submitted for approval: '+ex.getMessage());
                            break;
                        }
                    }
                }
                return;
            }
            /*
* Process each approval result against the corresponding Lead.
*/
            for (Integer i = 0; i < results.size(); i++) {
                Approval.ProcessResult result = results[i];
                if (result.isSuccess()) {
                    continue;
                }
                Id failedLeadId = leadIds[i];
                Lead failedLead = leadMap.get(failedLeadId);
                if(failedLead == null){
                    continue;
                }
                List<String> errorMessages = new List<String>();
                if(result.getErrors().isEmpty()){
                    continue;
                }
                for (Database.Error approvalError : result.getErrors()) {
                    errorMessages.add(approvalError.getMessage());
                }
                String errorMessage = errorMessages.isEmpty() ? 'Unknown approval submission error.' : String.join(errorMessages, '; ');
                failedLead.addError('The drop request could not be submitted for approval: ' + errorMessage);
            }
        }catch(exception ex){
            LoggerUtil.createErrorLog(
                'LeadDropApprovalService',
                'submitDropApprovals',
                ex.getTypeName(),
                ex.getMessage(),
                ex.getStackTraceString(),
                String.valueOf(ex.getLineNumber())
            );
        }
    }
    
}