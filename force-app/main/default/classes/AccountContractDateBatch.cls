/**
 * Description      :   This batch class will send email alert when contract expiry date is after 60 days and 30 days respectively and update ownership of prospect account 6 month
                        after create to account team bdm where nation1 = true 
 * JIRA             :   https://safexpress.atlassian.net/browse/SD-467
 *Last Modified By  :   Monika Rawat (September 09, 2019)                   
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
global class AccountContractDateBatch implements 
    Database.Batchable<sObject> ,Database.Stateful ,Schedulable {
   
    //Method to schedule the batch at specific time
    global void execute(SchedulableContext sc) {
        AccountContractDateBatch objACc = new AccountContractDateBatch();
        Database.executeBatch(objACc,200);
    }
    /*This batch class will send email alert when contract expiry date is after 60 days and 30 days respectively and update ownership of prospect account 6 month
    after create to account team bdm where nation1 = true */
    global String query='';
    global List<EmailTemplate> lstet = [SELECT id FROM EmailTemplate WHERE developerName =: 'Sending_email_to_Account' limit 1];
    global List<Contact> lstCon = [Select Id from Contact limit 1];
    global String [] sixtyDaysStr = String.valueOf(System.Today().addDays(60)).split(' ');
    global String [] thirtyDaysStr = String.valueOf(System.Today().addDays(30)).split(' ');
    /**
     * Querying suitable records of account
     **/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        query = 'SELECT Id ,Contract_Expiry_Date__c ,Base_Location__c ,Base_Location__r.Area__c ,Incremental_Clause__c ,Remove_Nsm_For_Sfx_Account_Date_Cal__c ,recordTypeID ,ownerId from Account where ';
        if(sixtyDaysStr.size() > 0){
            query += ' Contract_Expiry_Date__c = '+sixtyDaysStr[0];
        }
        if(thirtyDaysStr.size() > 0){
            query += ' OR Contract_Expiry_Date__c = '+thirtyDaysStr[0];
        }
        query += ' OR Remove_Nsm_For_Sfx_Account_Date_Cal__c = TODAY ';       
        return Database.getQueryLocator(query );
    }
        
    /**
     * sending email alert and updating ownership of prospect account
     **/
    global void execute(Database.BatchableContext bc, List<Account> scope){
        System.debug('<<<< scope >>> '+scope);
        Set<Id> prospectAccSet = new Set<Id>();
        Map<Id , Account> mapSfxAcc = new Map<Id ,Account>();
        List<Account> lstParentAccount = new List<Account>();
        List<Messaging.SingleEmailMessage> lstmails = new List<Messaging.SingleEmailMessage>();
        List<Account> lstChildAcc = new  List<Account> ();
        List<Task> lstTask = new List<Task>();
        Map<Id , User> accTeamRelationShipId = new Map<Id , User>();
        Map<Id , User> accTeamNam3Id = new Map<Id , User>();
        Map<Id , User> AMmap = new Map<Id, User>(); //MON
      //List<User> AMlist = new list<User>();
        Id recordsTypePros = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Id recordsTypeSfx = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
      //Id recordsTypeTask = Schema.SObjectType.Task.getRecordTypeInfosByName().get('General').getRecordTypeId();
        
        try{
            Contact objCon = null;
            if( lstCon.size() == 0 ){
                objCon = new Contact();
                objCon.lastName = 'Test Contact';
                objCon.Email = 'test@gmail.com';
                Database.insert(objCon ,False);
            }
            for(Account objAcc : scope){
                if(objAcc.recordTypeID == recordsTypePros){
                    prospectAccSet.add(objAcc.Id);
                }else if(objAcc.recordTypeID == recordsTypeSfx){
                    lstChildAcc.add(objAcc);         
                }
            }           
            for(Account objAcc : [Select Id ,OwnerId, (Select Id,National1__c from childAccounts where National1__c = true limit 1) from Account where Id IN : prospectAccSet]){                
                if(!objAcc.childAccounts.isEmpty() && objAcc.childAccounts.size() > 0){
                    mapSfxAcc.put(objAcc.childAccounts[0].Id , objAcc);
                }
            }            
            for(Account objAcc : [Select Id , (Select Id ,BDM__c from Account_Teams__r where National1__c = true limit 1) from Account where Id IN : mapSfxAcc.keySet()]){
                if(mapSfxAcc.containsKey(objAcc.Id) && !objAcc.Account_Teams__r.isEmpty() && objAcc.Account_Teams__r.size() > 0){
                    mapSfxAcc.get(objAcc.Id).OwnerId = objAcc.Account_Teams__r[0].BDM__c;
                    lstParentAccount.add(mapSfxAcc.get(objAcc.Id));
                }
            }            
            if(lstParentAccount.size() > 0){
                Database.SaveResult[] inRes = Database.update(lstParentAccount , false);
            }
           /* for(Account objAcc : [Select Id ,(Select Id ,BDM__r.id from Account_Teams__r where Relationship__c = true limit 1) from Account where Id IN : lstChildAcc]){
                System.debug('<< objAcc.Account_Teams__r >> '+objAcc.Account_Teams__r);
                if(!objAcc.Account_Teams__r.isEmpty() && objAcc.Account_Teams__r.size() > 0){
                    accTeamRelationShipId.put(objAcc.Id , objAcc.Account_Teams__r[0].BDM__r);               
                }
            }*/            
            for(Account objAcc : [Select Id , Base_Location__c, Base_Location__r.Area__c,(Select Id,National1__c ,BDM__r.id,BDM__r.Email from Account_Teams__r where National1__c = true limit 1) from Account where Id IN : lstChildAcc]){              
                if(!objAcc.Account_Teams__r.isEmpty() && objAcc.Account_Teams__r.size() > 0){
                    accTeamNam3Id.put(objAcc.Id , objAcc.Account_Teams__r[0].BDM__r); 
                    String Area = objAcc.Base_Location__r.Area__c;
                    system.debug('Area: '+Area);
                    for(User AM :[Select Name, email, Managerid, Manager.email from user where area__c =: Area AND profile.name = 'Area Manager']){
                    system.debug('AM: ' +AM);
                    AMmap.put(objAcc.Id , AM); 
                    }
                   // AM =[Select Name from user where area__c =: Area AND profile.name = 'Area Manager'];
                   // system.debug('AM: ' +AM);
                   // AMmap.put(objAcc.Id , AM); 

                }
            }            
            for (Account account : lstChildAcc) {
                if(account.Incremental_Clause__c != 'Yes'){
                  /*  if(accTeamRelationShipId.size() > 0 && accTeamRelationShipId.get(account.id) != null){
                        if(account.Contract_Expiry_Date__c == System.Today().addDays(60)){
                            Task objTask = new Task();
                            objTask.OwnerId = accTeamRelationShipId.get(account.id).id;
                            objTask.Subject = 'Contract Renewal Reminder';
                            objTask.Type__c = 'RENEWEL ACCOUNT  ';
                            objTask.whatId = account.id;
                            objTask.Priority ='High';
                            objTask.Status = 'Open';
                            objTask.IsReminderSet = true;
                            objTask.Automation__c = true;
                            objTask.ActivityDate = Date.Today().addDays(7);
                            if(recordsTypeTask != null){
                                objTask.recordTypeId = recordsTypeTask;
                            }
                            lstTask.add(objTask);
                        }
                    }*/
                    if(accTeamNam3Id.size() > 0 && accTeamNam3Id.get(account.Id) != null && AMmap.get(account.Id) != null){
                        if(account.Contract_Expiry_Date__c == System.Today().addDays(30) || account.Contract_Expiry_Date__c == System.Today().addDays(60)){
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                          //  for(User u : AMlist){
                          //  AMmap.put(Account.Id ,u);
                          //  }
                            String toAddress = accTeamNam3Id.get(account.Id).Email;
                            if (toAddress == System.Label.chirag_email){
                               toAddress = System.Label.Prasenjit_email;
                            }
                            system.debug('to: ' +toAddress);
                            list<String> ccAddress = new list<String>();
                            ccAddress.add(AMmap.get(account.Id).email);
                            ccAddress.add(AMmap.get(account.Id).manager.email);
                            system.debug('cc: ' +ccAddress);
                            if(!String.isBlank(toAddress)){
                                email.setToAddresses(new String[]{toAddress});
                                email.setccAddresses(ccAddress);
                            }
                             if(lstCon.size() > 0){
                                email.setTargetObjectId(lstCon[0].Id);
                            }else{
                                email.setTargetObjectId(objCon.id);
                            }
                            if(lstet != null && lstet.size() > 0){
                                email.setTemplateId(lstet[0].id);  
                            }    
                            email.setTreatTargetObjectAsRecipient(false); 
                            email.setWhatId(account.id);   
                            email.setSaveAsActivity(false);
                            lstmails.add(email);
                        }
                    }
                }
            }
           /* if(lstTask.size() > 0){
               insert lstTask;
            }*/
            System.debug('<< lstmails  >> '+lstmails );
            if(lstmails.size() > 0){
                try{
                    Messaging.sendEmail( lstmails );
                }catch(Exception e){
                    System.debug('<<< err message >>>'+e.getMessage());
                    System.debug('<<< err line number >>>'+e.getLineNumber());
                    String name = 'TEST123';
            String ClassName = 'TEST123';
            ExceptionHandling.Exception( name, ClassName, e);
                }
            }
            if(objCon != null){
                Database.delete(objCon , false);
            }
        }catch(Exception e){
            System.debug('<<< err message >>>'+e.getMessage());
            System.debug('<<< err line number >>>'+e.getLineNumber());
            String name = 'Monika';
            String ClassName = 'Monika Ka Code';
            ExceptionHandling.Exception( name, ClassName, e);
        }
    }    

    global void finish(Database.BatchableContext bc){
    }    
}