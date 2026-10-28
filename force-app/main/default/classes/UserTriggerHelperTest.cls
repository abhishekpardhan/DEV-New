@isTest
private class UserTriggerHelperTest {
     @isTest static void testUserBackupQueueableInsert() {
        User newUser = CommonDataTest.getUserAM();
        newUser.Region__c = 'CORPORATE OFFICE';
        insert newUser;
        Test.startTest();
        UserTriggerHelper.processUsers(new List<User>{newUser}, new Map<Id, User>(), true, false);
        Test.stopTest();
    }
    
    @isTest static void testUserBackupQueueableUpdate() {
        User oldUser = CommonDataTest.getUserAM();
        oldUser.Region__c = 'CORPORATE OFFICE'; 
        insert oldUser;
        
        // Create updated user data
        oldUser.Department = 'Marketing';
        update oldUser;
        // Create a map with old user data
        Map<Id, User> oldUserMap = new Map<Id, User>();
        oldUserMap.put(oldUser.Id, oldUser);
        
        // Test enqueue method
        Test.startTest();
        UserTriggerHelper.processUsers(new List<User>{oldUser}, oldUserMap, false, true);
        Test.stopTest();
    }
    
}