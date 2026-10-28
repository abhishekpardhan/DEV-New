/**
* Description      :       Test class for Account_Team__c Trigger
* 
* Coverage         :       92%
**/
@isTest 
public class helperAccountTeamTest{
    
    
    static testMethod void testMethod11() {
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
        String rcRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.RecordTypeId = rcRecordTypeId;
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
        
        checkRecursive.firstRun = true;
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true ;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.National1__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.BDMPropelI__c = us.id;
        accteam.Relationship__c  = true;
        accteam.Collection__c = true;
        accteam.National2__c = false;
        accteam.National3__c = true;
        accteam.National4__c = true;
        accteam.Submission__c = true; 
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id;
        Database.SaveResult result = Database.insert(accteam);
        newacteam.add(accteam);
        
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
        accteam.BDMPropelI__c=usAM.id;
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id+'0';
        Database.SaveResult uResult = Database.update(accteam);
        newacteamMap.put(accteam.Id,accteam);
        
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.whatId = objSfx.id;
        objTask.Automation__c = true;
        insert objTask;
        trg_AccountTeamHelper.afterUpdate(newacteam, newacteamMap);
        
        System.assert(uResult.isSuccess());
        System.assert(uResult.getErrors().size() == 0);
        System.assertEquals(false, accteam.Relationship__c);
        
        accteam = [SELECT Id, Account__c, BDMPropelI__c, Account__r.Parent.Parent.Id 
                   FROM Account_Team__c WHERE Id =: accteam.Id];
         helperAccountTeam.createAccountShareSfx(accteam);
        helperAccountTeam.syncBDMWithAccountTeam(new List<Account_Team__c>{accteam});
        
        helperAccountTeam.createAccountShare(objSfx.Id, ubm.Id);
        //Test.stopTest();
    }
    
