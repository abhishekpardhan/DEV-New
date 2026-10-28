/** 
* Description      :   Share Utility class for invoice Share
* Last Changed     :   created on 02 April 2024
* Author           :   Himanshi and Raghav @IBM
* Release          :   
* JIRA Ticket	   :   https://safexpress.atlassian.net/browse/SAC-484
* Coverage		   :   
* Revision Logs    :   
**/
public class shareUtility {
    
     /*@future
    public static void deleteInvShareFuture(Set<Id> invToBDMKeys,Set<Id>propBDM){
        Savepoint databaseSavePoint = Database.setSavepoint();
        try{
            List<invoice__share> invShareList = [SELECT 
                                                 Id,ParentId,UserorGroupId
                                                 From invoice__share 
                                                 WHERE ParentId IN : invToBDMKeys AND UserorGroupId IN : propBDM AND RowCause ='Manual' ];
            if (invShareList.size()>0){
                delete invShareList;
            }
            
        }catch(DMLexception e){
            Database.rollback(databaseSavePoint);
            Database.releaseSavepoint(databaseSavePoint);
            System.debug('invoiceTriggerHelper.deleteInvShareFuture is failing with '+e.getMessage());
            ExceptionHandling.Exception( 'deleteInvShareFuture', 'shareUtility', e); 
            
            
        }
        
    }*/
   /* @future
    public static void deleteInvShareFuture(Set<Id> invToBDMKeys ){
        
        Savepoint databaseSavePoint = Database.setSavepoint();
        try{
            
            
            List<invoice__c> invoiceList = [SELECT Id, Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,
                                            Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c
                                            FROM invoice__c WHERE Id IN : invToBDMKeys];
            Set<id> propBDM= new Set<id>();
            
            for(invoice__c inv : invoiceList){
                if (inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c != null){
                    propBDM.add(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c);
                }
                if(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c != null){
                    propBDM.add(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c); 
                }
                
            }
            List<invoice__share> invShareList = [SELECT 
                                                 Id,ParentId,UserorGroupId
                                                 From invoice__share 
                                                 WHERE ParentId IN : invToBDMKeys AND UserorGroupId IN : propBDM AND RowCause ='Manual' ];
            if (invShareList.size()>0){
                delete invShareList;
            }
            
        }catch(DMLexception e){
            Database.rollback(databaseSavePoint);
            Database.releaseSavepoint(databaseSavePoint);
            System.debug('invoiceTriggerHelper.deleteInvShareFuture is failing with '+e.getMessage());
            ExceptionHandling.Exception( 'deleteInvShareFuture', 'shareUtility', e); 
            
            
        }
        
    }*/
     
    public static void deleteInvShare(String invToBdmJson) {
        system.debug('entered deleteInvShare method');
        Savepoint databaseSavePoint = Database.setSavepoint();
        try{
            Map<id , set<id>> invToBDMMap = (Map<id , set<id>>)json.deserialize(invToBdmJson , Map<id , Set<id>>.class); 
            System.debug('invToBDMMap.KeySet()-->'+invToBDMMap.KeySet());
            List<invoice__share> invShareList = [SELECT 
                                                 Id,ParentId,UserorGroupId
                                                 From invoice__share 
                                                 WHERE ParentId IN : invToBDMMap.KeySet() AND RowCause ='Manual' ];
            system.debug('invShareList--->'+invShareList);
            List<invoice__share> invShareToDel = new List<invoice__share>();
            System.debug('invToBDMMap.values()-->'+invToBDMMap.values());
            for(invoice__share invshare : invShareList){
                if(invToBDMMap.get(invshare.ParentId).contains(invshare.UserorGroupId)){
                    invShareToDel.add(invshare);
                    system.debug('invShareToDel==>'+invShareToDel);
                }
                
            }
            if(invShareToDel.size()>0){
                delete invShareToDel;
            }
            
        }catch(DMLexception e){
            Database.rollback(databaseSavePoint);
            Database.releaseSavepoint(databaseSavePoint);
            System.debug('invoiceTriggerHelper.deleteInvShare is failing with '+e.getMessage());
            ExceptionHandling.Exception( 'deleteInvShare', 'shareUtility', e); 
            
            
        }

        
    }
    
   
}