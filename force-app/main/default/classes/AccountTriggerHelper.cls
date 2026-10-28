/**
* Description      :   Helper class for Account Trigger to provide/remove the sharing of account recordds to Branch Users
* 
* 
* Revision Logs    :   V_1.0 - Created
* 
**/
public class AccountTriggerHelper {
    
    //PRC accounts added to the branch and give visibility to the user of that new account.
    /*public static void prcAccountInsert(List<Account> lstAccount,Set<Id> setBranchId){
        
        Map<Id,Id> mapBranchUserId = new Map<Id,Id>();
        List<AccountShare> lstAShare = new List<AccountShare>();
        try{
            for(User_Branch_Mapping__c ubm : [select id,Branch_Name__c,User__c from User_Branch_Mapping__c where Branch_Name__c IN: setBranchId]){                
                mapBranchUserId.put(ubm.Branch_Name__c, ubm.User__c);
            }
            
            for(Account acc : lstAccount){
                
                AccountShare ash = new AccountShare();
                ash.accountid = acc.Id;
                ash.userorgroupid = mapBranchUserId.get(acc.Branch__c);
                ash.accountaccesslevel = 'Read';
                ash.OpportunityAccessLevel = 'None';
                ash.CaseAccessLevel = 'None';
                lstAShare.add(ash);
            }
            if(!lstAshare.isEmpty()){
                insert lstAshare;
            }
        }catch(Exception e){
            //System.debug('Exception:'+e.getMessage());
        }
    }*/
    
    //PRC accounts added to the branch and removing visibility from the user of that account.
    /*public static void prcAccountRemove(List<Account> lstAccount,Set<Id> setOldBranchId){
        
        Map<Id,Id> mapBranchUserId = new Map<Id,Id>();
        List<AccountShare> lstAShare = new List<AccountShare>();
        Map<String,Accountshare> mapAShareRemove = new Map<String,Accountshare>();
        try{
            for(User_Branch_Mapping__c ubm : [select id,Branch_Name__c,User__c from User_Branch_Mapping__c where Branch_Name__c IN: setOldBranchId]){
                
                mapBranchUserId.put(ubm.Branch_Name__c, ubm.User__c);
            }
            
            for(AccountShare ash : [select id,userorgroupid,accountid from accountshare where accountid in: lstAccount]){
                
                mapAShareRemove.put(ash.accountid+'+'+ash.userorgroupid,ash);
            }
            
            for(Account acc : lstAccount){
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
              //System.debug('Exception:'+e.getMessage());
        }
        
    }*/
    //This method is updating the Region from Branch and Booking branch on PRC account and SFX account by renu
    public static void getBranchName(List<Account> lstAccount, Set<Id> branchId){
        //  //System.debug('<< lstAccount >> '+lstAccount);
        Id rSfxId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        try{
            Map<Id ,String> mapBranMas = new Map<Id ,String>();
            for(Branch_Master__c objBranchMnaster : [Select Id ,Region__c from Branch_Master__c where Id IN : branchId]){
                if(!String.isBlank(objBranchMnaster.Region__c)){
                    mapBranMas.put(objBranchMnaster.Id , objBranchMnaster.Region__c);
                }
            }
            for(Account objAcc : lstAccount){
                if(objAcc.recordtypeid == rSfxId && mapBranMas.containsKey(objAcc.Booking_Branch__c)){
                    objAcc.Region__c = mapBranMas.get(objAcc.Booking_Branch__c);
                }else if(objAcc.recordtypeid == rId && mapBranMas.containsKey(objAcc.Branch__c)){
                    objAcc.Region__c = mapBranMas.get(objAcc.Branch__c);
                }
            }                        
        }catch(Exception e){
              //System.debug('Exception:'+e.getMessage());
             //System.debug('Exception:'+e.getLineNumber());
        }
    }
    
