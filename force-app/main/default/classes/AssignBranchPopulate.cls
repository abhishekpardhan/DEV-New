global class AssignBranchPopulate implements Database.Batchable<sObject> {
    
    public Set<String> acIdSet;
    public AssignBranchPopulate(){
        
    }
    public AssignBranchPopulate(Set<String> acIdSet){
        this.acIdSet = acIdSet;
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        if(this.acIdSet != null){
            System.debug('here...');
            return Database.getQueryLocator([select Id,Relationship__c,Account__c,PropelI_BDM_Mapping__c,
                PropelI_BDM_Mapping__r.Booking_Branch__r.Id 
                from Account_Team__c where Id IN : this.acIdSet AND  Relationship__c = true and assigned_Branch__c =null and 
                                         PropelI_BDM_Mapping__c !=null ]);
        } else{
        	return Database.getQueryLocator([select Id,Relationship__c,Account__c,PropelI_BDM_Mapping__c,
                PropelI_BDM_Mapping__r.Booking_Branch__r.Id 
                from Account_Team__c where Relationship__c = true and assigned_Branch__c =null and 
                                         PropelI_BDM_Mapping__c !=null ]);
        }
    }
    
    global void execute(Database.BatchableContext bc, List<Account_Team__c> relationshipTeamMembers){
        System.debug('relationshipTeamMembers-->'+relationshipTeamMembers);
        map<Id,ID> accountTeamIdToranchId = new map<Id,Id>();
        set<Id> rcIds = new set<Id>();
        for(Account_Team__c at : relationshipTeamMembers){
            accountTeamIdToranchId.put(at.Id,at.PropelI_BDM_Mapping__r.Booking_Branch__r.Id);
            rcIds.add(at.Account__c);
        }
        
        System.debug('-rcIds--'+rcIds);
        list<Account> assignAccounts = new list<Account>([ 
            select Id,Billing_Branch__c from account where  parentId in : rcIds LIMIT 10000
        ]);
        map<Id,Id> branchIdToAssignBranch = new map<Id,Id>();
        for(Account assignAcc : assignAccounts){
            branchIdToAssignBranch.put(assignAcc.Billing_Branch__c, assignAcc.Id);
        }
        system.debug('--branchIdToAssignBranch-'+branchIdToAssignBranch);
        
        List<Account_team__c> acListUpdate = new List<Account_team__c>();
        for(Account_team__c at : relationshipTeamMembers){
            system.debug('--accountTeamIdToranchId.get(at.Id)-'+accountTeamIdToranchId.get(at.Id));
            
            if(branchIdToAssignBranch.containsKey(accountTeamIdToranchId.get(at.Id))){
                System.debug('here inside...');
                at.Assigned_Branch__c = branchIdToAssignBranch.get(accountTeamIdToranchId.get(at.Id));
                acListUpdate.add(at);
            }
            
            system.debug('====== '+branchIdToAssignBranch.get(accountTeamIdToranchId.get(at.Id)));
        }
        try{
            System.debug('relationshipTeamMembers-->'+relationshipTeamMembers);
            if(acListUpdate.size() > 0){
                update relationshipTeamMembers;
            }            
        } catch(Exception excp){
            System.debug('exception --> '+excp.getMessage());
        }
        
        
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}