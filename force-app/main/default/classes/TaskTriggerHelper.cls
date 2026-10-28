/* Helper class for task trigger for cloning submission task*/
public class TaskTriggerHelper{
    //public static Boolean isExecuted = false;
    /*Method to create new Collection task after completion of submission task*/
    public static void createCollectionTask(List<Task> lstTask){
        Map<Id, Task> submissionTaskMap = new Map<Id , Task>();
        Map<Id, Task> existingCollectionTaskMap = new Map<Id , Task>();
        List<Debit_Credit_Note__c> lstDCNToUpdate = new List<Debit_Credit_Note__c>();
        List<Task> lstCollectionTask = new List<Task>();
        try{
            for(Task obj: lstTask){
                submissionTaskMap.put(obj.WhatId , obj);
            }

            for(Task t : [Select Id, WhatId from Task where WhatId In: submissionTaskMap.keySet() AND RecordTypeId =: Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId()]){
                existingCollectionTaskMap.put(t.WhatId, t);
            }
            for(Debit_Credit_Note__c dcn: [Select Id, Note_Number__c, Invoice_Name__c,Note_Amount_Total__c,Created_Date__c, Bill_Number__c, Invoice_Name__r.Bill_Number__c, Invoice_Name__r.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c, Invoice_Name__r.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c, 
                            Invoice_Name__r.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c, Invoice_Name__r.Customer_Contract_Code__c, Invoice_Name__r.Account__r.Customer_Category__c, Invoice_Name__r.Bill_Branch__c,
                            Invoice_Name__r.Billing_Level__c, Invoice_Name__r.Green_Book__c, Submission_Date__c, Remarks__c  from Debit_Credit_Note__c where Id In: submissionTaskMap.keySet()]){ 
                    if(submissionTaskMap.get(dcn.Id).Submitted_Date__c != null) {
                        dcn.Submission_Date__c = submissionTaskMap.get(dcn.Id).Submitted_Date__c;
                    }
                    
                    if(!String.isBlank(submissionTaskMap.get(dcn.Id).Description)) {
                        dcn.Remarks__c = submissionTaskMap.get(dcn.Id).Description;
                    }
                    lstDCNToUpdate.add(dcn);
                    if(existingCollectionTaskMap.containsKey(dcn.Id)) {
                        continue;
                    }

                    Task submissionTask = submissionTaskMap.get(dcn.Id);
                    Task collectionTask = new task();
                    collectionTask.Subject = 'Debit Note Collection Task - '+(dcn.Note_Number__c != null ? dcn.Note_Number__c : dcn.Invoice_Name__r.Bill_Number__c);
                    collectionTask.WhatId = dcn.Id;
                    collectionTask.SFX_Code__c = dcn.Invoice_Name__r.Customer_Contract_Code__c;
                    collectionTask.Customer_Category__c = dcn.Invoice_Name__r.Account__r.Customer_Category__c;
                    collectionTask.Billing_Branch__c = dcn.Invoice_Name__r.Bill_Branch__c;
                    collectionTask.Billing_Level__c = dcn.Invoice_Name__r.Billing_Level__c;
                    collectionTask.Green_Book__c =dcn.Invoice_Name__r.Green_Book__c;
                    collectionTask.Invoice_date__c =dcn.Created_Date__c;
                    collectionTask.Debit_Note_Amount__c =dcn.Note_Amount_Total__c;
                    collectionTask.Outstanding_Amount__c =dcn.Note_Amount_Total__c;

                    collectionTask.Status = 'Open';
                    collectionTask.Account_Name__c = submissionTask.Account_Name__c;
                    collectionTask.Priority = 'Normal';
                    collectionTask.RecordTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
                    collectionTask.OwnerId = dcn.Invoice_Name__r?.Collection_PropelI_BDM_Mapping__r?.PropelI_BDM__c != null ? dcn.Invoice_Name__r.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c :
                                                dcn.Invoice_Name__r.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    collectionTask.Description = submissionTask.Description;
                    collectionTask.Mobile_Number__c = submissionTask.Mobile_Number__c;
                    collectionTask.Submitted_Date__c = submissionTask.Submitted_Date__c;
                    collectionTask.Submitted_To__c = submissionTask.Submitted_To__c;
                    collectionTask.Email__c = submissionTask.Email__c;
                    collectionTask.Automation__c = true;
                    collectionTask.ActivityDate = Date.today().addDays(7);
                    lstCollectionTask.add(collectionTask);
            }
            if(!lstDCNToUpdate.isEmpty()){
                update lstDCNToUpdate;
            }

            if(!lstCollectionTask.isEmpty()){
                insert lstCollectionTask;
            }
        } catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('createCollectionTask', 'TaskTriggerHelper', e);
        }
    }

    public static void updateTask(List<Task> lstTask){
        try{
            List<Task> lstnewTask = new List<Task>();
            List<Invoice__c> lstInvoice = new List<Invoice__c>();
            Map<Id, Task> submissionTasks = new Map<Id , Task>();
            List<Id> InvoicesWithAccount = new List<Id>();
            Set<String> msaCode = new Set<String>();
            List<Id> msaSFXAccountIds = new List<Id>();
            Map<Id, Account_Team__c> collectionBDMMapped = new Map<Id, Account_Team__c>(); // map of account & account_team__r[0].BDM__c 
            Map<Id, Invoice__c> invoicesWithId = new Map<Id, Invoice__c>();
            List<String> msaLevelAccounts = new List<String>();
           
            Map<Id, String> invoicesWithCollectionBranches = new Map<Id, String>();
        	Map<Id, String> invoicesWithBillingBranches = new Map<Id, String>();
            Map<String, String> collectionBDMs = new Map<String, String>();
            Map<String, List<Account>> sfxOfMSAMap = new Map<String, List<Account>>();
            for(Task obj: lstTask){
                submissionTasks.put(obj.WhatId , obj);
            }
            for(Invoice__c inv: [Select Id, Green_Book__c,MSA__c,Customer_Contract_Code__c,Bill_Date__c,Sub_Branch_Master__c,Submission_Date__c, Remarks__c, Account__c,Account__r.Customer_Category__c, Charged_Total_Amount__c, Out_Total_Amount__c, Bill_Number__c, 
                                 Total_Outstanding_Amount__c, Billing_Level__c, Collection_Branch__c, Bill_Branch__c,SFX_Code__c,SFX__r.Customer_Category__c from Invoice__c where Id In: submissionTasks.keySet() and Status_LID__c = 292 ]){  //and Bill_Type_Flag__c != 'TP'
                                     InvoicesWithAccount.add(inv.Account__c);
                                     invoicesWithId.put(inv.Id, inv);
                                     msaCode.add(inv.MSA__c);
                                     invoicesWithBillingBranches.put(inv.Id, inv.Bill_Branch__c);
                    				 invoicesWithCollectionBranches.put(inv.Id, inv.Collection_Branch__c);
                                     
                                     if(submissionTasks.containsKey(inv.Id)){
                                         if(submissionTasks.get(inv.Id).Submitted_Date__c != null)
                                             inv.Submission_Date__c = submissionTasks.get(inv.Id).Submitted_Date__c;
                                         
                                         if(!String.isBlank(submissionTasks.get(inv.Id).Description))
                                             inv.Remarks__c = submissionTasks.get(inv.Id).Description;
                                         
                                         if(!String.isBlank(submissionTasks.get(inv.Id).Submitted_To__c))
                                             inv.Submitted_To__c = submissionTasks.get(inv.Id).Submitted_To__c;                      
                                         
                                         lstInvoice.add(inv);
                                     }
                                     // If Invoice Billing Level is MSA, SAC - 147
                                     if(inv.Billing_Level__c == 'MSA'){
                                         msaLevelAccounts.add(inv.Account__c);
                                     }
                                 }
            
            //Need Changes
            Id accRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
            Id rcRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
            // If Invoice Billing Level is MSA, than we should get BDM from its SFX
            // Added logic for SAC - 147
            if(msaLevelAccounts.size() > 0){
                List<Account> sfxList = [SELECT Id, SFX_Code__c, Parent.Propel_MSACode__c, ParentId                                 
                                         FROM Account 
                                         WHERE ParentId =: msaLevelAccounts 
                                         AND RecordType.Name='SFX' 
                                         AND Billing_Level__c ='MSA'];
                
                for(Account sfxAcc : sfxList){
                    InvoicesWithAccount.add(sfxAcc.Id);
                    if(!sfxOfMSAMap.containsKey(sfxAcc.ParentId)){
                        sfxOfMSAMap.put(sfxAcc.ParentId, new List<Account>());
                    }
                    sfxOfMSAMap.get(sfxAcc.ParentId).add(sfxAcc);
                }
            } 
            //InvoicesWithAccount.addAll(msaSFXAccountIds);
            
            // System.debug('InvoicesWithAccount-->'+InvoicesWithAccount);
            // System.debug('invoicesWithBillingBranches.values()-->'+invoicesWithBillingBranches.values());
            // Updated By - K SANSI, SAC-135
            // There are multiple BDM assigned for same collection branch, retrived the latest one to assign new collection task
            // Updated the logic to get BDM from BDM mapping instead Account team - SAC - 374
            for(PropelI_BDM_Mapping__c mapping : [Select Id, Name, PropelI_BDM__c, Submission__c,Submission_Branch__c,Collection__c,Collection_Branch__c, Billing_Branch__c, Account__c
                                                    from PropelI_BDM_Mapping__c   
                                                    where Account__c IN: InvoicesWithAccount
                                                    AND Billing_Branch__c IN: invoicesWithBillingBranches.values() AND (Collection__c = TRUE)]){
                                                    // System.debug(' mapping.Account__c-->'+ mapping.Account__c);
                                                    // System.debug(' mapping.Billing_Branch__c-->'+ mapping.Billing_Branch__c);
                                                    // System.debug(' mapping.Collection_Branch__c-->'+ mapping.Collection_Branch__c);                                                
                                                    //String key = mapping.Account__c+'-'+mapping.Billing_Branch__c+'-'+mapping.Collection_Branch__c; //commented By KSANSI - SAC-720
                                                    
                                                    
                                                    // System.debug(' key-->'+ key);
                                                    String key;
                                                        If(mapping.Collection__c){
                                                             key = mapping.Account__c+'-'+mapping.Collection_Branch__c;
                                                              collectionBDMs.put(key, mapping.PropelI_BDM__c);  
                                                        }                                 
                                                    }
                                  
                    
                     for(PropelI_BDM_Mapping__c mapping : [Select Id, Name, MSA__c,PropelI_BDM__c, Submission__c,Submission_Branch__c,Local_NAM__c, Billing_Branch__c, Account__c
                                                    from PropelI_BDM_Mapping__c   
                                                    where MSA__c IN: msaCode
                                                     AND Local_NAM__c = TRUE]){
                                                         String key;
                                                        If(mapping.Local_NAM__c){
                                                             key = mapping.MSA__c;
                                                              collectionBDMs.put(key, mapping.PropelI_BDM__c);  
                                                        }

                                                    


            }
            /*List<Account_Team__c> accTeamList = [Select Id, Collection__c, BDMPropelI__c , 
                                                Account__c FROM Account_Team__c WHERE Collection__c = true 
                                               	AND Account__c IN: InvoicesWithAccount AND 
                                                (Account__r.RecordTypeId =: accRecTypeId Or Account__r.RecordTypeId =: rcRecTypeId ) 
                                                ORDER BY LastModifiedDate ASC];
            for (Account_Team__c accTeam : accTeamList){
                	collectionBDMMapped.put(accTeam.Account__c, accTeam);                
            }*/
            /*for(Account acc: [Select Id, (Select Id, Collection__c, BDMPropelI__c from Account_Teams__r
             *  where Collection__c = true limit 1) from Account where Id IN:(InvoicesWithAccount.keySet()) 
             * And (RecordTypeId =: accRecTypeId Or RecordTypeId =: rcRecTypeId)]){
                if(acc.Account_Teams__r.size() > 0){
                    //mapAccId.put(mapInvAcc.get(acc.Id),acc.Account_Teams__r[0].bdm__c);
                    collectionBDMMapped.put(acc.Id, acc.Account_Teams__r);
                }
            }*/
            Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
            DateTime currentdt = system.now(); 
            // System.debug(' collectionBDMs-->'+ collectionBDMs);
            for(Task obj1: lstTask){
                // System.debug(' obj1-->'+ obj1);
                if(
                    (invoicesWithId.containsKey(obj1.whatId)  ) ||
                  	(
                        invoicesWithId.containsKey(obj1.whatId)  && 
                        invoicesWithId.get(obj1.whatId).Billing_Level__c == 'MSA'  
                    )
                  ){ 
                      Invoice__c inv = invoicesWithId.get(obj1.whatId) ;
                      	//String uniqueKey = inv.Account__c+'-'+inv.Bill_Branch__c+'-'+inv.Collection_Branch__c; //commented By KSANSI - SAC-720
                      	String uniqueKey = inv.Account__c+'-'+inv.Collection_Branch__c;
                       
                        String localNameUniqueKey = inv.MSA__c;
                        String collectionBDM;
                         
                        if(collectionBDMs.containsKey(uniqueKey)){
                            collectionBDM = collectionBDMs.get(uniqueKey); 
                        }
                      
                        else if(collectionBDMs.containsKey(localNameUniqueKey)){
                            collectionBDM = collectionBDMs.get(localNameUniqueKey);
                        }
                      
                      // If Invoice Billing Level is MSA, than we should get BDM from its SFX
                    // Added logic for SAC - 147
                    if(inv.Billing_Level__c == 'MSA'){
                        if(sfxOfMSAMap.containsKey(inv.Account__c)){                             
                            for(Account sfxAcc : sfxOfMSAMap.get(inv.Account__c)){
                                //uniqueKey = sfxAcc.Id + '-' + inv.Bill_Branch__c + '-' + inv.Collection_Branch__c; //commented By KSANSI - SAC-720
                                uniqueKey = sfxAcc.Id + '-' + inv.Collection_Branch__c;
                                if(collectionBDMs.containsKey(uniqueKey)){
                                    collectionBDM = collectionBDMs.get(uniqueKey); 
                                    break;
                                }
                            }
                        }                         
                    }
                      if(collectionBDM != null){ 
                    Task collectionTask = new task();
                    collectionTask.Subject = 'Bill Collection Task - '+invoicesWithId.get(obj1.WhatId).Bill_Number__c;
                    collectionTask.WhatId = obj1.whatid;
                    collectionTask.SFX_Code__c = inv.Customer_Contract_Code__c;
        			collectionTask.Customer_Category__c = inv.Account__r.Customer_Category__c;
                    collectionTask.Billing_Branch__c = inv.Bill_Branch__c;
                    collectionTask.Billing_Level__c = inv.Billing_Level__c;
                    collectionTask.Status = 'Open';
                    collectionTask.Green_Book__c =inv.Green_Book__c; //SAC-1550
                    collectionTask.Account_Name__c = obj1.Account_Name__c;
                    collectionTask.Priority = 'Normal';
                    collectionTask.Invoice_date__c = inv.Bill_Date__c;
                    collectionTask.RecordTypeId = rId;
                    // If Invoice Billing Level is MSA, SAC - 147  
                    collectionTask.ownerid = collectionBDM;
                    
                    /*if(invoicesWithId.get(obj1.whatId).Billing_Level__c == 'MSA' &&  collectionBDMMapped.containskey(msaSFXAccountIds.get(0))) {
                        collectionTask.OwnerId = collectionBDMMapped.get(msaSFXAccountIds.get(0)).BDMPropelI__c;
                    }else{
                        collectionTask.OwnerId = collectionBDMMapped.get(invoicesWithId.get(obj1.WhatId).Account__c).BDMPropelI__c;
                    }  */
                    collectionTask.Description = obj1.Description;
                    collectionTask.Mobile_Number__c = obj1.Mobile_Number__c;
                    collectionTask.Submitted_Date__c = obj1.Submitted_Date__c;
                    collectionTask.Submitted_To__c = obj1.Submitted_To__c;
                    collectionTask.Email__c = obj1.Email__c;
                    collectionTask.Automation__c = true;
                    collectionTask.ActivityDate = Date.newInstance(currentdt.year(), currentdt.month(), currentdt.day()).addDays(7); //tk.LastModifiedDate
                    collectionTask.Invoice_Amount__c = invoicesWithId.get(obj1.WhatId).Charged_Total_Amount__c;
                    collectionTask.Outstanding_Amount__c = invoicesWithId.get(obj1.WhatId).Total_Outstanding_Amount__c;//Out_Total_Amount__c
                    lstnewTask.add(collectionTask);
                      }
                }
            }
            if(!lstnewTask.isEmpty()){
                insert lstnewTask;
            } 
            if(lstInvoice.size() > 0){
                update lstInvoice;
            }
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updateTask', 'TaskTriggerHelper', e);
        }
    }

    public static void updateReopenTask(List<Task> lstTask){
        try {
            Set<Id> whatIds = new Set<Id>();
            Map<Id, Id> debitCreditNoteInvoiceMap = new Map<Id, Id>();
            Set<Id> debitCreditNoteIds = new Set<Id>();
            for(Task objTask : lstTask){
                whatIds.add(objTask.WhatId);
                if(objTask.WhatId.getSObjectType().getDescribe().getName() == 'Debit_Credit_Note__c'){
                    debitCreditNoteIds.add(objTask.WhatId);
                }
            }
            for(Debit_Credit_Note__c dcn : [SELECT Id, Invoice_Name__c FROM Debit_Credit_Note__c WHERE Id IN :debitCreditNoteIds]){
                whatIds.add(dcn.Invoice_Name__c);
                debitCreditNoteInvoiceMap.put(dcn.Id, dcn.Invoice_Name__c);
            } 

            Map<Id, Invoice__c> invToUserMap = new Map<Id, Invoice__c>([SELECT Id, Out_Total_Amount__c, Account__r.Parent.Name, Billing_Level__c, Green_Book__c,Account__r.Name,
                        Submission_propelI_BDM_Mapping__c, Submission_propelI_BDM_Mapping__r.PropelI_BDM__c, Bill_Branch__c, Total_Outstanding_Amount__c,
                        Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,
                        NAM_Propeli_BDM_Mapping__c, NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c, Bill_Number__c, CreatedDate,
                        QRM_Propeli_BDM_Mapping__c, QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c, Account__r.Customer_Category__c, Customer_Contract_Code__c,
                        CRS_Propeli_BDM_Mapping__c, CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c, SFX_Code__c, SFX__r.Customer_Category__c
                    FROM Invoice__c WHERE Id IN : whatIds]);
            for(Task objTask : lstTask){
                if(objTask.RecordTypeId == Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId() || objTask.RecordTypeId == Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId()) {
                    Invoice__c invRec = invToUserMap.get(objTask.WhatId);
                    if(invRec == null && debitCreditNoteInvoiceMap.containsKey(objTask.WhatId)){
                        invRec = invToUserMap.get(debitCreditNoteInvoiceMap.get(objTask.WhatId));
                    }
                    if(invRec != null && invRec.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c != null && objTask.RecordTypeId == Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId()){
                        if(objTask.OwnerId != invRec.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c) {
                            objTask.OwnerId = invRec.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c;
                        }
                    } else if(invRec != null && invRec.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c != null && objTask.RecordTypeId == Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId()){
                        if(objTask.OwnerId != invRec.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c) {
                            objTask.OwnerId = invRec.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c;
                        }
                    } else {
                        objTask.OwnerId = invRec.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    }
                }
                
            }
        } catch (Exception e) {
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updateReopenTask', 'TaskTriggerHelper', e);
        }
    }
    
    /*Method to create credit note case after completion of collection task*/
    public static void createCase(List<Task> lstTask, List<Id> lstInvId){
        try{
            List<Case__c> lstCase = new List<Case__c>();
            Map<Id,Id> mapInvIDAccountID = new Map<Id,Id>();
            Map<Id,Invoice__c> mapTaskInv = new Map<Id,Invoice__c>();
            map<Id,Id> mapAccId = new map<Id,Id>();
            
            Id rId = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Revenue Management Case').getRecordTypeId();
            User u = [select id,name,userrole.name from user where userrole.name='Claim User' limit 1];
            
            
            for(invoice__c inv: [select id,Charged_Total_Amount__c,Out_Total_Amount__c,Account__c from invoice__c where id in: lstInvId]){
                
                mapInvIDAccountID.put(inv.id, inv.Account__c);
            }
            for(task t: lstTask){
                Case__c cs = new Case__c();
                cs.Case_Typee__c = 'Credit Note';                
                cs.Invoice__c = t.WhatId;            
                cs.Remarks__c = 'Auto Created Credit Note';                            
                cs.Task_Amount__c = t.Non_Recoverable_Amount__c;
                cs.RecordTypeId = rId;                
                cs.account__c = mapInvIDAccountID.get(t.whatId);
                cs.Case_Type__c = t.non_recoverable_reason__c;
                cs.status__c = 'Active';
                lstCase.add(cs);
            }
            if(!lstCase.isEmpty()){
                insert lstCase;
            }
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('createCase', 'TaskTriggerHelper', e);
        }   
    }
    
    /*Method to Check task of account object and its contact/s not updated from last 90 days.*/
    public static void checkAccContacts(List<task> lstTask){
        try{
            map<Id,Id> mapTaskAccId = new map<Id,Id>();
            Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
            for(task t: lstTask){
                mapTaskAccId.put(t.Id,t.WhatId);
            }
            List<Account> lstAccount = [select id,name,(select id,name,lastmodifieddate from contacts) from account where recordtypeid=:rid and id in: mapTaskAccId.values()];
            map<Id,List<contact>> mapAccContacts = new map<Id,List<contact>>();
            for(Account acc: lstAccount){
                mapAccContacts.put(acc.Id, acc.contacts);
            }
            for(task t: lstTask){
                
                List<contact> lstCon =  mapAccContacts != null ? mapAccContacts.get(t.whatId):null;
                String contactsName = '';
                for(contact c: lstCon){
                    Date conLastmdf = date.valueof(c.LastModifiedDate);
                    Integer lday = conLastmdf.day();
                    Integer lmonth = conLastmdf.month();
                    Integer lyear = conLastmdf.year();
                    Date startDate = Date.newInstance(lyear,lmonth,lday);
                    Date currentDt = date.valueof(system.today());
                    Integer diffDate = startDate.daysBetween(currentDt);
                    if(diffDate >= 90){
                        if(contactsName == ''){
                            contactsName += c.name;
                        }
                        else{
                            contactsName = contactsName + ',' + c.name;
                        }
                    }
                }
                if(contactsName != ''){
                    t.addError('Please update the contacts "'+contactsName+'" information before updating task');
                }
            }
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('checkAccContacts', 'TaskTriggerHelper', e);
        }   
    }
    
    /*Method to Check task of invoice object and limit it to 1 for collection and submission*/
    public static void checkTaskInvoiceIns(List<task> lstTask,List<Id> lstInvoiceId){
        try{
            map<String,Integer> mapInvCount = new map<String,Integer>();//to store invoice id and the count of task(coll/sub).
            for(task t: [select id,whatid,recordtypeid from task where whatid in:lstInvoiceId]){
                
                if(!mapInvCount.containsKey(t.WhatId+'+'+t.recordtypeid)){                
                    mapInvCount.put(t.WhatId+'+'+t.recordtypeid,1);
                }
                else{                
                    Integer count = mapInvCount.get(t.WhatId+'+'+t.recordtypeid);
                    mapInvCount.put(t.WhatId+'+'+t.recordtypeid,count+1);
                }
            }
            for(task t: lstTask){            
                if(mapInvCount.get(t.WhatId+'+'+t.RecordTypeId) > 1){                
                    t.addError('Task of this type is already created.');
                }
            }
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('checkTaskInvoiceIns', 'TaskTriggerHelper', e);
        }
    }
    
    //Method to update SubmittedDate on task.
    public static void updateSubmitDate(List<task> lstTask){
        for(Task objTask : lstTask){
            objTask.Submitted_Date__c = Date.Today();
        }
    }
    
    //Method to update comments on submission task.
    public static void updateSubmissionComments(List<Task> lstTask){
        try{
            Id currentUser = UserInfo.getUserId();
            datetime dt = system.now();
            datetime dt2 = dt.addHours(5);
            datetime dt3 = dt2.addMinutes(30);
            Map<Id,User> mapUserIdName = new Map<Id,User>([select Id,name from user]);
            for(task tk : lstTask){
                if(String.isBlank(tk.Description)){
                    tk.Description = mapUserIdName.get(currentUser).Name +' '+ dt3 + ':' +tk.Comments_Added__c;  //tk.LastModifiedDate
                }
                else{
                    tk.Description += '\r\n' + mapUserIdName.get(currentUser).Name +' '+ dt3 + ':' +tk.Comments_Added__c;
                }
                tk.Comments_Added__c = '';
            }
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updateSubmissionComments', 'TaskTriggerHelper', e);
        }
    }
    
    //Method to update Payment details on task.
    public static void updatePaymentDetails(List<task> lstTask,map<Id,task> mapOldTask){
        List<task> lstTaskPartly = new List<task>();
        List<Id> lstInvId = new List<Id>();
        try{
            for(task t : lstTask){
                if(t.Payment_Remaining__c == 'Recoverable'){
                    if(t.Invoice_Amount__c == t.Outstanding_Amount__c){
                        if(t.Collected_Amount__c != null){
                            if(t.Collected_Amount__c > t.Outstanding_Amount__c){
                                t.addError('Collected Amount cannot be greater than Outstanding amount.');
                            }
                            else{                                
                                t.Recoverable_Amount__c = t.Outstanding_Amount__c - t.Collected_Amount__c;
                            }
                        }
                        else{
                            t.Recoverable_Amount__c = t.Outstanding_Amount__c;
                        }
                    }
                    //If outstanding amount < invoice amount
                    else if(t.Invoice_Amount__c > t.Outstanding_Amount__c){
                        if(t.Collected_Amount__c != null){
                            if(mapOldTask.get(t.Id).Collected_Amount__c != null){//If old value is not null
                                Double CollectedDiff = t.Collected_Amount__c - mapOldTask.get(t.Id).Collected_Amount__c;
                                if(CollectedDiff > t.Outstanding_Amount__c){
                                    t.addError('Collected Amount cannot be greater than Outstanding amount.');
                                }
                                else{
                                    t.Recoverable_Amount__c = t.Outstanding_Amount__c - CollectedDiff;
                                }
                            }
                            else{//If old value is null
                                if(t.Collected_Amount__c > t.Outstanding_Amount__c){
                                    t.addError('Collected Amount cannot be greater than Outstanding amount.');
                                }
                                else{
                                    t.Recoverable_Amount__c = t.Outstanding_Amount__c - t.Collected_Amount__c;
                                }
                            }
                        }
                        else{
                            t.Recoverable_Amount__c = t.Outstanding_Amount__c;
                        }
                    }
                    t.Partly_Non_Recoverable_Amount__c = 0;
                    t.Partly_Recoverable_Amount__c = 0;
                    t.Non_Recoverable_Amount__c = 0;
                }
                else if(t.Payment_Remaining__c == 'Non-Recoverable'){
                    if(t.Invoice_Amount__c == t.Outstanding_Amount__c){
                        if(t.Collected_Amount__c != null){
                            if(t.Collected_Amount__c >= t.Outstanding_Amount__c){
                                t.addError('Collected Amount cannot be greater than or equal to Outstanding amount.');
                            }
                            else{
                                t.Non_Recoverable_Amount__c = t.Outstanding_Amount__c - t.Collected_Amount__c;
                                if(t.Total_Credit_Note_Amount__c != null){
                                    t.Total_Credit_Note_Amount__c += t.Outstanding_Amount__c - t.Collected_Amount__c;
                                }
                                else{
                                    t.Total_Credit_Note_Amount__c = t.Outstanding_Amount__c - t.Collected_Amount__c;
                                }
                            }
                        }
                        else{
                            t.Non_Recoverable_Amount__c = t.Outstanding_Amount__c;
                        }
                        
                    }
                    //If outstanding amount < invoice amount
                    else if(t.Invoice_Amount__c > t.Outstanding_Amount__c){
                        if(t.Collected_Amount__c != null){
                            if(mapOldTask.get(t.Id).Collected_Amount__c != null){//If old value is not null
                                Double CollectedDiff = t.Collected_Amount__c - mapOldTask.get(t.Id).Collected_Amount__c;
                                if(CollectedDiff >= t.Outstanding_Amount__c){
                                    t.addError('Collected Amount cannot be greater than or eequal to Outstanding amount.');
                                }
                                else{
                                    t.Non_Recoverable_Amount__c = t.Outstanding_Amount__c - CollectedDiff;
                                    if(t.Total_Credit_Note_Amount__c != null){
                                        t.Total_Credit_Note_Amount__c += t.Outstanding_Amount__c - CollectedDiff;
                                    }
                                    else{
                                        t.Total_Credit_Note_Amount__c = t.Outstanding_Amount__c - CollectedDiff;
                                    }
                                }
                            }
                            else{
                                if(t.Collected_Amount__c >= t.Outstanding_Amount__c){
                                    t.addError('Collected Amount cannot be greater than or equal to Outstanding amount.');
                                }
                                else{                                
                                    t.Non_Recoverable_Amount__c = t.Outstanding_Amount__c - t.Collected_Amount__c;
                                    if(t.Total_Credit_Note_Amount__c != null){
                                        t.Total_Credit_Note_Amount__c += t.Outstanding_Amount__c - t.Collected_Amount__c;
                                    }
                                    else{
                                        t.Total_Credit_Note_Amount__c = t.Outstanding_Amount__c - t.Collected_Amount__c;
                                    }
                                }
                            }
                        }
                        //If collected amount is null.
                        else{
                            t.Non_Recoverable_Amount__c = t.Outstanding_Amount__c;
                            if(t.Total_Credit_Note_Amount__c != null){
                                t.Total_Credit_Note_Amount__c += t.Outstanding_Amount__c;
                            }
                            else{
                                t.Total_Credit_Note_Amount__c += t.Outstanding_Amount__c;
                            }
                        }
                    }
                    
                    t.Partly_Non_Recoverable_Amount__c = 0;
                    t.Partly_Recoverable_Amount__c = 0;
                    t.Recoverable_Amount__c = 0;                    
                }
                else if(t.Payment_Remaining__c == 'Partly Recoverable / Non Recoverable'){
                    if(t.Invoice_Amount__c == t.Outstanding_Amount__c){
                        if(t.Collected_Amount__c != null){
                            if((t.Collected_Amount__c + t.Partly_Recoverable_Amount__c) >= t.Outstanding_Amount__c ){
                                t.addError('Collected /Partly Recoverable Amount cannot be greater or equal to Outstanding amount.');
                            }
                            else{
                                t.Partly_Non_Recoverable_Amount__c = t.Outstanding_Amount__c - (t.Collected_Amount__c + t.Partly_Recoverable_Amount__c);
                                t.Non_Recoverable_Amount__c = t.Partly_Non_Recoverable_Amount__c; 
                                t.Recoverable_Amount__c = t.Partly_Recoverable_Amount__c;
                                if(t.Total_Credit_Note_Amount__c != null){
                                    t.Total_Credit_Note_Amount__c += t.Partly_Non_Recoverable_Amount__c;
                                }
                                else{
                                    t.Total_Credit_Note_Amount__c = t.Partly_Non_Recoverable_Amount__c;
                                }
                                lstTaskPartly.add(t);
                                lstInvId.add(t.WhatId);
                            }
                        }
                        //If collected amount is null
                        else{
                            if(t.Partly_Recoverable_Amount__c >= t.Outstanding_Amount__c){
                                t.addError('Partly Recoverable Amount cannot be greater or equal to Outstanding amount.');
                            }
                            else{
                                t.Partly_Non_Recoverable_Amount__c = t.Outstanding_Amount__c - t.Partly_Recoverable_Amount__c;
                                t.Non_Recoverable_Amount__c = t.Partly_Non_Recoverable_Amount__c; 
                                t.Recoverable_Amount__c = t.Partly_Recoverable_Amount__c;
                                if(t.Total_Credit_Note_Amount__c != null){
                                    t.Total_Credit_Note_Amount__c += t.Partly_Non_Recoverable_Amount__c;
                                }
                                else{
                                    t.Total_Credit_Note_Amount__c = t.Partly_Non_Recoverable_Amount__c;
                                }
                                lstTaskPartly.add(t);
                                lstInvId.add(t.WhatId);
                            }
                        }
                    }
                    //If oustanding amount < invoice amount
                    else if(t.Invoice_Amount__c > t.Outstanding_Amount__c){
                        if(t.Collected_Amount__c != null){
                            if(mapOldTask.get(t.Id).Collected_Amount__c != null){//If old value is not null
                                Double CollectedDiff = t.Collected_Amount__c - mapOldTask.get(t.Id).Collected_Amount__c;
                                if((CollectedDiff + t.Partly_Recoverable_Amount__c) >= t.Outstanding_Amount__c){
                                    t.addError('Collected /Partly Recoverable Amount cannot be greater or equal to Outstanding amount.');
                                }
                                else{
                                    t.Partly_Non_Recoverable_Amount__c = t.Outstanding_Amount__c - (CollectedDiff+t.Partly_Recoverable_Amount__c);
                                    t.Recoverable_Amount__c = t.Partly_Recoverable_Amount__c;
                                    t.Non_Recoverable_Amount__c = t.Partly_Non_Recoverable_Amount__c;
                                    if(t.Total_Credit_Note_Amount__c != null){
                                        t.Total_Credit_Note_Amount__c += t.Partly_Non_Recoverable_Amount__c;
                                    }
                                    else{
                                        t.Total_Credit_Note_Amount__c = t.Partly_Non_Recoverable_Amount__c;
                                    }
                                    lstTaskPartly.add(t);
                                    lstInvId.add(t.WhatId);
                                }
                            }
                            //If old collected value is null.
                            else{
                                if((t.Collected_Amount__c + t.Partly_Recoverable_Amount__c) >= t.Outstanding_Amount__c){
                                    t.addError('Collected /Partly Recoverable Amount cannot be greater or equal to Outstanding amount.');
                                }
                                else{
                                    t.Partly_Non_Recoverable_Amount__c = t.Outstanding_Amount__c - (t.Collected_Amount__c + t.Partly_Recoverable_Amount__c);
                                    t.Recoverable_Amount__c = t.Partly_Recoverable_Amount__c;
                                    t.Non_Recoverable_Amount__c = t.Partly_Non_Recoverable_Amount__c;
                                    if(t.Total_Credit_Note_Amount__c != null){
                                        t.Total_Credit_Note_Amount__c += t.Partly_Non_Recoverable_Amount__c;
                                    }
                                    else{
                                        t.Total_Credit_Note_Amount__c = t.Partly_Non_Recoverable_Amount__c;
                                    }
                                    lstTaskPartly.add(t);
                                    lstInvId.add(t.WhatId);
                                }
                            }
                            
                        }                       
                        else{
                            if(t.Partly_Recoverable_Amount__c >= t.Outstanding_Amount__c){
                                t.addError('Partly Recoverable Amount cannot be greater or equal to Outstanding amount.');
                            }
                            else{
                                t.Partly_Non_Recoverable_Amount__c = t.Outstanding_Amount__c - t.Partly_Recoverable_Amount__c;
                                t.Recoverable_Amount__c = t.Partly_Recoverable_Amount__c;
                                t.Non_Recoverable_Amount__c = t.Partly_Non_Recoverable_Amount__c;
                                if(t.Total_Credit_Note_Amount__c != null){
                                    t.Total_Credit_Note_Amount__c += t.Partly_Non_Recoverable_Amount__c;
                                }
                                else{
                                    t.Total_Credit_Note_Amount__c = t.Partly_Non_Recoverable_Amount__c;
                                }
                                lstTaskPartly.add(t);
                                lstInvId.add(t.WhatId);
                            }
                        }
                    }
                    
                    
                }
            }
            
            if(!lstTaskPartly.isEmpty()){
                createCase(lstTaskPartly,lstInvId);
            }
            
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updatePaymentDetails', 'TaskTriggerHelper', e);
        }
        
    }
    
    //Method to update collected amount on task and create Credit/debit note of partly recoverable/non recoverable.
    public static void updateCollectedAmount(List<task> lstTask,map<Id,task> mapOldTask){
        List<task> lstDebitNote = new List<task>();
        List<task> lstCreditNote = new List<task>();
        List<Id> lstDebitInv = new List<Id>();
        List<Id> lstCreditInv = new List<Id>();
        Double diff;
        try{
            for(task t: lstTask){
                diff = t.Collected_Amount__c - mapOldTask.get(t.Id).Collected_Amount__c;
                if(diff > t.Recoverable_Amount__c){ //Debit note creation
                    t.Debit_Note_Created__c = diff - t.Recoverable_Amount__c;
                    if(t.Total_Debit_Note__c != null){
                        t.Total_Debit_Note__c += t.Debit_Note_Created__c;
                    }
                    else{
                        t.Total_Debit_Note__c = t.Debit_Note_Created__c;
                    }
                    lstDebitNote.add(t);
                    lstDebitInv.add(t.WhatId);
                }
                else if(diff < t.Recoverable_Amount__c){
                    t.Partly_Non_Recoverable_Amount__c = t.Recoverable_Amount__c - diff;
                    t.Non_Recoverable_Amount__c = t.Recoverable_Amount__c - diff;
                    if(t.Total_Credit_Note_Amount__c != null){
                        t.Total_Credit_Note_Amount__c += t.Non_Recoverable_Amount__c;
                    }
                    else{
                        t.Total_Credit_Note_Amount__c = t.Non_Recoverable_Amount__c;
                    }
                    lstCreditNote.add(t);
                    lstCreditInv.add(t.whatid);
                }
                
            }
            if(!lstCreditNote.isEmpty()){
                createCase(lstCreditNote,lstCreditInv);
            }
            if(!lstDebitNote.isEmpty()){
                createDebitCase(lstDebitNote,lstDebitInv);
            }
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updateCollectedAmount', 'TaskTriggerHelper', e);
        }
    }
    
    /*Method to create debit note case of collection task*/
    public static void createDebitCase(List<Task> lstTask,List<Id> lstInvId){
        try{
            List<Case__c> lstCase = new List<Case__c>();
            Map<Id,Id> mapInvIDAccountID = new Map<Id,Id>();
            Map<Id,Invoice__c> mapTaskInv = new Map<Id,Invoice__c>();
            map<Id,Id> mapAccId = new map<Id,Id>();
            
            Id rId = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Revenue Management Case').getRecordTypeId();                                  
            for(invoice__c inv: [select id,Charged_Total_Amount__c,Out_Total_Amount__c,Account__c from invoice__c where id in: lstInvId]){
                
                mapInvIDAccountID.put(inv.id,inv.Account__c);
            }
            
            
            for(task t: lstTask){
                
                Case__c cs = new Case__c();
                cs.Case_Typee__c = 'Debit Note';                
                cs.Invoice__c = t.WhatId;            
                cs.Remarks__c = 'Auto Created Debit Note';                            
                cs.Task_Amount__c = t.Debit_Note_Created__c;
                cs.RecordTypeId = rId;                
                cs.account__c = mapInvIDAccountID.get(t.whatId);
                cs.status__c = 'Active';
                lstCase.add(cs);
            }
            if(!lstCase.isEmpty()){
                insert lstCase;
            }
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('createDebitCase', 'TaskTriggerHelper', e);
        }   
    }
    //Method to Relate task to Account if its not related to anyone
    public static void relateTask(List<Task> lstTask){
        List<Contact> lstCon = [Select id from Contact where Name =: 'INTEGRATION CONTACT' limit 1];
        if(lstCon != null && lstCon.size() > 0){
            for(Task objTask : lstTask){
                objTask.Submitted_to__c = lstCon[0].id;
            }
        }
    }
    
  

    //Method to check journey and contact null on status completed on on-boarding task.
    public static void onboaStatusTask(List<Task> tskList){
          User currentUser = [
            SELECT Id, Name, Profile.Name
            FROM User
             WHERE Id = :UserInfo.getUserId()
            ];

            String profileName = currentUser.Profile.Name;
        for(Task oldTask : tskList){
            //SAC-727 | Deepika Thakur | IBM
            if(oldTask.Meeting_type__c == 'AT CUSTOMER PREMISES' && oldTask.Journey__c == null && oldTask.WhoId == null){ 
                oldTask.Journey__c.adderror( 'Please fill Journey value.' );
                //oldTask.Contact_Person_Name__c.adderror( 'Please fill Contact Person Name.' );
               // oldTask.Mobile_Number__c.adderror( 'Please fill Contact Person Mobile Number.' );
              //  oldTask.Contact_Person_Email__c.adderror( 'Please fill Contact Person Email.' );
          
                
            
            }
            //SAC-727 | Deepika Thakur | IBM
            else if(oldTask.Meeting_type__c == 'AT CUSTOMER PREMISES' && oldTask.Journey__c == null){
                oldTask.Journey__c.adderror( 'Please fill Journey value.' );  
            }/*
            else if(oldTask.Contact_Person_Name__c == null){
                oldTask.Contact_Person_Name__c.adderror( 'Please fill Contact Person Name.' );  
            }
            else if(oldTask.Mobile_Number__c == null){
                oldTask.Mobile_Number__c.adderror( 'Please fill Contact Person Mobile Number.' );  
            }
            else if(oldTask.Contact_Person_Email__c == null){
                oldTask.Contact_Person_Email__c.adderror( 'Please fill Contact Person Email.' );  
            }*/
            else if(oldTask.WhoId == null){
                 
              if (profileName != 'Corporate salesforce team' && ProfileName != 'Read Only' && ProfileName != 'Onboarding Team' && ProfileName != 'System Administrator')
                {
                     oldTask.WhoId.adderror( 'Please fill Customer Contact Details (Multiple) Name.' ); 
                }
            }
        }
    }
    
    //Method to update comments on submission task.
    public static void updateInvoiceForSubmissionTask(Set<Id> invIdSet){
        try{
            List<Invoice__c> invoiceList = new List<Invoice__c>();
            if(!invIdSet.isEmpty()){
                for(Id invId : invIdSet){
                    Invoice__c inv = new Invoice__c();
                    inv.Id = invId;
                    inv.Create_Submission_Task__c = true;
                    invoiceList.add(inv);
                }
            }
            if(!invoiceList.isEmpty()){
                update invoiceList;
            }
            
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
            ExceptionHandling.Exception('updateInvoiceForSubmissionTask', 'TaskTriggerHelper', e);
        }
    }
    
       public static void setAssignerToField(List<Task> taskList){
        Map<String, String> cmdLblToFederationIdMap = new Map<String, String>();
        Map<String, String> response = new Map<String, String>();  
        
        List<Task_Assignment_Matrix__mdt> tam = Task_Assignment_Matrix__mdt.getAll().values();
         //List<Task_Assignment_Matrix__mdt> tam = new List<Task_Assignment_Matrix__mdt>();

        for (Task_Assignment_Matrix__mdt taskCmd : tam) {
            cmdLblToFederationIdMap.put(taskCmd.Label,taskCmd.Federation_id__c); 
        }
        
        List<User> userList = [SELECT Id, FederationIdentifier FROM User WHERE FederationIdentifier IN : cmdLblToFederationIdMap.values()];
        for(User usr: userList){
            response.put(usr.FederationIdentifier, usr.Id);
        }
      
        for (Task tsk :taskList ){
            if(tsk.Type__c != null && cmdLblToFederationIdMap.containsKey(tsk.type__c)){
               String FedID = cmdLblToFederationIdMap.get(tsk.type__c);
               String UserID = response.get(FedID);
               tsk.OwnerId = UserID;
            }            
        }
    }
    
    /*public static void setBillingBranchAndBillingLevel(Set<Id> invoiceTaskIds, List<Task> taskList){
        
        Map<Id, Invoice__c> invoiceList = new Map<Id, Invoice__c>([SELECT Id, Bill_Branch__c, Billing_Level__c 
                               FROM Invoice__c 
                               WHERE Id IN : invoiceTaskIds]);
        
        for(Task tsk: taskList){
            if(invoiceList.containsKey(tsk.WhatId)){
                tsk.Billing_Branch__c = invoiceList.get(tsk.WhatId).Bill_Branch__c;
                tsk.Billing_Level__c = invoiceList.get(tsk.WhatId).Billing_Level__c;
            }
        }
        
        
    }*/
    
