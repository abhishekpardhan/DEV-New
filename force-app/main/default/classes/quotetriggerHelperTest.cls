//Code Coverage: 83%
@isTest 
public class quotetriggerHelperTest{
    static testMethod void quoteTriggerUnitTest(){
        User usrAM = CommonDataTest.getUserAM();
        insert usrAM;
        System.assertNotEquals(usrAM.Id, Null);
        
        // Insert BDM.
        User usrBDM1 =  CommonDataTest.getUserBdm();
        usrBDM1.ManagerId = usrAM.Id;
        insert usrBDM1;
        System.assertNotEquals(usrBDM1.id, Null);
        
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
            
            Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
            objOpp1.Type__c = 'Credit';
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
            objOpp1.LatestQuote__c = null;
            insert objOpp1;
            
            //insert Contact
            Contact objCont = CommonDataTest.getContact();
            objCont.Opportunity_Name__c = objOpp1.Id;
            insert objCont;
            
            //upsert account_team__c
            Account_Team__c upsertAccTeam1 = new Account_Team__c();
            upsertAccTeam1.BDMPropelI__c = usrBDM1.Id;
            upsertAccTeam1.Account__c = sfxAccount.Id;
            upsertAccTeam1.PropelI_Composite_Key__c =usrBDM1.Id + '::'+ msaAccount.Id+':'+sfxNumber+':'+rcName;
            upsertAccTeam1.Collection__c = True;
            upsertAccTeam1.National1__c = true;
            //upsertAccTeam.CRS__c = True;
            upsertAccTeam1.Billing_By_Id__c = '12341';
            upsertAccTeam1.RecordTypeId = idProperIrecordType;
            insert upsertAccTeam1;
            Test.startTest();

            
            Renewal_SFX_RC_Mapping__c mapping = new Renewal_SFX_RC_Mapping__c();
            mapping.SFX__c = sfxAccount.Id;
            mapping.Rate_Card__c = rcAccount.Id;
            mapping.Opportunity__c = objOpp1.Id;
            insert mapping;
            
            Id rIdquoteNew = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId();
            
            Quote__c objQuo = CommonDataTest.getQuote();
            objQuo.Opportunity__c = objOpp1.Id;  
            objQuo.Enter_Remarks__c = null;
            objQuo.recordTypeId = rIdquoteNew;
            insert objQuo;
            System.debug('<< objQuo.name >> '+[Select name from Quote__c where Id =: objQuo.id limit 1].name);
            
            ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
            insert contentVersion_1;
            
            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
            contentlink.LinkedEntityId=objQuo.id;
            contentlink.LinkedEntityId = objQuo.Id; 
            contentlink.ContentDocumentId=testcontent.ContentDocumentId;
            insert contentlink;
            
            System.debug('<< objQuo.name >> '+[Select name from Quote__c where Id =: objQuo.id limit 1].name);
            objQuo.Enter_Remarks__c = 'Test remarks';
            objQuo.name = 'TEST OPP-TEST QUOTE';
            Update objQuo;
            List<Quote_Line_Item__c> quoteLineList = new List<Quote_Line_Item__c>();
            Quote_Line_Item__c  objQuoLineLine = CommonDataTest.getQuoteLineItem();
            objQuoLineLine.Quote__c = objQuo.id;
            objQuoLineLine.Type__c = 'Zone Prices';
            quoteLineList.add(objQuoLineLine);
            Quote_Line_Item__c  objQuoLine1 = CommonDataTest.getQuoteLineItem();
            objQuoLine1.Quote__c = objQuo.id;
            objQuoLine1.Type__c = 'Commandments';
            quoteLineList.add(objQuoLine1);

            Quote_Line_Item__c  objQuoLine2 = CommonDataTest.getQuoteLineItem();
            objQuoLine2.Quote__c = objQuo.id;
            objQuoLine2.Type__c = 'Special Destinations';
            quoteLineList.add(objQuoLine2);

            Quote_Line_Item__c  objQuoLine3 = CommonDataTest.getQuoteLineItem();
            objQuoLine3.Quote__c = objQuo.id;
            objQuoLine3.Type__c = 'State Surcharge';
            quoteLineList.add(objQuoLine3);

            Quote_Line_Item__c  objQuoLine4 = CommonDataTest.getQuoteLineItem();
            objQuoLine4.Quote__c = objQuo.id;
            objQuoLine4.Type__c = 'Safextension';
            quoteLineList.add(objQuoLine4);
			insert quoteLineList;
            
           // objQuo.Approval_Status__c = 'Submitted for Approval';
            update objQuo;
            objQuo.Approval_Status__c = 'Rejected By RM';
            update objQuo;
            Test.stopTest();
            
        }
    }
        
   
    static testMethod void testBatchUpdateOpportunityWithQuote() {
        Test.startTest();

        // Step 1: Create Test Data (Insert MSA account, Opportunity, and Quote)
        Account msaAccount = CommonDataTest.getMSAAccount();
        insert msaAccount;

        Opportunity__c testOpportunity = CommonDataTest.getOpportunity();
        testOpportunity.Account__c = msaAccount.Id;
        testOpportunity.LatestQuote__c = null;
        insert testOpportunity;

        Quote__c testQuote = CommonDataTest.getQuote();
        testQuote.Opportunity__c = testOpportunity.Id;
        insert testQuote;

        // Step 2: Execute the batch process
        Database.executeBatch(new UpdateOpportunityWithQuoteBatch(), 200);

        Test.stopTest();

        // Step 3: Validate the Result
        testOpportunity = [SELECT Id, LatestQuote__c FROM Opportunity__c WHERE Id = :testOpportunity.Id];
        System.assertNotEquals(null, testOpportunity.LatestQuote__c, 'LatestQuote__c should be updated by the batch process.');
        System.assertEquals(testQuote.Id, testOpportunity.LatestQuote__c, 'LatestQuote__c should match the most recent Quote associated with the Opportunity.');
    }

    // Additional Test: Test for Null and Invalid Cases
    static testMethod void testNullValuesInBatch() {
        Test.startTest();

        // Insert an Opportunity with no Quote
        Opportunity__c objOppWithNoQuote = CommonDataTest.getOpportunity();
        objOppWithNoQuote.LatestQuote__c = null;
        insert objOppWithNoQuote;

        // Simulate running the batch for the Opportunity with no associated Quote
        Database.executeBatch(new UpdateOpportunityWithQuoteBatch(), 200);
        Test.stopTest();

        // Verify that the batch should leave LatestQuote__c as null since no quote is associated
        objOppWithNoQuote = [SELECT Id, LatestQuote__c FROM Opportunity__c WHERE Id = :objOppWithNoQuote.Id];
        System.assertEquals(null, objOppWithNoQuote.LatestQuote__c, 'Opportunity should not have LatestQuote__c updated due to missing quote.');
    }

    // Additional Test: Ensure the batch does not fail if Quote is already associated with Opportunity
    static testMethod void testBatchHandlesAlreadyUpdatedOpportunities() {
        Test.startTest();

        // Insert an Opportunity and a Quote with a relationship
        Account msaAccount = CommonDataTest.getMSAAccount();
        insert msaAccount;

        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = msaAccount.Id;
        objOpp.LatestQuote__c = null;
        insert objOpp;

        Quote__c objQuote = CommonDataTest.getQuote();
        objQuote.Opportunity__c = objOpp.Id;
        insert objQuote;

        // Set LatestQuote__c to ensure the Opportunity already has the Quote
        
        List<String> failedRecords = new List<String>(); // Store failed records

        try {
            if (objOpp.Quotes__r.isEmpty()) {
                Quote__c recentQuote = objOpp.Quotes__r[0];
                objOpp.LatestQuote__c = recentQuote.Id; 
                update objOpp;
            } else {
                failedRecords.add(objOpp.Id + ',No Quotes'); // Capture failed due to no quote
            }
        } catch (Exception e) {
            failedRecords.add(objOpp.Id + ',' + e.getMessage()); // Capture exception message
        }
        
        // Run the batch to ensure it handles the opportunity correctly
        Database.executeBatch(new UpdateOpportunityWithQuoteBatch(), 200);
        
        UpdateOpportunityWithQuoteBatch.generateFailureFile(failedRecords);
        Test.stopTest();

        // Verify that the Opportunity's LatestQuote__c is not overwritten as it already has the correct Quote
        objOpp = [SELECT Id, LatestQuote__c FROM Opportunity__c WHERE Id = :objOpp.Id];
        System.assertEquals(objQuote.Id, objOpp.LatestQuote__c, 'LatestQuote__c should remain unchanged as it was already set correctly.');
    }

}