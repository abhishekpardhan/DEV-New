@isTest 
public class TaskTriggerHelperTest {
     
    static testMethod void testMethod1() {
            
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
		
        Branch_Master__c bm = new Branch_Master__c();
        bm.Name = 'Test Branch1';
        insert bm;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Branch__c = bm.Id;
        
        insert objSfx;
        

        User us = CommonDataTest.getUserBdm();
        insert us;
                
        
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.National4__c = true;
        accteam.Collection__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDMPropelI__c=us.Id;
        accteam.PropelI_Composite_Key__c = us.Id+'::'+objSfx.Id;
        insert accteam;
             
        PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
        mapping.Account__c = objSfx.Id;
        mapping.PropelI_BDM__c = us.Id; 
        mapping.CCD__c = true;
        mapping.Collection__c = true;
        mapping.PropelI_Composite_Key__c = us.Id+'::'+objSfx.Id;
        insert mapping;

        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.Account__c = objSfx.Id;
        objInv.NAM_Propeli_BDM_Mapping__c = mapping.Id;
        objSfx.Billing_Level__c = 'MSA';
        objInv.BDM_Email_IDs__c = 'test@gmail.com';

        insert objInv;
        
        Id rtypeCol = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        
        Task objTask = CommonDataTest.getSubmisionTask();
        objTask.WhatId = objInv.id;
        insert objTask;

        Debit_Credit_Note__c dcn = new Debit_Credit_Note__c();
        dcn.Invoice_Name__c = objInv.Id;
        dcn.Bill_Number__c = 'DCN-TEST-001';
        dcn.Created_Date__c = System.today();
        insert dcn;

        Task objTask2 = CommonDataTest.getSubmisionTask();
        objTask2.WhatId = dcn.id;
        insert objTask2;
        
        Contact objCon = CommonDataTest.getContact();
        objCon.AccountId = objSfx.Id;
        insert objCon ;

        objTask2.Status = 'Completed';
        // objTask2.Submitted_To__c = objCon.Id;
        objTask2.Subject = 'Customer Profiling';
        objTask2.Comments_Added__c = 'Test Comment';
        objTask2.Ebill_Submission__c = true;
        update objTask2;
        
        objTask2.Status = 'In Progress';
        update objTask2;


        objTask.Status = 'Completed';
       // objTask.Submitted_To__c = objCon.Id;
        objTask.Subject = 'Customer Profiling';
        objTask.Comments_Added__c = 'Test Comment';
        objTask.Ebill_Submission__c = true;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Non-Recoverable';
        objTask.RecordTypeId = rtypeCol;
        objTask.status = 'In Progress';
        objTask.Reason__c = 'SUBMIT';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.non_recoverable_reason__c = 'Undelivered';
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Collectable_Amount__c = 7;
        update objTask;
                
        Task objTask1 = CommonDataTest.getGeneralTask();
        objTask1.WhatId = objSfx.id;
        insert objTask1;
            
        objTask1.status = 'Open';
        update objTask1;
        
        objTask.Payment_Remaining__c = 'Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 4;
        objTask.Collectable_Amount__c = 7;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        update objTask;
        
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 5;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 3;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 10;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 60;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 10;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 70;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 10;
        objTask.Recoverable_Amount__c = 50;
        update objTask;
        
    }
    @isTest
    static void testUpdateCollectedAmount_BothPaths() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Task tDebit = new Task(
            Subject = 'Debit Note Test',
            WhatId = acc.Id,
            Status = 'In Progress',
            Collected_Amount__c = 100,
            Recoverable_Amount__c = 50,
            Total_Debit_Note__c = 0
        );

        Task tCredit = new Task(
            Subject = 'Credit Note Test',
            WhatId = acc.Id,
            Status = 'In Progress',
            Collected_Amount__c = 50,
            Recoverable_Amount__c = 100,
            Total_Credit_Note_Amount__c = 0
        );

        insert new List<Task>{ tDebit, tCredit };