/*Description: Converting workflow rule 
* author : Tarun Sachdeva
* SAC-1457
*/
    public static void updateTaskAutomation(List<Task> lstTask){
        for(Task task : lstTask){
            if(task.Automation__c == true){
                task.Automation__c = false;
            }
        }
    }
    
/*Description: Converting workflow rule 
* author : Tarun Sachdeva
* SAC-1457
*/
    public static void updateTaskDetails(List<Task> lstTask, Map<Id,Task> oldMap){
        for(Task task : lstTask){
            if(oldMap.get(task.Id).Automation__c != task.Automation__c && task.Automation__c == true){
                task.Automation__c = false;
            }
        }
    }
    
    // Changes as per the JIRA #1832
    
    public static void updateTaskCreatedAccTeam(List<Task> lstTask,Boolean Isdelete){
        Set<String> setSFXCode = new Set<String>();
        Set<Id> setRCId = new Set<Id>();
        Map<string, List<Account_Team__c>> mapSFXCodeWithAccountTeams = new Map<string, List<Account_Team__c>>();
        
        for(Task objTask : lstTask){
            if(objTask.WhatId != null){
                setSFXCode.add(objTask.WhatId);
            }
        }
        
        
        for(Account objAcc : [SELECT Id, name FROM Account WHERE Parent.Parent.Id IN: setSFXCode]){
            setRCId.add(objAcc.Id);
        }
        List<Account_Team__c> lstAccountTeams = new List<Account_Team__c>();
        if(Isdelete){
            
        lstAccountTeams = [SELECT ID, Relationship__c, Account__c, Account__r.parent.parent.Id, Assigned_Branch__c, BDMPropelI__c, Task_Created__c, SFX__c
                                                 FROM Account_Team__c
                                                 WHERE Account__c IN : setRCId
                                                 AND Relationship__c = true 
                                                 AND Task_Created__c = True
                                                ];
        }
        else{
            lstAccountTeams = [SELECT ID, Relationship__c, Account__c, Account__r.parent.parent.Id, Assigned_Branch__c, BDMPropelI__c, Task_Created__c, SFX__c
                                                 FROM Account_Team__c
                                                 WHERE Account__c IN : setRCId
                                                 AND Relationship__c = true 
                                                 AND Task_Created__c = false
                                                ];
        }

        if(lstAccountTeams.isEmpty()){
            return;
        }
        
        
        
        for (Account_Team__c objAT : lstAccountTeams) {
            String key = objAT.Account__r.parent.parent.Id + '-' + objAT.BDMPropelI__c;
            if (!mapSFXCodeWithAccountTeams.containsKey(key)) {
                mapSFXCodeWithAccountTeams.put(key, new List<Account_Team__c>());
            }
            mapSFXCodeWithAccountTeams.get(key).add(objAT);
        }
        
        for(Task objTask : lstTask){
            String key = objTask.WhatId + '-' + objTask.OwnerId;
            if(mapSFXCodeWithAccountTeams.containsKey(key)){
                for(Account_Team__c objAT : mapSFXCodeWithAccountTeams.get(key)){
                    if(Isdelete){
                        objAT.Task_Created__c = false;
                    }else{
                        objAT.Task_Created__c = true;
                    }
                    
                }
            }
        }
        
        if(!lstAccountTeams.isEmpty()){
            update lstAccountTeams;
        }
    }
}