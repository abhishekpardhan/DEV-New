/**
* Description		:		Test class for OpportunityTriggerHandler apex class
* 
* Coverage			:		91%
**/
@isTest 
public class OpportunityTriggerHandlerTest{
    public static testMethod void portfolioMangmentUnitTesting()
    {
        Test.startTest();
       
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        User usrBDM =  CommonDataTest.getUserBdm(); 
        System.runAs(usrBDM)
        {
            // Create MSA account. 
            Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            msaAccount.Pan_No__c='ASDGH6789K';
            msaAccount.GST__c='08ASDGH6789KKZR';
            insert msaAccount;
            System.assertNotEquals(msaAccount.Id, Null);
            
            // Insert SFX Account. 
            Account sfxAccount = CommonDataTest.getNewSFXAccount();
            String sfxNumber = sfxAccount.Name;
            sfxAccount.ParentId = msaAccount.Id;
            sfxAccount.national1__c = True;
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
            insert brchAccount;
            System.assertNotEquals(brchAccount.Id, Null);
            
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount1 = CommonDataTest.getBarnchAccount();
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec.Id;
            brchAccount1.Billing_Branch__c = BMrec.Id;
            brchAccount1.ParentId = srvcAccount.Id; //ADD by Vikas Sharma
            insert brchAccount1;
            System.assertNotEquals(brchAccount1.Id, Null);
            
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
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrAM.Id;
            upsertAccTeam1.Account__c = sfxAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam1.National1__c = True;
            //upsertAccTeam.CRS__c = True;
            upsertAccTeam1.Billing_By_Id__c = '12341';
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam1;
 
            Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
            objOpp1.Account__c = msaAccount.Id;
            objOpp1.Monthly_Potential_Air__c = 34 ;
            objOpp1.Monthly_Potential_Surface__c = 55;
            objOpp1.X3PL_Potential__c = 60;
            objOpp1.Customer_Type__c = 'New Opportunity';
            objOpp1.Region__c = 'DELHI';
            objOpp1.SFX_Code__c = '12345';
            objOpp1.Gst_Exempted__c = true;
            objOpp1.PAN_No__c = 'ASDGH6789K';
            objOpp1.GST_Number__c ='08ASDGH6789KKZR';
            objOpp1.TAN_No__c = 'QWER12345T';
            objOpp1.Quote_To_be_sent__c = true;
            insert objOpp1;
            
            
            ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
            insert contentVersion_1;
            
            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
            contentlink.LinkedEntityId = objOpp1.id;
            contentlink.LinkedEntityId = objOpp1.Id; 
            contentlink.ContentDocumentId = testcontent.ContentDocumentId;
            insert contentlink;
            
            Business_Detail__c objBD = new Business_Detail__c(GST_No__c='08ASDGH6789KKZR', Billing_State__c='Rajasthan');
            objBD.Opportunity__c = objOpp1.Id;
            objBD.Account__c = msaAccount.Id;
            insert objBD ;
            
            Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon ;
            Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
            
            Contract__c c = new Contract__c();
            c.Account__c = msaAccount.Id;
            c.Contract_Start_Date_MOU_Date__c = Date.today();
            c.Is_valid__c = True;
            c.Credit_Term__c = 'GB';
            Date today = System.today();
            Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
            c.Contract_End_Date__c = lastDayOfMonth;
            c.Bill_Cycle__c = 'Fortnightly';
            c.Service_Requirements__c = 'service';
            c.Claim_Understanding__c = 'Owners Risk';
            c.Description__c = 'description';
            c.Contract_Copy_enclosed__c = 'Yes';
            c.MOU_enclosed__c = 'Yes';
            c.Bill_Submission__c = 'Local';
            c.Bill_Collection__c = 'Local';
            c.Customer_Signed_by_Customer__c = objCon.Id;
            c.Customer_Signed_date__c = Date.Today();
            c.Contract_Signed_by_Safexpress__c = usrBDM.Id;
            c.Safexpress_signed_date__c = Date.today();
            c.Freight_MIS_required__c = 'Yes';
            c.POD_Link_Required__c = 'Yes';
            c.RecordTypeId = openRecordTypeId;
            insert c;
            
            
            Test.stopTest();
        }
    }
     public static testMethod void portfolioMangmentUnitTesting1()
    {
        Test.startTest();
       
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        User usrBDM =  CommonDataTest.getUserBdm(); 
        System.runAs(usrBDM)
        {
            // Create MSA account. 
            Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            msaAccount.Pan_No__c='ASDGH6789K';
            msaAccount.GST__c='08ASDGH6789KKZR';
            insert msaAccount;
            System.assertNotEquals(msaAccount.Id, Null);
            
            // Insert SFX Account. 
            Account sfxAccount = CommonDataTest.getNewSFXAccount();
            String sfxNumber = sfxAccount.Name;
            sfxAccount.ParentId = msaAccount.Id;
            sfxAccount.national1__c = True;
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
            insert brchAccount;
            System.assertNotEquals(brchAccount.Id, Null);
            
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount1 = CommonDataTest.getBarnchAccount();
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec.Id;
            brchAccount1.Billing_Branch__c = BMrec.Id;
            brchAccount1.ParentId = srvcAccount.Id; //ADD by Vikas Sharma
            insert brchAccount1;
            System.assertNotEquals(brchAccount1.Id, Null);
            
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
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrAM.Id;
            upsertAccTeam1.Account__c = sfxAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam1.National1__c = True;
            //upsertAccTeam.CRS__c = True;
            upsertAccTeam1.Billing_By_Id__c = '12341';
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam1;
 
            
            
            
            
            
            Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon ;
            Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
            
            Contract__c c = new Contract__c();
            c.Account__c = msaAccount.Id;
            c.Contract_Start_Date_MOU_Date__c = Date.today();
            c.Is_valid__c = True;
            c.Credit_Term__c = 'GB';
            Date today = System.today();
            Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
            c.Contract_End_Date__c = lastDayOfMonth;
            c.Bill_Cycle__c = 'Fortnightly';
            c.Service_Requirements__c = 'service';
            c.Claim_Understanding__c = 'Owners Risk';
            c.Description__c = 'description';
            c.Contract_Copy_enclosed__c = 'Yes';
            c.MOU_enclosed__c = 'Yes';
            c.Bill_Submission__c = 'Local';
            c.Bill_Collection__c = 'Local';
            c.Customer_Signed_by_Customer__c = objCon.Id;
            c.Customer_Signed_date__c = Date.Today();
            c.Contract_Signed_by_Safexpress__c = usrBDM.Id;
            c.Safexpress_signed_date__c = Date.today();
            c.Freight_MIS_required__c = 'Yes';
            c.POD_Link_Required__c = 'Yes';
            c.RecordTypeId = openRecordTypeId;
            insert c;
            Id rIdquoteNew = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId();
            
           
            Opportunity__c objOpp2 = CommonDataTest.getOpportunity();
            objOpp2.Account__c = msaAccount.Id;
            objOpp2.Monthly_Potential_Air__c = 34 ;
            objOpp2.Monthly_Potential_Surface__c = 55;
            objOpp2.X3PL_Potential__c = 60;
            objOpp2.Region__c = 'DELHI';
            objOpp2.Customer_Type__c = 'Existing-New';
            objOpp2.SFX_Code__c = '12345';
            objOpp2.Gst_Exempted__c = true;
            objOpp2.PAN_No__c = 'ASDGH6789K';
            objOpp2.TAN_No__c = 'QWER12345T';
            objOpp2.Quote_To_be_sent__c = true; 
            insert objOpp2;
            delete objOpp2;
            undelete objOpp2;

            
            Test.stopTest();
        }
    }
     public static testMethod void oppSharingUserTest1() {
         Test.startTest();
        Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            insert msaAccount;
        Opportunity__c objOpp2 = CommonDataTest.getOpportunity();
            objOpp2.Account__c = msaAccount.Id;
            objOpp2.Monthly_Potential_Air__c = 34 ;
            objOpp2.Monthly_Potential_Surface__c = 55;
            objOpp2.X3PL_Potential__c = 60;
            objOpp2.Region__c = 'DELHI';
            objOpp2.Customer_Type__c = 'Existing-New';
            objOpp2.SFX_Code__c = '12345';
            objOpp2.Quote_To_be_sent__c = false;
            objOpp2.Gst_Exempted__c = true;
            objOpp2.PAN_No__c = 'ASDGH6789K';
            objOpp2.TAN_No__c = 'QWER12345T';
            insert objOpp2;
        List<Opportunity__c> opp = new List<Opportunity__c>{objOpp2};
            OpportunityTriggerhandler oppp = new OpportunityTriggerhandler();
        oppp.checkPDF(opp);
        
        Test.stopTest();
    }
    
