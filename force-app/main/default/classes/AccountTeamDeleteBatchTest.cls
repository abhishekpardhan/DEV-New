/**
 * Description		:		Test class for AccountTeamDeleteBatch apex class
 * 
 * Coverage			:		86%
 **/
@isTest 
public class AccountTeamDeleteBatchTest{
    static testMethod void testMethod1() {
        User us = CommonDataTest.getUserBdm();
        insert us;
        System.runAs(us){
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
            
            Opportunity__c objOpp = CommonDataTest.getOpportunity();
            insert objOpp;
            
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;
    
            Account objSfx = CommonDataTest.getSfxAccount();
            objSfx.parentID = objPro.Id;
            objSfx.Opportunity__c = objOpp.Id;
            objSfx.Booking_Branch__c = objBranchMas.Id;
            insert objSfx;
            
            /*
            User us1 = CommonDataTest.getUserBdm();
            insert us1;
    
            User us3 = CommonDataTest.getUserBdm();
            insert us3;
            */
            Account_Team__c accteam = new Account_Team__c();
            accteam.national1__c = false;
            accteam.national2__c = false;
            accteam.national3__c = false;
            accteam.national4__c = false;
            accteam.Relationship__c = false;
            accteam.Collection__c = false;
            accteam.Submission__c = false;
            accteam.CRS__c = false;
            accteam.NSM__c = false;
            accteam.Account__c = objSfx.Id;
            accteam.BDM__c=us.Id;
            insert accteam;
            
            accteam.NSM__c = false;
            update accteam;
            
            Test.setCreatedDate(accteam.id, System.now().addMonths(-1));
            Test.startTest();
                AccountTeamDeleteBatch  obj = new AccountTeamDeleteBatch ();
                Database.executeBatch(obj);
            
            obj.execute(null);
            Test.stopTest();
        }
    }
}