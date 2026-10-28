/**
 * Description      :   Trigger on Event_Team__c object to perform various tasks upon different DML Operations by calling helper class methods
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
trigger EventTeamTrigger on Event_Team__c (before insert,after insert ,before update,after update) {
    
    //Checking Trigger switch values
    if(System.Label.TriggerSwitch.equals('On')){
        if(trigger.isBefore && trigger.isInsert){
            //Duplicate Rule Method called- Added by Anand Raju-SAC-2280
            EventTeamTriggerHandler.stopDuplicateRecord(trigger.new);
            Set<Id> idsEvent = new Set<Id>();
            for(Event_Team__c objEve : trigger.new){
                idsEvent.add(objEve.Event__c);
            }
            
            //Method to prevent the user to add more than one child event under a parent event
            EventTeamTriggerHandler.errorNewEvent(trigger.new ,idsEvent);
        }
        if(trigger.isAfter && trigger.isInsert){
            Set<Id> idsEvent = new Set<Id>();
            for(Event_Team__c objEve : trigger.new){
                idsEvent.add(objEve.Event__c);
            }
            
            //Method to create the Child Events under a event and sharing the records with Event Team Members
            EventTeamTriggerHandler.manageEventSync(trigger.new, idsEvent, true);
        }

        if(trigger.isBefore && trigger.isUpdate) {
             //Duplicate Rule Method called- Added by Anand Raju-SAC-2280
            EventTeamTriggerHandler.stopDuplicateRecord(trigger.new);
            Map<String, Id> mapOwnerIds = new Map<String, Id>();
            Set<Id> eventIds = new Set<Id>();
            Set<Id> oldOwnerIds = new Set<Id>();
            for(Event_Team__c objEve : trigger.new){
                if(objEve.User__c != null && objEve.User__c != trigger.oldMap.get(objEve.id).User__c){
                    String key = String.valueOf(objEve.Event__c) + String.valueOf(trigger.oldMap.get(objEve.id).User__c);
                    mapOwnerIds.put(key, objEve.Id);
                    oldOwnerIds.add(trigger.oldMap.get(objEve.id).User__c);
                    eventIds.add(objEve.Event__c);
                }
            }
            
            if(!mapOwnerIds.isEmpty()){
                EventTeamTriggerHandler.memberEventAlreadyCheckedIn(
                    mapOwnerIds,
                    trigger.newMap,
                    eventIds,
                    oldOwnerIds
                );
            }
        }
        if(trigger.isAfter && trigger.isUpdate){
            Set<Id> idEvent = new Set<Id>();
            Map<String, Id> mapOwnerIds = new Map<String, Id>();
            Set<Id> eventIds = new Set<Id>();
            Set<Id> oldOwnerIds = new Set<Id>();

            List<Event_Team__c> lstNewEventTeam = new List<Event_Team__c>();
            List<Event_Team__c> lstOldEventTeam = new List<Event_Team__c>();
            
            for(Event_Team__c objEve : trigger.new){
                if(objEve.User__c != trigger.oldMap.get(objEve.id).User__c){
                    lstNewEventTeam.add(objEve);
                    lstOldEventTeam.add(trigger.oldMap.get(objEve.id));
                    idEvent.add(objEve.Event__c);
                    Event_Team__c oldRec = trigger.oldMap.get(objEve.id);
                    String key = objEve.Event__c + String.valueOf(oldRec.User__c);

                    mapOwnerIds.put(key, objEve.User__c);

                    eventIds.add(objEve.Event__c);
                    oldOwnerIds.add(oldRec.User__c);
                }
            }
            
            //Method to update the Owners on Event with Event Team Members
            if(mapOwnerIds.size() > 0){
                EventTeamTriggerHandler.changeOwner(mapOwnerIds, eventIds, oldOwnerIds);
            }
            
            //Method to provide the event sharing to Event Team Members
            if(lstNewEventTeam.size() > 0){
                EventTeamTriggerHandler.addSharing(lstNewEventTeam);
            }
            
            //Method to remove the sharing from Event Team Members in case member get updated
            if(idEvent.size() > 0){
                EventTeamTriggerHandler.removeSharing(lstOldEventTeam,idEvent);  
            }
        }
    }
}