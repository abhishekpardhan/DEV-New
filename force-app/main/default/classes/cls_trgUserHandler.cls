/*------------------------------------------------------------
* Author: Safexpress team
* Description: restrict users to edit user details apart from system admin.
* Trigger Class: 
* Test Class:
* Code Coverage: 
* History:
*Modified By:                  Description:      Modified Date:

------------------------------------------------------------------------------------------------------------*/
public class cls_trgUserHandler {
    
    Public Static void restrictUser(List<User> lstNewUser, Map<Id, User> mapOldUsers)
    {
        try {
        String profileIds = System.label.ProfileIdsToAllowEditUserFields;
        Set<String> setProileIds = new Set<String>();   
        setProileIds.addAll(profileIds.split(','));
        for(User eachUsr : lstNewUser)
        {
            if( ( (eachUsr.FirstName != mapOldUsers.get(eachUsr.Id).FirstName)  || 
                 (eachUsr.LastName != mapOldUsers.get(eachUsr.Id).LastName) || 
                 (eachUsr.MobilePhone != mapOldUsers.get(eachUsr.Id).MobilePhone) || 
                 (eachUsr.Title != mapOldUsers.get(eachUsr.Id).Title) ||
                 (eachUsr.MiddleName!= mapOldUsers.get(eachUsr.Id).MiddleName) ||
                 (eachUsr.City != mapOldUsers.get(eachUsr.Id).City) ||
                 (eachUsr.Street != mapOldUsers.get(eachUsr.Id).Street) ||
                 (eachUsr.State != mapOldUsers.get(eachUsr.Id).State) ||
                 (eachUsr.Country != mapOldUsers.get(eachUsr.Id).Country) ||
                 (eachUsr.PostalCode != mapOldUsers.get(eachUsr.Id).PostalCode) ||
                 (eachUsr.Type__c != mapOldUsers.get(eachUsr.Id).Type__c) ||
                 (eachUsr.Journey_Type__c != mapOldUsers.get(eachUsr.Id).Journey_Type__c) ||
                // (eachUsr.Suffix != mapOldUsers.get(eachUsr.Id).Suffix) || Modified by rC for Story : SAC 567
                 (eachUsr.Department != mapOldUsers.get(eachUsr.Id).Department) ||
                 (eachUsr.CompanyName != mapOldUsers.get(eachUsr.Id).CompanyName) ||
                 (eachUsr.Region__c != mapOldUsers.get(eachUsr.Id).Region__c) ||
                 (eachUsr.Area__c != mapOldUsers.get(eachUsr.Id).Area__c) ||
                 (eachUsr.Sportfire_Group__c != mapOldUsers.get(eachUsr.Id).Sportfire_Group__c) ||
                 (eachUsr.Email != mapOldUsers.get(eachUsr.Id).Email) ||
                 (eachUsr.Phone != mapOldUsers.get(eachUsr.Id).Phone)) 
               && !setProileIds.contains(UserInfo.getProfileId()))                 
            {
                eachUsr.addError(System.label.UserDetailsModifyMessage);
            }
        }
        } catch(Exception e) {
            ExceptionHandling.Exception('restrictUser', 'cls_trgUserHandler', e);
        }
        
    }

    public static void handleUserUpdateAndInsert(
            List<User> newList,
            Map<Id, User> oldMap,
            Boolean isInsert,
            Boolean isUpdate
        ) {
        UserTriggerHelper.processUsers(
            newList,
            oldMap,
            isInsert,
            isUpdate
        );
    }