    //This method is updating the Expiry Date Pros on prospect Account If all Child SFX customers have Expiry Date By renu
   /* public static void updateProspectAccount(Set<Id> accountProsId){
        List<Account> lstParentAccount = new List<Account>();
        for(Account objAcc : [Select Id,Expiry_Date_Pros__c , (Select Id,Expiry_Date__c from ChildAccounts where Expiry_Date__c = null order by Expiry_Date__c Desc  limit 1) from Account where Id IN : accountProsId]){            
            if(objAcc.ChildAccounts.size() > 0){                
                objAcc.Expiry_Date_Pros__c = null;
            }else{                
                objAcc.Expiry_Date_Pros__c = Date.Today();
            }
            lstParentAccount.add(objAcc);
        }        
        if(lstParentAccount.size() > 0){
            try{
                update lstParentAccount;
            }catch(Exception e){                
                //System.debug('Exception:'+e.getLineNumber());
            }
        }
    }*/
    
    // Method to update ARM flag in Account
    /*Public static void ArmFlagChange(List<Account> lstAccount, Set<Id> branchId){
        List<Branch_master__c> lstBranchMaster =   [select id,name,branch_type__c from Branch_master__c where id in:branchId AND (branch_type__c = 'ARM' OR branch_type__c = 'ARM B' OR branch_type__c = 'ARM D')];
        //  //System.debug('');
        Set<id> setARMBranchIds = new Set<id>();    
        if(! lstBranchMaster.isEmpty())
        {
            for(Branch_master__c objbranchmaster:lstBranchMaster)
            {
                setARMBranchIds.add(objbranchmaster.id);
            }
        }
        //  //System.debug('lstAccount---------------->'+lstAccount);
        if(! setARMBranchIds.isEmpty() && ! lstAccount.isEmpty())
        {
            for(Account updateAcc: lstAccount)
            {
                if(setARMBranchIds != null && updateAcc.booking_branch__c != null && setARMBranchIds.contains(updateAcc.booking_branch__c))
                {
                    updateAcc.ARM_Branch__c= True;
                }
            }
        }
    }*/
    
   /* Public static void GBAFlagChange(List<Account> lstAccount, Set<Id> branchId){
        List<Branch_master__c> lstBranchMaster =   [select id,name,branch_type__c from Branch_master__c where id in:branchId AND ( branch_type__c = 'GBA' OR branch_type__c = 'GBA PLUS')];
        Set<id> setGBABranchIds = new Set<id>();    
        if(! lstBranchMaster.isEmpty())
        {
            for(Branch_master__c objbranchmaster:lstBranchMaster)
            {
                setGBABranchIds.add(objbranchmaster.id);
            }
        }
        //  //System.debug('lstAccount---------------->'+lstAccount);
        if(! setGBABranchIds.isEmpty() && ! lstAccount.isEmpty())
        {
            for(Account updateAcc: lstAccount)
            {
                if(setGBABranchIds != null && updateAcc.booking_branch__c != null && setGBABranchIds.contains(updateAcc.booking_branch__c))
                {
                    updateAcc.GBA_Branch__c= True;
                }
            }
        }
    }*/
    
