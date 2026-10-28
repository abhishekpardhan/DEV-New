/** 
 * Description      :   Trigger on PropelI_BDM_Mapping__c object to perform various tasks upon different DML Operations by calling helper class methods.
 * Last Changed     :   22,March,2024
 * Author           :   Raghav, IBM
 * Release          :   
 * JIRA Ticket		:	https://safexpress.atlassian.net/browse/SAC-507
 * Coverage			:   100%
 * Revision Logs    :   
 **/

trigger BDMMappingTrigger on PropelI_BDM_Mapping__c (before delete, after insert, after update, after delete, after undelete) {
   
         // Added by Raghav for Story : SAC - 484
        
    switch on trigger.operationType{
        when BEFORE_DELETE {
            BDMMappingTriggerHandler.changeInvShare(trigger.old);
        }
        // END change SAC - 484
        when AFTER_INSERT{
          //  cls_PropelIActiveCodeReport.handlePropelIActiveInactiveCodes(trigger.new, trigger.old, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
            List<PropelI_BDM_Mapping__c> lstBDMSubCol = new List<PropelI_BDM_Mapping__c> ();
            List<PropelI_BDM_Mapping__c> lstBDMRel = new List<PropelI_BDM_Mapping__c> ();
            // START changes SAC 484
            for (PropelI_BDM_Mapping__c pbmrecord : trigger.new ){
                boolean subCol = (pbmrecord.Submission__c || pbmrecord.Collection__c) ? true : false ;
                boolean relNat = pbmrecord.Local_NAM__c || pbmrecord.QRM__c || pbmrecord.CRS__c  ;
                if(subCol){
                    lstBDMSubCol.add(pbmrecord);
                }
                else if (relNat){
                    lstBDMRel.add(pbmrecord);
                }
                
            }
            list<Invoice__c> invoiceTobeUpdated = new list<invoice__c>();
            //list<Invoice__c> updateInvoiceListSubColl = new list<Invoice__c>();
            list<Invoice__c> updateInvoiceListRel = new list<invoice__c>();
            if(lstBDMSubCol.size()>0){
                BDMMappingTriggerHandler.updateInvoiceSubmissionCollectionInsert(lstBDMSubCol);
                //updateInvoiceListSubColl = BDMMappingTriggerHandler.updateInvoiceSubColl(lstBDMSubCol);
            }
            if(lstBDMRel.size()>0){
               updateInvoiceListRel =   BDMMappingTriggerHandler.updateInvoiceRel(lstBDMRel);  
            }
            //if(updateInvoiceListSubColl.size()>0){
            //    invoiceTobeUpdated.addAll(updateInvoiceListSubColl);
            //}
            if(updateInvoiceListRel.size()>0)
                invoiceTobeUpdated.addAll(updateInvoiceListRel);
                
            if(invoiceTobeUpdated.size() >0)
                update invoiceTobeUpdated;    
            
        }
        when AFTER_UPDATE{
           // cls_PropelIActiveCodeReport.handlePropelIActiveInactiveCodes(trigger.new, trigger.old, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
            
            List<PropelI_BDM_Mapping__c> removeInvoiceBDM = new List<PropelI_BDM_Mapping__c> ();
            List<PropelI_BDM_Mapping__c> updateInvoiceBDM = new List<PropelI_BDM_Mapping__c> ();
            List<PropelI_BDM_Mapping__c> pbmChangedBDM = new List<PropelI_BDM_Mapping__c> ();
            List<PropelI_BDM_Mapping__c> pbmOldChangedBDM = new List<PropelI_BDM_Mapping__c> ();
            
            for (PropelI_BDM_Mapping__c pbmrecord : trigger.new ){
                
                // for remove invoice if submission or collection branch is un-checked
                /*if(
                    (!pbmrecord.Submission__c && Trigger.oldMap.get(pbmrecord.Id).Submission__c) || 
                  	(!pbmrecord.Collection__c && Trigger.oldMap.get(pbmrecord.Id).Collection__c)
                  ){
                    removeInvoiceBDM.add(pbmrecord);
                }*/
                
                // for update invoices, if submission or collection or billing branch is changed
                // if(  
                //     (pbmrecord.Submission__c != Trigger.oldMap.get(pbmrecord.Id).Submission__c) || 
                //   	(pbmrecord.Collection__c != Trigger.oldMap.get(pbmrecord.Id).Collection__c)
                //   ){
                //       system.debug('inside if');
                //       updateInvoiceBDM.add(pbmrecord);
                //   }
                updateInvoiceBDM.add(pbmrecord);
                System.debug('pbmrecord.Id'+pbmrecord.Id);
                System.debug('pbmChangedBDM-->'+pbmrecord.PropelI_BDM__c );
                    System.debug('pbmChangedBDM-->'+Trigger.oldMap.get(pbmrecord.Id).PropelI_BDM__c );
                // if PBM is change, transfer of rights 
                if(pbmrecord.PropelI_BDM__c != Trigger.oldMap.get(pbmrecord.Id).PropelI_BDM__c){
                    System.debug('pbmChangedBDM');
                   
                    pbmChangedBDM.add(pbmrecord);
                    pbmOldChangedBDM.add(Trigger.oldMap.get(pbmrecord.Id));
                }
                
            }
            //if(removeInvoiceBDM.size() > 0){
                //BDMMappingTriggerHandler.removInvoice(removeInvoiceBDM);
            //}
            if(updateInvoiceBDM.size() > 0){
                //BDMMappingTriggerHandler.updateInvoiceSubColl(updateInvoiceBDM);
                BDMMappingTriggerHandler.updateInvoiceSubmissionCollectionUpdate(updateInvoiceBDM, Trigger.oldMap);
            } 
            System.debug('pbmChangedBDM-->'+pbmChangedBDM);
            if(pbmChangedBDM.size() > 0){
            	Map<Id,Invoice__c> invoiceMap = new Map<Id,Invoice__c>([Select Id FROM Invoice__c WHERE 
                                                Submission_propelI_BDM_Mapping__c IN : pbmChangedBDM OR
                                                Collection_PropelI_BDM_Mapping__c IN : pbmChangedBDM OR
                                                NAM_Propeli_BDM_Mapping__c IN : pbmChangedBDM
                                               ]);
                
                // delete invoice share records
                    System.debug('invoiceMap'+invoiceMap);
                {
                    Map<Id,Set<Id>> invToBDM = BDMMappingTriggerHandler.invToBDMMapping(pbmOldChangedBDM);
                    string invToBdmJson = json.serialize(invToBDM);
                    shareUtility.deleteInvShare(invToBdmJson);                    
                }

                // create invoice share records

                if(invoiceMap.size() > 0 ){
                    System.debug('Iaamherebdmmappingtriggerhandlertaskupdate');
                    invoiceTriggerHelper.createInvShareRec(invoiceMap.keySet());
                    invoiceTriggerHelper.updateDebitTask(invoiceMap.keySet());
                    invoiceTriggerHelper.updateSubmissionTask(invoiceMap.keySet());
                    invoiceTriggerHelper.updateCollectionTask(invoiceMap.keySet());
                }                
            }            
            
        }
        when AFTER_DELETE{
         // cls_PropelIActiveCodeReport.handlePropelIActiveInactiveCodes(trigger.new, trigger.old, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
        }
    }
    
    
}