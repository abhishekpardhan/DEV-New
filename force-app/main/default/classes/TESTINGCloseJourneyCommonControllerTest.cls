@isTest
public class TESTINGCloseJourneyCommonControllerTest {

static void setupTestData() {
    // Query the record type IDs directly
    Id eventGeolocationRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Event__c' AND DeveloperName = 'Event_Geolocation_Completed' LIMIT 1].Id;
    Id journeyCompletedRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Journey__c' AND DeveloperName = 'Journey_Completed' LIMIT 1].Id;

    // Create Sample Data: Journey with Events
    Journey__c journeyCheckedIn = CommonDataTest.getJourney();
    journeyCheckedIn.Journey_Date__c = Date.today()-11;
    journeyCheckedIn.CheckIn_Date__c = DateTime.now().addDays(-11);
    journeyCheckedIn.CheckIn_Location__c = 'Location A';
    journeyCheckedIn.CheckIn_Address__c = 'Address A';
    journeyCheckedIn.CheckOut_Date__c = null;
    journeyCheckedIn.Journey_KM__c = TESTINGCloseJourneyCommonController.calculatejourneyKm(journeyCheckedIn.Id);
    insert journeyCheckedIn;

    Event__c checkedInEvent = new Event__c(
        Journey__c = journeyCheckedIn.Id,
        CheckIn_Date__c = DateTime.now().addDays(-11),
        CheckIn_Location__c = 'Location B',
        CheckIn_Address__c = 'Address B',
        RecordTypeId = eventGeolocationRecordTypeId
    );
    insert checkedInEvent;
    
    
    Journey__c objJ = CommonDataTest.getJourney();
    objJ.Journey_Date__c = Date.today();
    insert objJ;
    
    Journey__c objJ2 = CommonDataTest.getJourney();
    objJ2.Journey_Date__c = Date.today() + 3;
    insert objJ2;
}
    
static void setupTestData1() {
    // Query the record type IDs directly
    Id eventGeolocationRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Event__c' AND DeveloperName = 'Event_Geolocation_Completed' LIMIT 1].Id;
    Id journeyCompletedRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Journey__c' AND DeveloperName = 'Journey_Completed' LIMIT 1].Id;

    // Create Sample Data: Journey with Events
    Journey__c journeyCheckedIn = CommonDataTest.getJourney();
    journeyCheckedIn.Journey_Date__c = Date.today()-11;
    journeyCheckedIn.CheckIn_Date__c = DateTime.now().addDays(-11);
    journeyCheckedIn.CheckIn_Location__c = 'Location A';
    journeyCheckedIn.CheckIn_Address__c = 'Address A';
    journeyCheckedIn.CheckOut_Date__c = null;
    journeyCheckedIn.Journey_KM__c = TESTINGCloseJourneyCommonController.calculatejourneyKm(journeyCheckedIn.Id);
    insert journeyCheckedIn;

    Event__c checkedInEvent = new Event__c(
        Journey__c = journeyCheckedIn.Id,
        CheckIn_Date__c = null,
        CheckOut_Date__c = null,
        CheckIn_Location__c = 'Location B',
        CheckIn_Address__c = 'Address B',
        RecordTypeId = eventGeolocationRecordTypeId
    );
    insert checkedInEvent;
    
    
    Journey__c objJ = CommonDataTest.getJourney();
    objJ.Journey_Date__c = Date.today();
    insert objJ;
    
    Journey__c objJ2 = CommonDataTest.getJourney();
    objJ2.Journey_Date__c = Date.today() + 3;
    insert objJ2;
}


   
    
    @isTest
    static void testAutoCheckoutJourneysInStation1() {
        setupTestData1();
        Test.startTest();
        List<Journey__c> updatedJourney = [Select Id,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c, CheckIn_Address__c, CheckOut_Address__c, Journey_Date__c,
            (Select Id ,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,CheckIn_Address__c, CheckOut_Address__c,Distance__c,Is_Claim__c from Events__r Order By CheckIn_Date__c DESC NULLS LAST)
            from Journey__c WHERE CheckOut_Date__c = null AND Outstation__c =: false AND Journey_Date__c <= today LIMIT 1];
        TESTINGCloseJourneyCommonController controller = new TESTINGCloseJourneyCommonController();
        controller.autoCheckoutJourneys(updatedJourney);
        Test.stopTest();

        // Assert journey and event updates
       // Journey__c updatedJourney = [SELECT Id, CheckOut_Date__c, CheckOut_Location__c, Remarks__c FROM Journey__c WHERE CheckOut_Date__c != null LIMIT 1];
      //  System.assertNotEquals(null, updatedJourney.CheckOut_Date__c, 'Journey should be checked out');
       // System.assertEquals('Auto-Checked Out Journey', updatedJourney.Remarks__c, 'Incorrect journey remark');
    }
}