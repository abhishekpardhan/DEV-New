/**
 * Description      :   EventContactTriggerHelper use to update the contact last event
 * Release          :   15th Oct, 2024
 * JIRA Ticket		:	SAC-962	
 * Coverage			:
 * Revision Logs    :   V_1.0 - Created By - KR SANSI(IBM)
 * 
 **/
public without sharing class EventContactTriggerHelper {   
     // Rule Method called- Added by Anand Raju-SAC-2280- 20th Feb 26

    // commented by abhishek pardahn as per story:- SAC-2623
    // public static void syncParentContactsToChild(List<Event__c> newChildEvents){
    //     try{
    //         if(newChildEvents.isEmpty()) return;

    //         Set<Id> parentIds = new Set<Id>();
    //         Set<Id> childIds = new Set<Id>();

    //         for(Event__c ev : newChildEvents){
    //             if(ev.Parent_Event__c != null){
    //                 parentIds.add(ev.Parent_Event__c);
    //                 childIds.add(ev.Id);
    //             }
    //         }

    //         if(parentIds.isEmpty()) return;

    //         // fetch parent contacts
    //         Map<Id, Set<Id>> parentToContacts = new Map<Id, Set<Id>>();

    //         for(Event_Contact__c ec : [
    //             SELECT Id, Event__c, Contact__c
    //             FROM Event_Contact__c
    //             WHERE Event__c IN :parentIds
    //         ]){
    //             if(!parentToContacts.containsKey(ec.Event__c)){
    //                 parentToContacts.put(ec.Event__c, new Set<Id>());
    //             }
    //             parentToContacts.get(ec.Event__c).add(ec.Contact__c);
    //         }

    //         List<Event_Contact__c> toInsert = new List<Event_Contact__c>();

    //         for(Event__c child : newChildEvents){
    //             Id parentId = child.Parent_Event__c;

    //             if(parentToContacts.containsKey(parentId)){
    //                 for(Id conId : parentToContacts.get(parentId)){
    //                     Event_Contact__c ec = new Event_Contact__c();
    //                     ec.Event__c = child.Id;
    //                     ec.Contact__c = conId;
    //                     toInsert.add(ec);
    //                 }
    //             }
    //         }

    //         if(!toInsert.isEmpty()){
    //             insert toInsert;
    //         }
    //     } catch(Exception e){
    //         System.debug('syncParentContactsToChild : '+e.getMessage());
    //         ExceptionHandling.Exception('syncParentContactsToChild', 'EventContactTriggerHelper', e.getMessage());
    //     }
        
    // }

    public static void stopDuplicateContact(List<Event_Contact__c> newList){
        try{
            Set<Id> eventIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            Set<Id> recordIds = new Set<Id>();

            for(Event_Contact__c rec : newList){
                if(rec.Event__c != null && rec.Contact__c != null){
                    eventIds.add(rec.Event__c);
                    contactIds.add(rec.Contact__c);
                }
                if(rec.Id != null){
                    recordIds.add(rec.Id);
                }
            }

            // existing records from DB
            Map<String,Id> existingMap = new Map<String,Id>();

            for(Event_Contact__c ec : [
                SELECT Id, Event__c, Contact__c
                FROM Event_Contact__c
                WHERE Event__c IN :eventIds
                AND Contact__c IN :contactIds
                AND Id NOT IN :recordIds
            ]){
                existingMap.put(ec.Event__c + '-' + ec.Contact__c, ec.Id);
            }

            // check duplicate in same transaction also
            Set<String> txnSet = new Set<String>();

            for(Event_Contact__c rec : newList){
                String key = rec.Event__c + '-' + rec.Contact__c;

                if(existingMap.containsKey(key) || txnSet.contains(key)){
                    rec.addError('Duplicate contact not allowed for same Event Contact.');
                }

                txnSet.add(key);
            }
        } catch(Exception e){
            System.debug('stopDuplicateContact : '+e.getMessage());
            ExceptionHandling.Exception('stopDuplicateContact', 'EventContactTriggerHelper', e.getMessage());
        }
    }

    // commented by abhishek pardahn as per story:- SAC-2623
    //MAIN SYNC METHOD (Insert/Delete) 
    // public static void syncToChild(List<Event_Contact__c> newList, List<Event_Contact__c> oldList){
    //     try{
    //         Set<Id> parentEventIds = new Set<Id>();
    //         Set<Id> contactIds = new Set<Id>();
    //         Map<Id, Set<Id>> parentEventToContacts = new Map<Id, Set<Id>>();

    //         //INSERT CASE
    //         if(newList != null){
    //             for(Event_Contact__c ec : newList){
    //                 if(ec.Event__c == null || ec.Contact__c == null) continue;

    //                 parentEventIds.add(ec.Event__c);
    //                 contactIds.add(ec.Contact__c);

    //                 if(!parentEventToContacts.containsKey(ec.Event__c)){
    //                     parentEventToContacts.put(ec.Event__c, new Set<Id>());
    //                 }
    //                 parentEventToContacts.get(ec.Event__c).add(ec.Contact__c);
    //             }
    //         }

    //         //DELETE CASE
    //         if(oldList != null){
    //             for(Event_Contact__c ec : oldList){
    //                 if(ec.Event__c == null || ec.Contact__c == null) continue;

    //                 parentEventIds.add(ec.Event__c);
    //                 contactIds.add(ec.Contact__c);

    //                 if(!parentEventToContacts.containsKey(ec.Event__c)){
    //                     parentEventToContacts.put(ec.Event__c, new Set<Id>());
    //                 }
    //                 parentEventToContacts.get(ec.Event__c).add(ec.Contact__c);
    //             }
    //         }

    //         if(parentEventIds.isEmpty()) return;

    //         //Only parent events
    //         Map<Id, Event__c> parentMap = new Map<Id, Event__c>(
    //             [SELECT Id 
    //             FROM Event__c 
    //             WHERE Id IN :parentEventIds 
    //             AND Parent_Event__c = NULL]
    //         );

    //         if(parentMap.isEmpty()) return;

    //         //Fetch child events
    //         List<Event__c> childEvents = [
    //             SELECT Id, Parent_Event__c 
    //             FROM Event__c 
    //             WHERE Parent_Event__c IN :parentMap.keySet()
    //         ];

    //         if(childEvents.isEmpty()) return;

    //         Set<Id> childEventIds = new Set<Id>();
    //         for(Event__c e : childEvents){
    //             childEventIds.add(e.Id);
    //         }

    //         // INSERT 
    //         if(newList != null){

    //             //avoid duplicates 
    //             //Duplicate Rule Method called- Added by Anand Raju-SAC-2280
    //             Map<String, Event_Contact__c> existingMap = new Map<String, Event_Contact__c>();

    //             for(Event_Contact__c ec : [
    //                 SELECT Id, Event__c, Contact__c
    //                 FROM Event_Contact__c
    //                 WHERE Event__c IN :childEventIds
    //                 AND Contact__c IN :contactIds
    //             ]){
    //                 existingMap.put(ec.Event__c+'-'+ec.Contact__c, ec);
    //             }

    //             List<Event_Contact__c> toInsert = new List<Event_Contact__c>();

    //             for(Event__c child : childEvents){
    //                 Id parentId = child.Parent_Event__c;
    //                 if(!parentEventToContacts.containsKey(parentId)) continue;
    //                 if(!parentEventToContacts.containsKey(parentId)) continue;

    //                 for(Id conId : parentEventToContacts.get(parentId)){
    //                     String key = child.Id+'-'+conId;

    //                     if(!existingMap.containsKey(key)){
    //                         Event_Contact__c newEC = new Event_Contact__c();
    //                         newEC.Event__c = child.Id;
    //                         newEC.Contact__c = conId;
    //                         toInsert.add(newEC);
    //                     }
    //                 }
    //             }

    //             if(!toInsert.isEmpty())
    //                 insert toInsert;
    //         }

            
    //         if(oldList != null){

    //             List<Event_Contact__c> toDelete = new List<Event_Contact__c>();

    //             for(Event_Contact__c ec : [
    //                 SELECT Id, Event__c, Contact__c
    //                 FROM Event_Contact__c
    //                 WHERE Event__c IN :childEventIds
    //                 AND Contact__c IN :contactIds
    //             ]){
    //                 toDelete.add(ec);
    //             }

    //             if(!toDelete.isEmpty())
    //                 delete toDelete;
    //         }
    //     } catch(Exception e){
    //         System.debug('syncToChild : '+e.getMessage());
    //         ExceptionHandling.Exception('syncToChild', 'EventContactTriggerHelper', e.getMessage());
    //     }
    // }

    // //UPDATE HANDLER
    // public static void handleUpdate(List<Event_Contact__c> newList, Map<Id,Event_Contact__c> oldMap){
    //     try{
    //         List<Event_Contact__c> oldToDelete = new List<Event_Contact__c>();
    //         List<Event_Contact__c> newToInsert = new List<Event_Contact__c>();

    //         for(Event_Contact__c newRec : newList){
    //             Event_Contact__c oldRec = oldMap.get(newRec.Id);

    //             if(newRec.Contact__c != oldRec.Contact__c 
    //             || newRec.Event__c != oldRec.Event__c){

    //                 oldToDelete.add(oldRec);
    //                 newToInsert.add(newRec);
    //             }
    //         }

    //         if(!oldToDelete.isEmpty())
    //             syncToChild(null, oldToDelete);

    //         if(!newToInsert.isEmpty())
    //             syncToChild(newToInsert, null);
    //     } catch(Exception e){
    //             System.debug('handleUpdate : '+e.getMessage());
    //             ExceptionHandling.Exception('handleUpdate', 'EventContactTriggerHelper', e.getMessage());
    //     }
    // }
}