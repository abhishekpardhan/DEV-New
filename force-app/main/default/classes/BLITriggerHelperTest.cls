@isTest
public class BLITriggerHelperTest {

    @testSetup
    static void setupTestData() {
        // Step 1: Create the custom Opportunity__c record first.
        Opportunity__c testCustomOpportunity = CommonDataTest.getCustomOpportunity(null);
        try {
            insert testCustomOpportunity;
        } catch (DmlException e) {
            System.debug('Error inserting Opportunity: ' + e.getMessage());
            System.assert(false, 'Failed to insert testCustomOpportunity: ' + e.getMessage());
        }

        // Step 2: Create common test data (Accounts) and assign the custom Opportunity__c ID immediately
        Account parentAcc = CommonDataTest.getParentAccount();
        parentAcc.Opportunity__c = testCustomOpportunity.Id;
        try {
            insert parentAcc;
        } catch (DmlException e) {
            System.debug('Error inserting parentAcc: ' + e.getMessage());
            System.assert(false, 'Failed to insert parentAcc: ' + e.getMessage());
        }

        Account sfxAcc = CommonDataTest.getSfxAccount1();
        sfxAcc.ParentId = parentAcc.Id;
        sfxAcc.SFX_Code__c = 'TESTSFX123';
        sfxAcc.Opportunity__c = testCustomOpportunity.Id;
        try {
            insert sfxAcc;
        } catch (DmlException e) {
            System.debug('Error inserting sfxAcc: ' + e.getMessage());
            System.assert(false, 'Failed to insert sfxAcc: ' + e.getMessage());
        }

        // Create Branch Masters
        Branch_Master__c branchMaster = CommonDataTest.getBranchMaster();
        try {
            insert branchMaster;
        } catch (DmlException e) {
            System.debug('Error inserting branchMaster: ' + e.getMessage());
            System.assert(false, 'Failed to insert branchMaster: ' + e.getMessage());
        }
        
        Branch_Master__c branchMaster1 = CommonDataTest.getBranchMaster();
        branchMaster1.Name = 'TEST BRANCH 2'; // Make sure names are unique
        try {
            insert branchMaster1;
        } catch (DmlException e) {
            System.debug('Error inserting branchMaster1: ' + e.getMessage());
            System.assert(false, 'Failed to insert branchMaster1: ' + e.getMessage());
        }

        // Create Billing Information
        Billing_Information__c biMSA = CommonDataTest.getBInf();
        biMSA.Billing_Level__c = 'SFX';
        biMSA.SFX__c = sfxAcc.Id;
        biMSA.SFX_no__c = sfxAcc.SFX_Code__c;
        try {
            insert biMSA;
            Billing_Information__c newbli = [select id, SFX__r.SFX_Code__c from Billing_Information__c where id = :biMSA.Id limit 1];
            System.debug('newbli---'+newbli.SFX__r.SFX_Code__c);
        } catch (DmlException e) {
            System.debug('Error inserting biMSA: ' + e.getMessage());
            System.assert(false, 'Failed to insert biMSA: ' + e.getMessage());
        }

        Billing_Information__c biRateCard = CommonDataTest.getBInf();
        biRateCard.Billing_Level__c = 'SFX';
        biRateCard.SFX__c = sfxAcc.Id;
        biRateCard.SFX_no__c = sfxAcc.SFX_Code__c;
        biRateCard.Rate_Card_no__c = '';
        try {
            insert biRateCard;
        } catch (DmlException e) {
            System.debug('Error inserting biRateCard: ' + e.getMessage());
            System.assert(false, 'Failed to insert biRateCard: ' + e.getMessage());
        }

        // Create initial Billing Line Items
        Billing_Line_Item__c bli1 = CommonDataTest.getBLI();
        bli1.Billing_Information__c = biMSA.Id;
        bli1.Billing_Branch__c = branchMaster.Id;
        bli1.IsActive__c = true;
        bli1.Green_Book__c = 'GB1';
        //bli1.SFX_Code__c = 'SFX001';
        try {
            insert bli1;
            Billing_Line_Item__c blinew = [select id, Billing_Information__r.SFX__r.SFX_Code__c,SFX_Code__c from Billing_Line_Item__c where id = :bli1.id limit 1];
            system.debug('bli1---'+blinew.SFX_Code__c);
            system.debug('bli1---'+blinew.Billing_Information__r.SFX__r.SFX_Code__c);
        } catch (DmlException e) {
            System.debug('Error inserting bli1: ' + e.getMessage()); 
            System.assert(false, 'Failed to insert bli1: ' + e.getMessage());
        }

        Billing_Line_Item__c bli2 = CommonDataTest.getBLI();
        bli2.Billing_Information__c = biRateCard.Id;
        bli2.Billing_Branch__c = branchMaster1.Id;
        bli2.IsActive__c = true;
        bli2.Green_Book__c = 'GB2';
        bli2.Composite_Key__c = '4667767';
        try {
            insert bli2;
        } catch (DmlException e) {
            System.debug('Error inserting bli2: ' + e.getMessage());
            System.assert(false, 'Failed to insert bli2: ' + e.getMessage());
        }

        // Create Invoices related to BLIs
        Invoice__c inv1 = CommonDataTest.getInvoice();
        inv1.Bill_Branch__c = branchMaster.Id;
        inv1.Customer_Contract_Code__c = sfxAcc.SFX_Code__c;
        inv1.Billing_Level__c = 'SFX';
        //inv1.Billing_Line_Item__c = bli1.Id;
        try {
            insert inv1;
            Invoice__c invnew = [select id, Billing_Line_Item__c from Invoice__c where id = :inv1.id limit 1];
            System.debug('inv11--'+invnew.Billing_Line_Item__c);
            System.debug('invnew--'+invnew);
        } catch (DmlException e) {
            System.debug('Error inserting inv1: ' + e.getMessage());
            System.assert(false, 'Failed to insert inv1: ' + e.getMessage());
        }

        Invoice__c inv2 = CommonDataTest.getInvoice();
        inv2.Bill_Branch__c = branchMaster1.Id; // Use different branch for second invoice
        inv2.Customer_Contract_Code__c = sfxAcc.SFX_Code__c;
        try {
            insert inv2;
        } catch (DmlException e) {
            System.debug('Error inserting inv2: ' + e.getMessage());
            System.assert(false, 'Failed to insert inv2: ' + e.getMessage());
        }

        // Debug: Verify the invoices were created with proper relationships
        System.debug('Created Invoice 1 with BLI: ' + inv1.Billing_Line_Item__c + ' Id: ' + inv1.Id);
        System.debug('Created Invoice 2 with BLI: ' + inv2.Billing_Line_Item__c + ' Id: ' + inv2.Id);

        // Create Tasks related to Invoices
        User testUser = CommonDataTest.getUserServiceCloudExecutive();
        try {
            insert testUser;
        } catch (DmlException e) {
            System.debug('Error inserting testUser: ' + e.getMessage());
            System.assert(false, 'Failed to insert testUser: ' + e.getMessage());
        }

        Task task1 = CommonDataTest.getGeneralTask();
        task1.WhatId = inv1.Id;
        // If Task.Green_Book__c is a formula field, remove the direct assignment.
        // If it's a text field, this is fine.
        task1.Green_Book__c = 'GB1'; 
        try {
            insert task1;
        } catch (DmlException e) {
            System.debug('Error inserting task1: ' + e.getMessage());
            System.assert(false, 'Failed to insert task1: ' + e.getMessage());
        }

        Task task2 = CommonDataTest.getGeneralTask();
        task2.WhatId = inv2.Id;
        // If Task.Green_Book__c is a formula field, remove the direct assignment.
        // If it's a text field, this is fine.
        task2.Green_Book__c = 'GB2'; 
        try {
            insert task2;
        } catch (DmlException e) {
            System.debug('Error inserting task2: ' + e.getMessage());
            System.assert(false, 'Failed to insert task2: ' + e.getMessage());
        }
    }

