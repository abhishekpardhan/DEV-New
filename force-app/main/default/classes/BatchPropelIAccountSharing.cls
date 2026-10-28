/*-------------------------------------------------------------
Author: Safexpress
Desciption: Batch class to share PropelI records with PropelI Account Team.
Test Class: 
History: 
------------------------------------------------------------------------*/
global class BatchPropelIAccountSharing implements DataBase.Batchable<sObject>
{
    // Pull the account team record which are created in last 1 days. 
    global  DataBase.QueryLocator Start(DataBase.BatchableContext BC)
    {
        String strTimeStamp = System.label.Sharing_PropelI_Time_Stamp;
        String recordTypeId = '\'PropelI Account Team\'';
        String query = 'SELECT Id, Shared_Account_Id__c, BDMPropelI__c, National1__c, National2__c, National3__c, National4__c, '
                + 'CRS__c, Relationship__c, Collection__c, Submission__c from Account_Team__c where BDMPropelI__c != Null AND Created_Date__c = ' 
                + strTimeStamp + ' AND RecordType.Name = ' + recordTypeId + ' AND BDMPropelI__r.IsActive = true'
                + ' AND (National1__c = true OR National2__c = true OR National3__c = true OR National4__c = true OR CRS__c = true '
                + 'OR Relationship__c = true OR Collection__c = true OR Submission__c = true)';
        System.debug('---- query: ' + query);
        return Database.getQueryLocator(query);
    
    }
    
    global void execute(Database.BatchableContext BC, List<Account_team__c> lstAccountTms) 
    {
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setBDMIds = new Set<Id>();
        Set<String> setAcc_BDMIds = new Set<String>();
        
        if(! lstAccountTms.isEmpty())
        {
            for(Account_Team__c eachAccountTeam : lstAccountTms)
            {
                if(eachAccountTeam.Shared_Account_Id__c != null)
                {
                    setAccountIds.add(eachAccountTeam.Shared_Account_Id__c);
                    setBDMIds.add(eachAccountTeam.BDMPropelI__c);
                    setAcc_BDMIds.add(eachAccountTeam.Shared_Account_Id__c +'::'+eachAccountTeam.BDMPropelI__c);
                }
            }
            
            if(! setAcc_BDMIds.isEmpty())
            {
                Set<String> setSharedAccountRecds = new Set<String>();
                List<AccountShare> lstAccountShare = [SELECT Id, UserOrGroupId, AccountId FROM AccountShare WHERE AccountId IN :setAccountIds];
                System.debug('lstAccountShare--------->'+lstAccountShare);
                
                if(! lstAccountShare.isEmpty())
                {
                    for(AccountShare eachAccountShare : lstAccountShare)
                    {
                        String accountId = eachAccountShare.accountId;
                        accountId = accountId.substring(0, 15);
                        setSharedAccountRecds.add(accountId + '::' + eachAccountShare.userorgroupid);
                    }
                }
                
                Set<String> setUnsharedAccountTeam = new Set<String>();
                for(String strlastDayAccountTeam : setAcc_BDMIds)
                {
                    if(! setSharedAccountRecds.isEmpty() && ! setSharedAccountRecds.contains(strlastDayAccountTeam))
                    {
                        setUnsharedAccountTeam.add(strlastDayAccountTeam);
                    }
                }

                if(! setUnsharedAccountTeam.isEmpty())
                {
                    list<AccountShare> lstAccountToBeShared = new List<AccountShare>();

                    for(String eachAccountToShare : setUnsharedAccountTeam)
                    {
                       if(eachAccountToShare != null && eachAccountToShare.contains('::'))
                       {
                            List<String> lstAccountId = eachAccountToShare.split('::');
                            AccountShare objAccountShare = new AccountShare(AccountId = lstAccountId[0], UserOrGroupId = lstAccountId[1], 
                                AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None', CaseAccessLevel = 'None');
                            lstAccountToBeShared.add(objAccountShare);
                       }
                    }
                    System.debug('---- size: ' + lstAccountToBeShared.size() + ' :: lstAccountToBeShared: ' +lstAccountToBeShared);
                    
                    if(! lstAccountToBeShared.isEmpty())
                    {
                        System.debug('Records are successfully updated !!!');
                        insert lstAccountToBeShared;
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        BatchPropelIAccountSharing btchAcc = new BatchPropelIAccountSharing();
        String sch = '0 0 0,4,8,12,16,20 ? * *';
        if(!Test.isRunningTest())
        {
            String cronId = System.scheduleBatch(btchAcc , 'PropelI Account Sharing Batch', 240);
            System.debug('cronID ----------------->'+cronID);
        }
    }
}