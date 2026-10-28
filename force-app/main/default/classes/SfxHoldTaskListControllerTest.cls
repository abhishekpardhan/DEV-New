@IsTest
private class SfxHoldTaskListControllerTest {

    @IsTest
    static void testGetHoldTasksForSfx() {

        String userId = userInfo.getUserID();
        
        Branch_Master__c objBranchMas = CommonDataTest.getBranchMaster();
        insert objBranchMas;
        
        Branch_Master__c objBranchMas1 = CommonDataTest.getBranchMaster();
        insert objBranchMas1;
        
        User_Branch_Mapping__c objUs = new User_Branch_Mapping__c();
        objUs.Branch_Name__c = objBranchMas.Id;
        objUs.User__c = userId;
        insert objUs;
        
        User_Branch_Mapping__c objUs1 = new User_Branch_Mapping__c();
        objUs1.Branch_Name__c = objBranchMas1.Id;
        objUs1.User__c = userId;
        insert objUs1;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Booking_Branch__c = objBranchMas.Id;
        insert objSfx;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        User us1 = CommonDataTest.getUserBdm();
        insert us1;
        
        User us3 = CommonDataTest.getUserBdm();
        insert us3;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.national1__c = true;
        accteam.national2__c = true;
        accteam.national3__c = true;
        accteam.national4__c = true;
        accteam.Account__c = objPro.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
        
        
        
         Account srvcAccount = CommonDataTest.getServiceAccount();
            srvcAccount.ParentId = objSfx.id;
            insert srvcAccount;
            System.assertNotEquals(srvcAccount.id, Null);
            // Insert rate Card account. 
        
         Account rcAccount = CommonDataTest.getRateCardAccount();
            rcAccount.ParentId = srvcAccount.Id;
            rcAccount.AssignBranch_ID__c = '123457';
            String rcName = rcAccount.Name;
            
            Insert rcAccount;
        
        Account_Team__c accteam2 = new Account_Team__c();
        accteam2.national3__c = true;
        accteam2.national4__c = true;
        accteam2.Account__c = rcAccount.Id;
        accteam2.BDM__c=us3.Id;
        insert accteam2;
        
        
        // Insert Branch Account. added by Vikas Sharma brchAccount1
        Account brchAccount1 = CommonDataTest.getBarnchAccount();
        brchAccount1.Name = 'ASSIGN BRANCH:' + rcName;
        brchAccount1.Assign_Branch_Id__c = objBranchMas.Id;
        brchAccount1.Billing_Branch__c = objBranchMas.Id;
        brchAccount1.ParentId = rcAccount.Id; //ADD by Vikas Sharma
        //insert brchAccount1;
        //System.assertNotEquals(brchAccount1.Id, Null);
        insert brchAccount1;
        brchAccount1.Delivery_Hold__c = '1';
        update brchAccount1;
        
        Task taskRecord = CommonDataTest.getGeneralTask();
        taskRecord.Subject = ConstantUtility.HOLD_TASK_SUBJECT_PREFIX;
        taskRecord.WhatId = brchAccount1.id;
        insert taskRecord;

        brchAccount1.Delivery_Hold__c = '0';
        update brchAccount1;

        // Older task for Branch 1
        Task oldTask = CommonDataTest.getGeneralTask();
        oldTask.Subject =  ConstantUtility.HOLD_TASK_SUBJECT_PREFIX;
        oldTask.WhatId = brchAccount1.Id;
        insert oldTask;

        // Latest task for Branch 1
        Task latestTask = CommonDataTest.getGeneralTask();
        latestTask.Subject =  ConstantUtility.HOLD_TASK_SUBJECT_PREFIX;
        latestTask.WhatId = brchAccount1.Id;
        insert latestTask;

        // Task for Branch 2
        Task branch2Task = CommonDataTest.getGeneralTask();
        branch2Task.Subject =  ConstantUtility.HOLD_TASK_SUBJECT_PREFIX;
        branch2Task.WhatId = brchAccount1.Id;
        insert branch2Task;
        // Test 1: Subject filter only - no hierarchy
List<Task> subjectOnly = [
    SELECT Id, Subject, WhatId,
           Account.Parent.Parent.ParentId
    FROM Task
    WHERE Subject LIKE :ConstantUtility.HOLD_TASK_SUBJECT_PREFIX + '%'
];
System.debug('Subject only count: ' + subjectOnly.size());
for(Task t : subjectOnly) {
    System.debug('Task Id: ' + t.Id 
        + ' | WhatId: ' + t.WhatId
        + ' | 3-level parent: ' + t.Account?.Parent?.Parent?.ParentId);
}

// Test 2: Confirm what ParentId the hierarchy actually resolves to
System.debug('objSfx.Id = ' + objSfx.Id);
System.debug('srvcAccount.Id = ' + srvcAccount.Id);
System.debug('rcAccount.Id = ' + rcAccount.Id);

// Test 3: Try each hierarchy level explicitly
List<Task> level1 = [SELECT Id FROM Task WHERE Account.ParentId IN :new List<Id>{brchAccount1.ParentId}];
System.debug('Level 1 (rcAccount) count: ' + level1.size());

List<Task> level2 = [SELECT Id FROM Task WHERE Account.Parent.ParentId = :srvcAccount.Id];
System.debug('Level 2 (srvcAccount) count: ' + level2.size());

List<Task> level3 = [SELECT Id FROM Task WHERE Account.Parent.Parent.ParentId = :objSfx.Id];
System.debug('Level 3 (objSfx) count: ' + level3.size());

List<Task> level4 = [SELECT Id FROM Task WHERE Account.Parent.Parent.Parent.ParentId = :objPro.Id];
System.debug('Level 4 (objPro) count: ' + level4.size());

        Test.startTest();

        List<SfxHoldTaskListController.FlowOutputs> results =
            SfxHoldTaskListController.getHoldTasksForSfx(
                new List<Id>{ objSfx.Id }
            );

        Test.stopTest();
    }


    @IsTest
    static void testGetHoldTasksForSfx_NoInput() {

        Test.startTest();

        List<SfxHoldTaskListController.FlowOutputs> results =
            SfxHoldTaskListController.getHoldTasksForSfx(
                new List<Id>()
            );

        Test.stopTest();
    }
}