    static testMethod void testMethod1() {
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
        
        checkRecursive.firstRun = true;
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true ;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.National1__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.BDMPropelI__c = us.id;
        accteam.Relationship__c  = true;
        accteam.Collection__c = true;
        accteam.National2__c = false;
        accteam.National3__c = true;
        accteam.National4__c = true;
        accteam.Submission__c = true; 
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id;
        Database.SaveResult result = Database.insert(accteam);
        newacteam.add(accteam);
        
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
        accteam.BDMPropelI__c=usAM.id;
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id+'0';
        Database.SaveResult uResult = Database.update(accteam);
        newacteamMap.put(accteam.Id,accteam);
        
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.whatId = objSfx.id;
        objTask.Automation__c = true;
        insert objTask;
        trg_AccountTeamHelper.afterUpdate(newacteam, newacteamMap);
        
        System.assert(uResult.isSuccess());
        System.assert(uResult.getErrors().size() == 0);
        System.assertEquals(false, accteam.Relationship__c);
        
        accteam = [SELECT Id, Account__c, BDMPropelI__c, Account__r.Parent.Parent.Id 
                   FROM Account_Team__c WHERE Id =: accteam.Id];
         helperAccountTeam.createAccountShareSfx(accteam);
        helperAccountTeam.syncBDMWithAccountTeam(new List<Account_Team__c>{accteam});
        
        helperAccountTeam.createAccountShare(objSfx.Id, ubm.Id);
        //Test.stopTest();
    }
    
    
    static testMethod void testMethod2() {
        //Test.startTest();
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
        
        Account objSfx1 = CommonDataTest.getSfxAccount();
        objSfx1.parentID = objPro.Id;
        objSfx1.Opportunity__c = objOpp.Id;
        objSfx1.Contract_Expiry_Date__c = System.Today().addDays(60);
        insert objSfx1;
        
        Account objPrc = CommonDataTest.getPrcAccount();
        objPrc.parentID = objPro.Id;
        objPrc.Opportunity__c = objOpp.Id;
        insert objPrc;
        
        User usAM = CommonDataTest.getUserAM();
        insert usAM;
        
        User us =  CommonDataTest.getUserBdm();
        us.ManagerId = usAM.Id;
        insert us;
        
        User_Branch_Mapping__c ubm = new User_Branch_Mapping__c();
        ubm.Branch_Name__c=BMrec1.id;
        ubm.User__c=us.id;
        insert ubm;
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true ;
        Account_Team__c accteam = new Account_Team__c();
        accteam.National1__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c  = true;
        accteam.BDMPropelI__c = us.id;
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id;
        insert accteam;
        newacteam.add(accteam);
        
        Account_Team__c accteam1 = new Account_Team__c();
        accteam1.National2__c = true;
        accteam1.Account__c = objSfx.Id;
        accteam1.BDM__c = usAM.Id;
        accteam1.BDMPropelI__c = us.id;
        accteam1.PropelI_Composite_Key__c = objPrc.Id+'&&'+objPrc.Id;
        insert accteam1;
        
        accteam1.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id+'0';
        accteam1.BDMPropelI__c = us.id;
        update accteam1;
               
        newacteam.add(accteam1);
        
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.whatId = objSfx.id;
        objTask.Automation__c = true;
        insert objTask;
        //Test.stopTest();
    }
    static testMethod void testMethod3() {
        
        //Test.startTest();
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
        
        Task objTask = CommonDataTest.getGeneralTask();
        objTask.whatId = objSfx.id;
        objTask.Automation__c = true;
        insert objTask;
        
        User usAM = CommonDataTest.getUserAM();
        insert usAM;
        
        User us =  CommonDataTest.getUserBdm();
        insert us;
        
        User_Branch_Mapping__c ubm = new User_Branch_Mapping__c();
        ubm.Branch_Name__c=BMrec1.id;
        ubm.User__c=us.id;
        insert ubm;
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true ;
        Account_Team__c accteam = new Account_Team__c();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c  = true;
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id;
        accteam.BDMPropelI__c = us.id;
        insert accteam; 
       
        system.debug('accteam---->'+json.serialize(accteam));
        newacteam.add(accteam);
        
        accteam.National1__c = false;
        accteam.Relationship__c  = false;
        accteam.Collection__c = false;
        accteam.National2__c = false;
        accteam.National3__c = false;
        accteam.National4__c = false;
        accteam.Submission__c = false;  
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id+'0';
        accteam.NSM__c = false;  
        accteam.CRS__c = false;
        accteam.BDM__c=usAM.Id;
        accteam.BDMPropelI__c = usAM.id;
        update accteam;
        
        objPrc.Collection__c = true;
        update objPrc;
        
        
    }
    static testMethod void testMethod4() {
        //Test.startTest();
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Branch_Master__c BMrec1 = CommonDataTest.getBranchMaster();
        BMrec1.Name = 'PANJIM-12';
        BMrec1.Branch_Code__c = 'PJI12';
        insert BMrec1;
        
        Account objPro = CommonDataTest.getParentAccount();
        objPro.Billing_Branch__c = BMrec1.Id;
        objPro.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Customer').getRecordTypeId();
        insert objPro;
        
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.SFX_Code__c = 'SFX123';
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(60);
        insert objSfx;
        
        Account objSfx2 = CommonDataTest.getSfxAccount();
        objSfx2.SFX_Code__c = 'SFX123';
        objSfx2.parentID = objPro.Id;
        objSfx2.Opportunity__c = objOpp.Id;
        objSfx2.Contract_Expiry_Date__c = System.Today().addDays(60);
        insert objSfx2;
        
        Account objSfx3 = CommonDataTest.getSfxAccount();
        objSfx3.SFX_Code__c = 'SFX1234';
        objSfx3.parentID = objPro.Id;
        objSfx3.Opportunity__c = objOpp.Id;
        objSfx3.Contract_Expiry_Date__c = System.Today().addDays(60);
        insert objSfx3;
        
        User usAM = CommonDataTest.getUserAM();
        insert usAM;
        
        User us =  CommonDataTest.getUserBdm();
        insert us;
        
        String orgId=UserInfo.getOrganizationId();
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 
        User us2 =  CommonDataTest.getUserBdm();
        us2.lastName = 'XYZW';
        us2.Username = uniqueName + '@testing' + orgId + '.orgg';
        insert us2;
        
        User_Branch_Mapping__c ubm = new User_Branch_Mapping__c();
        ubm.Branch_Name__c=BMrec1.id;
        ubm.User__c=us.id;
        insert ubm;
        
        
        checkRecursive.firstRun = true;
         cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true ;
        Account_Team__c accteam = new Account_Team__c();
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
        
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(true, accteam.Relationship__c);
        
        checkRecursive.firstRun = true;
        Account_Team__c accteam2 = new Account_Team__c();        
        accteam2.Account__c = objSfx2.Id;
        accteam2.BDM__c=us2.Id;
        accteam2.BDMPropelI__c = usAM.id;
        accteam2.Relationship__c  = true;
        accteam2.Collection__c = true;
        accteam2.National2__c = true;        
        accteam2.Submission__c = true;   
        accteam2.PropelI_Composite_Key__c = objSfx2.Id+'&&'+objSfx2.Id;
        Database.SaveResult result2 = Database.insert(accteam2);
        
        checkRecursive.firstRun = true;
        Account_Team__c accteam3 = new Account_Team__c();        
        accteam3.Account__c = objSfx3.Id;
        accteam3.BDM__c=us2.Id;
        accteam3.BDMPropelI__c = us.id;
        accteam3.Relationship__c  = true;
        accteam3.Collection__c = true;
        accteam3.National3__c = true;        
        accteam3.Submission__c = true;   
        accteam3.PropelI_Composite_Key__c = objSfx3.Id+'&&'+objSfx3.Id;
        Database.SaveResult result3 = Database.insert(accteam3);
        
        accteam3.PropelI_Composite_Key__c = objSfx3.Id+'&&'+objSfx3.Id+'0';
        accteam3.BDMPropelI__c = usAM.id;
        update accteam3;
        delete accteam3;
        undelete accteam3;
        //Test.stopTest();
        
       // Map<Id, Account_Team__c> accountTeamMap = new Map<Id, Account_Team__c>();
       // AccountTeamQueuable atObject = new AccountTeamQueuable(new Map<String, List<Account_Team__c>>() , new Map<Id, Account_Team__c>());
       // System.enqueueJob(atObject);
    }
    static testMethod void testMethod5() {
        //Test.StartTest();
        List<Account_Team__c> newacteam = new List<Account_Team__c>();
        Map<Id,Account_Team__c> oldacteamMap = new Map<Id,Account_Team__c>();
        List<Account_Team__c> onboardList = new List<Account_Team__c>();
        
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        // Insert BDM1 
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        usrBDM1.IsActive = true;
        insert usrBDM1;
        System.assertNotEquals(usrBDM1.id, Null);
        
        // Insert BDM.
        User usrBDM2 =  CommonDataTest.getUserBdm();
        usrBDM2.ManagerId = usrAM.Id;
        insert usrBDM2;
        System.assertNotEquals(usrBDM2.id, Null);
        
        // Insert BDM.
        User usrBDM3 =  CommonDataTest.getUserBdm();
        usrBDM3.ManagerId = usrAM.Id;
        insert usrBDM3;
        System.assertNotEquals(usrBDM3.id, Null);
        
        
        // Create MSA account. 
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        msaAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();

        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        // Insert SFX Account. 
        Account sfxAccount = CommonDataTest.getNewSFXAccount();
        String sfxNumber = sfxAccount.Name;
        sfxAccount.ParentId = msaAccount.Id;
        insert sfxAccount;
        System.assertNotEquals(sfxAccount.Id, Null);
        
        // Insert service account. 
        Account srvcAccount = CommonDataTest.getServiceAccount();
        srvcAccount.ParentId = sfxAccount.id;
        insert srvcAccount;
        System.assertNotEquals(srvcAccount.Id, Null);
        
        // Insert rate Card account. 
        Account rcAccount = CommonDataTest.getRateCardAccount();
        rcAccount.ParentId = srvcAccount.Id;
        String rcNumber = rcAccount.Name;
        String rcName = rcAccount.Name;
        Insert rcAccount;
        System.assertNotEquals(rcAccount.Id, Null);
        
        // Insert Barnch Master.
        Branch_Master__c BMrec = CommonDataTest.getBranchMaster();
        BMrec.Name = 'DELHI SOUTH-11';
        BMrec.Branch_Code__c = 'DLS11';
        insert BMrec;
        System.assertNotEquals(BMrec.Id, Null);
        
        // Insert Barnch Master.
        Branch_Master__c BMrec1 = CommonDataTest.getBranchMaster();
        BMrec1.Name = 'PANJIM-12';
        BMrec1.Branch_Code__c = 'PJI12';
        insert BMrec1;
        System.assertNotEquals(BMrec1.Id, Null);
        
        // Insert Branch Account. 
        Account brchAccount = CommonDataTest.getBarnchAccount();
        brchAccount.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
        brchAccount.Assign_Branch_Id__c = BMrec.Id;
        brchAccount.Billing_Branch__c = BMrec.Id;
        brchAccount.IsMappingDone__c = true; 
        insert brchAccount;
        System.assertNotEquals(brchAccount.Id, Null);
        
        // Insert Branch Account.
        Account brchAccount1 = CommonDataTest.getBarnchAccount();
        brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
        brchAccount1.Assign_Branch_Id__c = BMrec.Id;
        brchAccount1.Billing_Branch__c = BMrec.Id;
        brchAccount1.ParentId = srvcAccount.Id;
        insert brchAccount1;
        System.assertNotEquals(brchAccount1.Id, Null);
        
        // Create billing information record MSA level. 
        Billing_Information__c upsert_BillRec = new Billing_Information__c();
        upsert_BillRec.Billing_Level__c = 'MSA';
        upsert_BillRec.MSA__c = msaNumber;
        upsert_BillRec.SFX_no__c = sfxNumber;
        upsert_BillRec.SFX__c = sfxAccount.id;
        upsert_BillRec.Start_Date__c = System.today();
        upsert_BillRec.Alias_name__c = 'JSON MARK 1';
        upsert_BillRec.Rate_Card_no__c = rcName;
        upsert_BillRec.Name = 'Billing Info:' + msaNumber+':'+ sfxNumber;
        insert upsert_BillRec;
        System.assertNotEquals(upsert_BillRec.Id, Null);
        
        // Add billing line items msa. 
        Billing_Line_Item__c upsertBillingLineItems = new Billing_Line_Item__c();
        upsertBillingLineItems.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItems.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItems.Composite_Key__c = msaNumber + '::'+sfxNumber+'::'+ rcName+ '::' + BMrec.Id; 
        insert upsertBillingLineItems;
        System.assertNotEquals(upsertBillingLineItems.Id, Null);
        
        // Create billing information record SFX level. 
        Billing_Information__c upsert_BillRecsfx = new Billing_Information__c();
        upsert_BillRecsfx.Billing_Level__c = 'SFX';
        upsert_BillRecsfx.MSA__c = msaNumber;
        upsert_BillRecsfx.SFX_no__c = sfxNumber;
        upsert_BillRecsfx.SFX__c = sfxAccount.id;
        upsert_BillRecsfx.Start_Date__c = System.today();
        upsert_BillRecsfx.Alias_name__c = 'JSON MARK 1';
        upsert_BillRecsfx.Rate_Card_no__c = rcName;
        upsert_BillRecsfx.Name = 'Billing Info:' + sfxNumber+':'+ msaNumber;
        insert upsert_BillRecsfx;
        System.assertNotEquals(upsert_BillRecsfx.Id, Null);
        
        // Add billing line items sfx 
        Billing_Line_Item__c upsertBillingLineItemsfx = new Billing_Line_Item__c();
        upsertBillingLineItemsfx.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItemsfx.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItemsfx.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItemsfx.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItemsfx.Composite_Key__c = sfxNumber + '::'+msaNumber+'::'+ rcName+ '::' + BMrec.Id; 
        insert upsertBillingLineItemsfx;
        System.assertNotEquals(upsertBillingLineItemsfx.Id, Null);
        
        // Create billing information record RC level
        Billing_Information__c upsert_BillRecrc = new Billing_Information__c();
        upsert_BillRecrc.Billing_Level__c = 'SFX';
        upsert_BillRecrc.MSA__c = msaNumber;
        upsert_BillRecrc.SFX_no__c = sfxNumber;
        upsert_BillRecrc.SFX__c = sfxAccount.id;
        upsert_BillRecrc.Start_Date__c = System.today();
        upsert_BillRecrc.Alias_name__c = 'JSON MARK 1';
        upsert_BillRecrc.Rate_Card_no__c = rcName;
        upsert_BillRecrc.Name = 'Billing Info:' + rcNumber+':'+ msaNumber;
        insert upsert_BillRecrc;
        System.assertNotEquals(upsert_BillRecrc.Id, Null);
        
        // Add billing line items sfx 
        Billing_Line_Item__c upsertBillingLineItemrc = new Billing_Line_Item__c();
        upsertBillingLineItemrc.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItemrc.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItemrc.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItemrc.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItemrc.Composite_Key__c = rcAccount.id + '::'+msaNumber+'::'+ rcName+ '::' + BMrec.Id; 
        insert upsertBillingLineItemrc;
        System.assertNotEquals(upsertBillingLineItemrc.Id, Null);
        
        User_Branch_Mapping__c ubm = new User_Branch_Mapping__c();
        ubm.Branch_Name__c=BMrec1.id;
        ubm.User__c=usrBDM1.id;
        insert ubm;
        
        
        Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
         cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true ;
        // Account team rate card
        Account_Team__c upsertAccTeam1 = new Account_Team__c();
        upsertAccTeam1.BDMPropelI__c = usrBDM2.Id;
        upsertAccTeam1.Account__c = rcAccount.Id;
        upsertAccTeam1.PropelI_Composite_Key__c =usrBDM2.Id +'::'+msaAccount.id;
        upsertAccTeam1.National1__c = true;
        upsertAccTeam1.National2__c = True;
        upsertAccTeam1.National3__c = True;
        upsertAccTeam1.National4__c = True;       
        upsertAccTeam1.CRS__c = true; 
        upsertAccTeam1.Relationship__c = true;
        upsertAccTeam1.Collection__c = true;
        upsertAccTeam1.Submission__c = true;
        upsertAccTeam1.RecordTypeId = idProperIrecordType;
        insert upsertAccTeam1;
        System.assertNotEquals(upsertAccTeam1.Id, Null); 
        List<FormulaRecalcResult> resultsrc1 = Formula.recalculateFormulas(new List<Account_Team__c> { upsertAccTeam1 });
        System.assert(resultsrc1[0].isSuccess());
        newacteam.add(upsertAccTeam1);
        
        StopRecursion.AccountShare_RunOnce = true;
        Account_Team__c acc1 = new Account_Team__c();
        acc1.Id = upsertAccTeam1.Id;
        //acc1.National1__c = false;
        //acc1.National2__c = false;
        //acc1.National3__c = false;
        acc1.National4__c = false;       
        acc1.CRS__c = false;
        acc1.Collection__c = false;        
        acc1.Submission__c = false;
        acc1.Relationship__c = false;
        oldacteamMap.put(acc1.id,acc1);
        
        Account_Team__c upsertAccTeam2 = new Account_Team__c();
        upsertAccTeam2.BDMPropelI__c = usrBDM1.Id;
        upsertAccTeam2.Account__c = rcAccount.Id;
        upsertAccTeam2.PropelI_Composite_Key__c = usrBDM1.Id + '::'+ rcNumber;
        upsertAccTeam2.National1__c = false;
        upsertAccTeam2.National2__c = false;
        upsertAccTeam2.National3__c = false;
        upsertAccTeam2.National4__c = false;
        upsertAccTeam2.CRS__c = false;
        upsertAccTeam2.NSM__c = false;
        upsertAccTeam2.Relationship__c = false;
        upsertAccTeam2.Submission__c = false;
        upsertAccTeam2.Collection__c = false;
        upsertAccTeam2.RecordTypeId = idProperIrecordType;
        insert upsertAccTeam2;
         
        upsertAccTeam2.PropelI_Composite_Key__c = usrBDM1.Id + '::'+ rcNumber+'0';
        upsertAccTeam2.BDMPropelI__c=usrBDM1.id;
        update upsertAccTeam2;
        delete upsertAccTeam2;
        undelete upsertAccTeam2;
        
        List<FormulaRecalcResult> resultsrc2 = Formula.recalculateFormulas(new List<Account_Team__c> { upsertAccTeam2 });
        System.assert(resultsrc2[0].isSuccess()); 
        newacteam.add(upsertAccTeam2);
        
        StopRecursion.AccountShare_RunOnce = true;
        Account_Team__c acc2 = new Account_Team__c();
        acc2.Id = upsertAccTeam2.Id;
        acc2.National1__c = true;
        acc2.National2__c = true;
        acc2.National3__c = true;
        acc2.National4__c = true;
        acc2.CRS__c = true;
        acc2.NSM__c = true;
        acc2.Relationship__c = true;
        acc2.Submission__c = true;
        acc2.Collection__c = true;
        oldacteamMap.put(acc2.id,acc2);
        
        Account_Team__c upsertAccTeam3 = new Account_Team__c();
        upsertAccTeam3.BDMPropelI__c = usrBDM2.Id;
        upsertAccTeam3.Account__c = rcAccount.Id;
        upsertAccTeam3.PropelI_Composite_Key__c =usrBDM2.Id +'::'+rcAccount.id;
        upsertAccTeam3.National1__c = true;
        upsertAccTeam3.National2__c = True;
        upsertAccTeam3.National3__c = false;
        upsertAccTeam3.National4__c = true;       
        upsertAccTeam3.CRS__c = false; 
        upsertAccTeam3.Relationship__c = true;
        upsertAccTeam3.Collection__c = false;
        upsertAccTeam3.Submission__c = true;
        upsertAccTeam3.RecordTypeId = idProperIrecordType;
        insert upsertAccTeam3;
        System.assertNotEquals(upsertAccTeam3.Id, Null); 
        List<FormulaRecalcResult> resultsrc3 = Formula.recalculateFormulas(new List<Account_Team__c> { upsertAccTeam3 });
        System.assert(resultsrc3[0].isSuccess());
        newacteam.add(upsertAccTeam3);
        
        StopRecursion.AccountShare_RunOnce = true;
        Account_Team__c acc3 = new Account_Team__c();
        acc3.Id = upsertAccTeam3.Id;
        acc3.National1__c = true;
        acc3.National2__c = true;
        acc3.National3__c = true;
        acc3.National4__c = false;       
        acc3.CRS__c = true;
        acc3.Collection__c = false;        
        acc3.Submission__c = true;
        acc3.Relationship__c = false;
        oldacteamMap.put(acc3.id,acc3);
        
        Account_Team__c upsertAccTeam4 = new Account_Team__c();
        upsertAccTeam4.BDMPropelI__c = usrBDM2.Id;
        upsertAccTeam4.Account__c = rcAccount.Id;
        upsertAccTeam4.PropelI_Composite_Key__c =usrBDM3.Id +'::'+rcAccount.id;
        upsertAccTeam4.National1__c = false;
        upsertAccTeam4.National2__c = false;
        upsertAccTeam4.National3__c = false;
        upsertAccTeam4.National4__c = false;       
        upsertAccTeam4.CRS__c = false; 
        upsertAccTeam4.Relationship__c = false;
        upsertAccTeam4.Collection__c = false;
        upsertAccTeam4.Submission__c = true;
        upsertAccTeam4.RecordTypeId = idProperIrecordType;
        insert upsertAccTeam4;
        System.assertNotEquals(upsertAccTeam4.Id, Null); 
        List<FormulaRecalcResult> resultsrc4 = Formula.recalculateFormulas(new List<Account_Team__c> { upsertAccTeam4 });
        System.assert(resultsrc4[0].isSuccess());
        newacteam.add(upsertAccTeam4);
        
        StopRecursion.AccountShare_RunOnce = true;
        Account_Team__c acc4 = new Account_Team__c();
        acc4.Id = upsertAccTeam4.Id;
        acc4.National1__c = true;
        acc4.National2__c = true;
        acc4.National3__c = true;
        acc4.National4__c = true;       
        acc4.CRS__c = true;
        acc4.Collection__c = true;        
        acc4.Submission__c = true;
        acc4.Relationship__c = true;
        oldacteamMap.put(acc4.id,acc4);
        trg_AccountTeamHelper.afterUpdate(newacteam, oldacteamMap);
        
        Account_Team__c upsertAccTeamtask = new Account_Team__c();
        upsertAccTeamtask.BDMPropelI__c = usrBDM1.Id;
        upsertAccTeamtask.Account__c = rcAccount.Id;
        upsertAccTeamtask.PropelI_Composite_Key__c = usrBDM1.Id +'::'+rcName+'-'+BMrec.Name+':@'+BMrec.Id+':'+sfxAccount.SFX_Code__c+':'+msaAccount.Propel_MSACode__c; 
        upsertAccTeamtask.Relationship__c = True;
        upsertAccTeamtask.RecordTypeId = idProperIrecordType;
        insert upsertAccTeamtask;
        List<FormulaRecalcResult> resultsrc15 = Formula.recalculateFormulas(new List<Account_Team__c> { upsertAccTeamtask });
        System.assert(resultsrc15[0].isSuccess());
        onboardList.add(upsertAccTeamtask);
        
        //trg_AccountTeamHelper.onboardingTask(onboardList);
        trg_AccountTeamHelper.onboardingTask(onboardList, false,1);
        trg_AccountTeamHelper.onboardingTask(onboardList, true,2);
        
        Task objTask = new Task();
        objTask.Subject = 'Onboarding Task';
        objTask.OwnerId = usrBDM1.id;
        objTask.Priority = 'High';
        objTask.status = 'Open';
        objTask.ActivityDate = Date.Today().addDays(7);
        objTask.Booking_branch__c = 'DELHI SOUTH-11';
        objTask.SFX_Code__c = sfxAccount.SFX_Code__c;
        objTask.WhatId = sfxAccount.Id;
        insert objTask;
        Map<Task, Id> tasksToBeUpdated =  new Map<Task, Id> ();
        tasksToBeUpdated.put(objTask,usrBDM2.id);
        trg_AccountTeamHelper.updateOnBoardingTasksAssignee (tasksToBeUpdated);
        //Test.stopTest();
        
    } 
    
