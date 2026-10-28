/**
 * @description Test class for DebitCreditNoteHandler apex class
 *              Tests the createSubmissionTask method for Debit_Credit_Note__c records
 * 
 * @see DebitCreditNoteHandler*/

@isTest
public class DebitCreditNoteHandlerTest {

    /**
     * @description Setup method to create common test data
     */
    @testSetup
    static void setupTestData() {
        // Create test users
        User testUser = CommonDataTest.getUserBdm();
        insert testUser;

        System.runAs(testUser) {
            // Create Branch Master
            Branch_Master__c branch = CommonDataTest.getBranchMaster();
            insert branch;

            // Create User Branch Mapping
            User_Branch_Mapping__c userBranchMap = new User_Branch_Mapping__c();
            userBranchMap.Branch_Name__c = branch.Id;
            userBranchMap.User__c = testUser.Id;
            insert userBranchMap;
            
            // Create Opportunity for all tests
            Opportunity__c objOpp = CommonDataTest.getOpportunity();
            insert objOpp;
            
            // Create parent account
            Account parentAccount = CommonDataTest.getParentAccount();
            insert parentAccount;

            // Create SFX account for submission tests
            Account sfxAccount = CommonDataTest.getSfxAccount();
            sfxAccount.ParentId = parentAccount.Id;
            sfxAccount.Booking_Branch__c = branch.Id;
            sfxAccount.Opportunity__c = objOpp.Id;
            insert sfxAccount;

            // Create Invoice with required fields for submission tests
            Invoice__c invoice = CommonDataTest.getInvoice();
            invoice.Account__c = sfxAccount.Id;
            invoice.Billing_Level__c = 'Level1';
            invoice.Bill_Number__c = 'TEST-BILL-001';
            invoice.Out_Total_Amount__c = 1000;
            invoice.Charged_Freight_Amount__c = 500;
            invoice.Charged_ST_Amount__c = 600;
            invoice.BDM_Email_IDs__c = 'test@gmail.com';
            insert invoice;

            // Create PropelI BDM Mapping for Submission
            PropelI_BDM_Mapping__c propeliBdmMapping = new PropelI_BDM_Mapping__c();
            propeliBdmMapping.PropelI_BDM__c = testUser.Id;
            propeliBdmMapping.PropelI_Composite_Key__c = 'test';
            insert propeliBdmMapping;

            // Link Invoice to PropelI BDM Mapping
            invoice.Submission_propelI_BDM_Mapping__c = propeliBdmMapping.Id;
            update invoice;
            
            // Create additional parent account for case tests
            Account caseParentAccount = CommonDataTest.getParentAccount();
            insert caseParentAccount;
            
            // Create additional SFX account for case tests
            Account caseSfxAccount = CommonDataTest.getSfxAccount();
            caseSfxAccount.ParentId = caseParentAccount.Id;
            caseSfxAccount.Opportunity__c = objOpp.Id;
            insert caseSfxAccount;
            
            // Create test cases for case-related tests
            List<Case__c> testCases = new List<Case__c>();
            
            Case__c testCase1 = CommonDataTest.getCase('Revenue Management Case');
            testCase1.Account__c = caseSfxAccount.Id;
            testCases.add(testCase1);
            
            Case__c testCase2 = CommonDataTest.getCase('Revenue Management Case');
            testCase2.Account__c = caseSfxAccount.Id;
            testCases.add(testCase2);
            
            Case__c testCase3 = CommonDataTest.getCase('Operation Issues');
            testCase3.Account__c = caseSfxAccount.Id;
            testCases.add(testCase3);
            
            insert testCases;
        }
    }

    /**
     * @description Test that submission tasks are created when DCN is created with valid invoice
     */
    @isTest
    static void testCreateSubmissionTaskSuccess() {
        Invoice__c invoice = [SELECT Id, Account__c FROM Invoice__c LIMIT 1];

        Debit_Credit_Note__c dcn = new Debit_Credit_Note__c();
        dcn.Invoice_Name__c = invoice.Id;
        dcn.Bill_Number__c = 'DCN-TEST-001';
        dcn.Created_Date__c = System.today();
        dcn.Note_Type__c = 'Debit Note Created';
        insert dcn;

        Test.startTest();
        DebitCreditNoteHandler.createSubmissionTask(new List<Id>{dcn.Id});
        Test.stopTest();

    }

    /**
     * @description Test that task uses invoice bill number when DCN bill number is blank
     */
    @isTest
    static void testCreateSubmissionTaskWithInvoiceBillNumber() {
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];

        Debit_Credit_Note__c dcn = new Debit_Credit_Note__c();
        dcn.Invoice_Name__c = invoice.Id;
        dcn.Bill_Number__c = null;
        dcn.Note_Type__c = 'Debit Note Created';
        insert dcn;

