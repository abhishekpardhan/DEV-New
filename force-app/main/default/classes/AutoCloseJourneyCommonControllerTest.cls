@isTest
public class AutoCloseJourneyCommonControllerTest {

   
 
static void setupTestData() {
    List<Journey__c> lstOfjou = new List<Journey__c>(); //SAC-1374
    // Query the record type IDs directly
    Id eventGeolocationRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Event__c' AND DeveloperName = 'Event_Geolocation_Completed' LIMIT 1].Id;
    Id journeyCompletedRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Journey__c' AND DeveloperName = 'Journey_Completed' LIMIT 1].Id;

    // Create Sample Data: Journey with Events
    Journey__c journeyCheckedIn = CommonDataTest.getJourney();
    lstOfjou.add(journeyCheckedIn); //SAC-1374
    Map<Id,Decimal> mapOfJourneyKM = AutoCloseJourneyCommonController.calculatejourneyKm(lstOfjou); //SAC-1374
    journeyCheckedIn.Journey_Date__c = Date.today()-11;
    journeyCheckedIn.CheckIn_Date__c = DateTime.now().addDays(-11);
    journeyCheckedIn.CheckIn_Location__c = 'Location A';
    journeyCheckedIn.CheckIn_Address__c = 'Address A';
    journeyCheckedIn.CheckOut_Date__c = null;
    journeyCheckedIn.Journey_KM__c = mapOfJourneyKM.get(journeyCheckedIn.Id); //SAC-1374
    insert journeyCheckedIn;

    
    Contact blockedCon = new Contact(
            LastName = 'Blocked'
        );
       
     Contact con = new Contact(
    LastName            = 'test1',
    Email               = 'test@ktl.in',
    Designation__c      = 'Manager',
    Department__c       = 'Logistics and Distribution',
    MobilePhone         = '1234567898',
    Contact_State__c    = 'Uttarakhand',
    Responsible_for__c = 'BIR',
    MailingCity         = 'Haridwar',
    MailingCountry      = 'India',
    MailingState        = 'UK',
    MailingStreet       = '34 Sector 3a',
    MailingPostalCode  = '249403',
    Address_Type__c     = 'Pickup Location'
);
    
    Event__c checkedInEvent = new Event__c(
        Journey__c = journeyCheckedIn.Id,
        CheckIn_Date__c = DateTime.now().addDays(-11),
        CheckIn_Location__c = 'Location B',
        Contact__c = blockedCon.Id,
        CheckIn_Address__c = 'Address B',
        RecordTypeId = eventGeolocationRecordTypeId
    );
    insert checkedInEvent;
    Event__c checkedInEvents = new Event__c(
        Journey__c = journeyCheckedIn.Id,
        CheckIn_Date__c = DateTime.now().addDays(-11),
        CheckIn_Location__c = 'Location B',
        Contact__c = blockedCon.Id,
        
        CheckOut_Address__c = 'Address B',
        CheckIn_Address__c = 'Address B',
        RecordTypeId = eventGeolocationRecordTypeId
    );
    insert checkedInEvents;
    
    
    Journey__c objJ = CommonDataTest.getJourney();
    objJ.Journey_Date__c = Date.today();
    insert objJ;
    
    Journey__c objJ2 = CommonDataTest.getJourney();
    objJ2.Journey_Date__c = Date.today() + 3;
    insert objJ2;
}
    
static void setupTestData1() {
    // Query the record type IDs directly
    List<Journey__c> lstOfjou = new List<Journey__c>(); //SAC-1374
    Id eventGeolocationRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Event__c' AND DeveloperName = 'Event_Geolocation_Completed' LIMIT 1].Id;
    Id journeyCompletedRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Journey__c' AND DeveloperName = 'Journey_Completed' LIMIT 1].Id;

    // Create Sample Data: Journey with Events
    Journey__c journeyCheckedIn = CommonDataTest.getJourney();
    lstOfjou.add(journeyCheckedIn); //SAC-1374
    Map<Id,Decimal> mapOfJourneyKM = AutoCloseJourneyCommonController.calculatejourneyKm(lstOfjou); //SAC-1374
    journeyCheckedIn.Journey_Date__c = Date.today()-11;
    journeyCheckedIn.CheckIn_Date__c = DateTime.now().addDays(-11);
    journeyCheckedIn.CheckIn_Location__c = 'Location A';
    journeyCheckedIn.CheckIn_Address__c = 'Address A';
    journeyCheckedIn.CheckOut_Date__c = null;
    journeyCheckedIn.Journey_KM__c = mapOfJourneyKM.get(journeyCheckedIn.Id);  //SAC-1374
    insert journeyCheckedIn;

    
    Contact blockedCon = new Contact(
            LastName = 'Test'
        );
        insert blockedCon; 
    

    Contact con = new Contact(
    LastName            = 'Test User',
    Email               = 'test@ktl.in',
    MobilePhone         = '9999999999',

    // Picklists (must be valid values)
    Designation__c      = 'Manager',
    Department__c       = 'Logistics and Distribution',
    Address_Type__c     = 'Pickup Location',

    // Required by formula
    Contact_State__c    = 'Uttarakhand',
    Responsible_for__c = 'BIR',

    // Address
    MailingStreet       = '34 Sector 3a',
    MailingCity         = 'Haridwar',
    MailingState        = 'UK',
    MailingPostalCode   = '249403'
);
insert con;

/* ALWAYS re-query formula fields */
con = [
    SELECT Is_Complete__c
    FROM Contact
    WHERE Id = :con.Id
];

System.assertEquals(
    true,
    con.Is_Complete__c,
    'Contact should be marked complete by formula'
);
    
    Event__c checkedInEvent = new Event__c(
        Journey__c = journeyCheckedIn.Id,
        CheckIn_Date__c = null,
        CheckOut_Date__c = null,
        Contact__c = blockedCon.Id,
        CheckIn_Location__c = 'Location B',
        CheckIn_Address__c = 'Address B',
        RecordTypeId = eventGeolocationRecordTypeId
    );
    insert checkedInEvent;
     Event__c checkedInEvents = new Event__c(
        Journey__c = journeyCheckedIn.Id,
        CheckIn_Date__c = null,
        CheckOut_Date__c = null,
        Contact__c = con.Id,
        CheckIn_Location__c = 'Location c',
        CheckIn_Address__c = 'Address c',
        RecordTypeId = eventGeolocationRecordTypeId
    );
     insert checkedInEvents;
    
    Journey__c objJ = CommonDataTest.getJourney();
    objJ.Journey_Date__c = Date.today();
    insert objJ;
    
    Journey__c objJ2 = CommonDataTest.getJourney();
    objJ2.Journey_Date__c = Date.today() + 3;
    insert objJ2;
}
static void setupTestData2() {
    // Query the record type IDs directly
    List<Journey__c> lstOfjou = new List<Journey__c>(); //SAC-1374
    Id eventGeolocationRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Event__c' AND DeveloperName = 'Event_Geolocation_Completed' LIMIT 1].Id;
    Id journeyCompletedRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Journey__c' AND DeveloperName = 'Journey_Completed' LIMIT 1].Id;

    // Create Sample Data: Journey with Events
    Journey__c journeyCheckedIn = CommonDataTest.getJourney();
    lstOfjou.add(journeyCheckedIn); //SAC-1374
    Map<Id,Decimal> mapOfJourneyKM = AutoCloseJourneyCommonController.calculatejourneyKm(lstOfjou); //SAC-1374
    journeyCheckedIn.Journey_Date__c = Date.today()-11;
    journeyCheckedIn.CheckIn_Location__c = 'Location A';
    journeyCheckedIn.CheckIn_Address__c = 'Address A';
    journeyCheckedIn.CheckOut_Date__c = null;
    journeyCheckedIn.Journey_KM__c = mapOfJourneyKM.get(journeyCheckedIn.Id);  //SAC-1374
    insert journeyCheckedIn;
 
    Journey__c objJ = CommonDataTest.getJourney();
    objJ.Journey_Date__c = Date.today();
    insert objJ;
    
    Journey__c objJ2 = CommonDataTest.getJourney();
    objJ2.Journey_Date__c = Date.today() + 3;
    insert objJ2;
}
    @isTest
    static void testAutoCheckoutJourneysInStation3() {
        setupTestData2();
        Test.startTest();
        AutoCloseJourneyCommonController controller = new AutoCloseJourneyCommonController();
        controller.autoCheckoutJourneys(false);
        Test.stopTest();

        
        Journey__c updatedJourney = [SELECT Id, CheckOut_Date__c, CheckOut_Location__c, Remarks__c FROM Journey__c WHERE CheckOut_Date__c != null LIMIT 1];
       
    }
    @isTest
    static void testAutoCheckoutJourneysInStation() {
        setupTestData();
        Test.startTest();
        AutoCloseJourneyCommonController controller = new AutoCloseJourneyCommonController();
        controller.autoCheckoutJourneys(false);
        Test.stopTest();

        // Assert journey and event updates
        Journey__c updatedJourney = [SELECT Id, CheckOut_Date__c, CheckOut_Location__c, Remarks__c FROM Journey__c WHERE CheckOut_Date__c != null LIMIT 1];
       // System.assertNotEquals(null, updatedJourney.CheckOut_Date__c, 'Journey should be checked out');
        //System.assertEquals('Auto-Checked Out Journey', updatedJourney.Remarks__c, 'Incorrect journey remark');

        //Event__c updatedEvent = [SELECT Id, CheckOut_Date__c, Status__c FROM Event__c WHERE CheckOut_Date__c != null LIMIT 1];
       // System.assertNotEquals(null, updatedEvent.CheckOut_Date__c, 'Event should be checked out');
        //System.assertEquals('Completed', updatedEvent.Status__c, 'Event status should be completed');
    }
    
