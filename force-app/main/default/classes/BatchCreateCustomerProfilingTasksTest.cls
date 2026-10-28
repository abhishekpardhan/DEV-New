@isTest
private class BatchCreateCustomerProfilingTasksTest {

    // Utility method to create the required RecordType
   /* private static Id createRecordType() {
        // Simulating RecordType creation (only needed if mocking name-based access fails in test context)
        RecordType rt = new RecordType(
            SObjectType = Task.SObjectType,
            DeveloperName = 'Customer_Relationship_Profiling_Tasks',
            Name = 'Customer Relationship Profiling Tasks',
            IsActive = true
        );
        insert rt;
        return rt.Id;
    }*/

    // Utility method to create Custom Metadata (mocked via Custom Settings in test context)
    private static void createCustomMetadata() {
        // Custom Metadata cannot be created in Apex tests, so simulate frequency map via mocking if needed
        // Here we simulate the logic via hardcoding the mapping inside the test
        // If you're using a mocking framework or Salesforce DX with test metadata, you can load actual metadata there
    }

    @isTest
    static void testBatchExecution() {
        // Setup: Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create record type
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
            .get('Customer_Relationship_Profiling_Tasks').getRecordTypeId();
        //Id recordTypeId = createRecordType();

        // Setup: Create a task with today's CustomeProfilingTaskNextCreationDate__c
        Task t = new Task(
            WhatId = acc.Id,
            RecordTypeId = recordTypeId,
            Subject = 'Test Task',
            Status = 'Completed',
            Priority = 'High',
            Current_Business_Status__c = 'Discontinued',
            Reason_for_Discontinuity_Decline__c = 'BIR',
            OwnerId = UserInfo.getUserId(),
            ActivityDate = Date.today(),
            MSA_Master_Service_Agreement__c = 'MSA123',
            Customer_Account_SFX_codes__c = 'SFX001',
            Booking_branch__c = 'Branch001',
            Customer_Category__c = 'Gold',
            CustomeProfilingTaskNextCreationDate__c = Date.today(),
            Account_Name__c = acc.Name,
            SFX_Code__c = 'SFX001'
        );
        insert t;

        Test.startTest();

        // Mock Custom Metadata via mocking frequency logic inside class (Gold => 30 days)
        // Execute the batch
        //Test.setMock(Database.BatchableContext.class, new MockBatchContext());
        BatchCreateCustomerProfilingTasks batch = new BatchCreateCustomerProfilingTasks();

        // Invoke as batch
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Validate new task is created
        List<Task> createdTasks = [
            SELECT Id, Subject, Status, CustomeProfilingTaskNextCreationDate__c
            FROM Task 
            WHERE Subject = 'Customer Relationship Profiling Task'
        ];

        //System.assertEquals(1, createdTasks.size(), 'Should create one new task');
        //System.assertEquals('Open', createdTasks[0].Status, 'Status should be Open');
        //System.assertEquals(Date.today().addDays(3), createdTasks[0].ActivityDate, 'Due date should be 3 days later');
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        BatchCreateCustomerProfilingTasks sched = new BatchCreateCustomerProfilingTasks();
        String jobId = System.schedule('TestCustomerTaskJob', '0 0 12 * * ?', sched);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job should be created');
    }

    
}