    //Method to update NAM1 on new sfx inserted and create Ateam if other sfx has already nam1 populated.
   /* public static void newSFXInsertCheck(List<Account> lstAccount,List<Id> lstParentId){
        
        try{
            //  //System.debug('lstAccount++'+lstAccount);
            Map<Id,account> mapParentIdSfxAccount = new Map<Id,account>();
            Map<String,account_team__c> mapParentIdAccountTeam = new Map<String,account_team__c>();
            List<Account_Team__c> lstATeam = new List<Account_Team__c>();
            Map<String,account_team__c> mapAccountNamBDM = new Map<String,account_team__c>();
            
            for(account acc : [select id,(select id,national1__c from ChildAccounts where national1__c = true or national2__c = true
                                          or national3__c = true or national4__c = true limit 1) from account where Id IN: lstParentId]){
                                              if(acc.ChildAccounts.size() > 0){
                                                  mapParentIdSfxAccount.put(acc.Id,acc.ChildAccounts[0]);
                                              }
                                          }
            //  //System.debug('mapParentIdSfxAccount++'+mapParentIdSfxAccount);
            if(!mapParentIdSfxAccount.isEmpty()){
                for(Account_team__c at : [select id,bdm__c,national1__c,national2__c,national3__c,national4__c,Account__r.parentid from account_team__c
                                          where account__c IN: mapParentIdSfxAccount.values() and (national1__c = true or national2__c = true or national3__c = true or national4__c = true)]){
                                              //  //System.debug('at++'+at);
                                              if(at.National1__c == true){
                                                  mapAccountNamBDM.put(at.Account__r.parentid+'N1',at);   
                                              }
                                              if(at.National2__c == true){
                                                  mapAccountNamBDM.put(at.Account__r.parentid+'N2',at);
                                              }
                                              if(at.National3__c == true){
                                                  mapAccountNamBDM.put(at.Account__r.parentid+'N3',at);
                                              }
                                              if(at.National4__c == true){
                                                  mapAccountNamBDM.put(at.Account__r.parentid+'N4',at);
                                              }
                                          }
            }
            //  //System.debug('mapAccountNamBDM++'+mapAccountNamBDM);
            if(!mapAccountNamBDM.isEmpty()){
                for(account acc: lstAccount){
                    //  //System.debug('acc++'+acc);
                    //  //System.debug('acc.ParentId++'+acc.ParentId+'N1');
                    if(mapAccountNamBDM.containsKey(acc.ParentId+'N1')){
                        //  //System.debug('1if++');
                        Account_Team__c a = new Account_Team__c();
                        a.Account__c = acc.Id;
                        a.BDM__c = mapAccountNamBDM.get(acc.ParentId+'N1').bdm__c;
                        a.National1__c = true;
                        if(mapAccountNamBDM.containsKey(acc.ParentId+'N2') && 
                           mapAccountNamBDM.get(acc.ParentId+'N1').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N2').bdm__c){
                               a.National2__c = true;
                           }
                        if(mapAccountNamBDM.containsKey(acc.ParentId+'N3') && 
                           mapAccountNamBDM.get(acc.ParentId+'N1').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N3').bdm__c){
                               a.National3__c = true;
                           }
                        if(mapAccountNamBDM.containsKey(acc.ParentId+'N4') && 
                           mapAccountNamBDM.get(acc.ParentId+'N1').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N4').bdm__c){
                               a.National4__c = true;
                           }
                        lstATeam.add(a);
                    }
                    
                    if(mapAccountNamBDM.containsKey(acc.ParentId+'N2')){
                        if((mapAccountNamBDM.containsKey(acc.ParentId+'N1') &&
                            mapAccountNamBDM.get(acc.ParentId+'N1').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N2').bdm__c)){
                                
                            }
                        else{
                            Account_Team__c a = new Account_Team__c();
                            a.Account__c = acc.Id;
                            a.BDM__c = mapAccountNamBDM.get(acc.ParentId+'N2').bdm__c;
                            a.National2__c = true;
                            if(mapAccountNamBDM.containsKey(acc.ParentId+'N3') && 
                               mapAccountNamBDM.get(acc.ParentId+'N2').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N3').bdm__c){
                                   a.National3__c = true;
                               }
                            if(mapAccountNamBDM.containsKey(acc.ParentId+'N4') && 
                               mapAccountNamBDM.get(acc.ParentId+'N2').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N4').bdm__c){
                                   a.National4__c = true;
                               }
                            lstATeam.add(a);
                        }
                    }
                    
                    if(mapAccountNamBDM.containsKey(acc.ParentId+'N3')){
                        if(mapAccountNamBDM.containsKey(acc.ParentId+'N1') && mapAccountNamBDM.get(acc.ParentId+'N1').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N3').bdm__c){
                            
                        }
                        else if(mapAccountNamBDM.containsKey(acc.ParentId+'N2') && mapAccountNamBDM.get(acc.ParentId+'N2').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N3').bdm__c){
                            
                        }
                        else{
                            Account_Team__c a = new Account_Team__c();
                            a.Account__c = acc.Id;
                            a.BDM__c = mapAccountNamBDM.get(acc.ParentId+'N3').bdm__c;
                            a.National3__c = true;
                            if(mapAccountNamBDM.containsKey(acc.ParentId+'N4') && 
                               mapAccountNamBDM.get(acc.ParentId+'N3').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N4').bdm__c){
                                   a.National4__c = true;
                               }
                            lstATeam.add(a);
                        }
                    }                    
                    
                    if(mapAccountNamBDM.containsKey(acc.ParentId+'N4')){
                        if(mapAccountNamBDM.containsKey(acc.ParentId+'N1') && mapAccountNamBDM.get(acc.ParentId+'N1').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N4').bdm__c){
                            
                        }
                        else if(mapAccountNamBDM.containsKey(acc.ParentId+'N2') && mapAccountNamBDM.get(acc.ParentId+'N2').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N4').bdm__c){
                            
                        }
                        else if(mapAccountNamBDM.containsKey(acc.ParentId+'N3') && mapAccountNamBDM.get(acc.ParentId+'N3').bdm__c == mapAccountNamBDM.get(acc.ParentId+'N4').bdm__c){
                            
                        }
                        else{
                            Account_Team__c a = new Account_Team__c();
                            a.Account__c = acc.Id;
                            a.BDM__c = mapAccountNamBDM.get(acc.ParentId+'N4').bdm__c;
                            a.National4__c = true;                    
                            lstATeam.add(a);
                        }
                    }
                    
                }
            }            
            if(!lstATeam.isEmpty()){
                insert lstATeam;
            }
            
        }catch(Exception e){
          //System.debug('Exception:'+e.getMessage());
        }
    }*/
    
