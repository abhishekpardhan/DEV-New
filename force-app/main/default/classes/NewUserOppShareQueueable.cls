/**
* @File Name          : NewUserOppShareQueueable.apxc
* @Description        : NewUserOppShareQueueable is used for sharing opportunity to new user assigned area
* @Author             : Adarsh
* @Group              : Safexpress
* @Last Modified By   : Adarsh
* @Last Modified On   : 08-11-2023
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        08-11-2023                Adarsh                  Initial Version
**/

public class NewUserOppShareQueueable implements Queueable{
    Set<User> usrSet = new Set<User>();
    Set<String> areaList = new Set<String>();
    
    public NewUserOppShareQueueable(Set<String> areaList,Set<User> usrSet) {       
        this.usrSet = usrSet; 
        this.areaList = areaList; 
    } 
    public void execute(QueueableContext context) {
        system.debug('usrSet'+usrSet);
        system.debug('areaList'+areaList);
        
        List<opportunity__share> oppShareList = new List<opportunity__share>();
        Map<String,List<Id>> areaOppMap = new Map<String,List<Id>>();
        
        try{
            List<Opportunity__c> oppList = [Select Id,Name,Area__c from Opportunity__c where Area__c IN: areaList];
            if(!oppList.isEmpty()){
                for(Opportunity__c opp : oppList){
                    if(!String.isBlank(opp.Area__c)){
                        if(areaOppMap.containsKey(opp.Area__c)){
                            areaOppMap.get(opp.Area__c).add(opp.Id);
                        }else{
                            List<Id> data = new List<Id>();
                            data.add(opp.Id);
                            areaOppMap.put(opp.Area__c, data);    
                        }   
                    }
                }
            }
            system.debug('areaOppMap'+areaOppMap);
            for(User usrs : usrSet){
                for(Id oppId : areaOppMap.get(usrs.Area__c)){
                    opportunity__share oppShare = new opportunity__share();
                    oppShare.ParentId = oppId;
                    oppShare.UserOrGroupId = usrs.Id;
                    oppShare.AccessLevel = 'Read';
                    oppShareList.add(oppShare);
                }
            }
            system.debug('oppShareList'+oppShareList);
            if(!oppShareList.isEmpty()){ 
                Database.SaveResult[] srList = Database.insert(oppShareList, false);
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully share IDs: ' + sr.getId());
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('error: ' + err.getFields());
                        }
                    }
                }
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            System.debug('Exception:'+e.getLineNumber());
        }
    }   
}