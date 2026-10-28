//Helper class for Event__c object Trigger to perform various operations like relate journey to event if start sate of event is same, updating distance on Journey and 
//restricting the user to create multiple events under Account, Opportunity, Lead and Activity for same start date
public class CustomEventTriggerHandler{
    
    //Method to relate journey to event if start sate of event is same.
    public static void relateToJouney(List<Event__c> lstEvent ,Set<Date> startdate ){
        try {
            Map<String, List<Journey__c>> mapUniqueComboToLstJourney = new Map<String, List<Journey__c>>();        
            for(Journey__c objJourney : [Select Id,ownerId,Journey_Date__c from Journey__c where Journey_Date__c IN :startdate and CheckOut_Date__c = null Order by CreatedDate ASC]){
                String uniqueCombo = objJourney.ownerId +''+objJourney.Journey_Date__c;
                if(mapUniqueComboToLstJourney.containsKey(uniqueCombo))
                    mapUniqueComboToLstJourney.get(uniqueCombo).add(objJourney);
                else
                    mapUniqueComboToLstJourney.put(uniqueCombo ,new List<Journey__c>{objJourney} );
            }
            if(mapUniqueComboToLstJourney.size() > 0){
                for(Event__c objEve : lstEvent){
                    String uniqueId = objEve.ownerId+''+objEve.start__c.Date();
                    if(mapUniqueComboToLstJourney.get(uniqueId) != null ){
                        objEve.Journey__c = mapUniqueComboToLstJourney.get(uniqueId)[0].id; 
                    }
                }
            }
        } catch(Exception e){
            System.debug('Exception in relateToJouney'+e.getMessage());
            ExceptionHandling.Exception('relateToJouney', 'CustomEventTriggerHandler', e.getMessage());

        }
    }

    // Added by abhishek pardhan SAC-2750
    public static void recapCharacterCount(List<Event__c> lstEvent){
        try {
            for(Event__c objEve : lstEvent){
                if(objEve.Remarks__c != null){
                    objEve.Recap_Character_Count__c = objEve.Remarks__c.length();
                } else {
                    objEve.Recap_Character_Count__c = 0;
                }
            }
            if(lstEvent.size() > 0){
                update lstEvent;
            }
        } catch(Exception e){
            System.debug('Exception in recapCharacterCount'+e.getMessage());
            ExceptionHandling.Exception('recapCharacterCount', 'CustomEventTriggerHandler', e.getMessage());
        }
    }

    //Method to update distance on journey if is claim is true or not.
    public static void distanceOnJourneyUpdate(List<Event__c> lstEvent ,Set<Id> jourIds){
        try {
            Map<Id,Journey__c> mapJourneyIds = new Map<Id,Journey__c>();
            for(Journey__c objJourney : [Select Id,Journey_KM__c from Journey__c where Id IN : jourIds]){
                
                mapJourneyIds.put(objJourney.Id ,objJourney);
                
            }
            for(Event__c objEve : lstEvent){
                Decimal dis = mapJourneyIds.get(objEve.Journey__c).Journey_KM__c;
                
                if(objEve.Is_Claim__c){
                    mapJourneyIds.get(objEve.Journey__c).Journey_KM__c = dis != null ? dis + objEve.Distance__c : objEve.Distance__c;
                }else{
                    mapJourneyIds.get(objEve.Journey__c).Journey_KM__c = dis != null ? dis - objEve.Distance__c : null;
                }
            }
            if(mapJourneyIds.size() > 0){
                update mapJourneyIds.values();
            }
        } catch(Exception e){
            System.debug('Exception in distanceOnJourneyUpdate'+e.getMessage());
            ExceptionHandling.Exception('distanceOnJourneyUpdate', 'CustomEventTriggerHandler', e.getMessage());
        }
    }
    
