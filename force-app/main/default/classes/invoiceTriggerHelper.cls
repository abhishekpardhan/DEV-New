// Invoice helper class for teg_Invoice trigger to perform various tasks like creation of submission task on invoice creation after 5 days and updating the task status
// to either completed or reopen if Total Amount is 0 or greater than 0 respectively.
public class invoiceTriggerHelper{ 
    
    public static final Id subTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
    public static final Id colTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
    /* Trigger fire on invoice after update if outstaning amount changes */
    public static void updateInvoiceOut(List<Invoice__c> lstInvoice,List<Id> lstId,Map<Id,Invoice__c> mapInvoiceOldTrigger){
        //Map to store the invoice id and outstanding amount.
        map<Id,Decimal> mapInvOut = new map<Id,Decimal>();
        map<Id,Decimal> mapInvOutOld = new map<Id,Decimal>();
        map<Id,invoice__c> mapInvoice = new map<Id,invoice__c>();
        map<Id,payment__c> mapInvoicePmt = new map<Id,payment__c>();
        //List to add tasks to be updated with latest outstanding.
        List<Task> lstUpdTask = new List<Task>();
            for(invoice__c inv: lstInvoice){                
                mapInvOut.put(inv.Id,inv.Out_Total_Amount__c);
                mapInvoice.put(inv.Id,inv);                
            }
            for(invoice__c inv : mapInvoiceOldTrigger.values()){
                if(inv.Status_LID__c == 292 ){
                    mapInvOutOld.put(inv.Id,inv.Out_Total_Amount__c);
                }
            }
            for(invoice__c inv : [select id,(select id,name,Bill_Number__c,Cheque_Dishonor_Remarks__c,Invoice__c,Total_Amount__c from Payments__r order by lastmodifieddate DESC limit 1)
                                  from invoice__c where id IN: lstId]){
                                      if(inv.Payments__r.size() > 0){                   
                                          mapInvoicePmt.put(inv.Id,inv.Payments__r[0]);
                                      }
                                  }
            Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
            List<Task> lstTask = [select id,whatid,Outstanding_Amount__c,File_Uploaded_By_BDM__c from task where whatid in: lstId and recordtypeid =: rId];
            for(task t: lstTask){                
                t.Outstanding_Amount__c = mapInvOut.get(t.whatid);
                t.Automation__c = true;
                if(mapInvOut.get(t.whatid) == 0 ){ 
                    t.Status = 'Completed';
                }
                if(mapInvOutOld.get(t.whatid) == 0 && mapInvOut.get(t.whatid) > 0){
                    t.Status = 'Reopen';
                    if(!mapInvoicePmt.isEmpty()){
                        t.Reopen_Reason__c = mapInvoicePmt.get(t.whatid).Cheque_Dishonor_Remarks__c;
                    }
                }
                lstUpdTask.add(t);
            }
            if(!lstUpdTask.isEmpty()){
                 Database.SaveResult[] results = Database.update(lstUpdTask, false);
            }
            
        
    }
    
    @testVisible
    static invoice__share invShareRec(Id invId, Map<id , id > invUserId){
        if(invUserId.get(invId) != null){
            invoice__share invShareRec = new invoice__share();               
            invShareRec.ParentId= invId ;
            invShareRec.AccessLevel='Read';
            invShareRec.RowCause = 'Manual';
            invShareRec.UserOrGroupId=invUserId.get(invId);
            return invShareRec;
        }
        
        return null;
        
    }
    
