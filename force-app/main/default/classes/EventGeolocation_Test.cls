/**
 * Description      :       Test class for EventGeolocation apex class
 * 
 * Coverage         :       75%
 **/
@isTest
public class EventGeolocation_Test {
    
    @isTest static void test1() {
        
        Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper()); // Calling mock(Fake) responce for API test
        
        
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
        
         
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Account__c = prc.id;
        objEve.contact__c = objCon.id;
     //   objEve.Status__c = 'Cancelled';
     //   objEve.Reason__c = 'Customer not available';
     //   objEve.Sub_Reason__c = 'Ok Tested';
        objEve.CheckIn_Date__c = null;
        objEve.Is_Claim__c = true;
        insert objEve;
    
        ApexPages.StandardController sc = new ApexPages.StandardController(objEve);
        EventGeolocation testAccPlan = new EventGeolocation(sc);
        
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0266','checkin','20');
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut','20');
        
        
       // objEve.Status__c = 'Open';
       // update objEve;
        
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0288','checkin','30');
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut', '30');
        
        objEve.CheckIn_Date__c = System.now();
        update objEve;
        
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0299','checkin','40');
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut','40');
        
        objEve.Is_Claim__c = true;
        objEve.Event_Purpose__c = 'Existing Customer Meeting';
        objEve.Activities_to_be_Performed__c = 'BIR';
        objEve.Remarks__c = 'test';
        update objEve;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0211','checkin','50');
        
        
        
        objEve.CheckIn_Date__c = System.now();
        update objEve;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0222','checkOut','60');
        
        objEve.Remarks__c = 'Test';
        objEve.CheckOut_Date__c = null;
        update objEve;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut','70');
        
        objJ.CheckOut_Date__c = null;
        update objJ;
        
        objEve.Journey__c = objJ.Id;
        update objEve;
        
        Journey__c event = [Select Id,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,Journey_Date__c,
                            (Select Id ,Distance__c,Is_Claim__c from Events__r)
                            from Journey__C where Id =: objJ.Id];
        
        System.debug(event.Events__r.size());
        
        objEve.CheckOut_Date__c = System.now();
        objEve.CheckOut_Location__c = 'Gurgaon';
        update objEve;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0277','checkOut','100');
        
        objJ.CheckIn_Date__c = Date.today();
        update objJ;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0233','checkin','200');
        
        objJ.CheckIn_Date__c = null;
        objJ.CheckIn_Location__c = '';
        objJ.CheckOut_Date__c = null;
        objJ.CheckOut_Location__c = '';
        update objJ;
        objEve.CheckIn_Date__c = null;
        objEve.CheckIn_Location__c = '';
        objEve.CheckOut_Date__c = null;
        objEve.CheckOut_Location__c = '';
        update objEve;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0244','checkin','300');
        
        objJ.CheckIn_Date__c = null;
        objJ.CheckOut_Date__c = Date.today();
        update objJ;
        
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0255','checkin','400');
        
        objJ.CheckIn_Date__c = Date.today();
        objJ.CheckOut_Date__c = null;
        update objJ;
        
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.02101','checkin','500');
        
        objJ.CheckIn_Location__c = 'Gurgaon';
        update objJ;
        
        System.debug('Query-->' + [Select Id , CheckIn_Location__c FROM Journey__c where Id =:objJ.Id]);
        
        System.debug('objJ.Id---' + objJ.Id);
        
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.02102','checkin','600');
        
        delete objTask; 
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut','700');
        
        objTask = CommonDataTest.getGeneralTask();
        objTask.whatId = prc.id;
        insert objTask;
        
        List<EventGeolocation.TaskWrapper> lsttask = new List<EventGeolocation.TaskWrapper>();
        EventGeolocation.TaskWrapper objWrap = new EventGeolocation.TaskWrapper(objTask);
        objWrap.isSelected = true;
      //  objWrap.remarks = 'test';
        objWrap.objTask= objTask;
        lsttask.add(objWrap);
        testAccPlan.lstTaskWrapper = lstTask;
        testAccPlan.lat_long = 'test';
        String wrap = JSON.serialize(lsttask);
        testAccPlan.changeStatusTask();
        
        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        Event__c objEve1 = CommonDataTest.getEvent();
        objEve1.Campaign__c = objCam.Id;
        objEve1.CheckIn_Date__c = Date.today();
        objEve1.CheckOut_Date__c = Date.today();
        insert objEve1;
        
        
        EventGeolocation.eventLocation(objEve1.id, '28.4595','77.02121','checkin','150');
        
