/**
 * Description		:		Test class for Account Trigger
 * 
 * Coverage			:		89%
 **/
@isTest 
public class AccountTriggerHelperTest{
    static testMethod void testMethod1() {
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;
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
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        User us1 = CommonDataTest.getUserBdm();
        insert us1;

        User us3 = CommonDataTest.getUserBdm();
        insert us3;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.national1__c = true;
        accteam.national2__c = true;
        accteam.national3__c = true;
        accteam.national4__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
        
        Account_Team__c accteam1 = new Account_Team__c();
        accteam1.national2__c = true;
        accteam1.national3__c = true;
        accteam1.national4__c = true;
        accteam1.Account__c = objSfx.Id;
        accteam1.BDM__c=us1.Id;
        insert accteam1;
        
        Account_Team__c accteam2 = new Account_Team__c();
        accteam2.national3__c = true;
        accteam2.national4__c = true;
        accteam2.Account__c = objSfx.Id;
        accteam2.BDM__c=us3.Id;
        insert accteam2;
        
        Account objSfx1 = CommonDataTest.getSfxAccount();
        objSfx1.parentID = objPro.Id;
        objSfx1.Opportunity__c = objOpp.Id;
        objSfx1.Booking_Branch__c = objBranchMas.Id;
        insert objSfx1;
        
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.Branch__c = objBranchMas.Id;
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.Automation__c = true;
        objTask.whatId = objSfx.id;
        //objTask.Type__c ='RENEWEL ACCOUNT';
        insert objTask;
        
        objPrc1.Branch__c =  objBranchMas1.Id;
        update objPrc1;
        
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(70);
        update objSfx;
    }
    
    static testMethod void testMethod2() {
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        Id rSfxId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        Id ractualsfxId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();

		cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;
        
        String userId = userInfo.getUserID();
        
        Branch_Master__c objBranchMas = CommonDataTest.getBranchMaster();
        objBranchMas.Branch_Type__c = 'ARM';
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
        
        Account objProParent = CommonDataTest.getParentAccount();
        insert objProParent;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
		Account objPro = CommonDataTest.getParentAccount();
        objPro.RecordTypeId = rId;
        objPro.Opportunity__c = objOpp.Id;
        objPro.ParentId = objProParent.Id;
        objPro.Propel_MSACode__c = 'MSA00008417';
        insert objPro;
	
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Booking_Branch__c = objBranchMas.Id;
        objSfx.RecordTypeId = ractualsfxId;
        insert objSfx;
        
        Account objRate = CommonDataTest.getRateCardAccount();
        objRate.parentID = objPro.Id;
        objRate.Opportunity__c = objOpp.Id;
        objRate.Booking_Branch__c = objBranchMas.Id;
       // objRate.RecordTypeId = rRateId;
        insert objRate;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        User us1 = CommonDataTest.getUserBdm();
        insert us1;

        User us3 = CommonDataTest.getUserBdm();
        insert us3;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.national1__c = true;
        accteam.national2__c = true;
        accteam.national3__c = true;
        accteam.national4__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
        
        Account_Team__c accteam1 = new Account_Team__c();
        accteam1.national2__c = true;
        accteam1.national3__c = true;
        accteam1.national4__c = true;
        accteam1.Account__c = objSfx.Id;
        accteam1.BDM__c=us1.Id;
        insert accteam1;
        
        Account_Team__c accteam2 = new Account_Team__c();
        accteam2.national3__c = true;
        accteam2.national4__c = true;
        accteam2.Account__c = objSfx.Id;
        accteam2.BDM__c=us3.Id;
        insert accteam2;
        
        Account objSfx1 = CommonDataTest.getSfxAccount();
        objSfx1.parentID = objPro.Id;
        objSfx1.Opportunity__c = objOpp.Id;
        objSfx1.Booking_Branch__c = objBranchMas.Id;
        insert objSfx1;
        
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.Branch__c = objBranchMas.Id;
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.Automation__c = true;
        objTask.whatId = objSfx.id;
        //objTask.Type__c ='RENEWEL ACCOUNT';
        insert objTask;
        
        objPrc1.Branch__c =  objBranchMas1.Id;
        update objPrc1;
        
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(70);
        update objSfx;
        
        objRate.Name='test';
        update objRate;
    }
    
