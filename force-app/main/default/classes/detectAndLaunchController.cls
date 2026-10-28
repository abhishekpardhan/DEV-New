public without sharing class detectAndLaunchController {
    
    @AuraEnabled
    public static String checkMapping(String oppId){
        List<Renewal_SFX_RC_Mapping__c> mappings = new List<Renewal_SFX_RC_Mapping__c>();
        
        mappings = [Select Id, Name, opportunity__c from Renewal_SFX_RC_Mapping__c Where opportunity__c =: oppId];
        
        if(mappings.size() > 0){
            return 'Records Found';
        }else{
            return 'No Record Found';
        }
        
    }
    @AuraEnabled
    public static String getSFXAndRateCards(String msaId, String mode, String oppId){
        List<SFXWrapper> wrapper = new List<SFXWrapper>();
        system.debug(mode);
        system.debug(oppId);
        try {
            Map<Id, List<Account>> rateCardsRelatedToSFX = new Map<Id, List<Account>>();
            
            Map<Id, Account> sfxMap = new Map<Id, Account>([Select Id, Name, SFX_Code__c From Account Where RecordType.Name = 'SFX' AND ParentId =:msaId]);
            Map<Id, Account> rateCardMap = new Map<Id, Account>();
            
            if(sfxMap.size() > 0) rateCardMap = new Map<Id, Account>([Select Id, Name, Parent.ParentId From Account Where RecordType.Name = 'Rate Card' AND Parent.ParentId In:sfxMap.keySet()]);
            system.debug(rateCardMap);
            
            if(rateCardMap.size() > 0){
                for(Account acc : rateCardMap.values()){
                    if(rateCardsRelatedToSFX.containsKey(acc.Parent.ParentId)){
                        rateCardsRelatedToSFX.get(acc.Parent.ParentId).add(acc);
                    }else{
                        List<Account> accList = new List<Account>();
                        accList.add(acc);
                        rateCardsRelatedToSFX.put(acc.Parent.ParentId, accList);
                    }
                }
            }
            system.debug(rateCardsRelatedToSFX);
            List<Renewal_SFX_RC_Mapping__c> mapping = new List<Renewal_SFX_RC_Mapping__c>();
            
            Opportunity__c opp;
            
            if(mode == 'Edit' && oppId != null && oppId != ''){
                mapping = [Select Id, Name, SFX__r.SFX_Code__c, Rate_Card__r.Name From Renewal_SFX_RC_Mapping__c Where Opportunity__c =: oppId];
                opp = [Select Id, Name, Customer_Type__c from Opportunity__c Where Id =: oppId];
            }
               
            if(opp != null && opp.Customer_Type__c != 'Renewal Opportunity'){
                return 'not allowed';
            }else if(rateCardsRelatedToSFX.size() > 0){
                for(String recId : rateCardsRelatedToSFX.keySet()){
                    if(sfxMap.containsKey(recId)){
                        wrapper.add(new SFXWrapper(sfxMap.get(recId), rateCardsRelatedToSFX.get(recId)));
                    }
                }
                return JSON.serialize(wrapper)+'&&&'+JSON.serialize(mapping);
            }else{
                return 'There is no SFX and Rate Card available for given MSA.';
            }
        } catch(Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updateSFXAndRC(List<String> sfxList, String recId){
        if(recId == null || recId == '' || recId == 'undefined'){
            return 'Refresh Page';
        }else{
            Map<String, List<String>> SFX_RC_Mapping = new Map<String, List<String>>();
            Set<String> allRateCards = new Set<String>();
            try{
                List<String> data = new List<String>();
                List<String> rateCards = new List<String>();
                for(String str : sfxList){
                    system.debug(str);
                    data = str.split('=');
                    if(data.size() > 1){
                        if(data[1] != null && data[1] != ''){
                        	rateCards = data[1].split(', ');
                    	}
                   	 	system.debug(rateCards);
                    	allRateCards.addAll(rateCards);
                    	SFX_RC_Mapping.put(data[0], rateCards);
                    }
                }
                
                Map<String, Id> rcNames = new Map<String, Id>();
                for(Account acc : [Select Id, Name From Account Where Name In: allRateCards  AND RecordType.Name = 'Rate Card']){
                    rcNames.put(acc.Name, acc.Id);
                }
                
                Map<String, Id> sfxNames = new Map<String, Id>();
                for(Account acc : [Select Id, Name, SFX_Code__c From Account Where SFX_Code__c In: SFX_RC_Mapping.keySet() AND RecordType.Name = 'SFX']){
                    sfxNames.put(acc.SFX_Code__c, acc.Id);
                }
                
                List<Renewal_SFX_RC_Mapping__c> recordsToDelete = [Select Id, Name from Renewal_SFX_RC_Mapping__c where Opportunity__c =: recId];
                if(recordsToDelete != null && recordsToDelete.size() > 0){
                    delete recordsToDelete;
                }
                
                List<Renewal_SFX_RC_Mapping__c> records = new List<Renewal_SFX_RC_Mapping__c>();
                for(String sfx : SFX_RC_Mapping.keySet()){
                    for(String rc : SFX_RC_Mapping.get(sfx)){
                        Renewal_SFX_RC_Mapping__c rec = new Renewal_SFX_RC_Mapping__c();
                        rec.SFX__c = sfxNames.containsKey(sfx)? sfxNames.get(sfx) : null;
                        rec.Rate_Card__c = rcNames.containsKey(rc)? rcNames.get(rc) : null;
                        rec.Opportunity__c = recId;
                        records.add(rec);
                        system.debug(rec);
                    }
                }
                if(records.size() > 0){
                    insert records;
                }
                return 'Success';
                
            } catch(DmlException e) {
                system.debug(e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
            
        }
    }
    public class SFXWrapper{
        @AuraEnabled
        public Account sfxRecord;
        @AuraEnabled
        public List<Account> rateCardRecords;       
        
        public SFXWrapper(Account sfxRecord, List<Account> rateCardRecords){
            this.sfxRecord = sfxRecord;
            this.rateCardRecords = rateCardRecords;
        }
    }
}