/**
 * Description       :      Helper class for ContentDocumentLink trigger to update the  File_Uploaded_By_BDM__c to true on Quote and Task respectively.
 * JIRA ticket       :		https://safexpress.atlassian.net/browse/SD-453, https://safexpress.atlassian.net/browse/SD-629
 * Last Modified By  :      Monika Rawat
 * Last Modified Date:      09/07/2020
 * Revision Logs     :      V_1.0 - Created
 * 
 **/
public class CDLTriggerHelper {
    
    //Method to check if file is inserted on quote by bdm.
    public static void newInsert(List<ContentDocumentLink> lstRecords, List<Id> lstId, List<Id> lstLinkedId){
        //Get the list of all files on quotes.
        List<contentdocumentlink> lstAllCDL = new List<contentdocumentlink>(); 
        Map<Id,Integer> mapLinkedIdCount = new Map<Id,Integer>();
        List<quote__c> lstQuoteUpdate = new List<quote__c>();
        
        for( contentdocumentlink cdl : [select id,linkedentityid,contentdocumentid from contentdocumentlink where linkedentityid IN: lstLinkedId]){
            
            if(!mapLinkedIdCount.containsKey(cdl.LinkedEntityId)){
                mapLinkedIdCount.put(cdl.LinkedEntityId,1);
            }
            else{
                Integer cnt = mapLinkedIdCount.get(cdl.LinkedEntityId);
                mapLinkedIdCount.put(cdl.LinkedEntityId,cnt+1);
            }
        }
        
        for(quote__c qt : [select id,name,File_Uploaded_By_BDM__c from quote__c where ID IN: lstLinkedId]){
            
            if(mapLinkedIdCount.get(qt.Id) == 1){
                qt.File_Uploaded_By_BDM__c = true;
                lstQuoteUpdate.add(qt);
            }
        }
        if(!lstQuoteUpdate.isEmpty()){
            update lstQuoteUpdate;
        }
        
    }
    
    //Method to Check File uploaded on collection task by BDM. 
    public static void newInsertFileTask(List<ContentDocumentLink> lstRecords,List<Id> lstLinkedIdTask){
        try{
            Id rIdSub = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
            List<Id> lstSubTaskId = new List<Id>();
            Map<Id,Integer> mapLinkedIdCount = new Map<Id,Integer>();
            List<Task> lstTaskUpdate = new List<Task>();            
            for(Task t : [select id from task where recordtypeid =: rIdSub and Id in: lstLinkedIdTask]){
                lstSubTaskId.add(t.Id);
            }            
            for(contentdocumentlink cdl : [select id,linkedentityid,contentdocumentid from contentdocumentlink where linkedentityid IN: lstSubTaskId]){
                
                if(!mapLinkedIdCount.containsKey(cdl.LinkedEntityId)){
                    mapLinkedIdCount.put(cdl.LinkedEntityId,1);
                }
                else{
                    Integer cnt = mapLinkedIdCount.get(cdl.LinkedEntityId);
                    mapLinkedIdCount.put(cdl.LinkedEntityId,cnt+1);
                }
            }            
            for(task tk : [select id,File_Uploaded_By_BDM__c from task where ID IN: lstSubTaskId]){
                
                if(mapLinkedIdCount.get(tk.Id) == 1){
                    tk.File_Uploaded_By_BDM__c = true;
                    lstTaskUpdate.add(tk);
                }
            }

            if(!lstTaskUpdate.isEmpty()){
                update lstTaskUpdate;
            }
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
    }
    
    //Method to upload file by central team only once quote approved.
   /* public static void QuotePDFFileInsert(List<ContentDocumentLink> lstRecords, List<Id> lstId, List<Id> lstLinkedId){
        Map<Id,boolean> mapQuoteIdStatus = new Map<Id,boolean>(); //Set true if quote status is not approved.
        try{
            Id currentUser = UserInfo.getUserRoleId();
            String RoleName = [select id,name from userrole where id =: currentUser limit 1].name;            
            for(quote__c q : [select id,Approval_Status__c from quote__c where Id IN: lstLinkedId]){
                
                if(q.Approval_Status__c.equals('Approved By Corporate Head Credit/Retail') || 
                   q.Approval_Status__c.equals('Approved By CCD') ||
                   q.Approval_Status__c.equals('Pending from RM') ||
                   
                   q.Approval_Status__c.equals('Pending From CCD') ||
                   q.Approval_Status__c.equals('Submitted for Approval') ||
                   q.Approval_Status__c.equals('Approved by Regional Retail Head') ||
                   q.Approval_Status__c.equals('Pending with Regional Retail Head') ||
                   q.Approval_Status__c.equals('Pending from Corporate Head Credit/Retail')){ //Edited by Monika on 09/07/2020
                       mapQuoteIdStatus.put(q.Id,false);
                   }
            }            
            for(ContentDocumentLink cdl : lstRecords){                
                if(mapQuoteIdStatus.get(cdl.LinkedEntityId) == false && 
                   (!RoleName.equals('Central Quotation Team Credit') && !RoleName.equals('Central Team Retail'))){                       
                       cdl.addError('You do not have permission to upload file');
                   }
            }           
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
    }*/
    // Method to copy file to new created lead through zero keyboard app
    Public Static Void ContactFileCopyToLead(List<Id> IdList){
        List<Contact> conList = new List<Contact>();
        list<string> EmailList = new List<String>();
        list<Lead__c> LeadList = new List<Lead__c>();
        Integer a = 0;
         conList = [select id, name , email , LeadSource from contact where Id IN: IdList and LeadSource ='Directory'];
        system.debug('##########'+conList);
        for(contact con : conList){
            EmailList.add(con.Email);
        }
        LeadList = [Select id, name, email__c, Source__c from Lead__c where Email__c IN: EmailList and Source__c = 'Directory'];
        system.debug('##########'+LeadList);
        For(Contact con1: conList){
            For(Lead__c ld: LeadList){
                if(con1.Email == ld.Email__c){
                    a = a + 1;
                    system.debug('***********Matched************');
                    system.debug('Loop Number'+ a);
                    copyFile.CopyFileFromRecord1to2(con1.Id, ld.Id);
                }
            }
        }
    }
    
    public static void updateContractIsValid(List<Contract__c> contractList){
        
        TriggerUtility.byPassTrigger = true;
        update contractList;
        TriggerUtility.byPassTrigger = false; 
        
    }
    
    public static void newInsertFileCase(Set<Id> caseIds) {
         
        // Get RecordType Id for "Claim Issue"
        Map<Id, Case__c> casesToUpdate = new Map<Id, Case__c>();

        for (Case__c cs : [
            SELECT Id, RecordType.DeveloperName, IsSupportDocumentUploaded__c
            FROM Case__c
            WHERE Id IN :caseIds
        ]) {
            if (cs.RecordType.DeveloperName == 'Claim_Issues') {
                cs.IsSupportDocumentUploaded__c = true;
                casesToUpdate.put(cs.Id, cs);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            TriggerUtility.byPassTrigger = True;
            update casesToUpdate.values();
            TriggerUtility.byPassTrigger = False;
        }
    }
}