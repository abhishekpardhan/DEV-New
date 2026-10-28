/**
* Description		:		Helper class for journey trigger to perform various Operations like updating the Amount Rs/Km in journey basis of User's Journey Type, preventing the user to create
more than one record for the same date etc.
* Created By       :       
* Created Date     :       31st july, 2019
* Release          :       15th August, 2019
* Last Modified on :       Shubham Girdhar
* Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-422
**/
public class JourneyTriggerHandler{
    
    //This method is to update the Amount Rs/Km in journey  basis of User's Journey Type.
    public static void updateAmountKm(List<Journey__c> lstJourney ,Set<Id> Owner){
        try{
            Map<Id , String> mapUser= new Map<Id , String>();
            Set<Date> IdJ = new Set<Date>();
            for(User objUser : [Select id, Journey_Type__c  from User where Id IN : Owner]){
                if(!String.isBlank(objUser.Journey_Type__c)){
                    mapUser.put(objUser.id , objUser.Journey_Type__c);
                }
            }
            for(Journey__c objJrny : lstJourney){
                if(mapUser.get(objJrny.ownerId) != null){
                    String jurnType = mapUser.get(objJrny.ownerId);
                    if(jurnType == 'Car'){ // && System.Label.Journey_Car_RS_KM.isNumeric()){
                        objJrny.Amount_Rs_Km__c = Decimal.ValueOf(System.Label.Journey_Car_RS_KM) ;
                    }else if(jurnType == 'Bike'){ // && System.Label.Journey_Car_RS_KM.isNumeric()){
                        objJrny.Amount_Rs_Km__c = Decimal.ValueOf(System.Label.Journey_Bike_RS_KM);
                    }
                }
            }
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updateAmountKm', 'JourneyTriggerHandler', e.getMessage());
        }
    }
    //Methos is to check that 1 journey record for 1 day 
    /* public static void checkRecord(Id UserId, Date CreatedDate){
list<Journey__c> jorList = new list<Journey__c>();
jorList = [Select id, name, CreatedById, Journey_Date__c from Journey__c where CreatedById =: UserId AND Journey_Date__c =: CreatedDate];
if(jorList.size() > 0){
adderror('');
}
}*/
    