    public static Map<id , String > invToUserid(String fieldName, List<invoice__c> invoiceList){



        Map<id , string> invToPbdmOwnerMap = new Map<id , string>();
        
        for(invoice__c invv: invoiceList){
            switch on fieldName{
                when 'Sub'{
                    if(invv.Submission_propelI_BDM_Mapping__c != null){
                        invToPbdmOwnerMap.put(invv.id , invv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c);
                    }
                    else if(invv.NAM_Propeli_BDM_Mapping__c != null){
                        invToPbdmOwnerMap.put(invv.id , invv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                    }

                    }  
                when 'Col'{
                    if(invv.Collection_PropelI_BDM_Mapping__c != null){
                        invToPbdmOwnerMap.put(invv.id , invv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c);
                        }else if(invv.NAM_Propeli_BDM_Mapping__c != null){
                        invToPbdmOwnerMap.put(invv.id , invv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                    }
                    }
                
                when 'NAM'{
                    if(invv.NAM_Propeli_BDM_Mapping__c	 != null){
                        invToPbdmOwnerMap.put(invv.id , invv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                    }
                }
                
                when 'QRM'{
                    if(invv.QRM_Propeli_BDM_Mapping__c	 != null){
                        invToPbdmOwnerMap.put(invv.id , invv.QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                    }else if(invv.Submission_propelI_BDM_Mapping__c != null){
                        invToPbdmOwnerMap.put(invv.id , invv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c);
                    }else if(invv.Collection_PropelI_BDM_Mapping__c != null){
                        invToPbdmOwnerMap.put(invv.id , invv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c);
                    }
                    }
         
                when 'CRS'{
                    if(invv.CRS_Propeli_BDM_Mapping__c	 != null){
                        invToPbdmOwnerMap.put(invv.id , invv.CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                    }
                }
            }
            
        }
        return invToPbdmOwnerMap;
    }
    
    static Map<Id,Set<Id>> invToUserid(list<invoice__c> invList){
        Map<String,Id> PBMToBDM = new Map<String,Id>(); 

        Set<Id> pbmSet = new Set<Id>();
        for(invoice__c inv : invList){
            pbmSet.add(inv.Submission_propelI_BDM_Mapping__c);
            pbmSet.add(inv.Collection_PropelI_BDM_Mapping__c);
            pbmSet.add(inv.NAM_Propeli_BDM_Mapping__c);
            pbmSet.add(inv.QRM_Propeli_BDM_Mapping__c);
            pbmSet.add(inv.CRS_Propeli_BDM_Mapping__c);
        }
        map<Id,PropelI_BDM_Mapping__c> PBMMap = new map<Id,PropelI_BDM_Mapping__c>([
            SELECT ID,PropelI_BDM__c FROM PropelI_BDM_Mapping__c WHERE Id IN:pbmSet
        ]);
        
        for(invoice__c inv : invList){
            if(inv.Submission_propelI_BDM_Mapping__c !=null){
                PBMToBDM.put(inv.Id+''+inv.Submission_propelI_BDM_Mapping__c,PBMMap.get(inv.Submission_propelI_BDM_Mapping__c).PropelI_BDM__c);
                
            }
            if(inv.Collection_PropelI_BDM_Mapping__c != null){
                PBMToBDM.put(inv.Id+''+inv.Collection_PropelI_BDM_Mapping__c,PBMMap.get(inv.Collection_PropelI_BDM_Mapping__c).PropelI_BDM__c);
                
            }
            if(inv.QRM_Propeli_BDM_Mapping__c != null){
                PBMToBDM.put(inv.Id+''+inv.QRM_Propeli_BDM_Mapping__c,PBMMap.get(inv.QRM_Propeli_BDM_Mapping__c).PropelI_BDM__c);
                
            }
            if(inv.CRS_Propeli_BDM_Mapping__c !=null){
                PBMToBDM.put(inv.Id+''+inv.CRS_Propeli_BDM_Mapping__c,PBMMap.get(inv.CRS_Propeli_BDM_Mapping__c).PropelI_BDM__c);
                
            }
            if(inv.NAM_Propeli_BDM_Mapping__c !=null){
                PBMToBDM.put(inv.Id+''+inv.NAM_Propeli_BDM_Mapping__c,PBMMap.get(inv.NAM_Propeli_BDM_Mapping__c).PropelI_BDM__c);
                
            }
            
        }
        
        Map<Id,Set<Id>> invToBDM = new Map<Id,Set<Id>>();
        
        /*List<Invoice__c> invList = [SELECT Id, 
Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,
Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c ,
NAM_Propeli_BDM_Mapping__c,NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
QRM_Propeli_BDM_Mapping__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
CRS_Propeli_BDM_Mapping__c,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c                                        
FROM invoice__c WHERE Id IN : invIdSet];*/
        for(Invoice__c inv : invList){
            if (!invToBDM.containsKey(inv.Id)){
                invToBDM.put(inv.Id, new Set<Id>());
                
            }
            
            
            if (inv.Submission_propelI_BDM_Mapping__c!=null ){
                //invToBDM.get(inv.Id).add(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c);
                invToBDM.get(inv.Id).add(PBMToBDM.get(inv.Id+''+inv.Submission_propelI_BDM_Mapping__c));

            }
            
             if (inv.Collection_PropelI_BDM_Mapping__c!=null){
                invToBDM.get(inv.Id).add(PBMToBDM.get(inv.Id+''+inv.Collection_PropelI_BDM_Mapping__c));
            }
            if (inv.NAM_Propeli_BDM_Mapping__c!=null){
                invToBDM.get(inv.Id).add(PBMToBDM.get(inv.Id+''+inv.NAM_Propeli_BDM_Mapping__c));
                
            }
            if (inv.QRM_Propeli_BDM_Mapping__c!=null){
                invToBDM.get(inv.Id).add(PBMToBDM.get(inv.Id+''+inv.QRM_Propeli_BDM_Mapping__c));
                
            }
            if (inv.CRS_Propeli_BDM_Mapping__c!=null){
                invToBDM.get(inv.Id).add(PBMToBDM.get(inv.Id+''+inv.CRS_Propeli_BDM_Mapping__c));
                
            }
            
            
            
        }
        return invToBDM;
        
        
    }


    // // Changes as per SAC - 1770
    // Method is used to auto closed invoice if the out standing amount is zero and e bill alos be yes.
    // 
     public static void autoClosedInvoice(Map<Id, invoice__c> invoiceMap){
        System.debug('autoClosedInvoice');
        Map<Id, Task> mapExistingSubTaskWithWhatId = new Map<Id, Task>();
        Map<Id, Task> mapExistingColTaskWithWhatId = new Map<Id, Task>();
        for(Task objTask : [SELECT Id, WhatId, RecordType.developerName FROM Task WHERE WhatId IN: invoiceMap.keySet()]){
            if(objTask.RecordType.developerName == 'Submission'){
                mapExistingSubTaskWithWhatId.put(objTask.whatId, objTask);
            }else if(objTask.RecordType.developerName == 'Collection'){
                mapExistingColTaskWithWhatId.put(objTask.whatId, objTask);
            }
        }

        List<Task> submissionTasks = new List<Task>();
        List<Task> collectionTask = new List<Task>();
            
        List<invoice__c> invoiceList = [SELECT Id,MSA_Name__c,Name, e_Bill__c,Bill_Date__c,Green_Book__c,Out_Total_Amount__c, Account__r.Parent.Name,Collection_Branch__c,Sub_Branch_Master__c,
                                    Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Bill_Branch__c, Total_Outstanding_Amount__c,
                                    Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c , Billing_Level__c, Charged_Total_Amount__c,
                                    NAM_Propeli_BDM_Mapping__c,NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,Bill_Number__c,CreatedDate,BDM_Email_IDs__c,Customer_Category__c,
                                    QRM_Propeli_BDM_Mapping__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,Account__r.Customer_Category__c,Customer_Contract_Code__c,
                                    CRS_Propeli_BDM_Mapping__c,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c,SFX_Code__c, SFX__r.Customer_Category__c ,Remarks__c                                     
                                    FROM invoice__c WHERE Id IN : invoiceMap.keySet()];
        
        if(!invoiceList.isEmpty()){
            System.debug('invoiceList');
            Id subTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
            Id colTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
            Map<Id, String> invRecmap = new Map<Id, String>();
            Map<Id, String> invRecmap1 = new Map<Id, String>();
            Map<id ,String> invToUserMap = new Map<id, String>();
            Map<id ,String> CollectionBDminvToUserMapCollection = new Map<id, String>();
            Map<id ,String> NAMDminvToUserMapCollection = new Map<id, String>();
            Map<id ,String> SubmissionDminvToUserMapCollection = new Map<id, String>();
            
            for (invoice__c invv : invoiceList) {
                System.debug('invv'+invv);
                invRecmap.put(invv.Id, invv.Account__r.Parent.Name);
                invRecmap1.put(invv.Id, invv.Account__r.Customer_Category__c);
                System.debug('Submission_propelI_BDM_Mapping__cousideif--->'+invv.Submission_propelI_BDM_Mapping__c);
                if(invv.Submission_propelI_BDM_Mapping__c != null){
                    System.debug('Submission_propelI_BDM_Mapping__c--->'+invv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c);
                    SubmissionDminvToUserMapCollection.put(invv.id , invv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c);
                    if(invv.Collection_PropelI_BDM_Mapping__c != null){
                        CollectionBDminvToUserMapCollection.put(invv.id , invv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c);
                    }
                    if(invv.NAM_Propeli_BDM_Mapping__c != null){
                        NAMDminvToUserMapCollection.put(invv.id , invv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                    }
                }
                else if(invv.Collection_PropelI_BDM_Mapping__c != null){ // changes as per SAC - 1770
                    CollectionBDminvToUserMapCollection.put(invv.id , invv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c);
                    if(invv.Submission_propelI_BDM_Mapping__c != null){
                        SubmissionDminvToUserMapCollection.put(invv.id , invv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c);
                    }
                    if(invv.NAM_Propeli_BDM_Mapping__c != null){
                        NAMDminvToUserMapCollection.put(invv.id , invv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                    }
                }else if(invv.NAM_Propeli_BDM_Mapping__c != null){
                    invToUserMap.put(invv.id , invv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                    NAMDminvToUserMapCollection.put(invv.id , invv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c);
                }
            }

            for(Invoice__c objInvoice : invoiceList){
                if(objInvoice.e_Bill__c=='Yes'){
         
                    System.debug('objInvoice'+SubmissionDminvToUserMapCollection.containsKey(objInvoice.Id));
                    if(SubmissionDminvToUserMapCollection.containsKey(objInvoice.Id)){
                        submissionTasks.add(createTaskAutoClose(objInvoice, SubmissionDminvToUserMapCollection.get(objInvoice.Id), subTaskRecordId, 'Bill Submission Task - ','Completed'));
                    }
                    else{
                        submissionTasks.add(createTaskAutoClose(objInvoice, NAMDminvToUserMapCollection.get(objInvoice.Id), subTaskRecordId, 'Bill Submission Task - ','Completed'));
                    }
                    System.debug('submissionTasks'+submissionTasks);
                }
                    
            }

            if(!submissionTasks.isEmpty()){
                DATABASE.INSERT(submissionTasks, true);
            }
            
            Map<Id, Task> mapInvoiceWithTask = new Map<Id, Task>();
            for(Task objTask : submissionTasks){
                if(objTask.status == 'Completed'){
                    mapInvoiceWithTask.put(objTask.whatId, objTask);
                }
            }

            for(Invoice__c objInvoice : invoiceList){
                if(mapInvoiceWithTask.containsKey(objInvoice.Id)){
                    String Status='Open';
                    if(objInvoice.Out_Total_Amount__c <= 1){
                        Status='Completed';
                    }
                    if(CollectionBDminvToUserMapCollection.containsKey(objInvoice.Id)){
                         collectionTask.add(createTaskAutoClose(objInvoice, CollectionBDminvToUserMapCollection.get(objInvoice.Id), colTaskRecordId, 'Bill Collection Task - ',Status));
                    }
                    else{
                         collectionTask.add(createTaskAutoClose(objInvoice, NAMDminvToUserMapCollection.get(objInvoice.Id), colTaskRecordId, 'Bill Collection Task - ',Status));
                    }
                   
                }
            }

            if(!collectionTask.isEmpty()){
                DATABASE.INSERT(collectionTask, true);
            }
        }        

    }

    private static Task createTaskAutoClose(Invoice__c invRec, Id ownerId, Id recordTypeId, String subject,String Status){
        system.debug('createTaskAutoClose-->');
        Task tsk = new task();
        tsk.subject = subject + invRec.Name;
        tsk.recordtypeid = recordTypeId;
        tsk.whatid = invRec.Id;
        tsk.Priority = 'High';
        tsk.Account_Name__c = invRec.MSA_Name__c;
        tsk.status = Status;
        if(Status == 'Completed'){
            tsk.ValidationBypassDateTime__c = System.now();
        }
        tsk.ownerid = ownerId;
        tsk.Automation__c = true; 
        tsk.Green_Book__c = invRec.Green_Book__c;//SAC-1550
        if (subject != null && subject.contains('Collection')) {
            tsk.Outstanding_Amount__c = invRec.Total_Outstanding_Amount__c;
            tsk.Invoice_Amount__c     = invRec.Charged_Total_Amount__c;

            if (invRec.e_Bill__c == 'Yes') {
                tsk.Submitted_Date__c = System.today();
            }

        } else {
            tsk.Ebill_Submission__c = (invRec.e_Bill__c == 'Yes');
        }

        tsk.Customer_Category__c = invRec.Customer_Category__c;
        tsk.ActivityDate = date.newinstance(invRec.CreatedDate.year(), invRec.CreatedDate.month(), invRec.CreatedDate.day()).addDays(7);   
        tsk.SFX_Code__c = invRec.Customer_Contract_Code__c;
        tsk.Invoice_date__c = invRec.Bill_Date__c;
       // task.Customer_Category__c = invRecmap1.get(invRec.Id);
        tsk.Billing_Branch__c = invRec.Bill_Branch__c;
        tsk.Billing_Level__c = invRec.Billing_Level__c;
        if(invRec.Remarks__c != null && invRec.BDM_Email_IDs__c != null){
           String comments;
           comments = 'Submitted To Email Ids: '+ invRec.Remarks__c +' '
                               + '\nBDM Email: '+ invRec.BDM_Email_IDs__c;
           if (comments.length() > 255) {
               comments = comments.substring(0, 255);
             }
            tsk.Comments_Added__c = comments;
                } 
        System.debug('tsk===>'+tsk);
        return tsk;
    }
    
    // SAC-147 - updated by K SANSI - IBM, added logic to support MSA Level billing
    // updated by Himanshi Dang SAC-484
    // SAC-719 | Updated by Deepika | IBM (If outstanding amount on Invoice is zero, complete the submission collection Tasks as soon as they are created )
    //SAC-1644 | Updated by Manshi
    public static void createSubmissionTask(Map<id,invoice__c> invNewMap){
       
            // Changes as per SAC - 1770
            
             Map<Id, Task> mapExistingTaskWithWhatId = new Map<Id, Task>();
            for(Task objTask : [SELECT Id, WhatId FROM Task WHERE RecordType.developerName = 'Submission' AND WhatId IN: invNewMap.keySet()]){
                mapExistingTaskWithWhatId.put(objTask.whatId, objTask);
            }
            List<Task> submissionTasks = new List<Task>();
           List<invoice__c> invoiceList = [SELECT Id, MSA_Name__c,Bill_Date__c,Out_Total_Amount__c, Account__r.Parent.Name,Collection_Branch__c,Sub_Branch_Master__c,
                                        Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Bill_Branch__c,Total_Outstanding_Amount__c,
                                        Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c ,Billing_Level__c, Remarks__c, BDM_Email_IDs__c,
                                        NAM_Propeli_BDM_Mapping__c,NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,Bill_Number__c,CreatedDate, e_Bill__c, Green_Book__c,
                                        QRM_Propeli_BDM_Mapping__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,Account__r.Customer_Category__c,Customer_Contract_Code__c,
                                        CRS_Propeli_BDM_Mapping__c,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c,SFX_Code__c, SFX__r.Customer_Category__c, Charged_Total_Amount__c                                       
                                        FROM invoice__c WHERE Id IN : invNewMap.keySet()];
           
            Map<Id, String> invRecmap = new Map<Id, String>();
            Map<Id, String> invRecmap1 = new Map<Id, String>();
            Set<Id> colleactionBranchId = new Set<Id>();
            Set<Id> submissionBranchId = new Set<Id>();
            for (invoice__c inv : invoiceList) {
                System.debug('Inv'+inv);
                invRecmap.put(inv.Id, inv.MSA_Name__c);
                invRecmap1.put(inv.Id, inv.Account__r.Customer_Category__c);
                colleactionBranchId.add(inv.Collection_Branch__c);
                submissionBranchId.add(inv.Sub_Branch_Master__c); 
            }
            Map<Id,Branch_Master__c> mapOfBranchlst = new Map<Id,Branch_Master__c>([Select Id,PropelI_Branch_ID__c from Branch_Master__c where Id IN: colleactionBranchId OR Id IN: submissionBranchId ]);
            Map<id ,String > invToUserMap = invToUserid('Sub',invoiceList); // Update as per story SAC - 1770
            Id subTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
            for(invoice__c invRec : invNewMap.values()){
                // Changes as per SAC - 1770
            if(!mapExistingTaskWithWhatId.containsKey(invRec.Id)){
                Task task = new task();
                task.subject = 'Bill Submission Task - '+ invRec.Bill_Number__c;
                task.recordtypeid = subTaskRecordId;
                task.whatid = invRec.Id;
                task.SFX_Code__c = invRec.Customer_Contract_Code__c;
                task.Invoice_date__c = invRec.Bill_Date__c;
                task.Customer_Category__c = invRecmap1.get(invRec.Id);
                task.Billing_Branch__c = invRec.Bill_Branch__c;
                task.Billing_Level__c = invRec.Billing_Level__c;
                task.Account_Name__c = invRecmap.get(invRec.Id);
                task.Priority = 'High';
                if(invRec.Remarks__c != null && invRec.BDM_Email_IDs__c != null){
                    String comments;
                    comments = 'Submitted To Email Ids: '+ invRec.Remarks__c +' '
                               + '\nBDM Email: '+ invRec.BDM_Email_IDs__c;
                    if (comments.length() > 255) {
                        comments = comments.substring(0, 255);
                    }
                    task.Comments_Added__c = comments;
                }
                if(invRec.e_Bill__c == 'YES'  || invRec.Out_Total_Amount__c == 0.0){
                    task.Status = 'Completed';
                }else{
                     task.Status = 'Open';
                }
                task.ownerid = invToUserMap.get(invRec.Id);
                task.Ebill_Submission__c = (invRec.e_Bill__c == 'YES') ? true : false;
                task.Automation__c = true;
                task.Green_Book__c = invRec.Green_Book__c; //SAC-1550
                task.ActivityDate = date.newinstance(invRec.CreatedDate.year(), invRec.CreatedDate.month(), invRec.CreatedDate.day()).addDays(7);
                submissionTasks.add(task);
                system.debug('submissionTasks'+submissionTasks);
            }
        }
            List<Error_Log__c> errorlst = new List<Error_Log__c>();
            if(!submissionTasks.isEmpty()){
                Database.SaveResult[] results = Database.insert(submissionTasks,false);
              
                for (Integer i = 0; i < results.size(); i++) {
                    
                    if (results[i].isSuccess()) {
                        
                    } else {
                        
                        Error_Log__c errorLog = New Error_Log__c();
                        errorLog.Class_Name__c = 'invoiceTriggerHelper';
                        errorLog.Method_Name__c = 'createSubmissionTask';
                        errorLog.Exception_Message__c = results[i].getErrors()[0].getMessage();
                        errorlst.add(errorLog);
                    }
                }
                Database.insert(errorlst,false); 
            }
           
            if(submissionTasks[0].Status == 'Completed' && submissionTasks[0].Ebill_Submission__c == true){
                List<Task> collectionTasks = getTasksList(invoiceList);
            
            if(!collectionTasks.isEmpty()){
                Database.insert(collectionTasks,false);
               
              }
            }
            
       
    }
    
    public static Task createTask(Invoice__c invRec){
        Task tsk = new task();
        tsk.subject = 'Bill Submission Task - '+ invRec.Bill_Number__c;
        tsk.recordtypeid = subTaskRecordId;
        tsk.whatid = invRec.Id;
        tsk.Priority = 'High';
        tsk.Account_Name__c = invRec.MSA_Name__c;
        tsk.status = invRec.Out_Total_Amount__c != 0.0 ? 'Open' : 'Completed';
        tsk.ownerid = invRec.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c;
        tsk.Automation__c = true; 
        tsk.Green_Book__c = invRec.Green_Book__c;//SAC-1550
        tsk.ActivityDate = date.newinstance(invRec.CreatedDate.year(), invRec.CreatedDate.month(), invRec.CreatedDate.day()).addDays(7);                 
        return tsk;
    }
    // Updated by Himanshi
    public static void updateSubmissionTask(Set<id> invIdSet){
        System.debug('updateSubmissionTask--->');
       
            List<invoice__c> invoiceList = [SELECT Id,MSA_Name__c,Green_Book__c, Out_Total_Amount__c, Account__r.Parent.Name,
                                            Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,
                                            Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c ,
                                            NAM_Propeli_BDM_Mapping__c,NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                                            QRM_Propeli_BDM_Mapping__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                                            CRS_Propeli_BDM_Mapping__c,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c, Bill_Number__c, CreatedDate                                        
                                            FROM invoice__c WHERE Id IN : invIdSet];
            
           
            Id subTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
            List<Task> tasklist =  [SELECT Id, Status,WhatId,OwnerId, recordtypeid
                                    FROM  Task 
                                    WHERE WhatId IN :invIdSet AND recordtypeid =: subTaskRecordId AND Status != 'Completed' AND Status != 'Cancelled'];
          
            for(Task tk:tasklist ){
            }
            Map<String, Task> invoiceTaskIds = new Map<String, Task>();
            
            for(Task tsk : taskList){
                invoiceTaskIds.put(tsk.WhatId, tsk);                 
            }
            List<Task> upsertTaskList = new List<Task>();
            Map<Id, Invoice__c> invoiceListToCreateTask = new Map<Id, Invoice__c>();
            for(Invoice__c invoice : invoiceList){
                
                if(invoiceTaskIds.containsKey(invoice.Id)){
                    if(invoiceTaskIds.get(invoice.Id).Status != 'Completed' && invoiceTaskIds.get(invoice.Id).Status != 'Cancelled'){ 
                        Task tsk = new Task();
                       
                        tsk.Id = invoiceTaskIds.get(invoice.Id).Id;
                        if(invoice.Submission_propelI_BDM_Mapping__c != null){
                            if(invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c != invoiceTaskIds.get(invoice.Id).OwnerId) {
                                tsk.OwnerId = invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c;
                                upsertTaskList.add(tsk);
                            }
                        } else if(invoice.NAM_Propeli_BDM_Mapping__c != null){
                            if( invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c != invoiceTaskIds.get(invoice.Id).OwnerId){
                                tsk.OwnerId = invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                                upsertTaskList.add(tsk);
                            }
                        } 
                    }
                }else{
                  
                    upsertTaskList.add(createTask(invoice));
                }
            }
           
            if (upsertTaskList.size()>0){
                Database.update(upsertTaskList,false);
            }
            
        
    }

    public static void updateDebitTask(Set<Id> invIdSet){
        Set<Id> allWhatIds = new Set<Id>();
        List<Task> taskToUpdate = new List<Task>();
        Map<Id, Id> dcnToInvoiceMap = new Map<Id, Id>();
        
            Map<Id,Invoice__c> invoiceListMap = new Map<Id,Invoice__c>([
                SELECT Id, Bill_Date__c, Account__r.Name, Account__r.Parent.Name, Out_Total_Amount__c,
                       Submission_propelI_BDM_Mapping__c, Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,
                       Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,
                       NAM_Propeli_BDM_Mapping__c, NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                       QRM_Propeli_BDM_Mapping__c, QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                       CRS_Propeli_BDM_Mapping__c, CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                       Bill_Number__c, CreatedDate
                FROM Invoice__c
                WHERE Id IN :invIdSet
            ]);

            for(Debit_Credit_Note__c dcn : [SELECT Id, Invoice_Name__c FROM Debit_Credit_Note__c WHERE Invoice_Name__c IN :invIdSet]){
                dcnToInvoiceMap.put(dcn.Id, dcn.Invoice_Name__c);
            }

            List<Task> taskList = [
                SELECT Id, Status, WhatId, OwnerId, RecordTypeId
                FROM Task
                WHERE WhatId IN :dcnToInvoiceMap.keySet() AND Status != 'Completed' AND Status != 'Cancelled' LIMIT 50000
            ];

            for(Task tk : taskList){
                Id relatedInvoiceId = null;

                if(dcnToInvoiceMap.containsKey(tk.WhatId)){
                    relatedInvoiceId = dcnToInvoiceMap.get(tk.WhatId);
                }

                if(relatedInvoiceId == null) {
                    continue;
                }

                Invoice__c inv = invoiceListMap.get(relatedInvoiceId);
                if(inv == null) {
                    continue;
                }

                Id newOwnerId = null;
                if(tk.RecordTypeId == colTaskRecordId){
                    if(inv.Collection_PropelI_BDM_Mapping__c != null && inv.Collection_PropelI_BDM_Mapping__r != null){
                        newOwnerId = inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c;
                    } else if(inv.NAM_Propeli_BDM_Mapping__c != null && inv.NAM_Propeli_BDM_Mapping__r != null){
                        newOwnerId = inv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    }
                } else if(tk.RecordTypeId == subTaskRecordId){
                    if(inv.Submission_propelI_BDM_Mapping__c != null && inv.Submission_propelI_BDM_Mapping__r != null){
                        newOwnerId = inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c;
                    } else if(inv.NAM_Propeli_BDM_Mapping__c != null && inv.NAM_Propeli_BDM_Mapping__r != null){
                        newOwnerId = inv.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    }
                }
                if(newOwnerId != null && tk.OwnerId != newOwnerId){
                    tk.OwnerId = newOwnerId;
                    taskToUpdate.add(tk);
                }
            }

            if(!taskToUpdate.isEmpty()){
                Database.SaveResult[] results = Database.update(taskToUpdate, false);
                for(Integer i = 0; i < results.size(); i++){
                    if(!results[i].isSuccess()){
                        String errMsg = '';
                        for(Database.Error err : results[i].getErrors()){
                            errMsg += err.getStatusCode() + ' : ' + err.getMessage() + '\n';
                        }
                        ExceptionHandling.Exception('updateDebitCollectionTask', 'invoiceTriggerHelper', 'Failed to update task Id: ' + taskToUpdate[i].Id + ' Errors: ' + errMsg);
                    }
                }
            }

        
    }
    
    //Updated by Himanshi
    public static void updateCollectionTask(Set<id> invIdSet){
       
            List<Invoice__c> invoiceList = [SELECT Id,MSA_Name__c,Bill_Date__c, Account__r.Name,Account__r.Parent.Name, Out_Total_Amount__c, e_Bill__c, Bill_Branch__c,
                                        Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,
                                        Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c , BDM_Email_IDs__c,
                                        NAM_Propeli_BDM_Mapping__c,NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c, Billing_Level__c,Remarks__c,Green_Book__c,
                                        QRM_Propeli_BDM_Mapping__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,SFX_Code__c, Total_Outstanding_Amount__c,
                                        CRS_Propeli_BDM_Mapping__c,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c, Bill_Number__c, CreatedDate, Charged_Total_Amount__c                                        
                                        FROM Invoice__c WHERE Id IN : invIdSet];
           
            
            List<Task> taskList =  [SELECT Id, Status, WhatId, OwnerId, RecordTypeId
                                    FROM  Task 
                                    WHERE WhatId IN :invIdSet AND Status != 'Completed' AND Status != 'Cancelled' AND  recordtypeid =: colTaskRecordId Limit 50000];
           
           
           

            Map<String, Task> invoiceTaskMap = new Map<String,Task>();
           
            List<Task> upsertTaskList = new List<Task>();
             Map<String, Task> invoiceTaskIds = new Map<String, Task>();
            for(Task tsk : taskList){
                System.debug(tsk.Id);
                invoiceTaskIds.put(tsk.WhatId, tsk);                 
            }
            
            
            for(Invoice__c invoice : invoiceList){
             
              if(invoiceTaskIds.containsKey(invoice.Id)){
                    if(invoiceTaskIds.get(invoice.Id).Status != 'Completed' && invoiceTaskIds.get(invoice.Id).Status != 'Cancelled'){ 
                        Task tsk = new Task();
                       
                        tsk.Id = invoiceTaskIds.get(invoice.Id).Id;
                        System.debug('tsk.Id--------->'+tsk.Id);
                         if(invoice.Collection_PropelI_BDM_Mapping__c != null){
                           if(invoice.Collection_PropelI_BDM_Mapping__c != null && invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c != invoiceTaskIds.get(invoice.Id).OwnerId){
                            tsk.OwnerId = invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c;
                            upsertTaskList.add(tsk);
                            }
                        } else if(invoice.NAM_Propeli_BDM_Mapping__c != null){
                           if( invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c != invoiceTaskIds.get(invoice.Id).OwnerId){
                            tsk.OwnerId = invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                            upsertTaskList.add(tsk);
                            } 
                        } 
                          
                        System.debug('tsk.OwnerId---->'+tsk.OwnerId);
                    }
                }else{
                   
                    //upsertTaskList.add(createTask(invoice));
                }
            }
           
         
           if (upsertTaskList.size()>0){
                Database.update(upsertTaskList,false);
            }           
      
    }
    
   public static List<Task> createCollectionTask(List<Task> invTaskList, Invoice__c invoice){
   
       List<Task> taskListToUpsert = new List<Task>();
       Task collectionTask;
       Task submissionTask;
       for(Task invTask : invTaskList){
                
            if(invTask.whatId == invoice.Id){
                if(invTask.RecordTypeId == subTaskRecordId){
                submissionTask = invTask;  
                } 
            if(invTask.RecordTypeId == colTaskRecordId){
                   
                collectionTask = invTask;
                if(collectionTask != null){
                    if(invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c != null){
                        if( invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c != collectionTask.OwnerId) {
                            collectionTask.OwnerId = invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c;
                        }
                    } else if(invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c != null){
                        if(invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c != collectionTask.OwnerId) {
                            collectionTask.OwnerId = invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                        }
                    }
                    taskListToUpsert.add(collectionTask);
                } 
            }
            }
       }
       if(submissionTask != null && submissionTask.Status == 'Completed'){
           Task createNewTask = createCollectionTask(invoice); 

           taskListToUpsert.add(createNewTask);
       }
        return taskListToUpsert;
    }
     
    //SAC-1644 | Updated by Manshi
    public static Task createCollectionTask(Invoice__c invRec){
       
        Task tsk = new task();
        tsk.subject = 'Bill Collection Task - '+ invRec.Bill_Number__c;
        tsk.recordtypeid = colTaskRecordId;
        tsk.whatid = invRec.Id;
        tsk.Priority = 'High';
        tsk.Account_Name__c = invRec.MSA_Name__c;
        tsk.ownerid = invRec.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c;
        tsk.SFX_Code__c = invRec.SFX_Code__c;
        tsk.Outstanding_Amount__c = invRec.Total_Outstanding_Amount__c;
        tsk.Billing_Branch__c = invRec.Bill_Branch__c;
        tsk.Invoice_Amount__c = invRec.Charged_Total_Amount__c;
        tsk.Billing_Level__c =  invRec.Billing_Level__c;
        tsk.Invoice_date__c = invRec.Bill_Date__c;
        if(invRec.e_Bill__c == 'Yes'){
              tsk.Submitted_Date__c = system.today();
        }
        //tsk.Customer_Category__c = invRec.SFX__r.Customer_Category__c;
        tsk.status = invRec.Out_Total_Amount__c != 0.0 ? 'Open' : 'Completed';  // SAC-719 | Deepika | IBM (If outstanding amount on Invoice is zero, complete the tasksTasks as soon as they are created )
        tsk.Automation__c = True; 
        tsk.Green_Book__c = invRec.Green_Book__c; //SAC-1550
        tsk.Description = 'Submitted To Email Ids: '+ invRec.Remarks__c +' '
               + '\nBDM Email: '+ invRec.BDM_Email_IDs__c;
        tsk.ActivityDate = date.newinstance(invRec.CreatedDate.year(), invRec.CreatedDate.month(), invRec.CreatedDate.day()).addDays(7);                 
        return tsk;
    }
    
    //SAC-484 created by Himanshi Dang
    public static void PopulateSubColBdm(List<Invoice__c> invoices){
        
        
        
            Set<String> invBillingBranchSet = new Set<String>();
            Set<String> invoicesWithAccount = new Set<String>();
            Set<String> invSubmissionBranchSet = new Set<String>();
            Set<String> invCollectionBranchSet = new Set<String>();
            Set<id> msaLevelAccounts = new set<id>();
            Map<String, List<Account>> sfxOfMSAMap = new Map<String, List<Account>>();
            
            
            if(!invoices.isEmpty()){ 
                
                for(invoice__c inv : invoices){
                   
                    invBillingBranchSet.add(inv.Bill_Branch__c);
                    invSubmissionBranchSet.add(inv.Sub_Branch_Master__c);
                    invCollectionBranchSet.add(inv.Collection_Branch__c);
                    
                    if(inv.Account__c != null){
                        invoicesWithAccount.add(inv.Account__c);
                    }
                    if(inv.Billing_Level__c == 'MSA'){
                        msaLevelAccounts.add(inv.Account__c);
                    }
                    
                }
                
                
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
                
                Map<String , PropelI_BDM_Mapping__c > subPBDMrecMAp = new Map<string,PropelI_BDM_Mapping__c>();
                Map<String , PropelI_BDM_Mapping__c > colPBDMrecMAp = new Map<string,PropelI_BDM_Mapping__c>();
                
                //Updated By - Himanshi Dang , SAC-484
                //invoices will be visible to the BDM mapped with account
                // Updated By - K SANSI, SAC-135
                // Added Submission__c=TRUE, check to get only submission BDM for submission branch
                for(PropelI_BDM_Mapping__c mapping : [Select 
                                                      Id, Name, PropelI_BDM__c,Submission__c,Collection__c,Collection_Branch__c, Submission_Branch__c, Billing_Branch__c, Account__c
                                                      from PropelI_BDM_Mapping__c 
                                                      where Account__c IN: invoicesWithAccount
                                                      /*AND Billing_Branch__c IN: invBillingBranchSet */
                                                      AND
                                                      (Submission_Branch__c IN: invSubmissionBranchSet OR Collection_Branch__c IN: invCollectionBranchSet) 
                                                      
                                                     ]){
                                                        
                                                         if(mapping.Submission__c){
                                                             //string subKey = mapping.Account__c+'-'+mapping.Billing_Branch__c+'-'+mapping.Submission_Branch__c;// Commented By KSANSI, SAC-720
                                                             string subKey = mapping.Account__c+'-'+mapping.Submission_Branch__c;
                                                            
                                                             subPBDMrecMAp.put(subKey , mapping);
                                                         }
                                                         if(mapping.Collection__c){
                                                             //String ColKey = mapping.Account__c+'-'+mapping.Billing_Branch__c+'-'+mapping.Collection_Branch__c;// Commented By KSANSI, SAC-720
                                                             String ColKey = mapping.Account__c+'-'+mapping.Collection_Branch__c;
                                                             
                                                             colPBDMrecMAp.put(ColKey , mapping);
                                                         }
                                                         
                                                         
                                                     }
                
                
                for(invoice__c inv: invoices){
                    Boolean submissionExist = false;
                    Boolean collectionExist = false;
                    //String uniqueKey = inv.Account__c+'-'+inv.Bill_Branch__c+'-'+inv.Sub_Branch_Master__c;// Commented By KSANSI, SAC-720
                    String uniqueKey = inv.Account__c+'-'+inv.Sub_Branch_Master__c;// Commented By KSANSI, SAC-720
                    //String colUniqueKey = inv.Account__c+'-'+inv.Bill_Branch__c+'-'+inv.Collection_Branch__c;// Commented By KSANSI, SAC-720
                    
                    String colUniqueKey = inv.Account__c+'-'+inv.Collection_Branch__c;// Commented By KSANSI, SAC-720
                    
                   
                    if(inv.Billing_Level__c == 'MSA'){
                        if(sfxOfMSAMap.containsKey(inv.Account__c)){
                            
                            for(Account sfxAcc : sfxOfMSAMap.get(inv.Account__c)){
                                
                                //uniqueKey = sfxAcc.Id + '-' + inv.Bill_Branch__c + '-' + inv.Sub_Branch_Master__c;// Commented By KSANSI, SAC-720
                                uniqueKey = sfxAcc.Id + '-' + inv.Sub_Branch_Master__c;// Commented By KSANSI, SAC-720
                                //colUniqueKey = sfxAcc.Id+'-'+inv.Bill_Branch__c+'-'+inv.Collection_Branch__c;// Commented By KSANSI, SAC-720
                                colUniqueKey = sfxAcc.Id+'-'+inv.Collection_Branch__c;// Commented By KSANSI, SAC-720
                                if(subPBDMrecMAp.containsKey(uniqueKey)){  
                                    inv.Submission_propelI_BDM_Mapping__c = subPBDMrecMAp.get(uniqueKey).id;
                                 
                                    if(inv.Collection_PropelI_BDM_Mapping__c != null)
                                    {
                                       
                                        collectionExist= true;
                                        break;                                    
                                    }
                                    
                                }
                                if(colPBDMrecMAp.containsKey(coluniqueKey)){
                                    inv.Collection_PropelI_BDM_Mapping__c = colPBDMrecMAp.get(coluniqueKey).id;
                                   
                                    if(inv.Submission_propelI_BDM_Mapping__c != null){
                                        
                                        submissionExist = true;
                                        break;
                                    }
                                    
                                }
                                
                            }
                            
                            
                        }
                    }
                    else {
                        if(subPBDMrecMAp.containsKey(uniqueKey)){  
                            submissionExist = true;
                            inv.Submission_propelI_BDM_Mapping__c = subPBDMrecMAp.get(uniqueKey).id;
                          
                            
                        }
                        if(colPBDMrecMAp.containsKey(coluniqueKey)){
                            collectionExist = true;
                            inv.Collection_PropelI_BDM_Mapping__c = colPBDMrecMAp.get(coluniqueKey).id;
                           
                            
                        }
                    }
                   
                    if(!submissionExist){
                        inv.Submission_propelI_BDM_Mapping__c=null;
                    }
                    if(!collectionExist){
                        inv.Collection_PropelI_BDM_Mapping__c =null;
                    }
                }
            } 
            
       
    }
    
    // SAC-534 created by Himanshi dang
    public static void populateRelationBDM(List<Invoice__c> invoices){
        
            Set<String> invMsaCode = new Set<String> ();
            Map<String,Id> namId = new Map<String,Id> ();
            Map<String,Id> qrmID = new Map<String,Id> ();
            Map<String,Id> crsId = new Map<String,Id> ();
            for(Invoice__c inv: invoices){
                invMsaCode.add(inv.MSA__c);
                
            }
            for(PropelI_BDM_Mapping__c mapping : [Select Id,CRS__c,QRM__c, Name,Local_NAM__c, Account__c,MSA__c
                                                  from PropelI_BDM_Mapping__c 
                                                  where MSA__c IN: invMsaCode AND (CRS__c=TRUE OR QRM__c=TRUE OR Local_NAM__c=TRUE)]){
                                                      
                                                      if (mapping.Local_NAM__c){
                                                          namId.put(mapping.MSA__c,mapping.Id);
                                                      }
                                                      else if (mapping.QRM__c){
                                                          qrmID.put(mapping.MSA__c,mapping.Id);
                                                      }
                                                      else if (mapping.CRS__c){
                                                          crsId.put(mapping.MSA__c,mapping.Id);
                                                      }                                    
                                                      
                                                  }
            for(Invoice__c inv : invoices){
                if (namId.containsKey(inv.MSA__c)){
                    inv.NAM_Propeli_BDM_Mapping__c = namId.get(inv.MSA__c);
                }
                if (qrmID.containsKey(inv.MSA__c)){
                    inv.QRM_Propeli_BDM_Mapping__c = qrmID.get(inv.MSA__c);
                }
                if (crsId.containsKey(inv.MSA__c)){
                    inv.CRS_Propeli_BDM_Mapping__c = crsId.get(inv.MSA__c);
                }
                
            }
                
    }

    //added by abhishek 
    public static void handleInvoiceStatus(List<Invoice__c> triggerNew, Map<Id, Invoice__c> invOldMap){

        if(triggerNew == null || triggerNew.isEmpty()){
            return;
        }

        for(Invoice__c inv : triggerNew){

            Invoice__c oldInv = (invOldMap != null) ? invOldMap.get(inv.Id) : null;

            // BEFORE INSERT
            if(oldInv == null){

                if(inv.e_Bill__c == 'Yes'){
                    inv.Status__c = ConstantUtility.SUBMITTED;
                    inv.Submission_Date__c = System.today();
                    
                    if(inv.Total_Outstanding_Amount__c <= 1){
                        inv.Status__c = ConstantUtility.COLLECTED;
                    }
                } else if(inv.Total_Outstanding_Amount__c <= 1){
                    inv.Status__c = ConstantUtility.COLLECTED;

                } else if(inv.Total_Outstanding_Amount__c > 1 &&
                        inv.Total_Outstanding_Amount__c < inv.Charged_Total_Amount__c){
                    inv.Status__c = ConstantUtility.PARTLY_COLLECTED;
                } else {
                    inv.Status__c = ConstantUtility.ACTIVE;
                }

            }
            // BEFORE UPDATE
            else{

                Boolean isOutstandingChanged = 
                    oldInv.Total_Outstanding_Amount__c != inv.Total_Outstanding_Amount__c;

                if(inv.Submission_Date__c != null && oldInv.Submission_Date__c == null && oldInv.Status__c != ConstantUtility.COLLECTED && oldInv.Status__c != ConstantUtility.PARTLY_COLLECTED){

                    inv.Status__c = ConstantUtility.SUBMITTED;

                }else if(inv.Total_Outstanding_Amount__c <= 1 && isOutstandingChanged){

                    inv.Status__c = ConstantUtility.COLLECTED;

                }else if(inv.Total_Outstanding_Amount__c > 1 &&
                        inv.Total_Outstanding_Amount__c < inv.Charged_Total_Amount__c &&
                        isOutstandingChanged){

                    inv.Status__c = ConstantUtility.PARTLY_COLLECTED;
                }
            }
        }
    }

    public static void handleCancelInvoiceSubAndCollTask(Set<Id> invIdSet){
        try{
            List<Task> taskListToUpdate = new List<Task>();
            for(Task tsk : [SELECT Id, Status, Subject, WhatId, Remarks__c FROM Task WHERE WhatId IN :invIdSet AND RecordTypeId IN : new Set<Id>{subTaskRecordId, colTaskRecordId} AND Status != 'Cancelled']){
                tsk.ValidationBypassDateTime__c = System.now();
                if(tsk.Status != 'Completed') {
                    tsk.Status = 'Cancelled';
                    tsk.Subject = tsk.Subject + ' (Cancelled)';
                }
                if(tsk.Remarks__c == null || !tsk.Remarks__c.contains(ConstantUtility.CANCELLED_TASK_REMARKS)) {
                    tsk.Remarks__c = tsk.Remarks__c != null
                    ? tsk.Remarks__c + ' ' + ConstantUtility.CANCELLED_TASK_REMARKS
                    : ConstantUtility.CANCELLED_TASK_REMARKS;
                    taskListToUpdate.add(tsk);
                }
            }
            if(!taskListToUpdate.isEmpty()){
                TriggerUtility.byPassTrigger = true;
                Database.update(taskListToUpdate, false);
            }
        } catch(Exception e) { 
            ExceptionHandling.Exception( 'cancelInvoiceSubAndCollecitonTask', 'invoiceTriggerHelper', e);  
        }
    }
    
    //SAC-484 created by Himanshi Dang
    @future
    public static void createInvShareRec(Set<id> invIdSet){
       
        
            
            List<Invoice__Share> lstInvShare = new List<Invoice__Share>();
            Map<String, Set<String>> userInvoiceMap = new Map<String, Set<String>>();
            List<Invoice__c> invoiceList = [SELECT Id,MSA_Name__c, Out_Total_Amount__c, Account__r.Parent.Name,Green_Book__c,
                                            Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,
                                            Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c ,
                                            NAM_Propeli_BDM_Mapping__c,NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                                            QRM_Propeli_BDM_Mapping__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                                            CRS_Propeli_BDM_Mapping__c,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c                                        
                                            FROM invoice__c WHERE Id IN : invIdSet];
            
            for(Invoice__c invoice : invoiceList){
                if(invoice.Submission_propelI_BDM_Mapping__c != null && invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c != null){
                    String submissionUser = invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, submissionUser)); 
                    if(!userInvoiceMap.containsKey(submissionUser)){
                        userInvoiceMap.put(submissionUser, new Set<String>());
                    }
                    userInvoiceMap.get(submissionUser).add(invoice.Id);
                }
                if(invoice.Collection_PropelI_BDM_Mapping__c != null && invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c != null){
                    String collectionUser = invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, collectionUser)); 
                    if(!userInvoiceMap.containsKey(collectionUser)){
                        userInvoiceMap.put(collectionUser, new Set<String>());
                    }
                    userInvoiceMap.get(collectionUser).add(invoice.Id);                    
                }
                if(invoice.NAM_Propeli_BDM_Mapping__c != null && invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c != null){
                    
                    String namUser = invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, namUser)); 
                    if(!userInvoiceMap.containsKey(namUser)){
                        userInvoiceMap.put(namUser, new Set<String>());
                    }
                    userInvoiceMap.get(namUser).add(invoice.Id);                    
                }
                if(invoice.QRM_Propeli_BDM_Mapping__c != null && invoice.QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c != null){
                    String qrmUser = invoice.QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, qrmUser)); 
                    if(!userInvoiceMap.containsKey(qrmUser)){
                        userInvoiceMap.put(qrmUser, new Set<String>());
                    }
                    userInvoiceMap.get(qrmUser).add(invoice.Id);                                    
                }
                if(invoice.CRS_Propeli_BDM_Mapping__c != null && invoice.CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c != null){
                    String crsUser = invoice.CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, crsUser)); 
                    if(!userInvoiceMap.containsKey(crsUser)){
                        userInvoiceMap.put(crsUser, new Set<String>());
                    }
                    userInvoiceMap.get(crsUser).add(invoice.Id);                     
                }
            }
           
            if (lstInvShare.size()>0){
                //insert lstInvShare;
                Database.SaveResult[] results = Database.insert(lstInvShare, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                       
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'createInvShareRec', 'invoiceTriggerHelper', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage() + ' user-invoice-map : '+String.valueOf(JSON.serialize(userInvoiceMap))); 
                        }
                    }
                }
            }
            
       
        
    }
    
    public static invoice__share invShareRec(String invId, String invUserId){         
        invoice__share invShareRec = new invoice__share();               
        invShareRec.ParentId= invId ;
        invShareRec.AccessLevel='Read';
        invShareRec.RowCause = 'Manual';
        invShareRec.UserOrGroupId = invUserId;
       
        return invShareRec;                
    }
  
    // its created for run from Batch to give invoice access, for issues    
    public static void createInvShareRec(Set<id> invIdSet, String fromBatch){
       
        
            
            List<Invoice__Share> lstInvShare = new List<Invoice__Share>();
            Map<String, Set<String>> userInvoiceMap = new Map<String, Set<String>>();
            List<Invoice__c> invoiceList = [SELECT Id, MSA_Name__c,Out_Total_Amount__c, Account__r.Parent.Name,Green_Book__c,
                                            Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,
                                            Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c ,
                                            NAM_Propeli_BDM_Mapping__c,NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                                            QRM_Propeli_BDM_Mapping__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                                            CRS_Propeli_BDM_Mapping__c,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c                                        
                                            FROM invoice__c WHERE Id IN : invIdSet];
            
            for(Invoice__c invoice : invoiceList){
                if(invoice.Submission_propelI_BDM_Mapping__c != null && invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c != null){
                    String submissionUser = invoice.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, submissionUser)); 
                    if(!userInvoiceMap.containsKey(submissionUser)){
                        userInvoiceMap.put(submissionUser, new Set<String>());
                    }
                    userInvoiceMap.get(submissionUser).add(invoice.Id);
                }
                if(invoice.Collection_PropelI_BDM_Mapping__c != null && invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c != null){
                    String collectionUser = invoice.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, collectionUser)); 
                    if(!userInvoiceMap.containsKey(collectionUser)){
                        userInvoiceMap.put(collectionUser, new Set<String>());
                    }
                    userInvoiceMap.get(collectionUser).add(invoice.Id);                    
                }
                if(invoice.NAM_Propeli_BDM_Mapping__c != null && invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c != null){
                    
                    String namUser = invoice.NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, namUser)); 
                    if(!userInvoiceMap.containsKey(namUser)){
                        userInvoiceMap.put(namUser, new Set<String>());
                    }
                    userInvoiceMap.get(namUser).add(invoice.Id);                    
                }
                if(invoice.QRM_Propeli_BDM_Mapping__c != null && invoice.QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c != null){
                    String qrmUser = invoice.QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, qrmUser)); 
                    if(!userInvoiceMap.containsKey(qrmUser)){
                        userInvoiceMap.put(qrmUser, new Set<String>());
                    }
                    userInvoiceMap.get(qrmUser).add(invoice.Id);                                    
                }
                if(invoice.CRS_Propeli_BDM_Mapping__c != null && invoice.CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c != null){
                    String crsUser = invoice.CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c;
                    lstInvShare.add(invShareRec( invoice.Id, crsUser)); 
                    if(!userInvoiceMap.containsKey(crsUser)){
                        userInvoiceMap.put(crsUser, new Set<String>());
                    }
                    userInvoiceMap.get(crsUser).add(invoice.Id);                     
                }
            }
           
            if (lstInvShare.size()>0){
                //insert lstInvShare;
                Database.SaveResult[] results = Database.insert(lstInvShare, false);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            ExceptionHandling.Exception( 'createInvShareRec', 'invoiceTriggerHelper', 'Error Status : ' + error.getStatusCode() + ' : ' + 'Error Fields : ' + error.getFields()+' message : '+error.getMessage() + ' user-invoice-map : '+String.valueOf(JSON.serialize(userInvoiceMap))); 
                          
                        }
                    }
                }
            }
            
       
        
    }
    
    public static void deleteInvShare (list<invoice__c> invList){
       
        Map<Id,Set<Id>> invToBDM = invToUserid(invList);
        string invToBdmJson = json.serialize(invToBDM);
        
        shareUtility.deleteInvShare(invToBdmJson);
      
        
    }
    
    /*SAC-515 created by Deepika Thakur
Method to update Total_Number_Of_Invoices__c and Total_Outstanding_Amount__c on Account object 
whenever the Invoice gets updated or created*/
    
  /*  Public static void updateAccount(Set<Id> accountSet) {
        List<Account> listAccount = [SELECT Id, Name, Total_Number_Of_Invoices__c, Total_Outstanding_Amount__c,
                                     (SELECT Id, Name, Total_Outstanding_Amount__c FROM Invoices__r WHERE Status_LID__c = 292) 
                                     FROM Account WHERE Id IN : accountSet];
        List<Account> accToUpate = new List<Account>();
        for (Account acc : listAccount) { 
            if(acc.Invoices__r.size() > 0){
                acc.Total_Number_Of_Invoices__c = acc.Invoices__r.size();
                
                Decimal totalOutstanding = 0;
                for(Invoice__c invoice : acc.Invoices__r){ 
                    totalOutstanding += invoice.Total_Outstanding_Amount__c;
                }
                acc.Total_Outstanding_Amount__c = totalOutstanding;
                accToUpate.add(acc);
            }
        }   
       
            if(accToUpate.size() > 0){
                update listAccount;
            }
            
        
    }*/
    
    // SAC-719 | Deepika | IBM
   // SAC-1644 | Updated by Manshi | IBM
    Public static List<Task> getTasksList(List<invoice__c> invoiceList){
       
        List<Task> collectionTasks = new List<Task>();
        for (invoice__c inv : invoiceList) {
            if(inv.e_Bill__c == 'Yes' || inv.Out_Total_Amount__c== 0.0 ){ 
                collectionTasks.add(createCollectionTask(inv));
            }
        }
        return collectionTasks;
    }
    
    
    /*Description: Updating the BLI on Invoice 
* author : Tarun Sachdeva
* SAC-1550
*/
    Public static List<invoice__c> setLookupBLI(List<invoice__c> invoiceList, Map<Id,Invoice__c> mapOfOldInvoices){
       
        
            Set<Id> branchId = new Set<Id>();
            Set<String> sFXCode = new Set<String>();
            Map<String, String> mapBliToInvoice = new Map<String,String>();
            
            Set<Id> checkInv = new set<Id>();
            for (invoice__c inv : invoiceList) {
                if(mapOfOldInvoices !=null){
                    if(mapOfOldInvoices.get(inv.Id).Bill_Branch__c == inv.Bill_Branch__c && mapOfOldInvoices.get(inv.Id).Customer_Contract_Code__c == inv.Customer_Contract_Code__c){
                        checkInv.add(inv.Id);
                    }
                }
                if(inv.Billing_Level__c == ConstantUtility.Billing_Level_SFX || inv.Billing_Level__c == ConstantUtility.Billing_Level_RC ){
                    if (inv.Account__c != null && inv.Bill_Branch__c != null) {
                        branchId.add(inv.Bill_Branch__c);
                        sFXCode.add(inv.Customer_Contract_Code__c);
                        
                    }
                }
                
            }
            
            List<Billing_Line_Item__c> lstOfBli =[Select id ,Billing_Branch__c,SFX_Code__c,Billing_Information__r.IsActive__c,Billing_Information__r.Billing_Level__c,Billing_Information__r.Rate_Card_no__c,Billing_Information__r.SFX__c,Billing_Information__r.SFX__r.ParentId from Billing_Line_Item__c where (Billing_Branch__c IN :branchId And SFX_Code__c IN :sFXCode) And IsActive__c =True];
           
            Map<Id,String> mapOfRC = new Map<Id,String>();
            Map<Id,String> checkBillInfoActive = new Map<Id,String>();
            Set<String> rCNo = new Set<String>();
            for (Billing_Line_Item__c eachbli : lstOfBli) {
                rCNo.add(eachbli.Billing_Information__r.Rate_Card_no__c);
                
            }
            List<Account> lstOfRC =[Select id ,name,recordtype.Name from Account where name IN :rCNo and recordtype.Name ='Rate card'];
            for(Account acc :lstOfRC){
                mapOfRC.put(acc.Id,acc.Name);
            }
          
            for (Billing_Line_Item__c bli : lstOfBli) {
                String compositeKey = bli.Billing_Information__r.Billing_Level__c == 'Rate Card' ? bli.Billing_Branch__c + '-' + bli.SFX_Code__c + '-' +bli.Billing_Information__r.Rate_Card_no__c : bli.Billing_Branch__c + '-' + bli.SFX_Code__c;
                mapBliToInvoice.put(compositeKey,bli.Id);
                checkBillInfoActive.put(bli.id,String.ValueOf(bli.Billing_Information__r.IsActive__c));
                
            }
            
            List<invoice__c> updInvoice = new List<invoice__c>();
            for (invoice__c inv : invoiceList) {
                Boolean isRun = !checkInv.contains(inv.id)?True:False;
                if(isRun){            
                    String compositeKey = inv.Billing_Level__c == ConstantUtility.Billing_Level_RC && mapOfRC.containsKey(inv.Account__c)? inv.Bill_Branch__c + '-' + inv.Customer_Contract_Code__c + '-' + mapOfRC.get(inv.Account__c) : inv.Bill_Branch__c + '-' + inv.Customer_Contract_Code__c;
                    
                    if (mapBliToInvoice.containsKey(compositeKey)) {
                        inv.Billing_Line_Item__c = (checkBillInfoActive.get(mapBliToInvoice.get(compositeKey))).toLowerCase()=='true'? mapBliToInvoice.get(compositeKey):null;
                        
                        updInvoice.add(inv); 
                    }
                    else{
                        inv.Billing_Line_Item__c = null;
                    }
                } 
            }
            return updInvoice;
        
    }
    /*Description: Updating the GB on Task 
* author : Tarun Sachdeva
* SAC-1550
*/
    Public static void updateGBOnTask(List<invoice__c> invList,Map<Id,invoice__c> mapOfInv){
        
        
            Map<Id,String> mapOfGB = new Map<Id,String>();
            Set<Id> invId = new Set<Id>();
            Set<Id> isChangeGB = new Set<Id>();
            for (Invoice__c inv : invList) {
                invId.add(inv.Id);
                if(mapOfInv != null && mapOfInv.get(inv.Id).Billing_Line_Item__c == inv.Billing_Line_Item__c){
                    isChangeGB.add(inv.Id);
                }
                mapOfGB.put(inv.Id,inv.Green_Book__c);
            }
            List<Task> lstOfTask =[Select id, whatId,Green_Book__c from Task where whatId IN :invId];
            List<Task> updTask = new  List<Task>();
            for (Task tsk : lstOfTask) {
                Boolean isRun = !isChangeGB.contains(tsk.whatId)?True:False;
                if(isRun){
                    if(mapOfGB.containsKey(tsk.whatId)){ 
                        tsk.Green_Book__c = mapOfGB.get(tsk.whatId) !=null ? mapOfGB.get(tsk.whatId):null;
                        updTask.add(tsk);
                    }
                }
            }
            if(!updTask.isEmpty())
                update updTask;
        
    }
    
    // Coverage booster method


}