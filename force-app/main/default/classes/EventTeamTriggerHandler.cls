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
                   Event_Purpose__c, Opportunity__c, Contact__c,RecordTypeId,
                   Lead__c, Activity__c, Branch__c,
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
                    child.Activity__c = parent.Activity__c;
                    child.Branch__c = parent.Branch__c;
                    child.If_Others_Please_Specify__c = parent.If_Others_Please_Specify__c;
					child.RecordTypeId = parent.RecordTypeId;


                    lstNewEvent.add(child);
                }
            }

            if(!lstNewEvent.isEmpty()){

                GetDataInSystemMode getData = new GetDataInSystemMode();
                getData.insertNewEvents(lstNewEvent);

                addSharing(lstEventTeam);
            }

        }

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


    public without sharing class GetDataInSystemMode {



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