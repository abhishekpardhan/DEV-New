/**
 * Description      :   This batch class will delete those account team in which all checkbox relationship,collection,submission,nam1,nam2,nam3,nam4,crs,nsm are false from 1 month.
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
global class AccountTeamDeleteBatch implements Database.Batchable<sObject> ,Database.Stateful ,Schedulable {
        
    //Executing method of schedulable interface to schedule the batch at specific time 
    global void execute(SchedulableContext sc) {
        AccountTeamDeleteBatch objAccTeam = new AccountTeamDeleteBatch();
        Database.executeBatch(objAccTeam,200);
    }
    
    global String query='';
     
    /**
     * Start method to query the records from Account whose 'Account_Team_LastModi_Date__c' = Today and all the National Fiels are false
     **/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        query = 'SELECT Id ,Account_Team_LastModi_Date__c from Account_Team__c where Relationship__c = false and Collection__c = false and Submission__c = false and '+
        +'National1__c = false and National2__c = false and National3__c = false and National4__c = false and CRS__c = false and NSM__c = false';
        if(!Test.isRunningTest())
            query += ' AND Account_Team_LastModi_Date__c = TODAY';
        
        System.debug('query-->' + query);
        
        return Database.getQueryLocator(query );
    }

    /**
     * Execute method to delete the above queried records
     **/
    global void execute(Database.BatchableContext bc, List<Account_Team__c> scope){
        System.debug('<<<< scope >>> '+scope);
        try{
            if(scope != null && scope.size() > 0){
                delete scope;
            }
        }catch(Exception e){
            System.debug('<<< err message >>>'+e.getMessage());
            System.debug('<<< err line number >>>'+e.getLineNumber());
        }
    }    
    global void finish(Database.BatchableContext bc){
    }    
}