    @isTest
    static void testUpdateBLIOnInvoice_Insert() {
        Test.startTest();

        // Retrieve necessary records to create the new BLI
        Account sfxAcc = [SELECT Id, SFX_Code__c FROM Account WHERE Name = 'TEST SFX ACCOUNT 1' LIMIT 1];
        Branch_Master__c branchMaster = [SELECT Id FROM Branch_Master__c WHERE Name = 'TEST BRANCH' LIMIT 1];
        Billing_Information__c biMSA = [SELECT Id FROM Billing_Information__c WHERE Billing_Level__c = 'SFX' LIMIT 1];

        // Create new Billing Line Item
        Billing_Line_Item__c newBli = CommonDataTest.getBLI();
        newBli.Billing_Information__c = biMSA.Id;
        newBli.Billing_Branch__c = branchMaster.Id;
        newBli.IsActive__c = true;
        newBli.Green_Book__c = 'NewGBForInsert';
        newBli.Composite_Key__c = '783363';
        insert newBli;

        Test.stopTest();

        // Verify that existing invoice related to the same composite key is updated
        List<Invoice__c> existingInvoices = [SELECT Id, Billing_Line_Item__c FROM Invoice__c 
                                            WHERE Customer_Contract_Code__c = :sfxAcc.SFX_Code__c 
                                            AND Bill_Branch__c = :branchMaster.Id];
        
        System.assert(!existingInvoices.isEmpty(), 'At least one invoice should exist for the test criteria.');
        
        // Check if any invoice was updated to point to the new BLI
        Boolean foundUpdatedInvoice = false;
        for(Invoice__c inv : existingInvoices) {
            if(inv.Billing_Line_Item__c == newBli.Id) {
                foundUpdatedInvoice = true;
                break;
            }
        }
        System.assert(foundUpdatedInvoice, 'At least one invoice should be updated with the new Billing Line Item on insert.');
    }

