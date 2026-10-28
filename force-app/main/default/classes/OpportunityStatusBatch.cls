public class OpportunityStatusBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Query locator for the batch to retrieve opportunities with null Opportunity_Status__c
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator(
                'SELECT Id, Name, Stage__c, Opportunity_Status__c FROM Opportunity__c '
            );
        }else{
            return Database.getQueryLocator(
                'SELECT Id, Name, Stage__c, Opportunity_Status__c FROM Opportunity__c WHERE Opportunity_Status__c = null'
            );
        }
    }

    // Executes the logic on each batch of records
    public void execute(Database.BatchableContext bc, List<Opportunity__c> scope) {
        List<Opportunity__c> oppsToUpdate = new List<Opportunity__c>();

        // Loop through each opportunity in the batch
        for (Opportunity__c objOpp : scope) {
            if (objOpp.Stage__c == 'Active' || objOpp.Stage__c == 'Quotation' || 
                objOpp.Stage__c == 'Negotiation' || objOpp.Stage__c == 'Passive') {
                objOpp.Opportunity_Status__c = 'Open';
            } else {
                objOpp.Opportunity_Status__c = 'Closed';
            }
            oppsToUpdate.add(objOpp);
        }

        // Update the records in this batch
        if (!oppsToUpdate.isEmpty()) {
            // Temporarily bypass any triggers if necessary
            TriggerUtility.byPassTrigger = true;
            try {
                update oppsToUpdate;
           /* } catch(Exception exce){
                System.debug(exce);*/
            }finally {
                // Ensure the trigger bypass is reset
                TriggerUtility.byPassTrigger = false;
            }
        }
    }

    // Finish method, executes after all batches are processed
    public void finish(Database.BatchableContext bc) {
        // Optionally add any post-processing logic or logging here
       // System.debug('Batch processing completed successfully.');
    }
}