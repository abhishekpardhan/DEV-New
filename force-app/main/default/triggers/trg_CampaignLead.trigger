trigger trg_CampaignLead on Campaign_Lead__c (before update, before delete) {
    Set<Id> campaignIds = new Set<Id>();

    if (Trigger.isUpdate || Trigger.isDelete) {
        for (Campaign_Lead__c cm : Trigger.isDelete ? Trigger.old : Trigger.new) {
            if (cm.Campaign__c != null) {
                campaignIds.add(cm.Campaign__c);
            }
        }
    }

    if (!campaignIds.isEmpty()) {
        Map<Id, Campaign__c> campaignMap = new Map<Id, Campaign__c>(
            [SELECT Id, Status__c FROM Campaign__c WHERE Id IN :campaignIds]
        );

        for (Campaign_Lead__c cm : (Trigger.isDelete ? Trigger.old : Trigger.new)) {
            Campaign__c relatedCampaign = campaignMap.get(cm.Campaign__c);
            if (relatedCampaign != null && relatedCampaign.Status__c != 'Active') {
                cm.addError('You can only edit or delete Campaign Members when the related Campaign is Active.');
            }
        }
    }
}