    ///<SUMMARY>
    // This method will assign the CCD (National1__c) and RM (National4__c) to the respective users Arvind Tiwari-17526 and Kousher Alam-15988
    ///</SUMMARY>
    /*public static void createBDMMappingTeam(List<Account> lstNewAccount) {
        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;
        
        Id propelIAccountTeamRecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
        
        List<Account_Team__c> lstAccountTeam = new List<Account_Team__c>();
        for(Account eachAcc : lstNewAccount) {
            if(eachAcc.Propel_MSACode__c != null) {
                Account_Team__c objTeam1 = new Account_Team__c();
                objTeam1.National1__c = true;
                objTeam1.Account__c = eachAcc.Id;
                objTeam1.BDMPropelI__c = Label.CCD_BDM;
                objTeam1.RecordTypeId = propelIAccountTeamRecordType;
                objTeam1.PropelI_Composite_Key__c = objTeam1.BDMPropelI__c + '::' + eachAcc.Propel_MSACode__c;
                lstAccountTeam.add(objTeam1);
                
                Account_Team__c objTeam2 = new Account_Team__c();
                objTeam2.National4__c = true;
                objTeam2.Account__c = eachAcc.Id;
                objTeam2.BDMPropelI__c = Label.RM_BDM;
                objTeam2.RecordTypeId = propelIAccountTeamRecordType;
                objTeam2.PropelI_Composite_Key__c = objTeam2.BDMPropelI__c + '::' + eachAcc.Propel_MSACode__c;
                lstAccountTeam.add(objTeam2);
            }
        }
        //  //System.debug('lstAccountTeam----------------->'+lstAccountTeam);
        if(! lstAccountTeam.isEmpty())
        {
            //Upsert the account team record.
            Database.UpsertResult[] results = Database.upsert(lstAccountTeam, Account_Team__c.Field.PropelI_Composite_Key__c );
            for(Database.UpsertResult bdUpsrt : results) {
                if(bdUpsrt.isSuccess()) {
                    //  //System.debug(LoggingLevel.DEBUG, '---- The record is upserted successfull, record id is: ' + bdUpsrt.getId());
                }
                else {
                    for(Database.Error eachError : bdUpsrt.getErrors()) {
                        //  //System.debug(LoggingLevel.DEBUG, '---- Errors occurred in class cls_PullMSAOnDemand - eachError.getMessage(): ' + eachError.getMessage());
                        //  //System.debug(LoggingLevel.DEBUG, '---- Errors occurred in class cls_PullMSAOnDemand - eachError.getFields(): ' + eachError.getFields());
                    }
                }
            }
        }
    }*/
    
