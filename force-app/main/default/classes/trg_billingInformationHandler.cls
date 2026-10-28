/***********************************************************
**Author: Safexpress Private limited
**Description:  trigger is written to auto-populate the billing level at SFX(Account Type).
**JIRA Ticket: https://safexpress.atlassian.net/browse/SD-862
**Test Class: trg_billingInformation_Test(100%)
History: 
Modified By:
Modified Date: 
Comment: 

************************************************************/
Public class trg_billingInformationHandler
{
    // method to all the background operation performed on the billing information trigger.  
    Public Static void handlerOperations(Map<Id, Billing_Information__c> newBillingMap, Map<Id, Billing_Information__c> oldBillingMap, System.TriggerOperation triggerEvent, Boolean isInsert, Boolean isUpdate)
    {
        Switch on triggerEvent{

            When AFTER_INSERT, AFTER_UPDATE{
                updateBillingLevel(newBillingMap, oldBillingMap, isInsert, isUpdate);
                updateBLI(newBillingMap, oldBillingMap);

            }
        }
    }

    // method to auto-populate the billing level at SFX. 
    Public Static void updateBillingLevel(Map<Id, Billing_Information__c> newBillingMap, Map<Id, Billing_Information__c> oldBillingMap, Boolean isInsert, Boolean isUpdate)
    {
        if(! newBillingMap.isEmpty())
        {
            Map<String, String> mapSFXBillingLevel = new Map<String, String>();
            for(Billing_Information__c eachBillingLevel : newBillingMap.values())
            {

                if(String.isNotBlank(eachBillingLevel.SFX_no__c) && eachBillingLevel.IsActive__c== true)
                {
                    if(isInsert)
                        mapSFXBillingLevel.put(eachBillingLevel.SFX_no__c, eachBillingLevel.Billing_Level__c);
                    if(isUpdate)
                    {
                        mapSFXBillingLevel.put(eachBillingLevel.SFX_no__c, eachBillingLevel.Billing_Level__c);
                    }    

                }
                    
            }
            //System.debug('mapSFXBillingLevel------------------>'+mapSFXBillingLevel);
            if(! mapSFXBillingLevel.isEmpty())
            {
                List<Account> lstSFXAccount = [SELECT Id, Name, Billing_Level__c,SFX_Code__c from Account where SFX_Code__c IN : mapSFXBillingLevel.keySet() limit 9999];
                //System.debug('lstSFXAccount------------->'+lstSFXAccount);
                if(! lstSFXAccount.isEmpty())
                {
                    List<Account> lstSFXtoUpdate =new List<Account>();
                    for(Account eachSFXAcc : lstSFXAccount)
                    {
                        if(mapSFXBillingLevel.keySet().contains(eachSFXAcc.SFX_Code__c))
                        {
                            Account sfxAccount = new Account(Id = eachSFXAcc.id, Billing_Level__c =mapSFXBillingLevel.get(eachSFXAcc.SFX_Code__c) );
                            lstSFXtoUpdate.add(sfxAccount);

                        }
                        //System.debug('lstSFXtoUpdate----------->'+lstSFXtoUpdate);
                        if(! lstSFXtoUpdate.isEmpty())
                        {
                            update lstSFXtoUpdate;
                        }
                            
                    }
                }
            }
        }
    }
    /*Description: Updating the BLI on Invoice on the basis of IsActive Billing Information.
    * author : Tarun Sachdeva
    * SAC-1550
    */
    Public Static void updateBLI(Map<Id, Billing_Information__c> newBillingMap, Map<Id, Billing_Information__c> oldBillingMap){
        try{
            Set<Id> isCheck = new Set<Id>();
            Set<Id> bliIds = new Set<Id>();
            Set<String> sfxCodes = new Set<String>();
            Set<Id> billBranches = new Set<Id>();
            List<Invoice__c> updateBLIOnInv = new List<Invoice__c>();
            Map<Id,Billing_Information__c> billingIds = new  Map<Id,Billing_Information__c>();
            for(Billing_Information__c eachBillingLevel : newBillingMap.values()){
                if(oldBillingMap!= null && oldBillingMap.get(eachBillingLevel.Id).isActive__c == eachBillingLevel.isActive__c){
                    isCheck.add(eachBillingLevel.Id);
                }
                billingIds.put(eachBillingLevel.Id,eachBillingLevel);
            }
            List<Billing_Line_Item__c> lstOfBLI =[Select id, Billing_Branch__c , SFX_Code__c from Billing_Line_Item__c where Billing_Information__c IN :billingIds.keySet()];
            //System.debug('lstOfBLI---->'+lstOfBLI);
            for(Billing_Line_Item__c bli : lstOfBLI){
                bliIds.add(bli.Id);
                sfxCodes.add(bli.SFX_Code__c);
                billBranches.add(bli.Billing_Branch__c);
            }
            List<Invoice__c> lstOfInvoice = [Select id,Account__c,Bill_Branch__c,Customer_Contract_Code__c,Billing_Line_Item__c,Billing_Level__c,Billing_Line_Item__r.Billing_Information__c from Invoice__c where Billing_Line_Item__c IN :bliIds OR ( Customer_Contract_Code__c IN :sfxCodes AND Bill_Branch__c IN :billBranches)];
            //System.debug('lstOfInvoice1-->'+lstOfInvoice);
            Boolean isUpdateBli = False;
            for(Invoice__c inv :lstOfInvoice){
                Boolean isRun = !isCheck.contains(inv.Billing_Line_Item__r.Billing_Information__c)?True:False;
                if(isRun){
                    isUpdateBli= True;
                    updateBLIOnInv.add(inv);
                }
                //System.debug('inv.Billing_Line_Item__c-->'+inv.Billing_Line_Item__c);
            }
            if(isUpdateBli){
                List<Invoice__c> updLst= invoiceTriggerHelper.setLookupBLI(updateBLIOnInv,null);
                //System.debug('updLst--->'+updLst);
                if(updLst!= null || !updLst.isEmpty()){
                    update updLst;
                }
            }
        }catch(Exception exp) { 
            //System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : trg_billingInformationHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('trg_billingInformationHandler', 'updateBLI', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    

}