@isTest
public class customLookUpControllerTest {
    
    @testSetup
    static void createTestData() {
        
        //for Opportunity 
        Opportunity__c objOpp = new Opportunity__c();
        objOpp.Name = 'TEST OPP';
        objOpp.Type__c = 'Retail';
        objOpp.X3PL_Potential__c = 23;
        insert objOpp;
        
        //for parent account
        Account accountobjPro = new Account();
        accountobjPro.name = 'TEST PROSPECT ACCOUNT';
        accountobjPro.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        accountobjPro.Type = 'Credit';
        accountobjPro.region__c = 'DELHI';
        insert accountobjPro;
        
        //for personal account 
        Account newAccount = new Account();
        newAccount.Name = 'SFX00001';
        newAccount.Opportunity__c = objOpp.Id;
        newAccount.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        newAccount.parentID = accountobjPro.Id;
        newAccount.BillingState='Delhi';
        insert newAccount;
        
    }
    static testMethod void createCaseTest() {
        
        Test.startTest();
        customLookUpController.search('Delhi', 'BillingState','Account', Null);
        Test.stopTest();
        
    }
    
    
    
}