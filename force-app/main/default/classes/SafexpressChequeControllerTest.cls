@isTest
private class SafexpressChequeControllerTest {

    @TestSetup
    static void setupData() {
        Document doc = new Document(
            Name = 'SafexpressBlankCheque',
            Body = Blob.valueOf('dummy image content'),
            FolderId = UserInfo.getUserId(),
            ContentType = 'image/png',
            Type = 'png'
        );
        insert doc;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        //objSfx.Propel_MSACode__c = 'MSA00000002';
        insert objSfx;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Id rIdClaimIssues = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Claim Issues').getRecordTypeId();
		
        Case__c objCase2 = CommonDataTest.getCase('Customer Technology/IT request');
        objCase2.Account__c  = objSfx.Id;
        objCase2.Assigned_To__c = us.Id;
        objCase2.Remarks__c = 'asdfghjklpoiuytrewqsddfghhjkkkkkk';
        objCase2.Status__c='Active';
        objCase2.Requested_By__c ='Self Initiated';
        objCase2.Waybill_Numbers__c = '1234567890'; 
        objCase2.RecordTypeId = rIdClaimIssues;
        objCase2.Account_Holder_Name__c   = 'John Doe';
        objCase2.Task_Amount__c           = 100000;
        objCase2.Claim_Approved_Amount__c = 95000;
        objCase2.Account_Number__c        = '1234567890';
        objCase2.Bank_Branch_Name__c      = 'Main Branch';
        objCase2.IFSC_Code__c             = 'ABCD0123456';
        objCase2.Claim_Type__c            = 'COF';
        objCase2.Cheque_COF_No__c         = 'COF-001';
        insert objCase2;

        Waybill_Details__c wD = new Waybill_Details__c();
        wD.Name ='12345678';
        wD.Amount__c = 300;
        wD.Case__c =objCase2.Id;
        insert wD;
        
    }

    @isTest
    static void testMissingCaseId() {
        Test.setCurrentPage(Page.SafexpressChequeEmail);
        Test.startTest();
        SafexpressChequeController ctrl = new SafexpressChequeController();
        ctrl.getIsCOF();
        ctrl.getIsRTGSOrNEFT();
        ctrl.getDisplayName();
        ctrl.getAccountNumber();
        ctrl.getBankBranchName();
        ctrl.getSrNo();
        ctrl.getShowWaybills();
        ctrl.getWaybillCSV();
        Test.stopTest();
    }

    @isTest
    static void testWithCaseIdAndParams() {
        Case__c c = [SELECT Id FROM Case__c LIMIT 1];

        Test.setCurrentPageReference(new PageReference('/apex/SafexpressChequeEmail'));
        ApexPages.currentPage().getParameters().put('id', c.Id);
        ApexPages.currentPage().getParameters().put('poc', 'true');
        ApexPages.currentPage().getParameters().put('settlementDate', '2026-07-06');
        ApexPages.currentPage().getParameters().put('chequeCOFNo', 'COF-999');
        ApexPages.currentPage().getParameters().put('amountInWords', 'Test Amount Words');
        ApexPages.currentPage().getParameters().put('displayAmount', '95,000');
        ApexPages.currentPage().getParameters().put('showWaybills', 'false');
        ApexPages.currentPage().getParameters().put('waybillCSV', 'WB1,WB2');

        Test.startTest();
        SafexpressChequeController ctrl = new SafexpressChequeController();
        ctrl.getIsCOF();
        ctrl.getIsRTGSOrNEFT();
        ctrl.getDisplayName();
        ctrl.getAccountNumber();
        ctrl.getBankBranchName();
        ctrl.getSrNo();
        ctrl.getShowWaybills();
        ctrl.getWaybillCSV();
        SafexpressChequeController.isRTGSOrNEFT();
        Test.stopTest();
    }

    @isTest
    static void testStaticFormatters() {
        SafexpressChequeController.formatIndianCurrencyLong(959924L);
        SafexpressChequeController.formatIndianCurrencyLong(-500L);
        SafexpressChequeController.formatIndianCurrencyLong(null);
        SafexpressChequeController.formatIndianCurrency(1234567.89);
        SafexpressChequeController.formatIndianCurrency(null);
        SafexpressChequeController.formatIndianCurrency(-1234.5);
        SafexpressChequeController.convertToIndianWords(0L);
        SafexpressChequeController.convertToIndianWords(123456789L);
        SafexpressChequeController.convertAmountToIndianWords(1234.56);
        SafexpressChequeController.convertAmountToIndianWords(null);
        SafexpressChequeController.convertAmountToIndianWords(0);
    }
}