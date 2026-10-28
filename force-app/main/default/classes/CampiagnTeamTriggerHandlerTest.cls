/**
 * Description		:		Test class for Campaign Team Trigger
 * 
 * Coverage			:		92%
 **/
@isTest
public class CampiagnTeamTriggerHandlerTest{

    static testMethod void test1(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;
        Campaign_Team__c objCamTeam = new Campaign_Team__c();
        objCamTeam.BDM__c = us.Id;
        objCamTeam.Campaign__c = objCam.Id;
        objCamTeam.Department__c = 'Account Manager - Manages Credit Customers';
        insert objCamTeam;
        User usAm = CommonDataTest.getUserAM();
        insert usAm;
        objCamTeam.BDM__c = usAm.Id;
        update objCamTeam;
        delete objCamTeam;
    }

}