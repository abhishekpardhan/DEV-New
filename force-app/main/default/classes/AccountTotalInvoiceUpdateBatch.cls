global class AccountTotalInvoiceUpdateBatch implements Database.Batchable<sObject> {
    
    public string query;
    public AccountTotalInvoiceUpdateBatch(String query){
        this.query = query;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        // collect the batches of records or objects to be passed to execute
         //if(this.accountSet != null){

            return Database.getQueryLocator(query);
 /*else{
            return Database.getQueryLocator([SELECT Id, Name, Total_Number_Of_Invoices__c, Total_Outstanding_Amount__c
                                     FROM Account ]);
        }*/
            
        
    }
    
    global void execute(Database.BatchableContext bc, List<Account> listAccount){
        Set<Id> accountSet = new Set<Id>();
        // process each batch of records
        for(Account acc : listAccount){
            accountSet.add(acc.Id);
        }
        TriggerUtility.byPassTrigger = True;
        InvoiceTriggerHelper.updateAccount(accountSet);
        
    }  
    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    
}