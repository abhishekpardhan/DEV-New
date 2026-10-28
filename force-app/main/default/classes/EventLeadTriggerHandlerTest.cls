/**
 * Description		:		Test class for Event_Lead__c Trigger
 * 
 * Coverage			:		100%
 **/
@isTest
public class EventLeadTriggerHandlerTest {

    static testMethod void test1(){

        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Campaign__c = objCam.Id;
        insert objEve;
        
        Test.startTest();
        Event_Lead__c objEvLead = CommonDataTest.getEventLead();
        objEvLead.Customer_Type__c = 'Retail';
        objEvLead.Event__c = objEve.Id;
        objEvLead.Send_Sms__c = true;
        insert objEvLead;
        Test.setMock(HttpCalloutMock.class,new HttpCalloutMockClass());         
        Test.stopTest();
     
    }
    static testMethod void test2(){
        Opportunity__c opp = new Opportunity__c();
        opp.Customer_Type__c = 'NEW OPPORTUNITY';
        opp.Monthly_Potential_Air__c = 123456.90;
        opp.Monthly_Potential_Surface__c = 5436.75;
        insert opp;
        
        Account par = new Account();
        par.Name='TEST-PARENT';
        par.Composite_Key__c ='643001-SAFEX-12375';
        par.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        par.ParentId = null;
        par.Opportunity__c = opp.Id;
        insert par;
        
        Account acc = new Account();
        acc.Name='NON PRC PICKUP ACCOUNT';
        acc.Composite_Key__c ='643001-SAFEX-12345';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        acc.ParentId = par.Id;
        acc.Opportunity__c = opp.Id;
        insert acc;

        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        Event__c objEve = CommonDataTest.getEvent();
        objEve.Campaign__c = objCam.Id;
        insert objEve;
        Event_Lead__c objEvLead = CommonDataTest.getEventLead();
        objEvLead.Customer_Type__c = 'Pick Up';
        objEvLead.Event__c = objEve.Id;
        objEvLead.Send_Sms__c = false;
        insert objEvLead;

     
    }

}