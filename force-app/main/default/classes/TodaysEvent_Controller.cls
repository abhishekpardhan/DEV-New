/**
 * Description		:		Todays Event component controller
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th jan, 2020
 * Release          :       25th jan, 2020
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
public with sharing class TodaysEvent_Controller {
    @AuraEnabled
    public static list<Event__c> GetEventList(Id CurrentUserId){
        List<Event__c> EventListReturn = new list<Event__c>();
        List<Event__c> EventList = new List<Event__c>();
        EventList = [select id, name, status__c,Start__c,StartDate__c from Event__c where ownerId =: CurrentUserId AND Start__c >= today AND Start__c <= NEXT_N_DAYS:7 ORDER BY Start__c ASC ];
        for(Event__c Eve: EventList){
           Eve.StartDate__c = Eve.Start__c.date();
EventListReturn.add(Eve);
        }
        Update EventListReturn;
        return EventListReturn;
    }
    }