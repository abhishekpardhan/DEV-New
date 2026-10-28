@isTest
public class trg_CampaignLead_Test {
    @isTest static void testUpdateBlockedWhenCampaignNotActive() {
        // Create a Campaign with Status__c != 'Active'
        Campaign__c camp = new Campaign__c(Status__c='Cancelled',Reason__c = 'Very high cost of space');
        insert camp;

        // Create a Campaign_Lead__c linked to the Campaign
        Campaign_Lead__c lead = new Campaign_Lead__c(Campaign__c=camp.Id);
        insert lead;

        // Try to update Campaign_Lead__c - should fail due to trigger error
        //lead.Name = 'Updated Lead';

        try {
            update lead;
            System.assert(false, 'Expected exception not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You can only edit or delete Campaign Members when the related Campaign is Active.'));
        }
    }

    @isTest static void testUpdateAllowedWhenCampaignActive() {
        // Create a Campaign with Status__c = 'Active'
        Campaign__c camp = new Campaign__c(Name='Active Campaign', Status__c='Active');
        insert camp;

        // Create a Campaign_Lead__c linked to the Campaign
        Campaign_Lead__c lead = new Campaign_Lead__c(Campaign__c=camp.Id);
        insert lead;

        // Try to update Campaign_Lead__c - should succeed
        //lead.Name = 'Updated Lead';
        update lead;

        // Verify update
        Campaign_Lead__c updatedLead = [SELECT Name FROM Campaign_Lead__c WHERE Id = :lead.Id];
        //System.assertEquals('Updated Lead', updatedLead.Name);
    }

    @isTest static void testDeleteBlockedWhenCampaignNotActive() {
        // Create a Campaign with Status__c != 'Active'
        Campaign__c camp = new Campaign__c(Name='Test Campaign', Status__c='Cancelled',Reason__c = 'Very high cost of space');
        insert camp;

        // Create a Campaign_Lead__c linked to the Campaign
        Campaign_Lead__c lead = new Campaign_Lead__c(Campaign__c=camp.Id);
        insert lead;

        // Try to delete Campaign_Lead__c - should fail due to trigger error
        try {
            delete lead;
            System.assert(false, 'Expected exception not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You can only edit or delete Campaign Members when the related Campaign is Active.'));
        }
    }

    @isTest static void testDeleteAllowedWhenCampaignActive() {
        // Create a Campaign with Status__c = 'Active'
        Campaign__c camp = new Campaign__c(Status__c='Active');
        insert camp;

        // Create a Campaign_Lead__c linked to the Campaign
        Campaign_Lead__c lead = new Campaign_Lead__c(Campaign__c=camp.Id);
        insert lead;

        // Try to delete Campaign_Lead__c - should succeed
        delete lead;

        // Verify deletion
        Integer countLeads = [SELECT COUNT() FROM Campaign_Lead__c WHERE Id = :lead.Id];
        System.assertEquals(0, countLeads);
    }
}