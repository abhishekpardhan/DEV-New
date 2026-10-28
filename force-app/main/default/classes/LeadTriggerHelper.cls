public without sharing class LeadTriggerHelper {
    public static Boolean isExecuted = true;
    //Method to make the Automation field false on lead if it is already true
    public static void updateAutomationLead(List<Lead__c> lstLead){
        try{
            List<lead__c> lstLeadUpd = [select id,automation__c from lead__c where Id IN: lstLead];
            if(!lstLeadUpd.isEmpty()){
                for(Lead__c ld: lstLeadUpd){
                    ld.Automation__c = false;
                }
                update lstLeadUpd;
            }
            
        }catch(Exception e){
            system.debug('Exception:'+e.getLineNumber());
        }
    }
    
    //Method to insert the new lead with the Owners as Queues depending upon the Type__c value on lead
    public static void newLeadInsert(List<Lead__c> lstLead){
        try{
            Id centralCreditId = [select Id from Group where Type = 'Queue' and name = 'Lead Central Team (Credit)' limit 1].Id;            
            Id centralRetailId = [select Id from Group where Type = 'Queue' and name = 'Lead Central Team (Retail)' limit 1].Id;            
            Id central3PLId = [select Id from Group where Type = 'Queue' and name = 'Lead Central Team (3PL)' limit 1].Id;            
            for(lead__c ld : lstLead){
                if(ld.Type__c == 'Credit' || ld.Type__c == 'Transportation+3PL'){
                    ld.OwnerId = centralCreditId;
                }
                else if(ld.Type__c == 'Retail' || ld.RecordType.Name == 'Retail Lead'){
                    ld.OwnerId = centralRetailId;
                }
                else if(ld.Type__c == '3PL'){
                    ld.OwnerId = central3PLId;
                }
                else if(ld.Type__c == 'Prospective Oubound Customer for Retail' || ld.Type__c == 'Prospective Outbound Customer for Contract' || ld.Type__c == 'Prospective Customer for 3PL, Projects etc.' || ld.Type__c == 'Pickup Request' || ld.Type__c == 'Others' || ld.Type__c == 'Prospective Customer for  Inbound' || ld.Type__c == 'Service provider - Route Vehicle Vendor' || ld.Type__c == 'Service provider - Pickup / Delivery Associate' || ld.Type__c == 'Service provider - Products supplier' || ld.Type__c == 'Service provider - Contractual Job work ( Construction etc)' || ld.Type__c == 'Other service provider ( IT, HR, Security, Real Estate)' || ld.Type__c == 'Influencer for Business or PR ( eg Professor, Govt official )'  ){
                    ld.OwnerId = '0057F000004cZsQQAU';
                }
            }
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
    }
    
    //Method to update the Owners with Queues depending upon the Type__c value on lead and making Automation checkbox true
    public static void leadUpdateReassign(List<Lead__c> lstLead){
        try{
            Id centralCreditId = [select Id from Group where Type = 'Queue' and name = 'Lead Central Team (Credit)' limit 1].Id;
            Id centralRetailId = [select Id from Group where Type = 'Queue' and name = 'Lead Central Team (Retail)' limit 1].Id;
            Id central3PLId = [select Id from Group where Type = 'Queue' and name = 'Lead Central Team (3PL)' limit 1].Id;
            for(lead__c ld : lstLead){
                if(ld.Type__c == 'Credit' || ld.Type__c == 'Transportation+3PL'){
                    ld.OwnerId = centralCreditId;
                }
                else if(ld.Type__c == 'Retail' || ld.RecordType.Name == 'Retail Lead'){
                    ld.OwnerId = centralRetailId;
                }
                else if(ld.Type__c == '3PL'){
                    ld.OwnerId = central3PLId;
                }
                else if(ld.Type__c == 'Prospective Outbound Customer for Retail' || ld.Type__c == 'Prospective Outbound Customer for Contract' || ld.Type__c == 'Prospective Customer for 3PL, Projects etc.' || ld.Type__c == 'Pickup Request' || ld.Type__c == 'Others' || ld.Type__c == 'Prospective Customer for  Inbound' || ld.Type__c == 'Service provider - Route Vehicle Vendor' || ld.Type__c == 'Service provider - Pickup / Delivery Associate' || ld.Type__c == 'Service provider - Products supplier' || ld.Type__c == 'Service provider - Contractual Job work ( Construction etc)' || ld.Type__c == 'Other service provider ( IT, HR, Security, Real Estate)' || ld.Type__c == 'Influencer for Business or PR ( eg Professor, Govt official )'  ){
                    ld.OwnerId = '0057F000004cZsQQAU';
                }
                ld.Automation__c = true;
            }
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
    }
    //method to insert AMLeadSharing
    public static void AMLeadSharing(List<lead__c> lstAMLead){
        List<lead__share> lstLeadShare = new List<lead__share>();
        List<User> UserList = new List<User>();
        
        UserList = [Select id, name, Area__c,Profile.name from User 
                    where Profile.name ='Area Manager' and IsActive =true];   
        for(lead__c ld : lstAMLead){
            for(User U : UserList){
                
                if(ld.Area__c == U.Area__c && ld.OwnerId != U.id ){
                    // if( ){
                    lead__share ldShare = new lead__share();
                    ldShare.ParentId = ld.Id;
                    ldShare.AccessLevel = 'Read';
                    ldShare.UserOrGroupId = U.id;
                    lstLeadShare.add(ldShare);
                }
                //}
            }
        }
        insert lstLeadShare;
    }
    
    //method to insert leadSharing, who created the lead
    
    public static void LeadSharing(List<lead__c> lstLead){
        
        List<lead__share> lstLeadShare = new List<lead__share>();
        try{            
            for(lead__c ld : lstLead){
                lead__share ldShare = new lead__share();
                ldShare.ParentId = ld.Id;
                ldShare.AccessLevel = 'Read';
                ldShare.UserOrGroupId = ld.CreatedById;
                lstLeadShare.add(ldShare);
            }
            if(!lstLeadShare.isEmpty()){
                insert lstLeadShare;
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
        
    }
    
    //Method to send notification on lead owner change.
    public static void changeOwnerLead(List<Lead__c> lstLead){
        for(Lead__c ld : lstLead){
            //CustomNotificationType custype = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =:System.Label.Lead_Assigned_Name];
            String leadname = [SELECT Id, OwnerId, Name, Status__c FROM Lead__c Where Id =: ld.Id].Name;
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(System.Label.Lead_Assigned);   //set notification tittle
            notification.setBody('Lead "'+leadname+'" has been assigned to you. Please click to view the record.');
            notification.setTargetId(ld.OwnerId);   // target owner id
            notification.setNotificationTypeId(System.Label.Lead_Notification_Id);
            notification.setTargetId(ld.Id); // target object id
            notification.send(new Set<String>{ld.OwnerId});
        }
    }
    //SAC-97
    public static void leadShareInsert(List<Lead__c> lstlead){
        
        List<String> leadAreas = new List<String>();
        Map<String, list<Id>> AreaToUserMap = new Map<String, list<Id>>();        
        for(lead__c ld : lstlead){
            leadAreas.add(ld.Area__c);
        }        
        for(User usr : [Select id, Area__c from User where Designation__c = 'Area Manager' AND isActive = True AND 
                        Area__c IN : leadAreas]){
                            if(!AreaToUserMap.containskey(usr.Area__c)){                                
                                AreaToUserMap.put(usr.Area__c, new List<Id>());
                            }else{
                                AreaToUserMap.get(usr.Area__c).add(usr.Id);
                            }
                        }
        List<Lead__Share> ledShareList = new List<Lead__Share>();
        for(Lead__c led : lstlead){
            if(AreaToUserMap.containsKey(led.Area__c)){
                List<Id> areUsers = AreaToUserMap.get(led.Area__c);
                List<Lead__Share>  ledShare = createLeadShareUtility.createLeadShare(areUsers, led.Id);
                ledShareList.addall(ledShare);
            }
        }
        Database.SaveResult[] srList = Database.insert(ledShareList, false);
        
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted lead share records. Lead share IDs: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
        
    }
    //SAC-97
    
    public static void updateLeadToShare(List<Lead__c> ledList, Map<Id, Lead__c> oldLed){
        
        // insert all records
        leadShareInsert(ledList);
        
        // retreive old share records
        
        List<String> leadAreas = new List<String>();
        List<String> userIds = new List<String>();
        List<Lead__Share> deleteLeadShare = new List<Lead__Share>();
        Map<String, String> ledAresMap = new Map<String, String>();
        Map<String, String> usrAresMap = new Map<String, String>();
        
        for (Lead__c led : ledList) {
            leadAreas.add(oldLed.get(led.Id).Area__c); 
            ledAresMap.put(led.Id, oldLed.get(led.Id).Area__c);
        }
        
        for (User user : [SELECT Id, Area__c FROM User WHERE Designation__c = 'Area Manager' AND Area__c IN :leadAreas]) {
            userIds.add(user.Id);
            usrAresMap.put(user.Id,user.Area__c);                 
        }
        
        List<Lead__Share> existingLeadShare = [Select Id, ParentId,UserOrGroupId From Lead__Share 
                                               Where ParentId IN :ledList AND 
                                               UserOrGroupId IN : userIds ] ;
        
        for(Lead__Share ledShare: existingLeadShare){
            String usrId = ledShare.UserOrGroupId;
            String ledId = ledShare.ParentId;
            
            String leadOldArea;
            if(ledAresMap.containsKey(ledId)){
                leadOldArea = ledAresMap.get(ledId);
            }
            String usrOldArea;
            if(usrAresMap.containsKey(usrId)){
                usrOldArea = usrAresMap.get(usrId);
            }              
            
            if(leadOldArea == usrOldArea){
                deleteLeadShare.add(ledShare);
            }
        }
        
        if(deleteLeadShare.size()>0){
            
            Database.DeleteResult[] srList = Database.delete(deleteLeadShare, false);
            
            for (Database.DeleteResult sr : srList){
                if (sr.isSuccess()){
                    System.debug('Successfully deleted lead share records. Lead share IDs: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
        
    }
    // Converting the process builder 'Lead Approval status change to Rejected' to trigger - By Tarun Sachdeva
    // SAC - 1363
    public static void updateApprovalStatus(List<Lead__c> lstlead,Map<Id,Lead__c> oldleadValues){
        Boolean approvalCheck = true ;
        Map<String,Id> mapOfQueId = new Map<String,Id>();
        List<Group> queueLst = [SELECT Id,Name,DeveloperName FROM Group WHERE Type = 'Queue' And Name Like 'Lead Central%'];
        for(Group g : queueLst){
            mapOfQueId.put(g.DeveloperName,g.id);
        }
        for(Lead__c newled : lstLead){
            if(oldleadValues.get(newled.Id).Approval_Status__c != newled.Approval_Status__c){
                if(newled.Approval_Status__c == ConstantUtility.Rejected && newled.Assigned_to_Central_Desk__c == true){
                    if(newled.Type__c == ConstantUtility.Credit || newled.Type__c == ConstantUtility.Lead_Type_Trans_3PL){
                        newled.Approval_Status__c = ConstantUtility.Approval_Status_Central_Team;
                        newled.OwnerId = mapOfQueId.get(ConstantUtility.Lead_Queue_Credit);
                    }
                    else if(newled.Type__c == ConstantUtility.Lead_Type_Retail || newled.RecordType.Name == 'Retail Lead'){
                        newled.Approval_Status__c = ConstantUtility.Approval_Status_Central_Team;
                        newled.OwnerId = mapOfQueId.get(ConstantUtility.Lead_Queue_Retail);
                    }
                    else if(newled.Type__c == ConstantUtility.Lead_Type_3PL){
                        newled.Approval_Status__c = ConstantUtility.Approval_Status_Central_Team;
                        newled.OwnerId = mapOfQueId.get(ConstantUtility.Lead_Queue_3PL);
                    }
                }
                else if(newled.Assigned_to_Central_Desk__c == false){
                    newled.Approval_Status__c = ConstantUtility.Approval_Status_Central_Team_BDM;
                }
                
            }
        }
    } 
    // Converting the process builder 'lead assign to remove' to trigger - By Tarun Sachdeva 
    // SAC - 1363  
    public static void assignToRemove(List<Lead__c> lstlead,Map<Id,Lead__c> oldleadValues){
        Boolean ownCheck =true;
        for(Lead__c newled : lstLead){
            if(oldleadValues != null && oldleadValues.get(newled.Id).OwnerId == newled.OwnerId){
                ownCheck = false;
            }
            if(ownCheck){
                if(String.valueOf(newled.OwnerId).startsWith('005') && newled.Assigned_to_Central_Desk__c == true){
                    newled.Assigned_to_Central_Desk__c = false;
                }                
            }
        }  
    }

    public static void recordTypeValue(List<Lead__c> lstLead){
        Map<Id, Schema.RecordTypeInfo> rtMap =  Schema.SObjectType.Lead__c.getRecordTypeInfosById();
        for(Lead__c newled : lstLead){

            if(newled.RecordTypeId != null && rtMap.containsKey(newled.RecordTypeId)){

                String recordTypeName = rtMap.get(newled.RecordTypeId).getName();

                if(recordTypeName != newled.Record_Type_Name_2__c){
            newled.Record_Type_Name_2__c = recordTypeName;
        }  
    }
        }
    }
    
    // Converting the process builder 'lead assign to remove' to trigger - By Tarun Sachdeva 
    // SAC - 1363  
    public static void createTask(List<Lead__c> lstlead){
        Id creditLeadRecordTypeId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName().get('Credit_Lead').getRecordTypeId();
        List<Task> lstOfTsks = new List<Task>();
        Set<Id> leadIdsToCheck = new Set<Id>();
        for(Lead__c newled : lstLead){
            if(String.valueOf(newled.OwnerId).startsWith('005') && newled.RecordTypeId == creditLeadRecordTypeId && newled.Assigned_to_Central_Desk__c == false && newled.Status__c != ConstantUtility.Dropped){
                leadIdsToCheck.add(newled.Id);
            }
        }
        //Added by Manshi| SAC-1619
        // Fetch any existing 'Customer Profiling' task (ever created) for those leads
        Map<Id, Task> existingTaskMap = new Map<Id, Task>();
        if (!leadIdsToCheck.isEmpty()) { 
            for (Task t : [SELECT Id, WhatId FROM Task WHERE WhatId IN :leadIdsToCheck]){
                existingTaskMap.put(t.WhatId, t);
            }
        } 
        // Create task only if it doesn't already exist for the Lead
        for (Lead__c leadRec : lstLead) {
            if (leadIdsToCheck.contains(leadRec.Id) && !existingTaskMap.containsKey(leadRec.Id)) {
                Task newTsk = new Task();
                newTsk.Priority = 'High';
                newTsk.Status = 'Open';
                newTsk.Subject = 'Customer Profiling';
                newTsk.Type = 'CUSTOMER VISIT';
                newTsk.ActivityDate = Date.today().addDays(7);
                newTsk.OwnerId = leadRec.OwnerId;
                newTsk.WhatId = leadRec.Id;
                lstOfTsks.add(newTsk);
            }
        }
        
        if (!lstOfTsks.isEmpty()) {
            insert lstOfTsks;
        }
    }   
    
    /*Description: Converting workflow rule 
* author : Tarun Sachdeva
* SAC-1457
*/
    public static void updateLeadDetails(List<Lead__c> listLead){
        for(Lead__c lead : listLead){
            if(lead.Name != null){
                lead.Name =  lead.Name.toUpperCase();
            }
            lead.Assignment_Date__c = System.now();
        }
        
    }
    
    /*Description: Converting workflow rule 
* author : Tarun Sachdeva
* SAC-1457
*/
    public static void updateleadAssigndate(List<Lead__c> listLead, Map<Id,Lead__c> oldMap){
        for(Lead__c lead : listLead){
            if(oldMap.get(lead.Id).OwnerId != lead.OwnerId){
                lead.Assignment_Date__c = System.now();
            }
        }
        
    }
    
    /*Description: update lead status when change recordtype 
* author : Manshi Joshi
* SAC-1619
*/
    public static void handleRecordTypeChange(List<Lead__c> newLeads, Map<Id, Lead__c> oldLeadMap) {
        try{
            Id retailLeadRecordTypeId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName().get('Retail_Lead').getRecordTypeId();
            Id creditLeadRecordTypeId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName().get('Credit_Lead').getRecordTypeId();
            Set<Id> leadIds = new Set<Id>();
            for (Lead__c newLead : newLeads) {
                leadIds.add(newLead.Id);  
            }
            for (Lead__c newLead : newLeads) {
                if (!leadIds.contains(newLead.Id)) continue;
                Lead__c oldLead = oldLeadMap.get(newLead.Id);
                if (oldLead.RecordTypeId != newLead.RecordTypeId) {
                    Boolean isRetailToCredit = oldLead.RecordTypeId == retailLeadRecordTypeId && newLead.RecordTypeId == creditLeadRecordTypeId;
                    Boolean isCreditToRetail = oldLead.RecordTypeId == creditLeadRecordTypeId && newLead.RecordTypeId == retailLeadRecordTypeId; 
                    if (isRetailToCredit || isCreditToRetail) {
                        newLead.Status__c = 'Active'; 
                    }
                }  
            }
        }catch (Exception exp) {
            LoggerUtil.createErrorLog('LeadTriggerHelper', 'handleRecordTypeChange', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        } 
    } 
    
    /*Description: check GST number with statecode
* author : Manshi Joshi
* SAC-1742
*/ 
    public static void validateGSTWithState(List<Lead__c> leadlst){
        List<State_GST_Code__mdt> stateGstCodeList = [SELECT MasterLabel, State_GST_Code__c FROM State_GST_Code__mdt];
        Map<String, String> stateNameCodeMap = new Map<String, String>();
        for(State_GST_Code__mdt code : stateGstCodeList){
            stateNameCodeMap.put(code.MasterLabel, code.State_GST_Code__c);       
        }
        for (Lead__c leadRec : leadlst) {
            String gstStateCode = stateNameCodeMap.get(leadRec.State__c);
            if(!String.isBlank(leadRec.GST_Number__c)){
                String enteredCode = leadRec.GST_Number__c.length() >= 2 ? leadRec.GST_Number__c.substring(0, 2): '';
                if (!String.isBlank(leadRec.GST_Number__c) && !String.isBlank(leadRec.State__c)) {   
                    if (String.isNotBlank(gstStateCode) && enteredCode != gstStateCode) {
                        leadRec.addError('GST Number does not match the selected State.');
                    }
                }else if(String.isBlank(leadRec.State__c) && !String.isBlank(leadRec.GST_Number__c)){
                    leadRec.addError('Please select the State.');
                }
            }
        }
        
    }
    
    /*Description: update leadname for retail lead based on GSTcheck
* author : Manshi Joshi
* SAC-1742
*/
    public static void updateRetailLeadName(List<Lead__c> newLeads, Map<Id,Lead__c> oldMap){
        try{
            Id retailLeadRecordTypeId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName().get('Retail_Lead').getRecordTypeId();
            Set<Id> leadIdsToProcess = new Set<Id>();
            String leadId;
            String leadOldStatus;
            for (Lead__c ld : newLeads) {
                leadId = ld.Id;
                leadOldStatus = oldMap.get(ld.Id).Status__c;
                if ( (oldMap.get(ld.Id).Name != ld.Name || oldMap.get(ld.Id).GST_Number__c != ld.GST_Number__c || (oldMap.get(ld.Id).Status__c != 'Qualified' && ld.Status__c == 'Qualified')) && ld.Status__c == 'Qualified' && ld.RecordTypeId == retailLeadRecordTypeId) { 
                    if (ld.GST_Exempted__c == false && ld.GST_Number__c != null && ld.GST_Number__c.length() >= 12) {
                        processGSTValidationAsync(leadId,leadOldStatus);
                    }
                    else if(ld.GST_Number__c.length() < 12){
                        ld.addError('Invalid GST Number. Please ensure it is at least 12 characters long.');
                    }
                }
            }  
        }
        catch (Exception exp) {
            System.debug(' Exception Message ::' + exp.getMessage() + ' Class Name : LeadTriggerHelper at Line ::' + exp.getLineNumber());
            LoggerUtil.createErrorLog('LeadTriggerHelper', 'updateRetailLeadName', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        } 
    }

    @future(callout=true)
    public static void processGSTValidationAsync(String leadIds,String leadOldStatus) {
        try{
            String customerName ='';
            Lead__c ld = [select Id,name,Email__c, RecordTypeId, Contact_Person_Name__c ,Salutation__c,Mobile_No__c , 
                          Area__c,Region__c ,Phone__c,State__c,Street__c,City__c,Rating__c,
                          Status__c,Type__c,Account_Type__c, GST_Number__c, GST_Exempted__c
                          from lead__c where id=:leadIds limit 1];
            if(ld.GST_Exempted__c == false) {
                GstResponseWrapper validateGST = validateGSTNumber(ld);
                if(validateGST.data != null && validateGST.isValid) {
                    if(validateGST.data.LegalName.length()>=80){
                        if(validateGST.data.TradeName.length() >= 80){
                            customerName = validateGST.data.LegalName.substring(0, 80);
                        }else{
                            customerName = validateGST.data.TradeName;
                        }
                    }
                    else{
                        customerName = validateGST.data.LegalName;
                    }
                }
                String gstPANnumber = ld.GST_Number__c.substring(2, 12);
                // Check for duplicate PAN number in lead and account
                Map<String, String> duplicatePanMap = getDuplicatePANMap(new List<Lead__c>{ld});
                if(ld.Status__c == 'Qualified' && String.isNotBlank(ld.GST_Number__c)){
                    // If a duplicate PAN is found and the user is not an admin or part of the corporate Salesforce team or Read only, block conversion
                    if((customerName != '' && (!duplicatePanMap.containsKey(gstPANnumber) || ConstantUtility.isAdminCorporateSalesforceTeamOrReadOnly(UserInfo.getProfileId())))){
                        ld.Name = customerName;
                    } else if(leadOldStatus != ld.Status__c){
                        ld.Status__c = leadOldStatus;
                    }
                }
                if((!duplicatePanMap.isEmpty()) && !ConstantUtility.isAdminCorporateSalesforceTeamOrReadOnly(UserInfo.getProfileId())){
                    validateGST.evt.ErrorMessage__c = 'Duplicate PAN number found in ' + duplicatePanMap.get(gstPANnumber);
                }
                Database.SaveResult sr = EventBus.publish(validateGST.evt);
                TriggerUtility.byPassTrigger = true;
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.AllowSave = true;
                Database.SaveResult srUpdate = Database.update(ld, dml); 
                TriggerUtility.byPassTrigger = false;
            }
        } catch (Exception exp) {
            System.debug(' Exception Message ::' + exp.getMessage() + ' Class Name : LeadTriggerHelper at Line ::' + exp.getLineNumber());
            LoggerUtil.createErrorLog('LeadTriggerHelper', 'processGSTValidationAsync', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        } 
    }

    //Method added by abhishek to check duplicate PAN number in lead and account
    public static void checkDuplicatePanNumber(List<Lead__c> leadList){
        Set<String> panNumbers = new Set<String>();
        Set<String> gstNumbers = new Set<String>();
        
        if(ConstantUtility.isAdminCorporateSalesforceTeamOrReadOnly(UserInfo.getProfileId())){
            return;
        }

        try {

            Map<String, String> duplicatePanMap = getDuplicatePANMap(leadList);
            if(!duplicatePanMap.isEmpty()){
                for(Lead__c lead : leadList){
                    if(lead.GST_Number__c != null && lead.GST_Number__c.length() >= 12){
                        String panNumber = lead.GST_Number__c.substring(2, 12);
                        if(duplicatePanMap.containsKey(panNumber)){
                            lead.addError('Duplicate PAN number found in ' + duplicatePanMap.get(panNumber));
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception in checkDuplicatePanNumber: ' + e.getMessage());
            LoggerUtil.createErrorLog('LeadTriggerHelper', 'checkDuplicatePanNumber', e.getTypeName(), e.getMessage(), e.getStackTraceString(), null);
        }
    }

    // added by abhishek pardhan SAC-2804
    //Method to get duplicate PAN number in lead and account
    public static Map<String, String> getDuplicatePANMap(List<Lead__c> leadList) {

        Map<String, String> duplicatePanMap = new Map<String, String>();

        if (leadList == null || leadList.isEmpty()) {
            return duplicatePanMap;
        }

        Set<String> creditPANs = new Set<String>();
        Set<String> creditGSTs = new Set<String>();
        Set<String> retailGSTs = new Set<String>();
        Set<Id> leadIds = new Set<Id>();

        Id creditLeadRTId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
            .get('Credit_Lead').getRecordTypeId();

        Id retailLeadRTId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
            .get('Retail_Lead').getRecordTypeId();

        Id convertedLeadRTId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
            .get('Converted_Lead_Recordtype').getRecordTypeId();

        for (Lead__c ld : leadList) {

            if (ld.Id != null) {
                leadIds.add(ld.Id);
            }

            if (String.isBlank(ld.GST_Number__c) || ld.GST_Number__c.length() < 12) {
                continue;
            }

            String pan = ld.GST_Number__c.substring(2, 12);

            if (ld.RecordTypeId == creditLeadRTId) {
                creditGSTs.add(ld.GST_Number__c);
                creditPANs.add(pan);
            }
            else if (ld.RecordTypeId == retailLeadRTId) {
                retailGSTs.add(ld.GST_Number__c);
            }
        }
        // Duplicate Credit Leads
        if (!creditGSTs.isEmpty()) {

            for (Lead__c dupLead : [
                SELECT Id, Name, GST_Number__c
                FROM Lead__c
                WHERE GST_Number__c IN :creditGSTs
                AND (RecordTypeId = :creditLeadRTId OR RecordTypeId = :convertedLeadRTId)
                AND Id NOT IN :leadIds
            ]) {
                duplicatePanMap.put(
                    dupLead.GST_Number__c.substring(2, 12),
                    'Lead: ' + dupLead.Name
                );
            }
        }

        // Duplicate Retail Leads
        if (!retailGSTs.isEmpty()) {

            for (Lead__c dupLead : [
                SELECT Id, Name, GST_Number__c
                FROM Lead__c
                WHERE GST_Number__c IN :retailGSTs
                AND RecordTypeId = :retailLeadRTId
                AND Id NOT IN :leadIds
            ]) {
                duplicatePanMap.put(
                    dupLead.GST_Number__c.substring(2, 12),
                    'Lead: ' + dupLead.Name
                );
            }
        }

        // Credit Leads are also checked against Accounts
        if (!creditPANs.isEmpty()) {

            for (Account acc : [
                SELECT Id, Name, Pan_No__c
                FROM Account
                WHERE Pan_No__c IN :creditPANs
                AND (RecordType.Name = 'Prospect Customer'
                    OR RecordType.Name = 'SFX')
            ]) {
                duplicatePanMap.put(
                    acc.Pan_No__c,
                    'Account: ' + acc.Name
                );
            }
        }

        return duplicatePanMap;
    }

    public static GstResponseWrapper validateGSTNumber(Lead__c led){
        GstResponseWrapper wrapper;
        String gstNumber = '';
        String endPoint = System.Label.GST_Validation_End_Point;
        endPoint += '/'+led.GST_Number__c;
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endPoint);
        httpReq.setMethod('GET');
        httpReq.setHeader('Content-Type','application/json');         
        httpReq.setHeader('Authorization', 'Basic '+System.Label.GST_Validation_Key);         
        httpReq.setTimeout(60000); 
        Http htp = new Http();
        HttpResponse response = new HttpResponse();
        response = htp.send(httpReq);
        GST_Validation_Event__e evt = new GST_Validation_Event__e(LeadId__c = led.Id);
        if(response.getStatusCode() == 200){
            wrapper = (GstResponseWrapper)JSON.deserialize(response.getBody(), GstResponseWrapper.class);
            if(wrapper.data != null && wrapper.data.Gstin != null) {
                wrapper.isValid = true;
                if (led.GST_Exempted__c == false) {
                    if (led.GST_Number__c != null && led.GST_Number__c.length() >= 12) {
                        gstNumber = led.GST_Number__c; 
                        evt.LeadName__c = led.Name;
                        evt.SuccessMessage__c = 'Valid GST';
                        evt.GstResponseMsg__c = wrapper.data.LegalName;   
                    } 
                }
            } else if(wrapper.data == null) {
                wrapper.isValid = false;
                evt.ErrorMessage__c = 'Invalid GST';    
            }
            else if(wrapper.data != null && wrapper.data.Gstin == null){
                wrapper.isValid = false;
                evt.ErrorMessage__c = 'There is some issue to validate the GST. Please try again.';  
            }
        }
        else{
            evt.ErrorMessage__c = 'There is some issue to validate the GST. Please try again.';
            wrapper = new GstResponseWrapper();
            wrapper.isValid = false;
        }
        wrapper.evt = evt;
        return wrapper; 
    }
    
    // GST number wrapper class
    public class GstResponseWrapper{
        public GstResponseDataWrapper data;
        public boolean isValid;
        public GST_Validation_Event__e evt;
    }
    
    // GST number wrapper class
    public class GstResponseDataWrapper{
        public String Gstin;
        public String LegalName;
        public String TradeName;
    }
    
    // GST response wrapper class
    public class GstResponse{
        @AuraEnabled public String message;
        @AuraEnabled public boolean error;
        @AuraEnabled public String leadName;
        @AuraEnabled public String customerName;
        @AuraEnabled public boolean nameMissmatch;
        public GstResponse(String message, boolean error){
            this.message = message;
            this.error = error;
        }
        public GstResponse(String message, boolean error,String leadName, String customerName, boolean nameMissmatch){
            this.message = message;
            this.error = error;
            this.leadName = leadName;
            this.customerName = customerName;
            this.nameMissmatch = nameMissmatch;
        }
    }
    
    
    
}