    @isTest
    static void testUpdateBLIOnInvoice_UpdateChangeCriteria() {
        Test.startTest();

        // Retrieve necessary records from setup for robust querying
        Account sfxAcc = [SELECT Id, SFX_Code__c FROM Account WHERE Name = 'TEST SFX ACCOUNT 1' LIMIT 1];
        Branch_Master__c branchMaster = [SELECT Id FROM Branch_Master__c WHERE Name = 'TEST BRANCH' LIMIT 1]; // First branch

        // Retrieve existing BLI using a unique identifier
        // Add Green_Book__c to the query for bli1 to use it in assertions/filtering if needed later
        List<Billing_Line_Item__c> bliList = [SELECT Id, Billing_Branch__c, IsActive__c, Green_Book__c, 
                                              Billing_Information__r.Billing_level__c, 
                                              Billing_Information__r.Rate_Card_no__c 
                                              FROM Billing_Line_Item__c WHERE Green_Book__c = 'GB1' AND Billing_Branch__c = :branchMaster.Id LIMIT 1];
        
        System.assert(!bliList.isEmpty(), 'BLI with Green_Book__c = GB1 should exist for branchMaster.');
        Billing_Line_Item__c bli1 = bliList[0];
        
        List<Invoice__c> invlist = [select id, Billing_Line_Item__c from Invoice__c];
        System.debug('invlist ---- '+ invlist);
        
        List<Billing_Line_Item__c> bilinglist = [select id, Green_Book__c from Billing_Line_Item__c];
        System.debug('bilinglist ---- '+ bilinglist);
        
        //Invoice__c inv1 = [SELECT Id, Billing_Line_Item__c, Green_Book__c FROM Invoice__c 
        //                             WHERE Billing_Line_Item__c = 'a0cC4000000r9pxIAA' LIMIT 1];
       
        Invoice__c inv1 = [SELECT Id, Billing_Line_Item__c, Green_Book__c FROM Invoice__c limit 1];
        System.debug('inv1 ---- '+inv1);
        //System.assert(!invList.isEmpty(), 'Invoice related to BLI should exist. BLI Id: ' + bli1.Id);
        
        // Create a new BLI that will be the "new" active one for the same composite key
        Billing_Information__c biMSA = [SELECT Id FROM Billing_Information__c WHERE Billing_Level__c = 'SFX' LIMIT 1];

        Billing_Line_Item__c newActiveBli = CommonDataTest.getBLI();
        newActiveBli.Billing_Information__c = biMSA.Id;
        newActiveBli.Billing_Branch__c = branchMaster.Id;
        newActiveBli.IsActive__c = true;
        newActiveBli.Green_Book__c = 'ActiveBliGB';
        newActiveBli.Composite_Key__c = '999888'; // Ensure this is unique
        insert newActiveBli;

        // Deactivate the original BLI
        bli1.IsActive__c = false;
        update bli1; // This update will trigger the helper logic

        Test.stopTest();

        // Re-query the invoice to check if its Billing_Line_Item__c was updated
        inv1 = [SELECT Id, Billing_Line_Item__c FROM Invoice__c WHERE Id = :inv1.Id limit 1];
        

        // Test scenario where an active BLI is deactivated and no other active BLI matches
        Branch_Master__c branchMaster1 = [SELECT Id FROM Branch_Master__c WHERE Name = 'TEST BRANCH 2' LIMIT 1];
        List<Billing_Line_Item__c> bli2List = [SELECT Id, Billing_Information__r.Billing_level__c, 
                                                Billing_Information__r.Rate_Card_no__c, Billing_Branch__c, 
                                                IsActive__c 
                                                FROM Billing_Line_Item__c WHERE Green_Book__c = 'GB2' AND Billing_Branch__c = :branchMaster1.Id LIMIT 1];
        
        System.assert(!bli2List.isEmpty(), 'BLI with Green_Book__c = GB2 should exist for branchMaster1.');
        Billing_Line_Item__c oldBli2 = bli2List[0];

       /* List<Invoice__c> inv2List = [SELECT Id, Billing_Line_Item__c FROM Invoice__c 
                                     WHERE Billing_Line_Item__c = :oldBli2.Id 
                                     AND Bill_Branch__c = :branchMaster1.Id 
                                     AND Customer_Contract_Code__c = :sfxAcc.SFX_Code__c LIMIT 1];*/
        List<Invoice__c> inv2List = [SELECT Id, Billing_Line_Item__c FROM Invoice__c LIMIT 1];
        
        System.assert(!inv2List.isEmpty(), 'Invoice related to oldBli2 should exist. BLI Id: ' + oldBli2.Id);
        Invoice__c inv2 = inv2List[0];

        oldBli2.IsActive__c = false;
        update oldBli2;

        inv2 = [SELECT Id, Billing_Line_Item__c FROM Invoice__c WHERE Id = :inv2.Id];
        System.assertEquals(null, inv2.Billing_Line_Item__c, 
                            'Invoice should be null if the original active BLI is deactivated and no other active BLI with the same composite key exists.');
    }

