public class cls_propelIPortfolioBDMMapping
{
    public class propelIMapping
    {
        @AuraEnabled public DateTime LastCreatedDate;
        @AuraEnabled public String BDMName = '';
        @AuraEnabled public String MSA;
        @AuraEnabled public String SFX;
        @AuraEnabled public String AccountId;
        @AuraEnabled public String AccountName;
        @AuraEnabled public String BaseLocation;
        @AuraEnabled public String BookingBranch;
        @AuraEnabled public Boolean Relationship;
        @AuraEnabled public String SubmissionBranch;
        @AuraEnabled public Boolean Submission;
        @AuraEnabled public String CollectionBranch;
        @AuraEnabled public Boolean Collection;
        @AuraEnabled public Boolean LocalNAM;
        @AuraEnabled public Boolean NSM;
        @AuraEnabled public Boolean QRM;
        @AuraEnabled public Boolean CRS;
        
        propelIMapping(String BDMName, String MSA,String SFX, String AccountId, String AccountName,String BaseLocation, String BookingBranch, Boolean Relationship,String SubmissionBranch, Boolean Submission, String CollectionBranch, Boolean Collection,Boolean LocalNAM, Boolean NSM   )
        {
            this.BDMName = BDMName;
            this.MSA = MSA;
            this.SFX = SFX;
            this.AccountId = AccountId;
            this.AccountName = AccountName;
            this.BaseLocation = BaseLocation;
            this.BookingBranch = BookingBranch;
            this.Relationship = Relationship;
            this.SubmissionBranch = SubmissionBranch;
            this.Submission = Submission;
            this.CollectionBranch = CollectionBranch;
            this.Collection = Collection;
            this.LocalNAM = LocalNAM;
            this.NSM = NSM;
        }
        
        propelIMapping(DateTime LastCreatedDate, String BDMName, String MSA,String SFX, String AccountId, String AccountName,String BaseLocation, String BookingBranch, Boolean Relationship,String SubmissionBranch, Boolean Submission, String CollectionBranch, Boolean Collection,Boolean LocalNAM, Boolean NSM   )
        {
            this.LastCreatedDate = LastCreatedDate;
            this.BDMName = BDMName;
            this.MSA = MSA;
            this.SFX = SFX;
            this.AccountId = AccountId;
            this.AccountName = AccountName;
            this.BaseLocation = BaseLocation;
            this.BookingBranch = BookingBranch;
            this.Relationship = Relationship;
            this.SubmissionBranch = SubmissionBranch;
            this.Submission = Submission;
            this.CollectionBranch = CollectionBranch;
            this.Collection = Collection;
            this.LocalNAM = LocalNAM;
            this.NSM = NSM;
        }
    }
    
