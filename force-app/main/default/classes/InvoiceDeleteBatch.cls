/**
 * Description		:	When Total outstanding amount is 0 then after 3 months this class will delete the invoice
 * 
 * Revision Logs	:	V_1.0 - Created
 * 
 **/
global class InvoiceDeleteBatch implements Database.Batchable<sObject> ,Database.Stateful ,Schedulable {
    
        //Execute method of schedulable interface to schedule the batch at specific time
        global void execute(SchedulableContext sc) {
            InvoiceDeleteBatch objInv = new InvoiceDeleteBatch();
            Database.executeBatch(objInv,200);
        }
        
 	//Start method to query those invoices whose Date_Total_Amount__c = TODAY
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        String query = 'SELECT Id ,Date_Total_Amount__c from Invoice__c where Date_Total_Amount__c = TODAY';        
        return Database.getQueryLocator(query );
    }

        //Method to delete the Invoices returned from start method
    global void execute(Database.BatchableContext bc, List<Invoice__c> scope){        
        try{
            if(scope.size() > 0){
                delete scope;
            }
        }catch(Exception e){
            System.debug('<<< Exception message >>>'+e.getMessage());
            System.debug('<<< Exception line number >>>'+e.getLineNumber());
        }
    }    

    global void finish(Database.BatchableContext bc){        
    }    
}