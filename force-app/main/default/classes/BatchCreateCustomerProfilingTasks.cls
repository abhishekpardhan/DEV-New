global class BatchCreateCustomerProfilingTasks implements Database.Batchable<SObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, 
                   MSA_Master_Service_Agreement__c,
                   Customer_Account_SFX_codes__c,
                   Booking_branch__c,
                   Customer_Category__c,
                   CustomeProfilingTaskNextCreationDate__c,
            	   WhatId,Account_Name__c,OwnerId,SFX_Code__c
            FROM Task
            WHERE RecordType.DeveloperName = 'Customer_Relationship_Profiling_Tasks'
              AND CustomeProfilingTaskNextCreationDate__c = :Date.today()
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Task> taskList) {
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
            .get('Customer_Relationship_Profiling_Tasks').getRecordTypeId();

        // Load metadata for frequency
        Map<String, Decimal> categoryToFrequencyMap = new Map<String, Decimal>();
        for (CustomerRelationshipProfilingFrequency__mdt mdt : [
            SELECT Customer_Category__c, Frequency_In_days__c 
            FROM CustomerRelationshipProfilingFrequency__mdt
        ]) {
            categoryToFrequencyMap.put(mdt.Customer_Category__c, mdt.Frequency_In_days__c);
        }
        
        Set<Id> accountIds = new Set<Id>();
        for (Task t : taskList) {
            if (t.WhatId != null) {
                accountIds.add(t.WhatId);
            }
        }
        
        // Query existing open tasks on these invoices
        Map<String, Task> openTasksMap = new Map<String, Task>();
        for (Task t : [
            SELECT Id, WhatId, ActivityDate, Booking_branch__c, Customer_Account_SFX_codes__c
            FROM Task
            WHERE WhatId IN :accountIds
            AND Status != 'Completed'
            AND RecordType.DeveloperName = 'Customer_Relationship_Profiling_Tasks'
        ]) {
            String key = t.Booking_branch__c + t.Customer_Account_SFX_codes__c;
            openTasksMap.put(key, t); // Only one open task per Invoice assumed
        }

        List<Task> newTasks = new List<Task>();

        for (Task task : taskList) {
            String key = task.Booking_branch__c + task.Customer_Account_SFX_codes__c;
            if (!openTasksMap.containsKey(key)) {
                Task ts = new Task();
                ts.MSA_Master_Service_Agreement__c = task.MSA_Master_Service_Agreement__c;
                ts.Customer_Account_SFX_codes__c = task.Customer_Account_SFX_codes__c;
                ts.Booking_branch__c = task.Booking_branch__c;
                ts.Customer_Category__c = task.Customer_Category__c;
                if (categoryToFrequencyMap.containsKey(task.Customer_Category__c)) {
                    Decimal frequencyDaysDecimal = categoryToFrequencyMap.get(task.Customer_Category__c);
                    Integer frequencyDays = frequencyDaysDecimal != null ? frequencyDaysDecimal.intValue() : 0;
                    ts.CustomeProfilingTaskNextCreationDate__c = Date.today().addDays(frequencyDays);
                }
                ts.Status = 'Open';
                ts.Subject = 'Customer Relationship Profiling Task';
                ts.ActivityDate = Date.today().addDays(3); 
                ts.WhatId = task.WhatId;
                ts.Account_Name__c = task.Account_Name__c;
                ts.OwnerId = task.OwnerId; 
                ts.Priority = 'High';
                ts.SFX_Code__c = task.SFX_Code__c; 
                ts.RecordTypeId = recordTypeId;
                newTasks.add(ts);
            }
        }

        if (!newTasks.isEmpty()) {
            insert newTasks;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: logging or notification
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCreateCustomerProfilingTasks(), 200);
    }
}