    @isTest
    static void testAutoCheckoutJourneysInStation1() {
        setupTestData1();
        Test.startTest();
        AutoCloseJourneyCommonController controller = new AutoCloseJourneyCommonController();
        controller.autoCheckoutJourneys(false);
        Test.stopTest();

        // Assert journey and event updates
        Journey__c updatedJourney = [SELECT Id, CheckOut_Date__c, CheckOut_Location__c, Remarks__c FROM Journey__c WHERE CheckOut_Date__c != null LIMIT 1];
        System.assertNotEquals(null, updatedJourney.CheckOut_Date__c, 'Journey should be checked out');
        System.assertEquals('Auto-Checked Out Journey', updatedJourney.Remarks__c, 'Incorrect journey remark');
    }
    
    static testMethod void testschedule() {
        Test.startTest();
        String sch = '0 0 * * * ?';
        AutoCheckoutOutstationJourneyJob job = new AutoCheckoutOutstationJourneyJob();
        String jobName = 'AutoCheckoutOutstationJourneyJob';
        System.schedule(jobName, sch, job);
        Test.stopTest();
    }
    
    static testMethod void testschedule1() {
        Test.startTest();
        String sch = '0 0 * * * ?';
        AutoCheckoutLocalJourneyJob job = new AutoCheckoutLocalJourneyJob();
        String jobName = 'AutoCheckoutLocalJourneyJob';
        System.schedule(jobName, sch, job);
        Test.stopTest();
    }


}