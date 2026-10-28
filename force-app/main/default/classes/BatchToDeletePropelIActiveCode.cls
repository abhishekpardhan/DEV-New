global class BatchToDeletePropelIActiveCode implements Database.Batchable<sObject>, Database.Stateful {
    // Start method to query on billing line items.
    global String query = '';
    global List<String> MSAs = new List<String>();
    
    public BatchToDeletePropelIActiveCode(List<String> msaNumbers){
        
        this.MSAs = msaNumbers;
        
        if(!msaNumbers.isEmpty()){
            system.debug('Enter1');
            query = 'Select id, Name  from PropelI_Active_Code__c Where MSA__c In: MSAs';
        }else{
            system.debug('Enter2');
            query = 'Select id, Name  from PropelI_Active_Code__c';
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute method to store data into propeli active code object.
    global void execute(Database.BatchableContext bc, List<PropelI_Active_Code__c > activeCodes) {
        Database.delete(activeCodes, false);
    }
    // finish method
    global void finish(Database.BatchableContext bc) {
        system.debug('MSAs In Finish ==>'+MSAs);
        
        if(!MSAs.isEmpty()){
            system.debug('Enter1');
            database.executeBatch(new PropelIActiveCodeBatch(MSAs), 50);
        }else{
            system.debug('Enter2');
            database.executeBatch(new PropelIActiveCodeBatch(new List<String>()), 50);
        }
    }
}