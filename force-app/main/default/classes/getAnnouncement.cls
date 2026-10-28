public with sharing class getAnnouncement {
	
    @AuraEnabled(cacheable=true)
    public static List<announcementItemWrapper> getAnnouncements(){
        
        List<announcementItemWrapper> annList = new List<announcementItemWrapper>();
        List<String> lstString = new  List<String>();
        for(Announcement__c cc : [Select Id, Name, Image__c, User_profile__c, Other_Profiles__c from Announcement__c where isActive__c = True]){
            announcementItemWrapper wr = new announcementItemWrapper();
            wr.Id = cc.Id;
            wr.name = cc.name;
            wr.image = cc.Image__c;
            wr.userProfile = cc.User_profile__c;
            wr.otherProfile = cc.Other_Profiles__c;
            
            if(cc.Other_Profiles__c!= null){
            	lstString = cc.Other_Profiles__c.split(',');
            }
            Id profileId= userinfo.getProfileId();
			String profileName=[Select Id,Name from Profile where Id=:profileId].Name; 
            system.debug('profileName--->'+profileName);
            wr.isVisible = false; 
            if(
                (cc.User_profile__c == 'Include Profile' && lstString.contains(profileName)) ||
                (cc.User_profile__c == 'Exclude Profile' && !lstString.contains(profileName)) ||
                (cc.User_profile__c == 'All Profile')
            ){
                wr.isVisible = True;                               
            }  
            annList.add(wr);
            system.debug('annList--->'+annList);
        } 
		 system.debug(annList);       
         return annList;
    }
    
    public class announcementItemWrapper{
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String Image;
        @AuraEnabled
        public Boolean isVisible;
        @AuraEnabled
        public String userProfile;
        @AuraEnabled
        public String otherProfile;
    }
}