    // ***********SAC-97 starts******************//
    public static void amLeadShr(Map<Id, User> newMap, Map<Id, User> oldMap){
        list<User> userToShareLead = new list<User>();
        list<User> olduserValues = new list<User>();
        Map<Id,string> usrToAreaMap = new Map<Id,string>();
        Map<String,String> ledMap = new Map<String,String>();
        Map<String,String> ledToAreaMap = new Map<String,String>();
        List<Lead__Share> deleteLeadShare = new List<Lead__Share>();
        
        // SAC - user update scenario when area gets changed
        try {
        if(oldMap!=null){
            for(User usr : newMap.values()){               
                
                if(newMap.get(usr.Id).Area__c != oldMap.get(usr.Id).Area__c && usr.Designation__c == 'Area Manager')
                    userToShareLead.add(usr);
                
                if(oldMap.get(usr.Id).Area__c != newMap.get(usr.Id).Area__c && oldMap.get(usr.Id).Designation__c == 'Area Manager'){                     
                    olduserValues.add(oldMap.get(usr.Id));
                }
            } 
            if(olduserValues.size() > 0){
                //**********Implemented queueable to prevent mixed DML error ***********//
                deleteLeadShareQueueable q = new deleteLeadShareQueueable(olduserValues);
                System.enqueueJob(q);
            } 
        }                        
        else { // User insert scenario
            for(User usr : newMap.values()){
                if(usr.Designation__c == 'Area Manager' && usr.Area__c != null){
                    userToShareLead.add(usr);
                }               
            }
        }
        // Lead share insert 
        if(userToShareLead.size() > 0){  
            //**********Implemented queueable to prevent mixed DML error ***********//
            InsertLeadShareQueueable q = new InsertLeadShareQueueable(userToShareLead);
            System.enqueueJob(q);
        }
        } catch(Exception e) {
            ExceptionHandling.Exception('amLeadShr', 'cls_trgUserHandler', e);
        }           
    } 
    //*******SAC-97 ends**********//
    //
    
    
    // Added By Adarsh - SAC-166
    // when user is created with Area, all existing opportunity should be shared 
    public static void oppSharingNewUser(List<User> lstNewUser)
    {
        Set<String> areaSet = new Set<String>();
        Set<User> amUserSet = new Set<User>();
        List<opportunity__share> oppShareList = new List<opportunity__share>();
        try{
            Id AMProfileId = [Select Id from profile where name = 'Area Manager' limit 1].Id;
            for(User usr : lstNewUser){
                if((!String.isBlank(usr.Area__c)) && (usr.ProfileId == AMProfileId)){
                    areaSet.add(usr.Area__c); 
                    amUserSet.add(usr);
                }
            }
            if(!amUserSet.isEmpty()){
                //**********Implemented queueable to prevent mixed DML error ***********//
                NewUserOppShareQueueable q = new NewUserOppShareQueueable(areaSet,amUserSet);
                System.enqueueJob(q);
            }
        }catch(Exception e){
            ExceptionHandling.Exception('oppSharingNewUser', 'cls_trgUserHandler', e);
        }
    }
    // If user is updated with new Area. Old Area sharing should be removed and new Area sharing
    public static void oppSharingOldUser(List<User> lstNewUser, Map<Id, User> mapOldUsers)
    {
        Set<String> newUserAreaSet = new Set<String>();
        Set<User> amUserSet = new Set<User>();
        
        Id AMProfileId = [Select Id from profile where name = 'Area Manager' limit 1].Id;
        try {
        for(User eachUsr : lstNewUser){
            if((eachUsr.Area__c != mapOldUsers.get(eachUsr.Id).Area__c) && (eachUsr.ProfileId == AMProfileId)){
                newUserAreaSet.add(eachUsr.Area__c);
                amUserSet.add(eachUsr);
            }
        }
        if(!newUserAreaSet.isEmpty()){
            //**********Implemented queueable to prevent mixed DML error ***********//
            OldUserOppShareQueueable q = new OldUserOppShareQueueable(amUserSet,newUserAreaSet);
            System.enqueueJob(q);
        }
        } catch (Exception e) {
            ExceptionHandling.Exception('oppSharingOldUser', 'cls_trgUserHandler', e);
        }
    }
    //changes end - SAC-166
}