    @AuraEnabled
    public static List<propelIMapping> getPropelIBDMMapping()
    {
        Map<String, String> mapPropelIBDM = new Map<String, String>();
        List<Account_Team__c> lstAccountTeams = [SELECT id, Account__c,PropelI_Composite_Key__c,Account__r.SFX__c,PropelI_Branch_Id__c,
                Account__r.Base_Location__c, Account__r.name,Account__r.Account_Name__c, Account__r.MSA__c,BDMPropelI__r.name, 
                Relationship__c,Collection__c,Submission__c,NSM__c,National2__c,National1__c 
                from Account_Team__c where RecordType.name = 'PropelI Account Team' AND BDMPropelI__c != null LIMIT 20000];
        System.debug('lstAccountTeams------->'+lstAccountTeams);
        
        Set<String> setSFXCodes = new Set<String>();
        Map<String, Account_Team__c> mapBDMMapping = new Map<String, Account_Team__c>();
        Map<String,propelIMapping> mapSubColls = new Map<String, propelIMapping>(); 
        
        if(! lstAccountTeams.isEmpty())
        {
            for(Account_Team__c eachAccTeam : lstAccountTeams)
            {
                setSFXCodes.add(eachAccTeam.Account__r.SFX__c);  
                mapPropelIBDM.put(eachAccTeam.Account__r.MSA__c+'::'+eachAccTeam.Account__r.SFX__c+'::'+eachAccTeam.PropelI_Branch_Id__c, eachAccTeam.BDMPropelI__r.name);
                mapBDMMapping.put(eachAccTeam.Account__r.MSA__c+'::'+eachAccTeam.Account__r.SFX__c+'::'+eachAccTeam.PropelI_Branch_Id__c, eachAccTeam);
                
                if(eachAccTeam.Relationship__c)
                {
                    String strBranch = eachAccTeam.PropelI_Composite_Key__c.substringAfter('-');   
                    String strBranch1 = strBranch.substringBefore(':@');
                    mapSubColls.put(eachAccTeam.Account__r.MSA__c+'::'+eachAccTeam.Account__r.SFX__c+'::'+eachAccTeam.PropelI_Branch_Id__c, 
                                    new  propelIMapping(
                                        eachAccTeam.BDMPropelI__r.name,
                                        eachAccTeam.Account__r.MSA__c,
                                        eachAccTeam.Account__r.SFX__c,
                                        eachAccTeam.Account__c,
                                        eachAccTeam.Account__r.Account_Name__c.left(30),
                                        eachAccTeam.Account__r.Base_Location__c,
                                        strBranch1,
                                        eachAccTeam.Relationship__c,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null, 
                                        null
                                    ));  
                }
            }
            System.debug('setSFXCodes------>'+setSFXCodes);
            System.debug('mapPropelIBDM----->'+mapPropelIBDM);
            System.debug('mapBDMMapping------>'+mapBDMMapping);
            
            if(! setSFXCodes.isEmpty())
            {
                List<Billing_Line_Item__c> lstBillingLineItems = [SELECT id,Account_Name__c,Composite_Key__c,Billing_Information__r.MSA__c, SFX_Code__c,Billing_Branch__r.name, Collection_Branch__r.name,Submission_Branch__r.name,Billing_By_Id__c, Billing_Information__r.SFX__c from Billing_Line_Item__c where SFX_Code__c IN : setSFXCodes LIMIT 20000];
                System.debug('lstBillingLineItems----->'+lstBillingLineItems);
                if(! lstBillingLineItems.isEmpty())
                {
                    for(Billing_Line_Item__c eachBillings  : lstBillingLineItems)
                    {
                        mapSubColls.put(eachBillings.Composite_Key__c, 
                                        new  propelIMapping(
                                            mapSubColls.containsKey(eachBillings.Composite_Key__c) ? mapSubColls.get(eachBillings.Composite_Key__c).BDMName : null,
                                            eachBillings.Billing_Information__r.MSA__c,
                                            eachBillings.SFX_Code__c,
                                            eachBillings.Billing_Information__r.SFX__c,
                                            eachBillings.Account_Name__c.left(30),
                                            null,
                                            eachBillings.Billing_Branch__r.name,
                                            null,
                                            eachBillings.Submission_Branch__r.name,
                                            mapBDMMapping.containsKey(eachBillings.Composite_Key__c)? mapBDMMapping.get(eachBillings.Composite_Key__c).Submission__c: null,
                                            eachBillings.Collection_Branch__r.name,
                                            mapBDMMapping.containsKey(eachBillings.Composite_Key__c)? mapBDMMapping.get(eachBillings.Composite_Key__c).Collection__c: null,
                                            mapBDMMapping.containsKey(eachBillings.Composite_Key__c)? mapBDMMapping.get(eachBillings.Composite_Key__c).National2__c: null, 
                                            mapBDMMapping.containsKey(eachBillings.Composite_Key__c)? mapBDMMapping.get(eachBillings.Composite_Key__c).NSM__c: null
                                        ));
                    }
                    System.debug('mapSubColls----->'+mapSubColls);
                }
                
                List<Account> lstBranches = [SELECT name, id, Billing_Branch__r.name, Parent.Base_Location__r.name, AssignBranch_ID__c,SFX__c,MSA__c  from Account where RecordType.Name = 'Assign Branch' AND SFX__c IN : setSFXCodes LIMIT 20000];
                System.debug('lstBranches------>'+lstBranches);
                if(! lstBranches.isEmpty())
                {
                    for(Account eachAcc : lstBranches)
                    {
                        String compositeKey = eachAcc.MSA__c+'::'+eachAcc.SFX__c+'::'+eachAcc.AssignBranch_ID__c;
                        if(mapSubColls != null && mapSubColls.containsKey(compositeKey))
                        {
                            mapSubColls.get(compositeKey).BaseLocation = eachAcc.Parent.Base_Location__r.name;
                            mapSubColls.get(compositeKey).BookingBranch =   eachAcc.Billing_Branch__r.name ;                        
                        }
                    }
                }
            }
            
        }
        System.debug('mapSubColls.values() ----->'+mapSubColls.values());
        return mapSubColls.values();
    }
    
