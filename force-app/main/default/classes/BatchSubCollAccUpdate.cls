global class BatchSubCollAccUpdate implements Database.Batchable<sObject> ,Schedulable{

    global void execute(SchedulableContext sc) {
        BatchSubCollAccUpdate bs = new BatchSubCollAccUpdate();
        database.executebatch(bs,10);
    }
    global String query='';
    global Id rId1 = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
    global Id rId2 = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        query = 'select id, Subject, WhatId, Account_Name__c from Task Where recordtypeid IN (:rId1, :rId2)';
        return Database.getQueryLocator(query);
    }

    
    global void execute(Database.BatchableContext BC, List<Task> TasksToUpdate){
        TriggerUtility.byPassTrigger = True;
        Map<Task, Id> mapTaskAcc = new Map<Task, Id>();
        Map<Id, String> mapInvAcc = new Map<Id, String>();
        for(Task tsk : TasksToUpdate){
            mapTaskAcc.put(tsk, tsk.WhatId);
        }
        for(Invoice__c inv : [SELECT Id,Account__c,Account__r.Parent.Name FROM Invoice__c WHERE Id IN : mapTaskAcc.values()]){
            mapInvAcc.put(inv.Id, inv.Account__r.Parent.Name);            
        }
        for (Task task : TasksToUpdate) {
            task.Account_Name__c= mapInvAcc.get(task.WhatId);
        }
        if(TasksToUpdate.size()>0)
            update TasksToUpdate;
    }
    
    global void finish(Database.BatchableContext BC){
    }
}