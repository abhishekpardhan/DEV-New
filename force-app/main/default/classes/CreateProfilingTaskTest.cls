@isTest
private class CreateProfilingTaskTest {

    @isTest
    static void testCustomerProfilingTaskFromATList() {
        // Step 1: Setup test data
        User testBDM = CommonDataTest.getUserBdm();
        insert testBDM;

        Account msa = CommonDataTest.getMSAAccount();
        insert msa;

        Account sfx = CommonDataTest.getNewSFXAccount();
        sfx.ParentId = msa.Id;
        insert sfx;

        Account service = CommonDataTest.getServiceAccount();
        service.ParentId = sfx.Id;
        insert service;

        Branch_Master__c branch = CommonDataTest.getBranchMaster();
        branch.Branch_Code__c = 'BR001';
        insert branch;

        // Create Account_Team__c record with required fields
        Id accTeamRTId = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();

        Account_Team__c at = new Account_Team__c(
            BDMPropelI__c = testBDM.Id,
            Account__c = service.Id,
            PropelI_Composite_Key__c = testBDM.Id + '::' + msa.Id,
            Relationship__c = true,
            RecordTypeId = accTeamRTId
        );
        insert at;

        List<List<Account_Team__c>> wrapperList = new List<List<Account_Team__c>>{
            new List<Account_Team__c>{ at }
        };

        // Step 2: Call the method under test
        Test.startTest();
        List<CreateProfilingTask.FlowResponse> result = CreateProfilingTask.customerProfilingTaskFromATList(wrapperList);
        Test.stopTest();

        // Step 3: Validate result
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'There should be one FlowResponse');
        
        CreateProfilingTask.FlowResponse resp = result[0];
        System.debug('Inserted: ' + resp.insertedCount);
        System.debug('Updated: ' + resp.updatedCount);
        System.debug('No Change: ' + resp.noChangeCount);

        System.assert(resp.insertedCount != null || resp.updatedCount != null || resp.noChangeCount != null,
            'At least one count should be non-null');
    }
}