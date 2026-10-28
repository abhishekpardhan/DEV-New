/**
 * Description      :   Trigger on Event_Lead__c object to perform various tasks upon different DML Operations by calling helper class methods
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
trigger EventLeadTrigger on Event_Lead__c (after insert ,after update) {
    
    //Checking trigger switch values
    if(System.Label.TriggerSwitch.equals('On')){
        List<Event_Lead__c> listLead = new List<Event_Lead__c>();
        List<Event_Lead__c> listPrcLead = new List<Event_Lead__c>();
        
        if(trigger.isAfter && trigger.isInsert){
            For(Event_Lead__c objEveLead : trigger.new){
                if(objEveLead.Customer_Type__c =='Pick Up'){
                    listLead.add(objEveLead);
                }else if(objEveLead.Customer_Type__c =='Credit' ||  objEveLead.Customer_Type__c =='Retail'){
                    listPrcLead.add(objEveLead);
                }
            }
            
            //Calling the Method to create the Operational cases under 'NON PRC PICKUP ACCOUNT' if Event_Lead__c's Customer_Type__c is 'Pick up'
            if(listLead.size() > 0){
                EventLeadTriggerHandler.createCase(listLead);
            }
            
            //Calling the Method to create the Lead if Event_Lead__c's Customer_Type__c is either Credit or Retails
            if(listPrcLead.size() > 0){
                EventLeadTriggerHandler.createLead(listPrcLead);
            }
        }   
        /* if(trigger.isAfter && trigger.isUpdate){
For(Event_Lead__c objEveLead : trigger.new){
if(objEveLead.Customer_Type__c != trigger.oldMap.get(objEveLead.id).Customer_Type__c && objEveLead.Customer_Type__c =='1 Time Customer'){
listLead.add(objEveLead);
}else if(objEveLead.Customer_Type__c != trigger.oldMap.get(objEveLead.id).Customer_Type__c && objEveLead.Customer_Type__c =='PRC Customer'){
listPrcLead.add(objEveLead);
}
}
if(listLead.size() > 0){
EventLeadTriggerHandler.createCase(listLead);
}
if(listPrcLead.size() > 0){
EventLeadTriggerHandler.createLead(listPrcLead);
}
}*/
    }
}