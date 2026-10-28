/*********************************************************************************************
**Author: K SANSI - IBM, 29-11-2023
**Description: This Queuable Job is pulling MSA and its all childs(SFX->Services->Rate Card->Branch)
**JIRA Ticket: SAC-271
**Test Class: PullMSAQueueableTest
*************************************************************************************************** */

public class PullMSAQueueable implements Queueable, Database.AllowsCallouts {
    
    public List<Account> accList;    
    
    public PullMSAQueueable(List<Account> accList){
        this.accList = accList;
    }
    
    public void execute(QueueableContext context){
        if(this.accList.size() > 0){
            Account acc = this.accList[0];
            String sfxRecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Actual_SFX').getRecordTypeId();
            List<Account> sfxList = [SELECT Id, SFX_Code__c FROM Account WHERE ParentId =: acc.Id AND RecordTypeId =: sfxRecordTypeId];
            if(sfxList.size() > 0){
                clsPullPropelISFX.pullMSARecords(sfxList[0].SFX_Code__c);
                List<String> sfxIdList = new List<String>();
                for(Account sfxAcc : sfxList){
                    sfxIdList.add(sfxAcc.SFX_Code__c);
                }
                callSfxUpdateQueueable(sfxIdList);
                //ID nextJobId = System.enqueueJob(new BackSFXUpdateFuture(sfxIdList));
            }
            List<Account> remainingAccountList = this.accList;
            remainingAccountList.remove(0);
            if(remainingAccountList.size() > 0){
                Id remingJobId = System.enqueueJob(new PullMSAQueueable(remainingAccountList));
            }
        }
    } 
    
    public static void updateMSA(String startDate, String endDate, List<String> msaCodes){
        String msaRecordId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Customer').getRecordTypeId();
        String query = 'SELECT Id FROM Account Where ';
        query += ' RecordTypeId = \'' + msaRecordId + '\'';
        if(startDate != '' && endDate != ''){
            query += ' AND CreatedDate >= ' + startDate + 'T00:00:00Z ';
            query += ' AND CreatedDate <= ' + endDate + 'T11:59:59Z' ;
        }
        if(msaCodes.size() > 0){
            query += ' AND Propel_MSACode__c IN: msaCodes ';
        }        
        //query += ' AND Id = \'0017F00002335adQAA\'';
        query += ' AND Propel_MSACode__c != null';        
        System.debug('query-->'+query);
        
        List<Account> accList = Database.query(query);
        System.debug('accList-->'+accList);
        if(accList.size() > 0){ 
            Id queueJobId = System.enqueueJob(new PullMSAQueueable(accList));
        }
    }
    
    @future
    public static void callSfxUpdateQueueable(List<String> sfxIdList){
        ID nextJobId = System.enqueueJob(new BackSFXUpdateFuture(sfxIdList));
    }
}