    static testMethod void testMethod5() {
            Account objProParent = CommonDataTest.getParentAccount();
            insert objProParent;
            Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
    
            Opportunity__c objOpp = CommonDataTest.getOpportunity();
            insert objOpp;
        
        	Account objPro = CommonDataTest.getParentAccount();
            objPro.RecordTypeId = rId;
            objPro.Opportunity__c = objOpp.Id;
            objPro.ParentId = objProParent.Id;
            objPro.Propel_MSACode__c = 'MSA00008417';
            insert objPro;
    		Test.startTest();
        	AccountTriggerHelper.createBDMMappingTeamFuture(new Set<Id>{objPro.Id});
        	Test.stopTest();
    }
    
    static testMethod void testMethod3() {
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        Id rSfxId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        

		cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;
        
        String userId = userInfo.getUserID();
        
        Branch_Master__c objBranchMas = CommonDataTest.getBranchMaster();
        insert objBranchMas;
        
        Branch_Master__c objBranchMas1 = CommonDataTest.getBranchMaster();
        objBranchMas1.Branch_Type__c = 'GBA';
        insert objBranchMas1;
        
        User_Branch_Mapping__c objUs = new User_Branch_Mapping__c();
        objUs.Branch_Name__c = objBranchMas.Id;
        objUs.User__c = userId;
        insert objUs;
        
        User_Branch_Mapping__c objUs1 = new User_Branch_Mapping__c();
        objUs1.Branch_Name__c = objBranchMas1.Id;
        objUs1.User__c = userId;
        insert objUs1;
        
        Account objProParent = CommonDataTest.getParentAccount();
        insert objProParent;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
		Account objPro = CommonDataTest.getParentAccount();
        objPro.RecordTypeId = rId;
        objPro.Opportunity__c = objOpp.Id;
        objPro.ParentId = objProParent.Id;
        objPro.Propel_MSACode__c = 'MSA00008417';
        insert objPro;
	
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Booking_Branch__c = objBranchMas1.Id;
        //objSfx.RecordTypeId = rSfxId;
        objSfx.National1__c = true;
        insert objSfx;
        
        Account objRate = CommonDataTest.getRateCardAccount();
        objRate.parentID = objPro.Id;
        objRate.Opportunity__c = objOpp.Id;
        objRate.Booking_Branch__c = objBranchMas.Id;
        objRate.Base_Location__c =  objBranchMas1.Id;
        //objRate.RecordTypeId = rRateId;
        insert objRate;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        User us1 = CommonDataTest.getUserBdm();
        insert us1;

        User us3 = CommonDataTest.getUserBdm();
        insert us3;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.national1__c = true;
        accteam.national2__c = true;
        accteam.national3__c = true;
        accteam.national4__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
        
        Account_Team__c accteam1 = new Account_Team__c();
        accteam1.national2__c = true;
        accteam1.national3__c = true;
        accteam1.national4__c = true;
        accteam1.Account__c = objSfx.Id;
        accteam1.BDM__c=us1.Id;
        insert accteam1;
        
        Account_Team__c accteam2 = new Account_Team__c();
        accteam2.national3__c = true;
        accteam2.national4__c = true;
        accteam2.Account__c = objSfx.Id;
        accteam2.BDM__c=us3.Id;
        insert accteam2;
        
        Account objSfx1 = CommonDataTest.getSfxAccount();
        objSfx1.parentID = objPro.Id;
        objSfx1.Opportunity__c = objOpp.Id;
        objSfx1.Booking_Branch__c = objBranchMas.Id;
        insert objSfx1;
        
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.Branch__c = objBranchMas.Id;
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.Automation__c = true;
        objTask.whatId = objSfx.id;
        //objTask.Type__c ='RENEWEL ACCOUNT';
        insert objTask;
        
        objPrc1.Branch__c =  objBranchMas1.Id;
        update objPrc1;
        
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(70);
        update objSfx;
        
        objRate.Name='test11';
        objRate.Base_Location__c = objBranchMas.Id;
        update objRate;
              
        
    }
}