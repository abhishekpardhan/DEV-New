/**
 * Description      :   EvenContactTrigger on Event_Contact__c, use to update the contact last event
 * Release          :   15th Oct, 2024
 * JIRA Ticket		:	SAC-962	
 * Coverage			:
 * Revision Logs    :   V_1.0 - Created By - KR SANSI(IBM)
 * 
 **/
// Before insert and before update added by Anand Raju-SAC-2280 to prevent duplicate event contact
trigger EventContactTrigger on Event_Contact__c (before insert, before update,after insert, after update, after delete) {

    // Bypass trigger
    if(TriggerUtility.byPassTrigger) return;
    // Before insert and before update added by Anand Raju-SAC-2280 to prevent duplicate event contact
    if(Trigger.isBefore && Trigger.isInsert){
        EventContactTriggerHelper.stopDuplicateContact(Trigger.new);
    }
     if(Trigger.isBefore && Trigger.isUpdate){
        EventContactTriggerHelper.stopDuplicateContact(Trigger.new);
    }

    
    // commented by abhishek pardahn as per story:- SAC-2623
    // if(Trigger.isAfter){   
    //      if(Trigger.isInsert){

    //         EventContactTriggerHelper.syncToChild(Trigger.new, null);
    //     }

    //     if(Trigger.isUpdate){
    //         EventContactTriggerHelper.handleUpdate(Trigger.new, Trigger.oldMap);
    //     }

    //     if(Trigger.isDelete){
    //         EventContactTriggerHelper.syncToChild(null, Trigger.old);
    //     }
    // }
}