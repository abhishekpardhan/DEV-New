public class UpdateContactEmailBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc){
        
        return Database.getQueryLocator([SELECT Id, Email FROM Contact WHERE 
                                         Email != 'test@test.com' AND (
                                         CreatedBy.Profile.Name ='Service Cloud - Team Lead' OR
                                         CreatedBy.Profile.Name ='Service Cloud - Executive' OR
                                         CreatedBy.Profile.Name ='Service Cloud - Call Centre Head')
                                        ]);
        
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> contactList){
        for(Contact con : contactList){
            con.Email = 'test@test.com';
        }
        TriggerUtility.byPassTrigger = True;
        update contactList;
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}