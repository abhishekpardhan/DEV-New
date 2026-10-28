/**
* Description      :   Trigger on ContentDocumentLink object to perform various tasks upon different DML
*                      Operations by calling helper class methods
* JIRA ticket       :    https://safexpress.atlassian.net/browse/SD-453
* Last Modified By  :       Shubham Girdhar
* Last Modified Date:       06/01/2020
* Revision Logs    :   V_1.0 - Created
* 
**/
trigger trg_ContentDocumentLink on ContentDocumentLink (after insert,before insert, before delete, after delete) {
    
    //Checking trigger switch values
    if(System.Label.TriggerSwitch.equals('On')){
        Id currentUser = UserInfo.getUserRoleId();
        List<userrole> userroles = [select id,name from userrole where id =: currentUser limit 1];
        String RoleName;
        if(!userroles.isEmpty()) {
            RoleName = userroles[0].name;
        }
        if(trigger.isInsert && trigger.isAfter){
            List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();
            List<ContentDocumentLink> lstCDLTask = new List<ContentDocumentLink>();
            List<Id> lstId = new List<Id>();
            List<Id> lstLinkedId = new List<Id>();
            List<Id> lstLinkedIdTask = new List<Id>();
            List<Id> ListParentId = new List<Id>();  // By Shubham
            Set<Id> Caselist = new Set<Id>();
            List<Contract__c> contractToUpdateList = new List<Contract__c>();
            try{
                
                //Doing further processing only if file is getting created under 'Quote__c' or 'Task' object
                for(ContentDocumentLink cdl : trigger.new){
                    if(cdl.linkedentityid != null){
                        
                        String sObjName = cdl.linkedentityid.getSObjectType().getDescribe().getName();                    
                        if(sObjName.equals('Quote__c')){
                            lstCDL.add(cdl);
                            lstId.add(cdl.Id);
                            lstLinkedId.add(cdl.LinkedEntityId);
                        }
                        
                        else if(sObjName.equals('Task')){
                            lstCDLTask.add(cdl);
                            lstLinkedIdTask.add(cdl.LinkedEntityId);
                        }
                        else if(sObjName.equals('Contact')){      // By Shubham
                            ListParentId.add(cdl.linkedentityid);
                            System.debug('Its a Contact'+cdl.LinkedEntityId);
                        } else if(sObjName.equals('Contract__c')){      // By KR SANSI
                            Contract__c contract = new Contract__c(Id = cdl.LinkedEntityId, Is_Valid__c = True);
                            contractToUpdateList.add(contract);
                        }
                        else if(sObjName.equals('Case__c')){
                            Caselist.add(cdl.linkedentityid);
                        }
                    }
                }
                
                //method to check if file is inserted on case__c
                //Method to check if file is inserted on quote by bdm.
                
                if(!Caselist.isEmpty()){
                    CDLTriggerHelper.newInsertFileCase(Caselist);
                }
                if(!lstCDL.isEmpty()){
                    CDLTriggerHelper.newInsert(lstCDL,lstId,lstLinkedId);
                }
                //Method to check if file is inserted on collection task by bdm.
                if(!lstCDLTask.isEmpty()){
                    CDLTriggerHelper.newInsertFileTask(lstCDLTask,lstLinkedIdTask);
                }
                if(!ListParentId.isEmpty()){
                    CDLTriggerHelper.ContactFileCopyToLead(ListParentId);
                }
                if(!contractToUpdateList.isEmpty()){
                    CDLTriggerHelper.updateContractIsValid(contractToUpdateList);
                }
            }catch(Exception e){
                system.debug('Exception:'+e.getMessage());
            }
        }
        
        //Doing further processing only if file is getting created under 'Quote__c' object
        if(trigger.isBefore && trigger.isInsert){
             Trg_ContentDocumentLinkHandler.handleBeforeInsert(Trigger.new);
            /*List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();        
List<Id> lstId = new List<Id>();
List<Id> lstLinkedId = new List<Id>();        
for(ContentDocumentLink cdl : trigger.new){
if(cdl.linkedentityid != null){
String sObjName = cdl.linkedentityid.getSObjectType().getDescribe().getName();                    
if(sObjName.equals('Quote__c')){
lstCDL.add(cdl);
lstId.add(cdl.Id);
lstLinkedId.add(cdl.LinkedEntityId);
}
}
}
//Method to upload file by central team only.
if(!lstCDL.isEmpty()){
CDLTriggerHelper.QuotePDFFileInsert(lstCDL,lstId,lstLinkedId);
}*/
            System.debug('trg_ContentDocument');
            List<Id> CDid = new List<Id>();
            Id SAProfileId = [select id from profile where name = 'System Administrator' limit 1].Id;
            Id IUProfileId = [select id from profile where name = 'Integration User' limit 1].Id;
            Id Profile1 = userinfo.getProfileId();
            List<String> sObjNames = new List<String>();
            Set<Id> caseId  = new Set<Id> ();
            Set<Id> claimcaseId = new Set<Id>();
            map<Id,case__c> casemap = new map<Id,Case__c>();
            List<String> recordid = new List<String>();
          
            for(ContentDocumentLink con : Trigger.new){ 
                System.debug('Line @114-> '+con.linkedentityid);
                CDid.add(con.Id);
                if(con.linkedentityid != null){
                   
                    if(con.linkedentityid.getSObjectType().getDescribe().getName() == 'Case__c'){
                       
                        caseId.add(con.linkedentityid);
                        sObjNames.add(con.linkedentityid.getSObjectType().getDescribe().getName()); 
                        system.debug('case Id Line No 122'+caseId);
                    }
                    else{
                        
                        String objectname = con.linkedentityid.getSObjectType().getDescribe().getName(); 
                        System.debug('objectname @ Line->156'+ objectname);
                         
                        if(objectname != 'User' || objectname != 'Contract__c'){
                            sObjNames.add(con.linkedentityid.getSObjectType().getDescribe().getName());
                            recordid.add(con.linkedentityid);
                        }
                        
                    }
                    
                }  
            }
             
            if(caseId!=null){
                 
                  List<Case__c> caselist = [Select Id, recordType.developerName,Status__c,Approval_Status__c from Case__c  where Id IN :caseId];
           		  for(Case__c cs:caselist){
                system.debug('case Id Line No 142'+ cs);
                  if(cs.recordType.developerName!='Claim_Issues'){
                     system.debug('case Id Line No 144');
                    recordid.add(cs.Id);
                    caseId.remove(cs.Id);
                   }
                else{
                     system.debug('case Id Line No 149');
                    recordid.add(cs.Id);
                    casemap.put(cs.Id,cs);
                }
                 system.debug('case Id Line No 153'+caseId);
            }
		}
          
            String idListString = '\'' + String.join(recordid, '\', \'') + '\'';
            
            System.debug(' @@ idListString -> '+ idListString);
            List<String> fieldApiNames = new List<String>();
            Boolean isPresent = sObjNames.contains('Case__c');
            List<ContentDocumentDeletion__mdt> ccdList = [SELECT Id,FieldApiName__c,ObjectName__c,Operator__c,SkipPermissions__c,SkipRoles__c,Values__c FROM ContentDocumentDeletion__mdt where ObjectName__c IN: sObjNames];
            for(ContentDocumentDeletion__mdt ccd : ccdList) {
                System.debug(' @@ ccd.FieldApiName__c -> '+ ccd.FieldApiName__c);
                fieldApiNames.add(ccd.FieldApiName__c);
            }
            List<sObject> sobjList = new List<sObject>();
            if(!ccdList.isEmpty()) {
                string query = 'Select '+ String.join(fieldApiNames, ', ') + ' from ' + ccdList[0].ObjectName__c + ' where Id IN (' + idListString + ')';
                System.debug('############################'+query);
                sobjList = Database.query(query);
                
            }
            System.debug('Trigger.new--->'+Trigger.new);
            if(!sobjList.isEmpty() || !caseId.IsEmpty()) {
                for(ContentDocumentLink actualRecord : Trigger.new) {       
                     system.debug('case Id Line No 177'+actualRecord);
                     system.debug('case Id Line No 178'+caseId);
                    if(caseId.contains(actualRecord.linkedentityid)){
                       Boolean hasAccess =FeatureManagement.checkPermission('Claim_user_permission_set');
                        case__c Currentcaserecord = casemap.get(actualRecord.linkedentityid);
                         system.debug('i am here hello '+Currentcaserecord);
                            if((!hasAccess || Currentcaserecord.Status__c == 'Completed') && Currentcaserecord.Approval_Status__c !='Not Submitted for Approval'){
                                system.debug('case Id Line No 184');
                            actualRecord.addError('You cannot insert this file @@1');
                        }
                    }
                  else{
                     String objname = actualRecord.linkedentityid.getSObjectType().getDescribe().getName();
                     if(objname != 'User'){

                         system.debug('actualRecord-->'+actualRecord);
                        system.debug('i am here hello in else '+ccdList);
                        String field = '';
                        List<String> lstValues = new List<String>();
                        List<Boolean> fieldValues = new List<Boolean>();
                        for(ContentDocumentDeletion__mdt ccd : ccdList) {
                            field = String.valueOf(sobjList[0].get(ccd.FieldApiName__c));
                           
                            lstValues = ccd.Values__c != null ? ccd.Values__c.split(',') : null;
                           
                            if(lstValues != null) {
                                fieldValues.add(lstValues.contains(field));
                                system.debug('fieldValues'+fieldValues);
                               
                            }
                            System.debug(fieldValues);
                        }
                        String operator = ccdList[0].Operator__c;
                        List<String> customPermissions = ccdList[0].SkipPermissions__c != null ? ccdList[0].SkipPermissions__c.split(',') : null;
                        List<String> lstRoles = ccdList[0].SkipRoles__c != null ? ccdList[0].SkipRoles__c.split(',') : null;
                        List<Boolean> customPermissionValues = new List<Boolean>();
                        if (customPermissions != null) {
                            for(String customPermission : customPermissions) {
                                if(customPermission != null) {
                                    customPermissionValues.add(FeatureManagement.checkPermission(customPermission));
                                }
                            }
                        }
                        System.debug(customPermissionValues);
                        if(operator == '1') {
                            if((!fieldValues.isEmpty() && !fieldValues.contains(false)) && (lstRoles == null || !lstRoles.contains(RoleName)) && (customPermissionValues.isEmpty() || !customPermissionValues.contains(true))) {
                                if(actualRecord != Null) {
                                    System.debug(' @@ operator' + operator);
                                    //actualRecord.addError('You cannot insert this file @@2');
                                }
                            }
                        }
                        else {
                            if(fieldValues.contains(true) && (lstRoles == null || !lstRoles.contains(RoleName)) && (customPermissionValues.isEmpty() || !customPermissionValues.contains(true))) {
                                if(actualRecord != Null) {
                                    System.debug(' @@else operator' + operator);
                                    System.debug(' @@else fieldValues' + fieldValues);
                                    System.debug(' @@else fieldValues.contains(true)' + fieldValues.contains(true));
                                    System.debug(' @@else lstRoles' + lstRoles);
                                    System.debug(' @@else RoleName' + RoleName);
                                    System.debug(' @@else customPermissionValues.isEmpty()' + customPermissionValues.isEmpty());
                                    System.debug(' @@else !customPermissionValues.contains(true)' + !customPermissionValues.contains(true));
                                    System.debug(' @@else actualRecord' + actualRecord);
                                    actualRecord.addError('You cannot insert this file @@3');
                                }
                            }
                        }
                     }
                       
                    }
                    
                    
                    
                }
            }
            
        }
        
        
        //   Trigger to ristrict user to remove file from record
        if(trigger.isBefore && trigger.isDelete){
            List<Id> CDid = new List<Id>();
            Id SAProfileId = [select id from profile where name = 'System Administrator' limit 1].Id;
            Id IUProfileId = [select id from profile where name = 'Integration User' limit 1].Id;
            Id Profile1 = userinfo.getProfileId();
            List<String> sObjNames = new List<String>();
            List<String> recordid = new List<String>();
            for(ContentDocumentLink con : Trigger.old){
                System.debug(Trigger.old);
                System.debug(' ContentDocumentLink trigger !!!!!!!!!!!!!!!!!!!!!!!!!!!!'+con.Id);
                CDid.add(con.Id);
                if(con.linkedentityid != null){
                    sObjNames.add(con.linkedentityid.getSObjectType().getDescribe().getName());   
                    recordid.add(con.linkedentityid);
                }  
            }
            
            String idListString = '\'' + String.join(recordid, '\', \'') + '\'';
            List<String> fieldApiNames = new List<String>();
            List<ContentDocumentDeletion__mdt> ccdList = [SELECT Id,FieldApiName__c,ObjectName__c,Operator__c,SkipPermissions__c,SkipRoles__c,Values__c FROM ContentDocumentDeletion__mdt where ObjectName__c IN: sObjNames];
            for(ContentDocumentDeletion__mdt ccd : ccdList) {
                fieldApiNames.add(ccd.FieldApiName__c);
            }
            List<sObject> sobjList = new List<sObject>();
            if(!ccdList.isEmpty()) {
                string query = 'Select '+ String.join(fieldApiNames, ', ') + ' from ' + ccdList[0].ObjectName__c + ' where Id IN (' + idListString + ')';
                System.debug('############################'+query);
                sobjList = Database.query(query);
            }
            System.debug('############################'+sobjList);
            if(!sobjList.isEmpty()) {
                for(ContentDocumentLink actualRecord : Trigger.old) {
                    String field = '';
                    List<String> lstValues = new List<String>();
                    List<Boolean> fieldValues = new List<Boolean>();
                    for(ContentDocumentDeletion__mdt ccd : ccdList) {
                        field = String.valueOf(sobjList[0].get(ccd.FieldApiName__c));
                        lstValues = ccd.Values__c != null ? ccd.Values__c.split(',') : null;
                        if(lstValues != null) {
                            fieldValues.add(lstValues.contains(field));
                        }
                        System.debug(fieldValues);
                    }
                    String operator = ccdList[0].Operator__c;
                    List<String> customPermissions = ccdList[0].SkipPermissions__c != null ? ccdList[0].SkipPermissions__c.split(',') : null;
                    List<String> lstRoles = ccdList[0].SkipRoles__c != null ? ccdList[0].SkipRoles__c.split(',') : null;
                    List<Boolean> customPermissionValues = new List<Boolean>();
                    if (customPermissions != null) {
                        for(String customPermission : customPermissions) {
                            if(customPermission != null) {
                                customPermissionValues.add(FeatureManagement.checkPermission(customPermission));
                            }
                        }
                    }
                    System.debug(customPermissionValues);
                    if(operator == '1') {
                        if((!fieldValues.isEmpty() && !fieldValues.contains(false)) && (lstRoles == null || !lstRoles.contains(RoleName)) && (customPermissionValues.isEmpty() || !customPermissionValues.contains(true))) {
                            if(actualRecord != Null) {
                                actualRecord.addError('You cannot delete this file');
                            }
                        }
                    }
                    else {
                        if(fieldValues.contains(true) && (lstRoles == null || !lstRoles.contains(RoleName)) && (customPermissionValues.isEmpty() || !customPermissionValues.contains(true))) {
                            if(actualRecord != Null) {
                                actualRecord.addError('You cannot delete this file');
                            }
                        }
                    }
                    
                    
                }
            }
        }
        
        // Start SAC-1285 || Deepika || IBM
        if (Trigger.isAfter && Trigger.isDelete) {            
            Set<Id> contractIdsToUpdate = new Set<Id>();
            
            // Step 1: Get Contract__c IDs from deleted ContentDocumentLinks
            for (ContentDocumentLink cdl : Trigger.old) {
                if (cdl.LinkedEntityId != null && cdl.LinkedEntityId.getSObjectType() == Contract__c.SObjectType) {
                    contractIdsToUpdate.add(cdl.LinkedEntityId);
                }
            }
            
            if (!contractIdsToUpdate.isEmpty()) {
                // Step 2: Query all remaining ContentDocumentLinks for those contracts
                Map<Id, Integer> contractFileCounts = new Map<Id, Integer>();
                
                for (AggregateResult ar : [
                    SELECT LinkedEntityId, COUNT(Id) fileCount
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :contractIdsToUpdate
                    GROUP BY LinkedEntityId
                ]) {
                    contractFileCounts.put((Id) ar.get('LinkedEntityId'), (Integer) ar.get('fileCount'));
                }
                
                // Step 3: For each contract, check if it has no remaining files
                List<Contract__c> contractsToUpdate = new List<Contract__c>();
                
                for (Id contractId : contractIdsToUpdate) {
                    if (!contractFileCounts.containsKey(contractId)) {
                        contractsToUpdate.add(new Contract__c(
                            Id = contractId,
                            Is_Valid__c = false
                        ));
                    }
                }
                
                // Step 4: Update the contracts
                if (!contractsToUpdate.isEmpty()) {
                    update contractsToUpdate;
                }
            }
        }
        // End SAC-1285 || Deepika || IBM
    }
}