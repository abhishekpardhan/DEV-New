/**
* Description      :   Trigger on Opportunity_Teams__c object to prevent update/delete of default team members
* 
* Created By       :   Anand Raju
* Created Date     :   May 14, 2026
* 
* Revision Logs    :   V_1.0 - Created - Prevent modification of default opportunity team users
* 
**/
trigger OpportunityTeamsTrigger on Opportunity_Teams__c (before insert, before update, before delete) {
    
    // Bypass trigger if needed
    if(TriggerUtility.byPassTrigger) return;
    
    // Check trigger switch value
    if(System.Label.TriggerSwitch.equals('On')){
        
        OpportunityTeamsTriggerHandler handler = new OpportunityTeamsTriggerHandler();
        
        if(Trigger.isBefore){
            
           if(Trigger.isInsert){
           OpportunityTeamsTriggerHelper.populateADId(Trigger.new);
            }
            
            if(Trigger.isUpdate){
                handler.beforeUpdate(Trigger.new, Trigger.oldMap);
            }
            
            if(Trigger.isDelete){
                handler.beforeDelete(Trigger.oldMap);
            }
        }
    }
}