public class cls_PropelIActiveCodeReport {
    
    public static void handlePropelIActiveInactiveCodes(List<PropelI_BDM_Mapping__c> newRecords, List<PropelI_BDM_Mapping__c> oldRecords, Boolean isInsert, Boolean isUpdate, Boolean isDelete){
        
        List<String> MSAs = new List<String>();
        if(isInsert == true || isUpdate == true){
            
            Set<Id> accountIds = new Set<Id>();
            
            for(PropelI_BDM_Mapping__c mapping : newRecords){
                if(mapping.Account__c != null){
                    accountIds.add(mapping.Account__c);
                }
            }
            
            for(Account acc :  [Select Id, Name, Propel_MSACode__c, MSA__c From Account Where Id In: accountIds]){
                if(acc.Propel_MSACode__c != null && !MSAs.contains(acc.Propel_MSACode__c)){
                    MSAs.add(acc.Propel_MSACode__c);
                }
                if(acc.MSA__c != null && !MSAs.contains(acc.MSA__c)){
                    MSAs.add(acc.MSA__c);
                }
            }
        }
        
        if(isDelete){
            Set<Id> accountIds = new Set<Id>();
            
            for(PropelI_BDM_Mapping__c mapping : oldRecords){
                if(mapping.Account__c != null){
                    accountIds.add(mapping.Account__c);
                }
            }
            
            for(Account acc :  [Select Id, Name, Propel_MSACode__c, MSA__c From Account Where Id In: accountIds]){
                if(acc.Propel_MSACode__c != null && !MSAs.contains(acc.Propel_MSACode__c)){
                    MSAs.add(acc.Propel_MSACode__c);
                }
                if(acc.MSA__c != null && !MSAs.contains(acc.MSA__c)){
                    MSAs.add(acc.MSA__c);
                }
            }
        }
        if(!MSAs.isEmpty()){
            database.executeBatch(new BatchToDeletePropelIActiveCode(MSAs), 50);
        }
        
    }
    
}