@isTest
private class SafexpressChequeEmailInvokerTest {

    @TestSetup
    static void setupData() {
        User us = CommonDataTest.getUserBdm();
        insert us;
        System.runAs(us) {
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;

        

        contact con = CommonDataTest.getContact();
        insert con;
                
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;

        Id rIdClaimIssues = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Claim Issues').getRecordTypeId();

        // Case 1 — RTGS/NEFT, few waybills (<=5), has contact email
        Case__c c1 = CommonDataTest.getCase('Customer Technology/IT request');
        c1.Account__c              = objSfx.Id;
        c1.Assigned_To__c          = us.Id;
        c1.Remarks__c              = 'asdfghjklpoiuytrewqsddfghhjkkkkkk';
        c1.Status__c               = 'Active';
        c1.Requested_By__c         = 'Self Initiated';
        c1.Waybill_Numbers__c      = '1234567890';
        c1.RecordTypeId            = rIdClaimIssues;
        c1.Account_Holder_Name__c  = 'John Doe';
        c1.Task_Amount__c          = 100000;
        c1.Claim_Approved_Amount__c = 95000;
        c1.Claim_Settlement_Date__c = Date.today();
        c1.Account_Number__c       = '1234567890';
        c1.Bank_Branch_Name__c     = 'Main Branch';
        c1.IFSC_Code__c            = 'ABCD0123456';
        c1.Claim_Type__c           = 'RTGS/ NEFT';
        c1.Cheque_COF_No__c        = 'REF-001';
        c1.Contact__c              = con.Id;

        // Case 2 — COF, many waybills (>5), has contact email
        Case__c c2 = CommonDataTest.getCase('Customer Technology/IT request');
        c2.Account__c              = objPrc1.Id;
        c2.Assigned_To__c          = us.Id;
        c2.Remarks__c              = 'asdfghjklpoiuytrewqsddfghhjkkkkkk';
        c2.Status__c               = 'Active';
        c2.Requested_By__c         = 'Self Initiated';
        c2.Waybill_Numbers__c      = '1234567890';
        c2.RecordTypeId            = rIdClaimIssues;
        c2.Account_Holder_Name__c  = 'Jane Doe';
        c2.Claim_Approved_Amount__c = 25000;
        c2.Claim_Settlement_Date__c = Date.today();
        c2.Claim_Type__c           = 'COF';
        c2.Cheque_COF_No__c        = 'COF-002';
        c2.Contact__c              = con.Id;

        insert new List<Case__c>{ c1, c2 };
           // c2.Status__c = 'completed';
           // update  c2
        List<Waybill_Details__c> fewWaybills = new List<Waybill_Details__c>();
        for (Integer i = 0; i < 3; i++) {
            fewWaybills.add(new Waybill_Details__c(
                Name      = '1234567' + i,
                Case__c   = c1.Id,
                Amount__c = 100,
                Reason__c = 'Damage'
            ));
        }
        insert fewWaybills;

        List<Waybill_Details__c> manyWaybills = new List<Waybill_Details__c>();
        for (Integer i = 0; i < 7; i++) {
            manyWaybills.add(new Waybill_Details__c(
                Name      = '7654321' + i,
                Case__c   = c2.Id,
                Amount__c = 200,
                Reason__c = 'Loss'
            ));
        }
        insert manyWaybills;
            
            Case__c caserec = [SELECT Id,Status__c,Account__r.RecordType.DeveloperName, RecordType.DeveloperName,CreatedBy.Profile.Name FROM Case__c WHERE id=: c2.Id LIMIT 1];
            system.debug('case record'+caserec);

        }
    }

    @isTest
    static void testSendEmailFewWaybillsRTGS() {
        Case__c c = [SELECT Id FROM Case__c WHERE Claim_Type__c = 'RTGS/ NEFT' LIMIT 1];
        Test.startTest();
        SafexpressChequeEmailInvoker.sendEmail(c.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailManyWaybillsCOF() {
        Case__c c = [SELECT Id FROM Case__c WHERE Claim_Type__c = 'COF' AND Account_Holder_Name__c = 'Jane Doe' LIMIT 1];
        Test.startTest();
        SafexpressChequeEmailInvoker.sendEmail(c.Id);
        Test.stopTest();
    }

    @isTest
    static void testDuplicateEmailBlocked() {
        Case__c c = [SELECT Id, Name FROM Case__c WHERE Claim_Type__c = 'RTGS/ NEFT' LIMIT 1];
        insert new Task(
            WhatId  = c.Id,
            Subject = 'Settlement Email Sent — ' + c.Name,
            Status  = 'Completed',
            ValidationBypassDateTime__c = System.now()
        );

        Test.startTest();
        SafexpressChequeEmailInvoker.sendEmail(c.Id);
        Test.stopTest();
    }

    @isTest
    static void testInvocableMethod() {
        Case__c c = [SELECT Id FROM Case__c WHERE Claim_Type__c = 'RTGS/ NEFT' LIMIT 1];

        SafexpressChequeEmailInvoker.Request req = new SafexpressChequeEmailInvoker.Request();
        req.caseIds = c.Id;

        Test.startTest();
        SafexpressChequeEmailInvoker.sendChequeEmail(new List<SafexpressChequeEmailInvoker.Request>{ req });
        Test.stopTest();
    }
}