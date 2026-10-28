//Helper class for Opportunity trigger to perform various operations like updating the Monthly potential,surface potential and 3 pl potential on parent account, providing sharing of opportunity to
//Account Team Members, verifying business details record created etc.
public without sharing class OpportunityTriggerHandler{
    
    //This method is to update the Monthly potential,surface potential and 3 pl potential on account.
    public void customRollup(Set<Id> accountIds)
    {
        try{
            Map<Id,Account> mapaccountlist = new Map<Id,Account>();
            Map<Id,List<opportunity__c>> mapOpportToAccount = new Map<Id,List<opportunity__c>>();
            for(Account acc :[select id,Monthly_Potential_Surface__c,Monthly_Potential_Air__c,X3PL_Potential__c,(select id ,X3PL_Potential__c,Monthly_Potential_Air__c,Monthly_Potential_Surface__c from Opportunities__r) from account where id IN : accountIds])
            {
                mapOpportToAccount.put(acc.Id , acc.Opportunities__r);
                mapaccountlist.put(acc .id ,acc);
            }
            Decimal monSur  = 0;
            Decimal monAir  = 0;
            Decimal mon3Pl  = 0;
            for(Id ac : mapOpportToAccount.keySet()){
                for(opportunity__c objOpp : mapOpportToAccount.get(ac)){
                    if(objOpp.Monthly_Potential_Surface__c != null && objOpp.Monthly_Potential_Surface__c > 0 ){
                        monSur = monSur + objOpp.Monthly_Potential_Surface__c;
                    }
                    if(objOpp.Monthly_Potential_Air__c != null && objOpp.Monthly_Potential_Air__c > 0 ){
                        monAir = monAir + objOpp.Monthly_Potential_Air__c;
                    }
                    if(objOpp.X3PL_Potential__c != null && objOpp.X3PL_Potential__c > 0 ){
                        mon3Pl = mon3Pl + objOpp.X3PL_Potential__c;
                    }
                }
                
                mapaccountlist.get(ac).Monthly_Potential_Surface__c = monSur;
                
                
                mapaccountlist.get(ac).Monthly_Potential_Air__c = monAir;
                
                
                mapaccountlist.get(ac).X3PL_Potential__c = mon3Pl;
                
            }
            DataBase.update (mapaccountlist.Values() , False);
        }catch(Exception e){
            System.debug('<< error message >> ' +e.getMessage());
            System.debug('<< error message >> ' +e.getLineNumber());
        }
    } 
    
    /*Method to check validation of Opportunity on creation if account has sfx child or not (for existing opp)
* Added By Prabhsimran Singh */
    public void oppInsertValidation(List<opportunity__c> lstOpp,List<Id> lstOppId){
        try{
            Map<Id,Id> mapOppAccIds = new Map<Id,Id>();
            Map<Id,Boolean> mapAccChildVal = new Map<Id,Boolean>();
            Id rIdSfx = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
            Id rIdPros = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
            
            for(opportunity__c opp : lstOpp){
                
                mapOppAccIds.put(opp.Id,opp.Account__c);
            }
            
            for(account acc : [select id,name,(select id,name from ChildAccounts where recordtypeid =: rIdSfx) from account where recordtypeid =: rIdPros and Id in: mapOppAccIds.values()]){
                
                if(acc.ChildAccounts.size() > 0){
                    mapAccChildVal.put(acc.Id,true);
                }
                else{
                    mapAccChildVal.put(acc.Id,false);
                }
            }
            for(opportunity__c opp : lstOpp){
                
                if(mapAccChildVal.get(opp.Account__c) == false){
                    opp.Account__c.addError('Renewal Opportunity cannot be created for the Accounts having no SFX Code.');
                }
            }
        }catch(Exception e){
            System.debug('<< error message >> ' +e.getMessage());
            System.debug('<< error message >> ' +e.getLineNumber());
        }
    }
    
    //Calling the method to update 'Qrm_Email__c' field on Opportunity with respective account teams' BDM Email
    public void updateEmail(List<opportunity__c> lstOpp){
        system.debug('lstOpp'+lstOpp);
        try{
            Set<Id> accntID = new Set<Id>();
            Map<Id , Id> mapChildAcc = new Map<Id , Id>();
            Map<Id,Id> mapParentAcc = new Map<Id,Id>();
            Map<Id,Account_Team__c> mapAccTeam = new Map<Id,Account_Team__c>();
            for(opportunity__c objOpp: lstOpp){
                if(!String.isBlank(objOpp.Account__c)){
                    if(!accntID.contains(objOpp.Account__c)){
                        accntID.add(objOpp.Account__c);
                    }
                    mapParentAcc.put(objOpp.Id, objOpp.Account__c);
                }               
            }
            for(Account_Team__c team : [Select Id, BDMPropelI__r.Id, BDMPropelI__r.email ,National1__c, Account__c from Account_Team__c where Account__c In: accntID AND National1__c = true]){
                mapAccTeam.put(team.Account__c ,team);
            }
            for(opportunity__c objOpp: lstOpp){
                if(mapAccTeam.size() > 0){
                    if(mapParentAcc.containsKey(objOpp.Id) && mapParentAcc.get(objOpp.Id) != null){
                        if(mapAccTeam.containsKey(mapParentAcc.get(objOpp.Id)) && mapAccTeam.get(mapParentAcc.get(objOpp.Id)) != null){
                            objOpp.Qrm_Email__c = mapAccTeam.get(mapParentAcc.get(objOpp.Id)).BDMPropelI__r.email;
                        }
                    }
                }    
            }
            /*for(Account objAcc : [Select Id , (Select Id,National1__c from childAccounts where National1__c = true limit 1) from Account where Id IN : accntID]){
                if(objAcc.ChildAccounts.size() > 0){
                    mapChildAcc.put(objAcc.Id , objAcc.ChildAccounts[0].Id);
                }
            }            
            for(Account objAcc : [Select Id ,(Select Id,BDMPropelI__r.Id,BDMPropelI__r.email ,National1__c from Account_Teams__r where National1__c = true limit 1) from Account where Id IN : mapChildAcc.values()]){
                if(objAcc.Account_Teams__r.size() > 0){
                    mapAccTeam.put(objAcc.Id , objAcc.Account_Teams__r);
                }
            }
            for(opportunity__c objOpp: lstOpp){
                if(mapAccTeam.size() > 0){
                    if(mapParentAcc.get(objOpp.Id) != null){
                        if(mapChildAcc.get(mapParentAcc.get(objOpp.Id)) != null){
                            if(mapAccTeam.get(mapChildAcc.get(mapParentAcc.get(objOpp.Id))) != null){
                                objOpp.Qrm_Email__c = mapAccTeam.get(mapChildAcc.get(mapParentAcc.get(objOpp.Id))).BDMPropelI__r.email;
                            }
                        }
                    }
                }      
            }*/
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            System.debug('Exception:'+e.getLineNumber());
        }
    } 
    
    //Method to share opportunity with Nam1,2,3,4
    public void newOppInsert(List<opportunity__c> lstOpp){
        
        List<Id> lstAccId = new List<Id>();
        Map<Id,Account> mapParentChildAcc = new Map<Id,Account>();
        Map<String,Account_Team__c> mapParentAccAT = new Map<String,Account_Team__c>();
        List<opportunity__share> lstOppShare = new List<opportunity__share>();
        try{
            Id rIdSfx = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
            Id rIdPros = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
            for(opportunity__c opp : lstOpp){
                lstAccId.add(opp.Account__c);
            }
            for(Account acc : [select id,name,(select id,name,Parentid from ChildAccounts where (national1__c=true or
                                                                                                 national2__c=true or national3__c=true or national4__c=true) and recordtypeid =: rIdSfx limit 1) from account
                               where id IN:lstAccId and recordtypeid =: rIdPros]){
                                   if(acc.ChildAccounts.size() > 0){
                                       mapParentChildAcc.put(acc.Id,acc.ChildAccounts[0]);
                                   }
                               }            
            if(!mapParentChildAcc.isEmpty()){
                for(Account_team__c at : [select id,BDMPropelI__c,national1__c,national2__c,national3__c,national4__c,Account__r.parentid from account_team__c
                                          where account__c IN: mapParentChildAcc.values() and (national1__c = true or national2__c = true or national3__c = true or national4__c = true)]){
                                              if(at.National1__c == true){
                                                  mapParentAccAT.put(at.Account__r.parentid+'N1',at);   
                                              }
                                              if(at.National2__c == true){
                                                  mapParentAccAT.put(at.Account__r.parentid+'N2',at);
                                              }
                                              if(at.National3__c == true){
                                                  mapParentAccAT.put(at.Account__r.parentid+'N3',at);
                                              }
                                              if(at.National4__c == true){
                                                  mapParentAccAT.put(at.Account__r.parentid+'N4',at);
                                              }
                                          }
            }            
            for(opportunity__c opp : lstOpp){
                if(mapParentAccAT.containsKey(opp.Account__c+'N1') && opp.ownerId != mapParentAccAT.get(opp.Account__c+'N1').BDMPropelI__c){
                    opportunity__share oppShare = new opportunity__share();
                    oppShare.ParentId = opp.Id;
                    oppShare.UserOrGroupId = mapParentAccAT.get(opp.Account__c+'N1').BDMPropelI__c;
                    oppShare.AccessLevel = 'Edit';
                    lstOppShare.add(oppShare);                    
                }
                if(mapParentAccAT.containsKey(opp.Account__c+'N2') && 
                   (!mapParentAccAT.containsKey(opp.Account__c+'N1') || mapParentAccAT.get(opp.Account__c+'N2').BDMPropelI__c != mapParentAccAT.get(opp.Account__c+'N1').BDMPropelI__c)
                   && opp.ownerId != mapParentAccAT.get(opp.Account__c+'N2').BDMPropelI__c){
                       opportunity__share oppShare = new opportunity__share();
                       oppShare.ParentId = opp.Id;
                       oppShare.UserOrGroupId = mapParentAccAT.get(opp.Account__c+'N2').BDMPropelI__c;
                       oppShare.AccessLevel = 'Edit';
                       lstOppShare.add(oppShare);
                   }
                if(mapParentAccAT.containsKey(opp.Account__c+'N3') && 
                   (!mapParentAccAT.containsKey(opp.Account__c+'N1') || mapParentAccAT.get(opp.Account__c+'N3').BDMPropelI__c != mapParentAccAT.get(opp.Account__c+'N1').BDMPropelI__c) &&
                   (!mapParentAccAT.containsKey(opp.Account__c+'N2') || mapParentAccAT.get(opp.Account__c+'N3').BDMPropelI__c != mapParentAccAT.get(opp.Account__c+'N2').BDMPropelI__c)
                   && opp.ownerId != mapParentAccAT.get(opp.Account__c+'N3').BDMPropelI__c){
                       opportunity__share oppShare = new opportunity__share();
                       oppShare.ParentId = opp.Id;
                       oppShare.UserOrGroupId = mapParentAccAT.get(opp.Account__c+'N3').BDMPropelI__c;
                       oppShare.AccessLevel = 'Edit';
                       lstOppShare.add(oppShare);
                   }
                if(mapParentAccAT.containsKey(opp.Account__c+'N4') && 
                   (!mapParentAccAT.containsKey(opp.Account__c+'N1') || mapParentAccAT.get(opp.Account__c+'N4').BDMPropelI__c != mapParentAccAT.get(opp.Account__c+'N1').BDMPropelI__c) &&
                   (!mapParentAccAT.containsKey(opp.Account__c+'N2') || mapParentAccAT.get(opp.Account__c+'N4').BDMPropelI__c != mapParentAccAT.get(opp.Account__c+'N2').BDMPropelI__c) &&
                   (!mapParentAccAT.containsKey(opp.Account__c+'N3') || mapParentAccAT.get(opp.Account__c+'N4').BDMPropelI__c != mapParentAccAT.get(opp.Account__c+'N3').BDMPropelI__c)
                   && opp.ownerId != mapParentAccAT.get(opp.Account__c+'N4').BDMPropelI__c){
                       opportunity__share oppShare = new opportunity__share();
                       oppShare.ParentId = opp.Id;
                       oppShare.UserOrGroupId = mapParentAccAT.get(opp.Account__c+'N4').BDMPropelI__c;
                       oppShare.AccessLevel = 'Edit';
                       lstOppShare.add(oppShare);
                   }
                
            }
            if(!lstOppShare.isEmpty()){
                insert lstOppShare;
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            System.debug('Exception:'+e.getLineNumber());
        }
    }
    
    //Method to check if PDF exists on opportunity on closed won
    public void checkPDF(List<opportunity__c> lstOpp){
        map<Id,List<ContentDocumentLink>> mapIdCDL = new map<Id,List<ContentDocumentLink>>();
        map<Id,Id> mapoppIdCdlId = new map<Id,Id>();
        map<Id,String> mapOppIdType = new map<Id,String>();
        List<Id> lstOppId = new List<Id>();        
        try{
            for(opportunity__c opp : lstOpp){
                lstOppId.add(opp.Id);
            }
            
            for(ContentDocumentLink cdl : [select id,linkedentityid,contentdocumentid from contentdocumentlink where linkedentityid IN: lstOppId]){
                mapoppIdCdlId.put(cdl.contentdocumentid, cdl.linkedentityid);
            }            
            if(!mapoppIdCdlId.isEmpty()){
                for(contentdocument cd : [select id,title,fileextension from contentdocument where Id IN: mapoppIdCdlId.keySet()]){
                    
                    if(cd.fileextension == 'pdf'){
                        mapOppIdType.put(mapoppIdCdlId.get(cd.Id),'pdf');
                    }
                }
            }            
            for(opportunity__c opp : lstOpp){
                if((mapOppIdType.isEmpty() || mapOppIdType.get(opp.Id) != 'pdf')){                    
                    opp.addError('Please attach Contract PDF.');
                }
            }
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            System.debug('Exception:'+e.getLineNumber());
        }
    }
    //Method to check if buisness details record is exist on opportunity closed won
    public Static Id checkBuisnessDetail(List<opportunity__c> lstOpp){
        try{
            Map<Id,Id> mapBuisnessToOpp = new Map<Id,Id>();
            for(opportunity__c objOpp : [Select Id ,(Select id from Business_Details__r) from Opportunity__c where Id IN : lstOpp]){
                if(objOpp.Business_Details__r != null && objOpp.Business_Details__r.size() > 0){
                    mapBuisnessToOpp.put(objOpp.Id ,objOpp.Business_Details__r[0].Id);
                }
            }
            for(opportunity__c objOpp : lstOpp){
                if(String.isBlank(mapBuisnessToOpp.get(objOpp.id))){
                    return null;
                }
                else {
                    return mapBuisnessToOpp.get(objOpp.id);
                }
            }
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            System.debug('Exception:'+e.getLineNumber());
        }
        return null;
    }
    
    public Static void checkBuisnessDetails(List<opportunity__c> lstOpp){
        try{
            Map<Id,Id> mapBuisnessToOpp = new Map<Id,Id>();
            for(opportunity__c objOpp : [Select Id ,(Select id from Business_Details__r) from Opportunity__c where Id IN : lstOpp]){
                if(objOpp.Business_Details__r != null && objOpp.Business_Details__r.size() > 0){
                    mapBuisnessToOpp.put(objOpp.Id ,objOpp.Business_Details__r[0].Id);
                }
            }
            for(opportunity__c objOpp : lstOpp){
                if(String.isBlank(mapBuisnessToOpp.get(objOpp.id))){
                     objOpp.addError('Please create atleast one Business Detail Record.');
                }
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            System.debug('Exception:'+e.getLineNumber());
        }
    }
    
    public static void checkPermission(List<String> oppIds, List<Opportunity__c> newData){
        Map<Id, Boolean> permissionMap = new Map<Id, Boolean>();
        
        for(Renewal_SFX_RC_Mapping__c rec : [Select Id, Opportunity__c, Name from Renewal_SFX_RC_Mapping__c where Opportunity__c In: oppIds]){
            permissionMap.put(rec.Opportunity__c, true);
        }
        
        for(Opportunity__c opp : newData){
            if(permissionMap.containsKey(opp.Id) && permissionMap.get(opp.Id) == true && (FeatureManagement.checkPermission('Can_Edit_Restricted_Opportunity_Fields')) == false){
                opp.Customer_Type__c.addError('You cannot change the Opportunity type of the opportunity.');
            }
        }
    }
    // Added By Adarsh - SAC-166
    // New Opportunity should be shared with Area manager.
    public void oppShareAreaManager(List<opportunity__c> lstOpp){
        List<opportunity__share> oppShareList = new List<opportunity__share>();
        List<String> areaOppList = new List<String>();
        Map<String,List<Id>> areaUserMap = new Map<String,List<Id>>();
        try{
            Id AMProfileId = [Select Id from profile where name = 'Area Manager' limit 1].Id;
            for(opportunity__c opp : lstOpp){
                areaOppList.add(opp.Area__c);
            }
            List<User> usrList = [Select Id,Name,Area__c, Region__c,ProfileId from User where ProfileId =: AMProfileId And Area__c IN: areaOppList AND isActive = True ];
            system.debug('usrList'+usrList);
            if(!usrList.isEmpty()){
                for(User usr : usrList){
                    if(areaUserMap.containsKey(usr.Area__c)){
                        areaUserMap.get(usr.Area__c).add(usr.Id);
                    }else{
                        List<Id> data = new List<Id>();
                        data.add(usr.Id);
                        areaUserMap.put(usr.Area__c, data);
                    }
                }
            }
            system.debug('areaUserMap'+areaUserMap);
            for(opportunity__c opp : lstOpp){
                if(areaUserMap.containsKey(opp.Area__c)){
                    for(Id usrId : areaUserMap.get(opp.Area__c)){
                        opportunity__share oppShare = new opportunity__share();
                        oppShare.ParentId = opp.Id;
                        oppShare.UserOrGroupId = usrId;
                        oppShare.AccessLevel = 'Read';
                        oppShareList.add(oppShare);
                    }
                }
            }
            if(!oppShareList.isEmpty()){
                Database.SaveResult[] results = Database.insert(oppShareList, false);
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        System.debug('Successfully share opportunity with AM: ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields());
                        }
                    }
                }
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            System.debug('Exception:'+e.getLineNumber());
        }
    }
    //changes end - SAC-166
   
/*Description: Converting workflow rule 
* author : Tarun Sachdeva
* SAC-1457
*/
    public Static void updateOppDetails(List<Opportunity__c> oppList){
        for(Opportunity__c opp : oppList){
            if(opp.Name != null){
                opp.Name =  opp.Name.toUpperCase();
            }
            if(opp.Stage__c == 'Closed Lost' || opp.Stage__c == 'Closed Won'){
                opp.Close_Date__c =  Date.today();
            }
            opp.Assignment_Date__c = System.now();
        }
        
    }
/*Description: Converting workflow rule 
* author : Tarun Sachdeva
* SAC-1457
*/
     public static void updateOppAssigndate(List<Opportunity__c> listOpp, Map<Id,Opportunity__c> oldMap){
        for(Opportunity__c opp : listOpp){
            if(oldMap.get(opp.Id).OwnerId != opp.OwnerId){
                opp.Assignment_Date__c = System.now();
            }
            if(oldMap.get(opp.Id).Stage__c != opp.Stage__c && (opp.Stage__c == 'Closed Lost' || opp.Stage__c == 'Closed Won')){
                 opp.Close_Date__c =  Date.today();
            }
        }
        // Auto add default users as Opportunity Team Members
    }

     public static void addDefaultTeamMembers(List<Opportunity__c> oppList){

            List<Opportunity_Teams__c> teamMembersToInsert = new List<Opportunity_Teams__c>();

            // Read User Ids from Custom Label
            String userIds = System.Label.Default_Opportunity_Team_Users;

            if(String.isBlank(userIds)){
                return;
            }

            List<String> defaultUserIds = userIds.split(',');

            for(Opportunity__c opp : oppList){

                for(User usrId : [Select Id From User Where AD_Id__c In:defaultUserIds]){

                    Opportunity_Teams__c otm = new Opportunity_Teams__c();

                    otm.Opportunity__c = opp.Id;
                    otm.User__c = usrId.Id;
                    

                    teamMembersToInsert.add(otm);
                }
            }

            if(!teamMembersToInsert.isEmpty()){
                insert teamMembersToInsert;
            }
        }
}