	public static void createBDMMappingTeamFuture(Set<Id> accountIds) {

    if(accountIds == null || accountIds.isEmpty()) {
        return;
    }

    // Re-query Accounts because future methods cannot take sObject params
    List<Account> lstNewAccount = [
        SELECT Id, Propel_MSACode__c
        FROM Account
        WHERE Id IN :accountIds
    ];

    cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;

    Id propelIAccountTeamRecordType = Schema.SObjectType.Account_Team__c
                                        .getRecordTypeInfosByName()
                                        .get('PropelI Account Team')
                                        .getRecordTypeId();

    List<Account_Team__c> lstAccountTeam = new List<Account_Team__c>();

    for(Account eachAcc : lstNewAccount) {

        if(eachAcc.Propel_MSACode__c != null) {

            Account_Team__c objTeam1 = new Account_Team__c();
            objTeam1.National1__c = true;
            objTeam1.Account__c = eachAcc.Id;
            objTeam1.BDMPropelI__c = Label.CCD_BDM;
            objTeam1.RecordTypeId = propelIAccountTeamRecordType;
            objTeam1.PropelI_Composite_Key__c = objTeam1.BDMPropelI__c + '::' + eachAcc.Propel_MSACode__c;
            lstAccountTeam.add(objTeam1);

            Account_Team__c objTeam2 = new Account_Team__c();
            objTeam2.National4__c = true;
            objTeam2.Account__c = eachAcc.Id;
            objTeam2.BDMPropelI__c = Label.RM_BDM;
            objTeam2.RecordTypeId = propelIAccountTeamRecordType;
            objTeam2.PropelI_Composite_Key__c = objTeam2.BDMPropelI__c + '::' + eachAcc.Propel_MSACode__c;
            lstAccountTeam.add(objTeam2);
        }
    }

    if(!lstAccountTeam.isEmpty()) {

        Database.UpsertResult[] results = Database.upsert(
            lstAccountTeam,
            Account_Team__c.Field.PropelI_Composite_Key__c
        );

        for(Database.UpsertResult bdUpsrt : results) {
            if(!bdUpsrt.isSuccess()) {
                for(Database.Error eachError : bdUpsrt.getErrors()) {
                    // handle errors (kept same as original)
                }
            }
        }
    }
}
    
    public static void updateContractRecordType(List<String> accountIds){
        
        List<Account> accountList = [SELECT Id, Opportunity__r.Contract__c FROM Account Where Id IN : accountIds];
        Id closedRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Closed').getRecordTypeId();
        List<Contract__c> contractToUpdate = new List<Contract__c>();
        List<Account> accountToUpdate = new List<Account>();
        for(Account acc : accountList){
            if(acc.Opportunity__c != null && acc.Opportunity__r.Contract__c != null){
                Contract__c conract = new Contract__c(Id = acc.Opportunity__r.Contract__c, RecordTypeId = closedRecordTypeId);
                contractToUpdate.add(conract);
                accountToUpdate.add(new Account(Id = acc.Id, Contract__c = acc.Opportunity__r.Contract__c));
            }
        }
        TriggerUtility.byPassTrigger = true;
        update contractToUpdate;
        update accountToUpdate;
        TriggerUtility.byPassTrigger = false;
    }
    
