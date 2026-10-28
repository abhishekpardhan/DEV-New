/**
 * Description		:		Test class for PortfolioDataPush apex class
 * 
 * Coverage			:		79%
 **/
@isTest
private class PortfolioDataPushTest{
    Static TestMethod  void testMethos1(){
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(60);
        insert objSfx;
        
        Account objPrc = CommonDataTest.getPrcAccount();
        objPrc.parentID = objPro.Id;
        objPrc.Opportunity__c = objOpp.Id;
        insert objPrc;
           
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.whatId = objSfx.id;
        objTask.Automation__c = true;
        insert objTask;
        
        User usAM = CommonDataTest.getUserAM();
        insert usAM;
        
        User us =  CommonDataTest.getUserBdm();
        insert us;
        
        checkRecursive.firstRun = true;
        Account_Team__c accteam = new Account_Team__c();
        accteam.National1__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c  = true;
        accteam.Collection__c = true;
        accteam.National2__c = false;
        accteam.National3__c = true;
        accteam.Submission__c = true;   
        Database.SaveResult result = Database.insert(accteam);
        
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(true, accteam.Relationship__c);
        
        checkRecursive.firstRun = true;
        accteam.National1__c = false;
        accteam.Relationship__c  = false;
        accteam.Collection__c = false;
        accteam.National2__c = true;
        accteam.National3__c = false;
        accteam.Submission__c = false;  
        Database.SaveResult uResult = Database.update(accteam);
        
        System.assert(uResult.isSuccess());
        System.assert(uResult.getErrors().size() == 0);
        System.assertEquals(false, accteam.Relationship__c);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new HttpCalloutMockClass ());
        PortfolioDataPush.sendAccountTeam();                 
        Test.stopTest();
        
    }
}