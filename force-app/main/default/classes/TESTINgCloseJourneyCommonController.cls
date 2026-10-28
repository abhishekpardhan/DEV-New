public class TESTINgCloseJourneyCommonController {
    
    public void autoCheckoutJourneys(List<Journey__c> journeys ) {
        Id eventGeoloactionID = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event Geolocation Completed').getRecordTypeId();          
        Id jouneyCompletedID = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('Journey Completed').getRecordTypeId();
        DateTime now= System.Now();
        
        // Query all journeys that are not checked out
       
        List<Journey__c> journeysToUpdate = new List<Journey__c>();
        List<Journey__c> journeysToDelete = new List<Journey__c>();
        List<Event__c> eventsToUpdate = new List<Event__c>();
        
        // Loop through all the non-checked out Journeys
        
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
                    System.debug('lastEvent To be checked out :'+ lastEvent.Id);
                    for (Event__c moreEvent : journey.Events__r) {
                        /*Event is niether Check-In not Check-Out*/
                        if(moreEvent.CheckIn_Date__c==null && moreEvent.CheckOut_Date__c==null){
                            EventsToCancel.add(moreEvent);
                        }
                        /*Event is Check-In but not checked Out*/
                        else if(moreEvent.CheckIn_Date__c!=null && moreEvent.CheckOut_Date__c==null){
                            EventsToCheckOut.add(moreEvent);
                            //lastEvent = journey.Events__r[0];
                            System.debug('Event To be checked out :'+ moreEvent);
                        }
                    }
                    /*Cancel all the unchecked events*/
                    if(EventsToCancel.size()>0){
                        for(Event__c event : EventsToCancel){
                            event.Cancel__c = true;
                            event.Status__c = 'Cancelled';
                            event.Reason__c = 'Others';
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
                            System.debug('Event To be checked out Inside loop :'+ events);
                        }
                    }
                    /*Put checkout details in the Journey*/
                    journey.CheckOut_Date__c = now;
                    journey.CheckOut_Location__c = lastEvent.CheckIn_Location__c;
                    journey.CheckOut_Address__c = lastEvent.CheckIn_Address__c;
                    journey.recordtypeid = jouneyCompletedID;
                    journey.Remarks__c = 'Auto-Checked Out Journey';
                    journey.Journey_KM__c = calculatejourneyKm(journey.Id);
                    journeysToUpdate.add(journey);
                    
                }/*No Events*//*else{
                    journey.Journey_KM__c = 0;
                    journey.CheckOut_Date__c = now;
                    journey.CheckOut_Location__c = journey.CheckIn_Location__c;
                    journey.CheckOut_Address__c = journey.CheckIn_Address__c;
                    journey.recordtypeid = jouneyCompletedID;
                    journey.Remarks__c = 'Auto-Checked Out Journey';
                    journeysToUpdate.add(journey);
                }*/
            }else{
               // journeysToDelete.add(journey);
                //Journey not Checked In but has events
                Boolean hasEvents = journey.Events__r != null && !journey.Events__r.isEmpty();
                if(hasEvents){
                    for(Event__c event : journey.Events__r){
                        event.Cancel__c = true;
                        event.Status__c = 'Cancelled';
                        event.Reason__c = 'Others';
                        event.Sub_Reason__c = 'Auto-Checked Out Journey';
                        event.Remarks__c = 'Auto-Checked Out Journey';
                        eventsToUpdate.add(event);
                    }
                }
            }
        }
        performDMLOperation(eventsToUpdate, false, 1);
        performDMLOperation(journeysToDelete, true, 3);
        performDMLOperation(journeysToUpdate, false, 2);  
    }
    
    public void performDMLOperation(List<SObject> listToUpdate, Boolean deleteList, Integer type) {
        if (!listToUpdate.isEmpty()) {
            if (!deleteList&& (type !=3)) {
                Database.SaveResult[] saveResultList = Database.update(listToUpdate, false);
                handleSaveResults(saveResultList, type,listToUpdate);
            } else {
               // Database.delete(listToUpdate);
                System.debug('Deleted Journeys: ' + listToUpdate);
            }
        }
    }
    
    private void handleSaveResults(Database.SaveResult[] saveResultList, Integer type, List<SObject> listToUpdate) {
        List<Id> recordId = new List<Id>();
        for (Database.SaveResult sr : saveResultList) {
            if (sr.isSuccess()) {
                System.debug('Successfully updated ID: ' + sr.getId());
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
            message = 'Journey updated successfully.';
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
    
    public static Decimal calculatejourneyKm(Id jourId){
        Decimal Journey_KM;
        // Mathod to calculate total distance of events and update it into journey_km__c field
        AggregateResult[] totalDis  = [SELECT sum(Distance__c)avgDis FROM Event__c where Journey__C =:jourId and Is_Claim__c = true GROUP BY Journey__C];
        if(totalDis.size() > 0 && (Decimal)totalDis[0].get('avgDis') > 0){
            Journey_KM = ((Decimal)totalDis[0].get('avgDis')).round(System.RoundingMode.HALF_UP);
        } 
        return Journey_KM;
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
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(Notificationtype==1? 'Event': 'Journey');
            notification.setBody(message);
            notification.setTargetId(rec);
            notification.setNotificationTypeId(type.Id);
            notification.send(new Set<String>{recipientId.get(rec)});
        }
    }
}