    //Methos is to check that 1 journey record for 1 day
    public static void checkRecord(List<Journey__c> lstJourney ,Set<Date> journeyDate){
        try{
            Map<String, List<Journey__c>> mapUniqueComboToLstJourney = new Map<String, List<Journey__c>>();
            for(Journey__c objJourney : lstJourney){
                String uniqueCombo = objJourney.OwnerId + '::' + objJourney.Journey_Date__c.format();
                if(mapUniqueComboToLstJourney.containsKey(uniqueCombo))
                    mapUniqueComboToLstJourney.get(uniqueCombo).add(objJourney);
                else
                    mapUniqueComboToLstJourney.put(uniqueCombo, new List<Journey__c>{objJourney});
            }
            
            if(!mapUniqueComboToLstJourney.isEmpty()){
                for(Journey__c objJourney : [Select id,ownerId,Journey_Date__c  from Journey__c where Journey_Date__c IN : journeyDate ]){
                    String uniqueCombo = objJourney.OwnerId + '::' + objJourney.Journey_Date__c.format();
                    if(mapUniqueComboToLstJourney.get(uniqueCombo) != null)
                        mapUniqueComboToLstJourney.get(uniqueCombo)[0].addError('Record is present with the same Journey Date,Please change the Journey Date.');
                    
                }
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('checkRecord', 'JourneyTriggerHandler', e.getMessage());
        }

    } 
    
    //Method to Lock/Unlock the Event and Expense Item records if thier parent journey records are Lock/Unlock
    public static void updateLockRecords(Set<Id> lockIds , Set<Id> unLockIds){
        try
        {
            List<Event__c> lstLockEvent = [Select Id from Event__c where Journey__c IN : lockIds];
            List<Event__c> unLockEvent = [Select Id from Event__c where Journey__c IN : unLockIds];
            Approval.LockResult[] lockListEvent = Approval.lock(lstLockEvent, false);
            Approval.UnLockResult[] unLockListEvent = Approval.Unlock(unLockEvent , false);
            
            List<Expense_Item__c> lstLockExpense = [Select Id from Expense_Item__c where Journey__c IN : lockIds];
            List<Expense_Item__c> unLockExpense = [Select Id from Expense_Item__c where Journey__c IN : unLockIds];
            Approval.LockResult[] lockListExpense = Approval.lock(lstLockExpense, false);
            Approval.UnLockResult[] unLockListExpense = Approval.Unlock(unLockExpense , false);
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
             ExceptionHandling.Exception('updateLockRecords', 'JourneyTriggerHandler', e.getMessage());
        }
    }

    public static void eventTimeRollup(List<Journey__c> journeyRecords){
        try{
            Map<Id, Decimal> journeyTimeMap = new Map<Id, Decimal>();
            for(AggregateResult ar : [SELECT SUM(Time_Spent_in_minutes__c) totalTime, Journey__c FROM Event__c WHERE Journey__c IN :journeyRecords GROUP BY Journey__c]){
                journeyTimeMap.put((Id)ar.get('Journey__c'), (Decimal)ar.get('totalTime'));
            }
            for (Journey__c journey : journeyRecords) {

                Decimal totalMinutes = journeyTimeMap.get(journey.Id);

                if (totalMinutes == null) {
                    continue;
                }
                Integer minutes = totalMinutes.intValue(); // total minutes
                Integer hours = minutes / 60;
                Integer remainingMinutes = Math.mod(minutes, 60);

                String formattedTime;

                String hh = (hours < 10 ? '0' : '') + String.valueOf(hours);
                String mm = (remainingMinutes < 10 ? '0' : '') + String.valueOf(remainingMinutes);

                if (hours > 0) {
                    formattedTime = hh + 'h ' + mm + 'm';
                } else {
                    formattedTime = mm + 'm';
                }

                // Update only if value changed (best practice)
                if (journey.Time_Spent_in_Events__c != formattedTime) {
                    journey.Time_Spent_in_Events__c = formattedTime;
                }
            }

                
        } catch(Exception e){
            system.debug('Exception in eventTimeRollup: ' + e.getMessage());
            ExceptionHandling.Exception( 'eventTimeRollup', 'JourneyTriggerHandler', e); 
        }
    }
    
    //Method to update the journey record type to New Journey and deleting child Last Event if Journey is not approved
    public static void reOpenJourney(List<Journey__c> lstJourney){
        Savepoint sp = Database.setSavepoint();
        try
        {
            Id recordsTypenew = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('New Journey').getRecordTypeId();
            List<Journey__c> lstJourneyUpdate = [Select id,(Select id from Events__r where name = 'Journey Last Event' limit 1) ,recordtypeId from journey__c where Id IN :lstJourney];
            List<Event__c> lstEvent =new List<Event__c>();
            for(journey__c objJourney : lstJourneyUpdate){
                if(objJourney.Events__r.size() > 0){
                    lstEvent.add(objJourney.Events__r[0]);
                }
                objJourney.recordTypeId = recordsTypenew;
            }
            if(lstEvent.size() > 0){
                update lstJourneyUpdate ;
                delete lstEvent;
            }
        }catch(Exception e){
            lstJourney[0].addError(e.getMessage());
            Database.rollback(sp);
            system.debug('Exception:'+e.getMessage());
            system.debug('Exception:'+e.getLineNumber());
        }
    }
    // Method to Auto tag the event created by event team, whenver the journey created. added by abhishek pardhan sac 2007
    public static void eventAutoTag(List<Journey__c> lstJourney) {
        try{
            if (lstJourney == null || lstJourney.isEmpty()) return;

            // Collect ownerIds and journey dates
            Set<Id> ownerIds = new Set<Id>();
            Set<Date> journeyDates = new Set<Date>();
            Map<String, Id> journeyKeyMap = new Map<String, Id>();
            Map<String, Id> eventJourneyMap = new Map<String, Id>();
            List<Event__c> evList = new List<Event__c>();
            Set<Date> eventDates = new Set<Date>();
            for(Event__c ev : [SELECT Id, OwnerId, Start__c, Journey__c FROM Event__c WHERE Journey__c IN : lstJourney]) {
                ev.Journey__c = null;
                evList.add(ev);
            }
            if(!evList.isEmpty()) {
                update evList;
            }

            for (Journey__c jr : lstJourney) {
                if (jr.OwnerId != null && jr.Journey_Date__c != null) {
                    ownerIds.add(jr.OwnerId);
                    journeyDates.add(jr.Journey_Date__c);
                    journeyKeyMap.put(jr.OwnerId + '_' + jr.Journey_Date__c, jr.Id);
                }
            }

            if (ownerIds.isEmpty() || journeyDates.isEmpty()) return;

            // Query matching events
            List<Event__c> eventsToUpdate = new List<Event__c>();

            for (Event__c ev : [
                SELECT Id, OwnerId, Start__c, Journey__c
                FROM Event__c
                WHERE OwnerId IN :ownerIds
                AND Start__c != NULL
                AND DAY_ONLY(Start__c) IN :journeyDates
            ]) {
                Date eventDate = ev.Start__c.date();
                Id correctJourneyId = journeyKeyMap.get(ev.OwnerId + '_' + eventDate);

                if (correctJourneyId != null && ev.Journey__c != correctJourneyId) {
                    ev.Journey__c = correctJourneyId;
                    eventsToUpdate.add(ev);
                }
            }

            if (!eventsToUpdate.isEmpty()) {
                update eventsToUpdate;
            }

        } catch (Exception e) {
            system.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updateLockRecords', 'JourneyTriggerHandler', e.getMessage());
        }
    }
    
    public static void checkUnresolvedJourneys(List<Journey__c> lstJourney) {
        try{
            Set<Id> userIds = new Set<Id>();
            Map<Id, Date> journeyDates = new Map<Id, Date>();
            
            for (Journey__c journey : lstJourney) {
                userIds.add(journey.OwnerId);
                journeyDates.put(journey.Id, journey.Journey_Date__c);
            }
            
            List<Journey__c> olderJourneys = [
                SELECT Id, Name, OwnerId, Journey_Date__c, Approval_Status__c, ByPass_Lock__c 
                FROM Journey__c 
                WHERE OwnerId IN :userIds
                AND Journey_Date__c < :System.today()
                ORDER BY Journey_Date__c DESC
            ];
            
            Map<Id, List<Journey__c>> userJourneyMap = new Map<Id, List<Journey__c>>();
            
            for (Journey__c journey : olderJourneys) {
                if (!userJourneyMap.containsKey(journey.OwnerId)) {
                    userJourneyMap.put(journey.OwnerId, new List<Journey__c>());
                }
                userJourneyMap.get(journey.OwnerId).add(journey);
            }
            
            for (Journey__c currentJourney : lstJourney) {
                if (currentJourney.Approval_Status__c == 'Not to be claimed' || currentJourney.Approval_Status__c == 'Submitted for Approval') {
                    List<Journey__c> userOlderJourneys = userJourneyMap.get(currentJourney.OwnerId);
                    if (userOlderJourneys != null) {
                        for (Journey__c olderJourney : userOlderJourneys) {
                            if (olderJourney.Journey_Date__c >= currentJourney.Journey_Date__c) {
                                continue;
                            }
                            if (unResolvedJourneyExists(olderJourney)) {
                                String pendingJourney = olderJourney.Name;
                                showError(currentJourney,pendingJourney);
                            }
                        }
                    }
                }
            }

        }catch(Exception e){
            ExceptionHandling.Exception('checkUnresolvedJourneys', 'JourneyTriggerHandler', e.getMessage());
        }
    }
    
    public static boolean unResolvedJourneyExists(Journey__c olderJourney ){
        try{
            if (olderJourney.Approval_Status__c != null && !olderJourney.Approval_Status__c.contains('Approved') &&
                !olderJourney.Approval_Status__c.contains('Rejected') &&
                olderJourney.Approval_Status__c != 'Submitted for Approval' &&
                olderJourney.Approval_Status__c != 'Not to be Claimed' && olderJourney.Approval_Status__c != 'Pending from RM' && 
                (olderJourney.Journey_Date__c >= System.today().addDays(-30) || olderJourney.ByPass_Lock__c)) {
                return true;
            } else {
                return false;
            }
                
        } catch(Exception e){
            System.debug('Exception in JourneyTriggerHandler.unResolvedJourneyExists'+e);
            ExceptionHandling.Exception('unResolvedJourneyExists', 'JourneyTriggerHandler', e.getMessage());
        }
        return false;
    }
    
    public static void showError(Journey__c currentJourney , String oldJourney ){
        currentJourney.addError('You must take action on previous journeys '+oldJourney+' before proceeding with this one.');
    }
    // Converting the process builder "Journey for Regional Manager" in trigger - By Tarun Sachdeva
    public static void checkJourneyForRegionalManager(List<Journey__c> newJourney){
        try {  
            Set<Id> ownID = new Set<Id>();
            for(Journey__c jou :newJourney){
                ownID.add(jou.ownerId);
            }
            List<User> usOfReg = [Select id,profile.name from user where profile.name =:ConstantUtility.Profile_Regional_Manager AND id IN :ownId];
            ownID.clear();

            for(User u : usOfReg){
                ownID.add(u.id);
            }

            for(Journey__c newJou : newJourney){
                if((ownID.contains(newJou.OwnerId) && (newJou.Final_Amount__c > 0 || newJou.Actual_Amount__c > 0 || newJou.Journey_KM__c> 0))){
                    newJou.Approval_Status__c ='Auto Approved';
                }
            }

        } catch(Exception e){
            System.debug('Exception in JourneyTriggerHandler.checkJourneyForRegionalManager'+e);
            ExceptionHandling.Exception('checkJourneyForRegionalManager', 'JourneyTriggerHandler', e.getMessage());
        }
    }
}