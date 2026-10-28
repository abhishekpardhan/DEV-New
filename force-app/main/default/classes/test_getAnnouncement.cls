@isTest
public class test_getAnnouncement{
    @IsTest
    static void testMethodIncludeProfile() {
        
        Id profileId= userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name; 
        
       Announcement__c announcement1 = new Announcement__c(
            Name = 'Test Announcement',
            Image__c = 'Test Image',
            User_profile__c = 'Include Profile',
            Other_Profiles__c = profileName,
            isActive__c = True
        ); 
        insert announcement1;
		                
        Test.startTest();
        List<getAnnouncement.announcementItemWrapper> result = getAnnouncement.getAnnouncements();
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('Test Announcement', result[0].name);
        System.assertEquals('Test Image', result[0].image);
        System.assertEquals(true, result[0].isVisible);
    }
    
    @IsTest
    static void testMethodExcludeProfile() {
        
        Id profileId= userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name; 
        
       Announcement__c announcement1 = new Announcement__c(
            Name = 'Test Announcement',
            Image__c = 'Test Image',
            User_profile__c = 'Exclude Profile',
            Other_Profiles__c = profileName,
            isActive__c = True
        ); 
        insert announcement1;
		                
        Test.startTest();
        List<getAnnouncement.announcementItemWrapper> result = getAnnouncement.getAnnouncements();
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('Test Announcement', result[0].name);
        System.assertEquals('Test Image', result[0].image);
        System.assertEquals(false, result[0].isVisible); 
    }
    
    
    @IsTest
    static void testMethodAllProfile() {
        
        Id profileId= userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name; 
        
       Announcement__c announcement1 = new Announcement__c(
            Name = 'Test Announcement',
            Image__c = 'Test Image',
            User_profile__c = 'All Profile',
            Other_Profiles__c = profileName,
            isActive__c = True
        ); 
        insert announcement1;
		                
        Test.startTest();
        List<getAnnouncement.announcementItemWrapper> result = getAnnouncement.getAnnouncements();
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('Test Announcement', result[0].name);
        System.assertEquals('Test Image', result[0].image);
        System.assertEquals(true, result[0].isVisible); 
    }
        
}