    @isTest
static void testCreateOnBoardingTasksMethod() {
    // Reuse setup data from your existing testMethod5 setup:
    User testBDM = CommonDataTest.getUserBdm();
    insert testBDM;

    Account msa = CommonDataTest.getMSAAccount();
    insert msa;

    Account sfx = CommonDataTest.getNewSFXAccount();
    sfx.ParentId = msa.Id;
    insert sfx;

    Account service = CommonDataTest.getServiceAccount();
    service.ParentId = sfx.Id;
    insert service;

    Branch_Master__c branch = CommonDataTest.getBranchMaster();
    branch.Branch_Code__c = 'BR001';
    insert branch;

    // Compose SFX + Branch composite key
    String compositeKey = sfx.Name + '::' + branch.Branch_Code__c;

    // Create dummy Account_Team__c with required fields
    Account_Team__c acctTeam = new Account_Team__c(
        Account__c = service.Id,
        BDMPropelI__c = testBDM.Id
    );

    // Populate required __r fields manually
    acctTeam.Account__r = service;
    //acctTeam.Account__r.Account_Name__c = 'Test Service Account';

    // MSA (parent of parent of parent)
    Account parent1 = new Account(Id = sfx.Id, ParentId = msa.Id);
    Account parent2 = new Account(Id = service.Id, ParentId = sfx.Id);
    parent1.Parent = msa;
    parent2.Parent = parent1;

    acctTeam.Account__r.Parent = parent1;
    acctTeam.Account__r.Parent.Parent = msa;
    acctTeam.Account__r.Parent.Parent.Customer_Category__c = 'Enterprise';
    acctTeam.Account__r.Parent.Parent.Parent = new Account(Name = 'Big MSA Group');

    //acctTeam.Assigned_Branch__r = new Branch_Master__c(Opt_Out_for_Customer_Relationship_Profil__c = false);

    Map<String, Account_Team__c> originalData = new Map<String, Account_Team__c>{
        compositeKey => acctTeam
    };

    Map<String, String> sfxIDNameSet = new Map<String, String>{
        sfx.Name => service.Id
    };

    List<Account> accountToUpdateIsMapping = new List<Account>{ service };

    Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Task' LIMIT 1].Id;

    // Now call the actual method
    Test.startTest();
    Map<String, Integer> result = trg_AccountTeamHelper.createOnBoardingTasks(
        new Set<String>{ compositeKey },
        originalData,
        sfxIDNameSet,
        recordTypeId,
        accountToUpdateIsMapping,
        3 // taskType
    );
    Test.stopTest();

    // Assertions
    /*System.assertNotEquals(null, result, 'Result map should not be null');
    System.assertEquals(false, result.containsKey('noChange'), 'Should create profiling task');
    
    List<Task> insertedTasks = [SELECT Id, Subject, Status FROM Task WHERE Subject = 'Onboarding Task'];
    System.assert(insertedTasks.size() > 0, 'At least one onboarding task should be created');*/
}


