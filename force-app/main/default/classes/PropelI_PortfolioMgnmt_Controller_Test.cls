/*----------------------------------------------------------------
** Author: Safexpress.com
** Description: test class written to cover "PropelI_PortfolioMgnmt_Controller" apex class.
** Code Coverage: 
**History: 
-------------------------------------------------------------------------------------------------*/
@isTest
Public Class PropelI_PortfolioMgnmt_Controller_Test
{
    public static testMethod void portfolioMangmentUnitTesting()
    {
        Test.startTest();
        //Insert Account Manager
        List<User> userList = new List<User>();
        User usrAM = CommonDataTest.getUserAM();
         
        insert usrAM;
        System.assertNotEquals(usrAM.Id, Null);
        //Insert BDM.
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        userList.add(usrBDM1);
        //insert usrBDM1;
        //System.assertNotEquals(usrBDM1.id, Null);
        // Insert BDM.
        User usrBDM2 =  CommonDataTest.getUserBdm();
        usrBDM2.ManagerId = usrAM.Id;
        userList.add(usrBDM2);
        //insert usrBDM2;
        //System.assertNotEquals(usrBDM2.id, Null);
        // Insert BDM.
        User usrBDM3 =  CommonDataTest.getUserBdm();
        usrBDM3.ManagerId = usrAM.Id;
        userList.add(usrBDM3);
        //insert usrBDM3;
        //System.assertNotEquals(usrBDM3.id, Null);
        // Insert BDM.
        User usrBDM =  CommonDataTest.getUserBdm();
        usrBDM.ManagerId = usrAM.Id;
        userList.add(usrBDM);
        insert userList;
        System.runAs(usrBDM)
        {
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
            // Insert rate Card account. 
            Account rcAccount = CommonDataTest.getRateCardAccount();
            rcAccount.ParentId = srvcAccount.Id;
            rcAccount.AssignBranch_ID__c = '123456';
            String rcName = rcAccount.Name;
            
            Insert rcAccount;
            System.assertNotEquals(rcAccount.id, Null);
            
            // Insert Barnch Master.
            List<Branch_Master__c> bmList = new List<Branch_Master__c>();
            Branch_Master__c BMrec = CommonDataTest.getBranchMaster();
            BMrec.Name = 'DELHI SOUTH-11';
            BMrec.Branch_Code__c = 'DLS11';
            //insert BMrec;
            bmList.add(BMrec);
            //System.assertNotEquals(BMrec.Id, Null);
            // Insert Barnch Master.
            Branch_Master__c BMrec1 = CommonDataTest.getBranchMaster();
            BMrec1.Name = 'PANJIM-12';
            BMrec1.Branch_Code__c = 'PJI12';
            bmList.add(BMrec1);
            //insert BMrec1;
            //System.assertNotEquals(BMrec1.Id, Null);
            insert bmList;
            // Insert Branch Account. 
            List<Account> branchAccList = new List<Account>();
            Account brchAccount = CommonDataTest.getBarnchAccount();
            brchAccount.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount.Assign_Branch_Id__c = BMrec.Id;
            brchAccount.Billing_Branch__c = BMrec.Id;
            branchAccList.add(brchAccount);
            //insert brchAccount;
            //System.assertNotEquals(brchAccount.Id, Null);
            
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount1 = CommonDataTest.getBarnchAccount();
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec.Id;
            brchAccount1.Billing_Branch__c = BMrec.Id;
            brchAccount1.ParentId = srvcAccount.Id; //ADD by Vikas Sharma
            //insert brchAccount1;
            //System.assertNotEquals(brchAccount1.Id, Null);
            branchAccList.add(brchAccount1);
            insert branchAccList;
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
            
            //upsert account_team__c
            List<Account_Team__c> accountTeamList = new List<Account_Team__c>();
            Account_Team__c upsertAccTeam = new Account_Team__c();
            upsertAccTeam.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam.Account__c = msaAccount.Id;
            upsertAccTeam.PropelI_Composite_Key__c =usrBDM.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam.National1__c = True;
            upsertAccTeam.National2__c = True;
            upsertAccTeam.CRS__c = True;
            upsertAccTeam.Billing_By_Id__c = '12341';
            upsertAccTeam.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam);
            //insert upsertAccTeam;
            
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam1.Account__c = sfxAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ sfxAccount.Id;
            upsertAccTeam1.Collection__c = true;        
            upsertAccTeam1.Submission__c = true; 
            upsertAccTeam1.Billing_By_Id__c = '12342';
            upsertAccTeam1.Relationship__c = true; //Added By Vikas Sharma
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam1);
            //insert upsertAccTeam1;
            //System.assertNotEquals(upsertAccTeam1.Id, Null); 
            
            Account_Team__c upsertAccTeam2 = new Account_Team__c();
            upsertAccTeam2.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam2.Account__c = rcAccount.Id;
            upsertAccTeam2.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ rcAccount.Id;
            upsertAccTeam2.PropelI_Branch_Id__c = '123456';
            upsertAccTeam2.Billing_By_Id__c = '12343';
            upsertAccTeam2.Collection__c = true;        
            upsertAccTeam2.Submission__c = true; 
            upsertAccTeam2.Relationship__c = True;
            upsertAccTeam2.RecordTypeId = idProperIrecordType;
            //insert upsertAccTeam2;
            accountTeamList.add(upsertAccTeam2);
            
            Account_Team__c upsertAccTeam4 = new Account_Team__c();
            upsertAccTeam4.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam4.Account__c = rcAccount.Id;
            upsertAccTeam4.PropelI_Composite_Key__c =usrBDM2.Id + '::'+ rcAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam4.PropelI_Branch_Id__c = '123456';
            upsertAccTeam4.Billing_By_Id__c = '12344';
            upsertAccTeam4.Collection__c = true;        
            upsertAccTeam4.Submission__c = true; 
            upsertAccTeam4.Relationship__c = True;
            upsertAccTeam4.RecordTypeId = idProperIrecordType;
            //insert upsertAccTeam4;
            accountTeamList.add(upsertAccTeam4);
            
            Account_Team__c upsertAccTeam3 = new Account_Team__c();
            upsertAccTeam3.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam3.Account__c = msaAccount.Id;
            upsertAccTeam3.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ msaAccount.Id;
            upsertAccTeam3.National1__c = True;
            upsertAccTeam3.National2__c = True;
            upsertAccTeam3.National3__c = True;
            upsertAccTeam3.National4__c = True;
            upsertAccTeam3.Billing_By_Id__c = '12345';
            upsertAccTeam3.CRS__c = True;
            upsertAccTeam3.Relationship__c = True; //added by Vikas Sharma
            upsertAccTeam3.RecordTypeId = idProperIrecordType;
            //insert upsertAccTeam3;
            //System.assertNotEquals(upsertAccTeam3.Id, Null); 
            accountTeamList.add(upsertAccTeam3);
            
            //upsert account_team__c
            Account_Team__c upsertAccTeam5 = new Account_Team__c();
            upsertAccTeam5.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam5.Account__c = msaAccount.Id;
            upsertAccTeam5.PropelI_Composite_Key__c =usrBDM2.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam5.National3__c = True;
            upsertAccTeam5.Billing_By_Id__c = '12346';
            upsertAccTeam5.National4__c = True;
            upsertAccTeam5.RecordTypeId = idProperIrecordType;
            //insert upsertAccTeam5;
            accountTeamList.add(upsertAccTeam5);
            
            Account_Team__c upsertAccTeam6 = new Account_Team__c();
            upsertAccTeam6.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam6.Account__c = sfxAccount.Id;
            upsertAccTeam6.PropelI_Composite_Key__c =usrBDM2.Id + '::'+ sfxAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam6.Collection__c = true;        
            upsertAccTeam6.Submission__c = true; 
            upsertAccTeam6.Relationship__c = true; //Added By Vikas Sharma
            upsertAccTeam6.RecordTypeId = idProperIrecordType;
            upsertAccTeam6.Billing_By_Id__c = '12347';
            //insert upsertAccTeam6;
            //System.assertNotEquals(upsertAccTeam6.Id, Null); 
            accountTeamList.add(upsertAccTeam6);
            
            Account_Team__c upsertAccTeam7 = new Account_Team__c();
            upsertAccTeam7.BDMPropelI__c = usrBDM3.Id;
            upsertAccTeam7.Account__c = sfxAccount.Id;
            upsertAccTeam7.PropelI_Composite_Key__c =usrBDM3.Id + '::'+ sfxAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam7.Collection__c = true;        
            upsertAccTeam7.Submission__c = true; 
            upsertAccTeam7.Relationship__c = true; //Added By Vikas Sharma
            upsertAccTeam7.RecordTypeId = idProperIrecordType;
            upsertAccTeam7.Billing_By_Id__c = '12348';
            //insert upsertAccTeam7;
            //System.assertNotEquals(upsertAccTeam7.Id, Null); 
            accountTeamList.add(upsertAccTeam7);
            insert accountTeamList;
            
            
            /*Account_Team__c upsertAccTeam4 = new Account_Team__c();
upsertAccTeam4.BDMPropelI__c = usrBDM3.Id;
upsertAccTeam4.Account__c = rcAccount.Id;
upsertAccTeam4.PropelI_Composite_Key__c =usrBDM3.Id + '::'+ rcAccount.Id;
upsertAccTeam4.PropelI_Branch_Id__c = '1234567';
upsertAccTeam4.Collection__c = true;        
upsertAccTeam4.Submission__c = true; 
upsertAccTeam4.Relationship__c = True;
upsertAccTeam4.RecordTypeId = idProperIrecordType;
insert upsertAccTeam4;
System.assertNotEquals(upsertAccTeam4.Id, Null);*/
            
            // added by Vikas Sharma.
            PropelI_PortfolioMgnmt_Controller.getAssignedSCPortfolios('searchBy', usrBDM1.id, 'searchstr', 'Submission/ Collection', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getAssignedSCPortfolios(null, null, null,'Submission/ Collection', 10, 0, 10);
            //------
            PropelI_PortfolioMgnmt_Controller.getDepartment();
            PropelI_PortfolioMgnmt_Controller.getUsers('Area Manager');
            PropelI_PortfolioMgnmt_Controller.getPortfolioType();
            PropelI_PortfolioMgnmt_Controller.GetUserProfile(usrBDM.Id);
            PropelI_PortfolioMgnmt_Controller.getData();
            PropelI_PortfolioMgnmt_Controller.getSearchBy();  
            PropelI_PortfolioMgnmt_Controller.getAssignedUsrPorfolios('SFX', usrBDM1.Id, sfxNumber, 'Relationship/ National', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getAssignedUsrPorfolios(null, usrBDM1.Id, null, 'Relationship/ National', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getAssignedSCPortfolios(null, usrBDM1.Id, null, 'Submission/ Collection', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getNewPortfolios('MSA', usrBDM1.Id, msaNumber, 'Relationship/ National');
            PropelI_PortfolioMgnmt_Controller.getExSubmissionCollectionMapping('MSA', usrBDM1.Id, msaNumber, 'Submission/ Collection');
            PropelI_PortfolioMgnmt_Controller.getNewPortfolios('SFX', usrBDM1.Id, sfxNumber, 'Relationship/ National');
            PropelI_PortfolioMgnmt_Controller.getExSubmissionCollectionMapping('SFX', usrBDM1.Id, sfxNumber , 'Submission/ Collection');
            PropelI_PortfolioMgnmt_Controller.getNewPortfolios('Rate Card', usrBDM1.Id, rcName, 'Relationship/ National');
            PropelI_PortfolioMgnmt_Controller.getNewPortfolios('Rate Card', usrBDM2.Id, rcName, 'Relationship/ National');
            PropelI_PortfolioMgnmt_Controller.getExSubmissionCollectionMapping('Rate Card', usrBDM1.Id, rcName , 'Submission/ Collection');
            Map<String, Boolean> mapRelationship = new Map<String, Boolean>();
            mapRelationship.put('DELHI SOUTH-11'+'@'+'12345'+':'+sfxNumber+':'+msaNumber, True);
            Map<String, Boolean> mapCCD = new Map<String, Boolean>();
            mapCCD.put(msaNumber, True);
            Map<String, Boolean> mapNAM = new Map<String, Boolean>();
            mapNAM.put(msaNumber, True);
            Map<String, Boolean> mapQRM = new Map<String, Boolean>();
            mapQRM.put(msaNumber, True);
            Map<String, Boolean> mapRM = new Map<String, Boolean>();
            mapRM.put(msaNumber, True);
            Map<String, Boolean> mapCRS = new Map<String, Boolean>();
            mapCRS.put(msaNumber, True);
            PropelI_PortfolioMgnmt_Controller.upsertRNAccountBDM(usrBDM1.Id, mapRelationship, mapCCD,mapNAM, mapQRM,  mapRM, mapCRS);
            Map<String, Boolean> mapCollection = new Map<String, Boolean>();
            mapCollection.put('123456'+':'+sfxNumber+':'+msaNumber, True);
            mapCollection.put('123456'+':'+rcName+':'+sfxNumber+':'+msaNumber, True);
            Map<String, Boolean> mapSubmission = new Map<String, Boolean>();
            mapSubmission.put('123456'+':'+sfxNumber+':'+msaNumber, True);
            mapSubmission.put('123456'+':'+rcName+':'+sfxNumber+':'+msaNumber, True);
            
            PropelI_PortfolioMgnmt_Controller.upsertSCAccountBDM(usrBDM1.Id,  mapCollection,  mapSubmission);
        }
        Test.stopTest();
    }
    
    public static testMethod void portfolioMangmentUnitTesting1()
    {
        Test.startTest();
        //Insert Account Manager
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        System.assertNotEquals(usrAM.Id, Null);
        // Insert BDM.
        List<User> usrList = new List<User>();
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        usrList.add(usrBDM1);
        //insert usrBDM1;
        //System.assertNotEquals(usrBDM1.id, Null);
        // Insert BDM.
        User usrBDM2 =  CommonDataTest.getUserBdm();
        usrBDM2.ManagerId = usrAM.Id;
        usrList.add(usrBDM2);
        //insert usrBDM2;
        //System.assertNotEquals(usrBDM2.id, Null);
        
        User usrBDM3 =  CommonDataTest.getUserBdm();
        usrBDM3.ManagerId = usrAM.Id;
        usrList.add(usrBDM3);
        //insert usrBDM3;
        //System.assertNotEquals(usrBDM3.id, Null);
        // Insert BDM.
        User usrBDM =  CommonDataTest.getUserBdm();
        usrBDM.ManagerId = usrAM.Id;
        usrList.add(usrBDM);
        insert usrList;
        System.runAs(usrBDM)
        {
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
            // Insert rate Card account. 
            Account rcAccount = CommonDataTest.getRateCardAccount();
            rcAccount.ParentId = srvcAccount.Id;
            rcAccount.AssignBranch_ID__c = '123457';
            String rcName = rcAccount.Name;
            
            Insert rcAccount;
            System.assertNotEquals(rcAccount.id, Null);
            
            // Insert Barnch Master.
            Branch_Master__c BMrec = CommonDataTest.getBranchMaster();
            BMrec.Name = 'DELHI SOUTH-12';
            BMrec.Branch_Code__c = 'DLS11';
            insert BMrec;
            System.assertNotEquals(BMrec.Id, Null);
            // Insert Barnch Master.
            Branch_Master__c BMrec1 = CommonDataTest.getBranchMaster();
            BMrec1.Name = 'PANJIM-13';
            BMrec1.Branch_Code__c = 'PJI12';
            insert BMrec1;
            System.assertNotEquals(BMrec1.Id, Null);
            // Insert Branch Account. 
            List<Account> branchAccList = new List<Account>();
            Account brchAccount = CommonDataTest.getBarnchAccount();
            brchAccount.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount.Assign_Branch_Id__c = BMrec.Id;
            brchAccount.Billing_Branch__c = BMrec.Id;
            brchAccount.ParentId = rcAccount.id;
            branchAccList.add(brchAccount);
            //insert brchAccount;
            //System.assertNotEquals(brchAccount.Id, Null);
            
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount1 = CommonDataTest.getBarnchAccount();
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec.Id;
            brchAccount1.Billing_Branch__c = BMrec.Id;
            brchAccount1.ParentId = rcAccount.Id; //ADD by Vikas Sharma
            branchAccList.add(brchAccount1);
            //insert brchAccount1;
            //System.assertNotEquals(brchAccount1.Id, Null);
            insert branchAccList;
            
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
            
            //upsert account_team__c
            List<Account_Team__c> accountTeamList = new List<Account_Team__c>();
            Account_Team__c upsertAccTeam = new Account_Team__c();
            upsertAccTeam.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam.Account__c = msaAccount.Id;
            upsertAccTeam.PropelI_Composite_Key__c =usrBDM.Id + '::'+ msaAccount.Id+':'+rcName;
            upsertAccTeam.National1__c = True;
            upsertAccTeam.National2__c = True;
            upsertAccTeam.CRS__c = True;
            upsertAccTeam.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam);
            //insert upsertAccTeam;
            
            //upsert account_team__c
            Account_Team__c upsertAccTeam5 = new Account_Team__c();
            upsertAccTeam5.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam5.Account__c = msaAccount.Id;
            upsertAccTeam5.PropelI_Composite_Key__c =usrBDM2.Id + '::'+ msaAccount.Id+':'+rcName;
            upsertAccTeam5.National3__c = True;
            upsertAccTeam5.National4__c = True;
            upsertAccTeam5.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam5);
            //insert upsertAccTeam5;
            
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam1.Account__c = sfxAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ sfxAccount.Id+':'+rcName;
            upsertAccTeam1.Collection__c = true;        
            upsertAccTeam1.Submission__c = true; 
            upsertAccTeam1.Relationship__c = true; //Added By Vikas Sharma
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam1);
            //insert upsertAccTeam1;
            //System.assertNotEquals(upsertAccTeam1.Id, Null); 
            
            Account_Team__c upsertAccTeam2 = new Account_Team__c();
            upsertAccTeam2.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam2.Account__c = rcAccount.Id;
            upsertAccTeam2.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ rcAccount.Id+':'+rcName;
            upsertAccTeam2.PropelI_Branch_Id__c = '123456';
            upsertAccTeam2.Collection__c = true;        
            upsertAccTeam2.Submission__c = true; 
            upsertAccTeam2.Relationship__c = True;
            upsertAccTeam2.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam2);
            //insert upsertAccTeam2;
            
            Account_Team__c upsertAccTeam4 = new Account_Team__c();
            upsertAccTeam4.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam4.Account__c = rcAccount.Id;
            upsertAccTeam4.PropelI_Composite_Key__c =usrBDM2.Id + '::'+ rcAccount.Id+':'+rcName;
            upsertAccTeam4.PropelI_Branch_Id__c = '123456';
            upsertAccTeam4.Collection__c = true;        
            upsertAccTeam4.Submission__c = true; 
            upsertAccTeam4.Relationship__c = True;
            upsertAccTeam4.National1__c = True;
            upsertAccTeam4.National2__c = True;
            upsertAccTeam4.National3__c = True;
            upsertAccTeam4.National4__c = True;
            upsertAccTeam4.CRS__c = True;
            upsertAccTeam4.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam4);
            //insert upsertAccTeam4;
            
            Account_Team__c upsertAccTeam6 = new Account_Team__c();
            upsertAccTeam6.BDMPropelI__c = usrBDM3.Id;
            upsertAccTeam6.Account__c = rcAccount.Id;
            upsertAccTeam6.PropelI_Composite_Key__c =usrBDM3.Id + '::'+ rcAccount.Id+':'+rcName;
            upsertAccTeam6.PropelI_Branch_Id__c = '123456';
            upsertAccTeam6.Collection__c = true;        
            upsertAccTeam6.Submission__c = true; 
            upsertAccTeam6.Relationship__c = True;
            upsertAccTeam6.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam6);
            //insert upsertAccTeam6;
            
            Account_Team__c upsertAccTeam3 = new Account_Team__c();
            upsertAccTeam3.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam3.Account__c = msaAccount.Id;
            upsertAccTeam3.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ msaAccount.Id+':'+rcName;
            upsertAccTeam3.National1__c = True;
            upsertAccTeam3.National2__c = True;
            upsertAccTeam3.National3__c = True;
            upsertAccTeam3.National4__c = True;
            upsertAccTeam3.CRS__c = True;
            upsertAccTeam3.Relationship__c = True; //added by Vikas Sharma
            upsertAccTeam3.RecordTypeId = idProperIrecordType;
            accountTeamList.add(upsertAccTeam3);
            //insert upsertAccTeam3;
            //System.assertNotEquals(upsertAccTeam3.Id, Null); 
            insert accountTeamList;
            /* Account_Team__c upsertAccTeam4 = new Account_Team__c();
upsertAccTeam4.BDMPropelI__c = usrBDM1.Id;
upsertAccTeam4.Account__c = rcAccount.Id;
upsertAccTeam4.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ rcAccount.Id;
upsertAccTeam4.PropelI_Branch_Id__c = '1234567';
upsertAccTeam4.Collection__c = true;        
upsertAccTeam4.Submission__c = true; 
upsertAccTeam4.Relationship__c = True;
upsertAccTeam4.RecordTypeId = idProperIrecordType;
insert upsertAccTeam4;
System.assertNotEquals(upsertAccTeam4.Id, Null); */ 
            
            // added by Vikas Sharma.
            PropelI_PortfolioMgnmt_Controller.getAssignedSCPortfolios('searchBy', usrBDM1.id, 'searchstr', 'Submission/ Collection', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getAssignedSCPortfolios(null, null, null,'Submission/ Collection', 10, 0, 10);
            //------
            PropelI_PortfolioMgnmt_Controller.getDepartment();
            PropelI_PortfolioMgnmt_Controller.getUsers('Area Manager');
            PropelI_PortfolioMgnmt_Controller.getPortfolioType();
            PropelI_PortfolioMgnmt_Controller.GetUserProfile(usrBDM.Id);
            PropelI_PortfolioMgnmt_Controller.getData();
            PropelI_PortfolioMgnmt_Controller.getSearchBy();  
            PropelI_PortfolioMgnmt_Controller.getAssignedUsrPorfolios('SFX', usrBDM2.Id, sfxNumber, 'Relationship/ National', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getAssignedUsrPorfolios(null, usrBDM2.Id, null, 'Relationship/ National', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getAssignedSCPortfolios(null, usrBDM2.Id, null, 'Submission/ Collection', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getNewPortfolios('MSA', usrBDM2.Id, msaNumber, 'Relationship/ National');
            PropelI_PortfolioMgnmt_Controller.getExSubmissionCollectionMapping('MSA', usrBDM2.Id, msaNumber, 'Submission/ Collection');
            PropelI_PortfolioMgnmt_Controller.getNewPortfolios('SFX', usrBDM2.Id, sfxNumber, 'Relationship/ National');
            PropelI_PortfolioMgnmt_Controller.getExSubmissionCollectionMapping('SFX', usrBDM2.Id, sfxNumber , 'Submission/ Collection');
            PropelI_PortfolioMgnmt_Controller.getNewPortfolios('Rate Card', usrBDM1.Id, rcName, 'Relationship/ National');
            PropelI_PortfolioMgnmt_Controller.getNewPortfolios('Rate Card', usrBDM1.Id, rcName, 'Relationship/ National');
            PropelI_PortfolioMgnmt_Controller.getExSubmissionCollectionMapping('Rate Card', usrBDM1.Id, rcName , 'Submission/ Collection');
            Map<String, Boolean> mapRelationship = new Map<String, Boolean>();
            mapRelationship.put(rcName+'-'+sfxNumber+'-'+msaNumber, True);
            Map<String, Boolean> mapCCD = new Map<String, Boolean>();
            mapCCD.put(msaNumber, True);
            Map<String, Boolean> mapNAM = new Map<String, Boolean>();
            mapNAM.put(msaNumber, True);
            Map<String, Boolean> mapQRM = new Map<String, Boolean>();
            mapQRM.put(msaNumber, True);
            Map<String, Boolean> mapRM = new Map<String, Boolean>();
            mapRM.put(msaNumber, True);
            Map<String, Boolean> mapCRS = new Map<String, Boolean>();
            mapCRS.put(msaNumber, True);
            PropelI_PortfolioMgnmt_Controller.upsertRNAccountBDM(usrBDM1.Id, mapRelationship, mapCCD,mapNAM, mapQRM,  mapRM, mapCRS);
            Map<String, Boolean> mapCollection = new Map<String, Boolean>();
            mapCollection.put('123456'+':'+sfxNumber+':'+msaNumber, True);
            mapCollection.put('123456'+':'+rcName+':'+sfxNumber+':'+msaNumber, True);
            Map<String, Boolean> mapSubmission = new Map<String, Boolean>();
            mapSubmission.put('123456'+':'+sfxNumber+':'+msaNumber, True);
            mapSubmission.put('123456'+':'+rcName+':'+sfxNumber+':'+msaNumber, True);
            
            PropelI_PortfolioMgnmt_Controller.upsertSCAccountBDM(usrBDM2.Id,  mapCollection,  mapSubmission);
            //PropelI_PortfolioMgnmt_Controller.Wrap_RT_BracnhesPortfolios wrapRT= new PropelI_PortfolioMgnmt_Controller.Wrap_RT_BracnhesPortfolios('RT1003','AIR', 'EDL-12','12345',true, true,true);
        }
        Test.stopTest();
    }
    
    public static testMethod void portfolioMangmentUnitTesting2()
    {
        Test.startTest();
        //Insert Account Manager
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        System.assertNotEquals(usrAM.Id, Null);
        // Insert BDM.
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        insert usrBDM1;
        System.assertNotEquals(usrBDM1.id, Null);
        // Insert BDM.
        User usrBDM2 =  CommonDataTest.getUserBdm();
        usrBDM2.ManagerId = usrAM.Id;
        insert usrBDM2;
        System.assertNotEquals(usrBDM2.id, Null);
        // Insert BDM.
        User usrBDM =  CommonDataTest.getUserBdm();
        usrBDM.ManagerId = usrAM.Id;
        System.runAs(usrBDM)
        {
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
            
            // Insert SFX Account. 
            Account sfxAccount1 = CommonDataTest.getNewSFXAccount();
            String sfxNumber1 = sfxAccount.Name;
            sfxAccount1.ParentId = msaAccount.Id;
            insert sfxAccount1;
            System.assertNotEquals(sfxAccount1.id, Null);
            
            // Insert service account. 
            Account srvcAccount = CommonDataTest.getServiceAccount();
            srvcAccount.ParentId = sfxAccount.id;
            insert srvcAccount;
            System.assertNotEquals(srvcAccount.id, Null);
            
            // Insert service account. 
            Account srvcAccount1 = CommonDataTest.getServiceAccount();
            srvcAccount1.ParentId = sfxAccount1.id;
            insert srvcAccount1;
            System.assertNotEquals(srvcAccount1.id, Null);
            // Insert rate Card account. 
            Account rcAccount = CommonDataTest.getRateCardAccount();
            rcAccount.ParentId = srvcAccount.Id;
            rcAccount.AssignBranch_ID__c = '123457';
            String rcName = rcAccount.Name;
            
            Insert rcAccount;
            System.assertNotEquals(rcAccount.id, Null);
            // Insert rate Card account. 
            Account rcAccount1 = CommonDataTest.getRateCardAccount();
            rcAccount1.ParentId = srvcAccount1.Id;
            rcAccount1.AssignBranch_ID__c = '123459';
            String rcName1 = rcAccount1.Name;
            
            Insert rcAccount1;
            System.assertNotEquals(rcAccount1.id, Null);
            
            // Insert Barnch Master.
            Branch_Master__c BMrec = CommonDataTest.getBranchMaster();
            BMrec.Name = 'DELHI SOUTH-12';
            BMrec.Branch_Code__c = 'DLS11';
            insert BMrec;
            System.assertNotEquals(BMrec.Id, Null);
            // Insert Barnch Master.
            Branch_Master__c BMrec1 = CommonDataTest.getBranchMaster();
            BMrec1.Name = 'PANJIM-13';
            BMrec1.Branch_Code__c = 'PJI12';
            insert BMrec1;
            System.assertNotEquals(BMrec1.Id, Null);
            // Insert Branch Account. 
            Account brchAccount = CommonDataTest.getBarnchAccount();
            brchAccount.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount.Assign_Branch_Id__c = BMrec.Id;
            brchAccount.Billing_Branch__c = BMrec.Id;
            brchAccount.AssignBranch_ID__c = '123456';
            insert brchAccount;
            System.assertNotEquals(brchAccount.Id, Null);
            
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount1 = CommonDataTest.getBarnchAccount();
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec.Id;
            brchAccount1.Billing_Branch__c = BMrec.Id;
            brchAccount1.AssignBranch_ID__c = '123457';
            brchAccount1.ParentId = srvcAccount.Id; //ADD by Vikas Sharma
            insert brchAccount1;
            System.assertNotEquals(brchAccount1.Id, Null);
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount2 = CommonDataTest.getBarnchAccount();
            brchAccount2.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount2.Assign_Branch_Id__c = BMrec.Id;
            brchAccount2.Billing_Branch__c = BMrec.Id;
            brchAccount2.AssignBranch_ID__c = '1234578';
            brchAccount2.ParentId = srvcAccount.Id; //ADD by Vikas Sharma
            insert brchAccount2;
            System.assertNotEquals(brchAccount2.Id, Null);
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount3 = CommonDataTest.getBarnchAccount();
            brchAccount3.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount3.Assign_Branch_Id__c = BMrec.Id;
            brchAccount3.Billing_Branch__c = BMrec.Id;
            brchAccount3.AssignBranch_ID__c = '123459';
            brchAccount3.ParentId = rcAccount1.Id; //ADD by Vikas Sharma
            insert brchAccount3;
            System.assertNotEquals(brchAccount1.Id, Null);
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount4 = CommonDataTest.getBarnchAccount();
            brchAccount4.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount4.Assign_Branch_Id__c = BMrec.Id;
            brchAccount4.Billing_Branch__c = BMrec.Id;
            brchAccount4.AssignBranch_ID__c = '1234599';
            brchAccount4.ParentId = rcAccount1.Id; //ADD by Vikas Sharma
            insert brchAccount4;
            System.assertNotEquals(brchAccount4.Id, Null);
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
            
            //upsert account_team__c
            Account_Team__c upsertAccTeam = new Account_Team__c();
            upsertAccTeam.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam.Account__c = msaAccount.Id;
            upsertAccTeam.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ msaAccount.Id;
            upsertAccTeam.National1__c = True;
            upsertAccTeam.Relationship__c = true;
            upsertAccTeam.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam;
            //upsert account_team__c
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam1.Account__c = rcAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM2.Id +'::'+'123456'+ rcName+':'+sfxNumber+ msaAccount.Id;
            upsertAccTeam1.Relationship__c = true;
            upsertAccTeam1.PropelI_Branch_Id__c = '123456';
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam1;
            //upsert account_team__c
            Account_Team__c upsertAccTeam2 = new Account_Team__c();
            upsertAccTeam2.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam2.Account__c = rcAccount.Id;
            upsertAccTeam2.PropelI_Composite_Key__c =usrBDM2.Id +'::'+'123457'+ rcName+':'+sfxNumber+ msaAccount.Id;
            upsertAccTeam2.Relationship__c = true;
            upsertAccTeam2.National1__c = true;
            upsertAccTeam2.National2__c = true;
            upsertAccTeam2.National3__c = true;
            upsertAccTeam2.National4__c = true;
            upsertAccTeam2.PropelI_Branch_Id__c = '123457';
            upsertAccTeam2.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam2;
            //upsert account_team__c
            Account_Team__c upsertAccTeam3 = new Account_Team__c();
            upsertAccTeam3.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam3.Account__c = rcAccount.Id;
            upsertAccTeam3.PropelI_Composite_Key__c =usrBDM1.Id +'::'+'123458'+ rcName+':'+sfxNumber+ msaAccount.Id;
            upsertAccTeam3.Relationship__c = true;
            upsertAccTeam3.National1__c = true;
            upsertAccTeam3.National2__c = true;
            upsertAccTeam3.National3__c = true;
            upsertAccTeam3.National4__c = true;
            upsertAccTeam3.PropelI_Branch_Id__c = '123458';
            upsertAccTeam3.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam3;
            Account_Team__c upsertAccTeam4 = new Account_Team__c();
            upsertAccTeam4.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam4.Account__c = rcAccount1.Id;
            upsertAccTeam4.PropelI_Composite_Key__c =usrBDM1.Id +'::'+'123459'+ rcName1+':'+sfxNumber1+ msaAccount.Id;
            upsertAccTeam4.Relationship__c = true;
            upsertAccTeam4.National1__c = true;
            upsertAccTeam4.National2__c = true;
            upsertAccTeam4.National3__c = true;
            upsertAccTeam4.National4__c = true;
            upsertAccTeam4.PropelI_Branch_Id__c = '123459';
            upsertAccTeam4.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam4;
            PropelI_PortfolioMgnmt_Controller.getAssignedUsrPorfolios('SFX', usrBDM1.Id, sfxNumber, 'Relationship/ National', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getAssignedUsrPorfolios('SFX', usrBDM2.Id, sfxNumber, 'Relationship/ National', 10, 0, 10);
            PropelI_PortfolioMgnmt_Controller.getAssignedUsrPorfolios('MSA', usrBDM2.Id, msaNumber, 'Relationship/ National', 10, 0, 10);
        }
    } 
}