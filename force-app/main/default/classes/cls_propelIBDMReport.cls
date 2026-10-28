public class cls_propelIBDMReport {

    public static boolean stopAccountTeamTriggerPostUpdate = true;
    public static boolean stopAccountTeamTriggerPostInsert = true;
    // create relationship mapping in propelI BDM Mapping
    public static void createRelationshipPropelIBDMMapping(List<Account_Team__c> lstAccountTeams, Map<Id,Account_Team__c> oldAccTeam, Boolean isDelete, Boolean isInsert, Boolean isUpdate )
    {
        System.debug('lstAccountTeams------->'+lstAccountTeams);
        System.debug('oldAccTeam----->'+oldAccTeam);

        if(isInsert || isUpdate)
        {
            if( ! lstAccountTeams.isEmpty())
            {
                List<Branch_Master__c> lstBranchMaster = [SELECT id, name from Branch_Master__c where PropelI_Branch_ID__c != null limit 9999];
                System.debug('lstBranchMaster------->'+lstBranchMaster);
                Map<String, Id> mapBranchMaster = new Map<String, Id>();
                if(! lstBranchMaster.isEmpty())
                {
                    for(Branch_Master__c eachBrch : lstBranchMaster)
                        mapBranchMaster.put(eachBrch.name, eachBrch.id);
                }
                List<PropelI_BDM_Mapping__c> lstNewBDMMapping = new List<PropelI_BDM_Mapping__c>();
                for(Account_Team__c eachAccountTeam : lstAccountTeams)
                {
                    PropelI_BDM_Mapping__c newBDMMapping = new PropelI_BDM_Mapping__c();
                    newBDMMapping.Account__c = eachAccountTeam.Account__c;
                    newBDMMapping.PropelI_BDM__c = eachAccountTeam.BDMPropelI__c;
                    newBDMMapping.OwnerId = eachAccountTeam.BDMPropelI__c;
                    newBDMMapping.Relationship__c = eachAccountTeam.Relationship__c;
                    newBDMMapping.PropelI_Composite_Key__c = eachAccountTeam.PropelI_Composite_Key__c;
                    String strBranch = eachAccountTeam.PropelI_Composite_Key__c.substringAfter('-');   
                    String strBranch1 = strBranch.substringBefore(':@');
                    newBDMMapping.Booking_Branch__c = mapBranchMaster.containsKey(strBranch1) ?mapBranchMaster.get(strBranch1) : null ;
                    newBDMMapping.PropelI_Branch_Id__c = eachAccountTeam.PropelI_Branch_Id__c;
                    lstNewBDMMapping.add(newBDMMapping);

                }
                System.debug('lstNewBDMMapping------>'+lstNewBDMMapping);
                Database.UpsertResult[] results = Database.upsert(lstNewBDMMapping, PropelI_BDM_Mapping__c.PropelI_Composite_Key__c);
                Map<String, String> mapBDMAccountTeams = new Map<String, String>();
                for(Integer i = 0; i < results.size(); i++) 
                {
                    if(results[i].isSuccess()) 
                    {
                        if(results[i].isCreated()) 
                        {
                            System.debug(lstNewBDMMapping[i].PropelI_Composite_Key__c +' was created');
                            mapBDMAccountTeams.put(lstNewBDMMapping[i].PropelI_Composite_Key__c, results[i].getId());
                        } else 
                        {
                            System.debug(lstNewBDMMapping[i].PropelI_Composite_Key__c +' was updated');
                            mapBDMAccountTeams.put(lstNewBDMMapping[i].PropelI_Composite_Key__c, results[i].getId());
                        }
                    }
                }
                System.debug('mapBDMAccountTeams------->'+mapBDMAccountTeams);
                List<Account_Team__c> lstAccountToUpdate = new List<Account_Team__c>();
                for(Account_Team__c eachAccountTeam : lstAccountTeams)
                {
                    if(mapBDMAccountTeams.containsKey(eachAccountTeam.PropelI_Composite_Key__c))
                    {
                        Account_Team__c eachAccTeams = new Account_Team__c(Id= eachAccountTeam.Id);
                        eachAccTeams.PropelI_BDM_Mapping__c = mapBDMAccountTeams.get(eachAccountTeam.PropelI_Composite_Key__c);
                        lstAccountToUpdate.add(eachAccTeams);
                    }
                }
                System.debug('lstAccountToUpdate------>'+lstAccountToUpdate);
                if(! lstAccountToUpdate.isEmpty())
                {
                    //bypass the account post the update from here.
                    if(Trigger.isExecuting && trigger.isInsert) {
                   	 	cls_propelIBDMReport.stopAccountTeamTriggerPostInsert = false;
                    }
                    else {
                        cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;
                    }
                    
                    update lstAccountToUpdate;

                }
                   
            }
        }
        if(isDelete)
        {
            List<Id> lstBDMIds = new List<Id>();
            Id accTeamRecordTypeId = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId(); 
            for(Account_Team__c eachAccTeam : oldAccTeam.values())
            {
              if(eachAccTeam.RecordTypeId == accTeamRecordTypeId)  
              	lstBDMIds.add(eachAccTeam.PropelI_BDM_Mapping__c);
            }
            System.debug('lstBDMIds---->'+lstBDMIds);
            List<PropelI_BDM_Mapping__c> lstBDMMapping = [SELECT Id from PropelI_BDM_Mapping__c where Id IN : lstBDMIds];
            if(! lstBDMMapping.isEmpty())
                delete lstBDMMapping;
        }

    }
    public static void createMSABDMMapping(List<Account_Team__c> lstAccountTeams)
    {
        System.debug('lstAccountTeams-------->'+lstAccountTeams);
        if(! lstAccountTeams.isEmpty())
        {
                List<PropelI_BDM_Mapping__c> lstNewBDMMapping = new List<PropelI_BDM_Mapping__c>();
                for(Account_Team__c eachAccountTeam : lstAccountTeams)
                {
                    PropelI_BDM_Mapping__c newBDMMapping = new PropelI_BDM_Mapping__c();
                    newBDMMapping.Account__c = eachAccountTeam.Account__c;
                    newBDMMapping.PropelI_BDM__c = eachAccountTeam.BDMPropelI__c;
                    newBDMMapping.OwnerId = eachAccountTeam.BDMPropelI__c;
                    newBDMMapping.CCD__c = eachAccountTeam.National1__c;
                    newBDMMapping.Local_NAM__c = eachAccountTeam.National2__c;
                    newBDMMapping.QRM__c = eachAccountTeam.National3__c;
                    newBDMMapping.Revenue_Mgmt__c = eachAccountTeam.National4__c;
                    newBDMMapping.CRS__c = eachAccountTeam.CRS__c;
                    newBDMMapping.NSM__c = eachAccountTeam.NSM__c;
                    newBDMMapping.PropelI_Composite_Key__c = eachAccountTeam.PropelI_Composite_Key__c;
                    newBDMMapping.PropelI_Branch_Id__c = eachAccountTeam.PropelI_Branch_Id__c;
                    lstNewBDMMapping.add(newBDMMapping);

                }
                System.debug('lstNewBDMMapping------>'+lstNewBDMMapping);
                Database.UpsertResult[] results = Database.upsert(lstNewBDMMapping, PropelI_BDM_Mapping__c.PropelI_Composite_Key__c);
                Map<String, String> mapBDMAccountTeams = new Map<String, String>();
                for(Integer i = 0; i < results.size(); i++) 
                {
                    if(results[i].isSuccess()) 
                    {
                        if(results[i].isCreated()) 
                        {
                            System.debug(lstNewBDMMapping[i].PropelI_Composite_Key__c +' was created');
                            mapBDMAccountTeams.put(lstNewBDMMapping[i].PropelI_Composite_Key__c, results[i].getId());
                        } else 
                        {
                            System.debug(lstNewBDMMapping[i].PropelI_Composite_Key__c +' was updated');
                            mapBDMAccountTeams.put(lstNewBDMMapping[i].PropelI_Composite_Key__c, results[i].getId());
                        }
                    }
                }
                System.debug('mapBDMAccountTeams------->'+mapBDMAccountTeams);
                List<Account_Team__c> lstAccountToUpdate = new List<Account_Team__c>();
                for(Account_Team__c eachAccountTeam : lstAccountTeams)
                {
                    if(mapBDMAccountTeams.containsKey(eachAccountTeam.PropelI_Composite_Key__c))
                    {
                        Account_Team__c eachAccTeams = new Account_Team__c(Id= eachAccountTeam.Id);
                        eachAccTeams.PropelI_BDM_Mapping__c = mapBDMAccountTeams.get(eachAccountTeam.PropelI_Composite_Key__c);
                        lstAccountToUpdate.add(eachAccTeams);
                    }
                }
                System.debug('lstAccountToUpdate------>'+lstAccountToUpdate);
                if(! lstAccountToUpdate.isEmpty())
                {
                    //bypass the account post the update from here.
                    cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;
                    update lstAccountToUpdate;

                }
        }
    }

    //create submission and collection mapping record in PropelI BDM mapping
    public static void createSubmissionCollMapping(List<Account_Team__c> lstAccountTeams, Set<String> setSFXs)
    {
        System.debug('lstAccountTeams------->'+lstAccountTeams);  
        if( ! lstAccountTeams.isEmpty())
        {
            List<Billing_Line_Item__c> lstBillingLineItems = [SELECT id,Account_Name__c,Composite_Key__c,Billing_Information__r.MSA__c, SFX_Code__c,Billing_Branch__c, Collection_Branch__c,Submission_Branch__c,Billing_By_Id__c, Billing_Information__r.SFX__c from Billing_Line_Item__c where SFX_Code__c IN : setSFXs limit 9999];
            System.debug('lstBillingLineItems----->'+lstBillingLineItems);
            Map<String, Id> mapSubBrnch = new Map<String, Id>();
            Map<String, Id> mapCollBrnch = new Map<String, Id>();
            Map<String, Id> mapBillingBrnch = new Map<String, Id>();
            if(! lstBillingLineItems.isEmpty())
            {
                for(Billing_Line_Item__c eachBillItems : lstBillingLineItems)
                {
                   mapSubBrnch.put(eachBillItems.SFX_Code__c+'::'+eachBillItems.Billing_By_Id__c, eachBillItems.Submission_Branch__c); 
                   mapCollBrnch.put(eachBillItems.SFX_Code__c+'::'+eachBillItems.Billing_By_Id__c, eachBillItems.Collection_Branch__c); 
                   mapBillingBrnch.put(eachBillItems.SFX_Code__c+'::'+eachBillItems.Billing_By_Id__c, eachBillItems.Billing_Branch__c);
                }      
            }
            List<PropelI_BDM_Mapping__c> lstNewBDMMapping = new List<PropelI_BDM_Mapping__c>();
            for(Account_Team__c eachAccountTeam : lstAccountTeams)
            {
                PropelI_BDM_Mapping__c newBDMMapping = new PropelI_BDM_Mapping__c();
                newBDMMapping.Account__c = eachAccountTeam.Account__c;
                newBDMMapping.PropelI_BDM__c = eachAccountTeam.BDMPropelI__c;
                newBDMMapping.OwnerId = eachAccountTeam.BDMPropelI__c;
                newBDMMapping.Collection__c = eachAccountTeam.Collection__c;
                newBDMMapping.Submission_Branch__c = mapSubBrnch.containsKey(eachAccountTeam.SFX__c+'::'+eachAccountTeam.PropelI_Branch_Id__c)? mapSubBrnch.get(eachAccountTeam.SFX__c+'::'+eachAccountTeam.PropelI_Branch_Id__c) : null;
                
                // added by shubham rastogi
                newBDMMapping.Collection_Branch__c = mapCollBrnch.containsKey(eachAccountTeam.SFX__c+'::'+eachAccountTeam.PropelI_Branch_Id__c)? mapCollBrnch.get(eachAccountTeam.SFX__c+'::'+eachAccountTeam.PropelI_Branch_Id__c) : null;
                
                newBDMMapping.Submission__c = eachAccountTeam.Submission__c;
                newBDMMapping.Billing_Branch__c = mapBillingBrnch.containsKey(eachAccountTeam.SFX__c+'::'+eachAccountTeam.PropelI_Branch_Id__c)? mapBillingBrnch.get(eachAccountTeam.SFX__c+'::'+eachAccountTeam.PropelI_Branch_Id__c) : null;
                newBDMMapping.PropelI_Composite_Key__c = eachAccountTeam.PropelI_Composite_Key__c;
                newBDMMapping.PropelI_Branch_Id__c = eachAccountTeam.PropelI_Branch_Id__c;
                lstNewBDMMapping.add(newBDMMapping);

            }
            System.debug('lstNewBDMMapping------>'+lstNewBDMMapping);
            if(! lstNewBDMMapping.isEmpty())
            {
                Database.UpsertResult[] results = Database.upsert(lstNewBDMMapping, PropelI_BDM_Mapping__c.PropelI_Composite_Key__c);
                Map<String, String> mapBDMAccountTeams = new Map<String, String>();
                for(Integer i = 0; i < results.size(); i++) 
                {
                    if(results[i].isSuccess()) 
                    {
                        if(results[i].isCreated()) 
                        {
                            System.debug(lstNewBDMMapping[i].PropelI_Composite_Key__c +' was created');
                            mapBDMAccountTeams.put(lstNewBDMMapping[i].PropelI_Composite_Key__c, results[i].getId());
                        } else 
                        {
                            System.debug(lstNewBDMMapping[i].PropelI_Composite_Key__c +' was updated');
                            mapBDMAccountTeams.put(lstNewBDMMapping[i].PropelI_Composite_Key__c, results[i].getId());
                        }
                    }
                }
                System.debug('mapBDMAccountTeams------->'+mapBDMAccountTeams);
                List<Account_Team__c> lstAccountToUpdate = new List<Account_Team__c>();
                for(Account_Team__c eachAccountTeam : lstAccountTeams)
                {
                    if(mapBDMAccountTeams.containsKey(eachAccountTeam.PropelI_Composite_Key__c))
                    {
                        Account_Team__c eachAccTeams = new Account_Team__c(Id= eachAccountTeam.Id);
                        eachAccTeams.PropelI_BDM_Mapping__c = mapBDMAccountTeams.get(eachAccountTeam.PropelI_Composite_Key__c);
                        lstAccountToUpdate.add(eachAccTeams);
                    }
                }
                System.debug('lstAccountToUpdate------>'+lstAccountToUpdate);
                if(! lstAccountToUpdate.isEmpty())
                {
                    //bypass the account post the update from here.
                    cls_propelIBDMReport.stopAccountTeamTriggerPostUpdate = false;
                    update lstAccountToUpdate;

                }
            }
        }
    }

}