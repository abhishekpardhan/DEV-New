/**
@File Name : ContractRenewalBatchTest.cls
@Description : Test class used to validate the functionality of ContractRenewalService
@Author : Anand Raju
@Group : Grant Thornton Bharat
@Last Modified By : Anand Raju
@Last Modified On : 28-04-2026

@Modification Log :
*==============================================================================

Ver      Date         Author            Modification
*==============================================================================

1.1     28-04-2026     Anand Raju       Updated Contract End Date as month-end
**/

@isTest
private class ContractRenewalBatchTest {
    
    @testSetup
    static void setupData() {
        
        Test.startTest();

        List<Profile> pfList = new List<Profile>();
        pfList = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        User us = new User(
            firstname = 'ABC',
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

        insert us;

        System.assertNotEquals(us.Id, null);

        List<Id> objOppList = new List<Id>();

        System.runAs(us) {

            Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            insert msaAccount;

            Account_Team__c accteam = new Account_Team__c();
            accteam.Relationship__c = true;
            accteam.National2__c = true;
            accteam.Account__c = msaAccount.Id;
            accteam.BDM__c = us.Id;
            accteam.BDMPropelI__c = us.Id;
            insert accteam;

            Id openRecordTypeId = Schema.SObjectType.Contract__c
                .getRecordTypeInfosByName()
                .get('Closed')
                .getRecordTypeId();

            Date startDate = Date.today();
            Date endDate = getMonthEnd(startDate.addDays(30));

            Contract__c c = new Contract__c();
            c.Account__c = msaAccount.Id;
            c.Contract_Start_Date_MOU_Date__c = startDate;
            c.Is_valid__c = true;
            c.Credit_Term__c = 'GB';
            c.Contract_End_Date__c = endDate;
            c.Bill_Cycle__c = 'Fortnightly';
            c.Service_Requirements__c = 'service';
            c.Claim_Understanding__c = 'Owners Risk';
            c.Description__c = 'description';
            c.Contract_Copy_enclosed__c = 'Yes';
            c.MOU_enclosed__c = 'Yes';
            c.Bill_Submission__c = 'Local';
            c.Bill_Collection__c = 'Local';
            c.Customer_Signed_date__c = Date.today();
            c.Contract_Signed_by_Safexpress__c = us.Id;
            c.Safexpress_signed_date__c = Date.today();
            c.Freight_MIS_required__c = 'Yes';
            c.POD_Link_Required__c = 'Yes';
            c.RecordTypeId = openRecordTypeId;

            insert c;
        }

        Test.stopTest();
    }

    @isTest
    static void testBatchAndServiceExecution() {

        Test.startTest();
        ContractRenewalBatch batch = new ContractRenewalBatch();
        Id batchId = Database.executeBatch(batch, 50);
        Test.stopTest();
    }

    private static Date getMonthEnd(Date inputDate) {
        return Date.newInstance(
            inputDate.year(),
            inputDate.month(),
            1
        ).addMonths(1).addDays(-1);
    }
}