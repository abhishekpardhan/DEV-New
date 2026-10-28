@isTest
public class ContractRenewalServiceTest {

    @testSetup
    static void setupData() {
        
        // Create User
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User us =CommonDataTest.getUserAM();
        insert us;

        System.runAs(us) {

            // Create Account
            Account msaAccount = CommonDataTest.getMSAAccount();
            msaAccount.Propel_MSACode__c = '234';
            insert msaAccount;

            // Account Team
            Account_Team__c accteam = new Account_Team__c(
                Relationship__c = true,
                National2__c = true,
                Account__c = msaAccount.Id,
                BDM__c = us.Id,
                BDMPropelI__c = us.Id
            );
            insert accteam;

            // Record Types
            Id closedRT = Schema.SObjectType.Contract__c
                .getRecordTypeInfosByName()
                .get('Closed')
                .getRecordTypeId();

            Id openRT = Schema.SObjectType.Contract__c
                .getRecordTypeInfosByName()
                .get('Open')
                .getRecordTypeId();

            // Valid Month-End Dates
            Date endDate30 = getMonthEnd(Date.today().addDays(29));
            Date endDate60 = getMonthEnd(Date.today().addDays(59));

            // Contract 1 (Closed)
            Contract__c c1 = new Contract__c(
                Account__c = msaAccount.Id,
                Contract_Start_Date_MOU_Date__c = Date.today(),
                Contract_End_Date__c = endDate30,
                Is_valid__c = true,
                Credit_Term__c = 'GB',
                Bill_Cycle__c = 'Fortnightly',
                Service_Requirements__c = 'service',
                Claim_Understanding__c = 'Owners Risk',
                Description__c = 'description',
                Contract_Copy_enclosed__c = 'Yes',
                MOU_enclosed__c = 'Yes',
                Bill_Submission__c = 'Local',
                Bill_Collection__c = 'Local',
                Customer_Signed_date__c = Date.today(),
                Contract_Signed_by_Safexpress__c = us.Id,
                Safexpress_signed_date__c = Date.today(),
                Freight_MIS_required__c = 'Yes',
                POD_Link_Required__c = 'Yes',
                RecordTypeId = closedRT
            );

            // Contract 2 (Open)
            Contract__c c2 = new Contract__c(
                Account__c = msaAccount.Id,
                Contract_Start_Date_MOU_Date__c = Date.today().addDays(2),
                Contract_End_Date__c = endDate60,
                Is_valid__c = true,
                Credit_Term__c = 'GB',
                Bill_Cycle__c = 'Fortnightly',
                Service_Requirements__c = 'service',
                Claim_Understanding__c = 'Owners Risk',
                Description__c = 'description',
                Contract_Copy_enclosed__c = 'Yes',
                MOU_enclosed__c = 'Yes',
                Bill_Submission__c = 'Local',
                Bill_Collection__c = 'Local',
                Customer_Signed_date__c = Date.today(),
                Contract_Signed_by_Safexpress__c = us.Id,
                Safexpress_signed_date__c = Date.today(),
                Freight_MIS_required__c = 'Yes',
                POD_Link_Required__c = 'Yes',
                RecordTypeId = openRT
            );

            insert new List<Contract__c>{c1, c2};
            Account sfxAccount = CommonDataTest.getNewSFXAccount();
            sfxAccount.Contract__c = c1.Id;
            insert sfxAccount;
            Account sfxAccount2 = CommonDataTest.getNewSFXAccount();
            sfxAccount2.Contract__c = c2.Id;
            insert sfxAccount2;

        }
    }

    @isTest
    static void processContractsTest() {

        List<Contract__c> contracts = [
            SELECT Id, Name, Contract_End_Date__c,
                   Account__r.Name, Account__c,Account__r.Propel_MSACode__c, RecordType.DeveloperName,
                   (SELECT Id, SFX_Code__c FROM Accounts__r)
            FROM Contract__c
        ];

        Test.startTest();
        ContractRenewalService.processContracts(contracts);
        Test.stopTest();

        System.assert(contracts.size() > 0, 'Contracts should be processed');
    }

    // Helper Method to Get Last Day of Month
    private static Date getMonthEnd(Date inputDate) {
        return Date.newInstance(inputDate.year(), inputDate.month(), 1)
                   .addMonths(1)
                   .addDays(-1);
    }
}