        Map<Id, Task> oldMap = new Map<Id, Task>();
        oldMap.put(tDebit.Id, new Task(Id = tDebit.Id, Collected_Amount__c = 10));  // diff = 90 (Debit)
        oldMap.put(tCredit.Id, new Task(Id = tCredit.Id, Collected_Amount__c = 200)); // diff = -150 (Credit)

        tDebit.Collected_Amount__c = 100;
        tCredit.Collected_Amount__c = 50;

        List<Task> updatedTasks = new List<Task>{ tDebit, tCredit };

        Test.startTest();
            TaskTriggerHelper.updateCollectedAmount(updatedTasks, oldMap);
        Test.stopTest();
    }

    @isTest
    static void testRelateTask_WithContact() {

        Account acc = new Account(Name = 'Test Account');
        insert acc; 
        
        Contact integrationContact = new Contact(
            LastName = 'INTEGRATION CONTACT'
        );
        insert integrationContact;

        Task t = new Task(
            Subject = 'Relate Task Test',
            Status = 'Not Started',
            WhatId = acc.Id
        );
        insert t;

        List<Task> lstTasks = new List<Task>{ t };

        Test.startTest();
            TaskTriggerHelper.relateTask(lstTasks);
        Test.stopTest();
    }

    static testMethod void testMethod7() {
            
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
		
        Branch_Master__c bm = new Branch_Master__c();
        bm.Name = 'Test Branch2';
        insert bm;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Branch__c = bm.Id;
        
        insert objSfx;

        PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
        mapping.Account__c = objSfx.Id;
        mapping.PropelI_BDM__c = UserInfo.getUserId(); 
        mapping.CCD__c = true;
        mapping.Local_NAM__c = true;
        mapping.PropelI_Composite_Key__c = UserInfo.getUserId()+'::'+objSfx.Id;
        insert mapping;
        
        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.Account__c = objSfx.Id;
        objSfx.Billing_Level__c = 'MSA';
        objInv.BDM_Email_IDs__c = 'test@gmail.com';
        objInv.NAM_Propeli_BDM_Mapping__c = mapping.Id;
        insert objInv;

        User us = CommonDataTest.getUserBdm();
        insert us;
                
        
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.National4__c = true;
        accteam.Collection__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDMPropelI__c=us.Id;
        accteam.PropelI_Composite_Key__c = us.Id+'::'+objSfx.Id;
        insert accteam;
             
        Id rtypeCol = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        
        Task objTask = CommonDataTest.getSubmisionTask();
        objTask.WhatId = objInv.id;
        insert objTask;
        
        Contact objCon = CommonDataTest.getContact();
        objCon.AccountId = objSfx.Id;
        insert objCon ;
        
        objTask.Status = 'Completed';
       // objTask.Submitted_To__c = objCon.Id;
        objTask.Subject = 'Customer Profiling';
        objTask.Comments_Added__c = 'Test Comment';
        objTask.Ebill_Submission__c = true;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Non-Recoverable';
        objTask.RecordTypeId = rtypeCol;
        objTask.status = 'In Progress';
        objTask.Reason__c = 'SUBMIT';
        objTask.Invoice_Amount__c = 200;
        objTask.Outstanding_Amount__c = 100;
        objTask.non_recoverable_reason__c = 'Undelivered';
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Collectable_Amount__c = 7;
        try {
            update objTask;
        } catch(Exception e) {
        }
                
        Task objTask1 = CommonDataTest.getGeneralTask();
        objTask1.WhatId = objSfx.id;
        insert objTask1;
            
        objTask1.status = 'Open';
        update objTask1;
        
        objTask.Payment_Remaining__c = 'Recoverable';
        objTask.Invoice_Amount__c = 200;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 4;
        objTask.Collectable_Amount__c = 7;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        update objTask;
        
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 5;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 3;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 10;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 60;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 10;
        update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 100;
        objTask.Collected_Amount__c = 70;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 10;
        objTask.Recoverable_Amount__c = 50;
        update objTask;
        
    }
    static testMethod void testMethod2() {
            
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
		
        Branch_Master__c bm = new Branch_Master__c();
        bm.Name = 'Test Branch1';
        insert bm;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Branch__c = bm.Id;
        insert objSfx;

        PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
        mapping.Account__c = objSfx.Id;
        mapping.PropelI_BDM__c = UserInfo.getUserId(); 
        mapping.CCD__c = true;
        mapping.Local_NAM__c = true;
        mapping.PropelI_Composite_Key__c = UserInfo.getUserId()+'::'+objSfx.Id;
        insert mapping;
        
        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.Account__c = objSfx.Id;
        objInv.BDM_Email_IDs__c = 'test@gmail.com';
        objInv.NAM_Propeli_BDM_Mapping__c = mapping.Id;
        insert objInv;

        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.National4__c = true;
        accteam.Collection__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDMPropelI__c=us.Id;
        accteam.PropelI_Composite_Key__c = objSfx.Id;
        insert accteam;
        
        Id rtypeCol = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        
        Task objTask = CommonDataTest.getSubmisionTask();
        objTask.WhatId = objInv.id;
        insert objTask;
        
        Contact objCon = CommonDataTest.getContact();
        objCon.AccountId = objSfx.Id;
        insert objCon ;
        
        objTask.Status = 'In Progress';
        objTask.Reason__c = 'SUBMIT';
       // objTask.Submitted_To__c = objCon.Id;
       objTask.Subject = 'Customer Profiling';
        objTask.Comments_Added__c = 'Test Comment';
        objTask.Ebill_Submission__c = true;
        //update objTask;
        
        objTask.Collected_Amount__c = 4;
       // update objTask;
        
        objTask.Payment_Remaining__c = 'Non-Recoverable';
        objTask.RecordTypeId = rtypeCol;
        //objTask.Status__c = 'In Progress';
       
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 80;
        objTask.non_recoverable_reason__c = 'Undelivered';
        objTask.Collected_Amount__c = null;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        //update objTask;
                
        Task objTask1 = CommonDataTest.getGeneralTask();
        objTask1.WhatId = objSfx.id;
        insert objTask1;
            
        objTask1.status = 'Open';
        update objTask1;
        
        objTask.Payment_Remaining__c = 'Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 20;
        objTask.Collected_Amount__c = 10;
        
        objTask.Collectable_Amount__c = 7;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        //update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 80;
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 5;
        update objTask;
        
        
    }
    static testMethod void testMethod3() {
        Test.StartTest();
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Journey__c objJ = CommonDataTest.getJourney();
        insert objJ;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
		
        Branch_Master__c bm = new Branch_Master__c();
        bm.Name = 'Test Branch1';
        insert bm;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Branch__c = bm.Id;
        insert objSfx;
        
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Submission__c = true;
        accteam.Collection__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDMPropelI__c=us.Id;
        accteam.PropelI_Composite_Key__c = objSfx.Id;
        insert accteam;
        
        PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
        mapping.Account__c = objSfx.Id;
        mapping.PropelI_BDM__c = UserInfo.getUserId(); 
        mapping.CCD__c = true;
        mapping.Local_NAM__c = true;
        mapping.PropelI_Composite_Key__c = UserInfo.getUserId()+'::'+objSfx.Id;
        insert mapping;

        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.Account__c = objSfx.Id;
        objInv.BDM_Email_IDs__c = 'test@gmail.com';
        objInv.NAM_Propeli_BDM_Mapping__c = mapping.Id;
        insert objInv;
        
        Id rtypeCol = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        
        List<Task> tskList = new List<Task>();
        Task objTask = CommonDataTest.getSubmisionTask();
        objTask.WhatId = objInv.id;
        insert objTask;
        
        Contact objCon = CommonDataTest.getContact();
        objCon.AccountId = objSfx.Id;
        insert objCon ;
        
            
        objTask.Status = 'Completed';
       // objTask.Submitted_To__c = objCon.Id;
       objTask.Subject = 'Customer Profiling';
        objTask.Comments_Added__c = 'Test Comment';
        objTask.Ebill_Submission__c = true;
        objTask.File_Uploaded_By_BDM__c = true;
        update objTask;
        
        
        objTask.Payment_Remaining__c = 'Non-Recoverable';
        objTask.RecordTypeId = rtypeCol;
        objTask.status = 'In Progress';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 80;
        objTask.non_recoverable_reason__c = 'Undelivered';
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Reason__c = 'SUBMIT';
        objTask.Collectable_Amount__c = 7;
        try {
            update objTask;
        } catch(Exception e) {
        }
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 80;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 10;
        objTask.Recoverable_Amount__c = 50;
        
        objTask.Journey__c = objJ.Id;
        objTask.Contact_Person_Name__c = us.Name;
        objTask.Mobile_Number__c = us.Phone;
        objTask.Contact_Person_Email__c = us.Email;
        update objTask;
        tskList.add(objTask);
        
        /*Task collTask = CommonDataTest.getCollectionTask();
        collTask.WhatId = objTask.WhatId;
        collTask.status = 'Open';
        collTask.Priority = 'Normal';
        collTask.OwnerId = us.Id;
        collTask.ActivityDate = system.today();    
        collTask.Outstanding_Amount__c = objTask.Outstanding_Amount__c;
        insert collTask;*/
        
        
        Id rtypeGen = Schema.SObjectType.task.getRecordTypeInfosByName().get('General').getRecordTypeId();
        Task objTask2 = new Task();
        objTask2.subject = 'test sub';
        objTask2.ActivityDate = Date.Today().addDays(7);
        objTask2.recordTypeId = rtypeGen;
        objTask2.WhatId = objSfx.Id;
        insert objTask2;
        
        taskTriggerHelper.updateTask(tskList);
        taskTriggerHelper.onboaStatusTask(tskList);
        Test.stopTest();
    }
    static testMethod void testMethod4(){
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
		
        Branch_Master__c bm = new Branch_Master__c();
        bm.Name = 'Test Branch1';
        insert bm;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Branch__c = bm.Id;
        insert objSfx;

        PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
        mapping.Account__c = objSfx.Id;
        mapping.PropelI_BDM__c = UserInfo.getUserId(); 
        mapping.CCD__c = true;
        mapping.Local_NAM__c = true;
        mapping.PropelI_Composite_Key__c = UserInfo.getUserId()+'::'+objSfx.Id;
        insert mapping;
        
        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.Account__c = objSfx.Id;
        objInv.BDM_Email_IDs__c = 'test@gmail.com';
        objInv.Billing_Level__c = 'MSA';
        objInv.NAM_Propeli_BDM_Mapping__c = mapping.Id;
        insert objInv;

        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Id rtypeCol = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        
        Task objTask = CommonDataTest.getSubmisionTask();
        objTask.WhatId = objInv.id;
        insert objTask;
        
        Contact objCon = CommonDataTest.getContact();
        objCon.AccountId = objSfx.Id;
        insert objCon ;
        
        objTask.Status = 'In Progress';
        objTask.Reason__c = 'SUBMIT';
       // objTask.Submitted_To__c = objCon.Id;
        objTask.Comments_Added__c = 'Test Comment';
        objTask.Subject = 'Customer Profiling';
        objTask.Ebill_Submission__c = true;
        //update objTask;
        
        objTask.Collected_Amount__c = 4;
        //update objTask;
        
        objTask.Payment_Remaining__c = 'Non-Recoverable';
        objTask.RecordTypeId = rtypeCol;
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 80;
        objTask.non_recoverable_reason__c = 'Undelivered';
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
       // update objTask;
                
        Task objTask1 = CommonDataTest.getGeneralTask();
        objTask1.WhatId = objSfx.id;
        insert objTask1;
            
        objTask1.status = 'Open';
        update objTask1;
        
        objTask.Payment_Remaining__c = 'Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 20;
        objTask.Collected_Amount__c = 50;
        objTask.Collectable_Amount__c = 7;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
       // update objTask;
        
        objTask.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 80;
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        objTask.Partly_Recoverable_Amount__c = 5;
        update objTask;
        
    }
  	static testMethod void testMethod5(){
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
		
        Branch_Master__c bm = new Branch_Master__c();
        bm.Name = 'Test Branch1';
        insert bm;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Branch__c = bm.Id;
        insert objSfx;
        
        Account getServiceAccount = CommonDataTest.getServiceAccount();
        getServiceAccount.parentID = objSfx.Id;
        insert getServiceAccount;
         
        Account getRateCardAccount = CommonDataTest.getRateCardAccount();
        getRateCardAccount.parentID = getServiceAccount.Id;
        insert getRateCardAccount;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.Relationship__c = true;
        accteam.Task_Created__c = false;
        accteam.Account__c = getRateCardAccount.Id;
        accteam.BDM__c=userInfo.getUserId();
        insert accteam;
        
        Account_Team__c accteam2 = new Account_Team__c();
        accteam2.Relationship__c = true;
        accteam2.Task_Created__c = true;
        accteam2.Account__c = getRateCardAccount.Id;
        accteam2.BDM__c=userInfo.getUserId();
        insert accteam2;

        PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
        mapping.Account__c = objSfx.Id;
        mapping.PropelI_BDM__c = UserInfo.getUserId(); 
        mapping.CCD__c = true;
        mapping.Local_NAM__c = true;
        mapping.PropelI_Composite_Key__c = UserInfo.getUserId()+'::'+objSfx.Id;
        insert mapping;
                
        Invoice__c objInv = CommonDataTest.getInvoice();
        objInv.Account__c = objSfx.Id;
        objInv.BDM_Email_IDs__c = 'test@gmail.com';
        objInv.NAM_Propeli_BDM_Mapping__c = mapping.Id;
        insert objInv;

        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Id rtypeCol = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        
        Task objTask = CommonDataTest.getSubmisionTask();
        objTask.WhatId = objInv.id;
        insert objTask;
        
        Contact objCon = CommonDataTest.getContact();
        objCon.AccountId = objSfx.Id;
        insert objCon ;
        
         objTask.Status = 'In Progress';
        objTask.Reason__c = 'SUBMIT';
       // objTask.Submitted_To__c = objCon.Id;
        objTask.Comments_Added__c = 'Test Comment';
        objTask.Subject = 'Customer Profiling';
        objTask.Ebill_Submission__c = true;
       // update objTask;
        
        objTask.Collected_Amount__c = null;
        //update objTask;
        
        objTask.Payment_Remaining__c = 'Non-Recoverable';
        objTask.RecordTypeId = rtypeCol;
        objTask.status = 'Open';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 80;
        objTask.non_recoverable_reason__c = 'Undelivered';
        objTask.Collected_Amount__c = 50;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        //update objTask;
                
        Task objTask1 = CommonDataTest.getGeneralTask();
        objTask1.WhatId = objSfx.id;
        insert objTask1;
            
        objTask1.status = 'Open';
        update objTask1;
        
        objTask.Payment_Remaining__c = 'Recoverable';
        objTask.Invoice_Amount__c = 100;
        objTask.Outstanding_Amount__c = 200;
        objTask.Collectable_Amount__c = 7;
        objTask.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTask.Total_Credit_Note_Amount__c = 15.00;
        //update objTask;
        
        objTask.Collected_Amount__c = null;
        //update objTask;
        
        Task objTasks = new Task();
        objTasks.Id = objTask.Id;
        objTasks.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTasks.Invoice_Amount__c = 100;
        objTasks.Outstanding_Amount__c = 80;
        objTasks.Collected_Amount__c = 50;
        objTasks.non_recoverable_reason__c = 'Damage Delivery';
        objTasks.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTasks.Total_Credit_Note_Amount__c = 15.00;
        objTasks.Partly_Recoverable_Amount__c = 5;
        update objTasks;
        
        Task objTaskNon = new Task();
        objTaskNon.Id = objTask.Id;
        objTaskNon.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
        objTaskNon.Invoice_Amount__c = 100;
        objTaskNon.Outstanding_Amount__c = 80;
        objTaskNon.Collected_Amount__c = null;
        objTaskNon.Remaining_Payment_Tentative_Date__c = System.today() + 5;
        objTaskNon.Total_Credit_Note_Amount__c = 15.00;
        objTaskNon.Partly_Recoverable_Amount__c = 5;
        update objTaskNon;
        
        Id rtypeOnBoa = Schema.SObjectType.task.getRecordTypeInfosByName().get('On Boarding').getRecordTypeId();
        Journey__c jo = CommonDataTest.getJourney();
        Task objTask3 = new Task();
        objTask3.subject = 'test sub';
        objTask3.ActivityDate = Date.Today().addDays(7);
        objTask3.recordTypeId = rtypeOnBoa;
        objTask3.WhatId = objSfx.Id;
        objTask3.Status = 'Open';
        //objTask3.Journey__c = jo.Id;
        insert objTask3;
        Task t = [SELECT Id, WhatId, OwnerId FROM Task Where Id =:objTask3.Id  LIMIT 1];
        List<Task> lstTask = new List<Task>{t};

        Test.startTest();
        // Call helper to set Task_Created__c = TRUE
        taskTriggerHelper.updateTaskCreatedAccTeam(lstTask, false);
        // Call helper to set Task_Created__c = TRUE
        taskTriggerHelper.updateTaskCreatedAccTeam(lstTask, True);
        Test.stopTest();

        // Verify update worked
        //Account_Team__c updatedAT = [SELECT Id, Task_Created__c FROM Account_Team__c LIMIT 1];
        //System.assertEquals(true, updatedAT.Task_Created__c, 'Task_Created__c should be set to TRUE');
        /*Task objTask4 = new Task();
        objTask4.Id = objTask3.Id;
        objTask4.Status = 'Completed';
        update objTask4;*/
        
    }
    
    static testMethod void testMethod6(){
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        Contact objCon = new Contact();
        objCon.FirstName = 'INTEGRATION';
        objCon.LastName = 'CONTACT';
        objCon.Is_Active__c = true;
        objCon.Email = 'test@gmail.com';
        objCon.MobilePhone = '7686543212';
        objCon.Designation__c = 'Associate';
        objCon.Department__c = 'Sales';
        objCon.Contact_State__c ='Andhra Pradesh';
        objCon.Responsible_for__c = 'BIR';
        objCon.MailingStreet = 'test street';
        objCon.MailingPostalCode = '567654';
        objCon.MailingState = 'test';
        objCon.MailingCity = 'test';
        objCon.Address_Type__c = 'Pickup Location';
        //objCon.Is_Complete__c = true;
        //objCon.Name = 'INTEGRATION CONTACT'; 
        objCon.AccountId = objPro.Id;
        insert objCon ;
       Task_Assignment_Matrix__mdt lstCmd = [SELECT Label, Federation_Id__c FROM Task_Assignment_Matrix__mdt where Label ='BIR'];
       
       	User usr = [SELECT ID , FederationIdentifier FROM USER WHERE FederationIdentifier =: lstCmd.Federation_Id__c ];
       
        Id rtypeGen = Schema.SObjectType.task.getRecordTypeInfosByName().get('General').getRecordTypeId();
        task objTask4 = new task();
        objTask4.Subject = 'TEST HD';
        objTask4.Type__c = 'BIR';
       	objTask4.ActivityDate = Date.Today();
        objTask4.recordTypeId = rtypeGen;
        objTask4.Priority='High';
        objTask4.Status='Open';
        objTask4.WhatId = objPro.Id;
        objTask4.CurrencyIsoCode='INR';
        objtask4.Submitted_To__c = objCon.id ;
       	Test.StartTest();
        insert objTask4;
        Test.StopTest();
        Task tsk = [SELECT Id , ownerId FROM Task WHERE Id =: objTask4.Id];
        System.assertEquals(tsk.OwnerId , usr.id);
        
   
    }
}