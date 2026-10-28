global class airSurfaceAccessToRateCardBatch implements Database.Batchable<sObject> {
    
    global String query='';
    global Id rcRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
    //global List<Id> recId = new List<Id>{'a00C5000002b9joIAA','a00C5000002b9jnIAA','a00OX000005vtHdYAI','a00OX000005vtHcYAI'};
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        query = 'Select Id, Account__r.Parent.id, BDMPropelI__c FROM Account_Team__c WHERE Account__r.RecordTypeId =: rcRecordTypeId AND Relationship__c = true';// AND Id IN: recId limit 4';
        return Database.getQueryLocator(query);
    }
    
    
    global void execute(Database.BatchableContext BC, List<Account_Team__c> scope){
        
        List<AccountShare> accShareList = new List<AccountShare>();
        try{
            for(Account_Team__c accTeam : scope){
                if(accTeam.Account__r.Parent.id != null && accTeam.BDMPropelI__c !=null){
                    AccountShare accShare = helperAccountTeam.createAccountShare(accTeam.Account__r.Parent.id, accTeam.BDMPropelI__c);
                    accShareList.add(accShare);
                }
            }
            Database.SaveResult[] results = Database.insert(accShareList, false);
            for(Database.SaveResult result : results) {
                if(result.isSuccess()) {
                    System.debug('Successfully inserted Accounts : ' + result.getId());
                } else {
                    // iterate over the failed ones
                    for(Database.Error error : result.getErrors()) {
                        ExceptionHandling.Exception( 'airSurfaceAccessToRateCardBatch', 'updateAccountShare', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                        System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                    }
                }
            }
        }catch(Exception e){ 
            String name = 'Air Surface Access';
            String ClassName = 'airSurfaceAccessToRateCardBatch';
            ExceptionHandling.Exception( name, ClassName, e);  
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}