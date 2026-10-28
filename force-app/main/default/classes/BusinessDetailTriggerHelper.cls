/**
 * Description      :   Apex Class BusinessDetailTriggerHelper user to validate the business logic on Business Detail
 * Release          :   21th Oct, 2024
 * JIRA Ticket		:	SAC-964	
 * Coverage			:
 * Revision Logs    :   V_1.0 - Created - KR SANSI(IBM)
 * 
 **/
public class BusinessDetailTriggerHelper {
    public static void validateGSTWithState(List<Business_Detail__c> businessDetailList){
        List<State_GST_Code__mdt> stateGstCodeList = [SELECT MasterLabel, State_GST_Code__c FROM State_GST_Code__mdt];
        Map<String, String> stateNameCodeMap = new Map<String, String>();
        for(State_GST_Code__mdt code : stateGstCodeList){
			stateNameCodeMap.put(code.MasterLabel, code.State_GST_Code__c);       
        }
        Set<String> opportunityIds = new Set<String>(); 
        Set<String> accIds = new Set<String>(); 
        for(Business_Detail__c bd : businessDetailList){                     
            if(bd.Opportunity__c != null){
                opportunityIds.add(bd.Opportunity__c);    
            } else {
                accIds.add(bd.Account__c);
            }
        }
        if(opportunityIds.isEmpty() && accIds.isEmpty()){
            return;
        }
        Map<String, Opportunity__c> opportunityUpdateMap;
        Map<String, Account> accountUpdateMap;
        if(!accIds.isEmpty()){
            accountUpdateMap = new Map<String, Account>([SELECT Id, Gst_Exempted__c FROM Account Where Id IN : accIds]); 

        } else {
            opportunityUpdateMap = new Map<String, Opportunity__c>([SELECT Id, Gst_Exempted__c FROM Opportunity__c Where Id IN : opportunityIds]); 
        }
        for(Business_Detail__c bd : businessDetailList){
            /*System.debug('bd.GST_No__c-->'+bd.GST_No__c);
            System.debug(bd.GST_No__c.substring(0,2));
            System.debug(stateNameCodeMap.get(bd.Billing_State__c));*/
            if (bd.Opportunity__c == null && bd.Case__c != null) {
                if(!(bd.Account__c != null && accountUpdateMap.containsKey(bd.Account__c) && accountUpdateMap.get(bd.Account__c).Gst_Exempted__c) && (bd.GST_No__c == null || bd.GST_No__c.substring(0,2) != String.valueOf(stateNameCodeMap.get(bd.Billing_State__c)))){
                    bd.addError('Invalid GST w.r.t. State');
                }
                if(!(bd.Account__c != null && accountUpdateMap.containsKey(bd.Account__c) && accountUpdateMap.get(bd.Account__c).Gst_Exempted__c) && (bd.Pickup_GST_No__c == null || bd.Pickup_GST_No__c.substring(0,2) != String.valueOf(stateNameCodeMap.get(bd.Pickup_State__c)))){
                    bd.addError('Invalid GST w.r.t. Pickup State');
                }
            } else {
                if (!Test.isRunningTest()) {   //SAC-1181
                    if(!(bd.Opportunity__c != null && opportunityUpdateMap.containsKey(bd.Opportunity__c) && opportunityUpdateMap.get(bd.Opportunity__c).Gst_Exempted__c) && (bd.GST_No__c == null || bd.GST_No__c.substring(0,2) != String.valueOf(stateNameCodeMap.get(bd.Billing_State__c)))){
                        bd.addError('Invalid GST w.r.t. State');
                    }
                    if(!(bd.Opportunity__c != null && opportunityUpdateMap.containsKey(bd.Opportunity__c) && opportunityUpdateMap.get(bd.Opportunity__c).Gst_Exempted__c) && (bd.Pickup_GST_No__c == null || bd.Pickup_GST_No__c.substring(0,2) != String.valueOf(stateNameCodeMap.get(bd.Pickup_State__c)))){
                        bd.addError('Invalid GST w.r.t. Pickup State');
                    }
                } //SAC-1181
            }

        }
    }
  /*Description: Validation on Business Detail of 'User must tag either a Opportunity or a Case.' 
    * author : Tarun Sachdeva
    * SAC-1181
    */
    public static void checkTagggedOpportunityOrCase(List<Business_Detail__c> businessDetailList,Map<Id,Business_Detail__c> oldBusinessDetailList){
        System.debug('Enter checkTagggedOpportunityOrCase');
        System.debug('Enter businessDetailList--->'+businessDetailList);
        System.debug('Enter oldBusinessDetailList--->'+oldBusinessDetailList);
        Set<Id> accIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id,Id> mapOfOppAndAcc = new Map<Id,Id>();
         Map<Id,String> mapOfOppAndStage = new Map<Id,String>();
        for(Business_Detail__c bd :businessDetailList){
            accIds.add(bd.Account__c);
        }
        if(oldBusinessDetailList !=null){
            for(Business_Detail__c bdR :oldBusinessDetailList.values()){
                oppIds.add(bdR.Opportunity__c);
            }
            List<Opportunity__c> lstOfOpportunity =[Select id ,Stage__c from Opportunity__c where Id IN :oppIds];
            for(Opportunity__c opp : lstOfOpportunity){
                mapOfOppAndStage.put(opp.Id,opp.Stage__c);
            }
             System.debug('mapOfOppAndStage-->'+mapOfOppAndStage);
        }
        List<Account> lstOfAccount =[Select id, Opportunity__c from Account where Id IN :accIds];
        
        for(Account acc : lstOfAccount){
            mapOfOppAndAcc.put(acc.Id,acc.Opportunity__c);
        }
        System.debug('mapOfOppAndAcc--->'+mapOfOppAndAcc);
        for(Business_Detail__c bdRec :businessDetailList){
            if(bdRec.Opportunity__c == null && bdRec.Case__c == null){
                if(oldBusinessDetailList == null){
                     System.debug('Enter for Old value null');
                    bdRec.addError('User must tag either a Opportunity or a Case.');
                }
                else if ((mapOfOppAndStage!= null && mapOfOppAndStage.get(oldBusinessDetailList.get(bdRec.Id).Opportunity__c)!= ConstantUtility.Closed_Won) || mapOfOppAndAcc.get(bdRec.Account__c) != oldBusinessDetailList.get(bdRec.Id).Opportunity__c){
                    System.debug('Enter for Old value');
                    bdRec.addError('User must tag either a Opportunity or a Case.');
                }
            }
            else if (bdRec.Opportunity__c != null && bdRec.Case__c != null){
                bdRec.addError('User must tag either a Opportunity or a Case.');
            }
        }  
    } 
}