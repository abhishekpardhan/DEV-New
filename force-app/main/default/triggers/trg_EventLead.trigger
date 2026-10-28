/**
 * Description      :   Trigger on Event_Lead__c object to perform various tasks upon different DML Operations by calling helper class methods
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
trigger trg_EventLead on Event_Lead__c (after insert) {
    
    //Checking trigger switch value
    if(System.Label.TriggerSwitch.equals('On')){
        List<String> lstMobile = new List<String>();
        if(trigger.isInsert && trigger.isAfter){
            for(Event_Lead__c el : trigger.new){
                if(el.Send_Sms__c == true){
                    lstMobile.add(el.Mobile_Phone__c);
                }
            }
            
            //Calling the helper class method to hit the api of sending the SMS to specific phone if 'Send_Sms__c' checkbox is true
            if(!lstMobile.isEmpty()){
                EventLeadHandler.sendSMS(lstMobile);
            }
        }
    }
}