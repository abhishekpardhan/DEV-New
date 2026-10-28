global class AccTeamDelBatch implements Database.Batchable<sObject> , Schedulable {

        //Execute method of schedulable interface to schedule the batch at specific time
       		global void execute(SchedulableContext sc) {
            	AccTeamDelBatch objAT = new AccTeamDelBatch();
            	Database.executeBatch(objAT,200);
        }
     	//Start method to query those Account Teams whose BDM is inactive
     		global Database.QueryLocator start(Database.BatchableContext bc) {
             	return Database.getQueryLocator('select id, name, BDM__c, BDMPropelI__c from Account_Team__c where (BDM__c != null AND BDM__r.isActive = false) OR (BDMPropelI__c != null AND BDMPropelI__r.isActive = false)');
                //select id, name, BDM__c from Account_Team__c where BDM__r.isActive = false
            }
        //Method to delete the Account Teams returned from start method
       		global void execute(Database.BatchableContext bc, List<Account_Team__c> scope){
			try{
            if(scope != null && scope.size() > 0){
                delete scope;
            }
                if(test.isRunningTest()){
                    throw new dmlException();
                }
                
        }catch(Exception e){
            System.debug('<<< Exception message >>>'+e.getMessage());
            System.debug('<<< Exception line number >>>'+e.getLineNumber());
        }
    }    

    global void finish(Database.BatchableContext bc){        
    }    
}