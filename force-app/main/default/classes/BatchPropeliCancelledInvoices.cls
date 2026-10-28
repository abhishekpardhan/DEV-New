public with sharing class BatchPropeliCancelledInvoices implements
    Database.Batchable<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem>,
    Database.Stateful,
    Database.AllowsCallouts
{

    private final List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem> results;
    private Map<String, List<String>> exceptionMap = new Map<String, List<String>>();

    public BatchPropeliCancelledInvoices(List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem> results) {
        this.results = results;
    }

    public Iterable<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem> start(Database.BatchableContext bc) {
        return this.results;
    }

    public void execute(Database.BatchableContext bc, List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem> scope) {
        
        Set<Id> invoiceIds = new Set<Id>();
        List<Invoice__c> recordsToUpsert = new List<Invoice__c>();
		Map<Decimal, Invoice__c> invoiceMap = new Map<Decimal, Invoice__c>();

        try {
            for (PropeliCancelledInvoiceWrappers.CancelledInvoiceItem item : scope) {

                Invoice__c record = new Invoice__c();

                if(item.billId != null){
                    record.Propel_ID__c = Decimal.valueOf(item.billId);
                    record.Composite_Key__c = item.msaCode + ':' + item.billNumber;
                } else {
                    if(!exceptionMap.containsKey('Missing billId in API response billNumber Are These')) {
                        exceptionMap.put('Missing billId in API response billNumber Are These', new List<String>());
                    }
                    exceptionMap.get('Missing billId in API response billNumber Are These').add(String.valueOf(item.billNumber));
                    continue;
                }

                if(item.status != null && item.status != '' && item.status == 'CANCELLED') {
                    record.Status__c = item.status;
                } else {
                    if(!exceptionMap.containsKey('Invalid or missing status in API response billIds Are These')) {
                        exceptionMap.put('Invalid or missing status in API response billIds Are These', new List<String>());
                    }
                    exceptionMap.get('Invalid or missing status in API response billIds Are These')
                        .add(String.valueOf(item.billId) + ' with status: ' + String.valueOf(item.status));
                    continue;
                }

                record.Out_Total_Amount__c = item.outstandingAmount;

                if(String.isNotBlank(item.updatedDate) && item.updatedDate.contains('-')){
                    List<String> parts = item.updatedDate.split('-');
                    if(parts.size() == 3){
                        record.Bill_Last_Update_Date__c = Datetime.newInstance(
                            Integer.valueOf(parts[2]),
                            Integer.valueOf(parts[1]),
                            Integer.valueOf(parts[0]),
                            0,0,0
                        );
                    }
                } else {
                    if(!exceptionMap.containsKey('Invalid updatedDate format in API response billIds Are These')) {
                        exceptionMap.put('Invalid updatedDate format in API response billIds Are These', new List<String>());
                    }
                    exceptionMap.get('Invalid updatedDate format in API response billIds Are These')
                        .add(String.valueOf(item.updatedDate) + ' for billId: ' + item.billId);
                    continue;
                }
				invoiceMap.put(record.Propel_ID__c, record);
            }
            recordsToUpsert = invoiceMap.values();

            if (!recordsToUpsert.isEmpty()) {
                TriggerUtility.byPassTrigger = true;

                Database.UpsertResult[] results = Database.upsert(recordsToUpsert, Invoice__c.Composite_Key__c, false);

                for(Integer i = 0; i < results.size(); i++) {

                    Database.UpsertResult ur = results[i];
                    Invoice__c originalInvoice = recordsToUpsert[i];

                    if(ur.isSuccess()) {
                        invoiceIds.add(ur.getId());
                    } else {
                        for(Database.Error err : ur.getErrors()) {

                            if(!exceptionMap.containsKey(err.getMessage() + ' For Propel_ID__c: ')) {
                                exceptionMap.put(err.getMessage()+ ' For Propel_ID__c: ', new List<String>());
                            }
                            exceptionMap.get(err.getMessage() + ' For Propel_ID__c: ')
                            .add(String.valueOf(originalInvoice.Propel_ID__c));
                        }
                    }
                }
            }

            if(!invoiceIds.isEmpty()) {
                updateTask(invoiceIds);
            }

        } catch (Exception ex) {
            ExceptionHandling.Exception('BatchPropeliCancelledInvoices', 'execute', ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'BatchPropeliCancelledInvoices finished for window ' + this.results.size() + ' items');
        if(!exceptionMap.isEmpty()) {
            System.debug('exceptionMap >>' + exceptionMap);
            List<ExceptionHandler__c> expList = new List<ExceptionHandler__c>();

            for(String errorMsg : exceptionMap.keySet()) {
                ExceptionHandler__c exc = new ExceptionHandler__c();
                exc.Name = 'execute';
                exc.Class_Name__c = 'BatchPropeliCancelledInvoices';
                exc.Error_Message__c = errorMsg + ':-' +
                    String.join(exceptionMap.get(errorMsg), ',');

                expList.add(exc);
            }

            if(!expList.isEmpty()) {
                ExceptionHandling.Exceptions(expList);
            }
        }
    }

    @testVisible
    private static void updateTask(Set<Id> invoiceIds) {

        List<Task> taskListToUpdate = new List<Task>();
        try {
            for(Task tsk : [
                SELECT Id, Status, Subject, WhatId, Remarks__c
                FROM Task
                WHERE WhatId IN :invoiceIds
                AND RecordTypeId IN : new Set<Id>{invoiceTriggerHelper.subTaskRecordId, invoiceTriggerHelper.colTaskRecordId}
                AND Status != 'Cancelled'
            ]){
                if(tsk.Status != 'Completed') {
                    tsk.Status = 'Cancelled';
                    tsk.Subject = tsk.Subject + ' (Cancelled)';
                }
                tsk.ValidationBypassDateTime__c = System.now();
                if(tsk.Remarks__c == null || !tsk.Remarks__c.contains(ConstantUtility.CANCELLED_TASK_REMARKS)) {
                    tsk.Remarks__c = tsk.Remarks__c != null
                    ? tsk.Remarks__c + ' ' + ConstantUtility.CANCELLED_TASK_REMARKS
                    : ConstantUtility.CANCELLED_TASK_REMARKS;
                    taskListToUpdate.add(tsk);
                }
            }

            if(!taskListToUpdate.isEmpty()){

                Database.SaveResult[] results = Database.update(taskListToUpdate, false);

                List<ExceptionHandler__c> expList = new List<ExceptionHandler__c>();
                for (Database.SaveResult ur : results) {
                    if (!ur.isSuccess()) {
                        for (Database.Error err : ur.getErrors()) {
                            ExceptionHandler__c exc = new ExceptionHandler__c();
                            exc.Name = 'updateTask';
                            exc.Class_Name__c = 'BatchPropeliCancelledInvoices';
                            exc.Error_Message__c = err.getMessage() + ' for Task ID: ' + ur.getId();
                            expList.add(exc);
                        }
                    }
                }

                if(!expList.isEmpty()) {
                    ExceptionHandling.Exceptions(expList);
                }
            }
        } catch (Exception ex) {
            ExceptionHandling.Exception('BatchPropeliCancelledInvoices', 'updateTask', ex.getMessage());
        }
    }
}