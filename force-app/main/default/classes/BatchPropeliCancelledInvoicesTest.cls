@IsTest
private class BatchPropeliCancelledInvoicesTest {

    @TestSetup
    static void setupData() {
        // Create Invoice record (existing record for update scenario)
        Invoice__c inv = CommonDataTest.getInvoice();
        inv.Composite_Key__c = 'msa12345:BILL-001';
        insert inv;

        // Create Tasks related to Invoice
        Task t1 = CommonDataTest.getSubmisionTask();
        t1.WhatId = inv.Id;
        insert t1;
    }

    @IsTest
    static void testBatchSuccessScenario() {

        // Fetch existing invoice
        Invoice__c existingInv = [SELECT Id, Propel_ID__c FROM Invoice__c LIMIT 1];

        // Create wrapper data
        PropeliCancelledInvoiceWrappers.CancelledInvoiceItem item =
            new PropeliCancelledInvoiceWrappers.CancelledInvoiceItem();
        PropeliCancelledInvoiceWrappers.CancelledInvoiceItem item2 =
            new PropeliCancelledInvoiceWrappers.CancelledInvoiceItem();
        PropeliCancelledInvoiceWrappers.CancelledInvoiceItem item3 =
            new PropeliCancelledInvoiceWrappers.CancelledInvoiceItem();
        PropeliCancelledInvoiceWrappers.CancelledInvoiceItem item4 =
            new PropeliCancelledInvoiceWrappers.CancelledInvoiceItem();

        item.billNumber = 'BILL-001';
        item.status = 'Cancelled';
        item.sfRecordId = existingInv.Id;
        item.updatedDate = '01-01-2024';
        item.billId = '12345';
        item.msaCode = 'msa12345';

        
        item4.billNumber = 'BILL-001';
        item4.status = 'Cancelled';
        item4.sfRecordId = existingInv.Id;
        item4.updatedDate = '01-01-2024';
        item4.billId = null;
        item.msaCode = 'msa12346';

        
        item2.billNumber = 'BILL-001';
        item2.status = 'Active';
        item2.sfRecordId = existingInv.Id;
        item2.updatedDate = '01-01-2024';
        item2.billId = '12346';
        item.msaCode = 'msa12347';

        
        item3.billNumber = 'BILL-001';
        item3.status = 'Cancelled';
        item3.sfRecordId = existingInv.Id;
        item3.updatedDate = '01/01/2024';
        item3.billId = '12347';
        item.msaCode = 'msa12348';


        List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem> wrapperList =
            new List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem>{ item,item3,item2,item4 };

        Test.startTest();
        Database.executeBatch(new BatchPropeliCancelledInvoices(wrapperList), 10);
        BatchPropeliCancelledInvoices.updateTask(new Set<Id>{existingInv.Id});
        Test.stopTest();

        // Assert Invoice Updated
        Invoice__c updatedInv = [
            SELECT Status__c, Bill_Last_Update_Date__c
            FROM Invoice__c
            WHERE Id = :existingInv.Id
        ];
    }

    @IsTest
    static void testBatchInsertScenario() {

        // New wrapper record (Insert case)
        PropeliCancelledInvoiceWrappers.CancelledInvoiceItem item =
            new PropeliCancelledInvoiceWrappers.CancelledInvoiceItem();

        item.billNumber = 'BILL-NEW';
        item.status = 'Cancelled';
        item.updatedDate = '05-01-2024';
        item.billId = '99999';
        item.msaCode = 'msa12341';

        item.sfRecordId = null;

        List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem> wrapperList =
            new List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem>{ item };

        Test.startTest();
        Database.executeBatch(new BatchPropeliCancelledInvoices(wrapperList), 1);
        Test.stopTest();

    }
}