public class InvoiceSharebatch implements Database.Batchable<sObject>{
    
    public String query;
    public Database.QueryLocator start(Database.BatchableContext BC ){
        return Database.getQueryLocator(this.query);
        /*return Database.getQueryLocator([Select Id, Collection_PropelI_BDM_Mapping__c, Submission_propelI_BDM_Mapping__c,
                                         MSA__c, Bill_Branch__c, Sub_Branch_Master__c, Collection_Branch__c,
                                         QRM_Propeli_BDM_Mapping__c, CRS_Propeli_BDM_Mapping__c, Account__c, 
                                         Billing_Level__c , NAM_Propeli_BDM_Mapping__c 
                                         FROM Invoice__c 
                                         WHERE Total_Outstanding_Amount__c>0]);*/
    }
    
    public void execute( Database.BatchableContext BC, List<Invoice__c> lstInvoice){
        
        if(!lstInvoice.isEmpty()){
            invoiceTriggerHelper.PopulateSubColBdm(lstInvoice);
            invoiceTriggerHelper.populateRelationBDM(lstInvoice);
            update lstInvoice;
            System.debug('invList-->'+lstInvoice);
            
        }
    }
    public void finish(Database.BatchableContext BC){
        
    }
}