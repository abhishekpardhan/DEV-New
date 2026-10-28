/**
 * Description		:		Test class for CasePushApi apex class
 * 
 * Coverage			:		82%
 **/
@isTest 
public class CasePushApiTest{

   
    static testMethod void testMethod1() {

       Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
                
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Account_Team__c  objAccTeam = CommonDataTest.getAccountTeam();
        objAccTeam.Account__c = objSfx .Id;
        objAccTeam.BDM__c = us.Id;
        objAccTeam.National1__c = true;
        objAccTeam.National4__c = true;
        insert objAccTeam;
                
        Case__c objCase = CommonDataTest.getCase('Operation Issues');
        objCase.Account__c  = objSfx.Id;
        objCase.Assigned_To__c = us.Id;
        objCase.Status__c = 'Active';
        objCase.Waybill_Numbers__c = '12345678';
        insert objCase;
        
        
        Test.startTest();
        CasePushApi objSubTask = new CasePushApi();
        String sch = '0 0 23 * * ?';
        
        Test.setMock(HttpCalloutMock.class,new HttpCalloutMockClass());         
        system.schedule('Test status Check', sch, objSubTask );
                
        CasePushApi objSubTask1 = new CasePushApi();
        Test.setMock(HttpCalloutMock.class,new HttpCalloutMockClass1 ());
        system.schedule('Test status Check1', sch, objSubTask1 );  
        Test.stopTest();
    }
    static testMethod void testMethod2() {

       Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
                
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Account_Team__c  objAccTeam = CommonDataTest.getAccountTeam();
        objAccTeam.Account__c = objSfx .Id;
        objAccTeam.BDM__c = us.Id;
        objAccTeam.National1__c = true;
        objAccTeam.National4__c = true;
        insert objAccTeam;
                
        Case__c objCase = CommonDataTest.getCase('Operation Issues');
        objCase.Account__c  = objSfx.Id;
        objCase.Assigned_To__c = us.Id;
        objCase.Status__c = 'Active';
        objCase.Waybill_Numbers__c = '12345678';
        insert objCase;
        
        
        Test.startTest();
        CasePushApi objSubTask = new CasePushApi();
        String sch = '0 0 23 * * ?';
            
        CasePushApi objSubTask1 = new CasePushApi();
        Test.setMock(HttpCalloutMock.class,new HttpCalloutMockClass1 ());
        system.schedule('Test status Check1', sch, objSubTask);  
        Test.stopTest();
    }    
}