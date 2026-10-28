/**
* Description      :   Trigger on Task object to perform various tasks upon different DML Operations by calling helper class methods
* 
* 
* Revision Logs    :   V_1.0 - Created
* 
**/
trigger trg_task on Task (after update, after insert ,before Update,before Insert,after delete) {
    
     // bypass trigger
    if(TriggerUtility.byPassTrigger) return ;
    //Checking Trigger Switch Values
    if(System.Label.TriggerSwitch.equals('On')){
        List<Task> lstTask = new List<Task>();
        List<Task> lstCreateCase = new List<Task>();
        List<Task> debitCreditTaskList = new List<Task>();
        List<Task> lstForceUpdateAccount = new List<Task>();
        List<Task> lstForceUpdNewAccount = new List<Task>();
        List<Task> lstNewTaskCU = new List<Task>();
        List<Task> lstEmailTask = new List<Task>();
        List<Task> lstTaskUpd = new List<Task>();
        List<Task> lstTaskPaymentUpd = new List<Task>();
        List<Task> lstTaskPartlyUpdate = new List<Task>();
        List<Task> lstTaskPaymentUpdPartly = new List<Task>();
        List<Task> onboardingIdList = new List<Task>();
        List<Task> onboardingStatusList = new List<Task>();
        List<Task> cmdtaskTypeUpdate = new List<Task>();
        List<Task> cmdtaskType = new List<Task>();
        
        List<Id> lstInvoiceId = new List<Id>();
        List<Id> lstInvId = new List<Id>();
        List<Id> lstInvoiceIdPartly = new List<Id>();
        List<Task> subTskIdList = new List<Task>(); //referring - https://safexpress.atlassian.net/browse/SAC-89 // added by adarsh
        List<String> onboardingJouName = new List<String>();
        
        Set<Id> ownGroupId = new Set<Id>(); 
        Set<Id> contactId = new Set<Id>();
        Set<Id> subInvoiceIdSet = new Set<Id>(); 
        Set<Id> invoiceIdOfTask = new Set<Id>();
        Set<Id> invoiceIdOfTask1 = new Set<Id>();
        Set<Id> accountIdOfTask = new Set<Id>();
        
        //Getting record types Ids
        Id rtypeSub = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
        Id rtypeCol = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        Id rtypeGen = Schema.SObjectType.task.getRecordTypeInfosByName().get('General').getRecordTypeId();
        Id rtypeOnBoard = Schema.SObjectType.task.getRecordTypeInfosByName().get('On Boarding').getRecordTypeId();
        Id rtypCustomerProfilingTask = Schema.SObjectType.task.getRecordTypeInfosByName().get('Customer Relationship Profiling').getRecordTypeId();
        
        if(trigger.isUpdate && trigger.isAfter){    
            try{
                for(Task taskObj: Trigger.new){
                    if(taskObj.Payment_Remaining__c != trigger.oldmap.get(taskObj.Id).Payment_Remaining__c && taskObj.Payment_Remaining__c == 'Recoverable'){
                        /*if(taskObj.Collectable_Amount__c == trigger.oldMap.get(taskObj.id).Collectable_Amount__c){
                            taskObj.Collectable_Amount__c.addError('Please enter new Collectable Amount');
                        }*/
                    }
                    if(taskObj.WhatId != null){
                        String sObjName = taskObj.WhatId.getSObjectType().getDescribe().getName();
                        //Check if Task is of Invoice of Submission Type and Status is Completed.
                        if((sObjName.equals('Invoice__c') || sObjName.equals('Debit_Credit_Note__c')) && taskObj.RecordTypeId == rtypeSub  && taskObj.Status.equals('Completed')
                           && taskObj.Status != trigger.oldMap.get(taskObj.Id).Status){
                            if(sObjName.equals('Debit_Credit_Note__c')){
                                debitCreditTaskList.add(taskObj);
                            } else {
                                lstTask.add(taskObj);
                            }
                           }
                        
                        //Check if Task is of Invoice of Collection-type and Payment updated as Non-recoverable.
                        if(sObjName.equals('Invoice__c') && taskObj.RecordTypeId == rtypeCol && !String.isBlank(taskObj.Payment_Remaining__c) && 
                           taskObj.Payment_Remaining__c.equals('Non-Recoverable') && taskObj.Payment_Remaining__c != trigger.oldMap.get(taskObj.Id).Payment_Remaining__c){                                
                               lstCreateCase.add(taskObj);
                               lstInvId.add(taskObj.WhatId);
                           }
                        
                        //Check if Task is of an Account and Contact not updated from last 90days.
                        if(sObjName.equals('Account') && taskObj.RecordTypeId == rtypeGen){                                
                            lstForceUpdateAccount.add(taskObj);
                        }
                    }
                    //check if Task is Submission Recordtype and status is change to completed.
                    if(taskObj.RecordTypeId == rtypeSub && !String.isBlank(taskObj.Submitted_To__c) && trigger.oldMap.get(taskObj.Id).status != taskObj.status && taskObj.status == 'Completed'){
                        lstEmailTask.add(taskObj);
                        subTskIdList.add(taskObj); //Added by adarsh //referring - https://safexpress.atlassian.net/browse/SAC-132
                        contactId.add(taskObj.Submitted_To__c);
                        
                        // To update Submission Tasks in PropelI
                        if(!lstEmailTask.isEmpty()) {
                           // TasksCompAPI.taskFromSF(); // commented by adarsh, not call propel api for sending submission date //referring - https://safexpress.atlassian.net/browse/SAC-132
                        }
                    }
                }
                //To create collection task from submission.
                if(!lstTask.isEmpty()){
                    TaskTriggerHelper.updateTask(lstTask);
                }

                if(!debitCreditTaskList.isEmpty()){
                    TaskTriggerHelper.createCollectionTask(debitCreditTaskList);
                }
                //To sending submission date to propeli.
                if(!subTskIdList.isEmpty()){  //Added by adarsh from line 83-85 //referring - https://safexpress.atlassian.net/browse/SAC-132
                    System.enqueueJob(new cls_BillingSubmissionRequest(subTskIdList));
                }
                //To create claim case from collection task.
                if(!lstCreateCase.isEmpty()){
                   // TaskTriggerHelper.createCase(lstCreateCase, lstInvId);
                }
                //To stop updating the task if contact not updated from last 90 days.
                if(!lstForceUpdateAccount.isEmpty()){
                    TaskTriggerHelper.checkAccContacts(lstForceUpdateAccount);
                }
                
            }catch(Exception e){
               System.debug('Exception:'+e.getMessage());
               ExceptionHandling.Exception('afterUpdate', 'trg_task', e);
                
            }
        }
        
        /* Trigger on After Insert */
        if(trigger.isInsert && trigger.isAfter){
            try{
                List<Task> listToBeupdated = new List<task>();
                List<Task> listTaskToUpdateTaskCreatedAccTeam = new List<task>();
                for(Task t: Trigger.new){
                    if(t.WhatId != null){
                        String sObjName = t.WhatId.getSObjectType().getDescribe().getName();
                        //Check if Task if of account and show error if Contact not updated from last 90 days.
                        if(sObjName.equals('Account')){
                            lstForceUpdNewAccount.add(t);
                        }
                        //Check if task of Submission and Collection already created and not allow to create more.
                        if(sObjName.equals('Invoice__c') && (t.RecordTypeId == rtypeSub || t.RecordTypeId == rtypeCol)){
                            lstNewTaskCU.add(t);
                            lstInvoiceId.add(t.WhatId);
                        }
                        //Checked is submission created checkbox on invoice.
                        if(sObjName.equals('Invoice__c') && (t.RecordTypeId == rtypeSub)){
                            subInvoiceIdSet.add(t.WhatId);
                        }
                    }
                    
                    // changes for JIRA #1832

                    if(rtypCustomerProfilingTask == t.RecordTypeId && t.status != 'Completed'){
                        listTaskToUpdateTaskCreatedAccTeam.add(t);
                    }
                    
                }
                
                // Method is used to check related account team member and update the Task Created checkbox.
                if(!listTaskToUpdateTaskCreatedAccTeam.isEmpty()){
                    taskTriggerHelper.updateTaskCreatedAccTeam(listTaskToUpdateTaskCreatedAccTeam,False);
                }
                
                //Method to check if contact related to account is not updated past 90 days and show error on task update
                if(!lstForceUpdNewAccount.isEmpty()){
                    taskTriggerHelper.checkAccContacts(lstForceUpdNewAccount);
                }
                //Method to check task of invoice type of collection and submission to 1 only.
                if(!lstNewTaskCU.isEmpty()){
                    taskTriggerHelper.checkTaskInvoiceIns(lstNewTaskCU,lstInvoiceId);
                }
                //Method to check submission invoice created or not.
                if(!subInvoiceIdSet.isEmpty()){
                    taskTriggerHelper.updateInvoiceForSubmissionTask(subInvoiceIdSet);
                }
            }catch(Exception e){
                System.debug('Exception:'+e.getMessage());
                ExceptionHandling.Exception('afterInsert', 'trg_task', e);
                
            }
        }
        if(trigger.isBefore){
            
            // inactive contact should not whatid
            List<String> contactIds = new List<String>();
            String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
            for(Task t: Trigger.new){ 
                if((t.RecordTypeId == rtypeGen && !profileName.contains('Service Cloud')) ||t.RecordTypeId == rtypeSub){
                    Id recwhatId;
                    Id recwhoId;
                    String whatobjName;
                    String whoobjName;
                  
                     // Example Account Id
                    // changed by sahil jain  wrong logic  
                  if (t.WhoId != null && t.WhoId.getSObjectType() == Contact.SObjectType) {
                      contactIds.add(String.valueOf(t.WhoId));
                     }  
                }
            }
            if(contactIds.size() > 0){
                Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Is_Active__c, Is_Complete__c FROM Contact WHERE Id IN : contactIds AND (Is_Active__c = false OR Is_Complete__c = false)]);
                for(Task t: Trigger.new){
                    if(contactMap.containsKey(t.WhatId) || contactMap.containsKey(t.WhoId)){
                        t.addError('The contact you are trying to tag is either inactive or incomplete');
                    }
                }
            }
            if(trigger.isInsert){
                TaskTriggerHelper.updateTaskAutomation(trigger.new); //SAC-1457
                lstTask = new List<task>();
                List<Task> aloneTask = new List<Task>(); // alonetask list 
                for(task taskObj: trigger.new){
                    String sObjName1;
                     if (taskObj.WhatId != null ||
                        (taskObj.WhoId != null && taskObj.WhoId.getSObjectType() == Lead.SObjectType)) {
                    
                        if (taskObj.WhatId != null) {
                            sObjName1 = taskObj.WhatId.getSObjectType().getDescribe().getName();
                    
                            if (sObjName1.equals('Invoice__c')) {
                                invoiceIdOfTask1.add(taskObj.WhatId);
                            }
                            if (sObjName1.equals('Account')) {
                                accountIdOfTask.add(taskObj.WhatId);
                            }
                        }
                    } else {
                        taskObj.addError('Please select Related to for task');
                    }
                    if(taskObj.Initiated_by__c == null) {
                    	taskObj.Initiated_by__c = UserInfo.getUserId();
                    }
                    if (taskObj.RecordTypeId == rtypeCol && taskObj.Outstanding_Amount__c!= null) {
                        taskObj.Collectable_Amount__c = taskObj.Outstanding_Amount__c;
                    }
                    if(taskObj.WhatId != null && taskObj.RecordTypeId == rtypeCol){
                        String sObjName = taskObj.WhatId.getSObjectType().getDescribe().getName();
                        if(sObjName.equals('Invoice__c')){
                            invoiceIdOfTask.add(taskObj.WhatId);
                        }
                    }
                    
                    if(taskObj.type__c != Null && taskObj.RecordTypeId == rtypeGen){
                        cmdtaskType.add(taskObj);
                        
                    }
                    if(taskObj.RecordTypeId == rtypeSub){
                        if(taskObj.recordTypeId == rtypeSub && taskObj.status == 'Completed'){
                            lstTask.add(taskObj);
                        }
                    }
                    if(taskObj.recordTypeId == rtypeGen && String.isBlank(taskObj.Submitted_To__c) && String.isBlank(taskObj.whoId) && String.isBlank(taskObj.whatId)){
                        aloneTask.add(taskObj);
                    }
                }
                Map<Id, String> invoiceIdToCustomer = new Map<Id, String>();
                
                if (!invoiceIdOfTask1.isEmpty()) {
                    for (Invoice__c inv : [
                        SELECT Id, Account__r.Customer_Category__c
                        FROM Invoice__c
                        WHERE Id IN :invoiceIdOfTask1
                    ]) {
                        if (inv.Account__r.Customer_Category__c != null) {
                            invoiceIdToCustomer.put(inv.Id, inv.Account__r.Customer_Category__c);
                        }
                    }
                }
                Map<Id, String> accountIdToCustomer = new Map<Id, String>();
                if (!accountIdOfTask.isEmpty()) {
                    for (Account acc : [
                        SELECT Id, Customer_Category__c
                        FROM Account
                        WHERE Id IN :accountIdOfTask
                    ]) {
                        if (acc.Customer_Category__c != null) {
                            accountIdToCustomer.put(acc.Id, acc.Customer_Category__c);
                        }
                    }
                }
                for (Task t : Trigger.new) {
                    if (!invoiceIdOfTask.isEmpty() && invoiceIdToCustomer.containsKey(t.WhatId)) {
                        t.Customer_Category__c = invoiceIdToCustomer.get(t.WhatId);
                    }
                    if (!accountIdToCustomer.isEmpty() && accountIdToCustomer.containsKey(t.WhatId)) {
                        t.Customer_Category__c = accountIdToCustomer.get(t.WhatId);
                    }
                }
                if(cmdtaskType.size() > 0){
                    taskTriggerHelper.setAssignerToField(cmdtaskType);
                    
                }
                if(aloneTask.size() > 0){
                    taskTriggerHelper.relateTask(aloneTask);
                }
            }
            if(trigger.isUpdate){
                TaskTriggerHelper.updateTaskDetails(trigger.new,trigger.oldMap); //SAC-1457
                lstTask = new List<task>();
                List<Task> reopenTaskList = new List<Task>();
                for(task t: trigger.new){
                    
                    
                    // Added By KR SANSI, IBM, SAC-1157
                    if(t.Outstanding_Amount__c != trigger.oldMap.get(t.id).Outstanding_Amount__c && 
                       t.RecordTypeId == rtypeCol){
                        t.Status = 'Reopen';
                    }
                    if (t.RecordTypeId == rtypeCol && t.Collectable_Amount__c != trigger.oldMap.get(t.id).Collectable_Amount__c && t.Collectable_Amount__c > t.Outstanding_Amount__c) {
                        t.addError('Collectable Amount shall be equal to or less than the Propel Outstanding Amount');
                    }
                    if(t.Outstanding_Amount__c != trigger.oldMap.get(t.id).Outstanding_Amount__c && t.Outstanding_Amount__c == 0 &&
                       t.RecordTypeId == rtypeCol){
                        t.Status = 'Completed';
                    }
                    if(t.Case__c !=null && t.RecordTypeId == rtypeCol && (t.Payment_Remaining__c == 'Non-Recoverable' || t.Payment_Remaining__c == 'Partly Recoverable / Non Recoverable')){
                        t.Outstanding_Amount__c = 0;
                        t.Status = 'Completed';
                    }
                    // Added By KR SANSI, IBM, SAC-1157
                    if(t.Remaining_Payment_Tentative_Date__c != trigger.oldMap.get(t.id).Remaining_Payment_Tentative_Date__c && t.Remaining_Payment_Tentative_Date__c >= Date.Today() &&
                       t.RecordTypeId == rtypeCol){
                        t.Status = 'In Progress';
                    }
                    
                    
                     if(t.type__c != trigger.oldMap.get(t.id).type__c && t.RecordTypeId == rtypeGen){
                        cmdtaskTypeUpdate.add(t);
                        
                    }
                    
                    if(t.RecordTypeId == rtypeSub){
                        if(t.recordTypeId == rtypeSub && trigger.oldMap.get(t.Id).status != t.status && t.status == 'Completed'){
                            lstTask.add(t);
                        }
                        //Below condition to check if comments added and then update that into other read only field.
                        if(!String.isBlank(t.Comments_Added__c) && String.isBlank(trigger.oldMap.get(t.Id).Comments_Added__c)){
                            lstTaskUpd.add(t);
                        }
                    }
                    //To update the payment collection details on collection task.
                    else if(t.RecordTypeId == rtypeCol){
                        if(t.Payment_Remaining__c != trigger.oldmap.get(t.Id).Payment_Remaining__c && !String.isBlank(t.Payment_Remaining__c)){
                            lstTaskPaymentUpd.add(t);
                        }
                        //If partly recoverable amount update on task of partly recoverable/non-recoverable.
                        else if(t.Payment_Remaining__c == trigger.oldmap.get(t.Id).Payment_Remaining__c && t.Payment_Remaining__c == 'Partly Recoverable / Non Recoverable'
                                && t.Partly_Recoverable_Amount__c < trigger.oldmap.get(t.Id).Partly_Recoverable_Amount__c){                                
                                    
                                    t.Total_Credit_Note_Amount__c += trigger.oldmap.get(t.Id).Partly_Recoverable_Amount__c - t.Partly_Recoverable_Amount__c;
                                    t.Partly_Non_Recoverable_Amount__c += trigger.oldmap.get(t.Id).Partly_Recoverable_Amount__c - t.Partly_Recoverable_Amount__c;
                                    t.Recoverable_Amount__c = t.Partly_Recoverable_Amount__c;
                                    t.Non_Recoverable_Amount__c = trigger.oldmap.get(t.Id).Partly_Recoverable_Amount__c - t.Partly_Recoverable_Amount__c;
                                    lstTaskPartlyUpdate.add(t);
                                    lstInvoiceIdPartly.add(t.WhatId);
                                    
                                }
                        else if(t.Payment_Remaining__c == trigger.oldmap.get(t.Id).Payment_Remaining__c && t.Payment_Remaining__c == 'Partly Recoverable / Non Recoverable'
                                && t.Partly_Recoverable_Amount__c > trigger.oldmap.get(t.Id).Partly_Recoverable_Amount__c){
                                    if(t.Collected_Amount__c != null && (t.Partly_Recoverable_Amount__c + t.Collected_Amount__c) > t.Outstanding_Amount__c){
                                        t.addError('Collected /Partly Recoverable Amount cannot be greater or equal to Outstanding amount.');
                                    }
                                    else if(t.Partly_Recoverable_Amount__c > t.Outstanding_Amount__c){
                                        t.addError('Partly Recoverable Amount cannot be greater or equal to Outstanding amount.');
                                    }
                                }
                        else if(t.Payment_Remaining__c == trigger.oldmap.get(t.Id).Payment_Remaining__c && t.Payment_Remaining__c == 'Partly Recoverable / Non Recoverable'
                                && t.Collected_Amount__c > trigger.oldmap.get(t.Id).Collected_Amount__c){
                                    lstTaskPaymentUpdPartly.add(t);
                                }
                    }
                    //check onboarding status---added by adarsh
                    if(t.RecordTypeId == rtypeOnBoard){
                        if(trigger.oldMap.get(t.Id).status != t.status && t.status == 'Completed'){
                        	onboardingStatusList.add(t);    
                        }
                    }

                    if(t.Status != trigger.oldMap.get(t.id).Status && trigger.oldMap.get(t.id).Status == 'Completed'){
                        reopenTaskList.add(t);
                    }
                }

                if(!reopenTaskList.isEmpty()){
                    taskTriggerHelper.updateReopenTask(reopenTaskList);
                }
            }
            if(cmdtaskTypeUpdate.size()>0){
                  TaskTriggerHelper.setAssignerToField(cmdtaskTypeUpdate);

            }
            if(lstTask.size() > 0){
                taskTriggerHelper.updateSubmitDate(lstTask);
            }
            //Method to update comments on submission task read only field.
            if(!lstTaskUpd.isEmpty()){
                taskTriggerHelper.updateSubmissionComments(lstTaskUpd);
            }
            if(!lstTaskPaymentUpd.isEmpty()){
                taskTriggerHelper.updatePaymentDetails(lstTaskPaymentUpd, trigger.oldmap);
            }
            if(!lstTaskPartlyUpdate.isEmpty()){
              //  taskTriggerHelper.createCase(lstTaskPartlyUpdate,lstInvoiceIdPartly);
            }
            if(!lstTaskPaymentUpdPartly.isEmpty()){
                //If collected amount update on task of partly recoverable/non-recoverable.
                taskTriggerHelper.updateCollectedAmount(lstTaskPaymentUpdPartly,trigger.oldmap);
            }
            if(onboardingStatusList.size()>0){
                taskTriggerHelper.onboaStatusTask(onboardingStatusList);
            }
            
        }
        if(trigger.isafter && trigger.isDelete){
              List<Task> listTaskToUpdateTaskCreatedAccTeam = new List<task>();
             for(Task t: Trigger.Old){
                if(rtypCustomerProfilingTask == t.RecordTypeId && t.status != 'Completed'){
                        listTaskToUpdateTaskCreatedAccTeam.add(t);
                    }
             }
              if(!listTaskToUpdateTaskCreatedAccTeam.isEmpty()){
                    taskTriggerHelper.updateTaskCreatedAccTeam(listTaskToUpdateTaskCreatedAccTeam,True);
                }
             
        }
    }
}