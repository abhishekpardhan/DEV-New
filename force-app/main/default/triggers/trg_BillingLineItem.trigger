trigger trg_BillingLineItem on Billing_Line_Item__c (after insert,after update,before update , before insert) {
    //Checking trigger switch values
    if(System.Label.TriggerSwitch.equals('On')){
        
        if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
                BLITriggerHelper.updateBLIOnInvoice(trigger.new,trigger.oldMap);      //SAC-1550

            if(trigger.IsUpdate){
               BLITriggerHelper.updateGBOnTasks(trigger.new,trigger.oldMap); //SAC-1550
            }
            
        }   
        
    }
}