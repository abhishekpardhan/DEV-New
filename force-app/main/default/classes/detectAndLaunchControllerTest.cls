@isTest 
public class detectAndLaunchControllerTest {
    public static testMethod void portfolioMangmentUnitTesting() {
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
        User usrBDM4 =  CommonDataTest.getUserBdm();
        usrBDM4.ManagerId = usrAM.Id;
        insert usrBDM4;
        System.assertNotEquals(usrBDM4.id, Null);
        
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
            
            // Insert rate Card account. 
            Account rcAccount1 = CommonDataTest.getRateCardAccount();
            rcAccount1.ParentId = srvcAccount.Id;
            rcAccount1.AssignBranch_ID__c = '123456';
            String rcName1 = rcAccount1.Name;
            Insert rcAccount1;
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
            brchAccount1.Name = 'ASSIGN BRANCH:' + rcName1 + sfxNumber;
            brchAccount1.Assign_Branch_Id__c = BMrec1.Id;
            brchAccount1.Billing_Branch__c = BMrec1.Id;
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
            
            Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
            objOpp1.Account__c = msaAccount.Id;
            objOpp1.Monthly_Potential_Air__c = 34 ;
            objOpp1.Monthly_Potential_Surface__c = 55;
            objOpp1.X3PL_Potential__c = 60;
            objOpp1.Customer_Type__c = 'Renewal Opportunity';
            objOpp1.Region__c = 'DELHI';
            objOpp1.SFX_Code__c = '12345';
            objOpp1.Gst_Exempted__c = true;
            objOpp1.PAN_No__c = 'ASDGH6789K';
            objOpp1.TAN_No__c = 'QWER12345T';
            insert objOpp1;
            
            String str = sfxNumber+'='+rcName+', '+rcName1;
            List<String> strList = new List<String>();
            strList.add(str);
            
            detectAndLaunchController.checkMapping(objOpp1.Id);
            detectAndLaunchController.getSFXAndRateCards(msaAccount.Id, 'New', objOpp1.Id);
            detectAndLaunchController.updateSFXAndRC(strList, objOpp1.Id);
            
        }
        Test.stopTest();
    }
}