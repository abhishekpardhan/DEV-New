/**
* Description      :   Handler class for OpportunityTeamsTrigger
*                      Orchestrates validation logic to prevent insert/update/delete of default team members
* 
* Created By       :   Anand Raju
* Created Date     :   May 14, 2026
* 
* Revision Logs    :   V_1.0 - Created
*                      V_1.1 - Added beforeInsert to prevent default users from being inserted
* 
**/
public class OpportunityTeamsTriggerHandler {
    
    /**
     * @description Handles before insert event
     * @param newRecords List of new Opportunity_Teams__c records
     */
 
    
    /**
     * @description Handles before update event
     * @param newRecords List of new Opportunity_Teams__c records
     * @param oldMap Map of old Opportunity_Teams__c records
     */
    public void beforeUpdate(List<Opportunity_Teams__c> newRecords, Map<Id, Opportunity_Teams__c> oldMap) {
        // Validate that default users are not being updated
        OpportunityTeamsTriggerHelper.validateDefaultUsers(newRecords, oldMap);
        
    }
    
    /**
     * @description Handles before delete event
     * @param oldMap Map of old Opportunity_Teams__c records being deleted
     */
    public void beforeDelete(Map<Id, Opportunity_Teams__c> oldMap) {
        
        OpportunityTeamsTriggerHelper.validateDefaultUsers(oldMap.values(), null);
        
    }
}