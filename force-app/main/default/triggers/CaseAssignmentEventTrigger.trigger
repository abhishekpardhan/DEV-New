trigger CaseAssignmentEventTrigger on Case_Assignment_Event__e (after insert) {
    Set<Id> caseIds = new Set<Id>();

    for (Case_Assignment_Event__e event : Trigger.new) {
        System.debug('Details updated successfully! Case : '+(Id)event.Case_Id__c);
        if (event.Case_Id__c != null) {
            caseIds.add((Id)event.Case_Id__c);
        }
    }

    if (!caseIds.isEmpty()) {
        System.enqueueJob(new AssignToApproverJob(new List<Id>(caseIds)));
    }
}