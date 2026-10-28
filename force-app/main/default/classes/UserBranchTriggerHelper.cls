public class UserBranchTriggerHelper {
    
    //Method to give user access to PRC Accounts when new UserBranchMapping record insert.
    public static void newInsert(List<User_Branch_Mapping__c> lstRecords){
        
        Set<Id> setBranchId = new Set<Id>();
        Map<Id,Id> mapBranchUserId = new Map<Id,Id>();
        Map<Id,List<Account>> mapBranchAccountId = new Map<Id,List<Account>>();
        List<Id> lstId = new List<Id>();
        List<AccountShare> lstAShare = new List<AccountShare>();
        try{
            for(User_Branch_Mapping__c ub : lstRecords){
                mapBranchUserId.put(ub.Branch_Name__c,ub.User__c);
                setBranchId.add(ub.Branch_Name__c);
                
            }
            Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
            
            for(Account acc : [select id,name,Branch__c from account where Branch__c IN: setBranchId and recordtypeid =: rId]){
                
                AccountShare ash = new AccountShare();
                ash.accountid = acc.Id;
                ash.userorgroupid = mapBranchUserId.get(acc.Branch__c);
                ash.accountaccesslevel = 'Edit';
                ash.OpportunityAccessLevel = 'None';
                ash.CaseAccessLevel = 'None';
                lstAShare.add(ash);
            }
            if(!lstAshare.isEmpty()){
                insert lstAshare;
            }
            
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
    }
    
    //Method to update the records visibility if branch changes for the user.
    public static void updateOnRecord(List<User_Branch_Mapping__c> lstRecords,Map<Id,User_Branch_Mapping__c> mapOldRecords){
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        Map<Id,Id> mapNewBranchUserId = new Map<Id,Id>();
        Map<Id,Id> mapOldBranchUserId = new Map<Id,Id>();
        List<Account> lstAccountsToBeRemoved = new List<Account>();
        Map<String,Accountshare> mapAShareRemove = new Map<String,Accountshare>();
        Map<Id,List<Account>> mapBranchAccounts = new Map<Id,List<Account>>();
        List<account> lstAccount = new List<Account>();
        List<AccountShare> lstAShare = new List<AccountShare>();
        try{
            for(User_Branch_Mapping__c ubm : lstRecords){
                
                if(ubm.Branch_Name__c != mapOldRecords.get(ubm.Id).Branch_Name__c && ubm.User__c == mapOldRecords.get(ubm.Id).User__c){
                    mapNewBranchUserId.put(ubm.Branch_Name__c,ubm.User__c);
                    mapOldBranchUserId.put(mapOldRecords.get(ubm.Id).Branch_Name__c, mapOldRecords.get(ubm.Id).User__c);
                }
            }
            //For removing old branch accounts.
            for(Account acc : [select id,name,Branch__c from account where recordtypeid =:rId and Branch__c IN: mapOldBranchUserId.keySet()]){
                
                lstAccountsToBeRemoved.add(acc);
                
            }
            
            for(AccountShare ash : [select id,userorgroupid,accountid from accountshare where accountid in: lstAccountsToBeRemoved]){
                
                mapAShareRemove.put(ash.accountid+'+'+ash.userorgroupid,ash);
            }
            for(Account acc : [select id,name,Branch__c from account where recordtypeid =:rId and Branch__c IN: mapOldBranchUserId.keySet()]){
                AccountShare AShare = new AccountShare();                
                AShare = mapAShareRemove.get(acc.Id+'+'+mapOldBranchUserId.get(acc.Branch__c));
                if(AShare != null){
                    lstAShare.add(AShare);
                }
            }
            if(!lstAShare.isEmpty()){
                delete lstAShare;
            }
            
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
    }
    
    //Method to remove visibilty if Userbranchmapping record deleted.
    public static void deleteOnRecord(List<User_Branch_Mapping__c> lstRecords){
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        Map<Id,Id> mapBranchUserId = new Map<Id,Id>();
        List<Id> lstAccountsToBeRemoved = new List<Id>();
        List<AccountShare> lstAShare = new List<AccountShare>();
        Map<String,Accountshare> mapAShareRemove = new Map<String,Accountshare>();
        try{            
            for(User_Branch_Mapping__c ubm : lstRecords){                
                mapBranchUserId.put(ubm.Branch_Name__c,ubm.User__c);
            }            
            //For removing old branch accounts.
            for(Account acc : [select id,name,Branch__c from account where recordtypeid =: rId and Branch__c IN: mapBranchUserId.keySet()]){
				// System.debug('====2');
                lstAccountsToBeRemoved.add(acc.Id);
                
            }            
            for(AccountShare ash : [select id,userorgroupid,accountid from accountshare where accountid in: lstAccountsToBeRemoved]){
                
                mapAShareRemove.put(ash.accountid+'+'+ash.userorgroupid,ash);
            }
            for(Account acc : [select id,name,Branch__c from account where recordtypeid =:rId and Branch__c IN: mapBranchUserId.keySet()]){
                AccountShare AShare = new AccountShare();                
                AShare = mapAShareRemove.get(acc.Id+'+'+mapBranchUserId.get(acc.Branch__c));
                if(AShare != null){
                    lstAShare.add(AShare);
                }
            }
            if(!lstAShare.isEmpty()){
                delete lstAShare;
            }
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
        }   
    }
}