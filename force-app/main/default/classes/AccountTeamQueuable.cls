public class AccountTeamQueuable implements Queueable, Database.AllowsCallouts {
	
    public Map<String, List<Account_Team__c>> accountTeamMap;
    public Map<Id, Account_Team__c> mapOldAteam;
   // public string accountId;
    public AccountTeamQueuable(Map<String, List<Account_Team__c>> accountTeamMap, Map<Id, Account_Team__c> mapOldAteam ){
        this.accountTeamMap = accountTeamMap;
        this.mapOldAteam = mapOldAteam;
       // this.accountId = accountId;
    }
    
    public void execute(QueueableContext qc){
        
        List<Account_Team__c> updateCompositeKeyList = new List<Account_Team__c>();
        String accountId;
        for(String AccId : this.accountTeamMap.keySet()){
            updateCompositeKeyList = this.accountTeamMap.get(AccId);
            accountId = AccId;
            system.debug('accountId---->'+accountId);
            break;
        }
        updateCompositeKeyList = [SELECT Id, Account__c, Account__r.RecordTypeId, Account__r.Parent.Id, 
                                  Account__r.Parent.Parent.id, BDMPropelI__c, PropelI_BDM_Mapping__c, PropelI_Composite_Key__c,
                                  Collection__c, Submission__c
                           FROM Account_Team__c 
                           WHERE Id IN : updateCompositeKeyList];
        if(updateCompositeKeyList.size() > 0){
            System.debug('this.mapOldAteam-->'+this.mapOldAteam);
            if(this.mapOldAteam != null){
                helperAccountTeam.updateAccountShare(updateCompositeKeyList, this.mapOldAteam, accountId);
            
                helperAccountTeam.updateCompositeKeyOnPropelIBDM(updateCompositeKeyList, this.mapOldAteam);
            }
            helperAccountTeam.shareAccountHierarchy(updateCompositeKeyList, this.mapOldAteam, accountId);
        }
        Map<String, List<Account_Team__c>> accountTeamNewMap = this.accountTeamMap;
        system.debug('accountTeamNewMap--->'+accountTeamNewMap);
        accountTeamNewMap.remove(accountId);
        if(accountTeamNewMap.size() > 0){
            AccountTeamQueuable atObject = new AccountTeamQueuable(accountTeamNewMap, this.mapOldAteam);
            if(!Test.isRunningTest())
            	System.enqueueJob(atObject);
        }
        
    }
}