        objEve.Remarks__c = '';
        objEve.CheckIn_Date__c = Date.today();
        update objEve;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.0266','checkOut','250');
        
        
        objEve.Start__c = DateTime.now();
        objEve.is_Automated__c = true;
        System.debug('Status__c - - >' + objEve.Status__c);
        objEve.CheckIn_Date__c = null;
        objEve.Is_Claim__c = false;
        update objEve;
        //delete objJ;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.02121','checkin','350');
        
        objTask.Status = 'Completed';
        update objTask;
        
        objEve.Start__c = DateTime.now();
        objEve.is_Automated__c = true;
        System.debug('Status__c - - >' + objEve.Status__c);
        objEve.CheckIn_Date__c = null;
        objEve.Is_Claim__c = false;
        objEve.Journey__c = objJ.Id;
        update objEve;
        //delete objJ;
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.02121','checkOut','350');
        
    }
    
    @isTest static void test2() {
        Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper()); // Calling mock(Fake) responce for API test
        
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
        //insert objTask;
        
        Journey__c objJ = CommonDataTest.getJourney();
        insert objJ;
        
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
        Insert con;
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Account__c = prc.id;
        objEve.contact__c = con.id; 
        
        objEve.CheckIn_Date__c = System.now();
        objEve.Is_Claim__c = true;
        objEve.CheckOut_Date__c = null;
        objEve.Remarks__c = 'test1';
        insert objEve;
    
        ApexPages.StandardController sc = new ApexPages.StandardController(objEve);
        EventGeolocation testAccPlan = new EventGeolocation(sc);
         
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.02121','checkOut','350');
        
    }
    
    @isTest static void test3() {
        Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper()); // Calling mock(Fake) responce for API test
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
        //insert objTask;
        Journey__c objJ = new Journey__c();
        objJ.Journey_Date__c    = System.TODAY();
        objJ.CheckIn_Date__c = SYstem.TODAY();
        objJ.CheckIn_Location__c = '28.4595,77.0266';         
        objJ.Mode_of_transport__c = 'Public';
         
         
        insert objJ;
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Account__c = prc.id;
        objEve.contact__c = objCon.id; 
        objEve.CheckIn_Date__c = null;
        objEve.Is_Claim__c = true;
        objEve.CheckOut_Date__c = null;
        objEve.Remarks__c = 'test2';
        objEve.Journey__c =objJ.Id;
        objEve.Start__c = System.TODAY();
        objEve.End__c = System.TODAY();
        insert objEve;
    
        ApexPages.StandardController sc = new ApexPages.StandardController(objEve);
        EventGeolocation testAccPlan = new EventGeolocation(sc);
         
        EventGeolocation.eventLocation(objEve.id, '28.4595','77.02121','checkin','350');
        
    }
     @isTest static void test4() {
        Test.setMock(HttpCalloutMock.class, new mockRespoceCaseTriggerHelper()); // Calling mock(Fake) responce for API test
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
        //insert objTask;
        Journey__c objJ = new Journey__c();
        objJ.Journey_Date__c    = System.TODAY();
        objJ.CheckIn_Date__c = null;
        objJ.CheckIn_Location__c = '28.4595,77.0266';         
        objJ.Mode_of_transport__c = 'Public';
         
         
        insert objJ;
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Account__c = prc.id;
        objEve.contact__c = objCon.id; 
        objEve.CheckIn_Date__c = null;
        objEve.Is_Claim__c = true;
        objEve.CheckOut_Date__c = null;
        objEve.Remarks__c = 'test2';
        objEve.Journey__c =objJ.Id;
        objEve.Start__c = System.TODAY();
        objEve.End__c = System.TODAY();
        insert objEve;
    
        ApexPages.StandardController sc = new ApexPages.StandardController(objEve);
        EventGeolocation testAccPlan = new EventGeolocation(sc);
         
        EventGeolocation.eventLocation(objEve.id, null,null,'checkin','350');
        
    }
   

    
}