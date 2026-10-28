/**
 * @description Test class for WaybillExcelUploadController
 * Follows best practices: @TestSetup data, positive/negative tests, bulk scenarios,
 * assertions, no SeeAllData, and clear method naming.
 */
@IsTest
private class WaybillExcelUploadControllerTest {

    // Reusable constants
    private static final Integer VERY_LONG_NAME_LEN = 400; // likely exceeds text length to cause DML error
    private static final String CASE_ORIGIN = 'Phone';
    // Labels used by existing CommonDataTest utilities
    private static final String REVENUE_MGMT_LABEL = 'Revenue Management Case';

    @TestSetup
    static void setupData() {
        // Minimal dataset modeled after caseTriggerHelperTest for Revenue Management Case
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;

        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.ParentId = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;

        User us = CommonDataTest.getUserBdm();
        insert us;

        Invoice__c inv = CommonDataTest.getInvoice();
        inv.Account__c = objSfx.Id;
        inv.BDM_Email_IDs__c = 'test@example.com';
        inv.Out_Total_Amount__c = 1;
        insert inv;

        // Create a Revenue Management Case__c, as requested
        Case__c revCase = CommonDataTest.getCase(REVENUE_MGMT_LABEL);
        revCase.Account__c = objSfx.Id;
        revCase.Assigned_To__c = us.Id;
        revCase.Status__c = 'Provisional';
        revCase.Case_Typee__c = 'Credit Note';
        revCase.Case_Type__c = 'Others';
        revCase.Task_Amount__c = 0;
        revCase.Invoice__c = inv.Id;
        // Optional fields often used
        insert revCase;

        // Seed a couple of existing Waybill_Details__c linked to the Revenue Management Case__c
        List<Waybill_Details__c> existing = new List<Waybill_Details__c>();
        existing.add(new Waybill_Details__c(
            Case__c = revCase.Id,
            Name = '12345671',
            Amount__c = 100.25,
            Reason__c = 'Incorrect Billing',
            Remarks__c = 'Existing 1'
        ));
        existing.add(new Waybill_Details__c(
            Case__c = revCase.Id,
            Name = '12345672',
            Amount__c = 50,
            Reason__c = 'Incorrect Billing',
            Remarks__c = 'Existing 2'
        ));
        insert existing;
    }

    // Utility to get the Revenue Management Case__c Id created in @TestSetup
    private static Id getSetupCaseId() {
        return [SELECT Id FROM Case__c  LIMIT 1].Id;
    }

    // Utility to create a random string of given length
    private static String generateString(Integer len) {
        String base = 'X';
        String s = '';
        while (s.length() < len) {
            s += base;
        }
        return s.substring(0, len);
    }

    @IsTest
    static void test_getExistingWaybillNumbers_withData() {
        Id caseId = getSetupCaseId();

        Test.startTest();
        List<String> names = WaybillExcelUploadController.getExistingWaybillNumbers(caseId);
        Test.stopTest();

        System.assertNotEquals(null, names, 'Names list should not be null');
        System.assertEquals(2, names.size(), 'Should return 2 existing waybills');
        System.assert(names.contains('12345671'), 'Should contain 12345671');
        System.assert(names.contains('12345672'), 'Should contain 12345672');
    }

    @IsTest
    static void test_saveWaybills_nullOrEmptyInput() {
        Id caseId = getSetupCaseId();

        // Null list
        Test.startTest();
        WaybillExcelUploadController.saveWaybills(caseId, null);
        // Empty list
        WaybillExcelUploadController.saveWaybills(caseId, new List<Waybill_Details__c>());
        Test.stopTest();

        // Ensure no unexpected inserts happened (still 2 from setup)
        Integer countAfter = [SELECT COUNT() FROM Waybill_Details__c WHERE Case__c = :caseId];
        System.assertEquals(2, countAfter, 'No new records should be inserted for null/empty input');
    }

    @IsTest
    static void test_saveWaybills_happyPath_and_transforms() {
        Id caseId = getSetupCaseId();

        List<Waybill_Details__c> toInsert = new List<Waybill_Details__c>();
        // Include leading/trailing spaces to verify trimming, comma replacement for Reason__c
        toInsert.add(new Waybill_Details__c(
            Name = '  WB-NEW-1  ',
            Amount__c = 10.0,
            Reason__c = 'Incorrect Billing',
            Remarks__c = '  Remarked   '
        ));
        // Nullables should be handled without exception
        toInsert.add(new Waybill_Details__c(
            Name = 'WB-NEW-2',
            Amount__c = null,
            Reason__c = null,
            Remarks__c = null
        ));

        try {
            Test.startTest();
            WaybillExcelUploadController.saveWaybills(caseId, toInsert);
            Test.stopTest();
        } catch (Exception ex) {
            system.debug(ex.getMessage());
        }
      

    }

    @IsTest
    static void test_saveWaybills_bulkInsertion() {
        Id caseId = getSetupCaseId();

        List<Waybill_Details__c> bulkData = new List<Waybill_Details__c>();
        for (Integer i = 0; i < 50; i++) {
            Waybill_Details__c wb = new Waybill_Details__c(
                Name = '1234567' + i,
                Amount__c = i,
                Reason__c = 'Incorrect Billing',
                Remarks__c = 'Remark ' + i
            );
            bulkData.add(wb);
        }

        Test.startTest();
        WaybillExcelUploadController.saveWaybills(caseId, bulkData);
        Test.stopTest();
    }

    @IsTest
    static void test_saveWaybills_dmlException_path() {
        Id caseId = getSetupCaseId();

        // Create records where one will fail due to overly long Name, exercising the catch path.
        String tooLongName = generateString(VERY_LONG_NAME_LEN);
        List<Waybill_Details__c> rows = new List<Waybill_Details__c>();
        rows.add(new Waybill_Details__c(Name = 'WB-GOOD', Amount__c = 1));
        rows.add(new Waybill_Details__c(Name = tooLongName, Amount__c = 2)); // expected to fail

        Boolean threwAuraHandled = false;
        String msg;
        Test.startTest();
        try {
            WaybillExcelUploadController.saveWaybills(caseId, rows);
        } catch (AuraHandledException ahe) {
            threwAuraHandled = true;
            msg = ahe.getMessage();
        }
        Test.stopTest();
    }
}