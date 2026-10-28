// ************ Implemented as part of SAC - 97 *****************//

public class InsertLeadShareQueueable implements Queueable{
    
    List<User> usrLst = new List<User>();
    
    public InsertLeadShareQueueable(List<User> urlst) {       
        this.usrLst = urlst;        
    } 
    
    public void execute(QueueableContext context) {
        
        Map<String,List<Id>> areaUserMap = new map<String,List<Id>>();
        for(User user : usrLst){
            if(!areaUserMap.containsKey(user.Area__c))
                areaUserMap.put(user.Area__c, new list<Id>());
            areaUserMap.get(user.Area__c).add(user.Id);
        }
        system.debug('--areaUserMap-'+areaUserMap);
        list<Lead__c> leadList = new list<Lead__c>();
        list<Lead__share> leadShareList = new list<Lead__share>();
        map<Id,Id> leaduserMap = new map<Id,Id>();
        // fetch all leads associated with user's Area
        leadList = [select Id, Area__c from Lead__c where Area__c in:areaUserMap.keyset()];
        system.debug('----leadList--'+leadList);
        for(Lead__c lead : leadList){
            list<Id> areaSpecificUsers = new list<Id>();
            if(areaUserMap.containsKey(lead.area__c))
                areaSpecificUsers = areaUserMap.get(lead.area__c);
            if(areaSpecificUsers.size() > 0)   
                leadShareList.addAll(createLeadShareUtility.createLeadShare(areaSpecificUsers, lead.Id));
        }
        if(leadShareList.size() > 0){
            system.debug('leadShareList-->'+leadShareList);
            // insert leadShareList;
            Database.SaveResult[] srList = Database.insert(leadShareList, false);
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted lead share records. Lead share IDs: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Lead share fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
}