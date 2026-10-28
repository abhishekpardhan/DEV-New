/**
* Description      :   Trigger on Event__c object to perform various tasks upon different DML Operations by calling helper class methods
* 
* 
* Revision Logs    :   V_1.0 - Created
*                      V_2.0 - Modified (Added method 'checkEventForaDay' in order to check if any other evet is not going to create
*                                      for a date again, if already created)
* 
**/
trigger CustomEventTrigger on Event__c (before insert ,after update , after insert, before update, before delete){
    
    //Checking Trigger Switch Values
    if(System.Label.TriggerSwitch.equals('On')){
        List<Event__c> eventsToUpdate = new List<Event__c>();
        List<Event__c> oldEventsToUpdate = new List<Event__c>();
        if(trigger.isBefore && trigger.isInsert){
            List<Event__c> lstEvent = new List<Event__c>();
            List<Event__c> lstEvent1 = new List<Event__c>();
            List<Event__c> lstEvent2 = new List<Event__c>();           
            Set<Date> startdate = new Set<Date>();
            for(Event__c objEve : trigger.new){
                if(String.isBlank(objEve.Journey__c)){
                    lstEvent.add(objEve);
                    startdate.add(objEve.start__c.Date());
                }
                if(String.isNotBlank(objEve.Campaign__c) || String.isNotBlank(objEve.Activity__c) || String.isNotBlank(objEve.Account__c) ||String.isNotBlank(objEve.Lead__c)||
                   String.isNotBlank(objEve.opportunity__c))
                {
                    lstEvent1.add(objEve);
                }
                //added by Shubham Rastogi
                if(objEve.Journey__c != null){
                    lstEvent2.add(objEve);
                }
            }
            if(lstEvent.size() > 0){
                CustomEventTriggerHandler.relateToJouney(lstEvent ,startdate);
            }
            if(lstEvent1.size() > 0){
                CustomEventTriggerHandler.checkRecordforDay(lstEvent1);
            }
            //added by Shubham Rastogi
            if(!lstEvent2.isEmpty()){
                CustomEventTriggerHandler.validateEventJourney(lstEvent2);
            }
            //Deepika Thakur | IBM | SAC-501 | Method to populate vertical of an event.
            CustomEventTriggerHandler.populateVertical(trigger.new);
        }
        if(trigger.isAfter && trigger.isUpdate){
            List<Event__c> lstEvent = new List<Event__c>();

            List<Event__c> lstLastCheckoutDateEvent = new List<Event__c>();
            Set<Id> jourIds = new Set<Id>();

            for(Event__c objEve : trigger.new){
                if(!String.isBlank(objEve.Journey__c) && objEve.Distance__c != null && objEve.Distance__c > 0 &&objEve.Is_Claim__c != trigger.oldMap.get(objEve.Id).Is_Claim__c){
                    lstEvent.add(objEve);
                    jourIds.add(objEve.Journey__c);
                }
                // Added By K SANSI(IBM) - SAC-124, based on Checkout date changed, it should update as Last Event on Parents(Account, Opportunity, Contact, Lead, Branch Master)
                if(objEve.CheckOut_Date__c != null && objEve.CheckOut_Date__c != Trigger.oldMap.get(objEve.Id).CheckOut_Date__c){
                    lstLastCheckoutDateEvent.add(objEve);
                }
                if(objEve.Status__c != null && objEve.Status__c == 'Cancelled' && objEve.Status__c != Trigger.oldMap.get(objEve.Id).Status__c) {
                    eventsToUpdate.add(objEve);
                } else {
                    if(objEve.Account__c != trigger.oldMap.get(objEve.Id).Account__c) {
                        oldEventsToUpdate.add(objEve);
                    }
                }
            }

            if(!oldEventsToUpdate.isEmpty()) {
                CustomEventTriggerHandler.addLastEventDate(oldEventsToUpdate, trigger.oldMap);
            }
            if(lstEvent.size() > 0){
                CustomEventTriggerHandler.distanceOnJourneyUpdate(lstEvent ,jourIds);
            }
            // Start Changes SAC-124 , K Sansi 8th Sep 2023
            if(lstLastCheckoutDateEvent.size()>0){
                CustomEventTriggerHandler.updateLastEvent(lstLastCheckoutDateEvent);
            }
              // Added By Anand Raju-SAC 2280
            Set<Id> parentIds = new Set<Id>();
            for(Event__c newRec : trigger.new){
                Event__c oldRec = trigger.oldMap.get(newRec.Id);

                if(newRec.Parent_Event__c == null){
                    if(newRec.Name != oldRec.Name ||
                    newRec.Status__c != oldRec.Status__c ||
                    newRec.Start__c != oldRec.Start__c ||
                    newRec.End__c != oldRec.End__c ||
                    newRec.Remarks__c != oldRec.Remarks__c ||
                    newRec.Account__c != oldRec.Account__c ||
                    newRec.Campaign__c != oldRec.Campaign__c ||
                    newRec.Opportunity__c != oldRec.Opportunity__c ||
                    newRec.Contact__c != oldRec.Contact__c ||
                    newRec.Lead__c != oldRec.Lead__c ||
                    newRec.Activity__c != oldRec.Activity__c ||
                    newRec.Branch__c != oldRec.Branch__c){
                        parentIds.add(newRec.Id);
                    }
                }
            }

            if(!parentIds.isEmpty() && !EventTeamTriggerHandler.isSyncRunning){
                EventTeamTriggerHandler.isSyncRunning = true;
                // EventTeamTriggerHandler.syncParentToChild(parentIds);
            }
            // End Changes SAC-124 
        }
        //------------- Added by Shubham Girdhar on 28/08/2019 -------------
        if(trigger.isBefore && trigger.isUpdate){
            
            // Added as part of SAC-224 
            Boolean hasCustomPermission = FeatureManagement.checkPermission('Transfer_Admin_Permission');

            List<Event__c> updatedEvents = new List<Event__c>();
            List<Event__c> lstEvent = new List<Event__c>();
            List<Event__c> lstEventToUpdate = new List<Event__c>();
            Map<Id, Id> eventToJourneyMap = new Map<Id, Id>();
            Set<Date> lstEventDates = new Set<Date>();
            Id eveRecordTypeId = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Remarks_Edit').getRecordTypeId();// Added By Adarsh - SAC-206
            for(event__c event1 : trigger.new){
                if( event1.Cancel__c == true){
                    event1.Status__c = 'Cancelled';
                }
                // added by abhishek pradhan
                if((event1.start__c != null && event1.start__c != trigger.oldMap.get(event1.Id).start__c) || (event1.OwnerId != trigger.oldMap.get(event1.Id).OwnerId && event1.OwnerId != null &&  UserInfo.getUserType() == 'AutomatedProcess')){
                    updatedEvents.add(event1);
                    lstEventDates.add(event1.start__c.date());
                    eventToJourneyMap.put(event1.Id , event1.Journey__c);
                }
                //added by Shubham Rastogi
                if(event1.Journey__c != trigger.oldMap.get(event1.Id).Journey__c && event1.Journey__c != null){
                    lstEvent.add(event1);
                }
                //Added as part of SAC-224
                if(event1.OwnerId != trigger.oldMap.get(event1.Id).OwnerId && trigger.oldMap.get(event1.Id).OwnerId != null && UserInfo.getUserType() != 'AutomatedProcess'){
                    event1.OwnerId.addError('You cannot change the owner of the Event.');
                }
                //if(event1.Journey__c != trigger.oldMap.get(event1.Id).Journey__c && event1.Journey__c == null){
                    //event1.OwnerId.addError('Journey details cannot be null.');
               // }   // updated by abhishek pardhan
                
                //changes- SAC-2750 
                //I want to view the total number of characters entered in the Recap of Meeting field on an Event record,
                if(event1.Remarks__c != trigger.oldMap.get(event1.Id).Remarks__c){
                    lstEventToUpdate.add(event1);
                }
                if(event1.CheckIn_Date__c != null && event1.RecordTypeId != eveRecordTypeId){
                    event1.RecordTypeId = eveRecordTypeId;
                }
                //changes end - SAC-206
            }

            if(!lstEventToUpdate.isEmpty()) {
                CustomEventTriggerHandler.recapCharacterCount(lstEventToUpdate);
            }

            if(updatedEvents.size() > 0){
                CustomEventTriggerHandler.relateToJouney(updatedEvents , lstEventDates);
                for(Event__c ev : updatedEvents){
                    if(eventToJourneyMap.get(ev.Id) == ev.Journey__c) {
                        ev.Journey__c = null;
                    }
                }
            }
            if(!lstEvent.isEmpty()){
                CustomEventTriggerHandler.validateEventJourney(lstEvent);
            }
        }
        if(Trigger.isInsert && trigger.IsAfter){
            set<id>jorid=new set<id>();
            // List<Event__c> childEventLists = new List<Event__c>();
            for(Event__c Eve:trigger.new){
                // if(Eve.Parent_Event__c != null) {
                //     childEventLists.add(Eve);
                // }
                eventsToUpdate.add(Eve);
                if(!String.isBlank(Eve.Journey__c)){
                    jorid.add(Eve.journey__c);
                }
            }
            

            // if(!childEventLists.isEmpty()){
            // commented by abhishek pardahn as per story:- SAC-2623
            //     EventContactTriggerHelper.syncParentContactsToChild(childEventLists);
            // }
            if(jorid.size() > 0){
                CustomEventTriggerHandler.NumberOfEvents(jorid);  
            }
            
            
            
        }
        if (Trigger.isBefore && Trigger.isDelete) {
            Set<Id> jorid = new Set<Id>();
            Map<Id, Set<Id>> acctToOwners = new Map<Id, Set<Id>>();
            
            for (Event__c e : Trigger.old) {
                eventsToUpdate.add(e);
                if (!String.isBlank(e.Journey__c)) {
                    jorid.add(e.Journey__c);
                }
                if (e.Account__c != null && e.OwnerId != null) {
                    if (!acctToOwners.containsKey(e.Account__c)) {
                        acctToOwners.put(e.Account__c, new Set<Id>());
                    }
                    acctToOwners.get(e.Account__c).add(e.OwnerId);
                }
            }
            if(!eventsToUpdate.isEmpty()) {
                CustomEventTriggerHandler.addLastEventDate(eventsToUpdate, trigger.isInsert);
            }
            // Update number of events on journeys
            if (!jorid.isEmpty()) {
                CustomEventTriggerHandler.NumberOfEvents(jorid);
            }
            
            //  Recalculate LastEventDate__c on Account_Team__c
          //  if (!acctToOwners.isEmpty()) {
          //      CustomEventTriggerHandler.recalculateLastEventDate(acctToOwners);
         //   }
        //  CustomEventTriggerHandler.addLastEventDate(trigger.old, Trigger.insert);
        }

        if(Trigger.isAfter && (Trigger.isUpdate || trigger.isInsert)){
            if(!eventsToUpdate.isEmpty()) {
                CustomEventTriggerHandler.addLastEventDate(eventsToUpdate, trigger.isInsert);
            }
        } 
    }
}