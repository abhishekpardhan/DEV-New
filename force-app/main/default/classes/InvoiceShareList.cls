public class InvoiceShareList implements Database.Batchable<sObject>, Database.Stateful{

    public List<Invoice__c> invoiceList = new List<Invoice__c>();
    public String query;
    public List<String> emailList = new List<String>();
    public Database.QueryLocator start(Database.BatchableContext bc){        
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<Invoice__c> recordList){
        Invoice__c invoice = recordList[0];
         
        List<UserRecordAccess> readAccessList;
        boolean isShare = true;
        Set<String> userIds = new Set<String>();
        if(!String.isBlank(invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c)){
            userIds.add(invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c);
        }
        if(!String.isBlank(invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c)){
            userIds.add(invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c);
        }
        if(!String.isBlank(invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c)){
            userIds.add(invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
        }
        if(!String.isBlank(invoice.QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c)){
            userIds.add(invoice.QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
        }
        if(!String.isBlank(invoice.CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c)){
            userIds.add(invoice.CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c);
        }
        if(userIds.size() > 0){
            // query in loop because it woun't support bulk in userid
            for(String userId : userIds){
                readAccessList = [SELECT RecordId FROM UserRecordAccess 
                                                  WHERE UserId=: userId AND HasReadAccess = true 
    											  AND RecordId =: invoice.Id LIMIT 200];
                if(readAccessList.size() == 0){
                    isShare = false;
                }
            }
        }
         
        System.debug('isShare-->'+isShare);
        if(isShare == false){
            System.debug('invoice-->'+invoice);
            invoiceList.add(invoice);
            InvoiceTriggerHelper.createInvShareRec(new Set<Id>{invoice.Id}, '');
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        
        String header = 'Invoice Id, Submission BDM , Collection BDM, NAM BDM, QRM BDM, CRS BDM \n';
        String finalstr = header ;
            
        System.debug('invoice-->'+this.invoiceList);    
        for(invoice__c invoice : this.invoiceList){
            String key = invoice.Id+','+invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.Name +','+invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.Name+','+invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__r.Name+','+invoice.QRM_Propeli_BDM_Mapping__r.PropelI_BDM__r.Name+','+invoice.CRS_Propeli_BDM_Mapping__r.PropelI_BDM__r.Name+'\n';
                  
            finalstr = finalstr +key;
                
        } 
        System.debug('finalstr-->'+finalstr); 
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalstr);
        string csvname= 'Invoice Share List.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = this.emailList;
        String subject ='Invoice Share List';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody('Account Team CSV ');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        

    }
}