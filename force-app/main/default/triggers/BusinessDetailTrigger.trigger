/**
 * Description      :   Trigger on Business_Detail__c object to perform various busines logics
 * Release          :   21th Oct, 2024
 * JIRA Ticket		:	SAC-964	
 * Coverage			:
 * Revision Logs    :   V_1.0 - Created - KR SANSI(IBM)
 * 
 **/
trigger BusinessDetailTrigger on Business_Detail__c (before insert, before update) {

    if(TriggerUtility.byPassTrigger) return;
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        BusinessDetailTriggerHelper.validateGSTWithState(Trigger.New);
        BusinessDetailTriggerHelper.checkTagggedOpportunityOrCase(Trigger.new,Trigger.oldMap); //SAC-1181;
    }
    
}