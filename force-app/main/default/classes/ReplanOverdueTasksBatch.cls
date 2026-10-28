public class ReplanOverdueTasksBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    private Map<String, List<String>> exceptionMap = new Map<String, List<String>>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status, Remaining_Payment_Tentative_Date__c
            FROM Task
            WHERE Status IN ('Open', 'In Progress', 'Replanned')
              AND Remaining_Payment_Tentative_Date__c = TODAY AND RecordType.Id =: ConstantUtility.TASK_COLLECTION_RECORDTYPE_ID
        ]);
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ReplanOverdueTasksBatch(), 2000);
    }

    public void execute(Database.BatchableContext bc, List<Task> scope) {
        for (Task t : scope) {
            t.Status = 'Reopen';
            t.Is_Replanned__c = true;
        }

        Database.SaveResult[] results = Database.update(scope, false);

        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results[i];
            Task originalTask = scope[i];

            if (!sr.isSuccess()){
                for (Database.Error err : sr.getErrors()) {
                    String key = err.getMessage() + ' For Task Id: ';

                    if (!exceptionMap.containsKey(key)) {
                        exceptionMap.put(key, new List<String>());
                    }
                    exceptionMap.get(key).add(String.valueOf(originalTask.Id));
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!exceptionMap.isEmpty()) {
            List<ExceptionHandler__c> expList = new List<ExceptionHandler__c>();

            for (String errorMsg : exceptionMap.keySet()) {
                ExceptionHandler__c exc = new ExceptionHandler__c();
                exc.Name = 'execute';
                exc.Class_Name__c = 'ReplanOverdueTasksBatch';
                exc.Error_Message__c = errorMsg + ':-' +
                    String.join(exceptionMap.get(errorMsg), ',');

                expList.add(exc);
            }

            if (!expList.isEmpty()) {
                ExceptionHandling.Exceptions(expList);
            }
        }
    }
}