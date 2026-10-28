@isTest
public class PropelIActiveCodeBatchTest {
    public static testMethod void portfolioMangmentUnitTesting()
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
        User usrBDM3 =  CommonDataTest.getUserBdm();
        usrBDM3.ManagerId = usrAM.Id;
        insert usrBDM3;
        System.assertNotEquals(usrBDM3.id, Null);
        
        // Insert BDM.
        User usrBDM =  CommonDataTest.getUserBdm();
        usrBDM.ManagerId = usrAM.Id;
        
        System.runAs(usrBDM)
        {
            
            Branch_Master__c BMrec0 = CommonDataTest.getBranchMaster();
            BMrec0.Name = 'DELHI SOUTH-12';
            BMrec0.Branch_Code__c = 'DLS12';
            insert BMrec0;
            System.assertNotEquals(BMrec0.Id, Null);
            
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
            rcAccount.Base_Location__c = BMrec0.Id;
            rcAccount.AssignBranch_ID__c = '123456';
            String rcName = rcAccount.Name;
            
            Insert rcAccount;
            System.assertNotEquals(rcAccount.id, Null);
            
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
            brchAccount.ParentId = rcAccount.Id;
            brchAccount.Billing_Branch__c = BMrec.Id;
            insert brchAccount;
            System.assertNotEquals(brchAccount.Id, Null);
            
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount1 = CommonDataTest.getBarnchAccount();
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec1.Id;
            brchAccount1.Billing_Branch__c = BMrec1.Id;
            brchAccount1.ParentId = rcAccount.Id; //ADD by Vikas Sharma
            insert brchAccount1;
            System.assertNotEquals(brchAccount1.Id, Null);
            
            // Create billing information record. 
            Billing_Information__c upsert_BillRec = new Billing_Information__c();
            upsert_BillRec.Billing_Level__c = 'MSA';
            upsert_BillRec.MSA__c = msaNumber;
            upsert_BillRec.SFX_no__c = sfxNumber;
            upsert_BillRec.SFX__c = sfxAccount.id;
            upsert_BillRec.Start_Date__c = System.today();
            upsert_BillRec.Alias_name__c = 'JSON Test 1';
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
            upsertBillingLineItems.Composite_Key__c = msaNumber + '::'+sfxNumber+'::'+ rcName+ '::' + '4853'; 
            insert upsertBillingLineItems;
            System.assertNotEquals(upsertBillingLineItems.Id, Null); 
            
            Billing_Information__c upsert_BillRec1 = new Billing_Information__c();
            upsert_BillRec1.Billing_Level__c = 'SFX';
            upsert_BillRec1.MSA__c = msaNumber;
            upsert_BillRec1.SFX_no__c = sfxNumber;
            upsert_BillRec1.SFX__c = sfxAccount.id;
            upsert_BillRec1.Start_Date__c = System.today();
            upsert_BillRec1.Alias_name__c = 'JSON Test 2';
            upsert_BillRec1.Billing_Config_Id__c = 4854;
            upsert_BillRec1.Name = 'Billing Info:' + msaNumber+':'+ sfxNumber;
            insert upsert_BillRec1;
            System.assertNotEquals(upsert_BillRec1.Id, Null);
            
            // Add billing line items. 
            Billing_Line_Item__c upsertBillingLineItems1 = new Billing_Line_Item__c();
            upsertBillingLineItems1.Submission_Branch__c = BMrec.Id;
            upsertBillingLineItems1.Collection_Branch__c = BMrec.Id;
            upsertBillingLineItems1.Billing_Branch__c = BMrec.Id;
            upsertBillingLineItems1.Billing_Information__c = upsert_BillRec1.Id; 
            upsertBillingLineItems1.Composite_Key__c = msaNumber + '::'+sfxNumber+'::'+ '4854'; 
            insert upsertBillingLineItems1;
            System.assertNotEquals(upsertBillingLineItems1.Id, Null); 
            
             Billing_Information__c upsert_BillRec2 = new Billing_Information__c();
            upsert_BillRec2.Billing_Level__c = 'Rate Card';
            upsert_BillRec2.MSA__c = msaNumber;
            upsert_BillRec2.SFX_no__c = sfxNumber;
            upsert_BillRec2.SFX__c = sfxAccount.id;
            upsert_BillRec2.Rate_Card_no__c = rcName;
            upsert_BillRec2.Start_Date__c = System.today();
            upsert_BillRec2.Alias_name__c = 'JSON Test 3';
            upsert_BillRec2.Billing_Config_Id__c = 4855;
            upsert_BillRec2.Name = 'Billing Info:' + msaNumber+':'+ sfxNumber+':'+rcName;
            insert upsert_BillRec2;
            System.assertNotEquals(upsert_BillRec2.Id, Null);
            
            // Add billing line items. 
            Billing_Line_Item__c upsertBillingLineItems2 = new Billing_Line_Item__c();
            upsertBillingLineItems2.Submission_Branch__c = BMrec.Id;
            upsertBillingLineItems2.Collection_Branch__c = BMrec.Id;
            upsertBillingLineItems2.Billing_Branch__c = BMrec.Id;
            upsertBillingLineItems2.Billing_Information__c = upsert_BillRec2.Id; 
            upsertBillingLineItems2.Composite_Key__c =  msaNumber+ '::'+sfxNumber+'::'+rcName+'::'+'4855'; 
            insert upsertBillingLineItems2;
            System.assertNotEquals(upsertBillingLineItems2.Id, Null); 
            
            
            Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
            
            //upsert account_team__c
            Account_Team__c upsertAccTeam = new Account_Team__c();
            upsertAccTeam.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam.Account__c = msaAccount.Id;
            upsertAccTeam.PropelI_Composite_Key__c =usrBDM.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam.National1__c = True;
            upsertAccTeam.National2__c = True;
            upsertAccTeam.NSM__c = true;
            upsertAccTeam.National3__c = true;
            upsertAccTeam.National4__c = true;
            upsertAccTeam.CRS__c = True;
            upsertAccTeam.Billing_By_Id__c = '12341';
            upsertAccTeam.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam;
            
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam1.Account__c = sfxAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ sfxAccount.Id;
            upsertAccTeam1.Collection__c = true;        
            upsertAccTeam1.Submission__c = true; 
            upsertAccTeam1.Billing_By_Id__c = '12342';
            upsertAccTeam1.Relationship__c = true; //Added By Vikas Sharma
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam1;
            System.assertNotEquals(upsertAccTeam1.Id, Null); 
            
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
            insert upsertAccTeam2;
            
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
            insert upsertAccTeam4;
            
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
            insert upsertAccTeam3;
            System.assertNotEquals(upsertAccTeam3.Id, Null); 
            
            //upsert account_team__c
            Account_Team__c upsertAccTeam5 = new Account_Team__c();
            upsertAccTeam5.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam5.Account__c = msaAccount.Id;
            upsertAccTeam5.PropelI_Composite_Key__c =usrBDM2.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam5.National3__c = True;
            upsertAccTeam5.Billing_By_Id__c = '12346';
            upsertAccTeam5.National4__c = True;
            upsertAccTeam5.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam5;
            
            Account_Team__c upsertAccTeam6 = new Account_Team__c();
            upsertAccTeam6.BDMPropelI__c = usrBDM2.Id;
            upsertAccTeam6.Account__c = sfxAccount.Id;
            upsertAccTeam6.PropelI_Composite_Key__c =usrBDM2.Id + '::'+ sfxAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam6.Collection__c = true;        
            upsertAccTeam6.Submission__c = true; 
            upsertAccTeam6.Relationship__c = true; //Added By Vikas Sharma
            upsertAccTeam6.RecordTypeId = idProperIrecordType;
            upsertAccTeam6.Billing_By_Id__c = '12347';
            insert upsertAccTeam6;
            System.assertNotEquals(upsertAccTeam6.Id, Null); 
            
            Account_Team__c upsertAccTeam7 = new Account_Team__c();
            upsertAccTeam7.BDMPropelI__c = usrBDM3.Id;
            upsertAccTeam7.Account__c = sfxAccount.Id;
            upsertAccTeam7.PropelI_Composite_Key__c =usrBDM3.Id + '::'+ sfxAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam7.Collection__c = true;        
            upsertAccTeam7.Submission__c = true; 
            upsertAccTeam7.Relationship__c = true; //Added By Vikas Sharma
            upsertAccTeam7.RecordTypeId = idProperIrecordType;
            upsertAccTeam7.Billing_By_Id__c = '12348';
            insert upsertAccTeam7;
            System.assertNotEquals(upsertAccTeam7.Id, Null); 
            
            PropelI_Active_Code__c code1 = new PropelI_Active_Code__c();
            code1.MSA__c = msaNumber;
            code1.SFX__c = sfxNumber;
            code1.Rate_Card__c = rcName;
            code1.Composite_Key__c = msaNumber+'::'+sfxNumber+'::'+rcName;
            
            PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
            mapping.Account__c = msaAccount.Id;
            mapping.PropelI_BDM__c = usrBDM.Id;
            mapping.CCD__c = true;
            mapping.PropelI_Composite_Key__c = usrBDM.Id+'::'+msaAccount.Id;
            insert mapping;
            
            delete mapping;
            
        }
        
        Database.executeBatch(new BatchToDeletePropelIActiveCode(new List<String>()), 200);
        
        SchedulePropelIActiveCodeBatch batch = new SchedulePropelIActiveCodeBatch();
        String sch = '0 0 0 * * ? *';
        String jobIDNew = system.schedule('Batch Scheduled', sch, batch);
        
        Test.stopTest();
    }
}