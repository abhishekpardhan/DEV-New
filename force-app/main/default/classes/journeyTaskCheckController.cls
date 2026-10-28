public with sharing class journeyTaskCheckController {
     // Created By sahil Jain 24/11/2025 SAC:1998
   
    public journeyTaskCheckController() {
       
    }
        Public Static Id onBoardingTaskRecordTypeId = TASK.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('On_Boarding').getRecordTypeId();
        Public Static Id onGeneralTaskRecordTypeId   = ConstantUtility.TASK_GENERAL_RECORDTYPE_ID;
        Public Static Id onTaskCustomerRelationshipProfilingTaskId = ConstantUtility.TASK_CUSTOMER_RELATIONSHIP_PROFILING_TASK_ID;

    
    public static String journeyTaskCheck(Id JourneyId) {
        try {
            // Fetch events related to journey
            Date LatestJourneyDate;
            List<Event__c> eventList = [
                SELECT Id, OwnerId, Account__c
                FROM Event__c
                WHERE Journey__c =:JourneyId
            ];
            List<Journey__c> journeys = [Select id,Journey_Date__c from Journey__c where Id =:JourneyId];
            
             for(Journey__c jr : journeys){
             if(LatestJourneyDate==null){
               LatestJourneyDate =  jr.Journey_Date__c;
            }
            else{
                if(LatestJourneyDate< jr.Journey_Date__c){
                    LatestJourneyDate = jr.Journey_Date__c ; 
                }
            }
        }
            Set<Id> accountIds = new Set<Id>();
            Set<Id> ownerIds   = new Set<Id>();
            
            for (Event__c ev : eventList) {
                if (ev.Account__c != null) accountIds.add(ev.Account__c);
                if (ev.OwnerId   != null) ownerIds.add(ev.OwnerId);
            }
            
          
            return taskCheck(accountIds,ownerIds,new Set<Id>{onGeneralTaskRecordTypeId, onBoardingTaskRecordTypeId,onTaskCustomerRelationshipProfilingTaskId},LatestJourneyDate);
        }
        catch (Exception e) {
            ExceptionHandling.Exception('journeyTaskCheck','journeyTaskCheckController',e);
            Throw e;
        }
    }

   
    public static String eventTaskCheck(Id eventID) {
        try {
 				
            // Fetch events related to journey
            Date LatestJourneyDate;
            Set<Id> journeyId = new Set<Id>();
            List<Event__c> eventList = [
                SELECT Id, OwnerId, Account__c,Journey__c
                FROM Event__c
                WHERE Id =:eventID
            ];
           
            for(Event__c eve:eventList){
                journeyId.add(eve.Journey__c);
            }
            
            List<Journey__c> journeys = [Select id,Journey_Date__c from Journey__c where Id IN :journeyId];
            
             for(Journey__c jr : journeys){
             if(LatestJourneyDate==null){
               LatestJourneyDate =  jr.Journey_Date__c;
            }
            else{
                if(LatestJourneyDate< jr.Journey_Date__c){
                    LatestJourneyDate = jr.Journey_Date__c ; 
                }
            }
        }
            Set<Id> accountIds = new Set<Id>();
            Set<Id> ownerIds   = new Set<Id>();
            
            for (Event__c ev : eventList) {
                if (ev.Account__c != null) accountIds.add(ev.Account__c);
                if (ev.OwnerId   != null) ownerIds.add(ev.OwnerId);
            }
            
          
            return taskCheck(accountIds,ownerIds,new Set<Id>{onGeneralTaskRecordTypeId, onBoardingTaskRecordTypeId,onTaskCustomerRelationshipProfilingTaskId},LatestJourneyDate);
        }
        catch (Exception e) {
             ExceptionHandling.Exception('eventTaskCheck','journeyTaskCheckController',e);
            Throw e;
        }
    }

    Private static String taskCheck(Set<Id>accountIds,Set<Id> ownerIds,Set<Id> RecordTypeIds,Date LatestJourneyDate){
         List<Task> accountTasks = new List<Task>();
        
         if (!accountIds.isEmpty() && !ownerIds.isEmpty() && !RecordTypeIds.isEmpty() && LatestJourneyDate!=null) {
                accountTasks = [
                    SELECT Id,ActivityDate
                    FROM Task
                    WHERE WhatId IN :accountIds
                    AND OwnerId  IN :ownerIds
                    AND Status = 'Open'
                    AND RecordTypeId IN :new Set<Id>{onGeneralTaskRecordTypeId,onBoardingTaskRecordTypeId,onTaskCustomerRelationshipProfilingTaskId}AND ActivityDate<=:LatestJourneyDate
                ];
               
                if (accountTasks.isEmpty()) {
                    return 'False';
                }  
                return 'True';   
            }
                
                return 'False';
            
            
    }

    @InvocableMethod(label='Get User Record Access'
                     description='Returns read/edit access for the provided user and record IDs.')
    public static List<List<Event__Share>> getAccessDetails(List<AccessRequest> requests) {
        List<Event__Share> responseList = new List<Event__Share>();
        try {
            AccessRequest req = requests[0];

            if (req.recordIds == null || req.recordIds.isEmpty()) {
                return new List<List<Event__Share>>{ new List<Event__Share>() };
            }

            List<UserRecordAccess> uraList = [
                SELECT RecordId, HasReadAccess, HasEditAccess
                FROM UserRecordAccess
                WHERE UserId = :req.userId
                AND RecordId IN :req.recordIds
            ];

            Map<Id, UserRecordAccess> accessMap = new Map<Id, UserRecordAccess>();
            for (UserRecordAccess ura : uraList) {
                accessMap.put(ura.RecordId, ura);
            }

            for (Id recId : req.recordIds) {

                UserRecordAccess ura = accessMap.get(recId);

                Event__Share shareRecord = new Event__Share();
                shareRecord.ParentId = recId;
                shareRecord.UserOrGroupId = req.userId;
                shareRecord.RowCause = Schema.Event__Share.RowCause.Manual;

                if (ura == null) {
                    if (req.shouldHaveEditAccess == true) {
                        shareRecord.AccessLevel = 'Edit';
                    } else if (req.shouldHaveReadAccess == true) {
                        shareRecord.AccessLevel = 'Read';
                    }
                    responseList.add(shareRecord);
                    continue;
                }

                Boolean hasRead = ura.HasReadAccess;
                Boolean hasEdit = ura.HasEditAccess;

                if (req.shouldHaveEditAccess == true && !hasEdit) {
                    shareRecord.AccessLevel = 'Edit';
                    responseList.add(shareRecord);
                }
                else if (req.shouldHaveReadAccess == true && !hasRead) {
                    shareRecord.AccessLevel = 'Read';
                    responseList.add(shareRecord);
                }

            }
        } catch (Exception e) {
            ExceptionHandling.Exception('getAccessDetails','journeyTaskCheckController',e);
        }

        return new List<List<Event__Share>>{ responseList };
    }

    public class AccessRequest {
        @InvocableVariable(required=true)
        public List<Id> recordIds;

        @InvocableVariable(required=true)
        public String userId;

        @InvocableVariable
        public Boolean shouldHaveReadAccess;

        @InvocableVariable
        public Boolean shouldHaveEditAccess;
    }
}