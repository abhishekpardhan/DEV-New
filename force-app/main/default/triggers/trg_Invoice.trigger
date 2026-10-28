/**
* Description      :   Trigger on Invoice__c object to perform various tasks upon different DML Operations by calling helper class methods
* 
* 
* Revision Logs    :   V_1.0 - Created
* Ver         Date                     Author                   Modification
* 1.0        12-03-2026                Abhishek pardhan         Added the Logic to update the status of invoice as per the outstanding amount 
                                                                and also added the logic to update the submission date when status changes to submitted. (SAC-1901)
**/
trigger trg_Invoice on Invoice__c (after insert,after update,before update , before insert) {
    
    //Checking trigger switch values
    if(TriggerUtility.byPassTrigger) return ;
    if(System.Label.TriggerSwitch.equals('On')){
        Set<Id> invoiceIds = new Set<Id>();
        List<invoice__c> lstInv = new List<invoice__c>();
        List<Id> lstId = new List<Id>();
        Set<Id> accountSet = new Set <Id>();
        // Updated by Himanshi START changes SAC- 484
        switch on trigger.operationType{
            when BEFORE_INSERT{
                invoiceTriggerHelper.PopulateSubColBdm(Trigger.new);
                invoiceTriggerHelper.populateRelationBDM(Trigger.new);
                invoiceTriggerHelper.setLookupBLI(trigger.new,trigger.oldMap); //SAC-1550
                invoiceTriggerHelper.handleInvoiceStatus(trigger.new, trigger.oldMap); // Changes as per SAC- 1901
            }
            // END changes SAC- 484
            when AFTER_INSERT{
                // SAC-147 - updated by K SANSI - IBM, invoiceTriggerHelper.createSubmissionTask method is not needed 2 parameter, so removed from its invoke
               
                try{
                    Map<id , invoice__c> subTask = new  Map<id , invoice__c> ();
                     Map<id, invoice__c> autoClosedInvoice = new Map<Id, invoice__c>();
                     for(invoice__c inv : trigger.new){
                        // Changes as per SAC - 1770
                        /*if(inv.BDM_Email_IDs__c == null){
                            inv.addError('BDM Email Ids cannot be blank');    // Changes as per SAC-2310
                        }*/
                        Decimal amount = inv.Charged_Freight_Amount__c + inv.Charged_ST_Amount__c;
                     System.debug('amount >>' + amount);
                     System.debug('Out_Total_Amount__c >>' + inv.Out_Total_Amount__c);
                     System.debug('e_Bill__c >>' + inv.e_Bill__c);
                        if(inv.Out_Total_Amount__c != 0 && amount >= inv.Out_Total_Amount__c && inv.e_Bill__c=='No'){
                            System.debug('Ebiloinvoice create');
                            if(inv.Submission_propelI_BDM_Mapping__c != null){
                                 System.debug('inv.Submission_propelI_BDM_Mapping__c'+inv.Submission_propelI_BDM_Mapping__c);
                                subTask.put(inv.id ,inv);
                            }else if(inv.Collection_PropelI_BDM_Mapping__c != null){ 
                                 System.debug('inv.Submission_propelI_BDM_Mapping__c'+inv.Submission_propelI_BDM_Mapping__c);
                                subTask.put(inv.id ,inv);
                            }else if(inv.NAM_Propeli_BDM_Mapping__c != null){
                                 System.debug('inv.Submission_propelI_BDM_Mapping__c'+inv.Submission_propelI_BDM_Mapping__c);
                                subTask.put(inv.id ,inv);
                            }
                            
                        }else if(inv.Out_Total_Amount__c == 0 || inv.e_Bill__c == 'Yes'){
                            System.debug('ebillyes');
   
                             autoClosedInvoice.put(inv.id ,inv);
                            
                            if(inv.Status_LID__c == 292){                         
                                accountSet.add(inv.Account__c);
                            }
                        }
                    }
                    if(!accountSet.isEmpty()){
                       // invoiceTriggerHelper.updateAccount(accountSet);
                    }
                    // START changes SAC - 484
                    invoiceTriggerHelper.createInvShareRec(Trigger.newMap.KeySet());  
                   // invoiceTriggerHelper.createSubmissionTask(Trigger.newMap);
                   // chnage updated by himanshi
                   
                    if(!subTask.isEmpty()){
                        invoiceTriggerHelper.createSubmissionTask(subTask);
                   }
                   if(!autoClosedInvoice.values().isEmpty()){
                    
                        invoiceTriggerHelper.autoClosedInvoice(autoClosedInvoice);
                    }
                  // End changes SAC - 484
                }catch(Exception e){
                    system.debug('Exception After insert:'+e.getMessage()+e.getLineNumber());
                    ExceptionHandling.Exception('Afterinsert', 'trg_Invoice', e);
                }
              invoiceTriggerHelper.updateGBOnTask(trigger.new,trigger.oldMap);
            }
            when BEFORE_UPDATE{
                //Updated by Himanshi , SAC-484
                List<invoice__c> lstInvoice = new List<invoice__c>();
                
                for(Invoice__c inv : Trigger.new){
                    invoice__c oldInvRec = Trigger.oldMap.get(inv.Id);
                    if((oldInvRec.Sub_Branch_Master__c != inv.Sub_Branch_Master__c || oldInvRec.Collection_Branch__c !=inv.Collection_Branch__c ||
                        oldInvRec.Bill_Branch__c != inv.Bill_Branch__c || oldInvRec.Account__c !=inv.Account__c)){
                            lstInvoice.add(inv);
                        }
                    // Changes as per SAC- 1901
                }
                invoiceTriggerHelper.handleInvoiceStatus(trigger.new, trigger.oldMap);

                if(lstInvoice.size() > 0)
                    invoiceTriggerHelper.PopulateSubColBdm(lstInvoice);
                
                
               invoiceTriggerHelper.setLookupBLI(trigger.new,trigger.oldMap); //SAC-1550
            }
            when AFTER_UPDATE{
                try{ // Added by Raghav
                   
                    Set<id> subInvIdSet = new Set<id>();
                    Set<id> colInvIdSet = new Set<id>();
                    Set<id> namUpdatedInvIdSet = new Set<id>();
                    Set<Id> cancelledInvoiceIds = new Set<Id>();
                    Set<id> namInvIdSet = new Set<id>();  // Changes as per SAC - 1770
                    List<invoice__c> invIdOldSet = new list<invoice__c>();
                    Set<id> invIdNewSet = new Set<id>();
                    for(invoice__c inv: trigger.new){
                       
                        invoice__c oldInvRec = Trigger.oldMap.get(inv.Id);
                        if(inv.Status__c == 'Cancelled' &&
                            oldInvRec.Status__c != 'Cancelled' && !System.isBatch()){
                            cancelledInvoiceIds.add(inv.Id);
                        } else {
                        if(oldInvRec.Submission_propelI_BDM_Mapping__c != inv.Submission_propelI_BDM_Mapping__c  ){
                            invIdNewSet.add(inv.id);
                             if(inv.Submission_propelI_BDM_Mapping__c == null){
                                if(inv.Collection_PropelI_BDM_Mapping__c != null){
                                    subInvIdSet.add(inv.id);
                                }else if(inv.NAM_Propeli_BDM_Mapping__c != null){
                                    subInvIdSet.add(inv.id);
                                }
                            }else{
                                subInvIdSet.add(inv.id);
                            }
                            if(oldInvRec.Submission_propelI_BDM_Mapping__c!=null){
                                invIdOldSet.add(oldInvRec);
                            }
                        }

                        if(oldInvRec.Collection_PropelI_BDM_Mapping__c != inv.Collection_PropelI_BDM_Mapping__c ){
                            invIdNewSet.add(inv.id);
                            if(inv.Collection_PropelI_BDM_Mapping__c == null){
                                if(inv.NAM_Propeli_BDM_Mapping__c != null){
                                    colInvIdSet.add(inv.id);
                                }
                            }else{
                                colInvIdSet.add(inv.id);
                            }
                            //colInvIdSet.add(inv.id);
                            if(oldInvRec.Collection_PropelI_BDM_Mapping__c!=null){
                                invIdOldSet.add(oldInvRec);
                            }
                            
                        }

                         // Changes as per SAC - 177
                        if(oldInvRec.NAM_Propeli_BDM_Mapping__c != inv.NAM_Propeli_BDM_Mapping__c ){
                            invIdNewSet.add(inv.id);
                            namInvIdSet.add(inv.id);
                            if(inv.NAM_Propeli_BDM_Mapping__c != null){
                                namUpdatedInvIdSet.add(inv.id);
                            }
                                //namInvIdSet.add(inv.id);
                            if(oldInvRec.NAM_Propeli_BDM_Mapping__c!=null){
                                invIdOldSet.add(oldInvRec);
                            }         
                        }
                        if(oldInvRec.NAM_Propeli_BDM_Mapping__c != inv.NAM_Propeli_BDM_Mapping__c || 
                          oldInvRec.QRM_Propeli_BDM_Mapping__c != inv.QRM_Propeli_BDM_Mapping__c ||
                          oldInvRec.CRS_Propeli_BDM_Mapping__c != inv.CRS_Propeli_BDM_Mapping__c
                          ){
                            invIdNewSet.add(inv.id);                            
                        }
                        
                        /*To check if oustanding amount changes on invoice update*/
                        if(trigger.oldmap.get(inv.id).Out_Total_Amount__c != inv.Out_Total_Amount__c && inv.Status_LID__c == 292){
                            lstInv.add(inv);
                            lstId.add(inv.Id);
                        }
                        /*To check if total oustanding amount or status changes on invoice update*/
                        if(trigger.oldmap.get(inv.id).Status_LID__c != inv.Status_LID__c || trigger.oldmap.get(inv.id).Total_Outstanding_Amount__c != inv.Total_Outstanding_Amount__c){
                            accountSet.add(inv.Account__c);
                        }
                        /*To check if total Account changes on invoice update*/
                        if(trigger.oldmap.get(inv.id).Account__c != inv.Account__c){
                            accountSet.add(trigger.oldmap.get(inv.id).Account__c);
                            accountSet.add(inv.Account__c);
                        }
                        }
                        
                    }
                    if(invIdOldSet.size()>0){
                       invoiceTriggerHelper.deleteInvShare(invIdOldSet);
                    }
                    
                    if(!cancelledInvoiceIds.isEmpty()){
                        invoiceTriggerHelper.handleCancelInvoiceSubAndCollTask(cancelledInvoiceIds);
                    }
                    
                    if(subInvIdSet.size()>0){
                        //invoiceTriggerHelper.createSubmissionTask(Trigger.newMap);
                       invoiceTriggerHelper.updateSubmissionTask(subInvIdSet);
                       invoiceTriggerHelper.updateDebitTask(subInvIdSet);
                       
                        
                    }

                    if(namUpdatedInvIdSet.size()>0){
                        invoiceTriggerHelper.updateDebitTask(namUpdatedInvIdSet);
                        invoiceTriggerHelper.updateSubmissionTask(namUpdatedInvIdSet);
                        invoiceTriggerHelper.updateCollectionTask(namUpdatedInvIdSet);
                    }

                    if(!namInvIdSet.isEmpty()){
                        //invoiceTriggerHelper.updateNAMTask(namInvIdSet);
                    }
                    
                    if(!colInvIdSet.isEmpty()){
                        invoiceTriggerHelper.updateCollectionTask(colInvIdSet);
                        invoiceTriggerHelper.updateDebitTask(colInvIdSet);
                    }
                    if(!lstInv.isEmpty()){
                        invoiceTriggerHelper.updateInvoiceOut(lstInv,lstId,trigger.oldmap);
                    }
                    if(!accountSet.isEmpty()){
                       // invoiceTriggerHelper.updateAccount(accountSet);
                    }
                    if(invIdNewSet.size() >0){
                        invoiceTriggerHelper.createInvShareRec(invIdNewSet);
                    }
                    
                    invoiceTriggerHelper.updateGBOnTask(trigger.new,trigger.oldMap);
                }catch(Exception e){
                    system.debug('Exception update line:'+e.getMessage()+e.getLineNumber());
                    ExceptionHandling.Exception('Afterupdate', 'trg_Invoice', e);
                }
            }
            
        }
        
    }
}