@IsTest
public class cls_propelIBDMReportTest {
    
    static testMethod void unitTest1() {
        Test.StartTest();
        
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        
        // Insert BDM.
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        insert usrBDM1;
        System.assertNotEquals(usrBDM1.id, Null);
        User usrBDM =  CommonDataTest.getUserBdm();
        usrBDM.ManagerId = usrAM.Id;
        
        // Create MSA account. 
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        // Insert SFX Account. 
        Account sfxAccount = CommonDataTest.getNewSFXAccount();
        String sfxNumber = sfxAccount.Name;
        sfxAccount.ParentId = msaAccount.Id;
        insert sfxAccount;
        System.assertNotEquals(sfxAccount.id, Null);
        
        // Insert service account. 
        Account srvcAccount = CommonDataTest.getServiceAccount();
        srvcAccount.ParentId = sfxAccount.id;
        insert srvcAccount;
        System.assertNotEquals(srvcAccount.id, Null);
        
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
        // Insert rate Card account. 
        Account rcAccount = CommonDataTest.getRateCardAccount();
        rcAccount.ParentId = srvcAccount.Id;
        rcAccount.Base_Location__c = BMrec1.Id;
        
        String rcName = rcAccount.Name;
        Insert rcAccount;
        System.assertNotEquals(rcAccount.id, Null);
        // Insert Branch Account. 
        Account brchAccount = CommonDataTest.getBarnchAccount();
        brchAccount.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
        brchAccount.Assign_Branch_Id__c = BMrec.Id;
        brchAccount.Billing_Branch__c = BMrec.Id;
        brchAccount.AssignBranch_ID__c = '103591';
        insert brchAccount;
        System.assertNotEquals(brchAccount.Id, Null);
        
        // Create billing information record. 
        Billing_Information__c upsert_BillRec = new Billing_Information__c();
        upsert_BillRec.Billing_Level__c = 'MSA';
        upsert_BillRec.MSA__c = msaNumber;
        upsert_BillRec.SFX_no__c = sfxNumber;
        upsert_BillRec.SFX__c = sfxAccount.id;
        upsert_BillRec.Start_Date__c = System.today();
        upsert_BillRec.Alias_name__c = 'JSON MARK 1';
        upsert_BillRec.Rate_Card_no__c = rcName;
        upsert_BillRec.Billing_Config_Id__c = 4853;
        upsert_BillRec.Name = 'Billing Info:' + msaNumber+':'+ sfxNumber;
        insert upsert_BillRec;
        System.assertNotEquals(upsert_BillRec.Id, Null);
        
        // Add billing line items. 
        Billing_Line_Item__c upsertBillingLineItems = new Billing_Line_Item__c();
        upsertBillingLineItems.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItems.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItems.Composite_Key__c = 'MSA999964' + '::'+sfxNumber+'::'+ rcName+ '::' + '5186'; 
        insert upsertBillingLineItems;
        System.assertNotEquals(upsertBillingLineItems.Id, Null); 
        
        Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();     
        Account_Team__c upsertAccTeam1 = new Account_Team__c();
        upsertAccTeam1.BDMPropelI__c = usrBDM1.Id;
        upsertAccTeam1.Account__c = rcAccount.Id;
        upsertAccTeam1.PropelI_Composite_Key__c =usrBDM1.Id + '::'+rcName+'-' +'PANJIM-12'+':@'+'103591'+':'+sfxNumber+':'+msaNumber;
        upsertAccTeam1.Relationship__c = true;
        upsertAccTeam1.PropelI_Branch_Id__c = '103591';
        upsertAccTeam1.RecordTypeId = idProperIrecordType;
        insert upsertAccTeam1;
        
    }
    static testMethod void unitTest2() {
        
        Test.StartTest();
        
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        
        // Insert BDM.
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        insert usrBDM1;
        System.assertNotEquals(usrBDM1.id, Null);
        User usrBDM =  CommonDataTest.getUserBdm();
        usrBDM.ManagerId = usrAM.Id;
        
        // Create MSA account. 
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        // Insert SFX Account. 
        Account sfxAccount = CommonDataTest.getNewSFXAccount();
        String sfxNumber = sfxAccount.Name;
        sfxAccount.ParentId = msaAccount.Id;
        insert sfxAccount;
        System.assertNotEquals(sfxAccount.id, Null);
        
        // Insert service account. 
        Account srvcAccount = CommonDataTest.getServiceAccount();
        srvcAccount.ParentId = sfxAccount.id;
        insert srvcAccount;
        System.assertNotEquals(srvcAccount.id, Null);
        
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
        // Insert rate Card account. 
        Account rcAccount = CommonDataTest.getRateCardAccount();
        rcAccount.ParentId = srvcAccount.Id;
        rcAccount.Base_Location__c = BMrec1.Id;
        
        String rcName = rcAccount.Name;
        Insert rcAccount;
        System.assertNotEquals(rcAccount.id, Null);
        // Insert Branch Account. 
        Account brchAccount = CommonDataTest.getBarnchAccount();
        brchAccount.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
        brchAccount.Assign_Branch_Id__c = BMrec.Id;
        brchAccount.Billing_Branch__c = BMrec.Id;
        brchAccount.AssignBranch_ID__c = '103591';
        insert brchAccount;
        System.assertNotEquals(brchAccount.Id, Null);
        
        // Create billing information record. 
        Billing_Information__c upsert_BillRec = new Billing_Information__c();
        upsert_BillRec.Billing_Level__c = 'MSA';
        upsert_BillRec.MSA__c = msaNumber;
        upsert_BillRec.SFX_no__c = sfxNumber;
        upsert_BillRec.SFX__c = sfxAccount.id;
        upsert_BillRec.Start_Date__c = System.today();
        upsert_BillRec.Alias_name__c = 'JSON MARK 1';
        upsert_BillRec.Rate_Card_no__c = rcName;
        upsert_BillRec.Billing_Config_Id__c = 4853;
        upsert_BillRec.Name = 'Billing Info:' + msaNumber+':'+ sfxNumber;
        insert upsert_BillRec;
        System.assertNotEquals(upsert_BillRec.Id, Null);
        
        // Add billing line items. 
        Billing_Line_Item__c upsertBillingLineItems = new Billing_Line_Item__c();
        upsertBillingLineItems.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItems.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItems.Composite_Key__c = 'MSA999964' + '::'+sfxNumber+'::'+ rcName+ '::' + '5186'; 
        insert upsertBillingLineItems;
        System.assertNotEquals(upsertBillingLineItems.Id, Null); 
        
        Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();     
        Account_Team__c upsertAccTeam = new Account_Team__c();
        upsertAccTeam.BDMPropelI__c = usrBDM1.Id;
        upsertAccTeam.Account__c = msaAccount.Id;
        upsertAccTeam.PropelI_Composite_Key__c = usrBDM1.Id + '::'+ msaAccount.Id;
        upsertAccTeam.National1__c = True;
        upsertAccTeam.National2__c = True;
        upsertAccTeam.National3__c = True;
        upsertAccTeam.National4__c = True;
        upsertAccTeam.CRS__c = True;
        upsertAccTeam.RecordTypeId = idProperIrecordType;
        System.debug('---- upsertAccTeam: ' + upsertAccTeam);
        insert upsertAccTeam;
        checkRecursive.firstRun = true;
        StopRecursion.AccountShare_RunOnce = true;
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = true;
        upsertAccTeam.National1__c = false;
        upsertAccTeam.National2__c = false;
        upsertAccTeam.National3__c = false;
        upsertAccTeam.National4__c = false;
        upsertAccTeam.CRS__c = false;
        update upsertAccTeam;
    }
    static testMethod void unitTest3() {
        Test.StartTest();
        
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        
        // Insert BDM.
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        insert usrBDM1;
        System.assertNotEquals(usrBDM1.id, Null);
        User usrBDM =  CommonDataTest.getUserBdm();
        usrBDM.ManagerId = usrAM.Id;
        
        // Create MSA account. 
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        // Insert SFX Account. 
        Account sfxAccount = CommonDataTest.getNewSFXAccount();
        String sfxNumber = sfxAccount.Name;
        sfxAccount.ParentId = msaAccount.Id;
        insert sfxAccount;
        System.assertNotEquals(sfxAccount.id, Null);
        
        // Insert service account. 
        Account srvcAccount = CommonDataTest.getServiceAccount();
        srvcAccount.ParentId = sfxAccount.id;
        insert srvcAccount;
        System.assertNotEquals(srvcAccount.id, Null);
        
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
        // Insert rate Card account. 
        Account rcAccount = CommonDataTest.getRateCardAccount();
        rcAccount.ParentId = srvcAccount.Id;
        rcAccount.Base_Location__c = BMrec1.Id;
        
        String rcName = rcAccount.Name;
        Insert rcAccount;
        System.assertNotEquals(rcAccount.id, Null);
        // Insert Branch Account. 
        Account brchAccount = CommonDataTest.getBarnchAccount();
        brchAccount.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
        brchAccount.Assign_Branch_Id__c = BMrec.Id;
        brchAccount.Billing_Branch__c = BMrec.Id;
        brchAccount.AssignBranch_ID__c = '103591';
        insert brchAccount;
        System.assertNotEquals(brchAccount.Id, Null);
        
        // Create billing information record. 
        Billing_Information__c upsert_BillRec = new Billing_Information__c();
        upsert_BillRec.Billing_Level__c = 'MSA';
        upsert_BillRec.MSA__c = msaNumber;
        upsert_BillRec.SFX_no__c = sfxNumber;
        upsert_BillRec.SFX__c = sfxAccount.id;
        upsert_BillRec.Start_Date__c = System.today();
        upsert_BillRec.Alias_name__c = 'JSON MARK 1';
        upsert_BillRec.Rate_Card_no__c = rcName;
        upsert_BillRec.Billing_Config_Id__c = 4853;
        upsert_BillRec.Name = 'Billing Info:' + msaNumber+':'+ sfxNumber;
        insert upsert_BillRec;
        System.assertNotEquals(upsert_BillRec.Id, Null);
        
        // Add billing line items. 
        Billing_Line_Item__c upsertBillingLineItems = new Billing_Line_Item__c();
        upsertBillingLineItems.Submission_Branch__c = BMrec.Id;
        upsertBillingLineItems.Collection_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Branch__c = BMrec.Id;
        upsertBillingLineItems.Billing_Information__c = upsert_BillRec.Id; 
        upsertBillingLineItems.Composite_Key__c = 'MSA999964' + '::'+sfxNumber+'::'+ rcName+ '::' + '5186'; 
        insert upsertBillingLineItems;
        System.assertNotEquals(upsertBillingLineItems.Id, Null); 
        
        Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();     
        Account_Team__c upsertAccTeam = new Account_Team__c();
        upsertAccTeam.BDMPropelI__c = usrBDM1.Id;
        upsertAccTeam.Account__c = sfxAccount.Id;
        upsertAccTeam.PropelI_Composite_Key__c = usrBDM1.Id + '::'+'103591'+':'+sfxNumber+':'+ msaNumber;
        upsertAccTeam.Collection__c = true;        
        upsertAccTeam.Submission__c = true; 
        upsertAccTeam.PropelI_Branch_Id__c = '103591';
        upsertAccTeam.RecordTypeId = idProperIrecordType;
        System.debug('---- upsertAccTeam: ' + upsertAccTeam);
        insert upsertAccTeam;
        
        //checkRecursive.firstRun = true;
        //StopRecursion.AccountShare_RunOnce = true;
        //upsertAccTeam.National3__c = true;
        //update upsertAccTeam;
    }
}