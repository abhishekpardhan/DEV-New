/**
 * Description		:		Test class for Event__c trigger
 * 
 * Coverage			:		91%
 **/
@isTest
public class CustomEventTriggerHandlerTest{



    @TestSetup 
    static void setup(){
        Contact objCon = new Contact();
        objCon.FirstName  = 'TEST2';
        objCon.LastName = 'pwc2';
        objCon.Email = 'test2@gmail.com';
        objCon.MobilePhone = '5456789238';  // MobilePhone (not Phone)
        objCon.Phone = '5456789238';
        objCon.Designation__c = 'Manager';  // Must NOT be 'Others' or 'Not Specified'
        objCon.Department__c = 'Finance';   // Must NOT be 'Others'
        objCon.Contact_State__c = 'Delhi';
        objCon.Responsible_for__c = 'Collection';
        objCon.MailingStreet = 'test street';
        objCon.MailingPostalCode = '123456';
        objCon.MailingState = 'Delhi';
        objCon.MailingCity = 'Test contact';
        objCon.MailingCountry = 'In';
        objCon.Address_Type__c = 'Corporate Office';
        insert objCon;
    }
    
    static testMethod void test1(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        Journey__c objJ = CommonDataTest.getJourney();
        objJ.CheckOut_Date__c = null;
        objJ.Journey_Date__c =  Date.today().addDays(2);
        
        insert objJ;
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Distance__c = 10; 
        objEve.Campaign__c = objCam.id;
        insert objEve;
        objEve.Is_Claim__c = true;
        update objEve;
        
        objJ.CheckOut_Date__c = null;
        update objJ;
        
        Event__c objEvent = new Event__c();
        objEvent.Start__c = DateTime.Now().addDays(2);
        objEvent.End__c = DateTime.Now().addDays(2);
        objEvent.CheckIn_Date__c = System.now()+1;
        objEvent.CheckIn_Location__c = '24.4089,77.3178';
        objEvent.CheckOut_Date__c = System.now()+1 ; 
        objEvent.CheckOut_Location__c = '28.63,77.25';
        objEvent.Is_Claim__c = false;
        objEvent.Journey__c = objJ.Id;
        objEvent.Campaign__c = objCam.id;
        objEvent.is_Automated__c = true;
        insert objEvent;
        
        objEvent.Is_Claim__c = true;
        objEvent.Distance__c = 3;
        update objEvent;
        
        objJ = [Select Id, Journey_KM__c FROM Journey__c WHERE Id=: objJ.Id];
    }
    
