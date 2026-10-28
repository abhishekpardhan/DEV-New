/**
 * Description		:		Test class for GeolocationJourney apex class
 * Last Modified By :       Shubham Girdhar
 * Last Modified By :       26/8/2019
 * Coverage			:		80%
 * Release          :       Bug fix for release 22nd july 2019

 **/
@isTest
public class GeolocationJourney_Test { 

    @isTest static void test1() {
		
			 
				
        
            Journey__c objJ = CommonDataTest.getJourney();
        insert objJ;


        ApexPages.StandardController sc = new ApexPages.StandardController(objJ);
        GeolocationJourney testAccPlan = new GeolocationJourney(sc);
        
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkin','100');
        
        objJ.CheckIn_Date__c = Date.today();
        objJ.CheckOut_Date__c = null;
        update objJ;
        
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkin','100');
        
        objJ.CheckIn_Date__c = null;
        objJ.CheckOut_Date__c = null;
        update objJ;
        
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkin','100');
        
        
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut','100');
        
        objJ.CheckIn_Date__c = Date.today();
        objJ.CheckOut_Date__c = Date.today();
        update objJ;
        
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut','100');
        
        objJ.CheckOut_Date__c = null;
        update objJ;
        
        Event__c eve = CommonDataTest.getEvent();
        eve.CheckOut_Date__c = Date.today();
        eve.Journey__c = objJ.Id;
        eve.Activity__c = 'Others';
        eve.If_Others_Please_Specify__c = 'test';
        insert eve;
       
        
        System.debug('Queryyyy-->' + [Select Id,Start__c ,End__c ,CheckIn_Date__c ,CheckOut_Date__c,CheckOut_Location__c from Event__C where Journey__c =:objJ.Id and CheckOut_Date__c != null order by CheckOut_Date__c DESC limit 1]);
        
                GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checin','100');
         GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut','100');
       
//------Mock responce to api for test class added by Shubham Girdhar---------------
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse');
        mock.setStatusCode(200);
        mock.setStatus('OK');
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    }
   //--------------------------------------------------------------------------- 
    
   @isTest static void test2() {
		
			 
				
        
            Journey__c objJ = CommonDataTest.getJourney();
        insert objJ;


        ApexPages.StandardController sc = new ApexPages.StandardController(objJ);
        GeolocationJourney testAccPlan = new GeolocationJourney(sc);
        
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkin','100');
        
        objJ.CheckIn_Date__c = Date.today();
        objJ.CheckOut_Date__c = null;
        update objJ;
        
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkin','100');
        
        objJ.CheckIn_Date__c = null;
        objJ.CheckOut_Date__c = null;
        update objJ;
        
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkin','100');
        objJ.Journey_Date__c = Date.today();
        update objJ;
        GeolocationJourney.JourneyLocation(objJ.id, '28.4595','77.0266','checkin','100');
       
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse');
        mock.setStatusCode(200);
        mock.setStatus('OK');
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
         
    }
   
    
}