public class AutoCloseJourneyCommonController {
    
    public void autoCheckoutJourneys(Boolean isOutStation) {
        try {
            Id eventGeoloactionID = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event Geolocation Completed').getRecordTypeId();          
            Id jouneyCompletedID = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('Journey Completed').getRecordTypeId();
            DateTime now= System.Now();
            Set<Id> journeyId = new Set<Id>();
            Set<Id> journeyIdNotToBeCheckedOut= new set<Id>();
            List<Task> accountTasks = new List<Task> ();
            Id onBoardingTaskRecordTypeId = TASK.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('On_Boarding').getRecordTypeId();
            Id onGeneralTaskRecordTypeId   = ConstantUtility.TASK_GENERAL_RECORDTYPE_ID;
            Id onTaskCustomerRelationshipProfilingTaskId = ConstantUtility.TASK_CUSTOMER_RELATIONSHIP_PROFILING_TASK_ID;
            Set<Id> accountIds = new Set<Id>();
            Set<Id> ownerIds   = new Set<Id>();
            Date LatestJourneyDate ;
            // Query all journeys that are not checked out
            List<Journey__c> journeys = new List<Journey__c>();
            if(isOutStation) {
                journeys = [
                Select Id ,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c, CheckIn_Address__c, CheckOut_Address__c, Journey_Date__c,
                (Select Id ,Contact__r.Is_Complete__c,Journey__c,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,CheckIn_Address__c, CheckOut_Address__c,Distance__c,Is_Claim__c from Events__r WHERE Status__c != 'Cancelled' AND Cancel__c = false Order By CheckIn_Date__c DESC NULLS LAST)
                from Journey__c WHERE CheckOut_Date__c = null AND Outstation__c =: isOutStation AND Journey_Date__c < today];
            }
            else {
                journeys = [
                Select Id ,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c, CheckIn_Address__c, CheckOut_Address__c, Journey_Date__c,
                (Select Id ,Contact__r.Is_Complete__c,Journey__c,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,CheckIn_Address__c, CheckOut_Address__c,Distance__c,Is_Claim__c from Events__r WHERE Status__c != 'Cancelled' AND Cancel__c = false Order By CheckIn_Date__c DESC NULLS LAST)
                from Journey__c WHERE CheckOut_Date__c = null AND Outstation__c =: isOutStation AND Journey_Date__c <= today];
            }
            // Updated by sahil 24-11-2025 SAC 1998 
            for(Journey__c jr : journeys){
                journeyId.add(jr.Id);
                
                if(LatestJourneyDate==null){
                
                LatestJourneyDate =  jr.Journey_Date__c;
                }
                else{
                    if(LatestJourneyDate< jr.Journey_Date__c){
                        LatestJourneyDate = jr.Journey_Date__c ; 
                    }
                }
            }
            List<Event__c> eventList = [
                    SELECT Id, OwnerId, Account__c,Journey__c
                    FROM Event__c
                    WHERE Journey__c  IN :journeyId
                ];

            Map<Id,Id> EventJourneyMap = new Map<Id,Id>();
            Map<Id,Set<Id>> AccountEventMap = new Map<Id,Set<Id>>();
            for (Event__c ev : eventList) {
                if (ev.Account__c != null && ev.Journey__c!=null){
                    accountIds.add(ev.Account__c);
                    
                    if (!AccountEventMap.containsKey(ev.Account__c)) {
                        AccountEventMap.put(ev.Account__c, new Set<Id>());
                        }
                    AccountEventMap.get(ev.Account__c).add(ev.Id);
                    EventJourneyMap.Put(ev.Id,ev.Journey__c);
                }
                
                if (ev.OwnerId   != null) ownerIds.add(ev.OwnerId); 
                
                }
        
                if(!accountIds.isEmpty() && !ownerIds.isEmpty()) {
                accountTasks = [
                        SELECT Id,ActivityDate,WhatId
                        FROM Task
                        WHERE WhatId IN :accountIds
                        AND OwnerId  IN :ownerIds
                        AND Status = 'Open'
                        AND RecordTypeId IN :new Set<Id>{onGeneralTaskRecordTypeId, onBoardingTaskRecordTypeId,onTaskCustomerRelationshipProfilingTaskId} AND  ActivityDate<=:LatestJourneyDate];
                }
            for(Task tk:accountTasks){
                Set<Id> EventId = AccountEventMap.get(tk.WhatId);
                for(Id evid:EventId){
                Id JrId = EventJourneyMap.get(evid);
                    journeyIdNotToBeCheckedOut.add(JrId);
                }
    
            }
            List<Journey__c> journeysAutoCheckoutfalse = new List<Journey__c>();
            List<Id> listJourneyIdNotToBeCheckedOut = new  List<Id>();
            for (Integer i = journeys.size() - 1; i >= 0; i--) {
            if (journeyIdNotToBeCheckedOut.contains(journeys[i].Id)) {
                listJourneyIdNotToBeCheckedOut.add(journeys[i].Id);
                journeysAutoCheckoutfalse.add(journeys[i]);
                journeys.remove(i);
                
                }
            }
        
            // Updated by sahil 24-11-2025 SAC 1998 
            List<Journey__c> journeysToUpdate = new List<Journey__c>();
            List<Journey__c> journeysToDelete = new List<Journey__c>();
            List<Event__c> eventsToUpdate = new List<Event__c>();
            
            // Loop through all the non-checked out Journeys
            // Map<Id,Decimal> calJourneyKm = new Map<Id,Decimal>();
            Map<Id,Decimal> calJourneyKm = AutoCloseJourneyCommonController.calculatejourneyKm(journeys);
            for (Journey__c journey : journeys) {
                List<Event__c> EventsToCancel   = new List<Event__c>();
                List<Event__c> EventsToCheckOut = new List<Event__c>();

                //Journey is checked-In
                if(journey.CheckIn_Date__c!=null){
                    //Check for Events if available
                    Boolean hasEvents = journey.Events__r != null && !journey.Events__r.isEmpty();
                    //Journey consists of event
                    if(hasEvents){
                        //Loop through events
                        Event__c lastEvent = journey.Events__r[0];
                        for (Event__c moreEvent : journey.Events__r) {

                            /*Event is niether Check-In not Check-Out*/
                            if(moreEvent.CheckIn_Date__c!=null && moreEvent.CheckOut_Date__c==null && moreEvent.Contact__r.Is_Complete__c== false  && moreEvent.Contact__r!=null){
                                journeyIdNotToBeCheckedOut.add(moreEvent.Journey__c);
                            }
                            else if(moreEvent.CheckIn_Date__c==null && moreEvent.CheckOut_Date__c==null){
                                EventsToCancel.add(moreEvent);
                            }
                            /*Event is Check-In but not checked Out*/
                            else if(moreEvent.CheckIn_Date__c!=null && moreEvent.CheckOut_Date__c==null){
                                EventsToCheckOut.add(moreEvent);
                                lastEvent = journey.Events__r[0];
                            }
                        }
                        /*Cancel all the unchecked events*/
                        if(EventsToCancel.size()>0){
                            for(Event__c event : EventsToCancel){
                                event.Cancel__c = true;
                                event.Status__c = 'Cancelled';
                                event.Reason__c = 'Others';
                                event.Activities_to_be_Performed__c = 'No Meeting Done';
                                event.Sub_Reason__c = 'Auto- Checked Out';
                                event.Remarks__c = 'Auto-Checked Out Journey';
                                eventsToUpdate.add(event);
                            }
                        }
                        /*CheckOut all Checked-in events*/
                        if(EventsToCheckOut.size()>0){
                            for(Event__c events : EventsToCheckOut){
                                events.CheckOut_Date__c = now;
                                events.Status__c = 'Completed';
                                events.CheckOut_Location__c = events.CheckIn_Location__c;
                                events.CheckOut_Address__c = events.CheckIn_Address__c;
                                events.recordTypeId = eventGeoloactionID;
                                events.Remarks__c = 'Auto-Checked Out Event';
                                eventsToUpdate.add(events);
                            
                            }
                        }
                        /*Put checkout details in the Journey*/
                        journey.CheckOut_Date__c = now;
                        if(lastEvent != null  && lastEvent.CheckOut_Address__c!=null && lastEvent.CheckOut_Location__c!=null){
                        journey.CheckOut_Location__c = lastEvent == null ? journey.CheckIn_Location__c :lastEvent.CheckOut_Location__c;
                        journey.CheckOut_Address__c = lastEvent == null  ? journey.CheckIn_Address__c :lastEvent.CheckOut_Address__c;
                        }
                        else if (lastEvent != null  && lastEvent.CheckIn_Address__c!=null && lastEvent.CheckIn_Location__c!=null){
                        journey.CheckOut_Location__c = lastEvent == null ? journey.CheckIn_Location__c :lastEvent.CheckIn_Location__c;
                        journey.CheckOut_Address__c = lastEvent == null  ? journey.CheckIn_Address__c :lastEvent.CheckIn_Address__c;  
                        }
                        else {
                        journey.CheckOut_Location__c =  journey.CheckIn_Location__c ;
                        journey.CheckOut_Address__c =  journey.CheckIn_Address__c ;  
                        }
                        journey.recordtypeid = jouneyCompletedID;
                        journey.Remarks__c = 'Auto-Checked Out Journey';
                        journey.Journey_KM__c = calJourneyKm.get(journey.Id);
                        journeysToUpdate.add(journey);
                        
                    }/*No Events*/else{
                        journey.Journey_KM__c = 0;
                        journey.CheckOut_Date__c = now;
                        journey.CheckOut_Location__c = journey.CheckIn_Location__c;
                        journey.CheckOut_Address__c = journey.CheckIn_Address__c;
                        journey.recordtypeid = jouneyCompletedID;
                        journey.Remarks__c = 'Auto-Checked Out Journey';
                        journeysToUpdate.add(journey);
                    }
                }else{
                    journeysToDelete.add(journey);
                    //Journey not Checked In but has events
                    Boolean hasEvents = journey.Events__r != null && !journey.Events__r.isEmpty();
                    if(hasEvents){
                        for(Event__c event : journey.Events__r){
                            event.Cancel__c = true;
                            event.Status__c = 'Cancelled';
                            event.Reason__c = 'Others';
                            event.Sub_Reason__c = 'Auto-Checked Out Journey';
                            event.Remarks__c = 'Auto-Checked Out Journey';
                            event.Activities_to_be_Performed__c = 'No Meeting Done';
                            eventsToUpdate.add(event);
                        }
                    }
                }
            }
            for (Integer i = journeysToUpdate.size() - 1; i >= 0; i--) {
            if (journeyIdNotToBeCheckedOut.contains(journeysToUpdate[i].Id)) {
                listJourneyIdNotToBeCheckedOut.add(journeysToUpdate[i].Id);
                journeysAutoCheckoutfalse.add(journeysToUpdate[i]);
                journeysToUpdate.remove(i);
                
                }
            }
            performDMLOperation(eventsToUpdate, false, 1);
            performDMLOperation(journeysToDelete, true, 3);
            performDMLOperation(journeysToUpdate, false, 2);
            sendNotificationBasedOnType(listJourneyIdNotToBeCheckedOut, 4, journeysAutoCheckoutfalse);
        } catch (Exception e) {
            System.debug('Error in autoCheckoutJourneys: ' + e.getMessage());
            ExceptionHandling.Exception('autoCheckoutJourneys', 'AutoCloseJourneyCommonController', e.getMessage());
        }
    }
    
