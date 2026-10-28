/**
* Description		:	   This Batch class will stored msa,sfx,ratecard,billing branch, end date into propeli active code object .
* Created By       :       Shubham Rastogi
* Created Date     :       20/04/2023
* Last Modified on :
**/
global class PropelIActiveCodeBatch implements Database.Batchable<sObject> { //, Schedulable
    
    // Start method to query on billing line items.
    public String query = '';
    public List<String> MSAs = new List<String>();
    
    public PropelIActiveCodeBatch(List<String> msaNumbers){
        
        this.MSAs = msaNumbers;
        
        if(!msaNumbers.isEmpty()){
            system.debug('Enter1');
            query = 'Select id, Name, Propel_MSACode__c  from Account Where RecordType.Name = \'Prospect Customer\' AND Propel_MSACode__c != null AND Propel_MSACode__c In:MSAs order by Propel_MSACode__c';
        }else{
            system.debug('Enter2');
            query = 'Select id, Name, Propel_MSACode__c  from Account Where RecordType.Name = \'Prospect Customer\' AND Propel_MSACode__c != null order by Propel_MSACode__c';
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute method to store data into propeli active code object.
    global void execute(Database.BatchableContext bc, List<Account > accList) {
        
        Map<String, String> MSAIds = new Map<String, String>();
        Map<String, Account> MSACodes = new Map<String, Account>();
        
        Map<String, List<String>> MSAWithSFXCodes = new Map<String, List<String>>();
        Map<String, String> SFXIds = new Map<String, String>();
        Map<String, Account> SFXCodes = new Map<String, Account>();
        
        Map<String, List<String>> SFXWithRateCards = new Map<String, List<String>>();
        Map<String, String> RateCardIds = new Map<String, String>();
        Map<String, Account> RateCards = new Map<String, Account>();
        
        Map<String, List<Account>> RateCardWithAssignBranch = new Map<String, List<Account>>();
        Map<String, Account> AssignBranches = new Map<String, Account>();
        
       	Map<String, List<Billing_Line_Item__c>> MSALineItems = new Map<String, List<Billing_Line_Item__c>>();
        Map<String, List<Billing_Line_Item__c>> SFXLineItems = new Map<String, List<Billing_Line_Item__c>>();
        Map<String, List<Billing_Line_Item__c>> RCLineItems = new Map<String, List<Billing_Line_Item__c>>();
        
        Map<String, Billing_Line_Item__c> billingByIds = new Map<String, Billing_Line_Item__c>();
        
        Map<String, List<Account_Team__c>> bdmMapping = new Map<String, List<Account_Team__c>>();
        
        Map<String, boolean> isMappingDone = new Map<String, boolean>();
        
        for(Account msa : accList){
            MSAIds.put(msa.Propel_MSACode__c, msa.Id);
            MSACodes.put(msa.Propel_MSACode__c, msa);
        }
        system.debug(MSAIds.size());
        system.debug(MSACodes);
        
        for(Account sfx : [Select id, Name, Parent.Propel_MSACode__c, SFX_Code__c from Account Where ParentId IN: MSAIds.values() AND RecordType.Name = 'SFX' AND SFX_Code__c != null order by SFX_Code__c]){
            
            SFXIds.put(sfx.SFX_Code__c, sfx.Id);
            SFXCodes.put(sfx.SFX_Code__c, sfx);
            
            if(MSAWithSFXCodes.containsKey(sfx.Parent.Propel_MSACode__c)){
                MSAWithSFXCodes.get(sfx.Parent.Propel_MSACode__c).add(sfx.SFX_Code__c);
            }else{
                List<String> data = new List<String>();
                data.add(sfx.SFX_Code__c);
                MSAWithSFXCodes.put(sfx.Parent.Propel_MSACode__c, data);
            }
        }
        system.debug(SFXIds);
        system.debug(SFXCodes);
        system.debug(MSAWithSFXCodes);
        
        for(Account rateCard : [Select id, Name, SFX__c, Rate_card_end_date__c, Base_Location__c, Base_Location__r.Name from Account Where RecordType.Name = 'Rate Card' and Parent.ParentId IN: SFXIds.values() order by Name]){
            RateCardIds.put(rateCard.Name, rateCard.Id);
            RateCards.put(rateCard.Name, rateCard);
            
            if(SFXWithRateCards.containsKey(rateCard.SFX__c)){
                SFXWithRateCards.get(rateCard.SFX__c).add(rateCard.Name);
            }else{
                List<String> data = new List<String>();
                data.add(rateCard.Name);
                SFXWithRateCards.put(rateCard.SFX__c, data);
            }
        }
        system.debug(RateCardIds);
        system.debug(RateCards);
        system.debug(SFXWithRateCards);
        
        for(Account assignBranch : [Select id, Name, Billing_Branch__c, Billing_Branch__r.Name, Parent.Name from Account where RecordType.Name= 'Assign Branch' AND ParentId In: RateCardIds.values()]){
            AssignBranches.put(assignBranch.Id, assignBranch);
            
            if(RateCardWithAssignBranch.containsKey(assignBranch.Parent.Name)){
                RateCardWithAssignBranch.get(assignBranch.Parent.Name).add(assignBranch);
            }else{
                List<Account> data = new List<Account>();
                data.add(assignBranch);
                RateCardWithAssignBranch.put(assignBranch.Parent.Name, data);
            }
        }
        system.debug(RateCardWithAssignBranch);
        
        Map<String, Billing_Line_Item__c> items = new Map<String, Billing_Line_Item__c>();
        
        Map<String, String> billingLevels = new Map<String, String>();
        
        for(Billing_Line_Item__c item : [SELECT Id, Name, Billing_Information__c, Billing_Information__r.Billing_Level__c, Billing_Information__r.SFX__r.SFX_Code__c, Billing_Branch__c, Billing_Branch__r.Name, Collection_Branch__c, Collection_Branch__r.Name, Submission_Branch__c, Submission_Branch__r.Name, Billing_By_Id__c, SFX_Code__c, Account_Name__c, Rate_Card__c, MSA__c FROM Billing_Line_Item__c where MSA__c IN: MSAIds.keySet() OR SFX_Code__c In: SFXIds.keySet() OR Rate_Card__c IN: RateCardIds.keySet()]){
            //String key;
            
            //billingByIds.put(item.Billing_By_Id__c, item);
            
            //items.put(item.Billing_Information__r.SFX__r.SFX_Code__c+'::'+item.Billing_Branch__c+'::'+item.Submission_Branch__c+'::'+item.Collection_Branch__c, item);
        
        //} 
        //for(Billing_Line_Item__c item : items.values()){
       		//String sfxCode = item.Billing_Information__r.SFX__r.SFX_Code__c;
            
            //if(SFXLineItems.containsKey(sfxCode)){
               //SFXLineItems.get(sfxCode).add(item);
            //}else{
                //List<Billing_Line_Item__c> data = new List<Billing_Line_Item__c>();
                //data.add(item);
                //SFXLineItems.put(sfxCode, data);
           	//}
           	billingLevels.put(item.Id, item.Billing_Information__r.Billing_Level__c);
            
            if(item.Billing_Information__r.Billing_Level__c == 'Rate Card'){
                if(RCLineItems.containsKey(item.Rate_Card__c)){
                    RCLineItems.get(item.Rate_Card__c).add(item);
                }else{
                    List<Billing_Line_Item__c> data = new List<Billing_Line_Item__c>();
                    data.add(item);
                    RCLineItems.put(item.Rate_Card__c, data);
                }
            }else if(item.Billing_Information__r.Billing_Level__c == 'SFX'){
                String sfxCode = item.Billing_Information__r.SFX__r.SFX_Code__c;
                if(SFXLineItems.containsKey(sfxCode)){
                    SFXLineItems.get(sfxCode).add(item);
                }else{
                    List<Billing_Line_Item__c> data = new List<Billing_Line_Item__c>();
                    data.add(item);
                    SFXLineItems.put(sfxCode, data);
                }
            }else if(item.Billing_Information__r.Billing_Level__c == 'MSA'){
                if(MSALineItems.containsKey(item.MSA__c)){
                    MSALineItems.get(item.MSA__c).add(item);
                }else{
                    List<Billing_Line_Item__c> data = new List<Billing_Line_Item__c>();
                    data.add(item);
                    MSALineItems.put(item.MSA__c, data);
                }
            }
        }
        
        //system.debug(RCLineItems);
        //system.debug(SFXLineItems);
        //system.debug(MSALineItems);
        
        //Id msaRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Customer').getRecordTypeId();
        //Id sfxRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Actual_SFX').getRecordTypeId();
        //Id rcRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Rate_card').getRecordTypeId();
        
        Map<String, Branch_Master__c> branches = new Map<String, Branch_Master__c>();
        
        for(Branch_Master__c branch : [Select Id, Name, PropelI_Branch_ID__c from Branch_Master__c where PropelI_Branch_ID__c != null LIMIT 9999]){
            String branchId = String.valueOf(branch.PropelI_Branch_ID__c);
            branches.put(branchId, branch);
        }
        
        /*for(PropelI_BDM_Mapping__c mapData : [SELECT Id, Name, Account__c, Account__r.RecordTypeId, Billing_Branch__c, Billing_Branch__r.Name, Booking_Branch__c, Booking_Branch__r.Name, Collection_Branch__c, Collection_Branch__r.Name, Submission_Branch__c, Submission_Branch__r.Name, CCD__c, CRS__c, Collection__c, Submission__c, Local_NAM__c, NSM__c, QRM__c, Relationship__c, Revenue_Mgmt__c, PropelI_BDM__c, PropelI_Branch_Id__c, PropelI_Composite_Key__c, Account_Name__c, Base_Location__c, MSA__c, SFX__c FROM PropelI_BDM_Mapping__c where PropelI_BDM__c != null AND (Account__c In: MSAIds.values() OR Account__c In: SFXIds.values() OR Account__c IN : RateCardIds.values())]){
            if(mapData.Account__c != null){
                if(bdmMapping.containsKey(mapData.Account__c)){
                    bdmMapping.get(mapData.Account__c).add(mapData);
                }else{
                    List<PropelI_BDM_Mapping__c> records = new List<PropelI_BDM_Mapping__c>();
                    records.add(mapData);
                    bdmMapping.put(mapData.Account__c, records);
                }
            }
        }*/
        for(Account_Team__c team : [Select id, Name, Account__c, PropelI_BDM_Mapping__r.Billing_Branch__c, PropelI_BDM_Mapping__r.Billing_Branch__r.Name, PropelI_BDM_Mapping__r.Booking_Branch__c, PropelI_BDM_Mapping__r.Booking_Branch__r.Name, PropelI_BDM_Mapping__r.Collection_Branch__c, PropelI_BDM_Mapping__r.Collection_Branch__r.Name, PropelI_BDM_Mapping__r.Submission_Branch__c, PropelI_BDM_Mapping__r.Submission_Branch__r.Name, National1__c, CRS__c, Collection__c, Submission__c, National2__c, NSM__c, National3__c, Relationship__c, National4__c, BDMPropelI__c from Account_Team__c where RecordType.Name = 'PropelI Account Team' AND (Account__c In: MSAIds.values() OR Account__c In: SFXIds.values() OR Account__c IN : RateCardIds.values())]){
            if(team.Account__c != null){
                if(bdmMapping.containsKey(team.Account__c)){
                    bdmMapping.get(team.Account__c).add(team);
                }else{
                    List<Account_Team__c> records = new List<Account_Team__c>();
                    records.add(team);
                    bdmMapping.put(team.Account__c, records);
                }
            }
        }
        system.debug(bdmMapping);
        
        List<ReportData> data = new List<ReportData>();
        
        for(Account msa : accList){
            String msaId = msa.Id;
            String msaCode = msa.Propel_MSACode__c;
            
            if(MSAWithSFXCodes.containsKey(msa.Propel_MSACode__c)){
                for(String sfxCode : MSAWithSFXCodes.get(msa.Propel_MSACode__c)){
                    Account sfxAcc;
                    String sfxId = '';
                    
                    if(SFXCodes.containsKey(sfxCode)){
                        sfxAcc = SFXCodes.get(sfxCode);
                        sfxId = sfxAcc.Id;
                        
                        if(SFXWithRateCards.containsKey(sfxCode)){
                            for(String rateCard : SFXWithRateCards.get(sfxCode)){
                                Account rateCardAcc;
                                String rcId = '';
                                String status = 'Active';
                                
                                isMappingDone.put(rateCard, false);
                                
                                String baseLocationId;
                                String baseLocationName;
                                
                                if(RateCards.containsKey(rateCard)){
                                    rateCardAcc = RateCards.get(rateCard);
                                    rcId = rateCardAcc.Id;
                                    if(rateCardAcc.Rate_card_end_date__c != null && rateCardAcc.Rate_card_end_date__c < date.today()){
                                        status = 'InActive';
                                    }
                                    if(rateCardAcc.Base_Location__c != null){
                                        baseLocationId = rateCardAcc.Base_Location__c;
                                        baseLocationName = rateCardAcc.Base_Location__r.Name;
                                    }
                                }
                                
                                if(RateCardWithAssignBranch.containsKey(rateCard)){
                                    for(Account assBrnch : RateCardWithAssignBranch.get(rateCard)){
                                        String bookingBranchId = assBrnch.Billing_Branch__c;
                                        String bookingBranchName = assBrnch.Billing_Branch__r.Name;
                                        Boolean isMatch = false;
                                        
                                        if(MSALineItems.containsKey(msaCode) || SFXLineItems.containsKey(sfxCode) || RCLineItems.containsKey(rateCard)){
                                            if(MSALineItems.containsKey(msaCode)){
                                                for(Billing_Line_Item__c item : MSALineItems.get(msaCode)){
                                                    if(bookingBranchName == item.Billing_Branch__r.Name){
                                                        isMatch = true;
                                                        data.add(new ReportData(msaId, msaCode, sfxId, sfxCode, rcId, rateCard, new BranchWrapper(baseLocationId, baseLocationName, bookingBranchId, bookingBranchName, item.Billing_Branch__c, item.Billing_Branch__r.Name, item.Submission_Branch__c, item.Submission_Branch__r.Name, item.Collection_Branch__c, item.Collection_Branch__r.Name), 
                                                                                false, false, false, false, false, false, false, false, false, 
                                                                                null, null, null, null, null, null, null, null, null, status, assBrnch.Id, item.Id));
                                                    }
                                                }
                                                
                                            }
                                            if(SFXLineItems.containsKey(sfxCode)){
                                                for(Billing_Line_Item__c item : SFXLineItems.get(sfxCode)){
                                                    if(bookingBranchName == item.Billing_Branch__r.Name){
                                                        isMatch = true;
                                                		data.add(new ReportData(msaId, msaCode, sfxId, sfxCode, rcId, rateCard, new BranchWrapper(baseLocationId, baseLocationName, bookingBranchId, bookingBranchName, item.Billing_Branch__c, item.Billing_Branch__r.Name, item.Submission_Branch__c, item.Submission_Branch__r.Name, item.Collection_Branch__c, item.Collection_Branch__r.Name), 
                                                                                false, false, false, false, false, false, false, false, false, 
                                                                                null, null, null, null, null, null, null, null, null, status, assBrnch.Id, item.Id));
                                                    }
                                                }
                                                
                                            }
                                            if(RCLineItems.containsKey(rateCard)){
                                                for(Billing_Line_Item__c item : RCLineItems.get(rateCard)){
                                                    if(bookingBranchName == item.Billing_Branch__r.Name){
                                                        isMatch = true;
                                                		data.add(new ReportData(msaId, msaCode, sfxId, sfxCode, rcId, rateCard, new BranchWrapper(baseLocationId, baseLocationName, bookingBranchId, bookingBranchName, item.Billing_Branch__c, item.Billing_Branch__r.Name, item.Submission_Branch__c, item.Submission_Branch__r.Name, item.Collection_Branch__c, item.Collection_Branch__r.Name), 
                                                                                false, false, false, false, false, false, false, false, false, 
                                                                                null, null, null, null, null, null, null, null, null, status, assBrnch.Id, item.Id));
                                                    }
                                                }
                                                
                                            }
                                        }
                                        if(isMatch == false){
                                            data.add(new ReportData(msaId, msaCode, sfxId, sfxCode, rcId, rateCard, new BranchWrapper(baseLocationId, baseLocationName, bookingBranchId, bookingBranchName, null, null, null, null, null, null), 
                                                                    false, false, false, false, false, false, false, false, false, 
                                                                    null, null, null, null, null, null, null, null, null, status, assBrnch.Id, null));   
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }else{
                isMappingDone.put(msaCode, true);
                data.add(new ReportData(msaId, msaCode, null, null, null, null, new BranchWrapper(null, null, null, null, null, null, null, null, null, null), 
                                        false, false, false, false, false, false, false, false, false, null, null, null, null, null, null, null, null, null, null, null, null));
            }
        }
        system.debug(data.size());
        system.debug(data);
        
        for(ReportData rec : data){
            
            boolean isMap = false;
            
            if(bdmMapping.containsKey(rec.MSAId)){
                for(Account_Team__c mapping : bdmMapping.get(rec.MSAId)){
                    if(mapping.National1__c == true){
                        rec.isCCD = true;
                        rec.bdm4 = mapping.BDMPropelI__c;
                        isMap = true;
                    }
                    if(mapping.CRS__c == true){
                        rec.isCRS = true;
                        rec.bdm5 = mapping.BDMPropelI__c;
                        isMap = true;
                    }
                    if(mapping.National2__c == true){
                        rec.isNAM = true;
                        rec.bdm6 = mapping.BDMPropelI__c;
                        isMap = true;
                    }
                    if(mapping.NSM__c == true){
                        rec.isNSM = true;
                        rec.bdm7 = mapping.BDMPropelI__c;
                        isMap = true;
                    }
                    if(mapping.National3__c == true){
                        rec.isQRM = true;
                        rec.bdm8 = mapping.BDMPropelI__c;
                        isMap = true;
                    }
                    if(mapping.National4__c == true){
                        rec.isRevenueMgmt = true;
                        rec.bdm9 = mapping.BDMPropelI__c;
                        isMap = true;
                    }
                }
            }
            if(bdmMapping.containsKey(rec.SFXId)){
                for(Account_Team__c mapping : bdmMapping.get(rec.SFXId)){
                    String teamBookingBranchName = mapping.PropelI_BDM_Mapping__r.Booking_Branch__r.Name != null ? mapping.PropelI_BDM_Mapping__r.Booking_Branch__r.Name : '';
                    String teamBillingBranchName = mapping.PropelI_BDM_Mapping__r.Billing_Branch__r.Name != null ? mapping.PropelI_BDM_Mapping__r.Billing_Branch__r.Name : '';
                    String teamSubmissionBranchName = mapping.PropelI_BDM_Mapping__r.Submission_Branch__r.Name != null ? mapping.PropelI_BDM_Mapping__r.Submission_Branch__r.Name : '';
                    String teamCollectionBranchName = mapping.PropelI_BDM_Mapping__r.Collection_Branch__r.Name != null ? mapping.PropelI_BDM_Mapping__r.Collection_Branch__r.Name : '';
                    
                    if(mapping.Relationship__c == true && rec.branches.bookingBranchName == teamBookingBranchName){
                        rec.isRelationship = true;
                        rec.bdm1 = mapping.BDMPropelI__c;
                        isMap = true;
                    }
                    if(mapping.Submission__c == true && rec.branches.submissionBranchName == teamSubmissionBranchName && rec.branches.bookingBranchName == teamBillingBranchName){
                        rec.isSubmission = true;
                        rec.bdm2 = mapping.BDMPropelI__c;
                        isMap = true;
                        //rec.billingBranchId = branches.get(mapping.PropelI_Branch_Id__c).Id;
                        //rec.billingBranchName = branches.get(mapping.PropelI_Branch_Id__c).Name;
                        //rec.submissionBranchId = mapping.Submission_Branch__c != null ? mapping.Submission_Branch__c : rec.submissionBranchId;
                        //rec.submissionBranchName = mapping.Submission_Branch__r.Name != null ? mapping.Submission_Branch__r.Name : rec.submissionBranchName;
                    }
                    if(mapping.Collection__c == true && rec.branches.collectionBranchName == teamCollectionBranchName && rec.branches.bookingBranchName == teamBillingBranchName){
                        rec.isCollection = true;
                        rec.bdm3 = mapping.BDMPropelI__c;
                        isMap = true;
                        //rec.billingBranchId = branches.get(mapping.PropelI_Branch_Id__c).Id;
                        //rec.billingBranchName = branches.get(mapping.PropelI_Branch_Id__c).Name;
                        //rec.collectionBranchId = mapping.Collection_Branch__c != null ? mapping.Collection_Branch__c : rec.collectionBranchId;
                        //rec.collectionBranchName = mapping.Collection_Branch__r.Name != null ? mapping.Collection_Branch__r.Name : rec.collectionBranchName;
                        
                    }
                }
            }
            if(bdmMapping.containsKey(rec.RateCardId)){
                for(Account_Team__c mapping : bdmMapping.get(rec.RateCardId)){
                    String teamBookingBranchName = mapping.PropelI_BDM_Mapping__r.Booking_Branch__r.Name != null ? mapping.PropelI_BDM_Mapping__r.Booking_Branch__r.Name : '';
                    String teamBillingBranchName = mapping.PropelI_BDM_Mapping__r.Billing_Branch__r.Name != null ? mapping.PropelI_BDM_Mapping__r.Billing_Branch__r.Name : '';
                    String teamSubmissionBranchName = mapping.PropelI_BDM_Mapping__r.Submission_Branch__r.Name != null ? mapping.PropelI_BDM_Mapping__r.Submission_Branch__r.Name : '';
                    String teamCollectionBranchName = mapping.PropelI_BDM_Mapping__r.Collection_Branch__r.Name != null ? mapping.PropelI_BDM_Mapping__r.Collection_Branch__r.Name : '';
                    
                    if(mapping.Relationship__c == true && rec.branches.bookingBranchName == teamBookingBranchName){
                        rec.isRelationship = true;
                        rec.bdm1 = mapping.BDMPropelI__c;
                        //rec.billingBranchId = branches.get(mapping.PropelI_Branch_Id__c).Id;
                        //rec.billingBranchName = branches.get(mapping.PropelI_Branch_Id__c).Name;
                        isMap = true;
                    }
                    if(mapping.Submission__c == true && rec.branches.submissionBranchName == teamSubmissionBranchName && rec.branches.bookingBranchName == teamBillingBranchName){
                        rec.isSubmission = true;
                        rec.bdm2 = mapping.BDMPropelI__c;
                        isMap = true;
                        //rec.billingBranchId = branches.get(mapping.PropelI_Branch_Id__c).Id;
                        //rec.billingBranchName = branches.get(mapping.PropelI_Branch_Id__c).Name;
                        //rec.submissionBranchId = mapping.Submission_Branch__c != null ? mapping.Submission_Branch__c : rec.submissionBranchId;
                        //rec.submissionBranchName = mapping.Submission_Branch__r.Name != null ? mapping.Submission_Branch__r.Name : rec.submissionBranchName;
                    }
                    if(mapping.Collection__c == true && rec.branches.collectionBranchName == teamCollectionBranchName && rec.branches.bookingBranchName == teamBillingBranchName){
                        rec.isCollection = true;
                        rec.bdm3 = mapping.BDMPropelI__c;
                        isMap = true;
                        
                        //rec.billingBranchId = branches.get(mapping.PropelI_Branch_Id__c).Id;
                        //rec.billingBranchName = branches.get(mapping.PropelI_Branch_Id__c).Name;
                        //rec.collectionBranchId = mapping.Collection_Branch__c != null ? mapping.Collection_Branch__c : rec.collectionBranchId;
                        //rec.collectionBranchName = mapping.Collection_Branch__r.Name != null ? mapping.Collection_Branch__r.Name : rec.collectionBranchName;
                    }
                }
            }
            if(isMap == true && isMappingDone.containsKey(rec.RateCardNumber) && isMappingDone.get(rec.RateCardNumber) == false){
                isMappingDone.put(rec.RateCardNumber, isMap);
            }else if(isMappingDone.containsKey(rec.MSANumber) && isMappingDone.get(rec.MSANumber) == true){
                isMappingDone.put(rec.MSANumber, true);
            }   
        }
        
        List<PropelI_Active_Code__c> activeCodes = new List<PropelI_Active_Code__c>();
        
        for(ReportData rec : data){
            system.debug(rec.MSAId+', '+rec.MSANumber+', '+rec.SFXId+', '+rec.SFXNumber+', '+rec.RateCardId+', '+rec.RateCardNumber);
            system.debug(rec.branches.billingBranchId+', '+rec.branches.billingBranchName+', '+rec.branches.submissionBranchId+', '+rec.branches.submissionBranchName+', '+rec.branches.collectionBranchId+', '+rec.branches.collectionBranchName);
            system.debug(rec.isRelationship+', '+rec.isSubmission+', '+rec.isCollection+', '+rec.isCCD+', '+rec.isCRS+', '+rec.isNAM+', '+rec.isNSM+', '+rec.isQRM+', '+rec.isRevenueMgmt);
            system.debug(rec.bdm1+', '+rec.bdm2+', '+rec.bdm3+', '+rec.bdm4+', '+rec.bdm5+', '+rec.bdm6+', '+rec.bdm7+', '+rec.bdm8+', '+rec.bdm9);
            system.debug(rec.status);
            system.debug(rec.billingLineItemId);
            system.debug('======================>'+rec.MSANumber+':'+rec.SFXNumber+':'+rec.RateCardNumber+':'+rec.assignBranchId+':'+rec.billingLineItemId);
            
            PropelI_Active_Code__c rec1 = new PropelI_Active_Code__c();
            rec1.MSA__c = rec.MSANumber;
            rec1.SFX__c = rec.SFXNumber;
            rec1.Rate_Card__c = rec.RateCardNumber;
            rec1.Booking_Branch__c = rec.branches.bookingBranchId;
            rec1.Billing_Branch__c = rec.branches.billingBranchId;
            rec1.Submission_Branch__c = rec.branches.submissionBranchId;
            rec1.Collection_Branch__c = rec.branches.collectionBranchId;
            rec1.isRelationship__c = rec.isRelationship;
            rec1.isSubmission__c = rec.isSubmission;
            rec1.isCollection__c = rec.isCollection;
            rec1.isCCD__c = rec.isCCD;
            rec1.isCRS__c = rec.isCRS;
            rec1.isNAM__c = rec.isNAM;
            rec1.isNSM__c = rec.isNSM;
            rec1.isQRM__c = rec.isQRM;
            rec1.isRevenueMgmt__c = rec.isRevenueMgmt;
            rec1.Relationship_User__c = rec.bdm1;
            rec1.Submission_User__c = rec.bdm2;
            rec1.Collection_User__c = rec.bdm3;
            rec1.CCD_User__c = rec.bdm4;
            rec1.CRS_User__c = rec.bdm5;
            rec1.NAM_User__c = rec.bdm6;
            rec1.NSM_User__c = rec.bdm7;
            rec1.QRM_User__c = rec.bdm8;
            rec1.Revenue_User__c = rec.bdm9;
            rec1.Status__c = rec.status;
            rec1.Composite_Key__c = rec.MSANumber+':'+rec.SFXNumber+':'+rec.RateCardNumber+':'+rec.assignBranchId+':'+rec.billingLineItemId;
            rec1.Is_Map__c = isMappingDone.containsKey(rec.RateCardNumber) ? isMappingDone.get(rec.RateCardNumber) : isMappingDone.containsKey(rec.MSANumber)? isMappingDone.get(rec.MSANumber) : false;
            rec1.Base_Location__c = rec.branches.baseLocationId;
            rec1.Billing_Level__c = billingLevels.containsKey(rec.billingLineItemId) ? billingLevels.get(rec.billingLineItemId) : null;
            activeCodes.add(rec1);
        }
        
        if(!activeCodes.isEmpty()){
            Database.UpsertResult[] results = Database.upsert(activeCodes, PropelI_Active_Code__c.Composite_Key__c);
        }
    }
    // finish method
    global void finish(Database.BatchableContext bc) {
    }
    
    public class ReportData{
        
        public String MSAId;
        public String MSANumber;
        public String SFXId;
        public String SFXNumber;
        public String RateCardId;
        public String RateCardNumber;
        public BranchWrapper branches;
        public boolean isRelationship;
        public boolean isSubmission;
        public boolean isCollection;
        public boolean isCCD;
        public boolean isCRS;
        public boolean isNAM;
        public boolean isNSM;
        public boolean isQRM;
        public boolean isRevenueMgmt;
        public string bdm1;
        public string bdm2;
        public string bdm3;
        public string bdm4;
        public string bdm5;
        public string bdm6;
        public string bdm7;
        public string bdm8;
        public string bdm9;
        public string status;
        public string assignBranchId;
        public string billingLineItemId;
        
        public ReportData(String MSAId, String MSANumber, String SFXId, String SFXNumber, String RateCardId, String RateCardNumber, BranchWrapper branches,
                          boolean isRelationship, boolean isSubmission, boolean isCollection, boolean isCCD, boolean isCRS, boolean isNAM, boolean isNSM, boolean isQRM, boolean isRevenueMgmt,
                          String bdm1, String bdm2, String bdm3, String bdm4, String bdm5, String bdm6, String bdm7, String bdm8, String bdm9, String status, String assignBranchId, String billingLineItemId){
                              
                              this.MSAId = MSAId;
                              this.MSANumber = MSANumber;
                              this.SFXId = SFXId;
                              this.SFXNumber = SFXNumber;
                              this.RateCardId = RateCardId;
                              this.RateCardNumber = RateCardNumber;
                              this.branches = branches;
                              this.isRelationship = isRelationship;
                              this.isSubmission = isSubmission;
                              this.isCollection = isCollection;
                              this.isCCD = isCCD;
                              this.isCRS = isCRS;
                              this.isNAM = isNAM;
                              this.isNSM = isNSM;
                              this.isQRM = isQRM;
                              this.isRevenueMgmt = isRevenueMgmt;
                              this.bdm1 = bdm1;
                              this.bdm2 = bdm2;
                              this.bdm3 = bdm3;
                              this.bdm4 = bdm4;
                              this.bdm5 = bdm5;
                              this.bdm6 = bdm6;
                              this.bdm7 = bdm7;
                              this.bdm8 = bdm8;
                              this.bdm9 = bdm9;
                              this.status = status;
                              this.assignBranchId = assignBranchId;
                              this.billingLineItemId = billingLineItemId;
                          }
        
    }
    public class BranchWrapper{
        public String baseLocationId;
        public String baseLocationName;
        public String bookingBranchId;
        public String bookingBranchName;
        public String billingBranchId;
        public String billingBranchName;
        public String submissionBranchId;
        public String submissionBranchName;
        public String collectionBranchId;
        public String collectionBranchName;
        
        
        public BranchWrapper(String baseLocationId, String baseLocationName, String bookingBranchId, String bookingBranchName, String billingBranchId, String billingBranchName, String submissionBranchId, String submissionBranchName, String collectionBranchId, String collectionBranchName){
            this.baseLocationId = baseLocationId;
            this.baseLocationName = baseLocationName;
            this.bookingBranchId = bookingBranchId;
            this.bookingBranchName = bookingBranchName;
            this.billingBranchId = billingBranchId;
            this.billingBranchName = billingBranchName;
            this.submissionBranchId = submissionBranchId;
            this.submissionBranchName = submissionBranchName;
            this.collectionBranchId = collectionBranchId;
            this.collectionBranchName = collectionBranchName;
        }
    }
    
}