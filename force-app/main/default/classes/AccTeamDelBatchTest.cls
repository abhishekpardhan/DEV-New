@isTest
public class AccTeamDelBatchTest {
    static testmethod void test1(){
    Account acc = CommonDataTest.getParentAccount();
        insert acc;
    Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;   
    Account acc1 = CommonDataTest.getSfxAccount();
        acc1.parentid = acc.id;
        acc1.Opportunity__c = objOpp.Id;
        insert acc1;
    User us = CommonDataTest.getUserBdm();
        us.isactive = false;
        insert us;
      //  update us;

            Account_Team__c accteam = new Account_Team__c();
            accteam.national1__c = false;
            accteam.national2__c = true;
            accteam.national3__c = false;
            accteam.national4__c = false;
            accteam.Relationship__c = false;
            accteam.Collection__c = false;
            accteam.Submission__c = true;
            accteam.CRS__c = false;
            accteam.NSM__c = false;
            accteam.Account__c = acc1.Id;
            accteam.BDM__c=us.Id;
            insert accteam;
         
        Test.startTest();
       			AccTeamDelBatch obj = new AccTeamDelBatch();
                String sch = '0 0 23 * * ?';
       			system.schedule('Test status Check', sch, obj);
        Test.stopTest();
    }
}