    public void performDMLOperation(List<SObject> listToUpdate, Boolean deleteList, Integer type) {
        if (!listToUpdate.isEmpty()) {
            if (!deleteList&& (type !=3)) {
                Database.SaveResult[] saveResultList = Database.update(listToUpdate, false);
                handleSaveResults(saveResultList, type,listToUpdate);
            } else {
                Database.delete(listToUpdate);
            }
        }
    }
    
    private void handleSaveResults(Database.SaveResult[] saveResultList, Integer type, List<SObject> listToUpdate) {
        List<Id> recordId = new List<Id>();
        for (Database.SaveResult sr : saveResultList) {
            if (sr.isSuccess()) {
                recordId.add(sr.getId());
                //sendNotificationBasedOnType(sr.getId(), type, listToUpdate);
            } else {
                handleErrors(sr);
            }
        }
        sendNotificationBasedOnType(recordId, type, listToUpdate);
    }
    
    private void sendNotificationBasedOnType(List<Id> recordId, Integer type,List<SObject> listToUpdate) {
        String message;
        Map<String,String> recipientId = getOwnerIdForJourney(recordId, type);
        if (type == 1) {
            message = 'Event updated successfully.';
        } else if (type == 2) {
            message = 'Journey CheckedOut successfully.';
        }
        else if(type == 4){
            message = 'Auto-checkout blocked: Open tasks or incomplete contact.';
        }
        
        if (!recipientId.isEmpty()) {
            sendBellNotification(recordId, message, recipientId, type);
        }
    }
    
