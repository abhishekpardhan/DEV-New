/**
* Description      :   Trigger on Opportunity__c object to perform various tasks upon different DML Operations by calling helper class methods
* 
* 
* Revision Logs    :   V_1.0 - Created
* 
**/
trigger OpportunityTrigger on Opportunity__c (before insert , before Update ,after insert,after update , after delete ,after undelete) {
    
    // bypass trigger
    if(TriggerUtility.byPassTrigger) return ;
    OpportunityTriggerHandler objOppTri = new OpportunityTriggerHandler();
    
    //Checking trigger switch value
    if(System.Label.TriggerSwitch.equals('On')){
        OpportunityTriggerHandler objOppTri = new OpportunityTriggerHandler();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        if(trigger.isAfter){
            if(trigger.isInsert){
                List<Opportunity__c> lstOpp = new List<Opportunity__c>();
                List<Opportunity__c> lstnewOpp = new List<Opportunity__c>();
                List<Opportunity__c> newOppList = new List<Opportunity__c>();// Added By Adarsh - SAC-166.
                List<Id> lstOppId = new List<Id>();
                List<Id> oppIds  = new List<Id>();

                for(opportunity__c opp : trigger.new){

                    if(!String.isBlank(opp.Account__c)){
                        lstnewOpp.add(opp);
                    }
                    if(!String.isBlank(opp.Customer_Type__c) && opp.Customer_Type__c.equals('Renewal Opportunity')){
                        lstOpp.add(opp);
                        lstOppId.add(opp.Id);
                    }
                    if(!String.isBlank(opp.Customer_Type__c) && opp.Customer_Type__c.equals('New Opportunity')){
                        accountIds.add(opp.Account__c);
                    }
                    // Added By Adarsh - SAC-166.
                    if(!String.isBlank(opp.Area__c)){
                        newOppList.add(opp);
                    }
                    //changes end - SAC-166
                }
                
                //Calling the method to prevent the 'Renewal' Opportunity if 'Account__c' checkbox is false.
                if(!lstOpp.isEmpty() && !lstOppId.isEmpty()){
                    objOppTri.oppInsertValidation(lstOpp,lstOppId);
                }
                if(!lstnewOpp.isEmpty()){
                    //Method to share opportunity with Nam1,2,3,4.
                    objOppTri.newOppInsert(lstnewOpp);
                }
                if(accountIds.size() > 0){
                    //Calling the helper class method to roll up the data from Opportunity to Account
                    objOppTri.customRollup(accountIds );
                }
                // Added By Adarsh - SAC-166.
                if(!newOppList.isEmpty()){
                    objOppTri.oppShareAreaManager(newOppList);
                }
                //changes end - SAC-166
                //added by Anand Raju SAC-2626
                  OpportunityTriggerHandler.addDefaultTeamMembers(trigger.new);
                 }
            }
            try
            { 
                if(trigger.isUpdate)
                {
                    // The below block is written to hit the propel-I system when an opportunity is closed won.
                    if(MSAPushApi.firstCheck)
                    {
                        // Acccess the custom metadata type "PropelI_Call_By_Region" to hit the propel-I system for the specified region only.
                        /*List<PropelI_Call_By_Region__mdt> lstStr= [SELECT DeveloperName, Area__c from PropelI_Call_By_Region__mdt];
                        System.debug('lstStr---->'+lstStr);
                        Set<String> set_Region = new Set<String>();
                        for(PropelI_Call_By_Region__mdt eachMetaData :lstStr )
                            set_Region.add(eachMetaData.DeveloperName);
                       
                        System.debug('set_Region------->'+set_Region);*/
                        System.debug('trigger.new[0].Region__c--------->'+trigger.new[0].Region__c);
                        MSAPushApi.firstCheck = false;  
                        System.debug('cls_RecursiveHandler.bol_FlagToStopMSAPushAPI ----->'+cls_RecursiveHandler.bol_FlagToStopMSAPushAPI );
                        // cls_RecursiveHandler.bol_FlagToStopMSAPushAPI added to break the recursive condition when MSA upsert is getting hit. 
                        if(trigger.new[0].Stage__c == 'Closed Won' && ! cls_RecursiveHandler.bol_FlagToStopMSAPushAPI /* && set_Region != null && set_Region.size() > 0 && set_Region.contains(trigger.new[0].Region__c)*/)
                            
                        {
                            if(trigger.new[0].Type__c == 'Credit' || trigger.new[0].Type__c == '3PL' || trigger.new[0].Type__c == 'Transportation+3PL'|| trigger.new[0].Type__c == 'FTL' || trigger.new[0].Type__c == 'Credit+Retail')
                            {
                                System.debug('Invoked MSA API');
                                cls_RecursiveHandler.bol_FlagToStopMSAPushAPI = true; 
                                IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
                                createITLogObject.endPointURL = System.Label.MSAPushEndpointCC;
                                createITLogObject.objectName = 'Opportunity';
                                createITLogObject.recordIdList = new List<String>{trigger.new[0].id};
                                createITLogObject.operationType = System.Label.OperationType_PropelI_CreateOpportunityPropeli; 
                                IntegrationUtility.createIntegrationTransaction(createITLogObject);
                                //MSAPushApi.MSAFromSF(trigger.new[0].id, System.Label.MSAPushEndpointCC);    
                            }else
                            {
                                cls_RecursiveHandler.bol_FlagToStopMSAPushAPI = true;
                                System.debug('Invoked MSA PRC API');
                                IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
                                createITLogObject.endPointURL = System.Label.MSAPushEndpointPRC;
                                createITLogObject.objectName = 'Opportunity'; 
                                createITLogObject.recordIdList = new List<String>{trigger.new[0].id};
                                createITLogObject.operationType = System.Label.OperationType_PropelI_CreateOpportunityPropeli; 
                                IntegrationUtility.createIntegrationTransaction(createITLogObject);
                                
                                //MSAPushApi.MSAFromSF(trigger.new[0].id, System.Label.MSAPushEndpointPRC);   
                            }
                        }
                       
                        Set<Id> oppIdSet = new Set<Id>();
                        for(Opportunity__c opp : trigger.new)
                        {                
                            if(!String.isBlank(opp.Customer_Type__c) && opp.Customer_Type__c.equals('New Opportunity')){
                                accountIds.add(opp.Account__c);
                            }
                           
                        }
                        
                        if(accountIds.size() > 0){
                            
                            //Calling the helper class method to roll up the data from Opportunity to Account
                            objOppTri.customRollup(accountIds ); 
                        }
                    }
                }
            }catch(Exception e)
            {
                String name = 'Opportunity';
                String ClassName = 'OpportunityTrigger';
                ExceptionHandling.Exception( name, ClassName, e);   
            } 
            if(trigger.isDelete){
                for(opportunity__c opp : trigger.old){
                    if(!String.isBlank(opp.Customer_Type__c) && opp.Customer_Type__c.equals('New Opportunity')){
                        accountIds.add(opp.Account__c);
                    }
                }
                
                if(accountIds.size() > 0){
                    
                    //Calling the helper class method to roll up the data from Opportunity to Account
                    objOppTri.customRollup(accountIds ); 
                }
            }
            if(trigger.isUndelete){
                for(opportunity__c opp : trigger.new){
                    if(!String.isBlank(opp.Customer_Type__c) && opp.Customer_Type__c.equals('New Opportunity')){
                        accountIds.add(opp.Account__c);
                    }
                }
                
                //Calling the helper class method to roll up the data from Opportunity to Account 
                if(accountIds.size() > 0){
                    objOppTri.customRollup(accountIds); 
                }  
            }
        }
        if(trigger.isBefore){
            List<opportunity__c> lstOpp = new List<opportunity__c>();
            Set<Id> ownerIds = new Set<Id>();
            //List<opportunity__c> lstOpp2 = new List<opportunity__c>();
            // SAC-1567 get opportunities ownerId...
            for (opportunity__c opp : Trigger.new) {
                if (opp.OwnerId != null) {
                    ownerIds.add(opp.OwnerId);
                }
            }
            //Query the Owner with their Manager's ManagerId...
            Map<Id, User> ownerToUserMap = new Map<Id, User>([SELECT Id,Manager.Manager.Profile.Name,Manager.Manager.ManagerId,Manager.ManagerId,Profile.Name FROM User WHERE Id IN :ownerIds]);
            String profileName;
            String regionalManager;
         
            if(trigger.isinsert){
                //SAC-276 - KR SANSI, IBM, added logic to pull area from account
                OpportunityTriggerHandler.updateOppDetails(trigger.new);//SAC-1457
                Set<String> accountIdsInsert = new Set<String>();  
                for(opportunity__c objOpp: trigger.new){
                    //SAC- 1567- change logic for reginal manager... 
                    User ownerUser = ownerToUserMap.get(objOpp.OwnerId);
                    system.debug('ownerUser-->'+ownerUser);
                    if (ownerUser != null) {
                        profileName = ownerUser.Profile.Name;
                        SWITCH ON profileName {
                            WHEN 'Area Manager' {
                                regionalManager = ownerUser.ManagerId;
                            }
                            WHEN 'BDM' {

                              if(ownerUser.Manager.Manager.Profile.Name == 'MD'){

                                    regionalManager = ownerUser.ManagerId;

                                }

                                else if(ownerUser.Manager.Manager.Profile.Name != 'MD'){
                                     regionalManager = ownerUser.Manager.ManagerId;
                                }
                                
                            }
                            WHEN 'Retail BDM'{
                                if(ownerUser.Manager.Manager.Profile.Name == 'MD'){

                                    regionalManager = ownerUser.ManagerId;

                                }

                                else if(ownerUser.Manager.Manager.Profile.Name != 'MD'){
                                     regionalManager = ownerUser.Manager.ManagerId;
                                }
                            }
                            WHEN 'Regional Retail Manager'{
                                if(ownerUser.Manager.Manager.Profile.Name == 'MD'){

                                    regionalManager = ownerUser.ManagerId;

                                }

                                else if(ownerUser.Manager.Manager.Profile.Name != 'MD'){
                                     regionalManager = ownerUser.Manager.ManagerId;
                                }
                            }
                        }
                       
                    }
                    //Start of SAC- 844, SAC-920, Deepika, IBM
                    objOpp.Regional_Manager__c = regionalManager;
                    
                    if(objOpp.Customer_Type__c == 'Existing-New'&&
                       
                       !objOpp.Quote_To_be_sent__c){
                           
                           objOpp.Valid_for_Contract_Tagging__c = true;
                           
                       }
                    if(profileName == 'Integration User') {
                        objOpp.Stage__c = 'Closed Won';
                        }
                    //End of SAC- 844, SAC-920
                    if(objOpp.Stage__c == 'Closed Won' && profileName != 'Integration User'){
                        lstOpp.add(objOpp);
                    }
                    if(objOpp.Account__c != null){
                        accountIdsInsert.add(objOpp.Account__c);    
                    }
                    //SAC 844 - Deepika, IBM
                    if(objOpp.Stage__c == 'Active' ||
                       objOpp.Stage__c == 'Quotation' ||
                       objOpp.Stage__c == 'Negotiation' ||
                       objOpp.Stage__c == 'Passive'){
                           objOpp.Opportunity_Status__c = 'Open';
                       }else{
                           objOpp.Opportunity_Status__c = 'Closed';
                       }
                }
               
                //SAC-276 - KR SANSI, IBM, added logic to pull area from account
                //SAC-665 - Deepika, IBM, updated logic to update Vertical and Sub-Vertical on opportunity from account

                if(accountIdsInsert.size() > 0){ 
                    Map<String, Account> accountAreaMap = new Map<String, Account>([SELECT Id, Area__c,Vertical__c, Sub__c, GST__c,GST_Exempted__c,PAN_No__c FROM Account Where Id IN : accountIdsInsert]);                     
                    for(opportunity__c objOpp: trigger.new){
                        if(objOpp.Account__c != null && accountAreaMap.containsKey(objOpp.Account__c)){
                            objOpp.Area__c = accountAreaMap.get(objOpp.Account__c).Area__c;
                        }
                        if(objOpp.Account__c != null && accountAreaMap.containsKey(objOpp.Account__c) && accountAreaMap.get(objOpp.Account__c).Vertical__c != ''){
                            objOpp.Vertical__c = accountAreaMap.get(objOpp.Account__c).Vertical__c;
                        }
                        if(objOpp.Account__c != null && accountAreaMap.containsKey(objOpp.Account__c) ){
                            objOpp.GST_Exempted__c = accountAreaMap.get(objOpp.Account__c).GST_Exempted__c;
                        }
                        if(objOpp.GST_Exempted__c == false && objOpp.GST_Number__c != null && objOpp.PAN_No__c == null){
                            objOpp.PAN_No__c = objOpp.GST_Number__c.substring(2,12);
                        }
                        if(objOpp.GST_Exempted__c == true && objOpp.Account__c != null && accountAreaMap.get(objOpp.Account__c).PAN_No__c != null && objOpp.PAN_No__c == null){
                            objOpp.PAN_No__c = accountAreaMap.get(objOpp.Account__c).PAN_No__c;
                        }
                          if(objOpp.Account__c != null && accountAreaMap.containsKey(objOpp.Account__c) && accountAreaMap.get(objOpp.Account__c).Sub__c != ''){
                            objOpp.Sub_Vertical__c = accountAreaMap.get(objOpp.Account__c).Sub__c;
                        }
                        // GST validation 
                        //System.debug('objOpp.Account__c-->'+objOpp.Account__c);
                        //System.debug('objOpp.GST_Number__c.substring(2,10)-->'+objOpp.GST_Number__c.substring(2,10));
                        if(objOpp.Account__c != null && accountAreaMap.get(objOpp.Account__c).GST__c != null && objOpp.GST_Number__c != null && !(accountAreaMap.get(objOpp.Account__c).GST__c == objOpp.GST_Number__c)){
                            objOpp.addError('GST number is invalid');
                        }
                        if(objOpp.GST_Exempted__c == false && objOpp.GST_Number__c != null && objOpp.PAN_No__c != null && !(objOpp.GST_Number__c.substring(2,12) == objOpp.PAN_No__c)) {
                            objOpp.addError('PAN number does not match with GST number');
                        }
                        if(objOpp.Account__c != null && accountAreaMap.get(objOpp.Account__c).PAN_No__c == null && objOpp.PAN_No__c != null) {
                            objOpp.addError('Please update the PAN No in the tagged account. Then only you can enter the PAN No in opportunity');
                        }
                        if(objOpp.Account__c != null && accountAreaMap.get(objOpp.Account__c).PAN_No__c != null && objOpp.PAN_No__c != null && !(accountAreaMap.get(objOpp.Account__c).PAN_No__c == objOpp.PAN_No__c)) {
                            objOpp.addError('PAN number does not match with Account\'s  PAN number');
                        }
                    }
                    
                    
                }
                
            }
            
            if(trigger.isUpdate){
                OpportunityTriggerHandler.updateOppAssigndate(Trigger.new, Trigger.oldMap); //SAC-1457
                List<String> oppIds = new List<String>();
                List<String> oppIds1 = new List<String>();
                List<opportunity__c> oppList = new List<opportunity__c>();
                Set<String> accountIdsUpdate = new Set<String>(); 
                Map<id, id> mapOppEvents = new Map<id,id>();
                 String CurrentuserprofileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
                for(opportunity__c objOpp: trigger.new){ 
                    //SAC- 1567- change logic for reginal manager... 
                    User ownerUser = ownerToUserMap.get(objOpp.OwnerId);
                    system.debug('ownerUser-->'+ownerUser);
                    if (ownerUser != null) {
                        profileName = ownerUser.Profile.Name;
                        SWITCH ON profileName {
                            WHEN 'Area Manager' {
                                regionalManager = ownerUser.ManagerId;
                            }
                            WHEN 'BDM' {

                                if(ownerUser.Manager.Manager.Profile.Name == 'MD'){

                                    regionalManager = ownerUser.ManagerId;

                                }

                                else if(ownerUser.Manager.Manager.Profile.Name != 'MD'){
                                     regionalManager = ownerUser.Manager.ManagerId;
                                }
                                
                            }
                            WHEN 'Retail BDM'{
                                if(ownerUser.Manager.Manager.Profile.Name == 'MD'){

                                    regionalManager = ownerUser.ManagerId;

                                }

                                else if(ownerUser.Manager.Manager.Profile.Name != 'MD'){
                                     regionalManager = ownerUser.Manager.ManagerId;
                                }
                            }
                            WHEN 'Regional Retail Manager'{
                                if(ownerUser.Manager.Manager.Profile.Name == 'MD'){

                                    regionalManager = ownerUser.ManagerId;

                                }

                                else if(ownerUser.Manager.Manager.Profile.Name != 'MD'){
                                     regionalManager = ownerUser.Manager.ManagerId;
                                }
                            }
                        }
                    }
                   
                    objOpp.Regional_Manager__c = regionalManager;                    
                    if(objOpp.Account__c != null){
                        accountIdsUpdate.add(objOpp.Account__c);    
                    }
                    
                    if(objOpp.Customer_Type__c == 'Existing-New'&& !objOpp.Quote_To_be_sent__c){
                           
                           objOpp.Valid_for_Contract_Tagging__c = true;
                           
                       }
                }
                Map<String, Account> accountUpdateMap = new Map<String, Account>();
                
                //Start SAC - 874 || Deepika Thakur || IBM
                If(!Test.isRunningTest()) {
                for(Event__c opp_events : [SELECT Id, Opportunity__c, CheckOut_Date__c  FROM Event__c Where Opportunity__c IN : Trigger.New And CheckOut_Date__c =null AND Cancel__c != True ]){
                    mapOppEvents.put(opp_events.Opportunity__c,opp_events.Id );            
                }
                
                accountUpdateMap = new Map<String, Account>([SELECT Id, Area__c,Vertical__c, Sub__c, GST__c,PAN_No__c FROM Account Where Id IN : accountIdsUpdate]); 
                }
                for(opportunity__c objOpp: trigger.new){
                    if(objOpp.Stage__c != trigger.oldMap.get(objOpp.Id).Stage__c && objOpp.Stage__c == 'Closed Won'){
                        
                        
                        
                        if(objOpp.Customer_Type__c == 'Existing-New'&&
                           
                           !objOpp.Quote_To_be_sent__c && objOpp.Approval_Status_For_Existing_SFX__c != 'Approved By CCD'){
                               
                               objOpp.addError('Your opportunity is not approved, please send it for approval');
                               
                           }
                           lstOpp.add(objOpp);
                           if(mapOppEvents.containsKey(objOpp.Id)){
                            
                               objOpp.addError('Please check out associated event, complete the "Activities Performed" and "Recap of Meeting" to mark it closed won.');
                           }
                       }
                    //End SAC - 874 || Deepika Thakur || IBM

                    /*if(objOpp.Stage__c != trigger.oldMap.get(objOpp.Id).Stage__c && objOpp.Stage__c == 'Closed Won' &&
                       objOpp.Type__c == 'Credit'&& profileName != 'Integration User'){
                           lstOpp2.add(objOpp);
                       }*/
                    if(objOpp.Customer_Type__c != trigger.oldMap.get(objOpp.Id).Customer_Type__c && trigger.oldMap.get(objOpp.Id).Customer_Type__c == 'Renewal Opportunity'){
                        oppIds.add(objOpp.Id);
                    }
                    if(objOpp.GST_Exempted__c == false && objOpp.GST_Number__c != null && objOpp.PAN_No__c == null){
                            objOpp.PAN_No__c = objOpp.GST_Number__c.substring(2,12);
                    }
                    if((objOpp.Account__c != trigger.oldMap.get(objOpp.Id).Account__c) && trigger.oldMap.get(objOpp.Id).Account__c != null  && objOpp.Customer_Type__c == 'Renewal Opportunity'){
                        //objOpp.Account__c.addError('Account cannot be changed for Renewal opportunity.');
                    }
                    if(((objOpp.Account__c != trigger.oldMap.get(objOpp.Id).Account__c) || (objOpp.Customer_Type__c != trigger.oldMap.get(objOpp.Id).Customer_Type__c)) && objOpp.Customer_Type__c == 'Renewal Opportunity'){
                        oppList.add(objOpp);
                        oppIds1.add(objOpp.Id);
                    }
					System.debug('accountUpdateMap***'+accountUpdateMap);
                    if((accountUpdateMap == null || accountUpdateMap.isEmpty())) {
                    }
                    else{
                    if(objOpp.Account__c != null && accountUpdateMap.get(objOpp.Account__c).GST__c != null && objOpp.GST_Number__c != null && !accountUpdateMap.get(objOpp.Account__c).GST__c.contains(objOpp.GST_Number__c.substring(2,12))){
                        objOpp.addError('GST number is invalid');
                    }
                    if(objOpp.Account__c != null && accountUpdateMap.get(objOpp.Account__c).PAN_No__c == null && objOpp.PAN_No__c != null) {
                        objOpp.addError('Please update the PAN No in the tagged account. Then only you can enter the PAN No in opportunity');
                    }
                    if(objOpp.Account__c != null  && objOpp.PAN_No__c != null && accountUpdateMap.get(objOpp.Account__c).PAN_No__c != null && !(accountUpdateMap.get(objOpp.Account__c).PAN_No__c == objOpp.PAN_No__c)) {
                        objOpp.addError('PAN number does not match with Account\'s  PAN number');
                    }
                    }
                    Id businessDetailId = OpportunityTriggerHandler.checkBuisnessDetail(new List<opportunity__c>{objOpp});
                    if(businessDetailId == null && objOpp.Approval_Status_For_Existing_SFX__c != trigger.oldMap.get(objOpp.Id).Approval_Status_For_Existing_SFX__c && objOpp.Approval_Status_For_Existing_SFX__c == 'Submitted for approval')	 {
                        objOpp.addError('Please create atleast one Business Detail Record.');
                    }
                    //SAC 844 - Deepika, IBM
                    if(objOpp.Stage__c == 'Active' ||
                       objOpp.Stage__c == 'Quotation' ||
                       objOpp.Stage__c == 'Negotiation' ||
                       objOpp.Stage__c == 'Passive'){
                           objOpp.Opportunity_Status__c = 'Open';
                       }else if (objOpp.Stage__c == 'Closed Won' ||
                                 objOpp.Stage__c == 'Closed Lost'||
                                 objOpp.Stage__c == 'Archive'){
                                     objOpp.Opportunity_Status__c = 'Closed';
                                 }
                }
                if(oppList.size() > 0 && oppIds1.size() > 0){
                    objOppTri.oppInsertValidation(oppList, oppIds1);
                }
                if(oppIds.size() > 0){
                    OpportunityTriggerHandler.checkPermission(oppIds, trigger.new);
                }
            }
          
            if(lstOpp.size() > 0){
                
                //Calling the method to update 'Qrm_Email__c' field on Opportunity with respective account teams' BDM Email
                objOppTri.updateEmail(lstOpp);
                
                //Calling the helper class method to validate if the business details are added by the user.
                if(!Test.isRunningTest()){
                    OpportunityTriggerHandler.checkBuisnessDetails(lstOpp);
                }
            }
            
            /*if(lstOpp2.size() > 0){
                //Method to check pdf on oportunity.
                objOppTri.checkPDF(lstOpp2);
            }*/
        }
    
}