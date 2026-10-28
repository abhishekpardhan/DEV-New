global class UpdateAccountShareBatch implements Database.Batchable<sObject> {
    
    public String query;
     
    public UpdateAccountShareBatch(String query ){
        this.query = query; 
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
         
        return Database.getQueryLocator(this.query );
        
    }    
    
    
    global void execute(Database.BatchableContext bc, List<Account_Team__c> scope)
        
    {
        //System.debug('lstNew ------> '+lstNew);
        Set<String> setShareMSA = new Set<String>();
        List<AccountShare> lstAccountShare = new List<AccountShare>();
        Set<String> setStrKey = new Set<String>();
        Set<String> setIdTeam = new Set<String>();
        
        Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
        
        for(Account_Team__c eachAccountTeam : scope){
            String strKey = eachAccountTeam.Shared_Account_Id__c + '@' + eachAccountTeam.BDMPropelI__c;
            
            if(eachAccountTeam.RecordTypeId == idProperIrecordType && eachAccountTeam.BDMPropelI__c != null && eachAccountTeam.Account__c != null && !setStrKey.contains(strKey))
            {
                if(eachAccountTeam.National1__c || eachAccountTeam.National2__c || eachAccountTeam.National3__c || eachAccountTeam.National4__c || eachAccountTeam.CRS__c
                   || eachAccountTeam.Relationship__c || eachAccountTeam.Collection__c || eachAccountTeam.Submission__c )
                {
                    //lstAccountShare.add(shareAccount(eachAccountTeam.Shared_Account_Id__c, eachAccountTeam.BDMPropelI__c));
                    setStrKey.add(strKey);
                    setIdTeam.add(eachAccountTeam.Id);
                }
            }
        }
        
        
        if(setIdTeam != null && setIdTeam.size() > 0)
        {
            List<Account_Team__c> lstAccountTeam = [SELECT Id, BDMPropelI__c,Account__r.OwnerId, Account__r.Parent.Parent.OwnerId,Account__r.Parent.Parent.Parent.OwnerId, Rate_Card_Id__c, SFX_Id__c, MSA_Id__c 
                                                    FROM Account_Team__c 
                                                    WHERE 
                                                    Id IN :setIdTeam
                                                    AND BDMPropelI__r.IsActive = true];
            //System.debug('----- lstAccountTeam: ' + lstAccountTeam);
            
            for(Account_Team__c eachAccountTeam : lstAccountTeam)
            {
                //System.debug('eachAccountTeam.Account__r.OwnerId---->'+eachAccountTeam.Account__r.OwnerId);
                //System.debug('eachAccountTeam.BDMPropelI__c------>'+eachAccountTeam.BDMPropelI__c);
                if(eachAccountTeam.Rate_Card_Id__c != null && eachAccountTeam.Account__r.OwnerId != eachAccountTeam.BDMPropelI__c)
                {
                    
                    lstAccountShare.add(shareAccount(eachAccountTeam.Rate_Card_Id__c, eachAccountTeam.BDMPropelI__c));
                }
                if(eachAccountTeam.SFX_Id__c != null  && eachAccountTeam.Account__r.Parent.Parent.OwnerId != eachAccountTeam.BDMPropelI__c)
                {
                    lstAccountShare.add(shareAccount(eachAccountTeam.SFX_Id__c, eachAccountTeam.BDMPropelI__c));
                }
                if(eachAccountTeam.MSA_Id__c != null  && eachAccountTeam.Account__r.Parent.Parent.Parent.OwnerId != eachAccountTeam.BDMPropelI__c)
                {
                    lstAccountShare.add(shareAccount(eachAccountTeam.MSA_Id__c, eachAccountTeam.BDMPropelI__c));
                }
            }
        }
        
        System.debug('total -->'+lstAccountShare.size());
        Database.SaveResult[] srList = Database.insert(lstAccountShare, false);
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted account. Account ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                	LoggerUtil.createErrorLog('UpdateAccountShareBatch', 'UpdateAccountShareBatch', err.getMessage(), scope[0].Id, err.getMessage(), null);
                }
            }
        }
        
        
        
    }
    
    
    global void finish(Database.BatchableContext bc){        
    } 
    
    public AccountShare shareAccount(String strAccountId, Id strUserId)
    {
        AccountShare objAccountShare = new AccountShare();
        objAccountShare.AccountId = strAccountId;
        objAccountShare.UserORGroupId = strUserId;
        objAccountShare.AccountAccessLevel = 'Edit';    
        objAccountShare.OpportunityAccessLevel = 'None';
        objAccountShare.CaseAccessLevel = 'None';
        //objAccountShare.RowCause = 'BDM Mapping';
        
        return objAccountShare;
    }
    
}