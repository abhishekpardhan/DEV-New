// ************ Implemented as part of SAC - 97 *****************//

public class deleteLeadShareQueueable implements Queueable {
    
    List<User> usrLst = new List<User>();
    
    public deleteLeadShareQueueable(List<User> urlst) {       
        this.usrLst = urlst;        
    }
    
    public void execute(QueueableContext context){
        
        list<Lead__c> oldAreaLeads = new list<lead__c>();
        list<String> areaList = new list<String>();
        list<Lead__share> deleteLeadShare = new list<Lead__share>();
        map<id,String> userAreaMap = new map<Id,String>();
        
        for(User usr : usrLst){            
            areaList.add(usr.area__c);
            userAreaMap.put(usr.Id,usr.area__c); 
            system.debug('userAreaMap--->'+userAreaMap);
        }
        if(areaList.size() > 0){
            map<Id,String> leadAreaMap = new map<Id,String>();
            oldAreaLeads = [select Id,area__c from lead__c where area__c in : areaList];
            for(Lead__c oldlead : oldAreaLeads){
                leadAreaMap.put(oldLead.Id, oldlead.area__c);
            }
            system.debug('leadAreaMap-->'+leadAreaMap);
            for(lead__share leadShare : [select Id,ParentId,UserOrGroupId from lead__share where parentId in :oldAreaLeads
                                         AND UserOrGroupId in : userAreaMap.keyset() AND RowCause = 'Manual'])
            {     
               if(leadAreaMap.get(leadShare.parentId) == userAreaMap.get(leadShare.UserOrGroupId))   
               deleteLeadShare.add(leadShare);
            }
        }
        
        system.debug('deleteLeadShare-->'+deleteLeadShare);
        if(deleteLeadShare.size() > 0){
        	
            Database.DeleteResult[] srList = Database.delete(deleteLeadShare, false);
            
            for (Database.DeleteResult sr : srList){
            if (sr.isSuccess()){
                System.debug('Successfully deleted lead share records. Lead share IDs: ' + sr.getId());
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