/**
 * Description      :   Test class of EventContactTrigger and EventContactTriggerHelper
 * Release          :   15th Oct, 2024
 * JIRA Ticket		:	SAC-962	
 * Coverage			:
 * Revision Logs    :   V_1.0 - Created By - KR SANSI(IBM)
 * 
 **/
@isTest
public class EventContactTriggerTest {

    @testSetup
    public static void CreateData(){
        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Distance__c = 10; 
        objEve.Campaign__c = objCam.id;
        insert objEve;
        
        Event__c objEve1 = CommonDataTest.getEvent();      
        objEve1.Distance__c = 10; 
        objEve1.Campaign__c = objCam.id;
        objEve1.Parent_Event__c = objEve.id;
        insert objEve1;
        
        Contact objCon = CommonDataTest.getContact();
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.allowSave = true;
        objCon.LeadSource = 'Directory';
        objCon.Contact_State__c = 'Delhi';
        Database.insert(objCon, dmlOptions);

    }
    @isTest
    public static void updateContactTest(){
        
        Event__c  objEve = [SELECT Id FROM Event__c LIMIT 1];  
        Contact objCon = [SELECT Id FROM Contact LIMIT 1];
        Event_Contact__c eventContact = new Event_Contact__c();
        eventContact.Event__c = objEve.Id;
        eventContact.Contact__c = objCon.Id;
        
        Test.startTest();
        	insert eventContact;
        	update eventContact;
        	delete eventContact;
        Test.stopTest();
        
        
    }
     
    
}