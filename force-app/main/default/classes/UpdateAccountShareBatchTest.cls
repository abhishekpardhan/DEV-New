@isTest
public class UpdateAccountShareBatchTest {

    @isTest
    public static void testMethod1() {
        //Test.StartTest();
        List<Account_Team__c> newacteam = new List<Account_Team__c>();
        Map<Id,Account_Team__c> newacteamMap = new Map<Id,Account_Team__c>();
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        Branch_Master__c BMrec1 = CommonDataTest.getBranchMaster();
        BMrec1.Name = 'PANJIM-12';
        BMrec1.Branch_Code__c = 'PJI12';
        insert BMrec1;
        Account objPro = CommonDataTest.getParentAccount();
        objPro.Billing_Branch__c = BMrec1.Id;
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
        
        User usAM = CommonDataTest.getUserAM();
        insert usAM;
        
        User us =  CommonDataTest.getUserBdm();
        insert us;
        
        User_Branch_Mapping__c ubm = new User_Branch_Mapping__c();
        ubm.Branch_Name__c=BMrec1.id;
        ubm.User__c=us.id;
        insert ubm;
        
        Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
        
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true ;
        Account_Team__c accteam = new Account_Team__c();
        accteam.RecordTypeId = idProperIrecordType;
        accteam.National1__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.BDMPropelI__c = us.id;
        accteam.Relationship__c  = true;
        accteam.Collection__c = true;
        accteam.National2__c = false;
        accteam.National3__c = true;
        accteam.Submission__c = true; 
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id;
        Database.SaveResult result = Database.insert(accteam);
        newacteam.add(accteam);
        
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(true, accteam.Relationship__c);
         
        String query = 'SELECT Id, Shared_Account_Id__c, BDMPropelI__c,RecordTypeId, Account__c, National1__c, National2__c, National3__c, National4__c, CRS__c,Relationship__c, Collection__c, Submission__c  FROM Account_Team__c';
        Test.startTest();
        	UpdateAccountShareBatch obj  = new UpdateAccountShareBatch(query);
        	Database.executeBatch(obj);
        	obj.shareAccount(objPro.Id, UserInfo.getUserId());
        Test.stopTest();
        
    }
    
}