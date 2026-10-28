/**
 * Description      :   Trigger on Lead__c object to perform various tasks upon different DML Operations by calling helper class methods
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
trigger trg_Lead on Lead__c (before insert,before update,after update,after insert) {    
    
    // By pass trigger
    if(TriggerUtility.byPassTrigger) return ;
    
    //Checking trigger switch value
    if(System.Label.TriggerSwitch.equals('On')){
        
        //Calling the helper method to update the owner on Lead conditionally
        if(trigger.isInsert && trigger.isBefore){
            LeadTriggerHelper.checkDuplicatePanNumber(trigger.New); // SAC-2804
            LeadTriggerHelper.validateGSTWithState(trigger.New);//1742
            LeadTriggerHelper.updateLeadDetails(trigger.new);//SAC-1457
            LeadTriggerHelper.recordTypeValue(trigger.new);//SAC-1457
            List<lead__c> lstLead = new List<lead__c>();    
            for(lead__c ld : trigger.new){
                if(ld.Assigned_to_Central_Desk__c == true){
                    lstLead.add(ld);
                }
            }
            if(!lstLead.isEmpty()){
                // implemented as part of SAC- 97
                LeadTriggerHelper.newLeadInsert(lstLead);
            }
         //   LeadTriggerHelper.assignToRemove(trigger.new,trigger.oldMap); //By Tarun Sachdeva
            
        }
        
        //Calling the helper method to update the owner on Lead conditionally on lead updation and also throwing the error on below conditions meet
        if(trigger.isUpdate && trigger.isBefore){
            Set<Id> ownerIds = new Set<Id>();
            LeadTriggerHelper.updateRetailLeadName(trigger.new,Trigger.oldMap);//SAC-1742
            LeadTriggerHelper.validateGSTWithState(Trigger.New);//1742
            LeadTriggerHelper.recordTypeValue(Trigger.New);//1742
            LeadTriggerHelper.updateleadAssigndate(Trigger.new, Trigger.oldMap); //SAC-1457
            LeadTriggerHelper.handleRecordTypeChange(Trigger.new, Trigger.oldMap);//SAC-1619
            List<lead__c> lstLead = new List<lead__c>();
            List<lead__c> gstNumberUpdates = new List<lead__c>();
            for (Lead__c ld : Trigger.new) {
                ownerIds.add(ld.OwnerId);
            }
            Map<Id, User> ownerMap = new Map<Id, User>([SELECT Id, ManagerId FROM User WHERE Id IN :ownerIds]);
            String profileId = UserInfo.getProfileId();
            User loggedInUserInfo = [SELECT Id, manager.profile.name,ManagerId FROM User WHERE Id =: UserInfo.getUserId()];
            Id retailLeadRecordTypeId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName().get('Retail_Lead').getRecordTypeId();
            List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Id =: profileId];
            String profileName = profileList[0].Name;
            List<String> profileNameList = new List<String>{'System Administrator','Read Only','New Sales Head Corporate','Central Corporate Team','Corporate salesforce team'};
            List<String> profileNameListForRetail = new List<String>{'System Administrator','Read Only','Corporate salesforce team'};
            for(lead__c ld: trigger.new){
                User ownerUser = ownerMap.get(ld.OwnerId);
                Boolean isManager = (ownerUser != null && ownerUser.ManagerId == loggedInUserInfo.Id);

                if(ld.Assigned_to_Central_Desk__c == true && ld.Approval_Status__c == 'Approved'){
                    ld.addError('Please remove the Assigned to Central Desk Checkbox if record has to be Approved');
                }
                
                else if(ld.Assigned_to_Central_Desk__c == true && trigger.oldmap.get(ld.Id).Assigned_to_Central_Desk__c == false && ld.Approval_Status__c != 'Approved'){
                    lstLead.add(ld);
                }
                if(ld.Status__c == 'Dropped' && trigger.oldmap.get(ld.Id).Status__c == ld.Status__c && ld.Approval_Status__c == 'Approved' && trigger.oldmap.get(ld.Id).Approval_Status__c == ld.Approval_Status__c ){
                    ld.addError('This Lead is Dropped only certain users can change the status to Active');
                }
                // SAC-2804 // Check for duplicate PAN in existing Accounts or Leads
                if(ld.GST_Number__c != null && ld.GST_Number__c != trigger.oldmap.get(ld.Id).GST_Number__c){
                    gstNumberUpdates.add(ld);
                }
                
                if(trigger.oldmap.get(ld.Id).Status__c != ld.Status__c && ld.Status__c != 'Active' && trigger.oldmap.get(ld.Id).Status__c == 'Dropped' && profileNameList.contains(profileName)) {
                    ld.addError('This Lead is Dropped only you can mark it as active');
                }
                if(trigger.oldmap.get(ld.Id).Status__c != ld.Status__c  && trigger.oldmap.get(ld.Id).Status__c == 'Dropped' && !profileNameList.contains(profileName) && ld.Approval_Status__c != 'Rejected') {
                    ld.addError('You do not have the permission to change the status of dropped lead');
                }
                if(trigger.oldmap.get(ld.Id).Status__c != ld.Status__c  && trigger.oldmap.get(ld.Id).Status__c == 'Dropped' && !profileNameListForRetail.contains(profileName) && ld.RecordTypeId == retailLeadRecordTypeId) {
                    ld.addError('You do not have the permission to change the status of dropped lead');
                }
                if(ld.Status__c == 'Active' && trigger.oldmap.get(ld.Id).Status__c == 'Dropped' && ld.Approval_Status__c == 'Approved' && profileNameList.contains(profileName)){
                    ld.Approval_Status__c = '';
                }
                if(trigger.oldmap.get(ld.Id).Status__c != ld.Status__c && trigger.oldmap.get(ld.Id).Status__c == 'Qualified' && !profileNameListForRetail.contains(profileName) && ld.RecordTypeId == retailLeadRecordTypeId && !isManager){
                    ld.addError('Qualified Retail Lead is locked.');
                }
                if(ld.Status__c == 'Qualified' && trigger.oldmap.get(ld.Id).Status__c == 'Qualified' && !profileNameListForRetail.contains(profileName) && ld.RecordTypeId == retailLeadRecordTypeId && !isManager){
                    ld.addError('Qualified Retail Lead is locked.');
                }
                /*if(Trigger.oldMap.get(ld.Id).RecordTypeId != ld.RecordTypeId && !profileNameListForRetail.contains(profileName) && ld.OwnerId != UserInfo.getUserId()){
                     ld.addError('You do not have permission to change the Lead record type.'); //New changes
                }*/
                 
            }
            // SAC-2804 // If there are GST number updates, check for duplicate PAN numbers
            if(!gstNumberUpdates.isEmpty()){
                LeadTriggerHelper.checkDuplicatePanNumber(gstNumberUpdates);
            }

            if(!lstLead.isEmpty()){
                LeadTriggerHelper.leadUpdateReassign(lstLead);
            }
            LeadTriggerHelper.updateApprovalStatus(trigger.new,trigger.oldMap); //By Tarun Sachdeva
            LeadTriggerHelper.assignToRemove(trigger.new,trigger.oldMap); //By Tarun Sachdeva
        }
        
        if(trigger.isUpdate && trigger.isAfter){
            // LeadTriggerHelper.updateRetailLeadName(trigger.new);//SAC-1742
            List<Lead__c> updateAreLeadToShare = new List<Lead__c>();
            List<lead__c> lstLead = new List<lead__c>();
            List<lead__c> lstAMLead = new List<lead__c>();
            List<lead__c> lstLeadShare = new List<lead__c>();
            List<lead__c> leadOwnerList = new List<lead__c>();
            List<lead__c> leadlst = new List<lead__c>();
            for(lead__c ld: trigger.new){
                if(ld.Automation__c == true){               
                    lstLead.add(ld);
                }
                if((ld.Source__c == 'Campaign' || ld.Source__c == 'Directory') && ld.Assigned_to_Central_Desk__c == true){
                    lstLeadShare.add(ld);
                }
                if(ld.Area__c != null){// Added for SD-541
                    lstAMLead.add(ld);
                }
                if(trigger.oldMap.get(ld.Id).OwnerId != ld.OwnerId && LeadTriggerHelper.isExecuted){
                    LeadTriggerHelper.isExecuted = false;
                    leadOwnerList.add(ld);
                }
                if(ld.Area__c != NULL && ld.Area__c != Trigger.oldMap.get(ld.Id).Area__c){
                    updateAreLeadToShare.add(ld);
                }
                
                
                
            }
            
            //Calling the method to make the Automation field false on lead if it is already true
            if(!lstLead.isEmpty()){
                LeadTriggerHelper.updateAutomationLead(lstLead);
            }
            
            //Calling the method to provide lead sharing to ysers
            if(!lstLeadShare.isEmpty()){
                LeadTriggerHelper.LeadSharing(lstLeadShare);
            }
            if(!lstAMLead.isEmpty()){// Added for SD-541
                //Manual sharing of lead coming from marketing source with the created owner.
                LeadTriggerHelper.AMLeadSharing(lstAMLead);
               
            }
            //Calling the method to send notification on owner change.
            if(leadOwnerList.size()>0){
               LeadTriggerHelper.changeOwnerLead(leadOwnerList);
            }
            // implemented as part of SAC- 97
            if(updateAreLeadToShare.size()>0){
                LeadTriggerHelper.updateLeadToShare(updateAreLeadToShare, Trigger.oldMap);
            }
              	LeadTriggerHelper.createTask(trigger.new);	//SAC-1619	                        
        }
        
        if(trigger.isInsert && trigger.isAfter){
             List<lead__c> areaLead = new List<lead__c>();
            List<lead__c> lstLead = new List<lead__c>();
            List<lead__c> lstAMLead = new List<lead__c>();
            for(lead__c ld : trigger.new){
                if((ld.Source__c == 'Campaign' || ld.Source__c == 'Directory') && ld.Assigned_to_Central_Desk__c == true){
                    lstLead.add(ld);
                }
                if(ld.Area__c != null){ // Added for SD-541
                    lstAMLead.add(ld);
                }
                if(ld.Area__c != NULL){
                    areaLead.add(ld);                    
                }
                                                
            }
            if(!lstLead.isEmpty()){
                //Manual sharing of lead coming from marketing source with the created owner.
                LeadTriggerHelper.LeadSharing(lstLead);
               
            }
             if(!lstAMLead.isEmpty()){// Added for SD-541
                //Manual sharing of lead coming from marketing source with the created owner.
                LeadTriggerHelper.AMLeadSharing(lstAMLead);               
            }
            if(!areaLead.isEmpty()){
                LeadTriggerHelper.leadShareInsert(areaLead);
            }
              LeadTriggerHelper.createTask(trigger.new);          
        }                
    }
}