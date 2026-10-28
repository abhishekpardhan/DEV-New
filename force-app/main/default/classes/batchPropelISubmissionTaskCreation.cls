/***********************************************************
**Author: Safexpress Private limited
**Description:  batch class to create the tasks of the invoice whose outstanding amount is greater then 0 and there is no task created.
**JIRA Ticket: 
**Test Class:
History: 
Modified By:
Modified Date: 
Comment: 

************************************************************/
global class batchPropelISubmissionTaskCreation implements Database.Batchable<sObject> ,Schedulable{
    
    //Executing method of schedulable interface to schedule the batch at specific time
    global void execute(SchedulableContext sc) {
        batchPropelISubmissionTaskCreation bs = new batchPropelISubmissionTaskCreation();
        database.executebatch(bs,200);
    }
    global String query='';
    global Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();

   
    // Start method to pull out those invoices whose outstanding amount is greater then 0 and task is not created. 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('rId+'+rId);
        query = 'select id,createddate,Bill_Number__c,account__c,LastModifiedDate,(select id,subject from tasks where recordtypeid=:rId) from invoice__c where Total_Outstanding_Amount__c > 0  AND Is_PropelI__c = true';

        
        return Database.getQueryLocator(query);
    }

    /**
     * Execute method to create the Bill Submission Tasks
     **/    
    global void execute(Database.BatchableContext BC, List<invoice__c> scope){
        List<task> lstTask = new List<task>();
        Id rIdSFX = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        System.debug('scope---------------->'+scope);
        System.debug('scope size---------->'+scope.size());
        system.debug('rId++'+rId);
        List<Id> lstAccountId = new List<Id>();
        map<Id,Id> mapAccId = new map<Id,Id>();        
        try{
            for(invoice__c inv : scope){
                if(inv.tasks.size() == 0){
                    lstAccountId.add(inv.account__c);
                }
            }
            System.debug('lstAccountId------------>'+lstAccountId);
            for(Account acc: [select id,(select id,Submission__c,BDMPropelI__c	 from Account_Teams__r where Submission__c = true limit 1) from account where id IN: lstAccountId ]){
                if(acc.Account_Teams__r.size() > 0 && acc.Account_Teams__r[0] != null){
                    mapAccId.put(acc.Id,acc.Account_Teams__r[0].BDMPropelI__c	);
                }
            }
            System.debug('mapAccId-------------->'+mapAccId);
            if(!mapAccId.isEmpty() || true){
                for(invoice__c inv: scope){
                    if(mapAccId.containskey(inv.account__c) || true){
                        if(inv.tasks.size() == 0){
                            Task t = new task();
                            t.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
                            t.recordtypeid = rId;
                            t.whatid = inv.id;
                            t.Priority = 'High';
                            t.status = 'Open';
                            t.Is_PropelI__c = true;
                           // t.ownerid = mapAccId.get(inv.account__c);
                            t.Automation__c = true;
                            t.ActivityDate = date.newinstance(inv.LastModifiedDate.year(), inv.LastModifiedDate.month(), inv.LastModifiedDate.day()).addDays(7);
                            lstTask.add(t);
                        }
                    }
                }
            }
            if(!lstTask.isEmpty()){
                insert lstTask;
            }
        }catch(Exception e){ // Added By Shubham 
            String name = 'Bill submission Task';
            String ClassName = 'batchSubmissionTaskCreation';
            ExceptionHandling.Exception( name, ClassName, e);  
    }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}