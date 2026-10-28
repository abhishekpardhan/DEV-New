/**
 * Description      :   Trigger on Account object to perform various tasks upon different DML Operations by calling helper class methods
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
trigger trg_Account on Account (before Insert ,after insert,before update ,after update, after delete) {
	// bypass trigger
    if(TriggerUtility.byPassTrigger) return ;
	
    //Checking trigger switch values
    if(System.Label.TriggerSwitch.equals('On')){
        
        //Getting different record type Ids present on Account
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        Id rSfxId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        Id actualSFXRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Actual_SFX').getRecordTypeId();
        Id rMSAId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Id rRateId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Rate_card').getRecordTypeId();
        Set<Id> accountProsId = new  Set<Id>();
        if(trigger.isBefore && trigger.isInsert){
            AccountTriggerHelper.updateAccountDetails(Trigger.New);//Converting workflow rule
            //prc account and sfx account get region from branch and booking branch respectively        
            List<Account> lstAccount = new List<Account>();
           
            Set<Id> branchId = new  Set<Id>();
            for(Account acc: trigger.new){            
                if(acc.recordtypeid == rSfxId){                
                   if(!String.isBlank(acc.Booking_Branch__c)){
                       branchId.add(acc.Booking_Branch__c);
                       lstAccount.add(acc);
                    }
                }
              
            } 
            
            //Calling the method of helper class to update the region value according to Selected Booking Branch
            if(branchId.size() > 0){
                AccountTriggerHelper.getBranchName(lstAccount ,branchId);
                //AccountTriggerHelper.ArmFlagChange(lstAccount, branchId); // calling helper method to update the ARM flag in account
                //AccountTriggerHelper.GBAFlagChange(lstAccount, branchId); // calling helper method to update the GBA flag in account
            }
            // calling helper method to update the ARM flag in account
         //   if(lstAccount.size() > 0){
         //   AccountTriggerHelper.updageArmFlag(lstAccount);    
          //  }
          /*  branchId = new  Set<Id>();
            lstAccount = new List<Account>();
            for(Account acc: trigger.new){
                if(acc.recordtypeid == rId){
                    if(!String.isBlank(acc.Branch__c)){
                        branchId.add(acc.Branch__c);
                        lstAccount.add(acc);
                    }
                }
            }*/
           
            //Calling the method of helper class to update the region value according to Selected Booking Branch
           /* if(branchId.size() > 0){
                AccountTriggerHelper.getBranchName(lstAccount ,branchId);
            }*/
        }
        if(trigger.isInsert && trigger.isAfter){
            //System.debug('After Insert ---->');
            
            //AccountTriggerHelper.createBDMMappingTeam(Trigger.New);//Calling for CCD and RM default team creation.
            List<Account> lstAccount = new List<Account>();
            List<Account> lstAccount2 = new List<Account>();
            Set<Id> lstAccountId = new Set<Id>();
            //System.debug('lstAccountId'+lstAccountId);
            List<Id> lstParentId = new List<Id>();
            Set<Id> setBranchId = new Set<Id>();
            accountProsId = new Set<Id>();
            List<Account> LstrateCards = new List<Account>();
            List<String> sfxAccountIds = new List<String>();
            for(Account acc: trigger.new){
                lstAccountId.add(acc.Id);
                if(acc.recordtypeid == rId){
                    lstAccount.add(acc);
                    setBranchId.add(acc.Branch__c);
                }
                
                if(acc.recordtypeid == rRateId){

                    LstrateCards.add(acc);

                }
                
                if(acc.recordtypeid == rSfxId){
                    if(!accountProsId.contains(acc.ParentId)){
                        accountProsId.add(acc.ParentId);
                    }
                    
                    //Added by Prabhsimran for new sfx account nam1 to be updated.
                    if(acc.parentId != null){
                        lstAccount2.add(acc);
                        lstParentId.add(acc.ParentId);
                    }
                }
                if(actualSFXRecordTypeId == acc.recordtypeid){
                    sfxAccountIds.add(acc.Id);
                }
            }
            //System.debug('lstAccountId'+lstAccountId);
           // AccountTriggerHelper.createBDMMappingTeamFuture(lstAccountId);
            // test
           // if(lstAccount.size() > 0){
         //   AccountTriggerHelper.updageArmFlag(trigger.new);    
           // }
            
            //PRC accounts if new added to the branch then give visibility to users of that branch.
            if(lstAccount.size() > 0){
                //AccountTriggerHelper.prcAccountInsert(lstAccount,setBranchId);
            }      
            
            //Calling the helper class method to update'Expiry_Date_Pros__c' field on Parent Accounts
            if(accountProsId.size() > 0){            
               // AccountTriggerHelper.updateProspectAccount(accountProsId);
            }
            //System.debug('After Insert ---->'+LstrateCards);
            if(LstrateCards.size() > 0){
                
                AccountTriggerHelper.updateBaseLoc(LstrateCards,null);

            }   
            if(!lstAccount2.isEmpty()){
               // AccountTriggerHelper.newSFXInsertCheck(lstAccount2,lstParentId);
            }
            if(!sfxAccountIds.isEmpty()){
                AccountTriggerHelper.updateContractRecordType(sfxAccountIds);
            }
            AccountTriggerHelper.updateAccountOnBD(trigger.new);//SAC-1519
        }
        
        if(trigger.isUpdate && trigger.isBefore){
            List<Account> lstAccountArm = new List<Account>();
            List<Account> lstAccount = new List<Account>();
          //  List<Account> LstrateCards = new List<Account>();
            List<Account> lstOldAccount = new List<Account>();
            
            Set<Id> setBranchId = new Set<Id>();
            Set<Id> setOldBranchId = new Set<Id>();
            for(Account acc: trigger.new){
                if(acc.recordtypeid == rId && acc.Branch__c != trigger.oldmap.get(acc.Id).Branch__c){
                    lstAccount.add(acc);
                    lstOldAccount.add(trigger.oldmap.get(acc.Id));
                    setBranchId.add(acc.Branch__c);
                    setOldBranchId.add(trigger.oldmap.get(acc.Id).Branch__c);
                }
                if(acc.GST__c != null && acc.GST_Exempted__c == false) {

                    acc.Pan_No__c = acc.GST__c.substring(2,12);

                }
                 // SC-1182

         /*       if(acc.recordtypeid == rRateId && acc.Base_Location__c != trigger.oldmap.get(acc.Id).Base_Location__c){

                    LstrateCards.add(acc);

                } */
                
            }
            
            //PRC accounts if update to the different branch then give visibility to users of that branch.
            if(lstAccount.size() > 0){
                //AccountTriggerHelper.prcAccountInsert(lstAccount,setBranchId);
            }
            //PRC account if update to new branch then remove the visibility of that account from users of old branch.
            if(lstOldAccount.size() > 0){
                //AccountTriggerHelper.prcAccountRemove(lstOldAccount,setOldBranchId);
            }
            
            //Update the SFX account base location if the Rate Card base Location is updated

          /*  if(LstrateCards.size() > 0){

                AccountTriggerHelper.updateBaseLoc(LstrateCards,trigger.newmap);

                

            }*/
            
            for(Account acc: trigger.new){            
                if(acc.recordtypeid == rSfxId){                
                    if(!String.isBlank(acc.Booking_Branch__c)){
                    lstAccountArm.add(acc);
                    }
                }
            }
            // calling helper method to update the ARM flag in account
        //    if(lstAccountArm.size() > 0){
        //    AccountTriggerHelper.updageArmFlag(lstAccountArm);    
         //   }
            
        }
        if(trigger.isAfter && trigger.isUpdate){
            Set<Id> accountId = new  Set<Id>();
            accountProsId = new Set<Id>();
            List<Account> LstrateCards = new List<Account>();
            List<Account> lstNewAccount = new List<Account>();
            Set<Id> newAccountId = new Set<Id>(); 
            for(Account acc: trigger.new){
                if(acc.recordtypeid == rSfxId){
                   /* if(trigger.oldMap.get(acc.Id).Contract_Expiry_Date__c != null &&  acc.Contract_Expiry_Date__c != trigger.oldMap.get(acc.Id).Contract_Expiry_Date__c){
                        if(acc.Contract_Expiry_Date__c > Date.Today() && Date.Today().daysBetween(acc.Contract_Expiry_Date__c) > 60){
                            accountId.add(acc.Id);
                        }
                    }*/
                    if(acc.Expiry_Date__c != trigger.oldMap.get(acc.Id).Expiry_Date__c && !accountProsId.contains(acc.ParentId)){
                        accountProsId.add(acc.ParentId);
                    }
                }
                if(acc.recordtypeid == rRateId && acc.Base_Location__c != trigger.oldmap.get(acc.Id).Base_Location__c){

                    LstrateCards.add(acc);

                }
                if(acc.Propel_MSACode__c != trigger.oldmap.get(acc.Id).Propel_MSACode__c) {
                    lstNewAccount.add(acc);
                    newAccountId.add(acc.Id);
                }
                if(newAccountId.size() > 0){
                     AccountTriggerHelper.createBDMMappingTeamFuture(newAccountId);
                
            }
            }
            if(accountId.Size() > 0){
                //AccountTriggerHelper.closeTask(accountId);
            }    
            
            //Calling the helper class method to update'Expiry_Date_Pros__c' field on Parent Accounts
            if(accountProsId.size() > 0){
                //AccountTriggerHelper.updateProspectAccount(accountProsId);
            }
            //Update the SFX account base location if the Rate Card base Location is updated
            
            if(LstrateCards.size() > 0){
                
                AccountTriggerHelper.updateBaseLoc(LstrateCards,trigger.newmap);
                
            }
        }
        //SAC 881 || Deepika Thakur || MSA Accounts should not be deleted while merging, MSA should become the master Record
        if(trigger.isDelete && trigger.isAfter){
             for(Account acc: trigger.old){
                if(acc.recordtypeid == rMSAId &&acc.MSA__c != null){
                    acc.adderror('MSA Account cannot be deleted');
                }
             }
        }
    }
}