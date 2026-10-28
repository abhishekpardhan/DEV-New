/**
 * Description		:		Test class for JourneyDistanceCalculationApi apex class
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th july, 2019
 * Release          :       17th july, 2019
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-404
 * Coverage			:		98%
 **/
@isTest
public class JourneyDistanceCalculationApiTest {
    
    @isTest static void testCallout() {
        
        
        // Creating a dummy record
        // Creating a Journey with Events in it
        Journey__c myJour = new Journey__c();
        myJour.Journey_Date__c = Date.today();
        myJour.CheckIn_Location__c = '28.5252114,76.2724069';
        myJour.CheckOut_Location__c = '28.5583284,77.1370109';
        myJour.Mode_of_transport__c = 'Public';
        insert myJour;
        // first Event for the Journey myJour
        event__C eventObject  = new event__c();
        eventObject.name = 'test';
        eventObject.Start__c = system.now().addDays(-1);
        eventObject.is_Automated__c = true;
        eventObject.CheckOut_Location__c ='28.686273800000002,77.2217831';
        eventObject.Journey__c = myJour.id;
        eventObject.CheckOut_Date__c = myJour.Journey_Date__c;
        insert eventObject;
        // Second Event for the Journey myJour
        event__C abc  = new event__c();
        abc.name = 'Journey Last Event';
        abc.Start__c = system.now().addDays(-1);
        abc.is_Automated__c = true;
        abc.CheckOut_Location__c ='28.686273800000002,77.2217831';
        abc.Journey__c = myJour.id;
        abc.CheckOut_Date__c = myJour.Journey_Date__c;
        insert abc;
        
        event__c systemEvent  = new event__c();
        systemEvent.name = 'System Event';
        systemEvent.Start__c = system.now().addDays(-1);
        systemEvent.is_Automated__c = true;
        systemEvent.CheckOut_Location__c ='28.686273800000002,77.2217831';
        systemEvent.Journey__c = myJour.id;
        systemEvent.CheckOut_Date__c = myJour.Journey_Date__c;
        insert systemEvent;
        
        // calling the class for testing
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper()); // Calling mock(Fake) responce for API test
        
        	JourneyDistanceCalculationApi.journeyArea(myJour.id);
        Test.stopTest();
    }
}