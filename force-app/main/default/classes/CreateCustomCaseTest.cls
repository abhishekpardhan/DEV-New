/**
* @File Name          : CreateCustomCaseTest.cls
* @Description        : CreateCustomCaseTest is the test class for CreateCustomCase apex class
* @Author             : Deepak
* @Group              : Techmatrix
* @Last Modified By   : Deepak
* @Last Modified On   : 28-10-2021
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        28-10-2021                Deepak                   Initial Version
**/

@IsTest
private class CreateCustomCaseTest {
    @testSetup static void createTestData() {
        String endpoint = 'www.google.com';
        Safex_API__c safexApi = TestDataFactory.createSafexAPI(ConstantUtility.WAY_BILL_API_NAME, 'test', 'basic', null, null, endpoint, 'testUser', 'testPassword');
        // insert safexApi;
        
        Opportunity__c objOpp = new Opportunity__c();
        objOpp.Name = 'TEST OPP';
        objOpp.Type__c = 'Retail';
        objOpp.X3PL_Potential__c = 23;
        insert objOpp;
        
        //added by sourabh singh
       
        Account accountobjPro = new Account();
        accountobjPro.name = 'TEST PROSPECT ACCOUNT';
        accountobjPro.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        accountobjPro.Type = 'Credit';
        accountobjPro.region__c = 'DELHI';
        insert accountobjPro;
        
        Account newAccount = new Account();
        newAccount.Name = 'SFX00001';
        newAccount.Opportunity__c = objOpp.Id;
        newAccount.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        newAccount.parentID = accountobjPro.Id;
        insert newAccount;
        
        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        cases[0].WaybillNo__c = '12345678';
        cases[0].SFX__c = newAccount.Id;
        insert cases;
    }
    static testMethod void createCaseTest() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        CreateCustomCase.createCase(caseObj.Id);
        
        Test.stopTest();
    }
}