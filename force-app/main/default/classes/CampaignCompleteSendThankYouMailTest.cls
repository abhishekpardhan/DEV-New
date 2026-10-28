/**
 * @File Name          : CampaignCompleteSendThankYouMailTest.cls
 * @Description        : CampaignCompleteSendThankYouMailTest is the test class for CampaignCompleteSendThankYouMail apex class
 * @Author             : Manshi Joshi
 * @Group              : IBM
 * @Coverage		   : 95%
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        26-06-2025                Manshi                   Initial Version
**/
@isTest
public class CampaignCompleteSendThankYouMailTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test user who will be the campaign owner
        User campaignOwner = new User(
            FirstName = 'Campaign',
            LastName = 'Owner',
            Email = 'campaign.owner@test.com',
            Username = 'campaign.owner@test.com.test',
            Alias = 'campown',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            Region__c = 'CORPORATE OFFICE',
            Journey_Type__c = 'Car',
            Sportfire_Group__c = 'Group 1',
            Type__c = 'Retail',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert campaignOwner;

        // Create Campaign
        Campaign__c campaign = new Campaign__c(
            Name = 'Test Campaign',
            OwnerId = campaignOwner.Id
        );
        insert campaign;

        // Create a lead with valid email and campaign reference
        Lead__c lead = new Lead__c(
            Name = 'Test Lead',
            Email__c = 'lead@example.com',
            Campaign__c = campaign.Id,
            OwnerId = campaignOwner.Id
        );
        insert lead;
    }

    @isTest
    static void testSendThankYouEmails() {
        // Fetch the test campaign ID
        Id campaignId = [SELECT Id FROM Campaign__c LIMIT 1].Id;
        Test.startTest();
        CampaignCompleteSendThankYouMail.sendThankYouEmails(new List<Id>{ campaignId });
        Test.stopTest();
    }

    @isTest
    static void testNoEmailForBlankLeadEmail() {
        // Create a campaign
        Campaign__c camp = new Campaign__c(Name = 'No Email Lead Campaign');
        insert camp;

        // Create a lead without Email__c
        Lead__c lead = new Lead__c(
            Name = 'Lead Without Email',
            Campaign__c = camp.Id,
            Email__c = 'lead@gmail.com',
            OwnerId = UserInfo.getUserId()
        );
        insert lead;
        Campaign_Lead__c lead1 = new Campaign_Lead__c(Campaign__c=camp.Id,lead__c = lead.id);
        insert lead1;

        Test.startTest();
        CampaignCompleteSendThankYouMail.sendThankYouEmails(new List<Id>{ camp.Id });
        Test.stopTest();

        // No email should be sent
        System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent for lead without email');
    }


}