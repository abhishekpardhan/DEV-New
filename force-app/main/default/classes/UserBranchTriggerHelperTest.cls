@isTest 
public class UserBranchTriggerHelperTest {
    static testMethod void testMethod1() {
        Branch_Master__c objBranch = CommonDataTest.getBranchMaster();
        insert objBranch;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Account objPrc = CommonDataTest.getPrcAccount();
        objPrc.Branch__c = objBranch.Id;
        objPrc.parentID = objPro.Id;
        objPrc.Opportunity__c = objOpp.Id;
        insert objPrc;
        
        User_Branch_Mapping__c objusBranch =new User_Branch_Mapping__c();
        objusBranch.Branch_Name__c = objBranch.Id;
        objusBranch.User__c = us.id;
        insert objusBranch;
        
        Branch_Master__c objBranch1 = CommonDataTest.getBranchMaster();
        insert objBranch1;

        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.Branch__c = objBranch1.Id;
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        objusBranch.Branch_Name__c = objBranch1.Id;
        update objusBranch;     
        
        delete objusBranch;
    }
}