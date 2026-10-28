/**
 * Description      :       Test class for Geolocation apex class
 * 
 * Coverage         :       77%
 **/
@isTest
public class GeolocationTest{
    
    static testMethod void test1(){
        Account objParent = CommonDataTest.getParentAccount();
        insert objParent;
        Opportunity__c objOppc = CommonDataTest.getOpportunity();
        insert objOppc;
        Account prc = CommonDataTest.getPrcAccount();
        prc.name = 'NON PRC PICKUP ACCOUNT';
        prc.parentid= objParent.id;
        prc.opportunity__c = objOppc.id;
        insert prc;
        Contact objCon = CommonDataTest.getContact();
        objCon.Accountid = prc.id;
        insert objCon;
        User us = CommonDataTest.getUserBdm();
        insert us;
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.whatId = prc.id;
        insert objTask;
        
        
        Journey__c objJ = CommonDataTest.getJourney();
        insert objJ;
        
        Geolocation.eventLocation(objJ.id, '28.4595','77.0266','checkin');
        Geolocation.eventLocation(objJ.id, '28.4595','77.0266','checkOut');
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Account__c = prc.id;
        objEve.contact__c = objCon.id;
      //  objEve.Status__c = 'Cancelled';
      //  objEve.Reason__c = 'Customer not available';
        insert objEve;
        
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkin');
        
        objEve.CheckIn_Date__c = System.now();
        objEve.Status__c = 'Open';
        update objEve;
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkin');
        
        objEve.Is_Claim__c = true;
        update objEve;
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkin');
        
        objEve.CheckIn_Date__c = System.now();
        update objEve;
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut');
        
        objEve.Remarks__c = 'Test';
        objEve.CheckOut_Date__c = null;
        update objEve;
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut');

        objJ.CheckOut_Date__c = null;
        update objJ;
        
        objEve.Journey__c = objJ.Id;
        update objEve;
        
        Journey__c event = [Select Id,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,Journey_Date__c,
                                     (Select Id ,Distance__c,Is_Claim__c from Events__r)
                                     from Journey__C where Id =: objJ.Id];
        
        System.debug(event.Events__r.size());
        
        Geolocation.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut');
        Geolocation.JourneyLocation(objJ.id, '28.4595','77.0266','checkin');
        
        objEve.CheckOut_Date__c = System.now();
        objEve.CheckOut_Location__c = 'Gurgaon';
        update objEve;
        Geolocation.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut');
        
        objJ.CheckIn_Date__c = null;
        objJ.CheckIn_Location__c = '';
        objJ.CheckOut_Date__c = null;
        objJ.CheckOut_Location__c = '';
        update objJ;
        Geolocation.JourneyLocation(objJ.id, '28.4595','77.0266','checkin');    
        objEve.CheckIn_Date__c = null;
        objEve.CheckIn_Location__c = '';
        objEve.CheckOut_Date__c = null;
        objEve.CheckOut_Location__c = '';
        update objEve;
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkin');
        objEve.CheckOut_Date__c = null;
        objEve.CheckOut_Location__c = '';
        update objEve;
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut');
        Geolocation.getTask(objEve.id);
        List<Geolocation.TaskWrapper> lsttask = new List<Geolocation.TaskWrapper>();
        Geolocation.TaskWrapper objWrap = new Geolocation.TaskWrapper(objTask);
        objWrap.isSelected = true;
         // objWrap.remarks = 'test';
        objWrap.objTask= objTask;
        lsttask.add(objWrap);
        String wrap = JSON.serialize(lsttask);
        Geolocation.changeStatusTask(objEve.id,wrap ,'28.4595','77.0266');
        
    }
    static testMethod void test2(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        
        Journey__c objJ = CommonDataTest.getJourney();
        objJ.journey_Date__c = System.today()+1;
        insert objJ;
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Campaign__c = objCam.id;
        insert objEve;
        
        Geolocation.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut');
        objJ.CheckOut_Date__c = null;
        objJ.CheckOut_Location__c = '';
        update objJ;
        Geolocation.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut');
        
        /* Event__c objEve1 = CommonDataTest.getEvent();
objEve1.Campaign__c = objCam.id;
objEve1.CheckIn_Date__c = null;
objEve1.CheckIn_Location__c = '';
objEve1.CheckOut_Date__c = null;
objEve1.CheckOut_Location__c = '';
insert objEve1;

Geolocation.eventLocation(objEve1.id, '28.4595','77.0266','checkin');     */      
        
    }
    static testMethod void test3(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        
        Journey__c objJ = CommonDataTest.getJourney();
        objJ.CheckOut_Date__c = null;
        insert objJ;
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Campaign__c = objCam.id;
        objEve.CheckIn_Date__c = null;
        objEve.CheckIn_Location__c = '';
        objEve.CheckOut_Date__c = Date.today().addDays(2);
        objEve.CheckOut_Location__c = 'Gurgaon';
        objEve.Journey__c = objJ.Id;
        insert objEve;
        
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkin');            
        Geolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut');
        
        GeoLocation.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut');
        
        objEve.CheckOut_Location__c = 'Gurgaon';
        update objEve;
        
        GeoLocation.JourneyLocation(objJ.id, '28.4595','77.0266','checkOut');
        
        
    }
}