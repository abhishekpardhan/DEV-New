/**
* Description		:	    Trigger on Contact object to create Leads in system if leadSource on Contact is 'Directory'
* 					        by calling helper class methods
* JIRA ticket       :		https://safexpress.atlassian.net/browse/SD-453
* Last Modified By  :       Shubham Girdhar
* Last Modified Date:       06/01/2020
* Revision Logs   	:    	V_1.0 - Created
* 
**/
trigger trg_Contact on Contact (after insert, after update, before insert, before update) {
    
    //Checking trigger switch values
    if(System.Label.TriggerSwitch.equals('On')){
        
        if(trigger.isAfter && trigger.isInsert){
            List<contact> lstContacts = new List<contact>();
            Set<Id> setOwner  = new Set<Id>();
            List<String> EmailList = new List<String>();
            //Doing further processing only if leadSource is 'Directory'
            for(contact c: trigger.new){
                System.debug('In the trigger Contact loop');
                if(c.LeadSource == 'Directory'){
                    System.debug('Source is Directory');
                    EmailList.add(c.Email);
                    setOwner.add(c.ownerId);
                    lstContacts.add(c);
                }
            }
            System.debug('Calling the trigger');
            //Calling the method to create new leads in system
            triggerContactHelper.createLeads(lstContacts ,setOwner);
            
          /*  try{
            for (contact co : lstContacts){
                system.debug('In the contact for Loop');
                for (Lead__c ld : [Select Id, name, Email__c from Lead__c Where Email__c IN : EmailList]){
                    system.debug('In the Lead for Loop');
                    if(co.Email == ld.Email__c){
                        system.debug('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
                        system.debug('&&&&&&&&&&&&&&&&'+ co.Id);
                        system.debug('****************'+ ld.Id);
                        copyFile.CopyFileFromRecord1to2(co.Id, ld.Id);
                    }
                }
            }
        }catch(Exception e){
            String name = 'Zero Keyboard';
            String ClassName = 'ZeroKeyboardApp';
            ExceptionHandling.Exception( name, ClassName, e);
        }*/
        }
        List<Contact> contactList = new List<Contact>();
        if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)){
            for(Contact con : Trigger.New){
                if(con.Is_Active__c == false){
                    //SAC-938 || Deepika 
                    //triggerContactHelper.checkContactRelationship(Trigger.New);
                }
                
                
            }
            //System.debug(con.Account__r);
            
        }
        
        if(Trigger.isAfter && Trigger.isUpdate){
            triggerContactHelper.removeAccountContactRelation(Trigger.New, Trigger.oldMap);
        }
    }
}