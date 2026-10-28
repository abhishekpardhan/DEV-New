@isTest
private class Test_trg_JourneyUpdateEvent {

    @isTest
    static void testJourneyUpdateEventTrigger() {
        // Step 1: Create a Journey__c record
        Journey__c journey = CommonDataTest.getJourney();
        journey.Remarks_To_be_filled_by_Auditors__c = 'Initial';
        insert journey;

        // Step 2: Simulate the Platform Event
        Update_Event__e updateEvent = new Update_Event__e(
            ObjectName__c = 'Journey__c',
            ObjectId__c = journey.Id,
            FieldName__c = 'Remarks_To_be_filled_by_Auditors__c',
            Field_Value__c = 'Updated by Event'
        );

        // Step 3: Use Test.startTest/Test.stopTest to simulate async platform event behavior
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(updateEvent);
        Test.stopTest();

        // Step 4: Assert that the Journey__c record was updated
        Journey__c updatedJourney = [SELECT Id, Journey_Audited__c, Remarks_To_be_filled_by_Auditors__c 
                                     FROM Journey__c 
                                     WHERE Id = :journey.Id];

        System.assertEquals('Updated by Event', updatedJourney.Remarks_To_be_filled_by_Auditors__c, 'Remarks should be updated');
    }
     @isTest
    static void testJourneyAndEventUpdate() {

        // Create Journey record
        // 
        Journey__c journey = new Journey__c(
            Journey_Audited__c = false,
            Mode_of_transport__c = 'Public', 
            Remarks_To_be_filled_by_Auditors__c = 'Old'
        );
        insert journey;

        // Create Event record
        Event__c ev = new Event__c(
            OwnerId = UserInfo.getUserId(),
            Start__c = System.now(),
    Status__c = 'Open'
        );
        insert ev;

        List<Update_Event__e> eventList = new List<Update_Event__e>();

        // Journey update
        eventList.add(new Update_Event__e(
            ObjectName__c = 'Journey__c',
            ObjectId__c = journey.Id,
            Audited__c = true,
            FieldName__c = 'Remarks_To_be_filled_by_Auditors__c',
            Field_Value__c = 'Updated'
        ));

        // Event owner update
        eventList.add(new Update_Event__e(
            ObjectName__c = 'Event__c',
            ObjectId__c = ev.Id,
            Field_Value__c = UserInfo.getUserId()
        ));

        Test.startTest();
        EventBus.publish(eventList);
        Test.stopTest();

        // Verify Journey
        Journey__c updatedJourney = [
            SELECT Journey_Audited__c, Remarks_To_be_filled_by_Auditors__c
            FROM Journey__c
            WHERE Id = :journey.Id
        ];

        System.assertEquals(true, updatedJourney.Journey_Audited__c);
        System.assertEquals('Updated', updatedJourney.Remarks_To_be_filled_by_Auditors__c);

        // Verify Event
        Event__c updatedEvent = [
            SELECT OwnerId, ValidationBypassDateTime__c
            FROM Event__c
            WHERE Id = :ev.Id
        ];

        System.assertEquals(UserInfo.getUserId(), updatedEvent.OwnerId);
        System.assertNotEquals(null, updatedEvent.ValidationBypassDateTime__c);
    }
}