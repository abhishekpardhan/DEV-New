/**
 * Description		:		Test class for DistanceCalculationApi apex class
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th july, 2019
 * Release          :       17th july, 2019
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-404
 * Coverage			:		97%
 **/
@isTest
public class DistanceCalculationApiTest {
    @isTest static void testCallout() {
        
        Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper()); // Calling the mock(fake) responce to check api callout
       
        list<event__c> eventList = new list<event__c>();        
        // Creating a dummy record to insert in test class
        // Crating a Journey with an existing event in it
        Journey__c myJour = new Journey__c();
        myJour.Journey_Date__c = Date.today();
        myJour.CheckIn_Location__c = '28.5252114,76.2724069';
        myJour.Mode_of_transport__c = 'Public';
        insert myJour;
        // Creating an existing event for the journey myJour
        event__C eventObject  = new event__c();
        eventObject.name = 'test';
        eventObject.Start__c = system.now().addDays(-1);
        eventObject.is_Automated__c = true;
        eventObject.CheckOut_Location__c ='28.686273800000002,77.2217831';
        eventObject.Journey__c = myJour.id;
        eventObject.CheckOut_Date__c = myJour.Journey_Date__c;
        insert eventObject;
        eventList.add(eventObject);
        
        
        // Creating a Journey with only one event in it
        Journey__c myJour1 = new Journey__c();
        myJour1.Journey_Date__c = Date.today()+1;
        myJour1.CheckIn_Location__c = '28.5252114,76.2724069';
        myJour1.Mode_of_transport__c = 'Public';
        insert myJour1;
        // Creating first Event of the Journey myJour1
        event__C eventObject1  = new event__c();
        eventObject1.name = 'test';
        eventObject1.Start__c = system.now().addDays(-1);
        eventObject1.is_Automated__c = true;
        eventObject1.Journey__c = myJour1.id;
        insert eventObject1;
        eventList.add(eventObject1);
        
        for(event__c evt : eventList){
            DistanceCalculationApi.TotalArea(evt.id); // calling Class to test
            
        }
        
    }
}