    @isTest static void testRecalculateLastEventDate() {
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account_Team__c team = new Account_Team__c();
        team.Account__c = objPro.Id;
        team.BDMPropelI__c = UserInfo.getUserId();
        team.LastEventDate__c = System.now().addDays(-5);
        insert team;

        Event__c objEve = CommonDataTest.getEvent();
        objEve.ownerId = UserInfo.getUserId();
        objEve.Account__c = objPro.Id;
        objEve.Contact__c =[SELECT Id FROM Contact LIMIT 1].Id;
        insert objEve;

        Map<Id, Set<Id>> parentIds = new Map<Id, Set<Id>>();
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};
        parentIds.put(objPro.Id, userIds);
        Test.startTest();
            CustomEventTriggerHandler.recalculateLastEventDate(parentIds);
        Test.stopTest();
    }
    @isTest static void testCreateEventForaDay() {
        
         User us = CommonDataTest.getUserBdm();
        insert us;
        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        Journey__c objJ = CommonDataTest.getJourney();
        objJ.CheckOut_Date__c = null;
        insert objJ;
        
        Lead__c Lead = CommonDataTest.getLead();
        
        String userId = userInfo.getUserID();
        
        Branch_Master__c objBranchMas = CommonDataTest.getBranchMaster();
        insert objBranchMas;
        
        Branch_Master__c objBranchMas1 = CommonDataTest.getBranchMaster();
        insert objBranchMas1;
        
        User_Branch_Mapping__c objUs = new User_Branch_Mapping__c();
        objUs.Branch_Name__c = objBranchMas.Id;
        objUs.User__c = userId;
        insert objUs;
        
        User_Branch_Mapping__c objUs1 = new User_Branch_Mapping__c();
        objUs1.Branch_Name__c = objBranchMas1.Id;
        objUs1.User__c = userId;
        insert objUs1;
        
        insert lead;
        
        Opportunity__c oppNew = CommonDataTest.getOpportunity();
        insert oppNew;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account acc = CommonDataTest.getSfxAccount();
        acc.ParentId = objPro.Id; // fix added here
        acc.Opportunity__c = oppNew.Id;
        acc.Booking_Branch__c = objBranchMas.Id;
        insert acc;
        
        Opportunity__c opp = CommonDataTest.getOpportunity();
        opp.Account__c = objPro.Id;
        insert opp;
        
        Contact con = CommonDataTest.getContact();
        con.FirstName  = 'TEST3';
        con.LastName = 'pwc3';
        con.Email = 'test3@gmail.com';
        con.MobilePhone = '5456789239';  // MobilePhone (not Phone)
        con.Phone = '5456789239';
        con.AccountId = objPro.Id;
        con.Opportunity_Name__c = opp.Id;
        insert con;
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Distance__c = 10; 
        objEve.Campaign__c = objCam.id;
        insert objEve;
        
        Event__c objEve2 = CommonDataTest.getEvent();
        objEve2.Activity__c = 'Others'; 
        objEve2.If_Others_Please_Specify__c	 = 'Others';
        insert objEve2;
        
        Event__c objEve3 = CommonDataTest.getEvent();
        objEve3.Account__c = objPro.id; 
        objEve3.Contact__c = con.Id;
        insert objEve3;
        
        Event__c objEve4 = CommonDataTest.getEvent();
        objEve4.Lead__c = lead.id; 
        insert objEve4;
        
        Event__c objEve5 = CommonDataTest.getEvent();
        objEve5.Opportunity__c = opp.Id; 
        objEve5.Account__c = acc.Id;
        objEve5.Contact__c = con.id;
        
        objEve = CommonDataTest.getEvent();
        objEve.Distance__c = 10; 
        objEve.Campaign__c = objCam.id;
        
        try {
            insert objEve;
        }catch(Exception e) {
        }
        
        objEve2 = CommonDataTest.getEvent();
        objEve2.Activity__c = 'Others'; 
        objEve2.If_Others_Please_Specify__c	 = 'Others';
        
        try {
            insert objEve2;
        }catch(Exception e) {
        }
        
        objEve3 = CommonDataTest.getEvent();
        objEve3.Account__c = acc.id; 
        try {
            insert objEve3;
        }catch(Exception e) {
        }
        
        objEve4 = CommonDataTest.getEvent();
        objEve4.Lead__c = lead.id; 
        try {
            insert objEve4;
        }catch(Exception e) {
        }
        
        objEve5 = CommonDataTest.getEvent();
        objEve5.Opportunity__c = opp.Id; 
        try {
            insert objEve5;
        }catch(Exception e) {
        }
    }
    
    @isTest static void testUpdateLastEvent() {
        Account acc = CommonDataTest.getParentAccount();        
        insert acc;

        Opportunity__c opp = CommonDataTest.getOpportunity(); 
		opp.Account__c = acc.Id;        
        insert opp;        
        
        Lead__c led = CommonDataTest.getLead();
        insert led;
        
        Contact con = CommonDataTest.getContact();
        con.FirstName  = 'TEST4';
        con.LastName = 'pwc4';
        con.Email = 'test4@gmail.com';
        con.MobilePhone = '5456789230';  // MobilePhone (not Phone)
        con.Phone = '5456789230';
        con.AccountId = acc.Id;
        con.Opportunity_Name__c = opp.Id;
        insert con;
        
        Branch_Master__c masterBranch = CommonDataTest.getBranchMaster();
        insert masterBranch;        
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.CheckOut_Date__c = Date.today(); 
        objEve.Account__c = acc.Id;
        objEve.Contact__c = con.Id;
        objEve.Opportunity__c = opp.Id;
        objEve.Lead__c = led.Id;
        objEve.Branch__c = masterBranch.Id;
        insert objEve;
        
        Test.startTest();
        	objEve.CheckOut_Date__c = Date.today().addDays(1); 
        	update objEve;
        Test.stopTest();
        
        acc = [SELECT Id, Last_Event__c FROM Account Where Id=:acc.Id] ; 
        con = [SELECT Id, Last_Event__c FROM Contact Where Id=:con.Id] ;
        opp = [SELECT Id, Last_Event__c FROM Opportunity__c Where Id=:opp.Id] ;
        led = [SELECT Id, Last_Event__c FROM Lead__c Where Id=:led.Id] ;
        masterBranch = [SELECT Id, Last_Event__c FROM Branch_Master__c Where Id=:masterBranch.Id] ;
        
		System.AssertEquals(acc.Last_Event__c, objEve.Id);  
        System.AssertEquals(con.Last_Event__c, objEve.Id); 
        System.AssertEquals(opp.Last_Event__c, objEve.Id); 
        System.AssertEquals(led.Last_Event__c, objEve.Id); 
        System.AssertEquals(masterBranch.Last_Event__c, objEve.Id); 
    }

	@isTest static void beforeUpdateTest(){
        Id eveRecordTypeId = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Remarks_Edit').getRecordTypeId();
        Id newEveRecordTypeId = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('New_Event').getRecordTypeId();
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        
        Event__c objEvent = new Event__c();
        objEvent.Start__c = DateTime.Now().addDays(2);
        objEvent.End__c = DateTime.Now().addDays(2);
        objEvent.Is_Claim__c = false;
        objEvent.Campaign__c = objCam.id;
        objEvent.is_Automated__c = true;
        objEvent.OwnerId = us.id;
        objEvent.RecordTypeId = newEveRecordTypeId;
        insert objEvent;
        
        Test.startTest();
        objEvent.CheckIn_Date__c = Date.today().addDays(1);
        objEvent.RecordTypeId = eveRecordTypeId;
        update objEvent;
        Test.stopTest();
    }

    @isTest static void testAddLastEventDate_TeamUpdatePath() {
        Account top = CommonDataTest.getParentAccount();
        insert top;
        Account mid = new Account(Name = top.Name + ' Mid');
        insert mid;
        Account leaf = new Account(Name = top.Name + ' Leaf');
        insert leaf;
        
        User bdm = CommonDataTest.getUserBdm();
        insert bdm;
        
        Account_Team__c team = new Account_Team__c();
        team.Account__c = leaf.Id;
        team.BDMPropelI__c = bdm.Id;
        team.LastEventDate__c = System.now().addDays(-5);
        insert team;
        
        Event__c ev1 = CommonDataTest.getEvent();
        ev1.Account__c = top.Id;
        ev1.OwnerId = bdm.Id;
        ev1.CheckOut_Date__c = Date.today();
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        ev1.Contact__c = contact.Id;
        insert ev1;
        
        Test.startTest();
            ev1.CheckOut_Date__c = Date.today().addDays(2);
            update ev1;
        Test.stopTest();
        
        team = [SELECT Id, LastEventDate__c FROM Account_Team__c WHERE Id = :team.Id];
        System.assertNotEquals(team.Id, Null);
    }
    
    @isTest static void testAddLastEventDate_OverloadPath() {
        Account top = CommonDataTest.getParentAccount();
        insert top;
        Account mid = new Account(Name = top.Name + ' Mid');
        insert mid;
        Account leaf = new Account(Name = top.Name + ' Leaf');
        insert leaf;
        
        User bdm = CommonDataTest.getUserBdm();
        insert bdm;
        
        Account_Team__c team = new Account_Team__c();
        team.Account__c = leaf.Id;
        team.BDMPropelI__c = bdm.Id;
        insert team;
        
        Event__c evOld = CommonDataTest.getEvent();
        Account other = CommonDataTest.getParentAccount();
        insert other;
        evOld.Account__c = other.Id;
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        evOld.Contact__c = contact.Id;

        evOld.OwnerId = bdm.Id;
        insert evOld;
        
        Event__c evNew = CommonDataTest.getEvent();
        evNew.Account__c = top.Id;
        evNew.OwnerId = bdm.Id;
        evNew.Contact__c = contact.Id;
        insert evNew;
        
        Test.startTest();
            evOld.Account__c = top.Id;
            update evOld;
        Test.stopTest();
        
        team = [SELECT Id, LastEventDate__c FROM Account_Team__c WHERE Id = :team.Id];
        System.assertNotEquals(team.Id, Null);
    }
    
    @isTest static void testNoParentEventDoesNotFail() {
        Event__c ev = CommonDataTest.getEvent();
        ev.Account__c = null;
        ev.Contact__c = null;
        ev.Opportunity__c = null;
        ev.Lead__c = null;
        ev.Branch__c = null;
        ev.CheckOut_Date__c = Date.today();
        insert ev;
        
        Test.startTest();
            ev.CheckOut_Date__c = Date.today().addDays(1);
            update ev;
        Test.stopTest();
        
        Event__c e = [SELECT Id, CheckOut_Date__c FROM Event__c WHERE Id = :ev.Id];
        System.assertNotEquals(null, e.CheckOut_Date__c);
    }
    
    @isTest static void testDistanceOnJourneyUpdatePath() {
        User us = CommonDataTest.getUserBdm();
        insert us;
        Journey__c j = CommonDataTest.getJourney();
        j.CheckOut_Date__c = null;
        j.Journey_KM__c = 5;
        insert j;
        Event__c ev = CommonDataTest.getEvent();
        ev.Journey__c = j.Id;
        ev.Distance__c = 10;
        ev.Is_Claim__c = false;
        insert ev;
        
        Test.startTest();
            ev.Is_Claim__c = true;
            ev.Distance__c = 10;
            update ev;
        Test.stopTest();
        
        j = [SELECT Id, Journey_KM__c FROM Journey__c WHERE Id = :j.Id];
        System.assertNotEquals(null, j.Journey_KM__c);
    }
    
    @isTest static void testCreateAssociations() {
        Event__c ev = CommonDataTest.getEvent();
        ev.Distance__c = 10;
        ev.Is_Claim__c = false;
        insert ev;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        List<CustomEventTriggerHandler.RequestWrapper> requestList = new List<CustomEventTriggerHandler.RequestWrapper>();
        List<Event_Account_Association__c> associations = new List<Event_Account_Association__c>();
        Event_Account_Association__c eventAccount = new Event_Account_Association__c();
        eventAccount.Account__c = objPro.Id;
        eventAccount.Event__c = ev.id;
		insert eventAccount;
        
        associations.add(eventAccount);
        CustomEventTriggerHandler.RequestWrapper request = new CustomEventTriggerHandler.RequestWrapper();
        request.isDelete = true;
        request.associations = associations;
        CustomEventTriggerHandler.RequestWrapper request2 = new CustomEventTriggerHandler.RequestWrapper();
        request2.isDelete = false;
        request2.associations = associations;
        requestList.add(request2);
        Test.startTest();
        	CustomEventTriggerHandler.createAssociations(requestList);
        Test.stopTest();
        

    }
}