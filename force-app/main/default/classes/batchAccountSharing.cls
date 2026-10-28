/*-------------------------------------------------------------
Author: Safexpress
Desciption: batch class to share the account records based on account team. 
Test Class: 
History: 
------------------------------------------------------------------------*/
Global Class batchAccountSharing implements DataBase.Batchable<sObject>
{
    // Pull the account team record which are created in last 1 days. 
    Global  DataBase.QueryLocator Start(DataBase.BatchableContext BC)
    {
        String strTimeStamp = System.label.Sharing_Time_Stamp;
        String qury = 'SELECT Id, BDM__c ,Account__c,Account__r.SFX_Code__c,Account__r.Name, Account__r.SFX__c,BDM__r.isActive  from Account_Team__c where Created_Date__c ='+ strTimeStamp+'AND (BDMPropelI__c != Null OR BDM__c != Null)';
       
        return Database.getQueryLocator(qury);
    
    }
    Global void execute(Database.BatchableContext BC, List<Account_team__c> lstAccountTms) 
    {
        //Process account team records to check against of Account Share records. 
        System.debug('lstAccountTms------------->'+lstAccountTms);
        System.debug('lstAccountTms size() -------------->'+lstAccountTms.size());
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setBDMIds = new Set<Id>();
        Set<String> setAcc_BDMIds = new Set<String>();
        if(! lstAccountTms.isEmpty())
        {
            for(Account_Team__c eachAccountTeam : lstAccountTms)
            {
                if(eachAccountTeam.Account__c != null && eachAccountTeam.BDM__c != null && eachAccountTeam.BDM__r.isActive)
                {
                    setAccountIds.add(eachAccountTeam.Account__c);
                    setBDMIds.add(eachAccountTeam.BDM__c);
                    setAcc_BDMIds.add(eachAccountTeam.Account__c +'::'+eachAccountTeam.BDM__c);
                }
            }
            System.debug('setAccountIds------------>'+setAccountIds);
            System.debug('setBDMIds--------------------->'+setBDMIds);
            System.debug('setAcc_BDMIds----------------->'+setAcc_BDMIds);
            if(! setAcc_BDMIds.isEmpty())
            {
                Set<String> setSharedAccountRecds = new Set<String>();
                List<AccountShare> lstAccountShare = [select id,userorgroupid,accountid from accountshare where accountid in: setAccountIds];
                System.debug('lstAccountShare--------->'+lstAccountShare);
                if(! lstAccountShare.isEmpty())
                {
                    for(AccountShare eachAccountShare : lstAccountShare)
                    {
                        if(eachAccountShare.accountid != null && eachAccountShare.userorgroupid != null)
                            setSharedAccountRecds.add(eachAccountShare.accountid+'::'+eachAccountShare.userorgroupid);
                    }
                    
                }
                System.debug('setSharedAccountRecds------------->'+setSharedAccountRecds);
                Set<String> lstUnsharedAccountTeam = new Set<String>();
                for(String strlastDayAccountTeam : setAcc_BDMIds)
                {
                    if(! setSharedAccountRecds.isEmpty() && ! setSharedAccountRecds.contains(strlastDayAccountTeam))
                        lstUnsharedAccountTeam.add(strlastDayAccountTeam);
                }
                System.debug('lstUnsharedAccountTeam------------>'+lstUnsharedAccountTeam);
                list<AccountShare> lstAccountToBeShared = new List<AccountShare>();
                if(! lstUnsharedAccountTeam.isEmpty())
                {
                    for(String eachAccountToShare : lstUnsharedAccountTeam)
                    {
                       if(eachAccountToShare != null && eachAccountToShare.contains('::'))
                       {
                            List<String> lstAccountId = eachAccountToShare.split('::');
                            System.debug('lstAccountId--------->'+lstAccountId);
                            AccountShare accSharing = new AccountShare();
                            accSharing.accountid = lstAccountId[0];
                            accSharing.userorgroupid = lstAccountId[1];
                            accSharing.accountaccesslevel = 'Edit';
                            accSharing.OpportunityAccessLevel = 'None';
                            accSharing.CaseAccessLevel = 'None';
                            lstAccountToBeShared.add(accSharing);
                       }
                       
                    }
                    System.debug('lstAccountToBeShared----------->'+lstAccountToBeShared);
                    if(! lstAccountToBeShared.isEmpty())
                    {
                        System.debug('Records are successfully updated !!!');
                        insert lstAccountToBeShared;
                    }
                }
            }

        }

    }
    Global void finish(Database.BatchableContext BC) {


        batchAccountSharing btchAcc = new batchAccountSharing();
        String sch = '0 0 0,4,8,12,16,20 ? * *';
        if(!Test.isRunningTest())
        {
            
            String cronID = System.scheduleBatch(btchAcc , 'Account Sharing Batch', 240);
            System.debug('cronID ----------------->'+cronID);
        }
        //System.schedule('SFX Code Sharing Batch', sch, btchAcc);

    }

}