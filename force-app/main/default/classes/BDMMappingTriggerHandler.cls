/** 
* Description      :   Test class for PropelI_BDM_Mapping__c trigger.
* Last Changed     :   22,March,2024
* Author           :   Raghav, IBM
* Release          :   
* JIRA Ticket	   :   https://safexpress.atlassian.net/browse/SAC-507
* Coverage		   :   92%
* Revision Logs    :   
**/
public class BDMMappingTriggerHandler {
    /*public static void handlePropelIActiveInactiveCodes(List<PropelI_BDM_Mapping__c> mappings){
List<String> msaNumbers = new List<String>();

for(PropelI_BDM_Mapping__c mapData : mappings){
if(mapData.MSA__c != null){
msaNumbers.add(mapData.MSA__c);
}
}
system.debug('msaNumbers ===> '+msaNumbers);
if(!msaNumbers.isEmpty()){
Database.executeBatch(new PropelIActiveCodeBatch(msaNumbers), 50);
}

}*/
    // Added by Raghav , IBM
    public static Map<id,Set<Id>> invToBDMMapping (List<PropelI_BDM_Mapping__c> bdmRecords){
        
        Map<String,Id> submissionBranch = new Map<String,Id> ();
        Map<String,Id> submissionBDMId = new Map<String,Id> ();
        Map<String,Id> collectionBranch = new Map<String,Id> ();
        Map<String,Id> collectionBDMId = new Map<String,Id> ();
        Map<String,Id> namId = new Map<String,Id> ();
        Map<String,Id> qrmID = new Map<String,Id> ();
        Map<String,Id> crsId = new Map<String,Id> ();
        Map<Id,Set<Id>> invToBDM = new Map<Id,Set<Id>>();
        Set<Id> acntSet = new Set<Id>();
        Set<String> MsaCodeSet = new Set<String>();
        
        for (PropelI_BDM_Mapping__c record : bdmRecords){
            if (record.Submission_Branch__c != null && record.Submission__c){
                //String subKey = record.Account__c + '-' + record.Billing_Branch__c + '-' + record.Submission_Branch__c; // Commented By KSANSI, SAC-720
                String subKey = record.Account__c + '-' + record.Submission_Branch__c;
                submissionBranch.put(subKey, record.Submission_Branch__c);
                submissionBDMId.put(subKey, record.PropelI_BDM__c);
                acntSet.add(record.Account__c);
                //String subMSAKey = record.Account__r.ParentId + '-' + record.Billing_Branch__c + '-' + record.Submission_Branch__c; // Commented By KSANSI, SAC-720
                String subMSAKey = record.Account__r.ParentId + '-' +  record.Submission_Branch__c;
                submissionBDMId.put(subMSAKey, record.PropelI_BDM__c);
                acntSet.add(record.Account__r.ParentId);
                
            }
            if (record.Collection_Branch__c != null && record.Collection__c){
                //String colKey = record.Account__c + '-' + record.Billing_Branch__c + '-' + record.Collection_Branch__c; // Commented By KSANSI, SAC-720
                String colKey = record.Account__c + '-' + record.Collection_Branch__c;
                collectionBranch.put(colKey, record.Collection_Branch__c);
                collectionBDMId.put(colKey, record.PropelI_BDM__c);
                acntSet.add(record.Account__c);
                //String colMSAKey = record.Account__r.ParentId + '-' + record.Billing_Branch__c + '-' + record.Collection_Branch__c; // Commented By KSANSI, SAC-720
                String colMSAKey = record.Account__r.ParentId + '-' + record.Collection_Branch__c;
                collectionBDMId.put(colMSAKey, record.PropelI_BDM__c);
                acntSet.add(record.Account__r.ParentId);
                
            }
            if (record.Local_NAM__c){
                MsaCodeSet.add(record.MSA__c);
                namId.put(record.MSA__c,record.PropelI_BDM__c);
                system.debug('namId Map---->'+namId);
                acntSet.add(record.Account__c);
            }
            if (record.QRM__c){
                MsaCodeSet.add(record.MSA__c);
                qrmID.put(record.MSA__c,record.PropelI_BDM__c);
                acntSet.add(record.Account__c);
            }
            if (record.CRS__c){
                System.debug('hwre in crs');
                MsaCodeSet.add(record.MSA__c);
                crsId.put(record.MSA__c,record.PropelI_BDM__c);
                System.debug('record.PropelI_BDM__c-->'+record.PropelI_BDM__c);
                acntSet.add(record.Account__c);
            }
            
            system.debug('acntSet--->'+acntSet);
            
        }
        System.debug('MsaCodeSet-->'+MsaCodeSet);
        List<Invoice__c> invList = [SELECT 
                                    Id, Account__c,Bill_Branch__c,Collection_Branch__c,Sub_Branch_Master__c ,Submission_propelI_BDM_Mapping__c,
                                    Collection_PropelI_BDM_Mapping__c , MSA__c
                                    FROM Invoice__c WHERE ( Account__c IN : acntSet OR MSA__c IN : MsaCodeSet)
                                    AND (Collection_Branch__c IN: collectionBranch.values() OR  Sub_Branch_Master__c IN:submissionBranch.values() OR MSA__c IN: MsaCodeSet) AND Status__c != :ConstantUtility.CANCELLED];
        System.debug('invList-->'+invList);
        for(Invoice__c inv : invList){
            if (!invToBDM.containsKey(inv.Id)){
                invToBDM.put(inv.Id, new Set<Id>());
                system.debug('invToBDM-->' + invToBDM);
                
            }
            //String subKeyInv = inv.Account__c + '-' + inv.Bill_Branch__c + '-' + inv.Sub_Branch_Master__c; // Commented By KSANSI, SAC-720
            String subKeyInv = inv.Account__c + '-' + inv.Sub_Branch_Master__c;
            //String colKeyInv = inv.Account__c + '-' + inv.Bill_Branch__c + '-' + inv.Collection_Branch__c; // Commented By KSANSI, SAC-720
            String colKeyInv = inv.Account__c + '-' + inv.Collection_Branch__c;
            
            if (submissionBDMId.containsKey(subKeyInv)){
                invToBDM.get(inv.Id).add(submissionBDMId.get(subKeyInv));
                system.debug('invToBDM-->' + invToBDM);
                system.debug('Sub invToBDM-->' + invToBDM.values());
                
            }
            if (collectionBDMId.containsKey(colKeyInv)){
                invToBDM.get(inv.Id).add(collectionBDMId.get(colKeyInv));
                system.debug('invToBDM-->'+invToBDM); 
            }
            if (namId.containsKey(inv.MSA__c)){
                invToBDM.get(inv.Id).add(namId.get(inv.MSA__c));
                system.debug('NAM invToBDM--->'+invToBDM);
                
            }
            if (qrmID.containsKey(inv.MSA__c)){
                invToBDM.get(inv.Id).add(qrmID.get(inv.MSA__c));
                
            }
            if (crsId.containsKey(inv.MSA__c)){
                System.debug('here 2---');
                invToBDM.get(inv.Id).add(crsId.get(inv.MSA__c));
                System.debug('here 3---');
            }
            
            
        }
        system.debug('values invToBDM-->'+invToBDM.values());
        return invToBDM;
    }
    public static void changeInvShare (List<PropelI_BDM_Mapping__c> deletedRecords){
        system.debug('entered pbdm changeInvShare method');
        Map<Id,Set<Id>> invToBDM = invToBDMMapping(deletedRecords);
        string invToBdmJson = json.serialize(invToBDM);
        system.debug('invToBdmJson===>'+invToBdmJson);
        shareUtility.deleteInvShare(invToBdmJson);
        system.debug(' shareutility delInvShare method end');
        
    }
    /*
    public static list<invoice__c> updateInvoiceSubColl (List<PropelI_BDM_Mapping__c> newRecords){
        System.debug('updateInvoiceSubColl-->'+newRecords);
        try{
            Map<String,Id> submissionBranch = new Map<String,Id> ();
            Map<String,Id> submissionId = new Map<String,Id> ();
            Map<String,Id> collectionBranch = new Map<String,Id> ();
            Map<String,Id> collectionId = new Map<String,Id> ();
           
            Set<Id> acntSet = new Set<Id>();
            newRecords = [SELECT Id, Submission_Branch__c, Submission__c, Account__c, Billing_Branch__c,
                          Account__r.ParentId, PropelI_BDM__c, Collection_Branch__c, Collection__c 
                          FROM PropelI_BDM_Mapping__c WHERE Id IN : newRecords];
            
            for (PropelI_BDM_Mapping__c record : newRecords){
                System.debug('subMSAKey newRecords-->'+newRecords);
                if (record.Submission_Branch__c!=null && record.Submission__c){
                    String subKey = record.Account__c+ '-' + record.Billing_Branch__c+'-'+record.Submission_Branch__c;
                    System.debug('subMSAKey subKey-->'+subKey);
                    submissionBranch.put(subKey,record.Submission_Branch__c);
                    submissionId.put(subKey,record.Id);
                    acntSet.add(record.Account__c);
                    String subMSAKey = record.Account__r.ParentId + '-' + record.Billing_Branch__c + '-' + record.Submission_Branch__c;
                    submissionId.put(subMSAKey, record.Id);
                    acntSet.add(record.Account__r.ParentId);
                    System.debug('subMSAKey-->'+subMSAKey);
                    System.debug('subMSAKey acntSet-->'+acntSet);
                }
                
                if (record.Collection_Branch__c!=null && record.Collection__c){
                    
                    String colKey =  record.Account__c + '-' + record.Billing_Branch__c+'-'+record.Collection_Branch__c;
                    System.debug('colMSAKey colKey-->'+colKey);
                    collectionBranch.put(colKey,record.Collection_Branch__c);
                    collectionId.put(colKey,record.Id);
                    acntSet.add(record.Account__c);
                    String colMSAKey = record.Account__r.ParentId + '-' + record.Billing_Branch__c + '-' + record.Collection_Branch__c;
                    System.debug('colMSAKey colMSAKey-->'+colMSAKey);
                    collectionId.put(colMSAKey, record.Id);
                    acntSet.add(record.Account__r.ParentId);
                    System.debug('colMSAKey collectionId-->'+collectionId);
                    System.debug('colMSAKey acntSet-->'+acntSet);
                }
                
            }
            
            System.debug('colMSAKey acntSet-->'+acntSet);
            System.debug('colMSAKey collectionBranch.values()-->'+collectionBranch.values());
            System.debug('colMSAKey submissionBranch.values()-->'+submissionBranch.values());
            List<Invoice__c> invList = new List<Invoice__c>();
            invList =[ SELECT Id, Account__c,Bill_Branch__c,Collection_Branch__c,Sub_Branch_Master__c ,Submission_propelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__c
                                       FROM Invoice__c
                                       WHERE Account__c IN: acntSet AND (Collection_Branch__c IN: collectionBranch.values() OR  Sub_Branch_Master__c IN:submissionBranch.values())];
            List<Invoice__c> invListUpdate = new List<Invoice__c>();
            Boolean updateInvoice;
            for(Invoice__c inv : invList){
                updateInvoice = false;
                System.debug('subMSAKey inv...-->'+inv);
                String subKeyInv= inv.Account__c+'-'+inv.Bill_Branch__c+'-'+inv.Sub_Branch_Master__c;
                System.debug('subMSAKey inv...-->'+subKeyInv);
                System.debug('subMSAKey subKeyInv...-->'+submissionId.get(subKeyInv));
                String colKeyInv = inv.Account__c+'-'+ inv.Bill_Branch__c+'-'+inv.Collection_Branch__c;
                System.debug('colMSAKey colKeyInv-->'+colKeyInv);
                if (submissionId.containsKey(subKeyInv)){
                    updateInvoice = true;
                    System.debug('subMSAKey here...-->'+submissionId.get(subKeyInv));
                    inv.Submission_propelI_BDM_Mapping__c =submissionId.get(subKeyInv);   
                }
                
                if (collectionId.containsKey(colKeyInv)){
                    updateInvoice = true;
                    System.debug('colMSAKey here...-->'+collectionId.get(colKeyInv));
                    inv.Collection_PropelI_BDM_Mapping__c =collectionId.get(colKeyInv);
                }
                if(updateInvoice){
                    invListUpdate.add(inv);
                }
            }
            system.debug('invList'+invList);
            if (invListUpdate.size()>0){
                update invListUpdate; 
                return invListUpdate;
            }
            return invListUpdate;
        } catch(DmlException e){
            System.debug('BDMMappingTriggerHandler.updateInvoiceSubColl is failing with '+e.getMessage());
            ExceptionHandling.Exception('updateInvoiceSubColl' , 'BDMMappingTriggerHandler', e );
            return null;
        }
        
    }
    */
    public static list<invoice__c> updateInvoiceRel(List<PropelI_BDM_Mapping__c> newRecords){
        try{
            
            Map<String,Id> namId = new Map<String,Id> ();
            Map<String,Id> qrmID = new Map<String,Id> ();
            Map<String,Id> crsId = new Map<String,Id> ();
            for (PropelI_BDM_Mapping__c record : newRecords){
                if (record.Local_NAM__c){
                    namId.put(record.MSA__c,record.Id);
                }
                else if (record.QRM__c){
                    qrmID.put(record.MSA__c,record.Id);
                }
                else if (record.CRS__c){
                    crsId.put(record.MSA__c,record.Id);
                }
            }
            List<Invoice__c> invList = new List<Invoice__c>();
            invList =[ SELECT Id, Account__c ,MSA__c
                                       FROM Invoice__c
                                       WHERE  (MSA__c IN : namId.keySet()  OR MSA__c IN : qrmID.keySet() OR MSA__c IN : crsId.keySet()) AND Status__c != :ConstantUtility.CANCELLED];
            for(Invoice__c inv : invList){
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
            system.debug('invList'+invList);
            if (invList.size()>0){
                //update invList; 
                return invList;
            }
            return invList;
        } catch(DmlException e){
            System.debug('BDMMappingTriggerHandler.updateInvoiceRel is failing with '+e.getMessage());
            ExceptionHandling.Exception('updateInvoiceRel' , 'BDMMappingTriggerHandler', e );
            return null;
        }
    }
    public static void removInvoice(List<PropelI_BDM_Mapping__c> deletedRecords){
        try{
            
            Set<Id> submissionBranchId = new Set<Id> ();
            Set<Id> collectionBranchId = new Set<Id> ();
            for (PropelI_BDM_Mapping__c record : deletedRecords){
                System.debug('record-->'+record);
                if (record.Submission_Branch__c != null && !record.Submission__c){
                    submissionBranchId.add(record.Id);
                    
                }
                if (record.Collection_Branch__c != null && !record.Collection__c){
                    collectionBranchId.add(record.Id);
                    
                }
            }
            System.debug('submissionBranchId-->'+submissionBranchId);
            System.debug('collectionBranchId-->'+collectionBranchId);
            List<Invoice__c> invList =[ SELECT 
                                       Id, Account__c,Bill_Branch__c,Collection_Branch__c,Sub_Branch_Master__c ,Submission_propelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__c
                                       FROM Invoice__c
                                       WHERE (Submission_propelI_BDM_Mapping__c IN: submissionBranchId OR  Collection_PropelI_BDM_Mapping__c IN: collectionBranchId) AND Status__c != :ConstantUtility.CANCELLED];
            for(Invoice__c inv : invList){
                System.debug('inv-->'+inv);
                System.debug('inv.Submission_propelI_BDM_Mapping__c-->'+inv.Submission_propelI_BDM_Mapping__c);
                System.debug('inv.Collection_PropelI_BDM_Mapping__c-->'+inv.Collection_PropelI_BDM_Mapping__c);
                if (submissionBranchId.contains(inv.Submission_propelI_BDM_Mapping__c)){
                    inv.Submission_propelI_BDM_Mapping__c = null;
                }
                if (collectionBranchId.contains(inv.Collection_PropelI_BDM_Mapping__c) ){
                    inv.Collection_PropelI_BDM_Mapping__c = null;
                    
                }  
                
            }
            system.debug('removeInvoice.invList-->'+invList);
            if (invList.size()>0){
                update invList;
            }
        }
        catch(DmlException e){
            System.debug('BDMMappingTriggerHandler.removeInvoice is failing with '+e.getMessage());
            ExceptionHandling.Exception('removInvoice' , 'BDMMappingTriggerHandler', e );
        }        
    }
    
    
    public static void updateInvoiceSubmissionCollectionInsert(List<PropelI_BDM_Mapping__c> newBDMList){
        system.debug('entered new method');
        Set<Id> bdmAccountSet = new Set<Id>();        
        String submissionKey;
        String collectionKey;
        Set<String> submissionBranchSet = new Set<String>();
        Map<String, PropelI_BDM_Mapping__c> submissionBDMMap = new Map<String, PropelI_BDM_Mapping__c>();        
        Set<String> collectionBranchSet = new Set<String>();
        Map<String, PropelI_BDM_Mapping__c> collectionBDMMap = new Map<String, PropelI_BDM_Mapping__c>();
        List<Invoice__c> invoiceUpdateList = new List<Invoice__c>();
        Boolean isUpdate = false;
        
        newBDMList = [SELECT Id, Submission_Branch__c, Submission__c, Account__c, Billing_Branch__c,
                          Account__r.ParentId, PropelI_BDM__c, Collection_Branch__c, Collection__c 
                          FROM PropelI_BDM_Mapping__c WHERE Id IN : newBDMList];

        System.debug('newBDMList---->'+newBDMList);    
        
        for (PropelI_BDM_Mapping__c bdmRecord : newBDMList){
            System.debug('bdmRecord-->'+bdmRecord);
            // collect all sumission branch and fill submission map with unique key
            if (bdmRecord.Submission_Branch__c != null){ 
            	//submissionKey = bdmRecord.Account__c + '-' + bdmRecord.Billing_Branch__c + '-' + bdmRecord.Submission_Branch__c; // Commented By KSANSI, SAC-720
                submissionKey = bdmRecord.Account__c + '-' + bdmRecord.Submission_Branch__c;
                
            	submissionBranchSet.add(bdmRecord.Submission_Branch__c);                
                submissionBDMMap.put(submissionKey, bdmRecord);
            }
           System.debug('bdmRecord.Collection_Branch__c-------->'+bdmRecord.Collection_Branch__c);
            // collect all collection branch and fill collection map with unique key
            if (bdmRecord.Collection_Branch__c != null){ 
                //collectionKey =  bdmRecord.Account__c + '-' + bdmRecord.Billing_Branch__c+'-' + bdmRecord.Collection_Branch__c; // Commented By KSANSI, SAC-720
                collectionKey =  bdmRecord.Account__c + '-' + bdmRecord.Collection_Branch__c;
				collectionBranchSet.add(bdmRecord.Collection_Branch__c);
                collectionBDMMap.put(collectionKey, bdmRecord);
            }
            System.debug('collectionKey-->'+collectionKey);
            // collect all accounts 
            if(bdmRecord.Submission_Branch__c != null || bdmRecord.Collection_Branch__c != null){
                bdmAccountSet.add(bdmRecord.Account__c);
                bdmAccountSet.add(bdmRecord.Account__r.ParentId);
            }            
        }
        System.debug('collectionBranchSet-->'+collectionBranchSet);
        System.debug('submissionBranchSet-->'+submissionBranchSet);
        List<Invoice__c> invList = [SELECT Id, Account__c, Bill_Branch__c, Collection_Branch__c, Sub_Branch_Master__c, Submission_propelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__c 
                                  FROM Invoice__c 
                                  WHERE Account__c IN: bdmAccountSet AND  
                                  (Collection_Branch__c IN : collectionBranchSet OR  Sub_Branch_Master__c IN : submissionBranchSet) AND Status__c != :ConstantUtility.CANCELLED];
        for(Invoice__c invoice : invList){
            System.debug('invoice-->'+invoice);                          
        	//submissionKey = invoice.Account__c + '-' + invoice.Bill_Branch__c + '-' + invoice.Sub_Branch_Master__c; // Commented By KSANSI, SAC-720
            submissionKey = invoice.Account__c + '-' + invoice.Sub_Branch_Master__c;
            //collectionKey = invoice.Account__c + '-' + invoice.Bill_Branch__c + '-' + invoice.Collection_Branch__c; // Commented By KSANSI, SAC-720
            collectionKey = invoice.Account__c + '-' + invoice.Collection_Branch__c; 
            
            System.debug('submissionKey-->'+submissionKey);  
            System.debug('collectionKey-->'+collectionKey);  
            isUpdate = false;
            if(submissionBDMMap.containsKey(submissionKey)){
                if(submissionBDMMap.get(submissionKey).Submission__c){
                    invoice.Submission_propelI_BDM_Mapping__c = submissionBDMMap.get(submissionKey).Id;
                    isUpdate = true;
                }
            }
            if(collectionBDMMap.containsKey(collectionKey)){
                System.debug('collectionKey-->'+collectionKey);  
                if(collectionBDMMap.get(collectionKey).Collection__c){
                    invoice.Collection_PropelI_BDM_Mapping__c = collectionBDMMap.get(collectionKey).Id;
                    isUpdate = true;
                }                  
            }                         
            if(isUpdate){
            	invoiceUpdateList.add(invoice);
            }                         
        }        
        if(invoiceUpdateList.size() > 0){            
            update invoiceUpdateList;
        }
                
    }
    
    public static void updateInvoiceSubmissionCollectionUpdate(List<PropelI_BDM_Mapping__c> newBDMList, Map<Id, PropelI_BDM_Mapping__c> bdmOldMap){
        
        Set<Id> bdmAccountSet = new Set<Id>();        
        String submissionKey;
        String collectionKey;
        Set<String> submissionBranchSet = new Set<String>();
        Map<String, PropelI_BDM_Mapping__c> submissionBDMMap = new Map<String, PropelI_BDM_Mapping__c>();        
        Set<String> collectionBranchSet = new Set<String>();
        Map<String, PropelI_BDM_Mapping__c> collectionBDMMap = new Map<String, PropelI_BDM_Mapping__c>();
        List<Invoice__c> invoiceUpdateList = new List<Invoice__c>();
        Boolean isUpdate = false;
        
        newBDMList = [SELECT Id, Submission_Branch__c, Submission__c, Account__c, Billing_Branch__c,
                          Account__r.ParentId, PropelI_BDM__c, Collection_Branch__c, Collection__c 
                          FROM PropelI_BDM_Mapping__c WHERE Id IN : newBDMList];        
        
        for (PropelI_BDM_Mapping__c bdmRecord : newBDMList){
            System.debug('bdmRecord-->'+bdmRecord);
            // collect all sumission branch and fill submission map with unique key
            if (bdmRecord.Submission_Branch__c != null){ 
            	//submissionKey = bdmRecord.Account__c + '-' + bdmRecord.Billing_Branch__c + '-' + bdmRecord.Submission_Branch__c; // Commented By KSANSI, SAC-720
                submissionKey = bdmRecord.Account__c + '-' + bdmRecord.Submission_Branch__c;
            	submissionBranchSet.add(bdmRecord.Submission_Branch__c);                
                submissionBDMMap.put(submissionKey, bdmRecord);
            }
            // collect all collection branch and fill collection map with unique key
            system.debug('bdmRecord.Collection_Branch__c != null ::' + bdmRecord.Collection_Branch__c != null);
            if (bdmRecord.Collection_Branch__c != null){ 
                system.debug('insid if');
                //collectionKey =  bdmRecord.Account__c + '-' + bdmRecord.Billing_Branch__c+'-' + bdmRecord.Collection_Branch__c; // Commented By KSANSI, SAC-720
				collectionKey =  bdmRecord.Account__c + '-' + bdmRecord.Collection_Branch__c;  
                collectionBranchSet.add(bdmRecord.Collection_Branch__c);
                collectionBDMMap.put(collectionKey, bdmRecord);
            }
            System.debug('collectionKey-->'+collectionKey);
            // collect all accounts 
            if(bdmRecord.Submission_Branch__c != null || bdmRecord.Collection_Branch__c != null){
                bdmAccountSet.add(bdmRecord.Account__c);
                bdmAccountSet.add(bdmRecord.Account__r.ParentId);
            }            
        }
        System.debug('collectionBranchSet-->'+collectionBranchSet);
        System.debug('submissionBranchSet-->'+submissionBranchSet);
        List<Invoice__c> invList = new List<Invoice__c>();
        for(Invoice__c invoice : [SELECT Id, Account__c, Bill_Branch__c, Collection_Branch__c, Sub_Branch_Master__c, Submission_propelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__c 
                                  FROM Invoice__c 
                                  WHERE Account__c IN: bdmAccountSet AND  
                                  (Collection_Branch__c IN : collectionBranchSet OR  Sub_Branch_Master__c IN : submissionBranchSet) AND Status__c != :ConstantUtility.CANCELLED]){
            System.debug('invoice-->'+invoice);                          
        	//submissionKey = invoice.Account__c + '-' + invoice.Bill_Branch__c + '-' + invoice.Sub_Branch_Master__c; //Commented by KSANSI, SAC-720
            submissionKey = invoice.Account__c + '-' + invoice.Sub_Branch_Master__c;
            //collectionKey = invoice.Account__c + '-' + invoice.Bill_Branch__c + '-' + invoice.Collection_Branch__c; // Commented By KSANSI, SAC - 720
            collectionKey = invoice.Account__c + '-' + invoice.Collection_Branch__c; 
            System.debug('submissionKey-->'+submissionKey);  
            System.debug('collectionKey-->'+collectionKey);  
            isUpdate = false;
            if(submissionBDMMap.containsKey(submissionKey)){                
                PropelI_BDM_Mapping__c bdmObj = submissionBDMMap.get(submissionKey);
                PropelI_BDM_Mapping__c bdmObjOld = bdmOldMap.get(bdmObj.Id);
                if(bdmObj.Submission__c != bdmObjOld.Submission__c){ 
                    if(submissionBDMMap.get(submissionKey).Submission__c){
                        invoice.Submission_propelI_BDM_Mapping__c = submissionBDMMap.get(submissionKey).Id;                    
                    }else {
                        invoice.Submission_propelI_BDM_Mapping__c = null;
                    }  
                    isUpdate = true;
                }
            }
            if(collectionBDMMap.containsKey(collectionKey)){
                PropelI_BDM_Mapping__c collectionBbdmObj = collectionBDMMap.get(collectionKey);
                PropelI_BDM_Mapping__c collectionBbdmObjOld = bdmOldMap.get(collectionBbdmObj.Id);
                if(collectionBDMMap.get(collectionKey).Collection__c){
                        invoice.Collection_PropelI_BDM_Mapping__c = collectionBDMMap.get(collectionKey).Id;                     
                        isUpdate = true;
                    } else { 
                        invoice.Collection_PropelI_BDM_Mapping__c = null;                    
                } 
                    
                System.debug('collectionKey-->'+collectionKey); 
                /*if(collectionBbdmObj.Collection__c != collectionBbdmObjOld.Collection__c){
                    
                }*/
            } 
                                      
            if(isUpdate){
            	invoiceUpdateList.add(invoice);
            }
            System.debug('invoice----->'+invoice);     
            System.debug('invoiceUpdateList----->'+invoiceUpdateList);                         
        }
        
        if(invoiceUpdateList.size() > 0){            
            update invoiceUpdateList;
        }
                
    }
    
    
    
}