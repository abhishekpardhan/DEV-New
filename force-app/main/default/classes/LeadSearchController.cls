public without sharing class LeadSearchController {
    
    @AuraEnabled
    public static List<Lead__c> searchLeads(String searchTerm, Id campaignId) {
        System.debug('campaignId'+campaignId);
        return [
            SELECT Id, Name, Phone__c, Email__c
            FROM Lead__c
            WHERE (Name LIKE :('%' + searchTerm + '%') OR 
            Email__c LIKE :searchTerm OR
            Phone__c LIKE :searchTerm) AND (Status__c != 'Dropped' AND Status__c != 'Passive') and Id NOT IN (SELECT Lead__c FROM Campaign_Lead__c where Campaign__c =: campaignId)
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static void createCampaignMembers(Id campaignId, List<Id> leadIds, Map<Id, String> remarksMap) {
        List<Campaign_Lead__c> cms = new List<Campaign_Lead__c>();

        for (Id leadId : leadIds) {
            cms.add(new Campaign_Lead__c(
                Campaign__c = campaignId,
                Lead__c = leadId,
                Remarks__c = remarksMap.containsKey(leadId) ? remarksMap.get(leadId) : null
            ));
        }
        insert cms;
    }
}