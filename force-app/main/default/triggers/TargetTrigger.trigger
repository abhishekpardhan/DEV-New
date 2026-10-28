/**
 * Description      :   Trigger on Target__c object to perform various tasks upon different DML Operations by calling helper class methods
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
trigger TargetTrigger on Target__c (before insert ,after insert) {
    
    //Checking trigger switch values
    if(System.Label.TriggerSwitch.equals('On')){
        
        //Getting the record type for the 'Target__c' Object
        List<RecordType> lstRecordRegion = [Select Id, DeveloperName from RecordType where SobjectType= 'Target__c' and DeveloperName = 'Region' limit 1] ;
        Id regionId = lstRecordRegion[0].Id; 
        if(trigger.isBefore){
            List<Target__c> lstTarget = new List<Target__c>();
            if(trigger.isInsert){
                for(Target__c objTar : trigger.new){
                    if(objTar.recordTypeId == regionId && string.isNotBlank(objTar.Level__c) && objTar.Level__c == 'Region Level'){
                        lstTarget.add(objTar); 
                    }                    
                }
                
                //Calling the helper class method to update the owner on the target object according to region 
                if(lstTarget.size() > 0){
                    TargetActions.changeOwner(lstTarget);
                } 
            }
        }
        if(trigger.isAfter)
        {
            List<Target__c> lstTarget = new List<Target__c>();
            if(trigger.isInsert)
            {
                for(Target__c objTar : trigger.new){
                    if(objTar.recordTypeId == regionId && string.isNotBlank(objTar.Level__c) && objTar.Level__c == 'Region Level'){
                        lstTarget.add(objTar); 
                    }                    
                }
                
                //Calling the method to create the Targets for AM and BDM users as well
                if(lstTarget.size() > 0){
                    TargetActions.createAutoTarget(lstTarget);
                } 
            }
        }
    }
}