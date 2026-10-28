public class trg_AccountTeamHelper
{
    public static Boolean runOnce = true;
    
    public static void afterInsert(List<Account_Team__c> lstNew)
    {
        afterInsert_AccountSharing(lstNew); 
    }
    public static void afterUpdate(List<Account_Team__c> lstNew, Map<Id, Account_Team__c> mapOld)
    {
        afterUpdate_AccountSharing(lstNew, mapOld);
    }
    
    static void afterInsert_AccountSharing(List<Account_Team__c> lstNew)
    {
        // System.debug('lstNew ------> '+lstNew);
        Set<String> setShareMSA = new Set<String>();
        List<AccountShare> lstAccountShare = new List<AccountShare>();
        Set<String> setStrKey = new Set<String>();
        Set<String> setIdTeam = new Set<String>();
        
        Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
        
        for(Account_Team__c eachAccountTeam : lstNew)
        {
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
            
            
            for(Account_Team__c eachAccountTeam : lstAccountTeam)
            {
               
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
        
      
        
        //Inserting Account Sharing with BDM User.
        if(lstAccountShare != null && lstAccountShare.size() > 0)
        {
            //insert lstAccountShare;
            Database.SaveResult[] results = Database.insert(lstAccountShare, false);
            // iterate over the list of returned results
            for(Database.SaveResult result : results) {
                if(result.isSuccess()) {
                   
                } else {
                    // iterate over the failed ones
                    for(Database.Error error : result.getErrors()) {
                        ExceptionHandling.Exception( 'trg_AccountTeamHelper', 'afterInsert_AccountSharing', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                      
                    }
                }
            }
        }
    }
    
    //This will work for UI prospect.
    static void afterUpdate_AccountSharing(List<Account_Team__c> lstNew, Map<Id, Account_Team__c> mapOld)
    {
        List<AccountShare> lstAccountShare = new List<AccountShare>();
        Set<String> setAccountId = new Set<String>();
        Set<String> setBDM = new Set<String>();
        Set<String> setStrKey = new Set<String>();
        
        Id idProperIrecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
        
        for(Account_Team__c eachAccountTeam : lstNew)
        {
            //For sharing
            if(eachAccountTeam.RecordTypeId == idProperIrecordType && eachAccountTeam.BDMPropelI__c != null)
            {
                Set<String> setKey = new Set<String>();
                
                if((eachAccountTeam.National1__c && !mapOld.get(eachAccountTeam.Id).National1__c) 
                   || (eachAccountTeam.National2__c && !mapOld.get(eachAccountTeam.Id).National2__c) 
                   || (eachAccountTeam.National3__c && !mapOld.get(eachAccountTeam.Id).National3__c) 
                   || (eachAccountTeam.National4__c && !mapOld.get(eachAccountTeam.Id).National4__c) 
                   || (eachAccountTeam.CRS__c && !mapOld.get(eachAccountTeam.Id).CRS__c)
                  )
                {
                    if(eachAccountTeam.MSA_Id__c != null && eachAccountTeam.Account_Owner_Id__c != eachAccountTeam.BDMPropelI__c)
                    {
                        lstAccountShare.add(shareAccount(eachAccountTeam.MSA_Id__c, eachAccountTeam.BDMPropelI__c));
                        setKey.add(eachAccountTeam.MSA_Id__c + '@@' + eachAccountTeam.BDMPropelI__c);
                    }
                }
                
                if((eachAccountTeam.Collection__c && !mapOld.get(eachAccountTeam.Id).Collection__c) 
                   || (eachAccountTeam.Submission__c && !mapOld.get(eachAccountTeam.Id).Submission__c)
                  )
                {
                    if(eachAccountTeam.SFX_Id__c != null && eachAccountTeam.Account_Owner_Id__c != eachAccountTeam.BDMPropelI__c)
                    {
                        lstAccountShare.add(shareAccount(eachAccountTeam.SFX_Id__c, eachAccountTeam.BDMPropelI__c));
                        setKey.add(eachAccountTeam.SFX_Id__c + '@@' + eachAccountTeam.BDMPropelI__c);
                    }
                    String msaKey = eachAccountTeam.MSA_Id__c + '@@' + eachAccountTeam.BDMPropelI__c;
                    
                    if(eachAccountTeam.MSA_Id__c != null && !setKey.contains(msaKey) && eachAccountTeam.Account_Owner_Id__c != eachAccountTeam.BDMPropelI__c)
                    {
                        lstAccountShare.add(shareAccount(eachAccountTeam.MSA_Id__c, eachAccountTeam.BDMPropelI__c));
                        setKey.add(eachAccountTeam.MSA_Id__c + '@@' + eachAccountTeam.BDMPropelI__c);
                    }
                }
                
                if(eachAccountTeam.Relationship__c && !mapOld.get(eachAccountTeam.Id).Relationship__c)
                {
                    if(eachAccountTeam.Rate_Card_Id__c != null && eachAccountTeam.Account_Owner_Id__c != eachAccountTeam.BDMPropelI__c)
                    {
                        lstAccountShare.add(shareAccount(eachAccountTeam.Rate_Card_Id__c, eachAccountTeam.BDMPropelI__c));
                        setKey.add(eachAccountTeam.Rate_Card_Id__c + '@@' + eachAccountTeam.BDMPropelI__c);
                    }
                    String sfxKey = eachAccountTeam.SFX_Id__c + '@@' + eachAccountTeam.BDMPropelI__c;
                    if(eachAccountTeam.SFX_Id__c != null && !setKey.contains(sfxKey) && eachAccountTeam.Account_Owner_Id__c != eachAccountTeam.BDMPropelI__c)
                    {
                        lstAccountShare.add(shareAccount(eachAccountTeam.SFX_Id__c, eachAccountTeam.BDMPropelI__c));
                        setKey.add(eachAccountTeam.SFX_Id__c + '@@' + eachAccountTeam.BDMPropelI__c);
                    }
                    String msaKey = eachAccountTeam.MSA_Id__c + '@@' + eachAccountTeam.BDMPropelI__c;
                    if(eachAccountTeam.MSA_Id__c != null && !setKey.contains(msaKey) && eachAccountTeam.Account_Owner_Id__c != eachAccountTeam.BDMPropelI__c)
                    {
                        lstAccountShare.add(shareAccount(eachAccountTeam.MSA_Id__c, eachAccountTeam.BDMPropelI__c));
                        setKey.add(eachAccountTeam.MSA_Id__c + '@@' + eachAccountTeam.BDMPropelI__c);
                    }
                }
                //End sharing
                
                
                //For un-sharing
                //Rate Card Un-sharing
                if(!eachAccountTeam.Relationship__c && mapOld.get(eachAccountTeam.Id).Relationship__c)
                {
                    setAccountId.add(eachAccountTeam.SFX_Id__c);
                    setAccountId.add(eachAccountTeam.MSA_Id__c);
                    setBDM.add(eachAccountTeam.BDMPropelI__c);
                }
                
                //For SFX Un-sharing
                if(!eachAccountTeam.Collection__c && !eachAccountTeam.Submission__c 
                   && (mapOld.get(eachAccountTeam.Id).Collection__c || mapOld.get(eachAccountTeam.Id).Submission__c)
                  )
                {
                    setAccountId.add(eachAccountTeam.SFX_Id__c);
                    setAccountId.add(eachAccountTeam.MSA_Id__c);
                    setBDM.add(eachAccountTeam.BDMPropelI__c);
                }
                
                //For MSA Un-sharing
                if((!eachAccountTeam.National1__c && !eachAccountTeam.National2__c && !eachAccountTeam.National3__c && !eachAccountTeam.National4__c && !eachAccountTeam.CRS__c)
                   && (mapOld.get(eachAccountTeam.Id).National1__c || mapOld.get(eachAccountTeam.Id).National2__c || mapOld.get(eachAccountTeam.Id).National3__c 
                       || mapOld.get(eachAccountTeam.Id).National4__c || mapOld.get(eachAccountTeam.Id).CRS__c)
                  )
                {
                    if(eachAccountTeam.SFX_Id__c != null)
                    {
                        setAccountId.add(eachAccountTeam.SFX_Id__c);
                    }
                    setAccountId.add(eachAccountTeam.MSA_Id__c);
                    setBDM.add(eachAccountTeam.BDMPropelI__c);
                }
            }
        }

        
        if(setAccountId != null && setAccountId.size() > 0 && setBDM != null && setBDM.size() > 0)
        {
            List<Account_Team__c> lstExistingTeam = [SELECT Id, Account__c, BDMPropelI__c, Rate_Card_Id__c, SFX_Id__c, MSA_Id__c 
                                                     FROM Account_Team__c 
                                                     WHERE 
                                                     BDMPropelI__c IN :setBDM
                                                     AND (SFX_Id__c IN :setAccountId OR MSA_Id__c IN :setAccountId)
                                                    ];
           
            
            Map<String, List<Account_Team__c>> mapIdListAT = new Map<String, List<Account_Team__c>>();
            Map<String, Map<String, List<Account_Team__c>>> mapKeyMapMSAListAT = new Map<String, Map<String, List<Account_Team__c>>>();
            
            for(Account_Team__c eachTeam : lstExistingTeam)
            {
                String sfxKey = eachTeam.SFX_Id__c + eachTeam.BDMPropelI__c;
                if(!mapIdListAT.containsKey(sfxKey))
                {
                    mapIdListAT.put(sfxKey, new List<Account_Team__c>{});
                }
                mapIdListAT.get(sfxKey).add(eachTeam);
                
                String msaKey = eachTeam.MSA_Id__c + eachTeam.BDMPropelI__c;
                if(!mapIdListAT.containsKey(msaKey))
                {
                    mapIdListAT.put(msaKey, new List<Account_Team__c>{});
                }
                mapIdListAT.get(msaKey).add(eachTeam);                    
            }
            
            
            Map<String, List<String>> mapIdAccListIdBDM_Del = new Map<String, List<String>>();
            Set<Id> setUserId = new Set<Id>();
            
            for(Account_Team__c eachAccountTeam : lstNew)
            {
                //Rate Card Un-sharing
                if(!eachAccountTeam.Relationship__c && mapOld.get(eachAccountTeam.Id).Relationship__c)
                {
                    setUserId.add(eachAccountTeam.BDMPropelI__c);
                    mapIdAccListIdBDM_Del.put(eachAccountTeam.Rate_Card_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                    
                    if(mapIdListAT != null && mapIdListAT.size() > 0)
                    {
                        String SFXKey = eachAccountTeam.SFX_Id__c + eachAccountTeam.BDMPropelI__c;
                        if(mapIdListAT.containsKey(SFXKey) && mapIdListAT.get(SFXKey) != null && mapIdListAT.get(SFXKey).size() <= 1)
                        {
                         
                            mapIdAccListIdBDM_Del.put(eachAccountTeam.SFX_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                        }
                        
                        String MSAKey = eachAccountTeam.MSA_Id__c + eachAccountTeam.BDMPropelI__c;
                        if(mapIdListAT.containsKey(MSAKey) && mapIdListAT.get(MSAKey) != null && mapIdListAT.get(MSAKey).size() <= 1)
                        {
                          
                            mapIdAccListIdBDM_Del.put(eachAccountTeam.MSA_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                        }
                    }
                    else {
                      
                        mapIdAccListIdBDM_Del.put(eachAccountTeam.SFX_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                        mapIdAccListIdBDM_Del.put(eachAccountTeam.MSA_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                    }
                }
             
                //For SFX Un-sharing
                if(!eachAccountTeam.Collection__c && !eachAccountTeam.Submission__c 
                   && (mapOld.get(eachAccountTeam.Id).Collection__c || mapOld.get(eachAccountTeam.Id).Submission__c)
                  )
                {
                    if(mapIdListAT != null && mapIdListAT.size() > 0)
                    {
                        String SFXKey = eachAccountTeam.SFX_Id__c + eachAccountTeam.BDMPropelI__c;
                        if(mapIdListAT.containsKey(SFXKey) && mapIdListAT.get(SFXKey) != null && mapIdListAT.get(SFXKey).size() <= 1)
                        {
                            mapIdAccListIdBDM_Del.put(eachAccountTeam.SFX_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                            setUserId.add(eachAccountTeam.BDMPropelI__c);
                            
                            String MSAKey = eachAccountTeam.MSA_Id__c + eachAccountTeam.BDMPropelI__c;
                            if(mapIdListAT.containsKey(MSAKey) && mapIdListAT.get(MSAKey) != null && mapIdListAT.get(MSAKey).size() <= 1)
                            {
                                mapIdAccListIdBDM_Del.put(eachAccountTeam.MSA_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                            }
                        }
                    }
                    else {
                        mapIdAccListIdBDM_Del.put(eachAccountTeam.SFX_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                        mapIdAccListIdBDM_Del.put(eachAccountTeam.MSA_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                        setUserId.add(eachAccountTeam.BDMPropelI__c);
                    }
                }
                
                //For MSA Un-sharing
                if((!eachAccountTeam.National1__c && !eachAccountTeam.National2__c && !eachAccountTeam.National3__c && !eachAccountTeam.National4__c && !eachAccountTeam.CRS__c)
                   && (mapOld.get(eachAccountTeam.Id).National1__c || mapOld.get(eachAccountTeam.Id).National2__c || mapOld.get(eachAccountTeam.Id).National3__c 
                       || mapOld.get(eachAccountTeam.Id).National4__c || mapOld.get(eachAccountTeam.Id).CRS__c)
                  )
                {
                    if(mapIdListAT != null && mapIdListAT.size() > 0)
                    {
                        String MSAKey = eachAccountTeam.MSA_Id__c + eachAccountTeam.BDMPropelI__c;
                        if(mapIdListAT.containsKey(MSAKey) && mapIdListAT.get(MSAKey) != null && mapIdListAT.get(MSAKey).size() <= 1)
                        {
                            mapIdAccListIdBDM_Del.put(eachAccountTeam.MSA_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                            setUserId.add(eachAccountTeam.BDMPropelI__c);
                        }
                    }
                    else {
                        mapIdAccListIdBDM_Del.put(eachAccountTeam.MSA_Id__c, new List<String>{eachAccountTeam.BDMPropelI__c});
                        setUserId.add(eachAccountTeam.BDMPropelI__c);
                    }
                }
            }
          
            
            //Deleting Sharing
            if(setAccountId != null && setAccountId.size() > 0 && mapIdAccListIdBDM_Del != null && mapIdAccListIdBDM_Del.size() > 0)
            {
                String rowCause = Label.Sharing_Row_Cause != null ? Label.Sharing_Row_Cause : 'Owner,Team,Rule,ImplicitParent';
                
                Set<String> setSharingRowCause = new Set<String>();
                if(rowCause.contains(',')) {
                    for(String eachRowCause : rowCause.split(',')) {
                        setSharingRowCause.add(eachRowCause.trim());
                    }
                }
                else {
                    setSharingRowCause.add(rowCause);
                }
                
                List<AccountShare> lstExitingAccountShare = [SELECT Id, AccountId, UserORGroupId FROM AccountShare 
                                                             WHERE AccountId IN :mapIdAccListIdBDM_Del.keySet() AND UserORGroupId IN :setUserId AND RowCause NOT IN :setSharingRowCause];
              
                List<String> accIds = new List<String>();
                if(lstExitingAccountShare != null && lstExitingAccountShare.size() > 0)
                {
                    for(AccountShare eachExistingShare : lstExitingAccountShare)
                    {
                        String accountId = String.valueOf(eachExistingShare.AccountId).substring(0, 15);
                        accIds.add(accountId);
                    }
                }
                List<Account_Team__c> lstExistingTeam1 = [SELECT Id, Relationship__c, SFX_Id__c 
                                                          FROM Account_Team__c 
                                                          WHERE 
                                                          Account__r.Parent.Parent.id IN : accIds AND Account__r.RecordType.Name = 'Rate Card' AND Relationship__c = true
                                                         ];
                // System.debug('lstExistingTeam1 '+lstExistingTeam1);
                Map<String, List<Account_Team__c>> mapSfxListAT = new Map<String, List<Account_Team__c>>();
                for(Account_Team__c eachTeam : lstExistingTeam1)
                {
                    String sfxKey = eachTeam.SFX_Id__c;
                    if(!mapSfxListAT.containsKey(sfxKey))
                    {
                        mapSfxListAT.put(sfxKey, new List<Account_Team__c>{});
                    }
                    mapSfxListAT.get(sfxKey).add(eachTeam);
                }
                // System.debug('mapSfxListAT '+mapSfxListAT);
                
                if(lstExitingAccountShare != null && lstExitingAccountShare.size() > 0)
                {
                    List<AccountShare> lstAccountTODelete = new List<AccountShare>();
                    
                    for(AccountShare eachExistingShare : lstExitingAccountShare)
                    {
                        String accountId = String.valueOf(eachExistingShare.AccountId).substring(0, 15);
                        if(mapIdAccListIdBDM_Del.containsKey(accountId) && mapIdAccListIdBDM_Del.get(accountId) != null
                           && mapIdAccListIdBDM_Del.get(accountId).contains(String.valueOf(eachExistingShare.UserORGroupId)) &&
                           !(mapSfxListAT != null && mapSfxListAT.containsKey(accountId) && mapSfxListAT.get(accountId) != null)
                          )
                        {
                            lstAccountTODelete.add(eachExistingShare);
                        }
                    }
                    // System.debug('---- lstAccountTODelete: ' + lstAccountTODelete);
                    //// System.debug('---- lstAccountTODelete1: ' + lstAccountTODelete[1].AccountId);
                    
                    if(lstAccountTODelete.size() > 0)
                    {
                        delete lstAccountTODelete;
                    }
                }
            }
        }
        
        //Inserting Account Sharing with BDM User.
        // System.debug('---- trg_ATHelper 325 lstAccountShare: ' + lstAccountShare);
        if(lstAccountShare != null && lstAccountShare.size() > 0)
        {
            //insert lstAccountShare;
            Database.SaveResult[] results = Database.insert(lstAccountShare, false);
            // iterate over the list of returned results
            for(Database.SaveResult result : results) {
                if(result.isSuccess()) {
                    // System.debug('Successfully inserted Accounts : ' + result.getId());
                } else {
                    // iterate over the failed ones
                    for(Database.Error error : result.getErrors()) {
                        ExceptionHandling.Exception( 'trg_AccountTeamHelper', 'afterUpdate_AccountSharing', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                        // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                    }
                }
            }
        }
    }
    
    static AccountShare shareAccount(String strAccountId, Id strUserId)
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
    
    // SAC-662 | Deepika (IBM ) | Create on-boarding task by selecting multiple AT from list view.
    @InvocableMethod(callout=true label='Create OnboardingTask')    
    public static void onboardingTaskFromATList(List<List<Account_Team__c>> accTeam){
        // if(accTeam.get(0).size()>0)
        onboardingTask(accTeam.get(0), true, 1);
    }
    
    // SAC-662 | Deepika (IBM ) | Updated on-boarding task logic after mapping in propel-I portfolio.
    public static Map<String, Integer> onboardingTask(List<Account_Team__c> accTeam ,Boolean bulkOnBoardingTaskCreation/*, Boolean updateTaskAssignee */,
                                                      Integer taskType){
                                                        System.debug('accTeam'+accTeam);
                                                        System.debug('bulkOnBoardingTaskCreation'+bulkOnBoardingTaskCreation);
                                                          Map<String, Integer> result = new Map<String, Integer>();
                                                          try{
                                                              List<String> accTeamNameList = new List<String>();// store account name of AccountTeam.
                                                              //  Set<String> checkTaskString = new Set<String>(); //add billing branch and sfx combination.
                                                              Set<String> sfxSet = new Set<String>();
                                                              Set<String> branchSet = new Set<String>();
                                                              Set<String> branchSfxSet = new Set<String>();
                                                              Map<String, String> bdmFromAT 	= new Map<String, String>();
                                                              Map<Task, Id> tasksToBeUpdated = new Map<Task, Id>();
                                                              Map<String, Account_Team__c> originalData = new Map<String, Account_Team__c>();
                                                              Map<String,String> branchParentIdMap = new Map<String,String>(); //store branch and branchparentid combination.
                                                              Id recordTypeId1 = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('On_Boarding').getRecordTypeId();
                                                              Id recordTypeId2 = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Customer_Relationship_Profiling_Tasks').getRecordTypeId();
                                                              
                                                              if(accTeam.size() >0){
                                                                  // System.debug(' accTeam: '+accTeam);
                                                                  for(Account_Team__c accte : [SELECT Id, Account__c, Name, Account_Name__c, Relationship__c,Account__r.Name, Account__r.Account_Name__c, 
                                                                                               CreatedDate, BDMPropelI__c, Account__r.SFX__c, Account__r.Parent.Parent.Status__c, Account__r.ParentId, Account__r.Parent.Name,Account__r.Parent.Parent.ParentId, 
                                                                                               Account__r.Parent.Parent.Parent.Name,Account__r.Parent.Parent.Customer_Category__c, PropelI_Composite_Key__c, Assigned_Branch__r.Opt_Out_for_Customer_Relationship_Profil__c 
                                                                                               FROM Account_Team__c Where Id IN : accTeam And Relationship__c = true/* And CreatedDate = TODAY*/]){
                                                                                                   System.debug('i am here ');

                                                                                                   String sfx 			= (String.isNotEmpty(accte.Account__r.SFX__c)) ? accte.Account__r.SFX__c:''; 
                                                                                                   String BDM_PropelI 	= (String.isNotEmpty(accte.BDMPropelI__c)) ? accte.BDMPropelI__c :'';
                                                                                                   String compositeKey = (String.isNotEmpty(accte.PropelI_Composite_Key__c)) ? accte.PropelI_Composite_Key__c : '';
                                                                                                    System.debug('sfx '+ sfx);
                                                                                                    System.debug('BDM_PropelI'+ BDM_PropelI);
                                                                                                    //String branchName = compositeKey.split(':@').size() > 0 ? compositeKey.split(':@')[0].substringAfter('-') : '';
                                                                                                   String braName 		= compositeKey.substringBefore(':@');
                                                                                                   String branchName 	= braName.substringAfter('-');
                                                                                                   // System.debug('braName'+braName);
                                                                                                    // System.debug('branchName'+branchName);

                                                                                                   if(String.isNotEmpty(branchName)){
                                                                                                       String combination = sfx+'::'+branchName/*+'::'+BDM_PropelI*/;
                                                                                                       bdmFromAT.put(combination, BDM_PropelI);
                                                                                                       originalData.put(combination, accte);
                                                                                                       branchSfxSet.add(combination);
                                                                                                       sfxSet.add(sfx);
                                                                                                       branchSet.add(branchName);
                                                                                                   }
                                                                                               }
                                                                  Set<String> branchesmappedAlready = new Set<String>();
                                                                  
                                                                  for(Task tsk : [SELECT Id,Account.Name,Booking_branch__c, SFX_Code__c, WhatId, OwnerId, RecordType.Name FROM Task Where /*Account.Name LIKE '%SFX%' and*/  Status!='Completed' and Booking_branch__c In: branchSet and SFX_Code__c In: sfxSet and (RecordType.Id =: recordTypeId1 OR RecordType.Id =: recordTypeId2) limit 9999]){
                                                                      // System.debug(' accTask: '+tsk);
                                                                      
                                                                      if(branchSfxSet.contains(tsk.SFX_Code__c+'::'+tsk.Booking_branch__c/*+'::'+tsk.OwnerId*/)){
                                                                          if(bdmFromAT.get(tsk.SFX_Code__c+'::'+tsk.Booking_branch__c) != tsk.OwnerId){
                                                                              System.debug('bdmFromAT.get(tsk.SFX_Code__c+tsk.Booking_branch__c)--->'+bdmFromAT.get(tsk.SFX_Code__c+'::'+tsk.Booking_branch__c));
                                                                              tasksToBeUpdated.put(tsk, bdmFromAT.get(tsk.SFX_Code__c+'::'+tsk.Booking_branch__c));
                                                                          }
                                                                          //     checkTaskString.add(tsk.SFX_Code__c+'::'+tsk.Booking_branch__c/*+'::'+tsk.OwnerId*/);
                                                                      }
                                                                      if(bulkOnBoardingTaskCreation){
                                                                          branchesmappedAlready.add(tsk.Booking_branch__c);
                                                                      }
                                                                  }
                                                                  
                                                                  if(tasksToBeUpdated.size()>0){
                                                                      System.debug('tasksToBeUpdated');
                                                                      updateOnBoardingTasksAssignee(tasksToBeUpdated);
                                                                  }
                                                                  
                                                                  Set<String> branchSFXToBeUpdated = new Set<String>();
                                                                  Set<String> branchSFXSetForProfiling = new Set<String>();
                                                                  List<Account> accountToUpdateIsMapping = new List<Account>();
                                                                  // System.debug('sfxSet'+sfxSet);
                                                                  // System.debug('branchSet'+branchSet);
                                                                  for(Account acc : [SELECT Id, Name, IsMappingDone__c, Billing_Branch__r.Name, rate_card_id__c, SFX__c, SFX_CODE_STATUS__c FROM Account 
                                                                                     Where SFX__c In: sfxSet AND Name LIKE 'ASSIGN BRANCH%' AND Billing_Branch__r.Name In: branchSet]){
                                                                                         // Split the string based on the delimiter ":"
                                                                                         // String rateCardName = acc.Name.substringAfter(':').substringBefore('-');
                                                                                         String SFXName      = acc.Name.substringAfter(':').substringAfter('-');
                                                                                          System.debug('SFXName'+SFXName);
                                                                                         /*if(!bulkOnBoardingTaskCreation){
branchSFXSetForProfiling.add(SFXName+'::'+acc.Billing_Branch__r.Name);
}*/
                                                                                         if (!acc.IsMappingDone__c||bulkOnBoardingTaskCreation){
                                                                                             // System.debug(' branchesmapping: '+bulkOnBoardingTaskCreation);
                                                                                             acc.IsMappingDone__c = true;
                                                                                             branchSFXToBeUpdated.add(SFXName+'::'+acc.Billing_Branch__r.Name);
                                                                                         } else if(acc.IsMappingDone__c){
                                                                                             branchesmappedAlready.add(acc.Billing_Branch__r.Name);
                                                                                         }
                                                                                         
                                                                                         
                                                                                         accountToUpdateIsMapping.add(acc);
                                                                                     }
                                                                  
                                                                  
                                                                  
                                                                  //Integer count = 0;
                                                                  //In case of branch extension, skip creating task on branches which are checked already
                                                                  if(taskType!=2){
                                                                      for(String branchMapped : branchSFXToBeUpdated){
                                                                          String[] billBranch = branchMapped.split('::');
                                                                          if(branchesmappedAlready.contains(billBranch[1])){
                                                                              branchSFXToBeUpdated.remove(branchMapped);
                                                                          }
                                                                          //count++;
                                                                      }
                                                                  }    
                                                                  
                                                                  branchSfxSet = branchSFXToBeUpdated;
                                                                  
                                                                  Set<String> sfxName = sfxSet(branchSfxSet);
                                                                  
                                                                  Map< String, String> sfxIDNameSet = new Map<String, String>();
                                                                  for(Account acc : [SELECT Id, SFX_code__c  FROM Account WHERE SFX_code__c In: sfxName AND RecordType.DeveloperName='Actual_SFX']){
                                                                      sfxIDNameSet.put(acc.SFX_code__c,acc.Id);
                                                                  }
                                                                  
                                                                  
                                                                  /*Set<String> sfxName1 = sfxSet(branchSFXSetForProfiling);

Map< String, String> sfxIDNameSet1 = new Map<String, String>();
for(Account acc : [SELECT Id, SFX_code__c  FROM Account WHERE SFX_code__c In: sfxName1 AND RecordType.DeveloperName='Actual_SFX']){
sfxIDNameSet1.put(acc.SFX_code__c,acc.Id);
}*/
                                                                  
                                                                  result = createOnBoardingTasks(branchSfxSet,/*checkTaskString,*/ originalData, sfxIDNameSet, 
                                                                                                 recordTypeId1,/* rateCardDetails,*/ accountToUpdateIsMapping, taskType
                                                                                                 /*branchSFXSetForProfiling,sfxIDNameSet1*/);   
                                                                  
                                                                  // System.debug('result'+result);
                                                              }
                                                          }catch(Exception e){
                                                              System.debug('Exception:'+e.getMessage());
                                                              System.debug('<<< error line number >>>'+e.getLineNumber());
                                                          } 
                                                          return result;
                                                      }
    
    
    //  SAC-662 | Deepika (IBM ) | Prepare SFX set against which we need to create onboarding Tasks
    public static Set<String> sfxSet(Set<String> branchSfxSet){
        Set<String> sfxName = new Set<String>();
        if(!branchSfxSet.isEmpty()){
            for(String str : branchSfxSet){
                // System.debug ('branchSfxSet  : ' + str);
                String [] strcase1 = str.split('::');
                sfxName.add(strcase1[0]);
            }
        }
        return sfxName;
    }
    
    //  SAC-662 | Deepika (IBM ) | Create Onboarding Tasks if they don't exist
    public static Map<String, Integer> createOnBoardingTasks(Set<String> branchSfxSet, 
                                                             //  Set<String> checkTaskString,
                                                             Map<String, Account_Team__c> originalData,
                                                             Map< String, String> sfxIDNameSet,
                                                             Id recordTypeId,
                                                             //Set<String> rateCardDetails,
                                                             List<Account> accountToUpdateIsMapping, 
                                                             Integer taskType
                                                             /*Set<String> branchSfxSet1,
Map< String, String> sfxIDNameSet1*/)
    {
        System.debug('branchSfxSet : '+branchSfxSet);
         System.debug('taskType : '+taskType);
       // System.debug('branchSfxSet : '+branchSfxSet1);
        //Boolean onlyCreateProfilingTask=false;
        List<Task> addTaskList = new List<Task>(); //store new on-boarding task.
        List<Task> addProfilingList = new List<Task>(); //store new on-boarding task.
        /*if(branchSfxSet.isEmpty()){
// System.debug('inside loop');
onlyCreateProfilingTask = true;
branchSfxSet = branchSfxSet1;
sfxIDNameSet = sfxIDNameSet1;
}*/
        Map<Task,String> mapOfStatusAndTask = new Map<Task,String>();
        if(!branchSfxSet.isEmpty()){
            for(String str : branchSfxSet){
                // System.debug ('branchSfxSet  : ' + str);
                // System.debug('originalData : '+originalData);
                //   if(!checkTaskString.contains(str)){
                String [] strcase1 = str.split('::');
                if(strcase1.size()>0 && strcase1[1] != null && strcase1[0] != null && originalData.containsKey(str) && originalData.get(str) != null){
                    Task ts = new Task();
                    ts.Account_Name__c = originalData.get(str).Account__r.Account_Name__c;
                    datetime dt = originalData.get(str).CreatedDate;
                    // ts.ActivityDate = Date.newInstance(dt.year(), dt.month(), dt.day())+2;
                    ts.ActivityDate = Date.today().addDays(2); // SAC-795 | Deepika Thakur
                    ts.OwnerId = originalData.get(str).BDMPropelI__c; 
                    ts.Priority = 'High';
                    ts.RecordTypeId = recordTypeId;
                    ts.SFX_Code__c = strcase1[0]; 
                    ts.Status = 'Open';
                    ts.Subject = 'Onboarding Task';
                    ts.Booking_branch__c = strcase1[1];
                    ts.WhatId = sfxIDNameSet.get(strcase1[0]);
                    ts.MSA_Master_Service_Agreement__c = originalData.get(str).Account__r.Parent.Parent.Parent.Name;
                    ts.Customer_Account_SFX_codes__c = strcase1[0];
                    ts.Booking_branch__c = strcase1[1];
                    ts.Customer_Category__c = originalData.get(str).Account__r.Parent.Parent.Customer_Category__c;
                    System.debug ('Task Category : ' + originalData.get(str).Account__r.Parent.Parent.Customer_Category__c);
                    addTaskList.add(ts);
                    if(!(originalData.get(str).Assigned_Branch__r.Opt_Out_for_Customer_Relationship_Profil__c))
                        addProfilingList.add(ts);
                    mapOfStatusAndTask.put(ts,originalData.get(str).Account__r.Parent.Parent.Status__c);
                    System.debug('mapOfStatusAndTask**'+mapOfStatusAndTask);
                } 
                // }
            }
        }
        // System.debug('addProfilingList'+addProfilingList);
         System.debug('addTaskList'+addTaskList);
        if(addTaskList.size()>0){
            if(taskType ==1 ||taskType ==3){
                //// System.debug('inside onlyCreateProfilingTask : '+onlyCreateProfilingTask);
                // if(!onlyCreateProfilingTask)
                insert addTaskList;
                List<Database.SaveResult> data =  Database.Update(accountToUpdateIsMapping,false);
                
            }
        }
        
        Map<String, Integer> result = new Map<String, Integer>();
        if(addProfilingList.size()>0 && (taskType ==2 ||taskType ==3)){
            // System.debug('taskType insideif'+taskType);
            result = createCustomerProfilingTask(addProfilingList, taskType,mapOfStatusAndTask);
        }  
        else if(addProfilingList.size() == 0){
            result.put('noChange', 5);
        }
        return result;
    }
    
    //  SAC-662 | Deepika (IBM ) | If the Account Team BDM is updated, tasks assignee should be updated
    public static void updateOnBoardingTasksAssignee(Map<Task, Id> tasksToBeUpdated){
        List<Task> listToBeUpdated = new List<Task>();
        for (Task tsk : tasksToBeUpdated.keySet()) {
            tsk.OwnerId = tasksToBeUpdated.get(tsk); 
            listToBeUpdated.add(tsk);
        }
        // System.debug ('listToBeUpdated Task  : ' + listToBeUpdated);
        if(listToBeUpdated.size()>0){
            update listToBeUpdated;
        }
    }
    
    //  SAC-1390 | Deepika (IBM ) | Create Customer Profiling Task
    public static Map<String, Integer> createCustomerProfilingTask(List<Task> onboardingTaskList, Integer taskType,Map<Task,String> mapOfStatusAndTask){
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Customer_Relationship_Profiling_Tasks').getRecordTypeId();
        List<Task> addTaskList = new List<Task>(); 
        List<Task> updateTaskList = new List<Task>();
        
        
        // Step 1: Create a map of unique SFX + branch to identify duplicates
        Set<String> uniqueKeys = new Set<String>();
        for (Task task : onboardingTaskList) {
            String key = task.SFX_Code__c + '::' + task.Booking_branch__c;
            uniqueKeys.add(key);
        }
        
        // Step 2: Query existing tasks with same record type, SFX, and branch
        List<Task> existingTasks = [
            SELECT Id, SFX_Code__c, Booking_branch__c, OwnerId
            FROM Task
            WHERE RecordTypeId = :recordTypeId
            AND SFX_Code__c != null
            AND Booking_branch__c != null
            AND Status != 'Completed'
        ];
        // System.debug('existingTasks 1:::'+existingTasks);
        Map<String, Task> existingTaskMap = new Map<String, Task>();
        if(taskType==2||taskType==3){
            for (Task t : existingTasks) {
                String key = t.SFX_Code__c + '::' + t.Booking_branch__c;
                // System.debug('existingTasks 2:::'+key);
                if (!existingTaskMap.containsKey(key)) {
                    existingTaskMap.put(key, t);
                    // System.debug('existingTasks 3:::'+existingTaskMap);
                    
                }
            }
        }
        
        // Step 3: Fetch profiling frequency metadata
        Map<String, Decimal> categoryToFrequencyMap = new Map<String, Decimal>();
        for (CustomerRelationshipProfilingFrequency__mdt mdt : [
            SELECT Customer_Category__c, Frequency_In_days__c 
            FROM CustomerRelationshipProfilingFrequency__mdt
        ]) {
            categoryToFrequencyMap.put(mdt.Customer_Category__c, mdt.Frequency_In_days__c);
        }
        Map<String, Integer> result = new Map<String, Integer>();
        for(Task task : onboardingTaskList){
            // System.debug('existingTasks 4:::'+task);
            String key = task.SFX_Code__c + '::' + task.Booking_branch__c;
            // System.debug('existingTasks 5:::'+key);
            if (existingTaskMap.containsKey(key)) {
                // Update existing task owner
                Task existing = existingTaskMap.get(key);
                existing.OwnerId = task.OwnerId;
                updateTaskList.add(existing);
                // System.debug('existingTasks 6:::'+key);
            } else if(taskType==2 && mapOfStatusAndTask.get(task) == 'Active'){
                // Create new profiling task
                Date dueDate = Date.today().addDays(3);
                // System.debug('existingTasks 7:::');
                
                Task ts = new Task();
                ts.MSA_Master_Service_Agreement__c = task.MSA_Master_Service_Agreement__c;
                ts.Customer_Account_SFX_codes__c = task.Customer_Account_SFX_codes__c;
                ts.Booking_branch__c = task.Booking_branch__c;
                ts.ActivityDate = dueDate;
                ts.Customer_Category__c = task.Customer_Category__c;
                if (categoryToFrequencyMap.containsKey(task.Customer_Category__c)) {
                    Decimal frequencyDaysDecimal = categoryToFrequencyMap.get(task.Customer_Category__c);
                    Integer frequencyDays = frequencyDaysDecimal != null ? frequencyDaysDecimal.intValue() : 0;
                    ts.CustomeProfilingTaskNextCreationDate__c = Date.today().addDays(frequencyDays);
                }
                ts.Status = 'Open';
                ts.Subject = 'Customer Relationship Profiling Task';
                ts.WhatId = task.WhatId;
                ts.Account_Name__c = task.Account_Name__c;
                ts.OwnerId = task.OwnerId; 
                ts.Priority = 'High';
                ts.SFX_Code__c = task.SFX_Code__c; 
                ts.RecordTypeId = recordTypeId;
                addTaskList.add(ts); 
            }
        }
        
        
        // Step 5: DML operations
        if (!updateTaskList.isEmpty()) {
            update updateTaskList;
            //result.put('updated',1);
            
        }
        if (!addTaskList.isEmpty()) {
            insert addTaskList;
            result.put('inserted',1);
        }
        if(addTaskList.isEmpty()) {
            result.put('noChange', 5);
        }
        return result;
        
    }
    // Added by Anand Raju SAC-1812 To display last event date on update of accounts team 
    
    public static void populateLastEventDate(List<Account_Team__c> newList) {
        Set<Id> rootAccountIds = new Set<Id>();
        Set<Id> bdmUserIds = new Set<Id>();
        Set<Id> setAccIds = new Set<Id>();
        
        // Step 1: Collect BDM and related root account Ids
        for (Account_Team__c team : newList) {
            if (team.Account__c != null && team.BDMPropelI__c != null) {
                bdmUserIds.add(team.BDMPropelI__c);
                setAccIds.add(team.Account__c);
            }
        }
        
        // Step 2: Query Parent.Parent Ids for the teams
        Map<Id, Id> teamIdToRootAccountId = new Map<Id, Id>();
        
        List<Account_Team__c> teamsWithParents = [
            SELECT Id, Account__c, Account__r.Parent.Id, Account__r.Parent.Parent.Id
            FROM Account_Team__c
            WHERE Account__c IN :setAccIds
        ];
                
        for (Account_Team__c team : teamsWithParents) {
            if (team.Account__r != null &&
                team.Account__r.Parent != null &&
                team.Account__r.Parent.Parent != null) {
                    teamIdToRootAccountId.put(team.Id, team.Account__r.Parent.Parent.Id);
                    rootAccountIds.add(team.Account__r.Parent.Parent.Id);
                }
        }
        
        if (rootAccountIds.isEmpty() || bdmUserIds.isEmpty()) return;
        
        // Step 3: Query recent events for those root accounts and BDMs
        List<Event__c> recentEvents = [
            SELECT Id, Account__c, OwnerId, CreatedDate
            FROM Event__c
            WHERE Account__c IN :rootAccountIds
            AND OwnerId IN :bdmUserIds
            ORDER BY CreatedDate DESC
        ];
        
        // Step 4: Build map of (AccountId + OwnerId) => latest Event
        Map<String, Event__c> latestEventMap = new Map<String, Event__c>();
        for (Event__c evt : recentEvents) {
            String key = evt.Account__c + '-' + evt.OwnerId;
            if (!latestEventMap.containsKey(key)) {
                latestEventMap.put(key, evt);
            }
        }
        
        // Step 5: Set LastEventDate__c on trigger records
        for (Account_Team__c team : newList) {
            if (team.BDMPropelI__c == null || !teamIdToRootAccountId.containsKey(team.Id)) continue;
            
            Id rootAccountId = teamIdToRootAccountId.get(team.Id);
            String key = rootAccountId + '-' + team.BDMPropelI__c;
            if (latestEventMap.containsKey(key)) {
                team.LastEventDate__c = latestEventMap.get(key).CreatedDate; // Assuming Date type
            } else {
                team.LastEventDate__c = null;
            }
        }
    }
    
}