    static testMethod void testMsaDeleteAC() {
        //Test.StartTest();
        List<Account_Team__c> newacteam = new List<Account_Team__c>();
        Map<Id,Account_Team__c> oldacteamMap = new Map<Id,Account_Team__c>();
        List<Account_Team__c> onboardList = new List<Account_Team__c>();
        
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        // Insert BDM1 
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        usrBDM1.IsActive = true;
        insert usrBDM1;
        System.assertNotEquals(usrBDM1.id, Null);
        
        // Insert BDM.
        User usrBDM2 =  CommonDataTest.getUserBdm();
        usrBDM2.ManagerId = usrAM.Id;
        insert usrBDM2;
        System.assertNotEquals(usrBDM2.id, Null);
        
        // Insert BDM.
        User usrBDM3 =  CommonDataTest.getUserBdm();
        usrBDM3.ManagerId = usrAM.Id;
        insert usrBDM3;
        System.assertNotEquals(usrBDM3.id, Null);
        
        
        // Create MSA account. 
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        msaAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();

        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        // Insert SFX Account. 
        Account sfxAccount = CommonDataTest.getNewSFXAccount();
        String sfxNumber = sfxAccount.Name;
        sfxAccount.ParentId = msaAccount.Id;
        insert sfxAccount;
        System.assertNotEquals(sfxAccount.Id, Null);
        
        // Insert service account. 
        Account srvcAccount = CommonDataTest.getServiceAccount();
        srvcAccount.ParentId = sfxAccount.id;
        insert srvcAccount;
        System.assertNotEquals(srvcAccount.Id, Null);
        
        // Insert rate Card account. 
        Account rcAccount = CommonDataTest.getRateCardAccount();
        rcAccount.ParentId = srvcAccount.Id;
        String rcNumber = rcAccount.Name;
        String rcName = rcAccount.Name;
        Insert rcAccount;
        System.assertNotEquals(rcAccount.Id, Null);
        
        // Insert Barnch Master.
        Branch_Master__c BMrec = CommonDataTest.getBranchMaster();
        BMrec.Name = 'DELHI SOUTH-11';
        BMrec.Branch_Code__c = 'DLS11';
        insert BMrec;
        System.assertNotEquals(BMrec.Id, Null);
        
        // Insert Barnch Master.
        Branch_Master__c BMrec1 = CommonDataTest.getBranchMaster();
        BMrec1.Name = 'PANJIM-12';
        BMrec1.Branch_Code__c = 'PJI12';
        insert BMrec1;
        System.assertNotEquals(BMrec1.Id, Null);
        
        // Insert Branch Account. 
        Account brchAccount = CommonDataTest.getBarnchAccount();
        brchAccount.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
        brchAccount.Assign_Branch_Id__c = BMrec.Id;
        brchAccount.Billing_Branch__c = BMrec.Id;
        brchAccount.IsMappingDone__c = true; 
        insert brchAccount;
        System.assertNotEquals(brchAccount.Id, Null);
        
        // Insert Branch Account.
        Account brchAccount1 = CommonDataTest.getBarnchAccount();
        brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
        brchAccount1.Assign_Branch_Id__c = BMrec.Id;
        brchAccount1.Billing_Branch__c = BMrec.Id;
        brchAccount1.ParentId = srvcAccount.Id;
        insert brchAccount1;
        System.assertNotEquals(brchAccount1.Id, Null);
        
        // Create billing information record MSA level. 
        Billing_Information__c upsert_BillRec = new Billing_Information__c();
        upsert_BillRec.Billing_Level__c = 'MSA';
        upsert_BillRec.MSA__c = msaNumber;
        upsert_BillRec.SFX_no__c = sfxNumber;
        upsert_BillRec.SFX__c = sfxAccount.id;
        upsert_BillRec.Start_Date__c = System.today();
        upsert_BillRec.Alias_name__c = 'JSON MARK 1';
        upsert_BillRec.Rate_Card_no__c = rcName;
        upsert_BillRec.Name = 'Billing Info:' + msaNumber+':'+ sfxNumber;
        insert upsert_BillRec;
        System.assertNotEquals(upsert_BillRec.Id, Null);
        
        // Add billing line items msa. 
        Billing_Line_Item__c upsertBillingLineItems = new Billing_Line_Item__c();
        upsertBillingLineItems.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItems.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItems.Composite_Key__c = msaNumber + '::'+sfxNumber+'::'+ rcName+ '::' + BMrec.Id; 
        insert upsertBillingLineItems;
        System.assertNotEquals(upsertBillingLineItems.Id, Null);
        
        // Create billing information record SFX level. 
        Billing_Information__c upsert_BillRecsfx = new Billing_Information__c();
        upsert_BillRecsfx.Billing_Level__c = 'SFX';
        upsert_BillRecsfx.MSA__c = msaNumber;
        upsert_BillRecsfx.SFX_no__c = sfxNumber;
        upsert_BillRecsfx.SFX__c = sfxAccount.id;
        upsert_BillRecsfx.Start_Date__c = System.today();
        upsert_BillRecsfx.Alias_name__c = 'JSON MARK 1';
        upsert_BillRecsfx.Rate_Card_no__c = rcName;
        upsert_BillRecsfx.Name = 'Billing Info:' + sfxNumber+':'+ msaNumber;
        insert upsert_BillRecsfx;
        System.assertNotEquals(upsert_BillRecsfx.Id, Null);
        
        // Add billing line items sfx 
        Billing_Line_Item__c upsertBillingLineItemsfx = new Billing_Line_Item__c();
        upsertBillingLineItemsfx.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItemsfx.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItemsfx.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItemsfx.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItemsfx.Composite_Key__c = sfxNumber + '::'+msaNumber+'::'+ rcName+ '::' + BMrec.Id; 
        insert upsertBillingLineItemsfx;
        System.assertNotEquals(upsertBillingLineItemsfx.Id, Null);
        
        // Create billing information record RC level
        Billing_Information__c upsert_BillRecrc = new Billing_Information__c();
        upsert_BillRecrc.Billing_Level__c = 'SFX';
        upsert_BillRecrc.MSA__c = msaNumber;
        upsert_BillRecrc.SFX_no__c = sfxNumber;
        upsert_BillRecrc.SFX__c = sfxAccount.id;
        upsert_BillRecrc.Start_Date__c = System.today();
        upsert_BillRecrc.Alias_name__c = 'JSON MARK 1';
        upsert_BillRecrc.Rate_Card_no__c = rcName;
        upsert_BillRecrc.Name = 'Billing Info:' + rcNumber+':'+ msaNumber;
        insert upsert_BillRecrc;
        System.assertNotEquals(upsert_BillRecrc.Id, Null);
        
        // Add billing line items sfx 
        Billing_Line_Item__c upsertBillingLineItemrc = new Billing_Line_Item__c();
        upsertBillingLineItemrc.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItemrc.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItemrc.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItemrc.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItemrc.Composite_Key__c = rcAccount.id + '::'+msaNumber+'::'+ rcName+ '::' + BMrec.Id; 
        insert upsertBillingLineItemrc;
        System.assertNotEquals(upsertBillingLineItemrc.Id, Null);
        
        User_Branch_Mapping__c ubm = new User_Branch_Mapping__c();
        ubm.Branch_Name__c=BMrec1.id;
        ubm.User__c=usrBDM1.id;
        insert ubm;
         
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true;
		Account_Team__c upsertAccTeamMsa = new Account_Team__c();
        upsertAccTeamMsa.BDMPropelI__c = usrAM.Id;
        upsertAccTeamMsa.Account__c = msaAccount.Id;
        upsertAccTeamMsa.PropelI_Composite_Key__c =usrAM.Id +'::'+msaAccount.id;
        upsertAccTeamMsa.National1__c = true;
        upsertAccTeamMsa.National2__c = True;
        upsertAccTeamMsa.National3__c = True;
        upsertAccTeamMsa.National4__c = True;       
        upsertAccTeamMsa.CRS__c = true; 
        upsertAccTeamMsa.Relationship__c = true;
        upsertAccTeamMsa.Collection__c = true;
        upsertAccTeamMsa.Submission__c = true; 
        insert upsertAccTeamMsa;  
        
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true;
        checkRecursive.firstRun = true;
        upsertAccTeamMsa.National4__c = false;
        update upsertAccTeamMsa;
        checkRecursive.firstRun = true;
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true;
        delete upsertAccTeamMsa;
    } 

    @isTest
    static void testPropeliBDMChange() {
        
        
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
         
        
        User usAM = CommonDataTest.getUserAM();
        insert usAM;
        
        User us =  CommonDataTest.getUserBdm();
        insert us;
        
        checkRecursive.firstRun = true;
         cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true ;
        Account_Team__c accteam = new Account_Team__c();
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
        
        checkRecursive.firstRun = true;
        accteam.BDMPropelI__c = usAM.Id;
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true;  
        /*Test.StartTest();
        	Database.SaveResult uResult = Database.update(accteam);
        	cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;
        Test.stopTest();*/
        // Asserts
        
        
    }
    
}