    //Method to update the SFX account base location if the Rate Card base Location is updated
    public static void updateBaseLoc(List<Account> LstAccount,Map<id,Account> mapOfAcc) {
        List<Account> lstSfx= new List<Account>();
        Set<Id> uniqueParentIds = new Set<Id>();   // By-Tarun Sachdeva
        List<Account> accountList = [SELECT Id,Parent.Parent.Id,Base_Location__c from Account where Id IN:LstAccount];
        //  //System.debug('RC baselocation----->'+accountList);
        //  //System.debug('No. of RC----->'+accountList.size());
        for(Account acc : accountList) 
        {
            if (acc.Parent != null && acc.Parent.Parent != null && acc.Parent.Parent.Id != null) {
           if (!uniqueParentIds.contains(acc.Parent.Parent.Id)) {
            uniqueParentIds.add(acc.Parent.Parent.Id);
            Account sfxAcc = new Account(id = acc.Parent.Parent.Id , Base_Location__c = mapOfAcc == null ? acc.Base_Location__c : mapOfAcc.get(acc.Id).Base_Location__c);
            //  //System.debug('sfxAcc'+sfxAcc);
            lstSfx.add(sfxAcc);
        }    
            }
        }   
        ////  //System.debug('SFX baselocation----->'+lstSfx[0].Base_Location__c);
        //  //System.debug('Size of SFX----->'+lstSfx.size());
        if(!lstSfx.isEmpty())
        update lstSfx;       
    }
    
        
/*Description: Converting workflow rule 
* author : Tarun Sachdeva
* SAC-1457
*/
    public static void updateAccountDetails(List<Account> listAccount){
        //Preload RecordType DeveloperNames into a Map<Id, RecordType>
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
            [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Account']
        );
        for(Account acc : listAccount) {
            // Uppercase the Account Name
            if(acc.Name != null){
                acc.Name = acc.Name.toUpperCase();
            }
            // Set the Account_Recordtype_Name__c based on RecordType
            if(acc.RecordTypeId != null && recordTypeMap.containsKey(acc.RecordTypeId)) {
                RecordType rt = recordTypeMap.get(acc.RecordTypeId);
                if(rt.Name == ConstantUtility.Account_RTname_Prospect){
                    acc.Account_Recordtype_Name__c = rt.DeveloperName;
                }
            }
        }
        
    }
     /*Description: Updating the Business Detail Account Field for Opportunity Closed Won 
    * author : Tarun Sachdeva
    * SAC-1519
    */
    public static void updateAccountOnBD(List<Account> lstOfAccount){
        try{
            //  //System.debug('updateAccountOnBD--->');
            Map<Id,Id> oppRelatedSFX = new Map<Id,Id>();
            Id actualSFXRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Actual_SFX').getRecordTypeId();
            for(Account acc : lstOfAccount){
                if(acc.RecordTypeId == actualSFXRecordTypeId){
                    oppRelatedSFX.put(acc.Opportunity__c,acc.Id);
                }
            }
            //  //System.debug('oppRelatedSFX-->'+oppRelatedSFX);
            if(!oppRelatedSFX.isEmpty()){
                List<Business_Detail__c> lstOfBdRec =[Select id, Account__c,Opportunity__c from Business_Detail__c where Opportunity__c IN :oppRelatedSFX.keySet()];
                
                for(Business_Detail__c bdRec : lstOfBdRec){
                    
                    if(oppRelatedSFX.containsKey(bdRec.Opportunity__c)){
                        
                        bdRec.Account__c = oppRelatedSFX.get(bdRec.Opportunity__c);
                        bdRec.Opportunity__c = null;
                        
                    }
                    
                }
                //  //System.debug('lstOfBdRec--->'+lstOfBdRec);
                if(!lstOfBdRec.isEmpty())
                    update lstOfBdRec;
            }
        }catch(Exception exp) { 
             //System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : AccountTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('AccountTriggerHandler', 'updateAccountOnBD', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
}