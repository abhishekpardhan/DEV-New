/**
 * Description      :   Trigger on User_Branch_Mapping__c object to perform various tasks upon different DML Operations by calling helper class methods
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
trigger trg_UserBranchMapping on User_Branch_Mapping__c (after insert,before update,before delete) {
    
    //Checking Trigger Switch value
    if(System.Label.TriggerSwitch.equals('On')){
        if(trigger.isInsert && trigger.isAfter){
            
            //Calling the method to provide the Account share to branch user
            UserBranchTriggerHelper.newInsert(trigger.new);
        }
        
        if(trigger.isUpdate && trigger.isBefore){
            List<User_Branch_Mapping__c> lstRecords = new List<User_Branch_Mapping__c>();
            for(User_Branch_Mapping__c ubm : trigger.new){
                if(ubm.Branch_Name__c != trigger.oldmap.get(ubm.Id).Branch_Name__c && ubm.User__c == trigger.oldmap.get(ubm.Id).User__c){                
                    lstRecords.add(ubm);
                }
            }                
            
            //Updating sharing for branch users
            UserBranchTriggerHelper.updateOnRecord(trigger.new,trigger.oldmap);
            UserBranchTriggerHelper.newInsert(trigger.new);
        }
        
        //Calling the method to remove sharing if record is getting deleted
        if(trigger.isDelete && trigger.isBefore){
            UserBranchTriggerHelper.deleteOnRecord(trigger.old);
        }
    }
}