@IsTest
public class EventDistanceCalcBatchTest {

    static Journey__c testJourney;
    static Event__c testEvent1, testEvent2;
	
    static testMethod void testMethod1()  {
        // Create test data
        Id recordsTypeJourney = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('New Journey').getRecordTypeId();
		Id recordsTypeEvent = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('New Event').getRecordTypeId();

        Journey__c objJ = new Journey__c();
		objJ.Journey_km__c =0.0;
		objJ.Mode_of_transport__c='Personal';
		//objJ.CheckOut_Date__c=Date.today();
		//objJ.CheckIn_Address__c='VC7W+PXV, Ratnas, Rajasthan 341501, India';
		//objJ.CheckIn_Location__c='28.4902343,77.0752419';
		//objJ.CheckOut_Address__c='';
		//objJ.CheckOut_Location__c='';
        objJ.RecordTypeId=recordsTypeJourney;
        insert objJ;

		List<Event__c> lstEvent = new List<Event__c>();
        Event__c objEve1 = CommonDataTest.getEvent();
        objEve1.Name = 'test Event1';
		objEve1.Journey__c =objJ.id;
		objEve1.Distance__c= 0.0;
		objEve1.RecordTypeId=recordsTypeEvent;
		objEve1.CheckOut_Date__c= Date.today();
		objEve1.CheckIn_Date__c= Date.today() -1;
		objEve1.CheckIn_Address__c='28, Sector 17, Gurugram, Haryana 122015, India';
		objEve1.CheckIn_Location__c='28.4902343,77.0752419';
		objEve1.CheckOut_Address__c='VC7W+PXV, Ratnas, Rajasthan 341501, India';
		objEve1.CheckOut_Location__c='26.8660528,74.4468838';
		objEve1.Event_Purpose__c='Associate Meeting';
		objEve1.Remarks__c= 'test';
        objEve1.Activities_to_be_Performed__c='ARM Associate Meeting';
        lstEvent.add(objEve1);
       // insert testEvent1;

        Event__c objEve2 = CommonDataTest.getEvent();
        objEve2.Name = 'test Event2';
      	objEve2.Journey__c =objJ.id;
		objEve2.Distance__c= 0.0;
		objEve2.Remarks__c= 'test';
		objEve2.CheckOut_Date__c= Date.today() -1;
		objEve2.CheckIn_Date__c= Date.today() -2;
		//objEve2.CheckIn_Address__c='28, Sector 18, Gurugram, Sarhol, Haryana 122015, India';
		//objEve2.CheckIn_Location__c='28.4902343,77.0752419';
		//objEve2.CheckOut_Address__c='';
		//objEve2.CheckOut_Location__c='';
		objEve2.Event_Purpose__c='Associate Meeting';
		objEve2.RecordTypeId=recordsTypeEvent;
        objEve2.Activities_to_be_Performed__c='ARM Associate Meeting';
        lstEvent.add(objEve2);
        
        Event__c objEve3 = CommonDataTest.getEvent();
        objEve3.Name = 'test3';
		objEve3.Journey__c =objJ.id;
		objEve3.Distance__c= 0.0;
		objEve3.CheckOut_Date__c= Date.today() -2;
		objEve2.CheckIn_Date__c= Date.today() -3;
		objEve3.CheckIn_Address__c='28, Sector 18, Gurugram, Sarhol, Haryana 122015, India';
		objEve3.CheckIn_Location__c='28.4902343,77.0752419';
		objEve3.CheckOut_Address__c='VC7W+PXV, Ratnas, Rajasthan 341501, India';
		objEve3.CheckOut_Location__c='26.8660528,74.4468838';
		objEve3.Event_Purpose__c='Associate Meeting';
		objEve3.Remarks__c= 'test';
		objEve3.RecordTypeId=recordsTypeEvent;
        objEve3.Activities_to_be_Performed__c='ARM Associate Meeting';
        lstEvent.add(objEve3);
        insert lstEvent;
		
				
        EventDistanceUpdateBatch objEveBatch = new EventDistanceUpdateBatch(true ,'SELECT Id FROM Journey__c');    
        Database.executeBatch(objEveBatch ,1);

		EventDistanceUpdateBatch objEveBatch1 = new EventDistanceUpdateBatch(false ,'SELECT Id FROM Journey__c');    
        Database.executeBatch(objEveBatch1 ,1);

		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper()); // Calling mock(Fake) responce for API test
        EventDistanceUpdateBatch.journeyArea(objJ.id);
        Test.stopTest();

		

    }

static testMethod void testMethod2()  {
        // Create test data
        Id recordsTypeJourney = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('New Journey').getRecordTypeId();
		Id recordsTypeEvent = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('New Event').getRecordTypeId();

        Journey__c objJ = new Journey__c();
		objJ.Journey_km__c =0.0;
		objJ.Mode_of_transport__c='Personal';
        objJ.RecordTypeId=recordsTypeJourney;
        insert objJ;

		List<Event__c> lstEvent = new List<Event__c>();
        Event__c objEve1 = CommonDataTest.getEvent();
        objEve1.Name = 'test Event1';
		objEve1.Journey__c =objJ.id;
		objEve1.Distance__c= 0.0;
		objEve1.RecordTypeId=recordsTypeEvent;
		//objEve1.CheckIn_Address__c='28, Sector 18, Gurugram, Sarhol, Haryana 122015, India';
		//objEve1.CheckIn_Location__c='28.4902343,77.0752419';
		//objEve1.CheckOut_Address__c='VC7W+PXV, Ratnas, Rajasthan 341501, India';
		//objEve1.CheckOut_Location__c='26.8660528,74.4468838';
		objEve1.Event_Purpose__c='Associate Meeting';
		objEve1.Remarks__c= 'test';
        objEve1.Activities_to_be_Performed__c='ARM Associate Meeting';
    	objEve1.CheckOut_Date__c = null;
        lstEvent.add(objEve1);
       // insert testEvent1;
         
        insert lstEvent;

		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper());
    
        EventDistanceCalculationApiQueueable objEveBatch = new EventDistanceCalculationApiQueueable(lstEvent);    
        System.enqueueJob(objEveBatch);
 
        Test.stopTest();

		

    }

	
}