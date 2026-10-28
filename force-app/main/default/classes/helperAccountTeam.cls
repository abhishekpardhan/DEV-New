// Helper Class for AccountTeam Trigger "trg_AccountTeam" to perform various operations like providing/removing the sharing of parent account whenever AccountTeamMember
// added/removed etc.
public class helperAccountTeam {
    public static void removeSharing(List<Account_Team__c> lstAteam,List<Id> lstId,List<Id> lstIds, List<Id> lstBDM){ //lstBDM Added by Monika on 14-11-2019
        List<AccountShare> lstAShare = new List<AccountShare>();
        Map<String,Accountshare> mapAShare = new Map<String,Accountshare>();
        try{
            for(AccountShare ash : [select id,userorgroupid,accountid from accountshare where accountid in: lstId]){
                
                mapAShare.put(ash.accountid+'+'+ash.userorgroupid,ash);
            } 
            // System.debug('mapAShare-->'+mapAShare);
            for(Account_Team__c at: lstAteam){
                AccountShare AShare = new AccountShare();
                AShare = mapAShare.get(at.account__c+'+'+at.BDM__c);
                if(AShare != null){
                    lstAShare.add(AShare);
                }
            }
            // System.debug('lstAShare-->'+lstAShare);
            if(!lstAShare.isEmpty()){
                delete lstAShare;
                
            }
            // System.debug('lstAShare2-->'+[select id from Account_Team__c where id IN: lstIds]);
            delete [select id from Account_Team__c where id IN: lstIds];
            List<Contact> con = [Select id, name, OwnerId, AccountId from contact where AccountId IN:lstId and OwnerId IN: lstBDM]; //Mon
            // System.debug('Con:' +con); //Added by Monika on 14-11-2019
            for(Contact c : con){ //Added by Monika on 14-11-2019
                //  if(c.ownerid IN: lstBDM)
                //  if(lstBDM contains(c.ownerid))            
                c.ownerid = '0057F000002y4xPQAQ'; //Added by Monika on 14-11-2019
            }  
            update con;//Added by Monika on 14-11-2019
        }
        
        catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
    }
    //Method to update the mapping of field values between Account_Team__c and Account 
    public static void updateAccount(List<account_team__c> lstAteam,Map<Id,Account_Team__c> mapOldAteam,List<Id> lstId){
        try{
            
            List<Account> lstAcc = new List<Account>();
            Map<Id,Account> mapAcc = new Map<Id,Account>([select id,Relationship__c,Submission__c,Collection__c,National1__c,National2__c,National3__c,National4__c from account where Id IN : lstId AND RecordType.DeveloperName = 'Prospect_Customer']);
            
            for(Account_Team__c att: lstAteam){
                
                if(att.Relationship__c != mapOldAteam.get(att.Id).Relationship__c){                        
                    mapAcc.get(att.Account__c).Relationship__c = att.Relationship__c;
                }
                if(att.Collection__c != mapOldAteam.get(att.Id).Collection__c){
                    mapAcc.get(att.Account__c).Collection__c = att.Collection__c;
                }
                if(att.Submission__c != mapOldAteam.get(att.Id).Submission__c){
                    mapAcc.get(att.Account__c).Submission__c = att.Submission__c;
                }
                if(att.National1__c != mapOldAteam.get(att.Id).National1__c){
                    mapAcc.get(att.Account__c).National1__c = att.National1__c;
                }
                if(att.National2__c != mapOldAteam.get(att.Id).National2__c){
                    mapAcc.get(att.Account__c).National2__c = att.National2__c;
                }
                if(att.National3__c != mapOldAteam.get(att.Id).National3__c){
                    mapAcc.get(att.Account__c).National3__c = att.National3__c;
                }
                if(att.National4__c != mapOldAteam.get(att.Id).National4__c){
                    mapAcc.get(att.Account__c).National4__c = att.National4__c;
                }
            }
            if(!mapAcc.isEmpty()){
                lstAcc = mapAcc.values();
            }
            // System.debug('lstAcc++'+lstAcc);
            if(!lstAcc.isEmpty()){
                update lstAcc;
            }
            
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
        }
    } 
    //Remove nationals in account team update.
    public static void removeNationalsInAccTeamUpdate(List<account_team__c> lstAteam,Map<Id,Account_Team__c> mapOldAteam,List<Id> lstId){
        
        try{
            
            Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
            Set<String> setSFXNat = new Set<String>();
            Map<String,Account_Team__c> mapAteam = new Map<String,Account_Team__c>();
            Map<String,Account_Team__c> mapOldAccteam = new Map<String,Account_Team__c>();
            Map<Id,Account_Team__c> mapAccountTeamId = new Map<Id,Account_Team__c>();
            List<Account_Team__c> lstUpdAteam = new List<Account_Team__c>();
            Map<Id,Account> mapAccount = new Map<Id,Account>([select id,name,SFX_Code__c from account where recordtypeid =: rId and id IN: lstId]);
            for(Account_Team__c att: lstAteam){
                if((att.National1__c == false && mapOldAteam.get(att.id).National1__c == true) || 
                   (att.National2__c == false && mapOldAteam.get(att.id).National2__c == true) ||
                   (att.National3__c == false && mapOldAteam.get(att.id).National3__c == true) ||
                   (att.National4__c == false && mapOldAteam.get(att.id).National4__c == true)){
                       
                       setSFXNat.add(mapAccount.get(att.Account__c).SFX_Code__c);
                       mapAteam.put(mapAccount.get(att.Account__c).SFX_Code__c,att);
                       mapOldAccteam.put(mapAccount.get(att.Account__c).SFX_Code__c,mapOldAteam.get(att.id));
                       mapAccountTeamId.put(att.Id,att);
                   }
            }
            if(!setSFXNat.isEmpty()){
                List<Account_team__c> lstAtm = [select id,national1__c,national2__c,national3__c,national4__c,account__r.SFX_Code__c from account_team__c where account__r.SFX_Code__c IN: setSFXNat];                
                // System.debug('lstAtm++'+lstAtm);
                // System.debug('lstAtmSize++'+lstAtm.size());
                for(Account_team__c atm : lstAtm){
                    if(mapAccountTeamId.containsKey(atm.Id)){
                        
                    }
                    else{
                        if(mapAteam.get(atm.Account__r.SFX_Code__c).National1__c != mapOldAccteam.get(atm.Account__r.SFX_Code__c).National1__c){
                            atm.National1__c = mapAteam.get(atm.Account__r.SFX_Code__c).National1__c;
                        }
                        if(mapAteam.get(atm.Account__r.SFX_Code__c).National2__c != mapOldAccteam.get(atm.Account__r.SFX_Code__c).National2__c){
                            atm.National2__c = mapAteam.get(atm.Account__r.SFX_Code__c).National2__c;
                        }
                        if(mapAteam.get(atm.Account__r.SFX_Code__c).National3__c != mapOldAccteam.get(atm.Account__r.SFX_Code__c).National3__c){
                            atm.National3__c = mapAteam.get(atm.Account__r.SFX_Code__c).National3__c;
                        }
                        if(mapAteam.get(atm.Account__r.SFX_Code__c).National4__c != mapOldAccteam.get(atm.Account__r.SFX_Code__c).National4__c){
                            atm.National4__c = mapAteam.get(atm.Account__r.SFX_Code__c).National4__c;
                        }
                        lstUpdAteam.add(atm);
                    }
                }
                // System.debug('lstUpdAteam++'+lstUpdAteam);
                // System.debug('lstUpdAteamSize++'+lstUpdAteam.size());
                if(!lstUpdAteam.isEmpty()){
                    update lstUpdAteam;
                }
            }
            
            
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
        
    }
    //Added nationals in account team update.
    public static void addedNationalsInAccTeamUpdate(List<account_team__c> lstAteam,Map<Id,Account_Team__c> mapOldAteam,List<Id> lstId){
        
        try{
            Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
            Set<String> setSFX = new Set<String>();
            Map<Id,Account_Team__c> mapAT = new Map<Id,Account_Team__c>();
            Map<String,Account_Team__c> mapActeam = new Map<String,Account_Team__c>();
            Map<Id,Id> mapAccAteamId = new Map<Id,Id>();
            map<String,Id> mapUsername = new map<String,Id>();
            List<Account_Team__c> newlstAT = new List<Account_Team__c>();
            List<Account_Team__c> updlstAT = new List<Account_Team__c>();
            List<Account_Team__c> newlstAT2 = new List<Account_Team__c>();
            List<Account_Team__c> updlstAT2 = new List<Account_Team__c>();
            
            Id uname;
            List<AccountShare> lstAS = new List<AccountShare>();
            List<AccountShare> lstAS2 = new List<AccountShare>();
            map<Id,boolean> mapAteamStatus = new map<Id,boolean>();
            Map<Id,Account> mapAccount = new Map<Id,Account>([select id,name,SFX_Code__c from account where recordtypeid =: rId and id IN: lstId]);

            if(mapAccount != null && mapAccount.keySet() != null && !mapAccount.keySet().isEmpty() && !mapAccount.values().isEmpty())
            for(Account_Team__c at: lstAteam){
                if((at.National1__c == true && mapOldAteam.get(at.id).National1__c == false) || (at.National2__c == true && mapOldAteam.get(at.id).National2__c == false) || (at.National3__c == true && mapOldAteam.get(at.id).National3__c == false) || (at.National4__c == true && mapOldAteam.get(at.id).National4__c == false)){
                       setSFX.add(mapAccount.get(at.Account__c).SFX_Code__c);
                       mapActeam.put(mapAccount.get(at.Account__c).SFX_Code__c,at);
                       mapAccAteamId.put(at.Account__c,at.Id);
                   }
                mapAT.put(at.Id,at);
                mapUsername.put(mapAccount.get(at.Account__c).SFX_Code__c,at.BDM__c);
                uname = at.BDM__c;            
            }
            // System.debug('mapUsername++'+mapUsername);
            // System.debug('uname++'+uname);
            List<Account> lstAccount = [select id,name,SFX_Code__c,(select id,bdm__c,name,National1__c,National2__c,National3__c,National4__c,account__r.sfx_code__c from Account_Teams__r) from account where SFX_Code__c IN: setSFX];
            
            for(Account acc: lstAccount){
                
                if(mapAccAteamId.containsKey(acc.Id)){
                    // System.debug('Same account is in before update');
                }
                else if(acc.Account_Teams__r.size() > 0){
                    // System.debug('acc.Account_Teams__r[0]'+acc.Account_Teams__r[0]);
                    
                    for(integer i=0;i<acc.Account_Teams__r.size();i++){         //  account_team__c atc : acc.Account_Teams__r
                        if(i<acc.Account_Teams__r.size()){
                            if(acc.Account_Teams__r[i].bdm__c == mapUsername.get(acc.Account_Teams__r[i].account__r.sfx_code__c)){
                                
                                if(mapActeam.get(acc.SFX_Code__c).National1__c == true){
                                    // System.debug('1+++');
                                    acc.Account_Teams__r[i].National1__c = mapActeam.get(acc.SFX_Code__c).National1__c;
                                }
                                if(mapActeam.get(acc.SFX_Code__c).National2__c == true){
                                    // System.debug('2+++');
                                    acc.Account_Teams__r[i].National2__c = mapActeam.get(acc.SFX_Code__c).National2__c;
                                }
                                if(mapActeam.get(acc.SFX_Code__c).National3__c == true){
                                    // System.debug('3+++');
                                    acc.Account_Teams__r[i].National3__c = mapActeam.get(acc.SFX_Code__c).National3__c;
                                }
                                if(mapActeam.get(acc.SFX_Code__c).National4__c == true){
                                    // System.debug('4+++');
                                    acc.Account_Teams__r[i].National4__c = mapActeam.get(acc.SFX_Code__c).National4__c;
                                }
                                updlstAT.add(acc.Account_Teams__r[i]); mapAteamStatus.put(acc.Account_Teams__r[i].account__c,true);
                            }
                        }
                        if(i == acc.Account_Teams__r.size() - 1){  
                            if(!mapAteamStatus.containskey(acc.Account_Teams__r[i].account__c)){
                                
                                Account_Team__c a = new Account_Team__c(Account__c = acc.Id, BDM__c = mapUsername.get(acc.SFX_Code__c));
                                a.National1__c = mapActeam.get(acc.SFX_Code__c).National1__c;
                                a.National2__c = mapActeam.get(acc.SFX_Code__c).National2__c;
                                a.National3__c = mapActeam.get(acc.SFX_Code__c).National3__c;
                                a.National4__c = mapActeam.get(acc.SFX_Code__c).National4__c;
                                newlstAT.add(a);
                                AccountShare ash = new AccountShare(accountid = acc.Id, accountaccesslevel = 'Edit', CaseAccessLevel = 'None', OpportunityAccessLevel = 'None');
                                ash.userorgroupid = mapUsername.get(acc.SFX_Code__c);
                                lstAS.add(ash);
                            }
                        }
                    }
                    
                }
                
                else if(acc.Account_Teams__r.size() == 0){
                    
                    Account_Team__c a = new Account_Team__c();
                    a.Account__c = acc.Id;
                    a.BDM__c = mapUsername.get(acc.SFX_Code__c);
                    a.National1__c = mapActeam.get(acc.SFX_Code__c).National1__c;
                    a.National2__c = mapActeam.get(acc.SFX_Code__c).National2__c;
                    a.National3__c = mapActeam.get(acc.SFX_Code__c).National3__c;
                    a.National4__c = mapActeam.get(acc.SFX_Code__c).National4__c;
                    newlstAT2.add(a);
                    AccountShare ash = new AccountShare();
                    ash.accountid = acc.Id;
                    ash.userorgroupid = mapUsername.get(acc.SFX_Code__c);
                    ash.accountaccesslevel = 'Edit';    
                    ash.OpportunityAccessLevel = 'None';
                    ash.CaseAccessLevel = 'None';
                    lstAS2.add(ash);
                }
                
            }
            // System.debug('newlstAT++'+newlstAT);
            // System.debug('newlstATSize++'+newlstAT.size());
            // System.debug('newlstAT2++'+newlstAT2);
            // System.debug('newlstAT2Size++'+newlstAT2.size());
            
            // System.debug('updlstAT++'+updlstAT);
            // System.debug('updlstATSize++'+updlstAT.size());                        
            // System.debug('lstAS+++'+lstAS);
            // System.debug('lstAS2+++'+lstAS2);
            if(!updlstAT.isEmpty()){
                checkRecursive.firstRun = false;
                //update updlstAT;
                Database.SaveResult[] lstASResults2 = Database.insert(updlstAT, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : lstASResults2) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'addedNationalsInAccTeamUpdate:updlstAT', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }
            if(!newlstAT.isEmpty()){
                checkRecursive.firstRun = false;
                //insert newlstAT;
                Database.SaveResult[] lstASResults1 = Database.insert(newlstAT, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : lstASResults1) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'addedNationalsInAccTeamUpdate:newlstAT', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }
            if(!lstAS.isEmpty()){
                checkRecursive.firstRun = false;
                //insert lstAS;
                Database.SaveResult[] lstASResults = Database.insert(lstAS, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : lstASResults) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'addedNationalsInAccTeamUpdate:lstAS', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }  
            if(!newlstAT2.isEmpty()){
                checkRecursive.firstRun = false;
                insert newlstAT2;
                Database.SaveResult[] resultsnewlstAT2 = Database.insert(newlstAT2, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : resultsnewlstAT2) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'addedNationalsInAccTeamUpdate:newlstAT2', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }
            if(!lstAS2.isEmpty()){
                checkRecursive.firstRun = false;
                //insert lstAS2;
                Database.SaveResult[] results = Database.insert(lstAS2, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'addedNationalsInAccTeamUpdate:lstAS2', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }  
            checkRecursive.firstRun = true;
            
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
    }        
    //New AccountTeam Insertion
    public static void updateAccountNewAT(List<Account_Team__c> lstAteam,List<Id> lstAccId){
        try{            
            Map<String,Id> mapAUser = new Map<String,Id>();               
            
            for(Account_Team__c at: lstAteam){                                        
                if(at.Relationship__c == true ||  at.Collection__c == true || at.Submission__c == true ||
                   at.National1__c == true    ||  at.National2__c == true  || at.National3__c == true || at.National4__c == true  || at.NSM__c == true || at.CRS__c == true){
                       
                       mapAUser.put(at.Account__c + '-' + at.BDM__c, at.BDM__c);
                   }
            }
            
            // System.debug('mapAUser++'+mapAUser);            
            
            List<AccountShare> lstAS = new List<AccountShare>();
            
            if(mapAUser.size() > 0) {
                for(String accountBDM : mapAUser.keySet()) {
                    if(mapAUser.get(accountBDM) != null) //Added by Mohit Sharma on 3-May-2023
                    {
                        AccountShare ash = new AccountShare();
                        ash.accountid = accountBDM.split('-')[0];
                        ash.userorgroupid = mapAUser.get(accountBDM);
                        ash.accountaccesslevel = 'Edit';
                        ash.OpportunityAccessLevel = 'None';
                        ash.CaseAccessLevel = 'None';
                        lstAS.add(ash);
                    }
                }
            }
            
            if(!lstAS.isEmpty()){
                //insert lstAS;
                Database.SaveResult[] results = Database.insert(lstAS, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'updateAccountNewAT:lstAS', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }  
            
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
    }
    //New AccountTeam Insertion
    public static void updateAccountonNewATeam(List<Account_Team__c> lstAteam,List<Id> lstAccId){
        try{
            Map<Id,Account> mapAcc = new Map<Id,Account>([select id,Relationship__c,Submission__c,Collection__c,National1__c,National2__c,National3__c,National4__c from account where Id IN: lstAccId]);
            List<Account> lstAcc = new List<Account>();
            Map<Id,Id> mapAUser = new Map<Id,Id>();
            if(!mapAcc.isEmpty()){
                for(Account_Team__c at: lstAteam){
                    if(at.Relationship__c == true){
                        mapAcc.get(at.Account__c).Relationship__c = true;
                    }
                    if(at.Collection__c == true){
                        mapAcc.get(at.Account__c).Collection__c = true;
                    }
                    if(at.Submission__c == true){
                        mapAcc.get(at.Account__c).Submission__c = true;
                    }
                    if(at.National1__c == true){
                        mapAcc.get(at.Account__c).National1__c = true;
                    }
                    if(at.National2__c == true){
                        mapAcc.get(at.Account__c).National2__c = true;
                    }
                    if(at.National3__c == true){
                        mapAcc.get(at.Account__c).National3__c = true;
                    }
                    if(at.National4__c == true){
                        mapAcc.get(at.Account__c).National4__c = true;
                    }
                    
                }
        
            }                    
            if(!mapAcc.isEmpty()){
                lstAcc = mapAcc.values();
            }
            // System.debug('lstAcc++'+lstAcc);
            if(!lstAcc.isEmpty()){
                update lstAcc;
            }
            
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
    }    
    //Method to add all National1,2,3 of new inserted AccountTeam.
    public static void newATNational(List<Account_Team__c> lstAteam,List<Id> lstAccId){
        
        try{
            Set<String> setSFX = new Set<String>();
            Map<Id,Account_Team__c> mapAT = new Map<Id,Account_Team__c>();
            Map<String,Account_Team__c> mapActeam = new Map<String,Account_Team__c>();
            Id uname;
            List<Account_Team__c> newlstAT = new List<Account_Team__c>();
            List<Account_Team__c> newlstAT2 = new List<Account_Team__c>();
            List<Account_Team__c> updlstAT = new List<Account_Team__c>();
            List<Account> lstAccount = new List<Account>();
            map<String,Id> mapUsername = new map<String,Id>();
            map<Id,Id> mapAccountATId = new map<Id,Id>();
            List<accountshare> lstAS = new List<accountshare>();
            List<accountshare> lstAS2 = new List<accountshare>();
            map<Id,boolean> mapAteamStatus = new map<Id,boolean>();
            Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
            Map<Id,Account> mapAccount = new Map<Id,Account>([select id,SFX_Code__c,name from account where recordtypeid =: rId and id IN: lstAccId]);
            if(!mapAccount.isEmpty()){
                for(Account_Team__c at: lstAteam){
                    
                    setSFX.add(mapAccount.get(at.Account__c).SFX_Code__c);
                    mapActeam.put(mapAccount.get(at.Account__c).SFX_Code__c,at);
                    
                    mapAT.put(at.Id,at);
                    mapAccountATId.put(at.account__c,at.Id);
                    mapUsername.put(mapAccount.get(at.Account__c).SFX_Code__c,at.BDM__c);
                    uname = at.BDM__c;            
                }
            }
            // System.debug('mapUsername++'+mapUsername);
            if(!setSFX.isEmpty()){
                lstAccount = [select id,name,SFX_Code__c,Booking_Branch__r.name,(select id,bdm__c,name,National1__c,National2__c,National3__c,National4__c,account__r.sfx_code__c from Account_Teams__r) from account where SFX_Code__c IN: setSFX and recordtypeid =: rId];
            }
            // System.debug('+newlstAccount++'+lstAccount);
            // System.debug('+newlstAccountSize++'+lstAccount.size());
            
            if(!lstAccount.isEmpty()){
                for(account acc : lstAccount){
                    // System.debug('acc.Account_Teams__r.size()+++'+acc.Account_Teams__r.size());
                    // System.debug('accname+++'+acc.Name+acc.Booking_Branch__r.name);
                    //To check if the account is same on which it is inserted.
                    if(mapAccountATId.containskey(acc.Id)){
                        // System.debug('same account on which before insert is happening');
                    }                    
                    else if(acc.Account_Teams__r.size() > 0){
                        // System.debug('1ifelse++');
                        
                        
                        for(integer i=0;i<acc.Account_Teams__r.size();i++){         //  account_team__c atc : acc.Account_Teams__r
                            // System.debug('acc.accteam[i]++++'+acc.Account_Teams__r[i]);
                            // System.debug('i+++'+i);
                            // System.debug('ateamsize++'+acc.Account_Teams__r.size());
                            if(i<acc.Account_Teams__r.size()){
                                // System.debug('2+i+++'+i);
                                // System.debug('2+ateamsize++'+acc.Account_Teams__r.size());
                                if(acc.Account_Teams__r[i].bdm__c == mapUsername.get(acc.Account_Teams__r[i].account__r.sfx_code__c)){
                                    
                                    if(mapActeam.get(acc.SFX_Code__c).National1__c == true){
                                        // System.debug('1+++');
                                        acc.Account_Teams__r[i].National1__c = mapActeam.get(acc.SFX_Code__c).National1__c;
                                    }
                                    if(mapActeam.get(acc.SFX_Code__c).National2__c == true){
                                        // System.debug('2+++');
                                        acc.Account_Teams__r[i].National2__c = mapActeam.get(acc.SFX_Code__c).National2__c;
                                    }
                                    if(mapActeam.get(acc.SFX_Code__c).National3__c == true){
                                        // System.debug('3+++');
                                        acc.Account_Teams__r[i].National3__c = mapActeam.get(acc.SFX_Code__c).National3__c;
                                    }
                                    if(mapActeam.get(acc.SFX_Code__c).National4__c == true){
                                        // System.debug('4+++');
                                        acc.Account_Teams__r[i].National4__c = mapActeam.get(acc.SFX_Code__c).National4__c;
                                    }
                                    updlstAT.add(acc.Account_Teams__r[i]); mapAteamStatus.put(acc.Account_Teams__r[i].account__c,true);
                                }
                            }
                            if(i == acc.Account_Teams__r.size() - 1){
                                // System.debug('3+i++'+i);
                                // System.debug('++acc.Account_Teams__r.size()+++'+acc.Account_Teams__r.size());
                                
                                if(!mapAteamStatus.containskey(acc.Account_Teams__r[i].account__c) ){  //|| mapAteamStatus.get(acc.Account_Teams__r[i].account__c) != true
                                    // System.debug('gya++');
                                    Account_Team__c a = new Account_Team__c();
                                    a.Account__c = acc.Id;
                                    a.BDM__c = mapUsername.get(acc.SFX_Code__c);
                                    a.National1__c = mapActeam.get(acc.SFX_Code__c).National1__c;
                                    a.National2__c = mapActeam.get(acc.SFX_Code__c).National2__c;
                                    a.National3__c = mapActeam.get(acc.SFX_Code__c).National3__c;
                                    a.National4__c = mapActeam.get(acc.SFX_Code__c).National4__c;
                                    newlstAT.add(a);
                                    AccountShare ash = new AccountShare();
                                    ash.accountid = acc.Id;
                                    ash.userorgroupid = mapUsername.get(acc.SFX_Code__c);
                                    ash.accountaccesslevel = 'Edit';    
                                    ash.OpportunityAccessLevel = 'None';
                                    ash.CaseAccessLevel = 'None';
                                    lstAS.add(ash);
                                }
                            }
                        }
                        
                        
                        /*if(mapActeam.get(acc.SFX_Code__c).national1__c == true){
acc.Account_Teams__r[0].national1__c = true;
}
if(mapActeam.get(acc.SFX_Code__c).national2__c == true){
acc.Account_Teams__r[0].national2__c = true;
}
if(mapActeam.get(acc.SFX_Code__c).national3__c == true){
acc.Account_Teams__r[0].national3__c = true;
}
if(mapActeam.get(acc.SFX_Code__c).national4__c == true){
acc.Account_Teams__r[0].national4__c = true;
}
updlstAT.add(acc.Account_Teams__r[0]);*/
                    }
                    else if(acc.Account_Teams__r.size() == 0){
                        // System.debug('2ifelse++');
                        Account_Team__c atm = new Account_Team__c();
                        atm.Account__c = acc.Id;
                        atm.BDM__c = mapUsername.get(acc.SFX_Code__c);
                        atm.National1__c = mapActeam.get(acc.SFX_Code__c).National1__c;
                        atm.National2__c = mapActeam.get(acc.SFX_Code__c).National2__c;
                        atm.National3__c = mapActeam.get(acc.SFX_Code__c).National3__c;
                        atm.National4__c = mapActeam.get(acc.SFX_Code__c).National4__c;
                        newlstAT2.add(atm);
                        AccountShare ash = new AccountShare();
                        ash.accountid = acc.Id;
                        ash.userorgroupid = mapUsername.get(acc.SFX_Code__c);
                        ash.accountaccesslevel = 'Edit';    
                        ash.OpportunityAccessLevel = 'None';
                        ash.CaseAccessLevel = 'None';
                        lstAS2.add(ash);
                        
                    }
                }
            }
            // System.debug('newlstAT++'+newlstAT);
            // System.debug('newlstATSize++'+newlstAT.size());
            // System.debug('newlstAT2++'+newlstAT);
            // System.debug('newlstAT2Size++'+newlstAT.size());
            // System.debug('updlstAT++'+updlstAT);
            // System.debug('lstAS2++'+lstAS2);
            if(!newlstAT.isEmpty()){
                checkRecursive.firstRun = false;
                
                //insert newlstAT;
                Database.SaveResult[] results1 = Database.insert(newlstAT, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results1) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'newATNational:newlstAT', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
                
            }
            if(!newlstAT2.isEmpty()){
                checkRecursive.firstRun = false;
                //insert newlstAT2;
                Database.SaveResult[] results2 = Database.insert(newlstAT2, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results2) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'newATNational:newlstAT2', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }
            
            if(!updlstAT.isEmpty()){
                checkRecursive.firstRun = false;
                update updlstAT;
                Database.SaveResult[] results3 = Database.insert(updlstAT, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results3) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'newATNational:results3', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }
            if(!lstAS.isEmpty()){
                checkRecursive.firstRun = false;
                //insert lstAS;
                Database.SaveResult[] results = Database.insert(lstAS, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'newATNational:lstAS', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }
            if(!lstAS2.isEmpty()){
                checkRecursive.firstRun = false;
                //insert lstAS2;
                Database.SaveResult[] resultslstAS2 = Database.insert(lstAS2, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : resultslstAS2) {
                    if(result.isSuccess()) {
                        // System.debug('Successfully inserted Accounts : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'helperAccountTeam', 'newATNational:lstAS2', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                            // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }
            checkRecursive.firstRun = true;
            
        }catch(Exception e){
             System.debug('Exception:'+e.getMessage());
        }
        
    }
    
    /**
    @Author          : KR SANSI - SAC-547
    @Company         : IBM
    @Description     : This method is used to update composite key if bdm is changed 
    @Date            : 12/04/2024	 
    */
    public static void updateCompositeKey(List<Account_Team__c> accountTeamList){
         
        for(Account_Team__c accountTeam : accountTeamList){
             // System.debug('accountTeam list ---->'+accountTeam);
            // System.debug('accountTeam composite key ---->'+accountTeam.PropelI_Composite_Key__c);
            if(String.isNotBlank(accountTeam.PropelI_Composite_Key__c	)){                 
                String compositeKey = accountTeam.PropelI_Composite_Key__c	;
            	List<String> compositeKeyList = compositeKey.split('::'); 
                if(compositeKeyList.size() == 2){
                    String newCompositeKey = accountTeam.BDMPropelI__c + '::' + compositeKeyList[1];
                    // System.debug('newCompositeKey--->'+newCompositeKey);
                    accountTeam.PropelI_Composite_Key__c = newCompositeKey;
                }
            }
        }
    }
    
    /**
    @Author          : KR SANSI - SAC-547
    @Company         : IBM
    @Description     : This method is used to update composite key if bdm is changed on Account Team
    @Date            : 12/04/2024	 
    */
    public static void updateCompositeKeyOnPropelIBDM(List<Account_Team__c> accountTeamList, Map<Id, Account_Team__c> mapOldAteam){         
        List<PropelI_BDM_Mapping__c> updateBDMList = new List<PropelI_BDM_Mapping__c>();
        Boolean updateBDM;
        for(Account_Team__c accountTeam : accountTeamList){
            updateBDM = false;
            PropelI_BDM_Mapping__c bdm = new PropelI_BDM_Mapping__c(Id = accountTeam.PropelI_BDM_Mapping__c);
            if(String.isNotBlank(accountTeam.PropelI_Composite_Key__c)){
                String compositeKey = accountTeam.PropelI_Composite_Key__c	;
            	List<String> compositeKeyList = compositeKey.split('::');
                if(compositeKeyList.size() == 2){
                    updateBDM = true;
                    String newCompositeKey = accountTeam.BDMPropelI__c + '::' + compositeKeyList[1];
                    bdm.PropelI_Composite_Key__c = newCompositeKey;
                    bdm.PropelI_BDM__c = accountTeam.BDMPropelI__c;
                    bdm.OwnerId = accountTeam.BDMPropelI__c;
                }
            }
            // System.debug('accountTeam.Collection__c-->'+accountTeam.Collection__c);
            // System.debug('mapOldAteam.get(accountTeam.Id).Collection__c-->'+mapOldAteam.get(accountTeam.Id).Collection__c);
            if(accountTeam.Collection__c != mapOldAteam.get(accountTeam.Id).Collection__c){
                bdm.Collection__c = accountTeam.Collection__c;
                updateBDM = true;
            }
            if(accountTeam.Submission__c != mapOldAteam.get(accountTeam.Id).Submission__c){
                bdm.Submission__c = accountTeam.Submission__c;
                updateBDM = true;
            }
            // System.debug('bdm-->'+bdm); 
            if(updateBDM){
                updateBDMList.add(bdm);
            }            
        }  
        // System.debug('updateBDMList-->'+updateBDMList); 
        if(updateBDMList.size() > 0){
            try{
                update updateBDMList;
            }catch(Exception exp){
                LoggerUtil.createErrorLog('helperAccountTeam', 'updateCompositeKeyOnPropelIBDM', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
            }
        }
            
    }
    
    /**
    @Author          : KR SANSI - SAC-547
    @Company         : IBM
    @Description     : This method is used to create AccountShare and remove existing sharing 
    @Date            : 12/04/2024	 
    */
    
    public static void updateAccountShare(List<Account_Team__c> accountTeamList, Map<Id, Account_Team__c> mapOldAteam, String accountId){
        
        String rcRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();

        // System.debug(' updateCompositeKeyList :'+accountTeamList +' , '+ mapOldAteam);
		accountTeamList = [SELECT Id, Account__c, Account__r.RecordTypeId, Account__r.Parent.Id, Account__r.Parent.Parent.id, BDMPropelI__c
                           FROM Account_Team__c 
                           WHERE Id IN : accountTeamList];
        // System.debug('accountTeamList-->'+accountTeamList);
        String sfxId = accountTeamList[0].Account__r.Parent.Parent.Id;
        String oldBdmId = mapOldAteam.get(accountTeamList[0].Id).BDMPropelI__c;
        // System.debug('sfxId====>'+sfxId);
        // System.debug('oldBdmId====>'+oldBdmId);
        
        List<AccountShare> newAccountShareList = new List<AccountShare>();
        Set<String> oldAccountIds = new Set<String>();
        Set<String> oldUserIds = new Set<String>();
        List<Account_Team__c> oldAccountTeamList = new List<Account_Team__c>();
        //List<Account_Team__c> sfxAccountTeamList = new List<Account_Team__c>();
        
        List<Account_Team__c> allAccountTeamList = [SELECT Id FROM Account_Team__c 
                                                    WHERE Account__r.Parent.Parent.Id =: sfxId AND 
                                                    BDMPropelI__c =: oldBdmId];
        
        Integer allAccountTeamCount = allAccountTeamList.size();
        // System.debug('allAccountTeamCount====>'+allAccountTeamCount);
        Integer changedAccountTeamCount = accountTeamList.size();
        // System.debug('changedAccountTeamCount====>'+changedAccountTeamCount);
        
        Map<String, String> oldAccountTeamBDMMap = new Map<String, String>();

        for(Account_Team__c accountTeam : accountTeamList){

            Account_Team__c oldAccoutTeam = mapOldAteam.get(accountTeam.Id);
            oldAccountIds.add(oldAccoutTeam.Account__c);
            
            AccountShare acShare = createAccountShare(accountTeam);
            // System.debug('acShare-->'+acShare);
            newAccountShareList.add(acShare);

            if(accountTeam.Account__r.RecordTypeId == rcRecordTypeId){
                //AccountShare acShareSfx = createAccountShareSfx(accountTeam);
                List<AccountShare> ashList = createAccountShareSfxAndService(accountTeam);
                // System.debug('ashList---->'+ashList);
            	newAccountShareList.addAll(ashList);
                //sfxAccountTeamList.add(accountTeam);
                if(allAccountTeamCount == 0){
                    oldAccountIds.add(accountTeam.Account__r.Parent.Id);
					oldAccountIds.add(accountTeam.Account__r.Parent.Parent.Id);                    
                }                
            }		
             
            oldUserIds.add(oldAccoutTeam.BDMPropelI__c);
            oldAccountTeamList.add(oldAccoutTeam);
			oldAccountTeamBDMMap.put(oldAccoutTeam.Id, oldAccoutTeam.BDMPropelI__c);            
        }
        
        List<Account_Team__c> oldAccountTeamListNew = [SELECT Id, Account__c, Account__r.RecordTypeId, Account__r.Parent.Parent.id, BDMPropelI__c
                           FROM Account_Team__c 
                           WHERE Id IN : oldAccountTeamList];
        
        for(Account_Team__c accountTeam : oldAccountTeamListNew){
            accountTeam.BDMPropelI__c = oldAccountTeamBDMMap.get(accountTeam.Id);
        }
        // System.debug(' oldAccountTeamList :'+oldAccountTeamList );
        // System.debug('newAccountShareList---->'+newAccountShareList);
        // System.debug('oldAccountIds-->'+oldAccountIds);
        // Delete Sharing
        List<AccountShare> existingAccountShareList = getAccountShareRecords(oldAccountIds, oldUserIds);
        // System.debug('existingAccountShareList--->'+existingAccountShareList);
        if(existingAccountShareList.size() > 0){
            deleteAccountSharing(existingAccountShareList, oldAccountTeamListNew);
        }       
        
        // update account sharing
        try{
            //insert newAccountShareList;
            Database.SaveResult[] results = Database.insert(newAccountShareList, false);
            // iterate over the list of returned results
            for(Database.SaveResult result : results) {
                if(result.isSuccess()) {
                    // System.debug('Successfully inserted Accounts : ' + result.getId());
                } else {
                    // iterate over the failed ones
                    for(Database.Error error : result.getErrors()) {
                        ExceptionHandling.Exception( 'helperAccountTeam', 'updateAccountShare', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                        // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                    }
                }
            }
            
            // System.debug('newAccountShareList--->'+newAccountShareList);
        }catch(Exception exp){
            LoggerUtil.createErrorLog('helperAccountTeam', 'updateAccountShare', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    
    
    /*
    public static void updateAccountShareOld(List<Account_Team__c> accountTeamList, Map<Id, Account_Team__c> mapOldAteam, String accountId){
        
        String rcRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();

        // System.debug(' updateCompositeKeyList :'+accountTeamList +' , '+ mapOldAteam);
		accountTeamList = [SELECT Id, Account__c, Account__r.RecordTypeId, Account__r.Parent.Id, Account__r.Parent.Parent.id, BDMPropelI__c
                           FROM Account_Team__c 
                           WHERE Id IN : accountTeamList];
        //
        String sfxId = accountTeamList[0].Account__r.Parent.Parent.Id;
        String oldBdmId = mapOldAteam.get(accountTeamList[0].Id).BDMPropelI__c;
        // System.debug('sfxId====>'+sfxId);
        // System.debug('oldBdmId====>'+oldBdmId);
        
        List<AccountShare> newAccountShareList = new List<AccountShare>();
        Set<String> oldAccountIds = new Set<String>();
        Set<String> oldUserIds = new Set<String>();
        List<Account_Team__c> oldAccountTeamList = new List<Account_Team__c>();
        //List<Account_Team__c> sfxAccountTeamList = new List<Account_Team__c>();
        
        List<Account_Team__c> allAccountTeamList = [SELECT Id FROM Account_Team__c 
                                                    WHERE Account__r.Parent.Parent.Id =: sfxId AND 
                                                    BDMPropelI__c =: oldBdmId];
        
        Integer allAccountTeamCount = allAccountTeamList.size();
        // System.debug('allAccountTeamCount====>'+allAccountTeamCount);
        Integer changedAccountTeamCount = accountTeamList.size();
        // System.debug('changedAccountTeamCount====>'+changedAccountTeamCount);

        for(Account_Team__c accountTeam : accountTeamList){

            Account_Team__c oldAccoutTeam = mapOldAteam.get(accountTeam.Id);
            oldAccountIds.add(oldAccoutTeam.Account__c);
            
            AccountShare acShare = createAccountShare(accountTeam);
            // System.debug('acShare-->'+acShare);
            newAccountShareList.add(acShare);

            if(accountTeam.Account__r.RecordTypeId == rcRecordTypeId){
                AccountShare acShareSfx = createAccountShareSfx(accountTeam);
                // System.debug('acShareSfx---->'+acShareSfx);
            	newAccountShareList.add(acShareSfx);
                //sfxAccountTeamList.add(accountTeam);
                if(allAccountTeamCount == 0){
                    oldAccountIds.add(accountTeam.Account__r.Parent.Parent.Id);                    
                }                
            }		
             
            oldUserIds.add(oldAccoutTeam.BDMPropelI__c);
            oldAccountTeamList.add(oldAccoutTeam);            
        }
        
        oldAccountTeamList = [SELECT Id, Account__c, Account__r.RecordTypeId, Account__r.Parent.Parent.id, BDMPropelI__c
                           FROM Account_Team__c 
                           WHERE Id IN : oldAccountTeamList];
        
        // System.debug(' oldAccountTeamList :'+oldAccountTeamList );
        // System.debug('newAccountShareList---->'+newAccountShareList);
        // System.debug('oldAccountIds-->'+oldAccountIds);
        // Delete Sharing
        List<AccountShare> existingAccountShareList = getAccountShareRecords(oldAccountIds, oldUserIds);
        // System.debug('existingAccountShareList--->'+existingAccountShareList);
        if(existingAccountShareList.size() > 0){
            deleteAccountSharing(existingAccountShareList, oldAccountTeamList);
        }       
        
        // update account sharing
        try{
            insert newAccountShareList;
            // System.debug('newAccountShareList--->'+newAccountShareList);
        }catch(Exception exp){
            LoggerUtil.createErrorLog('helperAccountTeam', 'updateAccountShare', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    \*/
    /**
    @Author          : KR SANSI - SAC-547
    @Company         : IBM
    @Description     : This method is used to create AccountShare Record Object
    @Date            : 12/04/2024	 
    */    
    public static AccountShare createAccountShare(Account_Team__c accountTeam){
        if(String.isNotBlank(accountTeam.Account__c) && String.isNotBlank(accountTeam.BDMPropelI__c)){             
            AccountShare ash = new AccountShare();
            ash.AccountId = accountTeam.Account__c;
            ash.UserOrGroupId = accountTeam.BDMPropelI__c;
            ash.AccountAccessLevel = 'Edit';
            ash.OpportunityAccessLevel = 'None'; 
            ash.CaseAccessLevel = 'None';        
            ash.RowCause = 'Manual';
        	return ash;
        }
        return null;
    }

    public static AccountShare createAccountShareSfx(Account_Team__c accountTeam){
         
        if(String.isNotBlank(accountTeam.Account__c) && String.isNotBlank(accountTeam.BDMPropelI__c)){
            // System.debug('create sfx sharing...');
            AccountShare ash = new AccountShare();
            ash.AccountId = accountTeam.Account__r.Parent.Parent.Id;
            ash.UserOrGroupId = accountTeam.BDMPropelI__c;
            ash.AccountAccessLevel = 'Edit';
            ash.OpportunityAccessLevel = 'None'; 
            ash.CaseAccessLevel = 'None';        
            ash.RowCause = 'Manual';
        	return ash;
        }
        return null;
    }
    
    public static List<AccountShare> createAccountShareSfxAndService(Account_Team__c accountTeam){
         
        List<AccountShare> response = new List<AccountShare>();
        if(String.isNotBlank(accountTeam.Account__c) && String.isNotBlank(accountTeam.BDMPropelI__c)){
            // System.debug('create sfx sharing...');
            AccountShare ashService = new AccountShare();
            ashService.AccountId = accountTeam.Account__r.Parent.Id;
            ashService.UserOrGroupId = accountTeam.BDMPropelI__c;
            ashService.AccountAccessLevel = 'Edit';
            ashService.OpportunityAccessLevel = 'None'; 
            ashService.CaseAccessLevel = 'None';        
            ashService.RowCause = 'Manual';
            response.add(ashService);
            
            AccountShare ash = new AccountShare();
            ash.AccountId = accountTeam.Account__r.Parent.Parent.Id;
            ash.UserOrGroupId = accountTeam.BDMPropelI__c;
            ash.AccountAccessLevel = 'Edit';
            ash.OpportunityAccessLevel = 'None'; 
            ash.CaseAccessLevel = 'None';        
            ash.RowCause = 'Manual';
            response.add(ash);
        	 
        }
        return response;
    }
    
    /**
    @Author          : KR SANSI - SAC-547
    @Company         : IBM
    @Description     : This method is used to get AccountShared Records Object
    @Date            : 12/04/2024	 
    */
    public static List<AccountShare> getAccountShareRecords(Set<String> accountIds, Set<String> userIds){
        return [SELECT Id, AccountId, UserOrGroupId 
                FROM AccountShare 
                WHERE AccountId IN : accountIds AND 
                UserOrGroupId IN : userIds AND 
                RowCause = 'Manual'];
    }
    
    /**
    @Author          : KR SANSI - SAC-547
    @Company         : IBM
    @Description     : This method is used to delete AccountShared Records 
    @Date            : 12/04/2024	 
    */
    public static void deleteAccountSharing(List<AccountShare> accountShareList, List<Account_Team__c> accountTeamList){
        String rcRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        List<AccountShare> deleteAccountShareList = new List<AccountShare>();
        for(Account_Team__c accountTeam : accountTeamList){
            for(AccountShare accShare : accountShareList){
                if(
                    (accShare.AccountId == accountTeam.Account__c  || 
                     (accountTeam.Account__r.RecordTypeId == rcRecordTypeId && accShare.AccountId == accountTeam.Account__r.Parent.Parent.Id)
                     )
                    && accShare.UserOrGroupId == accountTeam.BDMPropelI__c){
                    deleteAccountShareList.add(accShare);
                }
            }
        } 
        // System.debug('deleteAccountShareList : '+deleteAccountShareList);
        if(deleteAccountShareList.size() > 0){
            try{
                
                delete deleteAccountShareList;
            }catch(Exception exp){ 
                LoggerUtil.createErrorLog('helperAccountTeam', 'deleteAccountSharing', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
            }
        }
    }
    
    
    public static void syncBDMWithAccountTeam(List<Account_Team__c> accountTeamList){
        Set<String> bdmIds = new Set<String>();
        Map<String, PropelI_BDM_Mapping__c> updateBDMMap = new Map<String, PropelI_BDM_Mapping__c>();
        Boolean isUpdate;
        accountTeamList = [SELECT Id, Submission__c, Collection__c, PropelI_BDM_Mapping__c FROM Account_Team__c WHERE Id IN : accountTeamList];
        for(Account_Team__c accountTeam : accountTeamList){
            bdmIds.add(accountTeam.PropelI_BDM_Mapping__c);
        }
        
        if(bdmIds.size() > 0){
			Map<Id, PropelI_BDM_Mapping__c> bdmMap = new Map<Id, PropelI_BDM_Mapping__c>([SELECT Id, Collection__c, Submission__c FROM PropelI_BDM_Mapping__c WHERE Id IN : bdmIds]); 
            for(Account_Team__c accountTeam : accountTeamList){
                isUpdate = false;
                if(bdmMap.containsKey(accountTeam.PropelI_BDM_Mapping__c)){
                    PropelI_BDM_Mapping__c bdmRecord = bdmMap.get(accountTeam.PropelI_BDM_Mapping__c);
                    if(bdmRecord.Submission__c != accountTeam.Submission__c){
                        bdmRecord.Submission__c = accountTeam.Submission__c;
                        isUpdate = true;
                    }
                    if(bdmRecord.Collection__c != accountTeam.Collection__c){
                        bdmRecord.Collection__c = accountTeam.Collection__c;
                        isUpdate = true;
                    }
                    if(isUpdate){
                        updateBDMMap.put(bdmRecord.Id, bdmRecord);
                    }
                }
            }
        }
        // System.debug('updateBDMMap-->'+updateBDMMap);
        if(updateBDMMap.size() > 0 ){
            update updateBDMMap.values();
        }
    }

    public static void shareAccountHierarchy(List<Account_Team__c> accountTeamList, Map<Id, Account_Team__c> mapOldAteam, String accountId){
        
        List<Account> accList = getAllAccountHierarchy(accountId);
        if(accList.size() > 0){
            List<String> accShareBDM = new List<String>();
            List<String> removeShareBDM = new List<String>();
            List<String> accShareRemoveBDM = new List<String>();
            for(Account_Team__c at: accountTeamList){
                // update case
                /*if (at.Assigned_Branch__c != null) {
                    accList.add(at.Assigned_Branch__r);
                }*/
                if(mapOldAteam != null && at.BDMPropelI__c != mapOldAteam.get(at.Id).BDMPropelI__c){
                    accShareBDM.add(at.BDMPropelI__c);
                    removeShareBDM.add(mapOldAteam.get(at.Id).BDMPropelI__c);
                }
                //insert case
                if(mapOldAteam == null && at.BDMPropelI__c != null){
                    accShareBDM.add(at.BDMPropelI__c); 
                }
            }
            List<AccountShare> accShareList = new List<AccountShare>();
            
            if(accShareBDM.size() > 0){
                for(String userId : accShareBDM){ 
                    for(Account acc : accList){
                        accShareList.add(createAccountShare(acc.Id, userId));
                    }                    
                }
            }
            
            // remove sharing   
            List<Account_Team__c> acTeamList = [SELECT Id, BDMPropelI__c FROM Account_Team__c WHERE 
                                                BDMPropelI__c IN : removeShareBDM AND 
                                                Account__c IN : accList
                                               ];
            for(Account_Team__c at: acTeamList){
                for(Integer index = 0; index < removeShareBDM.size(); index++){
                    if(at.BDMPropelI__c == removeShareBDM.get(index)){
                        removeShareBDM.remove(index);
                    }
                }
            }
            List<AccountShare> removeAccountShareList = [SELECT Id FROM AccountShare WHERE AccountId IN : accList AND UserOrGroupId IN : removeShareBDM];
            
            // Delete sharing 
            Database.DeleteResult[] results = Database.delete(removeAccountShareList, false);
            for(Database.DeleteResult result : results) {
                if(result.isSuccess()) {
                    // System.debug('Successfully inserted Accounts : ' + result.getId());
                } else {
                    // iterate over the failed ones
                    for(Database.Error error : result.getErrors()) {
                        ExceptionHandling.Exception( 'shareAccountHierarchy', 'deleteAccountShare', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                        // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                    }
                }
            }
            
            //insert Account Shareing 
            Database.SaveResult[] saveResults = Database.insert(accShareList, false);
            // iterate over the list of returned results
            for(Database.SaveResult result : saveResults) {
                if(result.isSuccess()) {
                    // System.debug('Successfully inserted Accounts : ' + result.getId());
                } else {
                    // iterate over the failed ones
                    for(Database.Error error : result.getErrors()) {
                        ExceptionHandling.Exception( 'shareAccountHierarchy', 'updateAccountShare', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage()); 
                        // System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                    }
                }
            }
        }
    }
    
    public static List<Account> getAllAccountHierarchy(String accountId){       
        // System.debug('getAllAccountHierarchy-->'+accountId);
        String rcRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
		Account accRecord = [SELECT Id, RecordTypeId, ParentId FROM Account WHERE Id =: accountId];
        
        List<Account> accList = [SELECT Id FROM Account WHERE
                                 /*(
                                     Id =: accountId AND 
                                     RecordType.DeveloperName = 'Prospect_Customer'
                                 ) OR*/ 
                                 (
                                     ParentId =: accountId AND 
                                     Parent.RecordType.DeveloperName = 'Prospect_Customer'
                                 ) OR (
                                     Parent.ParentId =: accountId AND 
                                     Parent.Parent.RecordType.DeveloperName = 'Prospect_Customer'
                                 ) OR (
                                 	 Parent.Parent.ParentId =: accountId AND
                                     Parent.Parent.Parent.RecordType.DeveloperName = 'Prospect_Customer'
                                 ) OR (
                                 	 Parent.Parent.Parent.ParentId =: accountId AND 
									 Parent.Parent.Parent.Parent.RecordType.DeveloperName = 'Prospect_Customer'                                     
                                 )
                                 
                                                                  
                                ];
        
        if(accRecord.RecordTypeId == rcRecordTypeId){
            accList.add(accRecord);
            Account parentAccount = new Account(Id = accRecord.ParentId);
            accList.add(parentAccount);
        }
        // System.debug('accList-->'+accList);
        return accList;
    }
    
    public static AccountShare createAccountShare(String accountId, String userId){          
        // System.debug('create sfx sharing...');
        AccountShare ash = new AccountShare();
        ash.AccountId = accountId;
        ash.UserOrGroupId = userId;
        ash.AccountAccessLevel = 'Edit';
        ash.OpportunityAccessLevel = 'None'; 
        ash.CaseAccessLevel = 'None';        
        ash.RowCause = 'Manual';
        return ash;        
    }
    
    public static void deleteHierarchyDelete(List<Account_Team__c> lstAccountTeams){
        // System.debug('lstAccountTeams-->'+lstAccountTeams);
        List<String> accountIds = new List<String>();
        List<String> bdmIds = new List<String>();
        Map<String, List<String>> accountUserList = new Map<String, List<String>>();
        for(Account_Team__c accountTeam : lstAccountTeams){
            accountIds.add(accountTeam.Account__c);
            bdmIds.add(accountTeam.BDMPropelI__c); 
            
            List<Account> accList = getAllAccountHierarchy(accountTeam.Account__c);
            for(Account acc : accList){
                accountIds.add(acc.Id);
            }
                
        }		
        // System.debug('bdmIds-->'+bdmIds);
        List<Account_Team__c> remainingAccountTeams = [SELECT Id, Account__c, BDMPropelI__c FROM Account_Team__c WHERE Account__c IN : accountIds];
        // System.debug('remainingAccountTeams-->'+remainingAccountTeams);
        for(Account_Team__c accountTeam : remainingAccountTeams){
            if(!accountUserList.containsKey(accountTeam.Account__c)){
                accountUserList.put(accountTeam.Account__c, new List<String>());
            }
            accountUserList.get(accountTeam.Account__c).add(accountTeam.BDMPropelI__c);
        }
        // System.debug('accountUserList-->'+accountUserList);
        List<AccountShare> accShareList = [SELECT Id, UserOrGroupId, AccountId FROM AccountShare 
                                           WHERE UserOrGroupId IN : bdmIds AND AccountId IN : accountIds AND
                                           RowCause = 'Manual'];
        // System.debug('accShareList-->'+accShareList);
        List<AccountShare> deleteAccShareList = new List<AccountShare>();
        for(AccountShare accShare : accShareList){
            if(accountIds.contains(accShare.AccountId) && bdmIds.contains(accShare.UserOrGroupId)){
                if(accountUserList.containsKey(accShare.AccountId)){
                    List<String> userList = accountUserList.get(accShare.AccountId);
                    if(userList.contains(accShare.UserOrGroupId)){
                        
                    }else{
                        deleteAccShareList.add(accShare);
                    }
                } else{
                    deleteAccShareList.add(accShare);
                }
            }
        }
        // System.debug('deleteAccShareList-->'+deleteAccShareList);
        if(deleteAccShareList.size() > 0){
            delete deleteAccShareList;
        }
    }
    
}