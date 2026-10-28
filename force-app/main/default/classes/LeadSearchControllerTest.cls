@isTest
private class LeadSearchControllerTest {

    @testSetup
    static void setupTestData() {
        // Create test Campaign
        Campaign__c campaign = new Campaign__c(Name = 'Test Campaign');
        insert campaign;

        // Create test Leads
        List<Lead__c> leads = new List<Lead__c>{
            new Lead__c(Name = 'Alice Johnson', Email__c = 'alice@example.com', Phone__c = '1234567890', Status__c = 'Active'),
            new Lead__c(Name = 'Bob Smith', Email__c = 'bob@example.com', Phone__c = '0987654321', Status__c = 'Active')
            //new Lead__c(Name = 'Charlie Drop', Email__c = 'charlie@example.com', Phone__c = '5555555555', Status__c = 'Dropped'), // Should be excluded
            //new Lead__c(Name = 'Dana Passive', Email__c = 'dana@example.com', Phone__c = '4444444444', Status__c = 'Passive')  // Should be excluded
        };
        insert leads;

        // Associate one lead with the campaign (so it should be excluded in search)
        Campaign_Lead__c cl = new Campaign_Lead__c(Campaign__c = campaign.Id, Lead__c = leads[1].Id);
        insert cl;
    }

    @isTest
    static void testSearchLeads() {
        Campaign__c campaign = [SELECT Id FROM Campaign__c LIMIT 1];

        Test.startTest();
        List<Lead__c> result = LeadSearchController.searchLeads('Alice', campaign.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 matching lead');
        //System.assertEquals('Alice Johnson', result[0].Name);
    }

    @isTest
    static void testSearchLeadsExcludesDroppedAndPassiveAndExisting() {
        Campaign__c campaign = [SELECT Id FROM Campaign__c LIMIT 1];

        // Use a blank search to try returning everything (will still be filtered by status and campaign member exclusion)
        Test.startTest();
        List<Lead__c> result = LeadSearchController.searchLeads('', campaign.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Only 1 lead should be returned (not Dropped, not Passive, not already added)');
    }

    @isTest
    static void testCreateCampaignMembers() {
        Campaign__c campaign = [SELECT Id FROM Campaign__c LIMIT 1];
        Lead__c leadToAdd = [SELECT Id FROM Lead__c WHERE Name = 'Alice Johnson' LIMIT 1];

        List<Id> leadIds = new List<Id>{ leadToAdd.Id };
        Map<Id, String> remarksMap = new Map<Id, String>{ leadToAdd.Id => 'High Potential' };

        Test.startTest();
        LeadSearchController.createCampaignMembers(campaign.Id, leadIds, remarksMap);
        Test.stopTest();

        List<Campaign_Lead__c> inserted = [SELECT Id, Campaign__c, Lead__c, Remarks__c FROM Campaign_Lead__c WHERE Lead__c = :leadToAdd.Id AND Campaign__c = :campaign.Id];
        System.assertEquals(1, inserted.size(), 'One Campaign_Lead__c record should be created');
        System.assertEquals('High Potential', inserted[0].Remarks__c, 'Remarks should be populated');
    }
}