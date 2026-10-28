/**
 * Description		:		Test class for ReassignTaskOwnerController
 * 
 * Coverage			:		84%
 **/
@isTest 
public class ReassignTaskOwnerControllerTest {
 // Setup data used across all test methods
    @testSetup
    static void setupData() {
        // Create active users
        List<User> users = new List<User>{
            new User(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'johndoe@example.com',
                Username = 'johndoe1@example.com.test',
                Alias = 'jdoe',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                IsActive = true,
                LanguageLocaleKey = 'en_US',
                Region__c = 'MUMBAI',
                Journey_Type__c = 'Bike',
                Sportfire_Group__c = 'Group 1',
                Type__c = 'Credit'
            ),
            new User(
                FirstName = 'Jane',
                LastName = 'Smith',
                Email = 'janesmith@example.com',
                Username = 'janesmith1@example.com.test',
                Alias = 'jsmith',
                IsActive = true,
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                Region__c = 'RAJASTHAN',
                Journey_Type__c = 'Bike',
                Sportfire_Group__c = 'Group 1',
                Type__c = 'Credit+Retail'
            )
        };
        insert users;

        // Create tasks assigned to the first user
        List<Task> tasks = new List<Task>{
            new Task(Subject = 'Incomplete Task', Status = 'Open', OwnerId = users[0].Id)
        };
        insert tasks;
    }

    @isTest
    static void testFindUsers() {
        Test.startTest();
        List<User> results = ReassignTaskOwnerController.findUsers('Jane');
        Test.stopTest();
        System.assertNotEquals(0, results.size(), 'Should return matching users');
    }

    @isTest
    static void testFetchCompletedTask_WithCompletedTask() {
        Task completedTask = [SELECT Id FROM Task LIMIT 1];
        Test.startTest();
        String result = ReassignTaskOwnerController.fetchCompletedTask(new List<Id>{completedTask.Id});
        Test.stopTest();
    }

    @isTest
    static void testFetchCompletedTask_WithoutCompletedTask() {
        Task incompleteTask = [SELECT Id FROM Task WHERE Status != 'Completed' LIMIT 1];
        Test.startTest();
        String result = ReassignTaskOwnerController.fetchCompletedTask(new List<Id>{incompleteTask.Id});
        Test.stopTest();
        System.assertEquals('', result);
    }
    @isTest
    static void testFetchCompletedTask_EmptyList() {
        Test.startTest();
        String result = ReassignTaskOwnerController.fetchCompletedTask(new List<Id>());
        Test.stopTest();
        System.assertEquals('Task IDs is missing.', result);
    }
    
    @isTest
    static void testReassignTaskOwners_InvalidInput() {
        Test.startTest();
        String result = ReassignTaskOwnerController.reassignTaskOwners(new List<Id>(), null);
        Test.stopTest();
        System.assertEquals('Task IDs or new owner is missing.', result);
    }

    @isTest
    static void reassignTaskOwnersTest() {
        Id taskId = [SELECT Id FROM Task LIMIT 1].Id;
        Id ownerId = [SELECT Id FROM User LIMIT 1].Id;
        Test.startTest();
        String result = ReassignTaskOwnerController.reassignTaskOwners(new List<Id>{taskId},ownerId);
        Test.stopTest();
    }
}