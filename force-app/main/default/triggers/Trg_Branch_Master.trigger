trigger Trg_Branch_Master on Branch_Master__c (before insert , after Insert, after update) {
//Checking trigger switch value
 /*   if(System.Label.TriggerSwitch.equals('On')){
        set<Id> BranchId = new set<Id>();
        set<Id> BranchIdList = new set<Id>();
        if(trigger.isAfter && trigger.isInsert){
            for(Branch_Master__c Branch : trigger.new){
                if(Branch.Branch_Type__c == 'ARM'){
                    BranchId.add(Branch.id);
                    system.debug('@@@@@@@@@@@@@@'+BranchId);
                }    
            }
            if(BranchId.size() > 0){
        BranchMasterHelper.markArmAccounts(BranchId);    
        }
        }
        if(trigger.isAfter && trigger.isUpdate){
            for(Branch_Master__c Branch : trigger.new){
                if(Branch.Branch_Type__c != 'ARM' ){
                    BranchIdList.add(Branch.Id);
                    system.debug('@@@@@@@@@@@@@@@@@@@@'+BranchIdList);
                }
                if(Branch.Branch_Type__c == 'ARM'){
                    BranchId.add(Branch.id);
                    system.debug('###################'+BranchId);
                }
            }
                if(BranchIdList.size() > 0){
               BranchMasterHelper.removeArmAccounts(BranchIdList);
                }
            else if(BranchId.size() > 0){
             BranchMasterHelper.markArmAccounts(BranchId);   
            }
            
         /*   for(Branch_Master__c Branch : trigger.new){
                if(Branch.Branch_Type__c == 'ARM'){
                    BranchId.add(Branch.id);
                }    
            }
            if(BranchId.size() > 0){
        BranchMasterHelper.markArmAccounts(BranchId);    
        }
       comment ends here  
        }
    } */
}