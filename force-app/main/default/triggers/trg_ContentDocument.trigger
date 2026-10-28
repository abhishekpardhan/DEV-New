/**
* Description      :   Trigger on ContentDocument object to restrict users from deleting files once uploaded
* JIRA ticket      :   https://safexpress.atlassian.net/browse/SD-623
* Created By       :   Shubham Girdhar
* Created Date     :   12/07/2020
**/
trigger trg_ContentDocument on ContentDocument (before insert,before delete) {
    
    Id currentUser = UserInfo.getUserRoleId();
    List<userrole> userroles = [select id,name from userrole where id =: currentUser limit 1];
    String RoleName;
    if(!userroles.isEmpty()) {
        RoleName = userroles[0].name;
    }
    
    if(trigger.isDelete && trigger.isBefore){
        List<Id> CDid = new List<Id>();
        Id SAProfileId = [select id from profile where name = 'System Administrator' limit 1].Id;
        Id IUProfileId = [select id from profile where name = 'Integration User' limit 1].Id;
        Id Profile1 = userinfo.getProfileId();
        for(ContentDocument con : Trigger.old){
            System.debug(Trigger.old);
            System.debug('!!!!!!!!!!!!!!!!!!!!!!!!!!!!'+con.Id);
            CDid.add(con.Id);
        }
        List<ContentDocumentLink> cdl1 = [select id , LinkedEntityId, ContentDocumentId from ContentDocumentLink where ContentDocumentId IN: CDid];
        System.debug('@@@@@@@@@@@@@@@@@@@@@@'+cdl1);
        List<String> sObjNames = new List<String>();
        List<String> recordid = new List<String>();
        if(!cdl1.isEmpty()){
            for(ContentDocumentLink cdl2 : cdl1 ){
                if(cdl2.linkedentityid != null){
                    sObjNames.add(cdl2.linkedentityid.getSObjectType().getDescribe().getName());   
                    recordid.add(cdl2.linkedentityid);
                }  
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
            for(ContentDocument actualRecord : Trigger.old) {
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
                if(operator == '1') {
                    if((!fieldValues.isEmpty() && !fieldValues.contains(false)) && (lstRoles == null || !lstRoles.contains(RoleName)) && (customPermissionValues.isEmpty() || !customPermissionValues.contains(true))) {
                        if(actualRecord != Null && !Test.isRunningTest()) {
                            actualRecord.addError('You cannot remove this file');
                        }
                    }
                }
                else {
                    if(fieldValues.contains(true) && (lstRoles == null || !lstRoles.contains(RoleName)) && (customPermissionValues.isEmpty() || !customPermissionValues.contains(true))) {
                        if(actualRecord != Null) {
                            actualRecord.addError('You cannot remove this file');
                        }
                    }
                }
                
                
            }
        }
        
        // Start SAC-1285 || Deepika || IBM
        // Step 1: Get all ContentDocumentIds that were deleted
        Set<Id> deletedDocIds = new Set<Id>();
        for (ContentDocument doc : Trigger.old) {
            deletedDocIds.add(doc.Id);
        }
        
        // Step 2: Query for related ContentDocumentLinks (they may still be accessible in trigger context)
        List<ContentDocumentLink> deletedLinks = [
            SELECT LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :deletedDocIds
        ];
        // Step 3: Collect Contract__c IDs
        Set<Id> contractIdsToUpdate = new Set<Id>();
        for (ContentDocumentLink cdl : deletedLinks) {
            if (cdl.LinkedEntityId != null && cdl.LinkedEntityId.getSObjectType() == Contract__c.SObjectType) {
                contractIdsToUpdate.add(cdl.LinkedEntityId);
            }
        }
        
        if (!contractIdsToUpdate.isEmpty()) {
            // Step 4: Query remaining files for those contracts using AggregateResult
            Map<Id, Integer> contractFileCounts = new Map<Id, Integer>();
            
            for (AggregateResult ar : [
                SELECT LinkedEntityId, COUNT(Id) fileCount
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :contractIdsToUpdate
                AND ContentDocumentId NOT IN :deletedDocIds
                GROUP BY LinkedEntityId
            ]) {
                contractFileCounts.put((Id) ar.get('LinkedEntityId'), (Integer) ar.get('fileCount'));
            }
            
            // Step 5: Check for remaining files
            List<Contract__c> contractsToUpdate = new List<Contract__c>();
            for (Id contractId : contractIdsToUpdate) {
                System.debug('Testt: '+contractId);
                if (!contractFileCounts.containsKey(contractId)) {
                    System.debug('Testt: '+contractFileCounts);
                    contractsToUpdate.add(new Contract__c(
                        Id = contractId,
                        Is_Valid__c = false
                    ));
                }
            }
            
            if (!contractsToUpdate.isEmpty()) {
                update contractsToUpdate;
            }
            // End SAC-1285 || Deepika || IBM
        }
    }
    /*if(trigger.isInsert && trigger.isBefore){
        System.debug('trg_ContentDocument');
        List<Id> CDid = new List<Id>();
        Id SAProfileId = [select id from profile where name = 'System Administrator' limit 1].Id;
        Id IUProfileId = [select id from profile where name = 'Integration User' limit 1].Id;
        Id Profile1 = userinfo.getProfileId();
        for(ContentDocument con : Trigger.new){
            System.debug(Trigger.new);
            System.debug('!!!!!!!!!!!!!!!!!!!!!!!!!!!!'+con.Id);
            CDid.add(con.Id);
        }
        List<ContentDocumentLink> cdl1 = new List<ContentDocumentLink>();
        if(!CDid.isEmpty()){
        cdl1 = [select id , LinkedEntityId, ContentDocumentId from ContentDocumentLink where ContentDocumentId IN: CDid];
    	}
        System.debug('@@@@@@@@@@@@@@@@@@@@@@'+cdl1);
        List<String> sObjNames = new List<String>();
        List<String> recordid = new List<String>();
        if(!cdl1.isEmpty()){
            for(ContentDocumentLink cdl2 : cdl1 ){
                if(cdl2.linkedentityid != null){
                    sObjNames.add(cdl2.linkedentityid.getSObjectType().getDescribe().getName());   
                    recordid.add(cdl2.linkedentityid);
                }  
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
            for(ContentDocument actualRecord : Trigger.new) {
                String field = '';
                List<String> lstValues = new List<String>();
                List<Boolean> fieldValues = new List<Boolean>();
                for(ContentDocumentDeletion__mdt ccd : ccdList) {
                    field = (String)sobjList[0].get(ccd.FieldApiName__c);
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
                if(operator == '1') {
                    if((!fieldValues.isEmpty() && !fieldValues.contains(false)) && (lstRoles == null || !lstRoles.contains(RoleName)) && (customPermissionValues.isEmpty() || customPermissionValues.contains(false))) {
                        if(actualRecord != Null) {
                            actualRecord.addError('You cannot insert this file operator 1.');
                        }
                    }
                }
                else {
                    if(fieldValues.contains(true) && (lstRoles == null || !lstRoles.contains(RoleName)) && (customPermissionValues.isEmpty() || customPermissionValues.contains(false))) {
                        if(actualRecord != Null) {
                            actualRecord.addError('You cannot insert this file operator 2.');
                        }
                    }
                }
                
                
            }
        }
    }*/
}