    public static testMethod void oppSharingUserTest2() {
         Test.startTest();
        Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            insert msaAccount;
        Opportunity__c objOpp2 = CommonDataTest.getOpportunity();
            objOpp2.Account__c = msaAccount.Id;
            objOpp2.Monthly_Potential_Air__c = 34 ;
            objOpp2.Monthly_Potential_Surface__c = 55;
            objOpp2.X3PL_Potential__c = 60;
            objOpp2.Region__c = 'DELHI';
            objOpp2.Customer_Type__c = 'Existing-New';
            objOpp2.SFX_Code__c = '12345';
            objOpp2.Gst_Exempted__c = true;
            objOpp2.PAN_No__c = 'ASDGH6789K';
            objOpp2.TAN_No__c = 'QWER12345T';
            objOpp2.Quote_To_be_sent__c = false;
            insert objOpp2;
        List<String> oppids = new List<String>{objOpp2.id};
        List<Opportunity__c> opp = new List<Opportunity__c>{objOpp2};
        
        OpportunityTriggerhandler.checkPermission(oppids,opp);
        
        Test.stopTest();
    }
    
    public static testMethod void oppSharingUserTest3() {
         Test.startTest();
        Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            msaAccount.Pan_No__c = 'ASDGH6789K';
            msaAccount.GST__c='08ASDGH6789KKZR';
            insert msaAccount;
        
        Opportunity__c objOpp2 = CommonDataTest.getOpportunity();
            objOpp2.Account__c = msaAccount.Id;
            objOpp2.Monthly_Potential_Air__c = 34 ;
            objOpp2.Monthly_Potential_Surface__c = 55;
            objOpp2.X3PL_Potential__c = 60;
            objOpp2.Region__c = 'Rajasthan';
            objOpp2.Customer_Type__c = 'Existing-New';
            objOpp2.SFX_Code__c = '12345';
            objOpp2.Gst_Exempted__c = true;
            objOpp2.PAN_No__c = 'ASDGH6789K';
            objOpp2.GST_Number__c = '08ASDGH6789KKZR';
            objOpp2.TAN_No__c = 'QWER12345T';
            objOpp2.Quote_To_be_sent__c = false;
            insert objOpp2;
        Business_Detail__c objBD1 = new Business_Detail__c(GST_No__c='08ASDGH6789KKZR', Billing_State__c='Rajasthan');
        	objBD1.Account__c = msaAccount.Id;
            objBD1.Opportunity__c = objOpp2.Id;
            insert objBD1 ;
        List<String> oppids = new List<String>{objOpp2.id};
        List<Opportunity__c> opp = new List<Opportunity__c>{objOpp2};
        
        OpportunityTriggerhandler.checkBuisnessDetails(opp);
        
        Test.stopTest();
    }
    
