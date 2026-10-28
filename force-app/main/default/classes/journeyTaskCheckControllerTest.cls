@isTest
private class journeyTaskCheckControllerTest {

    
    @IsTest
    static void testJourneyTaskCheck_ReturnsTrue() {

        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Journey
        Journey__c jr = new Journey__c(
            Journey_Date__c = Date.today().addDays(-1),
            CheckIn_Location__c = '28.52,76.27',
            Mode_of_transport__c = 'Public',
            OwnerId = UserInfo.getUserId()
        );
        insert jr;

        // Contact
        Contact con = new Contact(
            FirstName = 'Unit',
            LastName = 'Test',
            Email = 'test@gmail.com'
        );
        insert con;

        // Event
        Event__c ev = new Event__c(
            Name = 'Test Event',
            Journey__c = jr.Id,
            Account__c = acc.Id,
            Contact__c = con.Id,
            OwnerId = UserInfo.getUserId(),
            Start__c = System.now(),
            is_Automated__c = true,
            CheckIn_Location__c = '28.52,76.27',
            CheckOut_Location__c = '28.68,77.22',
            CheckOut_Date__c = jr.Journey_Date__c
        );
        insert ev;

        // Record Types
        Id generalRT = Schema.SObjectType.Task
            .getRecordTypeInfosByName()
            .get('General')
            .getRecordTypeId();

        // Task (IMPORTANT: ActivityDate <= Journey_Date__c)
        Task t = new Task(
            WhatId = acc.Id,
            OwnerId = UserInfo.getUserId(),
            Subject = 'Test Task',
            Status = 'Open',
            RecordTypeId = generalRT,
            ActivityDate = jr.Journey_Date__c
        );
        insert t;

        Test.startTest();
        String result = journeyTaskCheckController.journeyTaskCheck(jr.Id);
        Test.stopTest();

        System.assertEquals(
            'True',
            result,
            'Should return True when matching open task exists'
        );
    }
    @IsTest
static void testEventTaskCheck_ReturnsTrue() {

    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Journey__c jr = new Journey__c(
        Journey_Date__c = Date.today().addDays(-1),
        CheckIn_Location__c = '28.52,76.27',
        Mode_of_transport__c = 'Public',
        OwnerId = UserInfo.getUserId()
    );
    insert jr;

    Contact con = new Contact(
        FirstName = 'Unit',
        LastName = 'Test',
        Email = 'event@test.com'
    );
    insert con;

    Event__c ev = new Event__c(
        Name = 'Test Event',
        Journey__c = jr.Id,
        Account__c = acc.Id,
        Contact__c = con.Id,
        OwnerId = UserInfo.getUserId(),
        Start__c = System.now(),
        is_Automated__c = true,
        CheckIn_Location__c = '28.52,76.27',
        CheckOut_Location__c = '28.68,77.22',
        CheckOut_Date__c = jr.Journey_Date__c
    );
    insert ev;

    Id generalRT = Schema.SObjectType.Task
        .getRecordTypeInfosByName()
        .get('General')
        .getRecordTypeId();

    Task t = new Task(
        WhatId = acc.Id,
        OwnerId = UserInfo.getUserId(),
        Subject = 'Event Task',
        Status = 'Open',
        RecordTypeId = generalRT,
        ActivityDate = jr.Journey_Date__c
    );
    insert t;

    Test.startTest();
    String result = journeyTaskCheckController.eventTaskCheck(ev.Id);
    Test.stopTest();

    System.assertEquals('True', result);
}

   
   
    @isTest
    static void testGetAccessDetails_WithReadAndEditAccess() {

        Journey__c myJour = new Journey__c();
        myJour.Journey_Date__c = Date.today();
        myJour.CheckIn_Location__c = '28.5252114,76.2724069';
        myJour.CheckOut_Location__c ='28.686273800000002,77.2217831';
        myJour.Mode_of_transport__c = 'Public';
        //journeyList.add(myJour);
        insert myJour;
        // Setup test data
        event__C eventObject  = new event__c();
        eventObject.name = 'test';
        eventObject.Start__c = system.now().addDays(-1);
        eventObject.is_Automated__c = true;
        eventObject.CheckIn_Location__c = '28.5252114,76.2724069';
        eventObject.CheckOut_Location__c ='28.686273800000002,77.2217831';
        eventObject.Journey__c = myJour.id;
        eventObject.CheckOut_Date__c = myJour.Journey_Date__c;
        insert eventObject;

        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        journeyTaskCheckController.AccessRequest request = new journeyTaskCheckController.AccessRequest();
        request.recordIds = new List<Id>{ eventObject.Id };
        request.userId = testUser.Id;
        request.shouldHaveReadAccess = true;
        request.shouldHaveEditAccess = true;

        journeyTaskCheckController.AccessRequest request2 = new journeyTaskCheckController.AccessRequest();
        request2.recordIds = new List<Id>{ eventObject.Id };
        request2.userId = testUser.Id;
        request2.shouldHaveReadAccess = false;
        request2.shouldHaveEditAccess = true;

        Test.startTest();
        List<List<Event__Share>> result = journeyTaskCheckController.getAccessDetails(new List<journeyTaskCheckController.AccessRequest>{ request });
        System.runAs(CommonDataTest.getUserBdm()) {
            List<List<Event__Share>> result2 = journeyTaskCheckController.getAccessDetails(new List<journeyTaskCheckController.AccessRequest>{ request2 });
        }
        Test.stopTest();

    }
  
}