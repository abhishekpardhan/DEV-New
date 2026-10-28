/**
* Description		:	Test class for class:AddressCalculationQueueable
* Created By       :       Raghav, IBM
* Created Date     :       13th, Feb, 2024
* Release          :       
* Last Modified on :      13th, Feb, 2024
* Jira Ticket      :     https://safexpress.atlassian.net/browse/SAC-364
**/
@IsTest
private class AddressCalculationQueueableTest {
    
    @IsTest static void testAddressCalculationQueue(){
        Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper()); // Calling the mock(fake) responce to check api callout
        
        //List<Journey__c> journeyList = new List<Journey__c>();        
        Journey__c myJour = new Journey__c();
        myJour.Journey_Date__c = Date.today();
        myJour.CheckIn_Location__c = '28.5252114,76.2724069';
        myJour.CheckOut_Location__c ='28.686273800000002,77.2217831';
        myJour.Mode_of_transport__c = 'Public';
        //journeyList.add(myJour);
        insert myJour;
        // Creating an existing event for the journey myJour
        event__C eventObject  = new event__c();
        eventObject.name = 'test';
        eventObject.Start__c = system.now().addDays(-1);
        eventObject.is_Automated__c = true;
        eventObject.CheckIn_Location__c = '28.5252114,76.2724069';
        eventObject.CheckOut_Location__c ='28.686273800000002,77.2217831';
        eventObject.Journey__c = myJour.id;
        eventObject.CheckOut_Date__c = myJour.Journey_Date__c;
        insert eventObject;
        
        Test.startTest();
        System.enqueueJob(new AddressCalculationQueueable(null, myJour.Id, false, 'checkin' ));
        System.enqueueJob(new AddressCalculationQueueable(null, myJour.Id, false, 'checkout' ));
        System.enqueueJob(new AddressCalculationQueueable(eventObject.Id, null, false, 'checkin' ));
        System.enqueueJob(new AddressCalculationQueueable(eventObject.Id, null, false, 'checkout' ));
        Test.stopTest();
        
        
    } 
    @isTest 
    public static void testAddressCalculationQueueException(){
        
        Test.setMock(HttpCalloutMock.class, new mockRespoce()); // Calling the mock(fake) responce to check api callout
        
        //List<Journey__c> journeyList = new List<Journey__c>();        
        Journey__c myJour = new Journey__c();
        myJour.Journey_Date__c = Date.today(); 
        myJour.Mode_of_transport__c = 'Public';
        //journeyList.add(myJour);
        
        insert myJour;
        // Creating an existing event for the journey myJour
        event__c eventObject  = new event__c();
        eventObject.name = 'test';
        eventObject.Start__c = system.now().addDays(-1);
        eventObject.is_Automated__c = true; 
        eventObject.Journey__c = myJour.id;
        eventObject.CheckOut_Date__c = myJour.Journey_Date__c;
        insert eventObject;
        
        Test.startTest();
        
        System.enqueueJob(new AddressCalculationQueueable(null, myJour.Id, false, 'checkin' ));
        System.enqueueJob(new AddressCalculationQueueable(null, myJour.Id, false, 'checkout' ));
        System.enqueueJob(new AddressCalculationQueueable(eventObject.Id, null, false, 'checkin' ));
        System.enqueueJob(new AddressCalculationQueueable(eventObject.Id, null, false, 'checkout' ));
        Test.stopTest();
        
    }
    
    class mockRespoce implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            //res.setStatus('OK');
            res.setStatusCode(400);
            //res.setBody('{"destination_addresses" : [ "Charkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, India" ],"origin_addresses" : [ "Unnamed Road, Shankar Vihar, New Delhi, Delhi 110037, Indi Charkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, IndiaCharkhi Dadri - Kanina Rd, Haryana 127306, Indiaa" ],"rows" : [{"elements" : [{"distance" : {"text" : "116 km","value" : 116244},"duration" : {"text" : "2 hours 35 mins","value" : 9303},"status" : "OK"}]}],"status" : "OK"}');
            return res;
        }
    }
    
}