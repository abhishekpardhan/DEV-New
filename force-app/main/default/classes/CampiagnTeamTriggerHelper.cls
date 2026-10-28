/**
 * Description      :   Helper class for Campaign Team Trigger to perform various operations  like providing/removing the sharing of Campaign records to Campaign members
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
public class CampiagnTeamTriggerHelper {
    
    /**
     * Method to provide the sharing of the Campaign records to Campaign team members
     **/
    public static void addSharing(List<Campaign_Team__c> lstCampaignTeam){
        try{
            List<Campaign__Share> lstCampaignShare = new List<Campaign__Share>();
            for(Campaign_Team__c objCamTeam : lstCampaignTeam){
                Campaign__Share objShare = new Campaign__Share(); 
                objShare.ParentId = objCamTeam.Campaign__c;
                objShare.UserOrGroupId = objCamTeam .BDM__c;
                objShare.AccessLevel = 'Read';
                lstCampaignShare.add(objShare);     
            }
            if(lstCampaignShare.size() > 0){
                insert lstCampaignShare;
            }
        }Catch(Exception e){
            System.debug('Exception '+e.getMessage());
            System.debug('Exception line Number '+e.getlineNumber());
        }
    }
    
    /**
     * Method to remove the sharing of 'Campaign' record from user if it updating or removing from Campaign team
     **/
    public static void removeSharing(List<Campaign_Team__c> lstCamteam,Set<Id> setCamIds ){
        List<Campaign__Share> lstCamShare = new List<Campaign__Share>();
        Map<String,Campaign__Share> mapCamShare = new Map<String,Campaign__Share>();
        try{
            for(Campaign__Share CamShare: [select id,userorgroupid,ParentId from Campaign__Share where ParentId IN : setCamIds]){
               
                mapCamShare.put(CamShare.ParentId+'+'+CamShare.userorgroupid,CamShare);
            }            
            for(Campaign_Team__c campT: lstCamteam){
                Campaign__Share camShare = new Campaign__Share();
                camShare = mapCamShare.get(campT.Campaign__c+'+'+campT.BDM__c);
                if(camShare != null){
                    lstCamShare.add(camShare);
                }
            }
            if(!lstCamShare.isEmpty()){
                delete lstCamShare;
                
            }
        }Catch(Exception e){
            System.debug('Exception '+e.getMessage());
            System.debug('Exception line Number '+e.getlineNumber());
        }
    }
}