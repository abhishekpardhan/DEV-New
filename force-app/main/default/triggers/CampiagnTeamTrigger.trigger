/**
 * Description      :   Trigger on Campaign_Team__c object to provide the sharing of records to Campaign Team members
 *                      by calling helper class methods
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
trigger CampiagnTeamTrigger on Campaign_Team__c (after insert , after delete,after update) {
    
    //Checking Trigger Switch Values
    if(System.Label.TriggerSwitch.equals('On')){
        if(trigger.isAfter  && trigger.isInsert){
            CampiagnTeamTriggerHelper.addSharing(trigger.new);
        }
        if(trigger.isAfter && trigger.isUpdate){
            List<Campaign_Team__c> lstNewCampaignTeam = new List<Campaign_Team__c>();
            List<Campaign_Team__c> lstOldCampaignTeam = new List<Campaign_Team__c>();
            Set<Id> setOldCamIds = new Set<Id>();
            for(Campaign_Team__c objCam : trigger.new){
                if(objCam.BDM__C != trigger.oldMap.get(objCam.Id).BDM__C){
                    lstNewCampaignTeam.add(objCam);
                    lstOldCampaignTeam.add(trigger.oldMap.get(objCam.Id));
                    setOldCamIds.add(trigger.oldMap.get(objCam.Id).Campaign__c);
                }
            }
            System.debug('<< lstNewCampaignTeam >> '+lstNewCampaignTeam);
            System.debug('<< lstOldCampaignTeam >> '+lstOldCampaignTeam);
            System.debug('<< setOldCamIds >> '+setOldCamIds);
            
            if(lstOldCampaignTeam.size() > 0 && setOldCamIds.size() > 0){
                CampiagnTeamTriggerHelper.removeSharing(lstOldCampaignTeam,setOldCamIds);
            }
            if(lstNewCampaignTeam.size() > 0){
                CampiagnTeamTriggerHelper.addSharing(lstNewCampaignTeam);
            }
        }
        if(trigger.isAfter  && trigger.isdelete){
            Set<Id> setCamIds = new Set<Id>();
            for(Campaign_Team__c objCam : trigger.old){
                setCamIds.add(objCam.Campaign__c);
            }
            CampiagnTeamTriggerHelper.removeSharing(trigger.old,setCamIds);
        }
    }
}