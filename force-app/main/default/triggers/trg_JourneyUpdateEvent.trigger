trigger trg_JourneyUpdateEvent on Update_Event__e (after insert) {
    
    try {
        Map<Id, Update_Event__e> journeyEventMap = new Map<Id, Update_Event__e>();
        List<Event__c> eventList = new List<Event__c>();
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Update_Event__e event : Trigger.new) {
            if (event.ObjectName__c == 'Lead' && event.FieldName__c == 'OwnerId' &&
                String.isNotBlank(event.ObjectId__c) && String.isNotBlank(event.Field_Value__c)) {
                leadsToUpdate.add(new Lead(
                    Id = event.ObjectId__c,
                    OwnerId = event.Field_Value__c
                ));
            }
            if (event.ObjectName__c == 'Journey__c' && event.ObjectId__c != null) {
                journeyEventMap.put(event.ObjectId__c, event);
                
            }
            if(event.ObjectName__c == 'Event__c' && event.ObjectId__c != null) {
                eventList.add(new Event__c(
                    Id = event.ObjectId__c,
                    ownerId = event.Field_Value__c,
                    ValidationBypassDateTime__c = System.now()
                ));
                
            }
        }
        if(!eventList.isEmpty()) {
            Database.update(eventList, false);
        }
        if (!leadsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(
                leadsToUpdate, false, AccessLevel.SYSTEM_MODE);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error error : results[i].getErrors()) {
                        ExceptionHandling.Exception('trg_JourneyUpdateEvent', 'Lead owner update',
                            String.valueOf(leadsToUpdate[i].Id) + ': ' + error.getMessage());
                    }
                }
            }
        }
        
        if (!journeyEventMap.isEmpty()) {
            List<Journey__c> journeysToUpdate = new List<Journey__c>();
            List<Journey__c> existingJourneys = [
                SELECT Id, Journey_Audited__c, Remarks_To_be_filled_by_Auditors__c 
                FROM Journey__c 
                WHERE Id IN :journeyEventMap.keySet()
            ];
            
            for (Journey__c journey : existingJourneys) {
                Update_Event__e evt = journeyEventMap.get(journey.Id);
                Boolean needsUpdate = false;

                // Check for change in Audited__c (which maps to Journey_Audited__c)
                if (evt.Audited__c != null && journey.Journey_Audited__c != evt.Audited__c) {
                    journey.Journey_Audited__c = evt.Audited__c;
                    needsUpdate = true;
                }
                

                // Check for change in FieldName__c/Field_Value__c (like Remarks)
                if (evt.FieldName__c != null) {
                    Object existingFieldValue = journey.get(evt.FieldName__c);
                    if (String.valueOf(existingFieldValue) != evt.Field_Value__c) {
                        journey.put(evt.FieldName__c, evt.Field_Value__c);
                        needsUpdate = true;
                    }
                }
                
                if (needsUpdate) {
                    journeysToUpdate.add(journey);
                }
            }
            
            if (!journeysToUpdate.isEmpty()) {
                try {
                    update journeysToUpdate;
                } catch (Exception e) {
                    System.debug('Error updating Journey__c records: ' + e.getMessage());
                }
            }
        }
    } catch (Exception e) {
        System.debug('Error in trg_JourneyUpdateEvent: ' + e.getMessage());
        ExceptionHandling.Exception('trg_JourneyUpdateEvent', 'trg_JourneyUpdateEvent', e.getMessage());
    }
}