    public static testMethod void oppSharingUserTest4() {
         Test.startTest();
        Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            insert msaAccount;
        
        Account sfxAccount = CommonDataTest.getNewSFXAccount();
            String sfxNumber = sfxAccount.Name;
            sfxAccount.ParentId = msaAccount.Id;
            sfxAccount.national1__c = True;
            insert sfxAccount;
            System.assertNotEquals(sfxAccount.id, Null);
        
        Opportunity__c objOpp2 = CommonDataTest.getOpportunity();
            objOpp2.Account__c = msaAccount.Id;
            objOpp2.Monthly_Potential_Air__c = 34 ;
            objOpp2.Monthly_Potential_Surface__c = 55;
            objOpp2.X3PL_Potential__c = 60;
            objOpp2.Region__c = 'DELHI';
            objOpp2.Customer_Type__c = 'Renewal Opportunity';
            objOpp2.SFX_Code__c = '12345';
            objOpp2.Gst_Exempted__c = true;
            objOpp2.PAN_No__c = 'ASDGH6789K';
            objOpp2.TAN_No__c = 'QWER12345T';
            insert objOpp2;
        /*Business_Detail__c objBD1 = new Business_Detail__c(GST_No__c='08ABAFR3333A1ZR', Billing_State__c='Rajasthan');
            objBD1.Opportunity__c = objOpp2.Id;
            insert objBD1 ;
        List<String> oppids = new List<String>{objOpp2.id};
        List<Opportunity__c> opp = new List<Opportunity__c>{objOpp2};
        
        OpportunityTriggerhandler.checkBuisnessDetails(opp);*/
        
        Test.stopTest();
    }
    
