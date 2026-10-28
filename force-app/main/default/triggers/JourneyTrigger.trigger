/*
 * Description		:		Trigger on Journey__c object to perform various tasks upon different DML Operations by calling helper class methods
 * Created By       :       
 * Created Date     :       31st july, 2019
 * Release          :       15th August, 2019
 * Last Modified on :       Shubham Girdhar
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-422
 */
trigger JourneyTrigger on Journey__c (before insert ,before update , after update , after insert) {
    
    //Checking Trigger switch is on or Off
    if(System.Label.TriggerSwitch.equals('On')){
        if(Trigger.isInsert && trigger.IsBefore){
            Set<Date> journeyDate = new Set<Date>();
            Set<Id> jourOwnerIds = new Set<Id>();
            List<Journey__c> lstCheck = new List<Journey__c>();
            List<Journey__c> lstJourney = new List<Journey__c>();
            Schema.DescribeSObjectResult userKey = User.sObjectType.getDescribe();
            
            Id currentUserId = UserInfo.getUserId();
            List<Campaign__c> campaignList = [SELECT Id FROM Campaign__c Where End_Date__c < Today AND Status__c = 'Active' AND OwnerId =:currentUserId];

            //trigger to restrict user to create one journey per day
         /*   for(Journey__c objJour : trigger.new){
                JourneyTriggerHandler.checkRecord(objJour.CreatedById, objJour.Journey_Date__c);
            } */
           
            
            for(Journey__c objJour : trigger.new){
                if (!campaignList.isEmpty()) {
                    objJour.addError('You cannot create a new Journey while there are Active Campaigns past their End Date. Please mark those Campaigns as Cancelled or Completed.');
                }
                if(objJour.Journey_Date__c != null){
                    journeyDate.add(objJour.Journey_Date__c);
                    lstCheck.add(objJour);
                }
                if(String.ValueOf(objJour.ownerId).startsWith(userKey.getKeyPrefix())){
                    jourOwnerIds.add(objJour.ownerId);
                    lstJourney.add(objJour);
                }
            }
            
            //This method is to update the Amount Rs/Km in journey  basis of User's Journey Type.
            if(jourOwnerIds.size()  >0){
                JourneyTriggerHandler.updateAmountKm(lstJourney ,jourOwnerIds);
            }
            
            // test Methos is to check that 1 journey record for 1 day
            if(journeyDate.size() > 0){
            JourneyTriggerHandler.checkRecord(lstCheck ,journeyDate); //commeted by shubham due to bug
            }
            // JourneyTriggerHandler.checkJourneyForRegionalManager(trigger.new); //By Tarun Sachdeva
        }
        if(Trigger.isUpdate && trigger.IsBefore){
            list<Journey__c> jorList = new list<Journey__c>();
            Id jouneyCompletedID = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('Journey Completed').getRecordTypeId();
            List<Journey__c> journeyRecords = new List<Journey__c>();
            Set<Date> journeyDate = new Set<Date>();
            List<Journey__c> lstCheck = new List<Journey__c>();
            List<Journey__c> listCheck = new List<Journey__c>();
            for(Journey__c objJour : trigger.new){
                // Start SAC-1197 ||Deepika Thakur || IBM
                Journey__c oldJourney = Trigger.oldMap.get(objJour.Id);
                if (objJour.ByPass_Lock__c && (oldJourney == null || !oldJourney.ByPass_Lock__c)) {
                    objJour.Last_Bypassed_date__c = System.now();
                }
                
                if (trigger.oldMap.get(objJour.id).CheckOut_Date__c != objJour.CheckOut_Date__c) {
                    journeyRecords.add(objJour);
                }
                
                if ((objJour.Approval_Status__c!=oldJourney.Approval_Status__c)&&
                    (objJour.Approval_Status__c=='Not to be Claimed')) {
                        listCheck.add(objJour);
                        objJour.ByPass_Lock__c= false;
                    }

                if((/*objJour.Journey_Audited__c != oldJourney.Journey_Audited__c &&*/
                   objJour.Remarks_To_be_filled_by_Auditors__c != '' &&
                    objJour.Remarks_To_be_filled_by_Auditors__c != oldJourney.Remarks_To_be_filled_by_Auditors__c)||
                   (objJour.ByPass_Lock__c != oldJourney.ByPass_Lock__c)){
                       System.debug('TEST 1');
                   }else{
                       System.debug('TEST 2');
                       // Check if the record is locked
                     /*  if (!objJour.ByPass_Lock__c && ((oldJourney.Journey_Date__c < System.today().addDays(-30))||oldJourney.Approval_Status__c == 'Not to be Claimed' )) {
                           // Prevent any changes
                           objJour.addError('This record is locked and cannot be edited');
                           break;
                       }*/
                       // End SAC-1197 ||Deepika Thakur || IBM
                       if(objJour.recordtypeid == jouneyCompletedID && objJour.Approval_Status__c == 'Submitted for Approval' && trigger.oldMap.get(objJour.id).Approval_Status__c == 'Not Submitted for Approval'){
                           objJour.Approved_Amount__c = objJour.Final_Amount__c;
                       }
                       if((objJour.Actual_KM__c == null ||objJour.Actual_KM__c == 0) && objJour.Approval_Status__c == 'Submitted for Approval'  && (objJour.Approval_Status__c != trigger.oldMap.get(objJour.id).Approval_Status__c || String.isBlank(trigger.oldMap.get(objJour.id).Approval_Status__c))){
                           objJour.Actual_KM__c = objJour.Journey_KM__c;
                       }
                       if(objJour.Journey_Date__c != null && trigger.oldMap.get(objJour.id).Journey_Date__c != objJour.Journey_Date__c){
                           journeyDate.add(objJour.Journey_Date__c);
                           lstCheck.add(objJour);
                       }
                       
                       if((objJour.Approval_Status__c == 'Submitted for Approval' && trigger.oldMap.get(objJour.id).Approval_Status__c == 'Not Submitted for Approval')||(objJour.Approval_Status__c == 'Not to be Claimed')){
                           listCheck.add(objJour);
                       }
                   }
                
                //Method is to check that 1 journey record for 1 day
                if(journeyDate.size() > 0){
                    JourneyTriggerHandler.checkRecord(lstCheck ,journeyDate);
                }
            }
            if (!journeyRecords.isEmpty()) {
                //JourneyTriggerHandler.checkCheckoutEvents(journeyRecords,journeyIds);
            }

            if(!journeyRecords.isEmpty()) {
                JourneyTriggerHandler.eventTimeRollup(journeyRecords);
            }
            //Method is to check that no older journey record are either in "Submitted for Approval" or "Not to be Claimed"
                if(listCheck.size() > 0){
                    JourneyTriggerHandler.checkUnresolvedJourneys(listCheck);
                }
                //    JourneyTriggerHandler.checkJourneyForRegionalManager(trigger.new); //By Tarun Sachdeva  
        }
        if(trigger.isAfter && trigger.isUpdate){
            Set<Id> setLockJId = new Set<Id>();
            Set<Id> UnLockJId = new Set<Id>();
            List<Journey__c> lstCheck = new List<Journey__c>();
            List<Journey__c> lstReJourney = new List<Journey__c>();
            for(Journey__c objJour : trigger.new){
                
                if(objJour.Is_Locked__c != trigger.oldMap.get(objJour.Id).Is_Locked__c && objJour.Is_Locked__c){
                    setLockJId.add(objJour.id);
                }else if(objJour.Is_Locked__c != trigger.oldMap.get(objJour.Id).Is_Locked__c && !objJour.Is_Locked__c){
                    UnLockJId.add(objJour.id);
                }
                if(objJour.Approval_Status__c != 'Approved by Manager' && objJour.CheckOut_Date__c != trigger.oldMap.get(objJour.Id).CheckOut_Date__c && objJour.CheckOut_Date__c == null){
                    lstReJourney.add(objJour);
                }
                if(objJour.Journey_Date__c != null && trigger.oldMap.get(objJour.id).Journey_Date__c != objJour.Journey_Date__c){
                    lstCheck.add(objJour);
                }
            }

            if(lstCheck.size() > 0){
                JourneyTriggerHandler.eventAutoTag(lstCheck);
            }
            
           

            // Method to Lock/Unlock the Event and Expense Item records if their parent journey records are Lock/Unlock by Anand Raju
                if (setLockJId.size() > 0 || UnLockJId.size() > 0) {
                JourneyTriggerHandler.updateLockRecords(setLockJId, UnLockJId);
                }

                
//************************ *********************/
            
                Set<Id> rejectedIds_resubmittedIds = new Set<Id>();

                for (Journey__c objJour : Trigger.new) {
                    String oldStatus = Trigger.oldMap.get(objJour.Id).Approval_Status__c;
                    String newStatus = objJour.Approval_Status__c;


                    if(newStatus != oldStatus ){
                        if (newStatus == 'Rejected by RM' ||
                             newStatus == 'Rejected by Manager' || 
                                newStatus == 'Submitted for Approval' ||
                                 newStatus == 'Approved by Manager' )
                                 {
                            rejectedIds_resubmittedIds.add(objJour.Id);

                        }

                    }
                }

                if (!rejectedIds_resubmittedIds.isEmpty()) {
                    List<Event__c> eventsToUnlock = new List<Event__c>();
                    List<Event__c> eventsToLock   = new List<Event__c>();

                    
                    for (Event__c evt : [
                        SELECT Id, Journey__c, Journey__r.Approval_Status__c
                        FROM Event__c
                        WHERE Journey__c IN :rejectedIds_resubmittedIds
                    ]) {
                        
                        if (evt.Journey__r.Approval_Status__c == 'Rejected by RM' ||
                             evt.Journey__r.Approval_Status__c == 'Rejected by Manager') {
                                eventsToUnlock.add(evt);
                        } else if (evt.Journey__r.Approval_Status__c == 'Submitted for Approval' ||
                                     evt.Journey__r.Approval_Status__c == 'Approved by Manager') {
                                        eventsToLock.add(evt);
                        }
                    }

                    if (!eventsToUnlock.isEmpty()) {
                        Approval.unlock(eventsToUnlock, false);
                    }
                    if (!eventsToLock.isEmpty()) {
                        Approval.lock(eventsToLock, false);
                    }
                }                 
            
            //Method to update the journey record type to New Journey and deleting child Last Event if Journey is not approved
            if(lstReJourney.size() > 0){
                JourneyTriggerHandler.reOpenJourney(lstReJourney);

            } 
        }
        // Method to Auto tag the event created by event team, whenver the journey created. added by Shubham Girdhar
        if(Trigger.isInsert && trigger.IsAfter){
           JourneyTriggerHandler.eventAutoTag(trigger.new); 
        }
       
    } 
}