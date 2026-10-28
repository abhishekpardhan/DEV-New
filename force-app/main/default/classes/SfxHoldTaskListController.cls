public with sharing class SfxHoldTaskListController {

    public class FlowOutputs {

        @InvocableVariable(label='Task Records' description='List of Task records for the SFX account.')
        public List<Task> tasks;
    }

    @InvocableMethod(
        label='Get SFX Hold Tasks'
        description='Returns Account On Hold tasks for an SFX account for display in a Flow data table.'
        category='Task'
    )
    public static List<FlowOutputs> getHoldTasksForSfx(
        List<Id> sfxAccountIds
    ) {

        Set<Id> sfxIdSet = new Set<Id>(sfxAccountIds);

        List<Task> tasks = [
            SELECT Id,
                Subject__c,
                Status,
                Owner_Name__c,
                Account.Parent.Parent.ParentId,
                WhatId,
                TYPEOF What 
                    WHEN Account THEN Billing_Branch__c
                END     
            FROM Task
            WHERE Account.Parent.Parent.ParentId IN :sfxIdSet
            AND Subject LIKE :ConstantUtility.HOLD_TASK_SUBJECT_PREFIX.trim() + '%'
            ORDER BY CreatedDate DESC
        ];

        Map<String, List<Task>> groupedTasks = new Map<String, List<Task>>();
        for (Task t : tasks) {
            String billingBranch = '';
            if (t.What instanceof Account) {
                billingBranch = ((Account) t.What).Billing_Branch__c ?? '';
            }

            String groupKey = t.WhatId + '_' + billingBranch;

            if (!groupedTasks.containsKey(groupKey)) {
                groupedTasks.put(groupKey, new List<Task>());
            }
            groupedTasks.get(groupKey).add(t);
        }

        Map<String, String> latestWhatIdPerBranch = new Map<String, String>();

        for (Task t : tasks) {
            String billingBranch = '';
            if (t.What instanceof Account) {
                billingBranch = ((Account) t.What).Billing_Branch__c ?? '';
            }

            if (!latestWhatIdPerBranch.containsKey(billingBranch)) {
                latestWhatIdPerBranch.put(billingBranch, t.WhatId);
            }
        }

        List<Task> filteredTasks = new List<Task>();

        for (Task t : tasks) {
            String billingBranch = '';
            if (t.What instanceof Account) {
                billingBranch = ((Account) t.What).Billing_Branch__c ?? '';
            }

            String latestWhatId = latestWhatIdPerBranch.get(billingBranch);

            if (t.WhatId == latestWhatId) {
                filteredTasks.add(t);
            }
        }

        FlowOutputs output = new FlowOutputs();
        output.tasks = filteredTasks;

        return new List<FlowOutputs>{ output };
    }
}