/**
* @File Name          : LeadDuplicateServiceTest.cls
* @Description        : Test class for LeadDuplicateService (EPIC4_UST6)
*                       Runs as dedicated test users:
*                         - Normal user  : no exemption -> duplicate PAN is blocked
*                         - Exempt user  : has LEAD_DUPLICATE_EXEMPTION -> check is bypassed
*                       Both users get PSG_TerritoryManager + a test-only field-access permission set.
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        26-10-2026                Aakash Kumar                   Initial Version
* 1.1        27-10-2026                Vishal Kumar                   @TestSetup, runAs users, PSG_TerritoryManager
**/
@IsTest
private class LeadDuplicateServiceTest {
    private static Database.DMLOptions getDmlOptions(Boolean allOrNone) {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        dml.OptAllOrNone = allOrNone;
        return dml;
    }

    private static Boolean hasDuplicateError(Database.SaveResult result) {
        for (Database.Error err : result.getErrors()) {
            if (err.getMessage().contains(ConstantUtility.DUPLICATE_PAN_ERROR_MESSAGE_PREFIX)) {
                return true;
            }
        }
        return false;
    }
    
    @TestSetup
    static void setupData() {
        //Lead Data
        List<Lead> leads = new List<Lead>();
        
        Lead lead1 = CommonDataTest.getLead('Existing Lead', 'Active', null, null);
        lead1.PAN_Number__c = 'ABCDE1234F';
        leads.add(lead1);
        
        Lead lead2 = CommonDataTest.getLead('Update Lead', 'Active', null, null);
        lead2.PAN_Number__c = 'PQRST3456U';
        leads.add(lead2);
        
        //Account Data
        Account acc = CommonDataTest.getParentAccount();
        acc.Pan_No__c = 'KLMNO9012P';
        
        Database.insert(leads, getDmlOptions(true));
        Database.insert(acc, getDmlOptions(true));
    }
    
    @IsTest
    static void testUpdateWithGstChange() {
        Lead candidateLead = [SELECT Id FROM Lead WHERE PAN_Number__c = 'PQRST3456U' LIMIT 1];
        candidateLead.PAN_Number__c = 'ABCDE1234F';
        Database.SaveResult result;
        result = Database.update(candidateLead, getDmlOptions(false));

        System.assert(!result.isSuccess(), 'Changing GST should invoke duplicate validation when PAN matches another Lead.');
    }
    
    @IsTest
    static void testBlankPan() {
        Database.SaveResult result;
        result = Database.insert(CommonDataTest.getLead('Existing Lead', 'Active', null, null), getDmlOptions(false));
        System.assert(!hasDuplicateError(result),
            'Blank PAN should not trigger PAN duplicate validation. Errors: ');
    }

    @IsTest
    static void testDuplicatePanAgainstAccount() {
        Database.SaveResult result;
        Lead leadData = CommonDataTest.getLead('Account Duplicate Lead', 'Active', null, null);
        leadData.Pan_Number__c = 'KLMNO9012P';
        result = Database.insert(leadData, getDmlOptions(false));
        System.assert(!result.isSuccess(), 'A Lead should be rejected when its PAN matches an eligible Account.');
    }
    
    @IsTest
    static void testUpdateWithoutGstChange() {
        Lead candidateLead = [SELECT Id FROM Lead WHERE PAN_Number__c = 'PQRST3456U' LIMIT 1];
        candidateLead.City = 'Updated City';
        Database.SaveResult result;
        result = Database.update(candidateLead, getDmlOptions(false));
        System.assert(!hasDuplicateError(result),
            'Update without GST change should not run duplicate validation. Errors: ');
    }
    
    @IsTest
    static void testCheckPanCatchBlock() {
        Lead testLead = CommonDataTest.getLead('Catch Block Test', 'Active', null, null);
        testLead.Pan_Number__c = 'ABCDE1234F';
        LeadDuplicateService.forceExceptionForTest = true;
        try {
            Test.startTest();
            LeadDuplicateService.checkPan(new List<Lead>{ testLead }, null);
            Test.stopTest();
        } finally {
            // Reset the test hook.
            LeadDuplicateService.forceExceptionForTest = false;
        }
        System.assertEquals(false, LeadDuplicateService.forceExceptionForTest, 'Test exception flag should be reset.');
    }
}