    /* List<Event__c> eventAccList = [Select Id,Start__c,Account__c from Event__c where  Day_Only(Start__c) IN: setEventStartDates AND Account__c IN : mapEvtToParent.keySet()];
List<Event__c> eventOppList = [Select Id,Start__c,opportunity__c from Event__c where  Day_Only(Start__c) IN: setEventStartDates AND opportunity__c IN : mapEvtToParent.keySet()];
List<Event__c> eventLeList = [Select Id,Start__c,Lead__c from Event__c where  Day_Only(Start__c) IN: setEventStartDates AND Lead__c IN : mapEvtToParent.keySet()];
List<Event__c> eventCamList = [Select Id,Start__c,Campaign__c from Event__c where  Day_Only(Start__c) IN: setEventStartDates AND  Campaign__c IN : mapEvtToParent.keySet()];
List<Event__c> eventActList = [Select Id,Start__c,Activity__c from Event__c where  Day_Only(Start__c) IN: setEventStartDates AND Activity__c IN : mapEvtToParent.keySet()];
system.debug('eventAccList'+eventAccList);
system.debug('eventOppList'+eventOppList);
system.debug('eventLeList'+eventLeList);
system.debug('eventCamList'+eventCamList);
system.debug('eventActList'+eventActList);
*/
    //Methos to check that only 1 Event create in single against lead,opp,Account,campaing and activity
    public static void checkRecordforDay(List<Event__c> lstEvent){
        try {
            Map<String,String> mapAccESDToEv = new Map<String,String>();
            Map<String,String> mapOppESDToEv = new Map<String,String>();
            Map<String,String> mapLeadESDToEv = new Map<String,String>();
            Map<String,String> mapCampESDToEv = new Map<String,String>();
            Map<String,String> mapActESDToEv = new Map<String,String>();
            
            Map<String,String> mapEvtToParent = new Map<String,String>();
            
            Set<Date> setEventStartDates = new Set<Date>();
            
            for(Event__c objEvent : lstEvent){
                
                if(objEvent.Parent_Event__c == Null) {
                    //    if(String.isNotBlank(objEvent.Account__c)){
                    //        if(mapAccESDToEv.containsKey(objEvent.Account__c +'::'+objEvent.Start__c.date())){
                    //            objEvent.addError('An event of same date has already created for this account');
                    //        }
                    //        else{
                    //            mapAccESDToEv.put(objEvent.Account__c +'::'+objEvent.Start__c.date(),'1');
                    //            mapEvtToParent.put(objEvent.Account__c,objEvent.Account__c);
                    //        }
                    //   }
                    if(String.isNotBlank(objEvent.opportunity__c)){
                        if(mapOppESDToEv.containsKey(objEvent.opportunity__c +'::'+objEvent.Start__c.date())){
                            objEvent.addError('An event of same date has already created for this opportunity');
                        }
                        else{
                            mapOppESDToEv.put(objEvent.opportunity__c +'::'+objEvent.Start__c.date(),'1');
                            mapEvtToParent.put(objEvent.opportunity__c,objEvent.opportunity__c);
                        }
                    }
                    if(String.isNotBlank(objEvent.Lead__c)){
                        if(mapLeadESDToEv.containsKey(objEvent.Lead__c +'::'+objEvent.Start__c.date())){
                            objEvent.addError('An event of same date has already created for this lead');
                        }
                        else{
                            mapLeadESDToEv.put(objEvent.Lead__c +'::'+objEvent.Start__c.date(),'1');
                            mapEvtToParent.put(objEvent.Lead__c,objEvent.Lead__c);
                        }           
                    }
                    if(String.isNotBlank(objEvent.Campaign__c)){
                        if(mapCampESDToEv.containsKey(objEvent.Campaign__c +'::'+objEvent.Start__c.date())){
                            objEvent.addError('An event of same date has already created for this campaign');
                        }
                        else{
                            mapCampESDToEv.put(objEvent.Campaign__c +'::'+objEvent.Start__c.date(),'1');
                            mapEvtToParent.put(objEvent.Campaign__c,objEvent.Campaign__c);
                        }
                    }
                    //    if(String.isNotBlank(objEvent.Activity__c)){
                    //        if(mapActESDToEv.containsKey(objEvent.Activity__c +'::'+objEvent.Start__c.date())){
                    //            objEvent.addError('An event of same date has already created for this activity');
                    //        }
                    //        else{
                    //            mapActESDToEv.put(objEvent.Activity__c +'::'+objEvent.Start__c.date(),'1');
                    //            mapEvtToParent.put(objEvent.Activity__c,objEvent.Activity__c);
                    //        }
                    //    }
                    
                    setEventStartDates.add(objEvent.Start__c.date());
                }
            }
            
            for(Event__c objEvent : [Select Id,Start__c,Account__c,opportunity__c,Lead__c,Campaign__c,Activity__c from Event__c where (opportunity__c IN : mapEvtToParent.keySet() OR Lead__c IN : mapEvtToParent.keySet() OR Campaign__c IN : mapEvtToParent.keySet()) AND Day_Only(Start__c) IN: setEventStartDates] ){
                //    if(String.isNotBlank(objEvent.Account__c) && mapAccESDToEv.containsKey(objEvent.Account__c +'::'+objEvent.Start__c.date())){
                //       mapAccESDToEv.put(objEvent.Account__c +'::'+objEvent.Start__c.date(),'2');
                //    }
                if(String.isNotBlank(objEvent.opportunity__c) && mapOppESDToEv.containsKey(objEvent.opportunity__c +'::'+objEvent.Start__c.date())){
                    mapOppESDToEv.put(objEvent.opportunity__c +'::'+objEvent.Start__c.date(),'2');
                }
                if(String.isNotBlank(objEvent.Lead__c) && mapLeadESDToEv.containsKey(objEvent.Lead__c +'::'+objEvent.Start__c.date())){
                    mapLeadESDToEv.put(objEvent.Lead__c +'::'+objEvent.Start__c.date(),'2');
                }
                if(String.isNotBlank(objEvent.Campaign__c) && mapCampESDToEv.containsKey(objEvent.Campaign__c +'::'+objEvent.Start__c.date())){
                    mapCampESDToEv.put(objEvent.Campaign__c +'::'+objEvent.Start__c.date(),'2');
                }
                //    if(String.isNotBlank(objEvent.Activity__c) && mapActESDToEv.containsKey(objEvent.Activity__c +'::'+objEvent.Start__c.date())){
                //        mapActESDToEv.put(objEvent.Activity__c +'::'+objEvent.Start__c.date(),'2');
                //    }
            }
            
            for(Event__c objEvent : lstEvent){
                
                if(objEvent.Parent_Event__c == Null) {
                    //if(objEvent.Account__c != Null && mapAccESDToEv.containsKey(objEvent.Account__c + '::' + objEvent.Start__c.date()) && mapAccESDToEv.get(objEvent.Account__c + '::' + objEvent.Start__c.date()) == '2'){
                    //  System.debug(' Error++++++ ');
                    //objEvent.addError('An event of same date has already created for this account');
                    // }
                    if(objEvent.Opportunity__c != Null && mapOppESDToEv.containsKey(objEvent.opportunity__c + '::' + objEvent.Start__c.date()) && mapOppESDToEv.get(objEvent.opportunity__c + '::' + objEvent.Start__c.date()) == '2'){
                        objEvent.addError('An event of same date has already created for this opportunity');
                    }
                    if(objEvent.Lead__c != Null && mapLeadESDToEv.containsKey(objEvent.Lead__c + '::' + objEvent.Start__c.date()) && mapLeadESDToEv.get(objEvent.Lead__c + '::' + objEvent.Start__c.date()) == '2'){
                        objEvent.addError('An event of same date has already created for this lead');
                    }
                    if(objEvent.Campaign__c != Null && mapCampESDToEv.containsKey(objEvent.Campaign__c + '::' + objEvent.Start__c.date()) && mapCampESDToEv.get(objEvent.Campaign__c + '::' + objEvent.Start__c.date()) == '2'){
                        objEvent.addError('An event of same date has already created for this campaign');
                    }
                    // if(objEvent.Activity__c != Null && mapActESDToEv.containsKey(objEvent.Activity__c +'::'+objEvent.Start__c.date()) && mapActESDToEv.get(objEvent.Activity__c +'::'+objEvent.Start__c.date()) == '2'){
                    //   objEvent.addError('An event of same date has already created for this activity');
                    //}
                }
            }
        } catch(Exception e){
            System.debug('Exception in CustomEventTriggerHandler'+e.getMessage());
            ExceptionHandling.Exception('checkRecordforDay', 'CustomEventTriggerHandler', e.getMessage());
        }

    }  
    // Method to populate the number of events in the journey added By Shubham Girdhar
    Public static void NumberOfEvents(set <Id> jorid){
        try{
            map<id,integer>mapCount=new map<id,integer>();
            list<Event__c>listevent=new list<Event__c>();
            list<Journey__c>jorlist=new list<Journey__c>();
            list<Event__c>Eventlist=new list<Event__c>();
            list<Journey__c>listjourney=new list<Journey__c>();
            jorlist=[SELECT id,name FROM Journey__c WHERE id in:jorid];
            Eventlist=[SELECT id,name,Journey__c FROM Event__c WHERE Journey__c in:jorid];
            for(Journey__c jor:jorlist){
                listevent.clear();
                for(Event__c c:Eventlist){
                    if(c.Journey__c==jor.id){
                        listevent.add(c);
                        mapCount.put(c.Journey__c,listevent.size() - 1);
                    }
                }
            }
            if(jorlist.size()>0){
                
                for(Journey__c a:jorlist)
                {
                    if(mapCount.get(a.id)==null)
                        a.Number_Of_Event__c =0; 
                    
                    else
                        
                        a.Number_Of_Event__c =mapCount.get(a.id);
                    listjourney.add(a);
                }
            }
            
            
            if(listjourney.size()>0)
                
                update listjourney;
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('NumberOfEvents', 'CustomEventTriggerHandler', e.getMessage());   
        }
    }
    
