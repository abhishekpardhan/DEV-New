/**
* @File Name          : OldUserOppShareQueueable.apxc
* @Description        : OldUserOppShareQueueable is used for sharing  and unsharing opportunity to those user where area changed.
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
public class OldUserOppShareQueueable implements Queueable{
    Set<User> usrSet = new Set<User>();
    Set<String> areaSet = new Set<String>();
    
    public OldUserOppShareQueueable(Set<User> usrSet,Set<String> areaSet) {       
        this.usrSet = usrSet;
        this.areaSet = areaSet;
    } 
    public void execute(QueueableContext context) {
        system.debug('usrSet'+usrSet);
        system.debug('areaSet'+areaSet);
        List<opportunity__share> oppShareList = new List<opportunity__share>();
        Map<String,List<Id>> areaOppMap = new Map<String,List<Id>>();
        
        try{
            List<opportunity__share> oppSharedList = [select Id,ParentId, UserOrGroupId, AccessLevel from opportunity__share where UserOrGroupId =: usrSet];
            if(!oppSharedList.isEmpty()){
                Database.DeleteResult[] srList = Database.delete(oppSharedList, false);
                for (Database.DeleteResult sr : srList){
                    if (sr.isSuccess()){
                        System.debug('Successfully IDs: ' + sr.getId());
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
            //**********Implemented queueable to prevent mixed DML error ***********//
            NewUserOppShareQueueable q = new NewUserOppShareQueueable(areaSet,usrSet);
            System.enqueueJob(q);
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            System.debug('Exception:'+e.getLineNumber());
        }
    }   
}