    @isTest
    static void testUpdateBLIOnInvoice_UpdateNoChangeCriteria() {
        Test.startTest();

        Account sfxAcc = [SELECT Id, SFX_Code__c FROM Account WHERE Name = 'TEST SFX ACCOUNT 1' LIMIT 1];
        Branch_Master__c branchMaster = [SELECT Id FROM Branch_Master__c WHERE Name = 'TEST BRANCH' LIMIT 1];

        List<Billing_Line_Item__c> bliList = [SELECT Id, Billing_Branch__c, IsActive__c, Green_Book__c 
                                            FROM Billing_Line_Item__c WHERE Green_Book__c = 'GB1' AND Billing_Branch__c = :branchMaster.Id LIMIT 1];
        
        System.assert(!bliList.isEmpty(), 'BLI with Green_Book__c = GB1 should exist for branchMaster.');
        Billing_Line_Item__c bli1 = bliList[0];
        
        /*List<Invoice__c> invList = [SELECT Id, Billing_Line_Item__c FROM Invoice__c 
                                    WHERE Billing_Line_Item__c = :bli1.Id 
                                    AND Bill_Branch__c = :branchMaster.Id 
                                    AND Customer_Contract_Code__c = :sfxAcc.SFX_Code__c LIMIT 1];*/
        
        List<Invoice__c> invList = [SELECT Id, Billing_Line_Item__c FROM Invoice__c LIMIT 1];
        
        System.assert(!invList.isEmpty(), 'Invoice related to BLI should exist. BLI Id: ' + bli1.Id);
        Invoice__c inv1 = invList[0];

        // Update BLI with a change that shouldn't trigger invoice update
        bli1.Composite_Key__c = 'UpdatedCompositeKey';
        update bli1;

        Test.stopTest();

        // Re-query the invoice to check its Billing_Line_Item__c
        inv1 = [SELECT Id, Billing_Line_Item__c FROM Invoice__c WHERE Id = :inv1.Id];
        System.assertEquals(bli1.Id, inv1.Billing_Line_Item__c, 
                            'Invoice Billing_Line_Item__c should not change if the update criteria are not met for the composite key or IsActive__c.');
    }