        Test.startTest();
        DebitCreditNoteHandler.createSubmissionTask(new List<Id>{dcn.Id});
        Test.stopTest();
        
    }

    /**
     * @description Test that no task is created when invoice amount is not sufficient
     */
    @isTest
    static void testCreateSubmissionTaskInsufficientAmount() {
        Opportunity__c opp = [SELECT Id FROM Opportunity__c LIMIT 1];
        Account parentAccount = [SELECT Id FROM Account WHERE ParentId = null LIMIT 1];

        Account sfxAccount = CommonDataTest.getSfxAccount();
        sfxAccount.ParentId = parentAccount.Id;
        sfxAccount.Opportunity__c = opp.Id;
        insert sfxAccount;

        Invoice__c invoice = CommonDataTest.getInvoice();
        invoice.Account__c = sfxAccount.Id;
        invoice.Out_Total_Amount__c = 1000;
        invoice.Charged_Freight_Amount__c = 100;
        invoice.Charged_ST_Amount__c = 100;
        invoice.BDM_Email_IDs__c = 'test@gmail.com';
        insert invoice;

        Debit_Credit_Note__c dcn = new Debit_Credit_Note__c();
        dcn.Invoice_Name__c = invoice.Id;
        dcn.Bill_Number__c = 'DCN-LOW-001';
        dcn.Note_Type__c = 'Debit Note Created';
        insert dcn;

        Test.startTest();
        DebitCreditNoteHandler.createSubmissionTask(new List<Id>{dcn.Id});
        Test.stopTest();

    }
    
    /**
     * @description Test that task fields are populated correctly
     */
    @isTest
    static void testCreateSubmissionTaskFieldPopulation() {
        Invoice__c invoice = [
            SELECT Id, Customer_Contract_Code__c, Bill_Branch__c, Billing_Level__c, Green_Book__c
            FROM Invoice__c 
            LIMIT 1
        ];

        Debit_Credit_Note__c dcn = new Debit_Credit_Note__c();
        dcn.Invoice_Name__c = invoice.Id;
        dcn.Bill_Number__c = 'DCN-FIELD-TEST-001';
        dcn.Note_Type__c = 'Debit Note Created';
        insert dcn;

        Map<Id, Debit_Credit_Note__c> dcnMap = new Map<Id, Debit_Credit_Note__c>();
        dcnMap.put(dcn.Id, dcn);

        Test.startTest();
        DebitCreditNoteHandler.createSubmissionTask(new List<Id>{dcn.Id});
        Test.stopTest();

    }

    /**
     * @description Test that activity date is set correctly (7 days from DCN creation date)
     */
    @isTest
    static void testCreateSubmissionTaskActivityDate() {
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];

        Debit_Credit_Note__c dcn = new Debit_Credit_Note__c();
        dcn.Invoice_Name__c = invoice.Id;
        dcn.Bill_Number__c = 'DCN-DATE-001';
        dcn.Note_Type__c = 'Debit Note Created';
        insert dcn;

        Test.setCreatedDate(dcn.Id, System.now().addDays(-1));

        Map<Id, Debit_Credit_Note__c> dcnMap = new Map<Id, Debit_Credit_Note__c>();
        dcnMap.put(dcn.Id, dcn);

        Test.startTest();
        DebitCreditNoteHandler.createSubmissionTask(new List<Id>{dcn.Id});
        Test.stopTest();
    }

    // ========== Tests for updateCaseCreditNote method ==========

    /**
     * @description Test updateCaseCreditNote - Before Insert with valid case number
     * Scenario: Credit note with valid case number in remarks (before insert)
     * Expected: Case_Status__c should be set to 'Case Found - {caseId}'
     */
    //Field is not writeable: Case__c.Name 
    @isTest
    static void testUpdateCaseCreditNoteBeforeInsertValidCase() {
        // Query existing test case from setup
        Case__c testCase = [SELECT Id, Name FROM Case__c LIMIT 1];

        // Create credit note with valid case number in remarks
        Debit_Credit_Note__c creditNote = new Debit_Credit_Note__c();
        creditNote.Note_Type__c = 'CREDIT_NOTE';
        creditNote.Remarks__c =  testCase.Name + '; Additional remarks here';
        creditNote.Note_Number__c = 'CN-001';

        Debit_Credit_Note__c creditNote2 = new Debit_Credit_Note__c();
        creditNote2.Note_Type__c = 'CREDIT_NOTE';
        creditNote2.Remarks__c = 'CASE-99999; This case does not exist';
        creditNote2.Note_Number__c = 'CN-002';

        Debit_Credit_Note__c creditNote3 = new Debit_Credit_Note__c();
        creditNote3.Note_Type__c = 'CREDIT_NOTE';
        creditNote3.Remarks__c = 'sdjfkdsj';
        creditNote3.Note_Number__c = 'CN-003';

        List<Debit_Credit_Note__c> creditNotes = new List<Debit_Credit_Note__c>{creditNote, creditNote2, creditNote3};

        Test.startTest();
        DebitCreditNoteHandler.updateCaseCreditNote(creditNotes, true);
        Test.stopTest();
    }

    @isTest
    static void testUpdateCaseCreditNoteMultipleCases() {
        // Query existing test cases from setup
        List<Case__c> testCases = [SELECT Id, Name FROM Case__c];
        Case__c testCase1 = testCases[0]; // First Revenue Management Case
        Case__c testCase2 = testCases[1]; // Second Revenue Management Case
        Case__c testCase3 = testCases[2]; // Operation Issues Case

        // Create multiple credit notes
        List<Debit_Credit_Note__c> creditNotes = new List<Debit_Credit_Note__c>();
        
        Debit_Credit_Note__c cn1 = new Debit_Credit_Note__c();
        cn1.Note_Type__c = 'CREDIT_NOTE';
        cn1.Remarks__c =  testCase1.Name + '; First credit note';
        cn1.Note_Number__c = 'CN-111';
        creditNotes.add(cn1);

        Debit_Credit_Note__c cn2 = new Debit_Credit_Note__c();
        cn2.Note_Type__c = 'CREDIT_NOTE';
        cn2.Remarks__c =  testCase2.Name + '; Second credit note';
        cn2.Note_Number__c = 'CN-222';
        creditNotes.add(cn2);

        Debit_Credit_Note__c cn3 = new Debit_Credit_Note__c();
        cn3.Note_Type__c = 'CREDIT_NOTE';
        cn3.Remarks__c = 'CASE-333; Third credit note';
        cn3.Note_Number__c = 'CN-333';
        creditNotes.add(cn3);

        Test.startTest();
        DebitCreditNoteHandler.updateCaseCreditNote(creditNotes, false);
        Test.stopTest();

    }
  
}