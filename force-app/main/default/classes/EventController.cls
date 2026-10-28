public without sharing class EventController {

    Public Static Boolean isContactComplete (Id ContactId){

        Contact con = [Select Id, Is_Complete__c  from Contact where Id =: ContactId];
        return con.Is_Complete__c;
    }


    
}