    private void handleErrors(Database.SaveResult sr) {
        for (Database.Error err : sr.getErrors()) {
            System.debug('The following error has occurred: ' + err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Fields that affected this error: ' + err.getFields());
        }
    }
    
    private Map<String,String> getOwnerIdForJourney(List<Id> recordId, Integer type) {
        try {
            Map<String,String> mapOwnerId = new Map<String,String>();
            if(type == 1){
                List<Event__c> event = [SELECT Id, OwnerId FROM Event__c WHERE Id IN :recordId];
                for(Event__c ev : event) {
                    mapOwnerId.put(ev.ID,ev.OwnerId);
                }
            }else{
                List<Journey__c> journey = [SELECT Id, OwnerId FROM Journey__c WHERE Id IN :recordId];
                for(Journey__c jr : journey) {
                    mapOwnerId.put(jr.Id,jr.OwnerId);
                }
            }
            return mapOwnerId;
            
        } catch (Exception e) {
            System.debug('Error fetching Journey Owner: ' + e.getMessage());
            return null;
        }
    }
    


   public static Map<Id,Decimal> calculatejourneyKm(List<Journey__c> jourId){
        Map<Id,Decimal> calculateJourneyKm = new Map<Id,Decimal>();
        Decimal Journey_KM;
        // Mathod to calculate total distance of events and update it into journey_km__c field
        AggregateResult[] totalDis  = [SELECT sum(Distance__c)avgDis,Journey__r.Id jouId FROM Event__c where Journey__r.Id IN :jourId and Is_Claim__c = true GROUP BY Journey__r.Id];
       if(!totalDis.isEmpty()){
       for(AggregateResult tDistance :totalDis){
        if((Decimal)tDistance.get('avgDis') > 0){
            Journey_KM = ((Decimal)tDistance.get('avgDis')).round(System.RoundingMode.HALF_UP);
            calculateJourneyKm.put((ID)tDistance.get('jouId'),Journey_KM);
        } 
       }
       }
        return calculateJourneyKm;
    }
    
  /*public static Decimal calculateEventDistance(String lastCheckOutDetail, String currentCheckInDetails){
        String[] lastCheckOutLatLong = lastCheckOutDetail.split(',');
        String[] currentCheckInLatLong = currentCheckInDetails.split(',');
        Location loc1 = Location.newInstance((lastCheckOutLatLong[0] != null?Double.valueOf(lastCheckOutLatLong[0]):null),(lastCheckOutLatLong[1] != null?Double.valueOf(lastCheckOutLatLong[1]):null));
        Location loc2 = Location.newInstance((currentCheckInLatLong[0] != null?Double.valueOf(currentCheckInLatLong[0]):null),(currentCheckInLatLong[1] != null?Double.valueOf(currentCheckInLatLong[1]):null));
        Double dist = Location.getDistance(loc1, loc2, 'km');
        return Decimal.valueOf(dist).round(System.RoundingMode.HALF_UP) ;
    }*/
    
    private void sendBellNotification(List<Id> recordId, String message, Map<String,String> recipientId, Integer Notificationtype) {
        CustomNotificationType type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Journey_And_Event_Custom_Notification' LIMIT 1];
        for(Id rec : recordId) {
            String recipient = recipientId.get(rec);
            if (recipient != null) {
                try {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle(Notificationtype==1? 'Event': 'Journey');
                    notification.setBody(message);
                    notification.setTargetId(rec);
                    notification.setNotificationTypeId(type.Id);
                    notification.send(new Set<String>{recipientId.get(rec)});
                } catch (Exception e) {
                    // Log the error but do not fail the whole transaction
                    System.debug('Notification send failed for record: ' + rec + ' to user: ' + recipient + ' with error: ' + e.getMessage());
                }
            }
        }
    }
}