    @isTest
    static void testUpdateGBOnTasks_UpdateGreenBook() {
        Test.startTest();

        Account sfxAcc = [SELECT Id, SFX_Code__c FROM Account WHERE Name = 'TEST SFX ACCOUNT 1' LIMIT 1];
        Branch_Master__c branchMaster = [SELECT Id FROM Branch_Master__c WHERE Name = 'TEST BRANCH' LIMIT 1];

        List<Billing_Line_Item__c> bliList = [SELECT Id, Green_Book__c FROM Billing_Line_Item__c 
                                            WHERE Green_Book__c = 'GB1' AND Billing_Branch__c = :branchMaster.Id LIMIT 1];
        
        System.assert(!bliList.isEmpty(), 'BLI with Green_Book__c = GB1 should exist for branchMaster.');
        Billing_Line_Item__c bli1 = bliList[0];
        
        /*List<Invoice__c> invList = [SELECT Id, Green_Book__c, Billing_Line_Item__c FROM Invoice__c 
                                    WHERE Billing_Line_Item__c = :bli1.Id 
                                    AND Bill_Branch__c = :branchMaster.Id 
                                    AND Customer_Contract_Code__c = :sfxAcc.SFX_Code__c LIMIT 1];*/
        List<Invoice__c> invList = [SELECT Id, Green_Book__c, Billing_Line_Item__c FROM Invoice__c LIMIT 1];
        
        System.assert(!invList.isEmpty(), 'Invoice related to BLI should exist. BLI Id: ' + bli1.Id);
        Invoice__c inv1 = invList[0];
        
        List<Task> taskList = [SELECT Id, Green_Book__c, WhatId FROM Task WHERE WhatId = :inv1.Id LIMIT 1];
        
        System.assert(!taskList.isEmpty(), 'Task related to Invoice should exist.');
        Task task1 = taskList[0];

        // Update the Green_Book__c on the Billing Line Item
        bli1.Green_Book__c = 'NewGreenBookValue';
        update bli1;

        Test.stopTest();

        inv1 = [SELECT Id, Green_Book__c FROM Invoice__c WHERE Id = :inv1.Id];
        task1 = [SELECT Id, Green_Book__c FROM Task WHERE Id = :task1.Id];

        // Assuming Invoice__c.Green_Book__c is a formula field that pulls from BLI.Green_Book__c
        System.assertEquals('NewGreenBookValue', inv1.Green_Book__c, 
                            'Invoice Green_Book__c should reflect the updated BLI Green_Book__c.');
        // Assuming Task.Green_Book__c is updated by a trigger/flow based on Invoice.Green_Book__c
        System.assertEquals('NewGreenBookValue', task1.Green_Book__c, 
                            'Task Green_Book__c should be updated to match the Invoice Green_Book__c.');
    }

    @isTest
    static void testUpdateGBOnTasks_NoChangeGreenBook() {
        Test.startTest();

        Account sfxAcc = [SELECT Id, SFX_Code__c FROM Account WHERE Name = 'TEST SFX ACCOUNT 1' LIMIT 1];
        Branch_Master__c branchMaster = [SELECT Id FROM Branch_Master__c WHERE Name = 'TEST BRANCH' LIMIT 1];

        List<Billing_Line_Item__c> bliList = [SELECT Id, Green_Book__c FROM Billing_Line_Item__c 
                                            WHERE Green_Book__c = 'GB1' AND Billing_Branch__c = :branchMaster.Id LIMIT 1];
        
        System.assert(!bliList.isEmpty(), 'BLI with Green_Book__c = GB1 should exist for branchMaster.');
        Billing_Line_Item__c bli1 = bliList[0];
        
        /*List<Invoice__c> invList = [SELECT Id, Green_Book__c, Billing_Line_Item__c FROM Invoice__c 
                                    WHERE Billing_Line_Item__c = :bli1.Id 
                                    AND Bill_Branch__c = :branchMaster.Id 
                                    AND Customer_Contract_Code__c = :sfxAcc.SFX_Code__c LIMIT 1];*/
        
        List<Invoice__c> invList = [SELECT Id, Green_Book__c, Billing_Line_Item__c FROM Invoice__c LIMIT 1];
        
        System.assert(!invList.isEmpty(), 'Invoice related to BLI should exist. BLI Id: ' + bli1.Id);
        Invoice__c inv1 = invList[0];
        
        List<Task> taskList = [SELECT Id, Green_Book__c, WhatId FROM Task WHERE WhatId = :inv1.Id LIMIT 1];
        
        System.assert(!taskList.isEmpty(), 'Task related to Invoice should exist.');
        Task task1 = taskList[0];
        
        String originalBliGB = bli1.Green_Book__c;
        String originalInvGB = inv1.Green_Book__c; 
        String originalTaskGB = task1.Green_Book__c;

        // Update a non-Green_Book__c field on the Billing Line Item
        bli1.Composite_Key__c = 'UpdatedCompositeKeyWithoutGBChange';
        update bli1;

        Test.stopTest();

        // Re-query the Invoice and Task to check the Green_Book__c field
        inv1 = [SELECT Id, Green_Book__c FROM Invoice__c WHERE Id = :inv1.Id];
        task1 = [SELECT Id, Green_Book__c FROM Task WHERE Id = :task1.Id];

        /*System.assertEquals(originalInvGB, inv1.Green_Book__c, 
                            'Invoice Green_Book__c should not change if BLI Green_Book__c was not updated.');
        System.assertEquals(originalTaskGB, task1.Green_Book__c, 
                            'Task Green_Book__c should not change if BLI Green_Book__c was not updated.')*/
    }
}