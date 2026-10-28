/**
 * Description		:		Test class for AccountContractDateBatch apex class
 * 
 * Coverage			:		76%
 **/
@isTest 
public class AccountContractDateBatchTest {
    
    static testMethod void testMethod1() {
    
        Contact objCon = CommonDataTest.getContact();
        insert objCon;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Datetime yesterday = Datetime.now().addMonths(-6);
        Test.setCreatedDate(objPro.Id, yesterday);
        
        Account objAcc = [Select id , Remove_Nsm_For_Sfx_Account_Date_Cal__c from Account where id =: objPro.Id limit 1];
        
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(60);
        insert objSfx;
        
        Account objSfx1 = CommonDataTest.getSfxAccount();
        objSfx1.parentID = objPro.Id;
        objSfx1.Opportunity__c = objOpp.Id;
        objSfx1.Contract_Expiry_Date__c = System.Today().addDays(30);
        insert objSfx1;
  
        User usAM = CommonDataTest.getUserAM();
        insert usAM;
        
        User us = CommonDataTest.getUserBdm();
        us.ManagerId = usAM.Id;
        insert us;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.Relationship__c = true;
        accteam.National1__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
        
        Account_Team__c accteam1 = new Account_Team__c();
        accteam1.Relationship__c = true;
        accteam1.Account__c = objSfx1.Id;
        accteam1.National1__c = true;
        accteam1.BDM__c=us.Id;
        insert accteam1;
        
        Test.startTest();
        AccountContractDateBatch objAccCon = new AccountContractDateBatch();    
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, objAccCon );
        Test.stopTest();
    }   
}