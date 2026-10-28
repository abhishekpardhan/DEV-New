/**
* Description      :   Trigger on Account_Team__c object to perform various tasks upon different DML Operations by calling helper class methods
* JIRA ticket    : SD-485
* 
* Revision Logs    :   V_1.0 - Created
* 
**/
trigger trg_AccountTeam on Account_Team__c (before insert, after insert, before update,after update, after delete) {
    
   
    if(System.Label.TriggerSwitch.equals('On'))
    {
        if(trigger.isInsert && !cls_propelIBDMReport.stopAccountTeamTriggerPostInsert)
            return;
        if(trigger.isupdate && !cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate)
            return;
        if(trigger.isbefore && trigger.isInsert){
            List<Id> lstAccountId = new List<Id>();
            if(checkRecursive.isFirstRun()){
                List<Id> lstAccId = new List<Id>();
                List<Id> lstAccId2 = new List<Id>();
                List<Account_Team__c> lstATeam = new List<Account_Team__c>();
                for(Account_Team__c at: trigger.new){
                    // System.debug('sfxcode+++:'+at.Account__c);
                    if((at.National1__c || at.National2__c || at.National3__c || at.National4__c)  && at.BDM__c != null){
                        // System.debug('chk-++'+at.National1__c);
                        lstATeam.add(at);
                        lstAccId2.add(at.Account__c);
                    }
                    lstAccId.add(at.Account__c);
                }
                //Update Account collecton/relationship stc when new AccountTeam insert.
                if(!lstAccId.isEmpty()){
                    helperAccountTeam.updateAccountNewAT(trigger.new,lstAccId);
                }
                //New ATeam having National1,2,3 checked and checked all other accounts of that SFX code.
                if(!lstATeam.isEmpty()){
                    helperAccountTeam.newATNational(lstATeam,lstAccId2);
                }
            }
            
            for(Account_Team__c at: trigger.new){
                lstAccountId.add(at.Account__c);
            }
            if(!lstAccountId.isEmpty()){
                helperAccountTeam.updateAccountonNewATeam(trigger.new,lstAccountId);
            }
            // Changes as per JIRA #1832 (Method is used to update the task created status )
            // trg_AccountTeamHelper.updateTaskCreated(Trigger.new);
            trg_AccountTeamHelper.populateLastEventDate(trigger.new);
        }
        
        if(trigger.isbefore && trigger.isUpdate){
            List<Id> lstId = new List<Id>();
            boolean frun = checkRecursive.isFirstRun();
            // System.debug('frun++'+frun);
            List<Account_Team__c> updateCompositeKeyList = new List<Account_Team__c>();
            if(frun){ //checkRecursive.isFirstRun()
                // System.debug('++inside'+frun);              
                List<Id> lstIdremoveNationals = new List<Id>();
                List<Id> lstIdaddedNationals = new List<Id>();                
                //List to store ateam if ccd,local-nam,qrm and rm is removed on update.
                List<Account_Team__c> lstNationalsRemove = new List<Account_Team__c>();
                List<Account_Team__c> lstNationalsAdded = new List<Account_Team__c>();
                
                for(Account_Team__c at: trigger.new){
                    // System.debug('2++');
                    //If nationals remove on accountteam update
                    if((at.National1__c != trigger.oldmap.get(at.Id).national1__c && at.National1__c == false) ||
                       (at.National2__c != trigger.oldmap.get(at.Id).national2__c && at.National2__c == false) ||
                       (at.National3__c != trigger.oldmap.get(at.Id).national3__c && at.National3__c == false) ||
                       (at.National4__c != trigger.oldmap.get(at.Id).national4__c && at.National4__c == false)){
                           // System.debug('3++');
                           lstNationalsRemove.add(at);
                           lstIdremoveNationals.add(at.Account__c);
                       }
                    
                    //If nationals added on accountteam update
                    if((at.National1__c != trigger.oldmap.get(at.Id).national1__c && at.National1__c == true) ||
                       (at.National2__c != trigger.oldmap.get(at.Id).national2__c && at.National2__c == true) ||
                       (at.National3__c != trigger.oldmap.get(at.Id).national3__c && at.National3__c == true) ||
                       (at.National4__c != trigger.oldmap.get(at.Id).national4__c && at.National4__c == true)){
                           // System.debug('nationalUpdated++');
                           // System.debug('4++');
                           lstNationalsAdded.add(at);
                           lstIdaddedNationals.add(at.Account__c);
                       }
                    
                }              
                
                if(!lstNationalsRemove.isEmpty()){
                    // System.debug('5++');
                    helperAccountTeam.removeNationalsInAccTeamUpdate(lstNationalsRemove,trigger.oldmap,lstIdremoveNationals); 
                }
                if(!lstNationalsAdded.isEmpty()){
                    // System.debug('nationalUpdated2++');
                    // System.debug('6++');
                    // System.debug('lstNationalsAdded++'+lstNationalsAdded+'size+'+lstNationalsAdded.size());
                    // System.debug('lstIdaddedNationals++'+lstIdaddedNationals+'size++'+lstIdaddedNationals.size());
                    helperAccountTeam.addedNationalsInAccTeamUpdate(lstNationalsAdded,trigger.oldmap,lstIdaddedNationals); 
                }
                
            }
            Set<String> userIds = new Set<String>();
            List<Account_Team__c> listupdatedAccountTeam = new List<Account_Team__c>();
            for(Account_Team__c att: trigger.new){
                if(att.BDMPropelI__c != trigger.oldmap.get(att.Id).BDMPropelI__c){
                    listupdatedAccountTeam.add(att);
                    userIds.add(att.BDMPropelI__c);
                }
            }
            Map<Id, User> inactiveUserMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN : userIds AND isActive = false]);
             
            for(Account_Team__c att: trigger.new){
                lstId.add(att.Account__c);
                
                // Added By  - K SANSI, SAC-547, update the composite key if BDM is changed
                if(att.BDMPropelI__c != trigger.oldmap.get(att.Id).BDMPropelI__c){
                    updateCompositeKeyList.add(att);
                    // System.debug('updateCompositeKeyList-->'+updateCompositeKeyList);
                    if(inactiveUserMap.containsKey(att.BDMPropelI__c) ){
                        att.addError('In active user not allowed to transfer rights!');
                    }
                }
            }
            //To update the Account with relationship/coll etc when AccountTeam updated. 
            if(!lstId.isEmpty()){       
                helperAccountTeam.updateAccount(trigger.new,trigger.oldmap,lstId); // should be in after insert sahil jain
            }
            
            // Added By  - K SANSI, SAC-547, update the composite key if BDM is changed
            if(updateCompositeKeyList.size() > 0){
                helperAccountTeam.updateCompositeKey(updateCompositeKeyList);
                // System.debug('updateCompositeKey method called');
            }
            
            // Changes as per JIRA #1832 (Method is used to update the task created status )
            // trg_AccountTeamHelper.updateTaskCreated(listupdatedAccountTeam);
            if(!listupdatedAccountTeam.isEmpty()){
                trg_AccountTeamHelper.populateLastEventDate(listupdatedAccountTeam);
            }

        }
        
        if(trigger.isafter && trigger.isUpdate){
            //if(checkRecursive.isFirstRun()){
            List<Id> lstAccId = new List<Id>();
            List<Id> lstIds = new List<Id>();
            List<Account_Team__c> lstremoveATsharing = new List<Account_Team__c>();
            List<Account_Team__c> updateCompositeKeyList = new List<Account_Team__c>();
            //List<Account_Team__c> updateCompositeKeySubmissionCollectionList = new List<Account_Team__c>();
            Map<String, List<Account_Team__c>> accountTeamMap = new Map<String, List<Account_Team__c>>();
            List<Id> lstBDM = new List<Id>();//Mon
            for(Account_Team__c at: trigger.new){
                // System.debug('at --> '+at);
                // System.debug('trigger.oldmap.get(at.Id) --> '+trigger.oldmap.get(at.Id));
                if(at.Collection__c == false && at.Relationship__c == false && at.Submission__c == false &&
                   at.National1__c == false && at.National2__c == false && at.National3__c == false && at.National4__c == false && at.CRS__c == false && at.NSM__c == false){
                       lstIds.add(at.Id);
                       lstremoveATsharing.add(at);
                       lstAccId.add(at.Account__c);
                       lstBDM.add(at.BDM__c); //Mon
                   }
                
                // Added By  - K SANSI, SAC-547, update the composite key on PropelI BDM if BDM is changed  
                if(at.BDMPropelI__c != trigger.oldmap.get(at.Id).BDMPropelI__c){
                    updateCompositeKeyList.add(at);
                   if(!accountTeamMap.containsKey(at.Account__c)){
                        accountTeamMap.put(at.Account__c, new List<Account_Team__c>());
                    }
                    accountTeamMap.get(at.Account__c).add(at);
                   // System.debug('accountTeamMap--->'+accountTeamMap);
                }
                //if(at.BDMPropelI__c != trigger.oldmap.get(at.Id).BDMPropelI__c || at.Submission__c != trigger.oldmap.get(at.Id).Submission__c || at.Collection__c != trigger.oldmap.get(at.Id).Collection__c){
                //  updateCompositeKeySubmissionCollectionList.add(at);
                //}
                
            }
            
            //To remove the sharing and delete the Account Team if all checkboxes removed.
            if(!lstremoveATsharing.isEmpty()){
                helperAccountTeam.removeSharing(lstremoveATsharing,lstAccId,lstIds,lstBDM); //lstBM added by Monika on 14 Nov,2019
            }
            //}
            
            // Added By  - K SANSI, SAC-547, update the composite key on PropelI BDM if BDM is changed 
            if(updateCompositeKeyList.size() > 0){                  
                //helperAccountTeam.updateAccountShare(updateCompositeKeyList, Trigger.oldMap);
                // Added By  - Deepika, SAC-662, update assignee details on task if BDM is changed 
                trg_AccountTeamHelper.onboardingTask(updateCompositeKeyList, false, 3); //call this method to update onboarding task.
            }
            //// System.debug('updateCompositeKeySubmissionCollectionList-->'+updateCompositeKeySubmissionCollectionList);
            //if(updateCompositeKeySubmissionCollectionList.size() > 0){
                //helperAccountTeam.updateCompositeKeyOnPropelIBDM(updateCompositeKeySubmissionCollectionList, Trigger.oldMap); 
            //}
           if(accountTeamMap.size() > 0){
                // System.debug('QueableStart---->'+accountTeamMap);
               
               
                AccountTeamQueuable atObject = new AccountTeamQueuable(accountTeamMap, Trigger.oldMap);
                System.enqueueJob(atObject);
            }
        }
        
        // Block is written to share the accounts with assigned BDM team for propel-I system. 
        if(Trigger.isAfter)
        {
            if(Trigger.isInsert && StopRecursion.AccountShare_RunOnce)
            {
                
                StopRecursion.AccountShare_RunOnce = false;
                trg_AccountTeamHelper.afterInsert(Trigger.New);
            }
            
            if(Trigger.isUpdate && StopRecursion.AccountShare_RunOnce)
            {
                StopRecursion.AccountShare_RunOnce = false;
                trg_AccountTeamHelper.afterUpdate(Trigger.New, Trigger.OldMap);
            }
        }
        //added by Adarsh Ranjan
        //Used to send AccountTeam after mapping in propel-I portfolio.
        if(Trigger.isAfter && Trigger.isInsert){
            // System.debug('TEST TEST : '+'onboarding');
            trg_AccountTeamHelper.onboardingTask(Trigger.New, false, 3); //call this method to create onboarding task.
        }
        
        if(Trigger.isAfter && (Trigger.isInsert || Trigger.isDelete /*|| Trigger.isUpdate*/))
        {
            List<Account_Team__c> lstAccountTeams = new List<Account_Team__c>();
            List<Account_Team__c> lstMSAAccountTeams = new List<Account_Team__c>();
            List<Account_Team__c> lstSubCollAccTeams = new List<Account_Team__c>();
            Map<String, List<Account_Team__c>> accountTeamMap = new Map<String, List<Account_Team__c>>();
            Set<String> setRC = new Set<String>();
            Set<String> setSFXs = new Set<String>();
            Id accTeamRecordTypeId = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId(); 
            if(Trigger.isInsert || Trigger.isUpdate)
            {
                // System.debug('here...after insert-->');
                for(Account_Team__c eachAccTeams : Trigger.New)
                {
                    // System.debug('eachAccTeams-->'+eachAccTeams);
                    if(!accountTeamMap.containsKey(eachAccTeams.Account__c)){
                        accountTeamMap.put(eachAccTeams.Account__c, new List<Account_Team__c>());
                    }
                    accountTeamMap.get(eachAccTeams.Account__c).add(eachAccTeams);
                    
                    if(eachAccTeams.RecordTypeId == accTeamRecordTypeId)
                    {
                        if(eachAccTeams.Relationship__c && Trigger.isInsert)
                        {
                            setRC.add(eachAccTeams.Account__c);
                            lstAccountTeams.add(eachAccTeams);
                        }
                        
                        //when CCD, NAM, QRM, CRS, NSM, Revenue Management
                        if(eachAccTeams.National1__c || eachAccTeams.National2__c || eachAccTeams.National3__c || eachAccTeams.National4__c || eachAccTeams.CRS__c || eachAccTeams.NSM__c)
                            lstMSAAccountTeams.add(eachAccTeams);
                        if(eachAccTeams.Collection__c || eachAccTeams.Submission__c)
                        {
                            lstSubCollAccTeams.add(eachAccTeams); 
                            setSFXs.add(eachAccTeams.SFX__c);
                        }  
                    }

                    
                }
                // System.debug('lstAccountTeams------->'+lstAccountTeams);
                // System.debug('lstMSAAccountTeams------->'+lstMSAAccountTeams);
                if(! lstAccountTeams.isEmpty())
                    cls_propelIBDMReport.createRelationshipPropelIBDMMapping(lstAccountTeams, Trigger.oldMap, Trigger.isDelete, Trigger.isInsert, Trigger.isUpdate);
                if(! lstMSAAccountTeams.isEmpty())
                    cls_propelIBDMReport.createMSABDMMapping(lstMSAAccountTeams);
                if(! lstSubCollAccTeams.isEmpty())
                    cls_propelIBDMReport.createSubmissionCollMapping(lstSubCollAccTeams, setSFXs);
                
                // System.debug('accountTeamMap-->'+accountTeamMap);
                if(accountTeamMap.size() > 0){
                    AccountTeamQueuable atObject = new AccountTeamQueuable(accountTeamMap, Trigger.oldMap);
                    System.enqueueJob(atObject);
                }
                
            }
            if(Trigger.isDelete){ 
                // System.debug('is delete -->' + Trigger.Old);
                helperAccountTeam.deleteHierarchyDelete(Trigger.Old);  
                cls_propelIBDMReport.createRelationshipPropelIBDMMapping(lstAccountTeams, Trigger.oldMap, Trigger.isDelete, Trigger.isInsert, Trigger.isUpdate);
            
            }
            
        }
    }
}