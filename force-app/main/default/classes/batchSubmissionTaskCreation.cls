/**
 * Description      :   Batch class to create the 'Bill Submission Tasks' for those Invoices which are not having any tasks created already
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
global class batchSubmissionTaskCreation implements Database.Batchable<sObject> ,Schedulable{
    
    //Executing method of schedulable interface to schedule the batch at specific time
    global void execute(SchedulableContext sc) {
        batchSubmissionTaskCreation bs = new batchSubmissionTaskCreation();
        database.executebatch(bs,200);
    }
    global String query='';
    global Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
   // datetime cr = date.valueOf(system.now().addDays(-5));
   // datetime cr2 = date.valueOf(system.now().addDays(-4));
   
    /**
     * Start method to query those invoice which are having createddate = YESTERDAY and Status_LID__c = 292 and Total_Outstanding_Amount__c > 0 and Collection_Branch__r.name != \'DELHI-10\' 
     **/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('rId+'+rId);
        query = 'select id,createddate,Bill_Number__c,account__c,LastModifiedDate,(select id,subject from tasks where recordtypeid=:rId) from invoice__c where createddate = YESTERDAY and Status_LID__c = 292 and Total_Outstanding_Amount__c > 0 and Collection_Branch__r.name != \'DELHI-10\'';

        
        return Database.getQueryLocator(query);
    }

    /**
     * Execute method to create the Bill Submission Tasks
     **/    
    global void execute(Database.BatchableContext BC, List<invoice__c> scope){
        List<task> lstTask = new List<task>();
        Id rIdSFX = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        system.debug('rId++'+rId);
        List<Id> lstAccountId = new List<Id>();
        map<Id,Id> mapAccId = new map<Id,Id>();        
        try{
            for(invoice__c inv : scope){
                if(inv.tasks.size() == 0){
                    lstAccountId.add(inv.account__c);
                }
            }
            
            for(Account acc: [select id,(select id,Submission__c,bdm__c from Account_Teams__r where Submission__c = true limit 1) from account where id IN: lstAccountId and recordtypeid =: rIdSFX ]){
                if(acc.Account_Teams__r.size() > 0 && acc.Account_Teams__r[0] != null){
                    mapAccId.put(acc.Id,acc.Account_Teams__r[0].bdm__c);
                }
            }
            if(!mapAccId.isEmpty()){
                for(invoice__c inv: scope){
                    if(mapAccId.containskey(inv.account__c)){
                        if(inv.tasks.size() == 0){
                            Task t = new task();
                            t.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
                            t.recordtypeid = rId;
                            t.whatid = inv.id;
                            t.Priority = 'High';
                            t.status = 'Open';
                            t.ownerid = mapAccId.get(inv.account__c);
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