    //'PropelI Account Team'
    @AuraEnabled
    public static List<propelIMapping> getPropelIBDMMapping1(String recordTypeName, DateTime lastCreatedDate)
    {
        System.debug('---- lastCreatedDate: ' + lastCreatedDate);
        List<Account_Team__c> lstAccountTeams = new List<Account_Team__c>();
        if(lastCreatedDate != null)
        {
            lstAccountTeams = [SELECT Id, CreatedDate, Account__c, PropelI_Composite_Key__c, PropelI_Branch_Id__c, Relationship__c, Collection__c,
                                                Submission__c, NSM__c, National2__c, National1__c, Account__r.SFX__c, Account__r.Base_Location__c,
                                                Account__r.Name, Account__r.Account_Name__c, Account__r.MSA__c, BDMPropelI__r.Name
                                                FROM Account_Team__c 
                                                WHERE
                                                PropelI_Composite_Key__c != null
                                                AND RecordType.Name = :recordTypeName 
                                                AND CreatedDate > :lastCreatedDate
                                                ORDER BY CreatedDate ASC LIMIT 20];
        }
        else
        {
            lstAccountTeams = [SELECT Id, CreatedDate, Account__c, PropelI_Composite_Key__c, PropelI_Branch_Id__c, Relationship__c, Collection__c,
                                                Submission__c, NSM__c, National2__c, National1__c, Account__r.SFX__c, Account__r.Base_Location__c,
                                                Account__r.Name, Account__r.Account_Name__c, Account__r.MSA__c, BDMPropelI__r.Name
                                                FROM Account_Team__c 
                                                WHERE 
                                                PropelI_Composite_Key__c != null
                                                AND RecordType.Name = :recordTypeName 
                                                ORDER BY CreatedDate ASC LIMIT 20];
        }
        System.debug('lstAccountTeams------->'+lstAccountTeams);
        
        Map<String, String> mapPropelIBDM = new Map<String, String>();
        Set<String> setSFXCodes = new Set<String>();
        Map<String, Account_Team__c> mapBDMMapping = new Map<String, Account_Team__c>();
        Map<String,propelIMapping> mapSubColls = new Map<String, propelIMapping>(); 
        
        if(!lstAccountTeams.isEmpty())
        {
            for(Account_Team__c eachAccTeam : lstAccountTeams)
            {
                setSFXCodes.add(eachAccTeam.Account__r.SFX__c);  
                mapPropelIBDM.put(eachAccTeam.Account__r.MSA__c+'::'+eachAccTeam.Account__r.SFX__c+'::'+eachAccTeam.PropelI_Branch_Id__c, eachAccTeam.BDMPropelI__r.name);
                mapBDMMapping.put(eachAccTeam.Account__r.MSA__c+'::'+eachAccTeam.Account__r.SFX__c+'::'+eachAccTeam.PropelI_Branch_Id__c, eachAccTeam);
                
                if(eachAccTeam.Relationship__c)
                {
                    String strBranch = eachAccTeam.PropelI_Composite_Key__c.substringAfter('-');   
                    String strBranch1 = strBranch.substringBefore(':@');
                    mapSubColls.put(eachAccTeam.Account__r.MSA__c+'::'+eachAccTeam.Account__r.SFX__c+'::'+eachAccTeam.PropelI_Branch_Id__c, 
                                    new  propelIMapping(
                                        lstAccountTeams[lstAccountTeams.size() - 1].CreatedDate,
                                        eachAccTeam.BDMPropelI__r.name,
                                        eachAccTeam.Account__r.MSA__c,
                                        eachAccTeam.Account__r.SFX__c, eachAccTeam.Account__c,
                                        eachAccTeam.Account__r.Account_Name__c.left(30),
                                        eachAccTeam.Account__r.Base_Location__c,
                                        strBranch1,
                                        eachAccTeam.Relationship__c,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null, 
                                        null
                                    ));  
                }
            }
            System.debug('setSFXCodes------>'+setSFXCodes);
            System.debug('mapPropelIBDM----->'+mapPropelIBDM);
            System.debug('mapBDMMapping------>'+mapBDMMapping);
            
            if(! setSFXCodes.isEmpty())
            {
                List<Billing_Line_Item__c> lstBillingLineItems = [SELECT id,Account_Name__c,Composite_Key__c,Billing_Information__r.MSA__c, SFX_Code__c,Billing_Branch__r.name, Collection_Branch__r.name,Submission_Branch__r.name,Billing_By_Id__c, Billing_Information__r.SFX__c from Billing_Line_Item__c where SFX_Code__c IN : setSFXCodes];
                System.debug('lstBillingLineItems----->'+lstBillingLineItems);
                if(! lstBillingLineItems.isEmpty())
                {
                    for(Billing_Line_Item__c eachBillings  : lstBillingLineItems)
                    {
                        mapSubColls.put(eachBillings.Composite_Key__c, 
                                        new  propelIMapping(
                                            lstAccountTeams[lstAccountTeams.size() - 1].CreatedDate,
                                            mapPropelIBDM.get(eachBillings.Composite_Key__c),
                                            eachBillings.Billing_Information__r.MSA__c,
                                            eachBillings.SFX_Code__c, eachBillings.Billing_Information__r.SFX__c,
                                            eachBillings.Account_Name__c.left(30),
                                            null,
                                            eachBillings.Billing_Branch__r.name,
                                            null,
                                            eachBillings.Submission_Branch__r.name,
                                            mapBDMMapping.containsKey(eachBillings.Composite_Key__c)? mapBDMMapping.get(eachBillings.Composite_Key__c).Submission__c: null,
                                            eachBillings.Collection_Branch__r.name,
                                            mapBDMMapping.containsKey(eachBillings.Composite_Key__c)? mapBDMMapping.get(eachBillings.Composite_Key__c).Collection__c: null,
                                            mapBDMMapping.containsKey(eachBillings.Composite_Key__c)? mapBDMMapping.get(eachBillings.Composite_Key__c).National2__c: null, 
                                            mapBDMMapping.containsKey(eachBillings.Composite_Key__c)? mapBDMMapping.get(eachBillings.Composite_Key__c).NSM__c: null
                                        ));
                    }
                    System.debug('mapSubColls----->'+mapSubColls);
                }
                
                List<Account> lstBranches = [SELECT name, id, Billing_Branch__r.name, Parent.Base_Location__r.name, AssignBranch_ID__c,SFX__c,MSA__c  from Account where RecordType.Name = 'Assign Branch' AND SFX__c IN : setSFXCodes];
                System.debug('lstBranches------>'+lstBranches);
                if(! lstBranches.isEmpty())
                {
                    for(Account eachAcc : lstBranches)
                    {
                        String compositeKey = eachAcc.MSA__c+'::'+eachAcc.SFX__c+'::'+eachAcc.AssignBranch_ID__c;
                        if(mapSubColls != null && mapSubColls.containsKey(compositeKey))
                        {
                            mapSubColls.get(compositeKey).BaseLocation = eachAcc.Parent.Base_Location__r.name;
                            mapSubColls.get(compositeKey).BookingBranch =   eachAcc.Billing_Branch__r.name ;                        
                        }
                    }
                }
            }
        }
        System.debug('mapSubColls.values() ----->'+mapSubColls.values());
        return mapSubColls.values();
    }
}