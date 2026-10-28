/*Description: Updating the BLI on Invoice 
    * author : Tarun Sachdeva
    * SAC-1550
    */

public class BLITriggerHelper {
    
    public static void updateBLIOnInvoice(List<Billing_Line_Item__c> lstOfBLI, Map<Id,Billing_Line_Item__c> mapOfBLI){
        try{
            Map<String, String> mapBliToInvoice = new Map<String,String>();
            Set<Id> branchId = new Set<Id>();
            Set<String> sFXCode = new Set<String>();
            Set<String> checkInvForNull = new Set<String>();
            Set<Id> checkBli = new set<Id>();
            Set<Id> bilInfoIds = new set<Id>();
            Map<Id, Billing_Information__c> mapOfBillInfo = new Map<Id,Billing_Information__c>();
            for(Billing_Line_Item__c eachBli :lstOfBLI){
                bilInfoIds.add(eachBli.Billing_Information__c);
            }
            List<Billing_Information__c> lstOfBillInfo =[Select id,Billing_level__c ,Rate_Card_no__c from Billing_Information__c where Id IN :bilInfoIds];
            for(Billing_Information__c eachBillInfo :lstOfBillInfo){
               mapOfBillInfo.put(eachBillInfo.Id,eachBillInfo);
            }
            for (Billing_Line_Item__c bli : lstOfBLI) {
                String compositeKey = '';
                branchId.add(bli.Billing_Branch__c);
                sFXCode.add(bli.SFX_Code__c);
                if(mapOfBLI !=null){
                    if(mapOfBLI.get(bli.Id).Billing_Branch__c == bli.Billing_Branch__c && mapOfBLI.get(bli.Id).SFX_Code__c == bli.SFX_Code__c && mapOfBLI.get(bli.Id).IsActive__c == bli.IsActive__c){
                        checkBli.add(bli.Id);
                    }
                    else{
                        if(mapOfBillInfo.containsKey(mapOfBLI.get(bli.Id).Billing_Information__c) && mapOfBillInfo.get(mapOfBLI.get(bli.Id).Billing_Information__c).Billing_level__c =='Rate Card'){
                           compositeKey = mapOfBLI.get(bli.Id).Billing_Branch__c + '-' + mapOfBLI.get(bli.Id).SFX_Code__c + '-' +mapOfBillInfo.get(mapOfBLI.get(bli.Id).Billing_Information__c).Rate_Card_no__c ;  
                         }
                        else{
                           compositeKey = mapOfBLI.get(bli.Id).Billing_Branch__c + '-' + mapOfBLI.get(bli.Id).SFX_Code__c;
                         }
                        checkInvForNull.add(compositeKey);
                        branchId.add(mapOfBLI.get(bli.Id).Billing_Branch__c);
                        sFXCode.add(mapOfBLI.get(bli.Id).SFX_Code__c);
                    }
                    
                }
                if(bli.IsActive__c == True){
                    if(mapOfBillInfo.containsKey(bli.Billing_Information__c) && mapOfBillInfo.get(bli.Billing_Information__c).Billing_level__c =='Rate Card'){
                        compositeKey = bli.Billing_Branch__c + '-' + bli.SFX_Code__c + '-' +mapOfBillInfo.get(bli.Billing_Information__c).Rate_Card_no__c ;  
                    }
                    else{
                        compositeKey = bli.Billing_Branch__c + '-' + bli.SFX_Code__c;
                    }
                    
                    mapBliToInvoice.put(compositeKey,bli.Id);
                    System.debug('mapBliToInvoice'+mapBliToInvoice);
                }
            }
            
            List<Invoice__c> lstOfInvoice =[Select id,Bill_Branch__c,Billing_level__c,Billing_Line_Item__c,Account__r.Name,Billing_Line_Item__r.Billing_Information__r.Billing_Level__c,Billing_Line_Item__r.Billing_Information__c,Billing_Line_Item__r.Billing_Information__r.Rate_Card_no__c,Customer_Contract_Code__c from Invoice__c where Bill_Branch__c IN :branchId And Customer_Contract_Code__c IN :sFXCode];
            System.debug('lstOfInvoice--->'+lstOfInvoice);
            List<Invoice__c> updateInv = new List<Invoice__c>();
            for (invoice__c inv : lstOfInvoice) {
                String compositeKey ='';
                Boolean isRun = !checkBli.contains(inv.Billing_Line_Item__c)?True:False;
                 System.debug('isRun__>'+isRun);
                 if(inv.Billing_level__c =='RATE Card'){
                        compositeKey = inv.Bill_Branch__c + '-' + inv.Customer_Contract_Code__c + '-' +inv.Account__r.Name ;  
                    }
                    else{
                        compositeKey = inv.Bill_Branch__c + '-' + inv.Customer_Contract_Code__c;
                    }
                System.debug('compositeKey'+compositeKey);
                if(isRun && mapBliToInvoice.containsKey(compositeKey)){
                         System.debug('Running for new,changed');
                        inv.Billing_Line_Item__c = mapBliToInvoice.get(compositeKey);
                        updateInv.add(inv);
                    
                }
                else if(checkInvForNull.contains(compositeKey) && inv.Billing_Line_Item__c !=null){
                    System.debug('Running for old branch Invoice--->');
                    inv.Billing_Line_Item__c = null;
                    updateInv.add(inv);
                }
               System.debug('inv--->'+inv);
               System.debug('inv.Billing_Line_Item__c--->'+inv.Billing_Line_Item__c);  
            } 
            if(!updateInv.isEmpty()){
               update updateInv;
           } 
        }catch(Exception exp) { 
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : BLITriggerHelper at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('BLITriggerHelper', 'updateBLIOnInvoice', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        } 
    }
     /*Description: Updating the BLI on Invoice 
    * author : Tarun Sachdeva
    * SAC-1550
    */
    Public static void updateGBOnTasks(List<Billing_Line_Item__c> bLIList,Map<Id,Billing_Line_Item__c> mapOfBLI){
        system.debug('Enter updateGBOnTasks--->');
        try{
            Map<Id,String> mapOfInv = new Map<Id,String>();
            Set<Id> bliId = new Set<Id>();
            Set<Id> isChangeGB = new Set<Id>();
            for (Billing_Line_Item__c bli : bLIList) {
                //  invId.put(inv.Id,inv.Green_Book__c);
                if(mapOfBLI != null && mapOfBLI.get(bli.Id).Green_Book__c == bli.Green_Book__c){
                   isChangeGB.add(bli.Id);
                  }
                  bliId.add(bli.Id);
                }
           List<Invoice__c> lstOfInvoice =[Select id,Billing_Line_Item__c,Green_Book__c from Invoice__c where Billing_Line_Item__c IN :bliId];
           System.debug('lstOfInvoice------>'+lstOfInvoice);
            for (Invoice__c inv : lstOfInvoice) {
                  mapOfInv.put(inv.Id,inv.Green_Book__c);
                }
           List<Task> lstOfTask =[Select id, whatId,Green_Book__c,Status from Task where whatId IN :mapOfInv.keySet()];
           System.debug('lstOfTaskK---->'+lstOfTask);
           List<Task> updTask = new  List<Task>();
            for (Task tsk : lstOfTask) {
                Boolean isRun = !isChangeGB.contains(tsk.whatId)?True:False;
                if(isRun){
                if(mapOfInv.containsKey(tsk.whatId) && tsk.Status != ConstantUtility.COMPLETED){ 
                 tsk.Green_Book__c = mapOfInv.get(tsk.whatId);
                 updTask.add(tsk);
                }
                }
               }
              System.debug('updTask--->'+updTask);
              if(!updTask.isEmpty())
              update updTask;
        }catch(Exception exp) { 
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : invoiceTriggerHelper at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('BLITriggerHelper', 'updateGBOnTasks', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        } 
    }
}