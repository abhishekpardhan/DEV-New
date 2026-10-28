/***********************************************************
**Author: Shubham Rastogi
**Description:  Batch class to pull today's SFX records along with updated branches from Propeli System
**JIRA Ticket: 
**Test Class:
History: 
Modified By:
Modified Date: 
Comment: 

************************************************************/
global class BatchToPullSFX implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable
{
    //Executing method of schedulable interface to schedule the batch at specific time
    global void execute(SchedulableContext sc)
    {
        Integer batchSize = Integer.valueOf(Label.BatchToPullSFXSize);
        BatchToPullSFX objBatch = new BatchToPullSFX();
        database.executebatch(objBatch, batchSize);
    }
    
    global String query='';
    global Id sfxRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
    
    // Start method to pull out those invoices whose outstanding amount is greater then 0 and task is not created. 
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        query = 'SELECT Id, Name, SFX_Code__c FROM Account WHERE RecordTypeId =:sfxRecordTypeId AND LastModifiedDate = TODAY';
        System.debug('---- Query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    /**
* Execute method to fetch SFX from Propeli
**/    
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        system.debug(scope);
        try{
            for(Account acc : scope){
                clsPullPropelISFX.pullSFXData(acc.SFX_Code__c);
            }
        }catch(Exception e){
            ExceptionHandling.Exception('Pull SFX From Propeli', 'BatchToPullSFX', e);  
        }
    }
    
    global void finish(Database.BatchableContext BC){}
}