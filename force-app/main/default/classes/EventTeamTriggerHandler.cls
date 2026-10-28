/**
 * Description		:	Helper class for Event Team Trigger to perform various tasks like, preventing the user to add more than one event under a parent event, providing/removing 
 *					    the sharing to/from Event Team members on insertion/deletion/updation
 * 
 * Revision Logs	:	V_1.0 - Created
 * 
 **/
public with sharing class EventTeamTriggerHandler{
    
    //Method to prevent the user to add more than one child event under a parent event
    public static Boolean isSyncRunning = false;
    //added by abhishek
    public static void stopDuplicateRecord(List<Event_Team__c> lstEventTeam){
        try {
            Set<Id> idsEvent = new Set<Id>();
            Set<Id> idsUser = new Set<Id>();
            for(Event_Team__c objEventTeam : lstEventTeam){ 
                if(objEventTeam.Event__c != null && objEventTeam.User__c != null){
                    idsEvent.add(objEventTeam.Event__c);
                    idsUser.add(objEventTeam.User__c);
                }
            }
            Set<String> exisinngEventUserSet = New Set<String>();
            for(Event_Team__c et: [Select Id, Event__c, User__c from Event_Team__c Where Event__c IN:idsEvent AND User__c IN:idsUser]) {
                exisinngEventUserSet.add(et.Event__c+'-'+et.User__c);
            }

            for(Event_Team__c objEventTeam : lstEventTeam){ 
                if(exisinngEventUserSet.contains(objEventTeam.Event__c+'-'+objEventTeam.User__c)){
                    objEventTeam.addError('Duplicate user not allowed for same Event Team');
                }
            }
        } Catch(Exception e){
            System.debug('Exception '+e.getMessage());
            ExceptionHandling.Exception('stopDuplicateRecord', 'EventTeamTriggerHandler', e.getMessage());
        }   
    }

    // Added by Abhishek to prevent the user to change the member in event team if event is already checked in.
    public static void memberEventAlreadyCheckedIn(
        Map<String, Id> mapOwnerIds,
        Map<Id, Event_Team__c> mapEventTeam,
        Set<Id> eventIds,
        Set<Id> oldOwnerIds
    ){
        try{

            List<Event__c> childEvents =
                new GetDataInSystemMode()
                    .getChildEvents(
                        eventIds,
                        oldOwnerIds
                    );

            for(Event__c evt : childEvents){

                if(evt.CheckIn_Date__c != null){

                    String key =
                        String.valueOf(evt.Parent_Event__c) +
                        String.valueOf(evt.OwnerId);

                    Id eventTeamId =
                        mapOwnerIds.get(key);

                    if(eventTeamId != null &&
                    mapEventTeam.containsKey(eventTeamId)){

                        mapEventTeam.get(eventTeamId)
                            .addError(
                                'You are not able to change the member because the event is already checked in.'
                            );
                    }
                }
            }

        }catch(Exception e){

            ExceptionHandling.Exception(
                'memberEventAlreadyCheckedIn',
                'EventTeamTriggerHandler',
                e.getMessage()
            );
        }
    }

    public static void errorNewEvent(List<Event_Team__c> lstEventTeam,Set<Id> idsEvent){
        try{
            Map<Id,Event__c> mapEvent = new Map<Id,Event__c>();
            for(Event__c objEve : [Select Id,Parent_Event__c from Event__c where Id IN : idsEvent and Parent_Event__c != null]){
                mapEvent.put(objEve.id, objEve);
                
            }
            for(Event_Team__c objEventTeam : lstEventTeam){ 
                If(mapEvent.containsKey(objEventTeam.Event__c)){
                    objEventTeam.addError('you are not able to add child member.');
                }
            }
        }catch(Exception e){
            System.debug('Exception '+e.getMessage());
            ExceptionHandling.Exception('errorNewEvent', 'EventTeamTriggerHandler', e.getMessage());
        }
    }
    
    //Method to create the Child Events under a event and sharing the records with Event Team Members
    // public static void createNewEvent(List<Event_Team__c> lstEventTeam,Set<Id> idsEvent){
    //     try{
    //        // List<Account> lstAcc = [Select id from Account where name =: 'NON PRC PICKUP ACCOUNT' limit 1];
    //         Map<Id,Event__c> mapEvent = new Map<Id,Event__c>();
    //         List<Event__c> lstNewEvent = new List<Event__c>();
    //       /*  for(Event__c objEve : [Select Id,Campaign__c,Account__c,Status__c,name,ownerId,Start__c,Remarks__c,End__c,Parent_Event__c , Journey__c, 
    //                                Opportunity__c, Contact__c, Lead__c, Meeting_at_other_location__c, Other_Address__c, Activity__c, 
    //                                Branch__c, Event_Purpose__c, Virtual_Meeting__c, If_Others_Please_Specify__c 
    //                                from Event__c where Id IN : idsEvent and Parent_Event__c = null]){*/
	// 		  for(Event__c objEve : [Select Id,Campaign__c,Account__c,Status__c,name,ownerId,Start__c,Remarks__c, End__c,Parent_Event__c , Journey__c, 
    //                                Opportunity__c, Contact__c, Lead__c, Meeting_at_other_location__c, Other_Address__c, Activity__c, 
    //                                Branch__c, Event_Purpose__c, /*Virtual_Meeting__c,*/ If_Others_Please_Specify__c 
    //                                from Event__c where Id IN : idsEvent and Parent_Event__c = null]){  // Added by Monika on 24-06-2020 
                                       
    //                                mapEvent.put(objEve.id, objEve);
    //         }
    //         for(Event_Team__c objEventTeam : lstEventTeam){ 
    //             If(mapEvent.containsKey(objEventTeam.Event__c)){
    //                 Event__c objEve = mapEvent.get(objEventTeam.Event__c);
    //                 Event__c objNewEve = new Event__c();
    //                 objNewEve.name = objEve.name;
    //                 objNewEve.Status__c = objEve.Status__c;
    //                 objNewEve.Start__c = objEve.Start__c;
    //                 objNewEve.Remarks__c = objEve.Remarks__c;
    //                 objNewEve.End__c = objEve.End__c;
    //                 objNewEve.ownerId = objEventTeam.User__c;
    //                 objNewEve.Parent_Event__c = objEve.Id;
    //                 objNewEve.Account__c = objEve.Account__c;
    //                 objNewEve.is_Automated__c = true;
    //                 objNewEve.Campaign__c = objEve.Campaign__c;
    //                 objNewEve.Event_Purpose__c = objEve.Event_Purpose__c;//Added by Monika on 24-06-2020
    //                 // objNewEve.Virtual_Meeting__c = objEve.Virtual_Meeting__c;//Added by Monika on 24-06-2020 //Commented by Deepika | IBM, SAC-632
                    
    //                 //--------Added by Sharad on 7 March 19 '
    //                // objNewEve.Journey__c = objEve.Journey__c; //Added by Ashu
    //                 objNewEve.Opportunity__c = objEve.Opportunity__c;
    //                 objNewEve.Contact__c = objEve.Contact__c;
    //                 objNewEve.Lead__c = objEve.Lead__c;
    //                 objNewEve.Meeting_at_other_location__c = objEve.Meeting_at_other_location__c;
    //                 objNewEve.Other_Address__c = objEve.Other_Address__c; 
    //                 objNewEve.Activity__c = objEve.Activity__c;
    //                 objNewEve.Branch__c = objEve.Branch__c;
    //                 objNewEve.If_Others_Please_Specify__c = objEve.If_Others_Please_Specify__c;
    //                 //--------------------------------
                    
    //                 lstNewEvent.add(objNewEve);
    //             }
    //         }
    //         if(lstNewEvent.size() > 0){ 
    //             EventTeamTriggerHandler.GetDataInSystemMode withoutSharing = new EventTeamTriggerHandler.GetDataInSystemMode();
    //             lstNewEvent = withoutSharing.insertNewEvents(lstNewEvent);
    //             //added by Anand on 20th Feb 26 SAC-2280
    //             // EventContactTriggerHelper.syncParentContactsToChild(lstNewEvent);
    //             addSharing(lstEventTeam);
    //         }
    //     }catch(Exception e){
    //         System.debug('Exception '+e.getMessage());
    //         ExceptionHandling.Exception('createNewEvent', 'EventTeamTriggerHandler', e.getMessage());
    //     }
    // }
      public static void manageEventSync(
    List<Event_Team__c> lstEventTeam,
    Set<Id> eventIds,
    Boolean isCreateOperation
){
    try{

        Map<Id, Event__c> parentMap = new Map<Id, Event__c>();

        for(Event__c evt : [
            SELECT Id, Name, Status__c, Start__c, Remarks__c, End__c,
                   Parent_Event__c, Account__c, Campaign__c,
                   Event_Purpose__c, Opportunity__c, Contact__c,
                   Lead__c, Activity__c, Branch__c,//Meeting_at_other_location__c,Other_Address__c, // commented due to SF2-193
                   If_Others_Please_Specify__c
            FROM Event__c
            WHERE Id IN :eventIds
        ]){
            parentMap.put(evt.Id, evt);
        }

        if(isCreateOperation){

            List<Event__c> lstNewEvent = new List<Event__c>();

            for(Event_Team__c objEventTeam : lstEventTeam){

                if(parentMap.containsKey(objEventTeam.Event__c)){

                    Event__c parent = parentMap.get(objEventTeam.Event__c);

                    Event__c child = new Event__c();

                    child.Name = parent.Name;
                    child.Status__c = parent.Status__c;
                    child.Start__c = parent.Start__c;
                    child.Remarks__c = parent.Remarks__c;
                    child.End__c = parent.End__c;
                    child.OwnerId = objEventTeam.User__c;
                    child.Parent_Event__c = parent.Id;
                    child.Account__c = parent.Account__c;
                    child.is_Automated__c = true;
                    child.Campaign__c = parent.Campaign__c;
                    child.Event_Purpose__c = parent.Event_Purpose__c;
                    child.Opportunity__c = parent.Opportunity__c;
                    child.Contact__c = parent.Contact__c;
                    child.Lead__c = parent.Lead__c;
                   // child.Meeting_at_other_location__c = parent.Meeting_at_other_location__c;    // commented due to SF2-193
                   // child.Other_Address__c = parent.Other_Address__c;     // commented due to SF2-193
                    child.Activity__c = parent.Activity__c;
                    child.Branch__c = parent.Branch__c;
                    child.If_Others_Please_Specify__c = parent.If_Others_Please_Specify__c;

                    lstNewEvent.add(child);
                }
            }

            if(!lstNewEvent.isEmpty()){

                GetDataInSystemMode getData = new GetDataInSystemMode();
                getData.insertNewEvents(lstNewEvent);

                addSharing(lstEventTeam);
            }

        }
        //  else {

        //     List<Event__c> childToUpdate = new List<Event__c>();

        //     for(Event__c child : [
        //         SELECT Id, Remarks__c, Parent_Event__c
        //         FROM Event__c
        //         WHERE Parent_Event__c IN :eventIds
        //     ]){

        //         Event__c parent = parentMap.get(child.Parent_Event__c);

        //         if(parent == null) continue;

        //         child.Name = parent.Name;
        //         child.ValidationBypassDateTime__c = System.now();

        //         // child.Start__c = parent.Start__c;
        //         // child.End__c = parent.End__c;

        //         child.Remarks__c = child.Remarks__c == null
        //             ? parent.Remarks__c
        //             : child.Remarks__c + ' | ' + parent.Remarks__c;

        //         child.Account__c = parent.Account__c;
        //         child.Campaign__c = parent.Campaign__c;
        //         child.Event_Purpose__c = parent.Event_Purpose__c;
        //         child.Opportunity__c = parent.Opportunity__c;
        //         child.Contact__c = parent.Contact__c;
        //         child.Lead__c = parent.Lead__c;
        //         child.Meeting_at_other_location__c = parent.Meeting_at_other_location__c;
        //         child.Other_Address__c = parent.Other_Address__c;
        //         child.Activity__c = parent.Activity__c;
        //         child.Branch__c = parent.Branch__c;
        //         child.If_Others_Please_Specify__c = parent.If_Others_Please_Specify__c;

        //         childToUpdate.add(child);
        //     }

        //     if(!childToUpdate.isEmpty()){
        //         update childToUpdate;
        //     }
        // }

    }catch(Exception e){

        System.debug('Exception ' + e.getMessage());

        ExceptionHandling.Exception(
            'manageEventSync',
            'EventTeamTriggerHandler',
            e.getMessage()
        );

    } finally {
        EventTeamTriggerHandler.isSyncRunning = false;
        }
    }
    
    //Method to update the Owners on Event with Event Team Members
    public static void changeOwner(Map<String,Id> mapOwnerids, Set<Id> eventIds, Set<Id> oldOwnerIds){
        try{
            List<Update_Event__e> platformEvenList = new List<Update_Event__e>();
            for(Event__c objEve : new GetDataInSystemMode().getChildEvents(eventIds, oldOwnerIds)){
                String key =
                String.valueOf(objEve.Parent_Event__c) +
                String.valueOf(objEve.OwnerId);
                Update_Event__e ev = New Update_Event__e();
                ev.ObjectName__c = 'Event__c';
                ev.ObjectId__c = objEve.Id;
                ev.Field_Value__c = mapOwnerids.get(key);
                platformEvenList.add(ev);
            }
            if(platformEvenList.size() > 0){
                List<Database.SaveResult> results = EventBus.publish(platformEvenList);
                // Check the results for success or failure
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event with ID: ' + sr.getId());
                    } else {
                        for (Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }
                }

            }
        } catch(Exception e){
            System.debug('Exception '+e.getMessage());
            ExceptionHandling.Exception('changeOwner', 'EventTeamTriggerHandler', e.getMessage());
        }
    }
    
    //Method to provide the event sharing to Event Team Members
    public static void addSharing(List<Event_Team__c> lstEventTeam){
        try{
            List<Event__Share> lstEventShare = new List<Event__Share>();
            for(Event_Team__c objEveTeam : lstEventTeam){
                Event__Share objShare = new Event__Share(); 
                objShare.ParentId = objEveTeam.Event__c;
                objShare.UserOrGroupId = objEveTeam .User__c;
                objShare.AccessLevel = 'Read';
                lstEventShare.add(objShare);     
            }
            if(lstEventShare.size() > 0){
                insert lstEventShare;
            }
        }catch(Exception e){
            System.debug('Exception '+e.getMessage());
            ExceptionHandling.Exception('addSharing', 'EventTeamTriggerHandler', e.getMessage());
        }
    }
    
    //Method to remove the sharing from Event Team Members in case member get updated
    public static void removeSharing(List<Event_Team__c> lstEveteam,Set<Id> setEveIds ){
        List<Event__Share> lstEveShare = new List<Event__Share>();
        Map<String,Event__Share> mapEveShare = new Map<String,Event__Share>();
        try{
            for(Event__Share evtShare: [select id,userorgroupid,ParentId from Event__Share where ParentId IN : setEveIds]){
               
                mapEveShare.put(evtShare.ParentId+'+'+evtShare.userorgroupid,evtShare);
            }            
            for(Event_Team__c eveT: lstEveteam){
                Event__Share evtShare = new Event__Share();
                evtShare = mapEveShare.get(eveT.Event__c+'+'+eveT.User__c);
                if(evtShare != null){
                    lstEveShare.add(evtShare);
                }
            }
            if(!lstEveShare.isEmpty()){
                delete lstEveShare;
                
            }
        }Catch(Exception e){
            System.debug('Exception '+e.getMessage());
            ExceptionHandling.Exception('removeSharing', 'EventTeamTriggerHandler', e.getMessage());
        }
    }
    //Added By Anand Raju-SAC 2280- Method to Update the Child Events under a event and sharing the records with Event Team Members
    // public static void syncParentToChild(Set<Id> parentEventIds){
    //     try{
    //         if(parentEventIds.isEmpty()) return;

            // Map<Id, Event__c> parentMap = new Map<Id, Event__c>(
            //     [SELECT Id, Name, Status__c, Start__c, End__c, Remarks__c,
            //             Account__c, Campaign__c, Event_Purpose__c,
            //             Opportunity__c, Contact__c, Lead__c,
            //             Meeting_at_other_location__c, Other_Address__c,
            //             Activity__c, Branch__c, If_Others_Please_Specify__c
            //     FROM Event__c
            //     WHERE Id IN :parentEventIds]
            // );

    //         GetDataInSystemMode getData = new GetDataInSystemMode();
    //         getData.updateEvent(parentEventIds, parentMap);

    //     }catch(Exception e){
    //         System.debug('sync error '+e.getMessage());
    //         ExceptionHandling.Exception( 'syncParentToChild', 'EventTeamTriggerHandler', e.getMessage());
    //     } finally {
    //         EventTeamTriggerHandler.isSyncRunning = false;
    //     }
    // }

    public without sharing class GetDataInSystemMode {

        // public void updateEvent(Set<Id> parentEventIds, Map<Id, Event__c> parentMap){
        //     try{
        //         List<Event__c> childToUpdate = new List<Event__c>();
        //         for(Event__c child : [SELECT Id,Remarks__c, Parent_Event__c FROM Event__c WHERE Parent_Event__c IN :parentEventIds]){
        //             Event__c parent = parentMap.get(child.Parent_Event__c);
        //             if(parent == null) continue;

        //             child.Name = parent.Name;
        //             child.ValidationBypassDateTime__c = System.now();
        //            // child.Start__c = parent.Start__c;   // Commented By Anand raju 8-May-226 SAC-2590
        //            // child.End__c = parent.End__c;        // Commented By Anand raju 8-May-226 SAC-2590
        //             child.Remarks__c = child.Remarks__c == null ? parent.Remarks__c : child.Remarks__c + ' | ' + parent.Remarks__c;
        //             child.Account__c = parent.Account__c;
        //             child.Campaign__c = parent.Campaign__c;
        //             child.Event_Purpose__c = parent.Event_Purpose__c;
        //             child.Opportunity__c = parent.Opportunity__c;
        //             child.Contact__c = parent.Contact__c;
        //             child.Lead__c = parent.Lead__c;
        //             child.Meeting_at_other_location__c = parent.Meeting_at_other_location__c;
        //             child.Other_Address__c = parent.Other_Address__c;
        //             child.Activity__c = parent.Activity__c;
        //             child.Branch__c = parent.Branch__c;
        //             child.If_Others_Please_Specify__c = parent.If_Others_Please_Specify__c;

        //             childToUpdate.add(child);
        //         }

        //         if(!childToUpdate.isEmpty()){
        //             update childToUpdate;
        //         }

        //     } Catch(Exception e){
        //         System.debug('updateEvent '+e.getMessage());
        //         ExceptionHandling.Exception('updateEvent', 'EventTeamTriggerHandler', e.getMessage());
        //     }
        
        // }

        public List<Event__c> getChildEvents(Set<Id> eventIds, Set<Id> ownerIds ) {
            return [
                SELECT Id,
                    OwnerId,
                    Parent_Event__c,
                    CheckIn_Date__c
                FROM Event__c
                WHERE Parent_Event__c IN :eventIds
                AND OwnerId IN :ownerIds
            ];
        }

        public List<Event__c> insertNewEvents(List<Event__c> lstNewEvent) {
            insert lstNewEvent;
            return lstNewEvent;
        }
    }

}