    //changed by Abhisek pardhan Sac- 2007
    public static void validateEventJourney(List<Event__c> eventList){
        try {
            Set<Id> journeyIds = new Set<Id>();
            
            for(Event__c evt : eventList){
                journeyIds.add(evt.Journey__c);
            }
            
            Map<Id, Journey__c> journeyMap = new Map<Id, Journey__c>([SELECT Id, Name, Journey_Date__c, OwnerId FROM Journey__c WHERE Id IN :journeyIds]);
            
            for(Event__c evt : eventList){
                if(journeyMap.containsKey(evt.Journey__c)){
                    if(journeyMap.get(evt.Journey__c).OwnerId != evt.OwnerId){
                        evt.Journey__c.addError('Incorrect Journey attached. Please attach your journey details.');
                    } 
                    if( evt.Start__c != null && journeyMap.get(evt.Journey__c).Journey_Date__c != evt.Start__c.date()){
                        evt.Journey__c.addError('Journey date does not match with Event start date. Please attach correct journey.'); 
                    }
                }
            }
        } catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('validateEventJourney', 'CustomEventTriggerHandler', e.getMessage());   
        }
        
    }
    
    
    // Start Change: SAC-124  By K SANSI(IBM) , 8th Sep 23 
    // This method is updating the Parents Object(Account, Opportunity, Contact, Lead, Branch Master)
    // based on last check out date changed
    public static void updateLastEvent(List<Event__c> eventList){
        try{
            List<Account> accToUpdate = new List<Account>();
            List<Contact> conToUpdate = new List<Contact>();
            List<Opportunity__c> oppToUpdate = new List<Opportunity__c>();
            List<Lead__c> ledToUpdate = new List<Lead__c>();
            List<Branch_Master__c> branchMasterToUpdate = new List<Branch_Master__c>();
            
            for( Event__c evnt :  eventList){
                if(evnt.Account__c != null){
                    Account acc = new Account(Id=evnt.Account__c, Last_Event__c=evnt.Id);
                    accToUpdate.add(acc);
                }
                if(evnt.Contact__c != null){
                    Contact con = new Contact(Id=evnt.Contact__c, Last_Event__c=evnt.Id);
                    conToUpdate.add(con);
                }
                if(evnt.Opportunity__c != null){
                    Opportunity__c opp = new Opportunity__c(Id=evnt.Opportunity__c, Last_Event__c=evnt.Id);
                    oppToUpdate.add(opp);
                }
                if(evnt.Lead__c != null){
                    Lead__c led = new Lead__c(Id=evnt.Lead__c, Last_Event__c=evnt.Id, ValidationBypassDateTime__c = System.now());
                    ledToUpdate.add(led);
                }
                if(evnt.Branch__c != null){
                    Branch_Master__c branchMaster = new Branch_Master__c(Id=evnt.Branch__c, Last_Event__c=evnt.Id);
                    branchMasterToUpdate.add(branchMaster);
                }
            }
            
            // update all parent records  
            if(accToUpdate.size() > 0){
                UPDATE accToUpdate;
            }  
            if(conToUpdate.size() > 0){
                UPDATE conToUpdate;
            } 
            if(oppToUpdate.size() > 0){
                UPDATE oppToUpdate;
            }
            if(ledToUpdate.size() > 0){
                TriggerUtility.byPassTrigger = true; // to by pass the locked Retail Lead 
                UPDATE ledToUpdate;
                TriggerUtility.byPassTrigger = false;
            }
            if(branchMasterToUpdate.size() > 0){
                UPDATE branchMasterToUpdate;
            }
        } catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updateLastEvent', 'CustomEventTriggerHandler', e.getMessage());   
        }
        
    }
    // End changed SAC-124 
    
    
    // Start Change: SAC-501  By Deepika Thakur(IBM) 
    // This method is updating the event Vertical based on the lookup to Object(Account, Opportunity, Contact, Lead)
    public static void populateVertical(List<Event__c> eventList){
        try{
        //Set to store Account, Opportunity, Lead and Contact Ids
            Set <Id> leadSet = new Set <Id>();
            Set <Id> accSet = new Set <Id>();
            Set <Id> oppSet = new Set <Id>();
            Set <Id> conSet = new Set <Id>();
            
            // Map to store Account, Opportunity, Lead and Contact Verticals
            Map <Id, String > leadVerticals     = new map <Id, String>();
            Map <Id, String > accountVerticals  = new map <Id, String>();
            Map <Id, String > opporVerticals    = new map <Id, String>();
            Map <Id, String > contactVerticals  = new map <Id, String>();
            
            for(Event__c objEvent : eventList){
                if(objEvent.Lead__c!=null)
                    leadSet.add(objEvent.Lead__c);
                else if(objEvent.Account__c!=null)
                    accSet.add(objEvent.Account__c);
                else if(objEvent.Opportunity__c!=null)
                    oppSet.add(objEvent.Opportunity__c);
                else if(objEvent.Contact__c!=null)
                    conSet.add(objEvent.Contact__c);
            }
            
            // Query and populate Lead Verticals
            if(leadSet !=null && leadSet.size() > 0){
                for (Lead__c leadVal : [SELECT Id, Vertical__c FROM Lead__c WHERE Id IN :leadSet]) {
                    leadVerticals.put(leadVal.Id, leadVal.Vertical__c);
                }
            }        
            
            // Query and populate Account Verticals
            else if(accSet !=null && accSet.size() > 0){
                for (Account acc : [SELECT Id, Vertical__c FROM Account WHERE Id IN :accSet]) {
                    accountVerticals.put(acc.Id, acc.Vertical__c);
                }
            }        
            
            // Query and populate Opportunity Verticals
            else if(oppSet !=null && oppSet.size() > 0){
                for (Opportunity__c opp : [SELECT Id, Vertical__c FROM Opportunity__c WHERE Id IN :oppSet]) {
                    opporVerticals.put(opp.Id, opp.Vertical__c);
                }
            } 
            
            // Query and populate Contact Verticals
            else if(conSet !=null && conSet.size() > 0){
                for (Contact con : [Select Id, Account.Vertical__c from Contact WHERE Id IN :conSet]) {
                    contactVerticals.put(con.Id, con.Account.Vertical__c);
                }
            }
            
            // Populate Event Verticals based on Account and Opportunity Verticals
            for (Event__c evt : eventList) {
                if (evt.Lead__c != null && leadVerticals.containsKey(evt.Lead__c)) {
                    evt.Vertical__c = leadVerticals.get(evt.Lead__c);
                } else if (evt.Account__c != null && accountVerticals.containsKey(evt.Account__c)) {
                    evt.Vertical__c = accountVerticals.get(evt.Account__c);
                } else if (evt.Opportunity__c != null && opporVerticals.containsKey(evt.Opportunity__c)) {
                    evt.Vertical__c = opporVerticals.get(evt.Opportunity__c);
                } else if (evt.Contact__c != null && contactVerticals.containsKey(evt.Contact__c)) {
                    evt.Vertical__c = contactVerticals.get(evt.Contact__c);
                }
            }
        } catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('populateVertical', 'CustomEventTriggerHandler', e.getMessage());   
        }
        
    }
    // End changed SAC-501