    // Added By Adarsh - SAC-166
        public static testMethod void oppSharingUserTest()
        {
            Test.startTest();
            String userId = userInfo.getUserId();
            USer us = [Select Id from User where Id =: userId limit 1];
            System.runAS(us){
            List<profile> pfList = new List<profile>();
            pfList = [Select Id from profile where Name = 'Area Manager'];                                                   
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = 'test13@test13.com', 
                               Username = 'testabc13@testabc13.com', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = 'test', 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfList[0].Id,
                               Region__c = 'DELHI',
                               AD_Id__c = '123',
                               Department = 'test AM',
                               Designation__c = 'Area manager',
                               Area__c = 'DELHI', 
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'
                              ); 
            Insert UsAM;
            System.assertNotEquals(UsAM.id, Null);
            
            List<Opportunity__c> oppLst = new List<Opportunity__c>();
            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP';
            objOpp.Type__c = 'Retail';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            Insert objOpp;
            System.assertNotEquals(objOpp.id, Null);
            oppLst.add(objOpp);
            
            // Asserts 
            List<opportunity__share> actualOppShares = new List<opportunity__share>();
            opportunity__share oppShare = new opportunity__share();
            oppShare.ParentId = objOpp.Id;
            oppShare.UserOrGroupId = UsAM.Id;
            oppShare.AccessLevel = 'Read';
            insert oppShare;
            System.assertNotEquals(oppShare.id, Null);
            actualOppShares.add(oppShare);
            Test.stopTest();
        }
    }
    //changes end - SAC-166
    
     // Added By Deepika - SAC-844
    public static testMethod void integrationUserOppTest()
    {
        Test.startTest();
       // User us = [Select Id from User where Profile.Name= 'Integration User' limit 1];
        
        List<profile> pfList = new List<profile>();
        pfList = [Select Id from profile where Name = 'System Administrator'];                                                   
        User us=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = 'test13@test13.com', 
                         Username = 'testabc13@testabc13.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'test', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfList[0].Id,
                         Region__c = 'DELHI',
                         AD_Id__c = '123',
                         Department = 'test AM',
                         Designation__c = 'Area manager',
                         Area__c = 'DELHI', 
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                        ); 
        Insert us;
        System.assertNotEquals(us.id, Null);
        List<id> objOppList = new List<id>();
        System.runAS(us){
             Account msaAccount = CommonDataTest.getMSAAccount();
                String msaNumber = msaAccount.Propel_MSACode__c;
                insert msaAccount;
            
            Contact objCon = CommonDataTest.getContact();
                objCon.LeadSource = 'Directory';
                objCon.Contact_State__c = 'Delhi';
                insert objCon ;
                Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
                
                Contract__c c = new Contract__c();
                c.Account__c = msaAccount.Id;
                c.Contract_Start_Date_MOU_Date__c = Date.today();
                c.Is_valid__c = True;
                c.Credit_Term__c = 'GB';
            Date today = System.today();
                Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
                
                c.Contract_End_Date__c = lastDayOfMonth;
               // c.Contract_End_Date__c = date.newInstance(2026, 12, 31);
                c.Bill_Cycle__c = 'Fortnightly';
                c.Service_Requirements__c = 'service';
                c.Claim_Understanding__c = 'Owners Risk';
                c.Description__c = 'description';
                c.Contract_Copy_enclosed__c = 'Yes';
                c.MOU_enclosed__c = 'Yes';
                c.Bill_Submission__c = 'Local';
                c.Bill_Collection__c = 'Local';
                c.Customer_Signed_by_Customer__c = objCon.Id;
                c.Customer_Signed_date__c = Date.Today();
                c.Contract_Signed_by_Safexpress__c = us.Id;
                c.Safexpress_signed_date__c = Date.today();
                c.Freight_MIS_required__c = 'Yes';
                c.POD_Link_Required__c = 'Yes';
                c.RecordTypeId = openRecordTypeId;
                insert c;
            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP NEW TEST';
            objOpp.Type__c = 'Retail';
            objOpp.Stage__c = 'Active';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            objOpp.Account__c = msaAccount.Id;
            objOpp.Contract__c = c.Id;
            objOpp.Valid_for_Contract_Tagging__c = true;
            Insert objOpp;
            objOppList.add(objOpp.Id);
            objOpp.Stage__c = 'Closed Won';
            //objOpp.Lost_Reason__c = 'Customer Not Interested';
            Update objOpp;
        }
       // OpportunityTriggerHandler.updateOpportunityToClosedWon(objOppList);
        
        Opportunity__c objOppo = [Select Id,Stage__c,CreatedBy.Profile.Name from Opportunity__c Where Id IN :objOppList Limit 1];

         System.assertEquals('System Administrator', objOppo.CreatedBy.Profile.Name);
         System.assertEquals('Closed Won', objOppo.Stage__c);
        Test.stopTest();
    }
    //changes end - SAC-166
    //
   
    public static testMethod void integrationUserOppTest1()
    {
        Test.startTest();
        List<profile> pfList = new List<profile>();
        pfList = [Select Id from profile where Name = 'System Administrator'];                                                   
        User us=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = 'test13@test13.com', 
                         Username = 'testabc13@testabc13.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'test', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfList[0].Id,
                         Region__c = 'DELHI',
                         AD_Id__c = '123',
                         Department = 'test AM',
                         Designation__c = 'Area manager',
                         Area__c = 'DELHI', 
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                        ); 
        Insert us;
        System.assertNotEquals(us.id, Null);
        List<id> objOppList = new List<id>();
        System.runAS(us){
             Account msaAccount = CommonDataTest.getMSAAccount();
                String msaNumber = msaAccount.Propel_MSACode__c;
                insert msaAccount;
            
            Contact objCon = CommonDataTest.getContact();
                objCon.LeadSource = 'Directory';
                objCon.Contact_State__c = 'Delhi';
                insert objCon ;
                Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
                
                Contract__c c = new Contract__c();
                c.Account__c = msaAccount.Id;
                c.Contract_Start_Date_MOU_Date__c = Date.today();
                c.Is_valid__c = True;
                c.Credit_Term__c = 'GB';
            	Date today = System.today();
                Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
                
                c.Contract_End_Date__c = lastDayOfMonth;
              
                c.Bill_Cycle__c = 'Fortnightly';
                c.Service_Requirements__c = 'service';
                c.Claim_Understanding__c = 'Owners Risk';
                c.Description__c = 'description';
                c.Contract_Copy_enclosed__c = 'Yes';
                c.MOU_enclosed__c = 'Yes';
                c.Bill_Submission__c = 'Local';
                c.Bill_Collection__c = 'Local';
                c.Customer_Signed_by_Customer__c = objCon.Id;
                c.Customer_Signed_date__c = Date.Today();
                c.Contract_Signed_by_Safexpress__c = us.Id;
                c.Safexpress_signed_date__c = Date.today();
                c.Freight_MIS_required__c = 'Yes';
                c.POD_Link_Required__c = 'Yes';
                c.RecordTypeId = openRecordTypeId;
                insert c;
            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP NEW TEST';
            objOpp.Type__c = 'Credit+Retail';
            objOpp.GST_Number__c ='09ASDGH6789K1ZZ';
            objOpp.TAN_No__c = 'PDES03028F';
            objOpp.Stage__c = 'Active';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            objOpp.Account__c = msaAccount.Id;
            objOpp.Contract__c = c.Id;
            objOpp.Valid_for_Contract_Tagging__c = true;
            Insert objOpp;
            objOppList.add(objOpp.Id);
            objOpp.Stage__c = 'Closed Won';
            //objOpp.Lost_Reason__c = 'Customer Not Interested';
            Update objOpp;
        }
        Opportunity__c objOppo = [Select Id,Stage__c,CreatedBy.Profile.Name from Opportunity__c Where Id IN :objOppList Limit 1];

         System.assertEquals('System Administrator', objOppo.CreatedBy.Profile.Name);
         System.assertEquals('Closed Won', objOppo.Stage__c);
        Test.stopTest();
    }
    
    public static testMethod void integrationUserOppTest11()
    {
        Test.startTest();
        List<profile> pfList = new List<profile>();
        pfList = [Select Id from profile where Name = 'System Administrator'];                                                   
        User us=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = 'test13@test13.com', 
                         Username = 'testabc13@testabc13.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'test', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfList[0].Id,
                         Region__c = 'DELHI',
                         AD_Id__c = '123',
                         Department = 'test AM',
                         Designation__c = 'Area manager',
                         Area__c = 'DELHI', 
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                        ); 
        Insert us;
        System.assertNotEquals(us.id, Null);
        List<id> objOppList = new List<id>();
        System.runAS(us){
             Account msaAccount = CommonDataTest.getMSAAccount();
                String msaNumber = msaAccount.Propel_MSACode__c;
                msaAccount.GST__c = '09ASDGH6789K1ZZ';
                insert msaAccount;
            
            Contact objCon = CommonDataTest.getContact();
                objCon.LeadSource = 'Directory';
                objCon.Contact_State__c = 'Delhi';
                insert objCon ;
                Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
                
                Contract__c c = new Contract__c();
                c.Account__c = msaAccount.Id;
                c.Contract_Start_Date_MOU_Date__c = Date.today();
                c.Is_valid__c = True;
                c.Credit_Term__c = 'GB';
            Date today = System.today();
                Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
                
                c.Contract_End_Date__c = lastDayOfMonth;
                //c.Contract_End_Date__c = date.newInstance(2025, 12, 31);
                c.Bill_Cycle__c = 'Fortnightly';
                c.Service_Requirements__c = 'service';
                c.Claim_Understanding__c = 'Owners Risk';
                c.Description__c = 'description';
                c.Contract_Copy_enclosed__c = 'Yes';
                c.MOU_enclosed__c = 'Yes';
                c.Bill_Submission__c = 'Local';
                c.Bill_Collection__c = 'Local';
                c.Customer_Signed_by_Customer__c = objCon.Id;
                c.Customer_Signed_date__c = Date.Today();
                c.Contract_Signed_by_Safexpress__c = us.Id;
                c.Safexpress_signed_date__c = Date.today();
                c.Freight_MIS_required__c = 'Yes';
                c.POD_Link_Required__c = 'Yes';
                c.RecordTypeId = openRecordTypeId;
                insert c;
            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP NEW TEST';
            objOpp.Type__c = 'Retail';
            objOpp.GST_Number__c ='09ASDGH6789K1ZZ';
            objOpp.TAN_No__c = 'PDES03028F';
            objOpp.Stage__c = 'Active';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            objOpp.Account__c = msaAccount.Id;
            objOpp.Contract__c = c.Id;
            objOpp.Valid_for_Contract_Tagging__c = true;
            Insert objOpp;
            objOppList.add(objOpp.Id);
            objOpp.Stage__c = 'Closed Won';
            //objOpp.Lost_Reason__c = 'Customer Not Interested';
            Update objOpp;
        }
        Opportunity__c objOppo = [Select Id,Stage__c,CreatedBy.Profile.Name from Opportunity__c Where Id IN :objOppList Limit 1];

         System.assertEquals('System Administrator', objOppo.CreatedBy.Profile.Name);
         System.assertEquals('Closed Won', objOppo.Stage__c);
        Test.stopTest();
    }
 public static testMethod void retailbdmuseropprtunity()
    {
        Test.startTest();
       
        User usrAM = CommonDataTest.getUserRetailBDM();
        insert usrAM;
        User usrBDM =  CommonDataTest.getUserRetailBDM(); 
        System.runAs(usrBDM)
        {
            // Create MSA account. 
            Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            msaAccount.Pan_No__c='ASDGH6789K';
            msaAccount.GST__c='08ASDGH6789KKZR';
            insert msaAccount;
            System.assertNotEquals(msaAccount.Id, Null);
            
            // Insert SFX Account. 
            Account sfxAccount = CommonDataTest.getNewSFXAccount();
            String sfxNumber = sfxAccount.Name;
            sfxAccount.ParentId = msaAccount.Id;
            sfxAccount.national1__c = True;
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
            insert brchAccount;
            System.assertNotEquals(brchAccount.Id, Null);
            
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount1 = CommonDataTest.getBarnchAccount();
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec.Id;
            brchAccount1.Billing_Branch__c = BMrec.Id;
            brchAccount1.ParentId = srvcAccount.Id; //ADD by Vikas Sharma
            insert brchAccount1;
            System.assertNotEquals(brchAccount1.Id, Null);
            
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
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrAM.Id;
            upsertAccTeam1.Account__c = sfxAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam1.National1__c = True;
            //upsertAccTeam.CRS__c = True;
            upsertAccTeam1.Billing_By_Id__c = '12341';
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam1;
 
            Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
            objOpp1.Account__c = msaAccount.Id;
            objOpp1.Monthly_Potential_Air__c = 34 ;
            objOpp1.Monthly_Potential_Surface__c = 55;
            objOpp1.X3PL_Potential__c = 60;
            objOpp1.Customer_Type__c = 'New Opportunity';
            objOpp1.Region__c = 'DELHI';
            objOpp1.SFX_Code__c = '12345';
            objOpp1.Gst_Exempted__c = true;
            objOpp1.PAN_No__c = 'ASDGH6789K';
            objOpp1.GST_Number__c ='08ASDGH6789KKZR';
            objOpp1.TAN_No__c = 'QWER12345T';
            objOpp1.Quote_To_be_sent__c = true;
            insert objOpp1;
             objOpp1.X3PL_Potential__c = 70;
            Update objOpp1;
            
            ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
            insert contentVersion_1;
            
            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
            contentlink.LinkedEntityId = objOpp1.id;
            contentlink.LinkedEntityId = objOpp1.Id; 
            contentlink.ContentDocumentId = testcontent.ContentDocumentId;
            insert contentlink;
            
            Business_Detail__c objBD = new Business_Detail__c(GST_No__c='08ASDGH6789KKZR', Billing_State__c='Rajasthan');
            objBD.Opportunity__c = objOpp1.Id;
            objBD.Account__c = msaAccount.Id;
            insert objBD ;
            
            Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon ;
            Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
            
            Contract__c c = new Contract__c();
            c.Account__c = msaAccount.Id;
            c.Contract_Start_Date_MOU_Date__c = Date.today();
            c.Is_valid__c = True;
            c.Credit_Term__c = 'GB';
            Date today = System.today();
            Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
            c.Contract_End_Date__c = lastDayOfMonth;
            c.Bill_Cycle__c = 'Fortnightly';
            c.Service_Requirements__c = 'service';
            c.Claim_Understanding__c = 'Owners Risk';
            c.Description__c = 'description';
            c.Contract_Copy_enclosed__c = 'Yes';
            c.MOU_enclosed__c = 'Yes';
            c.Bill_Submission__c = 'Local';
            c.Bill_Collection__c = 'Local';
            c.Customer_Signed_by_Customer__c = objCon.Id;
            c.Customer_Signed_date__c = Date.Today();
            c.Contract_Signed_by_Safexpress__c = usrBDM.Id;
            c.Safexpress_signed_date__c = Date.today();
            c.Freight_MIS_required__c = 'Yes';
            c.POD_Link_Required__c = 'Yes';
            c.RecordTypeId = openRecordTypeId;
            insert c;
            
            
            Test.stopTest();
        }
    }
    public static testMethod void RegionalRetailManageruseropprtunity()
    {
        Test.startTest();
       
        User usrAM = CommonDataTest.getUserRegionalRetailManager();
        insert usrAM;
        User usrBDM =  CommonDataTest.getUserRegionalRetailManager(); 
        System.runAs(usrBDM)
        {
            // Create MSA account. 
            Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            msaAccount.Pan_No__c='ASDGH6789K';
            msaAccount.GST__c='08ASDGH6789KKZR';
            insert msaAccount;
            System.assertNotEquals(msaAccount.Id, Null);
            
            // Insert SFX Account. 
            Account sfxAccount = CommonDataTest.getNewSFXAccount();
            String sfxNumber = sfxAccount.Name;
            sfxAccount.ParentId = msaAccount.Id;
            sfxAccount.national1__c = True;
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
            insert brchAccount;
            System.assertNotEquals(brchAccount.Id, Null);
            
            // Insert Branch Account. added by Vikas Sharma brchAccount1
            Account brchAccount1 = CommonDataTest.getBarnchAccount();
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec.Id;
            brchAccount1.Billing_Branch__c = BMrec.Id;
            brchAccount1.ParentId = srvcAccount.Id; //ADD by Vikas Sharma
            insert brchAccount1;
            System.assertNotEquals(brchAccount1.Id, Null);
            
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
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrAM.Id;
            upsertAccTeam1.Account__c = sfxAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam1.National1__c = True;
            //upsertAccTeam.CRS__c = True;
            upsertAccTeam1.Billing_By_Id__c = '12341';
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam1;
 
            Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
            objOpp1.Account__c = msaAccount.Id;
            objOpp1.Monthly_Potential_Air__c = 34 ;
            objOpp1.Monthly_Potential_Surface__c = 55;
            objOpp1.X3PL_Potential__c = 60;
            objOpp1.Customer_Type__c = 'New Opportunity';
            objOpp1.Region__c = 'DELHI';
            objOpp1.SFX_Code__c = '12345';
            objOpp1.Gst_Exempted__c = true;
            objOpp1.PAN_No__c = 'ASDGH6789K';
            objOpp1.GST_Number__c ='08ASDGH6789KKZR';
            objOpp1.TAN_No__c = 'QWER12345T';
            objOpp1.Quote_To_be_sent__c = true;
            insert objOpp1;
              objOpp1.X3PL_Potential__c = 70;
            Update objOpp1;
            ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
            insert contentVersion_1;
            
            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
            contentlink.LinkedEntityId = objOpp1.id;
            contentlink.LinkedEntityId = objOpp1.Id; 
            contentlink.ContentDocumentId = testcontent.ContentDocumentId;
            insert contentlink;
            
            Business_Detail__c objBD = new Business_Detail__c(GST_No__c='08ASDGH6789KKZR', Billing_State__c='Rajasthan');
            objBD.Opportunity__c = objOpp1.Id;
            objBD.Account__c = msaAccount.Id;
            insert objBD ;
            
            Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon ;
            Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
            
            Contract__c c = new Contract__c();
            c.Account__c = msaAccount.Id;
            c.Contract_Start_Date_MOU_Date__c = Date.today();
            c.Is_valid__c = True;
            c.Credit_Term__c = 'GB';
            Date today = System.today();
            Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
            c.Contract_End_Date__c = lastDayOfMonth;
            c.Bill_Cycle__c = 'Fortnightly';
            c.Service_Requirements__c = 'service';
            c.Claim_Understanding__c = 'Owners Risk';
            c.Description__c = 'description';
            c.Contract_Copy_enclosed__c = 'Yes';
            c.MOU_enclosed__c = 'Yes';
            c.Bill_Submission__c = 'Local';
            c.Bill_Collection__c = 'Local';
            c.Customer_Signed_by_Customer__c = objCon.Id;
            c.Customer_Signed_date__c = Date.Today();
            c.Contract_Signed_by_Safexpress__c = usrBDM.Id;
            c.Safexpress_signed_date__c = Date.today();
            c.Freight_MIS_required__c = 'Yes';
            c.POD_Link_Required__c = 'Yes';
            c.RecordTypeId = openRecordTypeId;
            insert c;
            
            
            Test.stopTest();
        }
    }
    
}