public static void addLastEventDate(List<Event__c> lstEvent, Boolean isInsert) {
    try{
        Set<Id> accountIds = new Set<Id>();
        Set<Id> eventIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        for (Event__c eve : lstEvent) {
            if (eve.Account__c != null) accountIds.add(eve.Account__c);
            if (eve.Id != null) eventIds.add(eve.Id);
            if (eve.OwnerId != null) ownerIds.add(eve.OwnerId);
        }

        if (accountIds.isEmpty()) return;

        Map<Id, List<Account_Team__c>> accountIdToTeams = new Map<Id, List<Account_Team__c>>();
        for (Account_Team__c team : [
            SELECT Id, BDMPropelI__c, Account__c, Account__r.Parent.Parent.Id, LastEventDate__c
            FROM Account_Team__c
            WHERE Account__r.Parent.Parent.Id IN :accountIds AND BDMPropelI__c IN :ownerIds
        ]) {
            if (!accountIdToTeams.containsKey(team.Account__r.Parent.Parent.Id)) {
                accountIdToTeams.put(team.Account__r.Parent.Parent.Id, new List<Account_Team__c>());
            }
            accountIdToTeams.get(team.Account__r.Parent.Parent.Id).add(team);
        }

        List<Account_Team__c> teamsToUpdate = new List<Account_Team__c>();
        Map<Id, Event__c> latestEventsMap = new Map<Id, Event__c>();
        if(!isInsert) { 
            for(Event__c eve : [SELECT Id, Account__c, OwnerId, CreatedDate FROM Event__c
                                    WHERE Account__c IN :accountIds
                                    AND OwnerId IN :ownerIds
                                    AND Id != :eventIds
                                    AND Status__c != 'Cancelled'
                                    ORDER BY CreatedDate DESC
                                ]) {
                                if (!latestEventsMap.containsKey(eve.Account__c)) {
                                        latestEventsMap.put(eve.Account__c, eve);
                                    }
                                }
        }
        
        for (Event__c eve : lstEvent) {
            
            if (eve.Account__c != null) {
                List<Account_Team__c> teams = accountIdToTeams.get(eve.Account__c);
                if (teams != null) {
                    for (Account_Team__c team : teams) {
                        if (team.BDMPropelI__c == eve.OwnerId) {
                            Datetime latestDate = null;
                            if(isInsert) {
                                latestDate = eve.CreatedDate;
                            } else {
                                latestDate = latestEventsMap.get(eve.Account__c) != null ? latestEventsMap.get(eve.Account__c).CreatedDate : null;
                            }
                            
                            team.LastEventDate__c = latestDate;
                            teamsToUpdate.add(team);
                        }
                    }
                }
            }
        }

        if (!teamsToUpdate.isEmpty()) update teamsToUpdate;
    } catch(Exception e){
        System.debug('Exception in addLastEventDate : '+e.getMessage());
        ExceptionHandling.Exception('addLastEventDate', 'CustomEventTriggerHandler', e.getMessage());
    }
}

    public static void addLastEventDate(List<Event__c> lstEvent, Map<Id, Event__c> oldEventMap) {
        try{
            Set<Id> allAccountIds = new Set<Id>();
            Set<Id> eventOwnerIds = new Set<Id>();

            for(Event__c eve: lstEvent) {
                String oldaccId = oldEventMap.get(eve.Id).Account__c;
                eventOwnerIds.add(eve.OwnerId);
                allAccountIds.add(eve.Account__c);
                allAccountIds.add(oldaccId);
            }
            Map<Id, Event__c> accountIdEventMap = new Map<Id, Event__c>();
            list<Event__c> allEventsOfAccount = [SELECT Id, Account__c, OwnerId, CreatedDate FROM Event__c WHERE Account__c IN :allAccountIds AND Status__c != 'Cancelled' AND ownerId IN :eventOwnerIds
                                Order by CreatedDate Desc];
            for(Event__c ev : allEventsOfAccount) {
                if(!accountIdEventMap.containsKey(ev.Account__c)) {
                    accountIdEventMap.put(ev.Account__c, ev);
                }
                                
            }

            Map<Id, List<Account_Team__c>> accountIdToTeams = new Map<Id, List<Account_Team__c>>();
            for (Account_Team__c team : [
                SELECT Id, BDMPropelI__c, Account__c, Account__r.Parent.Parent.Id, LastEventDate__c
                FROM Account_Team__c
                WHERE Account__r.Parent.Parent.Id IN :allAccountIds AND BDMPropelI__c IN :eventOwnerIds
            ]) {
                if (!accountIdToTeams.containsKey(team.Account__r.Parent.Parent.Id)) {
                    accountIdToTeams.put(team.Account__r.Parent.Parent.Id, new List<Account_Team__c>());
                }
                accountIdToTeams.get(team.Account__r.Parent.Parent.Id).add(team);
            }
            List<Account_Team__c> teamsToUpdate = new List<Account_Team__c>();

            for (Id teamAccountId : accountIdToTeams.keySet()) {
                List<Account_Team__c> teams = accountIdToTeams.get(teamAccountId);
                if (teams != null && !teams.isEmpty()) {
                    Event__c eve = accountIdEventMap.get(teamAccountId);
                    for (Account_Team__c team : teams) {
                        if (eve != null && eve.Account__c != null) {
                            if(team.LastEventDate__c != eve.CreatedDate){
                                team.LastEventDate__c = eve.CreatedDate;
                                teamsToUpdate.add(team);
                            }
                            
                        } else {
                            if(team.LastEventDate__c != null){
                                team.LastEventDate__c = null;
                                teamsToUpdate.add(team);
                            }
                        }
                    }
                }
            }
            if (!teamsToUpdate.isEmpty()) update teamsToUpdate;
        } catch(Exception e){
            System.debug('Exception in addLastEventDate : '+e.getMessage());
            ExceptionHandling.Exception('addLastEventDate', 'CustomEventTriggerHandler', e.getMessage());
        }
    }
    
    /**
* Recalculate LastEventDate__c on Account_Team__c records when Events are deleted
* or when Events are unchecked. 
* Ensures the field is cleared if no remaining events exist for that Account–BDM pair.
*/
    public static void recalculateLastEventDate(Map<Id, Set<Id>> acctToOwners) {
        try{
            if (acctToOwners == null || acctToOwners.isEmpty()) return;
            
            Set<Id> accountIds = acctToOwners.keySet();
            Set<Id> ownerIds = new Set<Id>();
            for (Set<Id> s : acctToOwners.values()) {
                ownerIds.addAll(s);
            }
            if (accountIds.isEmpty() || ownerIds.isEmpty()) return;
            
            // Query remaining events for these Accounts + Owners
            List<Event__c> evts = [
                SELECT Id, Account__c, OwnerId, CreatedDate
                FROM Event__c
                WHERE Account__c IN :accountIds
                AND OwnerId IN :ownerIds
                ORDER BY CreatedDate DESC
            ];
            
            // Build latest event map: key = AccountId-OwnerId
            Map<String, Datetime> keyToLatest = new Map<String, Datetime>();
            for (Event__c e : evts) {
                String key = e.Account__c + '-' + e.OwnerId;
                if (!keyToLatest.containsKey(key)) {
                    keyToLatest.put(key, e.CreatedDate); // first = latest due to ORDER BY
                }
            }
            
            // Fetch Account_Team__c records for those Account + Owner combos
            List<Account_Team__c> teams = [
                SELECT Id, Account__c, BDMPropelI__c, LastEventDate__c
                FROM Account_Team__c
                WHERE Account__c IN :accountIds
                AND BDMPropelI__c IN :ownerIds
            ];
            
            List<Account_Team__c> updates = new List<Account_Team__c>();
            for (Account_Team__c team : teams) {
                String key = team.Account__c + '-' + team.BDMPropelI__c;
                Datetime latest = keyToLatest.get(key);
                
                if (latest == null && team.LastEventDate__c != null) {
                    // Clear the field if no events remain
                    team.LastEventDate__c = null;
                    updates.add(team);
                } else if (latest != null && team.LastEventDate__c != latest) {
                    // Update if different
                    team.LastEventDate__c = latest;
                    updates.add(team);
                }
            }
            
            if (!updates.isEmpty()) {
                update updates;
            }
        } catch(Exception e){
            System.debug('Exception in recalculateLastEventDate : '+e.getMessage());
            ExceptionHandling.Exception('recalculateLastEventDate', 'CustomEventTriggerHandler', e.getMessage());
        }
    }

    @InvocableMethod(label='Create and Delete Event Account Associations' description='Creates and Delete EventAccountAssociation records from Flow input')
    public static void createAssociations(List<RequestWrapper> requestList) {
        try{  
            if(requestList == null || requestList.isEmpty()) return;
            RequestWrapper request = requestList[0];
            
            List<Event_Account_Association__c> records = request.associations != null ? request.associations : new List<Event_Account_Association__c>();

            if(records.isEmpty()) return;

            if(request.isDelete != null && request.isDelete) {
                delete records;
            } else {
                insert records;
            }
        } catch(Exception e){
            System.debug('Exception in createAssociations : '+e.getMessage());
            ExceptionHandling.Exception('createAssociations', 'CustomEventTriggerHandler', e.getMessage());
        }   
         
    }
    
    public class RequestWrapper {
        @InvocableVariable(label='Event Account Associations')
        public List<Event_Account_Association__c> associations;

        @InvocableVariable(label='Is Delete Flag')
        public Boolean isDelete;
    }
    
}