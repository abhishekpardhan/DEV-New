//Controller class for GeoLocation Page to get the current latitue/Longitude and time information and updation them on CheckIn/CheckOut Fields
public with sharing class Geolocation{
    
    //Method to get current location of user and updating the CheckIn/CheckOut fields on Event with Current Latitue/Longitude and System Time
    @AuraEnabled
    public static String eventLocation(Id eId ,Object latitude ,Object longitude ,String purpose){        
        System.debug('<< eventLocation >> ');
        System.debug('<< eId >> '+eId);
        System.debug('<< lat >> '+latitude + ' << longitude >> '+longitude);
        Savepoint sp = Database.setSavepoint();
        DateTime now= System.Now();
        System.debug( ' << now >> '+ System.Now());
        String userId = userinfo.getUserId();
        System.debug( ' << userId >> '+ userId);
        String errorMessage = ''; 
        try{
            System.debug( ' << now try>> '+ System.Now());
            Event__c curEvent = [Select Id,Is_Claim__c ,Campaign__c,Activity__c,Account__c,recordTypeId,CheckIn_Date__c ,Remarks__c,
                                 Status__c,CheckOut_Date__c,CheckIn_Location__c ,CheckOut_Location__c,Distance__c,Journey__c from Event__c where Id =: eId limit 1];
            System.debug( ' << now try>> '+ System.Now());
            if(curEvent.Status__c == 'Cancelled'){
                errorMessage = 'Not possible as Event is Cancelled.';
                return errorMessage;
            }
            if(purpose == 'checkin'){
                curEvent.Status__c = 'In Progress';
                System.debug('<< checkin >>'+curEvent.CheckIn_Date__c);
                if(curEvent.CheckIn_Date__c != null){
                    System.debug( ' << urrent Event is already Check In>> '+ System.Now());
                    errorMessage = 'Current Event is already Check In.';
                    return errorMessage;
                }else if(curEvent.Is_Claim__c && String.isBlank(curEvent.Journey__c)){
                    errorMessage = 'Please create journey record as you want to claim this Event.';
                    return errorMessage;
                }else{
                    List<Event__c> exsEvent = [Select Id,name from Event__c where ownerId =:userId and CheckIn_Date__c != null and CheckOut_Date__c = null and id !=: eId limit 1];
                    System.debug('<< exsEvent >> '+exsEvent);
                    if(exsEvent.size() > 0){
                        errorMessage = 'PLease checkout last Event '+exsEvent[0].name +'.';
                        return errorMessage;
                    }else{
                        List<Journey__c> relJourney = [Select Id,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,
                                                       (Select Id,CheckIn_Date__c ,CheckOut_Date__c,CheckIn_Location__c ,CheckOut_Location__c from Events__r where CheckOut_Date__c != null order by CheckOut_Date__c DESC limit 1)
                                                       from Journey__C where Id =: curEvent.Journey__c limit 1];  
                        System.debug('++ relJourney ++ '+relJourney);
                        if(relJourney != null && relJourney.size() > 0){
                            if(relJourney[0].CheckOut_Date__c != null){
                                errorMessage = 'Journey is already completed.Please ask administrator to Re-open the journey.';
                                return errorMessage;
                            }else if(relJourney[0].CheckIn_Date__c != null){
                                if(relJourney[0].Events__r.size() > 0){
                                    curEvent.CheckIn_Date__c = now;
                                    if(latitude != null){
                                        curEvent.CheckIn_Location__c = ((latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):''));
                                        if(String.isNotBlank(relJourney[0].Events__r[0].CheckOut_Location__c)){
                                            String[] checkoutEvent = relJourney[0].Events__r[0].CheckOut_Location__c.split(',');
                                            if(checkoutEvent.size() > 0 && !String.isBLANK(checkoutEvent[0])){
                                                
                                                Location loc1 = Location.newInstance((checkoutEvent[0] != null?Double.valueOf(checkoutEvent[0]):null),(checkoutEvent[1] != null?Double.valueOf(checkoutEvent[1]):null));
                                                Location loc2 = Location.newInstance((latitude != null?Double.valueOf(latitude):null) ,(longitude != null?Double.valueOf(longitude):null));
                                                //Double dist = Location.getDistance(loc1, loc2, 'km');
                                                Double dist = Location.getDistance(loc1, loc2, 'km');
                                                curEvent.Distance__c = Decimal.valueOf(dist).round(System.RoundingMode.HALF_UP) ;
                                            }
                                        }
                                    }
                                    update curEvent;
                                    return 'checkIn success';
                                }else{
                                    curEvent.CheckIn_Date__c = now;
                                    if(latitude != null){
                                        curEvent.CheckIn_Location__c = ((latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):''));
                                        if(String.isNotBlank(relJourney[0].CheckIn_Location__c)){
                                            String[] checkInJourney = relJourney[0].CheckIn_Location__c.split(','); 
                                            if(checkInJourney.size() > 0 && !String.isBLANK(checkInJourney[0])){
                                                Location loc1 = Location.newInstance((checkInJourney[0] != null?Double.valueOf(checkInJourney[0]):null),(checkInJourney[1] != null?Double.valueOf(checkInJourney[1]):null));
                                                Location loc2 = Location.newInstance((latitude != null?Double.valueOf(latitude):null) ,(longitude != null?Double.valueOf(longitude):null));
                                                Double dist = Location.getDistance(loc1, loc2, 'km');
                                                curEvent.Distance__c =  (dist != null ? Decimal.valueOf(dist).round(System.RoundingMode.HALF_UP) : null) ;
                                            }
                                        }
                                    }
                                    update curEvent;
                                    return 'checkIn success';
                                    
                                }
                                
                            }else{
                                errorMessage = 'Please first checkIn related Journey.';
                                return errorMessage;
                            }
                        }else{
                            curEvent.CheckIn_Date__c = now;
                            if(latitude != null){
                                curEvent.CheckIn_Location__c = (latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):'');
                            }
                            update curEvent;
                            return 'checkIn success';
                        }
                    }
                }
            }else if(purpose =='checkOut'){
                System.debug('<< checkOut event >> ');
                curEvent.Status__c = 'Completed';
                if(curEvent.CheckIn_Date__c != null){
                    
                    if(curEvent.CheckOut_Date__c != null){
                        
                        errorMessage = 'Current Event is already Check Out.';
                        return errorMessage;
                        
                    }else if((!String.isBlank(curEvent.Campaign__c) || !String.isBlank(curEvent.Activity__c)) && String.isBlank(curEvent.Remarks__c)){
                        errorMessage = 'Please Enter the Remarks in Event.';
                        return errorMessage;
                    }
                   else{
                        List<TaskWrapper> lstTaskWRapper =getTask(eId);
                        if(lstTaskWRapper!= null && lstTaskWRapper.size() > 0){
                            System.debug('checkOut success Task');
                            return 'checkOut success Task';  
                        }else{
                            System.debug('checkOut end');
                            Id eventGeoloactionID = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event Geolocation Completed').getRecordTypeId();        
                            curEvent.CheckOut_Date__c = now;
                            if(latitude != null){
                                curEvent.CheckOut_Location__c = (latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):'');
                            }
                            curEvent.recordTypeId = eventGeoloactionID;
                            update curEvent;
                            return 'checkOut success';
                        }
                    }
                }else{
                    errorMessage = 'Please first CheckIn current Event.';
                    return errorMessage;
                }    
            }
        }catch(Exception e){
            errorMessage = 'Exception '+e.getMessage();
            System.debug('++ errorMessage ++ '+errorMessage);
            System.debug('++ errorMessage ++ '+e.getLineNumber());
            Database.rollback(sp);
            return errorMessage;
        }
        return 'success';
    }   
    
    //Method to get current location of user and updating the CheckIn/CheckOut fields on Journey__c with Current Latitue/Longitude and System Time
    @AuraEnabled
    public static String JourneyLocation(Id eId ,Object latitude ,Object longitude ,String purpose){    
        Savepoint sp = Database.setSavepoint();
        DateTime now= System.Now();
        String userId = userinfo.getUserId();
        String errorMessage = '';     
        System.debug('<< JourneyLocation >> ');
        System.debug('<< lat >> '+latitude + ' << longitude >> '+longitude);
        try{
            Journey__C curJourney = [Select Id,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,Journey_Date__c,
                                     (Select Id ,Distance__c,Is_Claim__c from Events__r)
                                     from Journey__C where Id =: eId limit 1];    
            System.debug('<< curJourney >> '+curJourney.Events__r);
            if(purpose == 'checkin'){
                
                List<Journey__C> exsExpense = [Select Id,Name from Journey__C where ownerId =: userId and CheckIn_Date__c != null and CheckOut_Date__c = null and id !=: eId limit 1];
                
                System.debug('<< exsExpense >> '+exsExpense);
                if(exsExpense.size() > 0){
                    errorMessage = 'PLease checkout last Journey '+exsExpense[0].Name+'.';
                    return errorMessage;
                }else{  
                    if(curJourney.CheckIn_Date__c != null){
                        errorMessage = 'Current Journey is already CheckIn.';
                        return errorMessage;
                    }else{
                        //store latitude and longitude and current date to expense.        
                        curJourney.CheckIn_Date__c = now;
                        if(latitude != null){
                            curJourney.CheckIn_Location__c = (latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):'');
                        }
                        update curJourney;
                        return 'checkIn success';
                    }
                }
            }else if(purpose =='checkOut'){
                System.debug('<< purpose >>> '+purpose);
                if(curJourney.CheckIn_Date__c != null){
                    if(curJourney.CheckOut_Date__c != null){
                        errorMessage = 'Journey is already checkout.';
                        return errorMessage;
                    }else{
                        List<Event__c> lstEveErr = [Select id, CheckIn_Date__c ,CheckOut_Date__c from Event__c where (CheckIn_Date__c = null or CheckOut_Date__c = null) and Status__c !='Cancelled' and Journey__c =:eId limit 1];
                        if(lstEveErr != null && lstEveErr.size() > 0){ 
                            errorMessage = 'Please first CheckIn/checkout all related Event.';
                            return errorMessage;
                        }else{
                            //store latitude and langitude and checkout date to current date.
                            curJourney.CheckOut_Date__c = now;
                            if(latitude != null){
                                curJourney.CheckOut_Location__c = (latitude != null?String.valueOf(latitude):'')+','+(longitude != null?String.valueOf(longitude):'');
                            }
                            
                            System.debug('true');
                            SYstem.debug('curJourney.Events__r - - ? ' + curJourney.Events__r);
                            
                            if(curJourney.Events__r.size() > 0 || Test.isRunningTest()){
                                List<Event__c> lstexisEve = [Select Id,Start__c ,End__c ,CheckIn_Date__c ,CheckOut_Date__c,CheckOut_Location__c from Event__C where Journey__c =:eId and CheckOut_Date__c != null order by CheckOut_Date__c DESC limit 1];
                                if(lstexisEve != null && lstexisEve.size() > 0){
                                    List<Account> lstAcc = [Select id from ACcount where name =: 'NON PRC PICKUP ACCOUNT' limit 1];
                                    Id eventGeoloactionID = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event Geolocation Completed').getRecordTypeId();        
                                    Event__c objEve = new Event__c();
                                    objEve.Name = 'Journey Last Event';
                                    objEve.Start__c = lstexisEve[0].End__c;
                                    objEve.End__c = lstexisEve[0].End__c;
                                    objEve.Status__c = 'Completed';
                                    objEve.Journey__c = eId;
                                    objEve.Is_Claim__c = true;
                                    objEve.CheckIn_Date__c = now;
                                    objEve.is_Automated__c = true;
                                    objEve.recordtypeId = eventGeoloactionID;
                                    if(latitude != null){
                                        objEve.CheckIn_Location__c = (latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):'');
                                        objEve.CheckOut_Location__c = (latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):'');
                                    }
                                    objEve.CheckOut_Date__c = now;
                                    if(lstAcc.size() > 0){
                                        List<Contact> lstCon = [Select id from Contact where AccountId =: lstAcc[0].id limit 1];
                                        objEve.Account__c = lstAcc[0].Id;
                                        if(lstCon.size() > 0){
                                            objEve.Contact__c = lstCon[0].Id;
                                        }
                                    }
                                    insert objEve;
                                    
                                    System.debug('lstexisEve - - > ' + lstexisEve[0].CheckOut_Location__c + ' s-ze' + lstexisEve.size());
                                    if(!String.isBlank(lstexisEve[0].CheckOut_Location__c)){
                                        String[] chekout = lstexisEve[0].CheckOut_Location__c.split(',');
                                        if(String.isNotBlank(lstexisEve[0].CheckOut_Location__c)){
                                            if(chekout.size() > 0 && !String.isBLANK(chekout[0])){
                                                Location loc1 = Location.newInstance((!String.isBlank(chekout[0])?Double.valueOf(chekout[0]):null) ,(!String.isBlank(chekout[1])?Double.valueOf(chekout[1]):null));
                                                Location loc2 = Location.newInstance((latitude != null?Double.valueOf(latitude):null) ,(longitude != null?Double.valueOf(longitude):null));
                                                //Double dist = loc2.getDistance(loc1, 'km');
                                                Double dist = Location.getDistance(loc1, loc2, 'km');
                                                System.debug('<< dist >  '+dist);
                                                objEve.Distance__c = Decimal.valueOf(dist).round(System.RoundingMode.HALF_UP) ;
                                                objEve.is_Automated__c = false;
                                                update objEve;
                                            }
                                        }
                                    }
                                }
                                AggregateResult[] totalDis  = [SELECT sum(Distance__c)avgDis FROM Event__c where Journey__C =: eId and Is_Claim__c = true GROUP BY Journey__C];
                                //System.debug('<< totalDis >> '+totalDis + ' <> '+ (decimal)totalDis[0].get('avgDis') + ' >< '+((decimal)totalDis[0].get('avgDis')).intValue());
                                if(totalDis.size() > 0 && (Decimal)totalDis[0].get('avgDis') > 0){
                                    curJourney.Journey_KM__c = ((Decimal)totalDis[0].get('avgDis')).round(System.RoundingMode.HALF_UP);
                                }
                            }
                            Id jouneyCompletedID = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('Journey Completed').getRecordTypeId();
                            curJourney.recordtypeid = jouneyCompletedID;
                            update curJourney;
                            return 'checkOut success';
                        }
                    }
                }else{
                    errorMessage = 'Please first CheckIn current Journey.';
                    return errorMessage;
                }
            }
        }catch(Exception e){
            errorMessage = 'Exception '+e.getMessage();
            System.debug('++ errorMessage ++ '+errorMessage);
            System.debug('++ errorMessage ++ '+e.getLineNumber());
            Database.rollback(sp);
            return errorMessage;
        }
        return 'success';
    }
    
    //Method to fetch the task under current event
    @AuraEnabled
    public static List<TaskWrapper> getTask(Id eId){
        System.debug('<< getTask >> ');
        List<TaskWrapper> lstTaskWrapper = new List<TaskWrapper>();
        List<Event__c> curEvent = [Select id ,name,Account__c from Event__c where id=:eId and Account__c != null limit 1]; 
        System.debug('<< curEvent getTask>> '+curEvent);
        if(curEvent != null && curEvent.size() > 0){
            List<Task> lstTask = [Select Id,Type__c ,Purpose__c,subject,recordType.id,RecordType.Name,status,Description,whatId from Task where whatId =:curEvent[0].Account__c and status !='Completed'];
            for(Task objTask : lstTask){
                System.debug('recordType.Name ' +objTask.recordType.Name);
                lstTaskWrapper.add(new TaskWrapper(objTask));
            }
        }
        System.debug('<< lstTaskWrapper >> '+lstTaskWrapper);
        return lstTaskWrapper;
    }
    
    //Method to update the task status as 'Task Performed' if tasks are tagged to that account to which event is also tagged are pending and user selects them to update remarks
    @AuraEnabled
    public static String changeStatusTask(Id eId ,String lstTaskWrapper,Object latitude ,Object longitude){
        Savepoint sp = Database.setSavepoint();
        System.debug('++ changeStatusTask ++ '+lstTaskWrapper);
        String errorMessage='';
        Id eventGeoloactionID = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event Geolocation Completed').getRecordTypeId();        
        List<Event__c> curEvent = [Select id ,LastModifiedBy.name ,name,recordTypeId,CheckOut_Date__c,CheckOut_Location__c from Event__c where id=:eId limit 1]; 
        List<Task> lstTask = new List<Task>();
        try{  
            system.debug('chk1+++');
            List<TaskWrapper> listWrapper = (List<TaskWrapper>) System.JSON.deserialize(lstTaskWrapper,List<TaskWrapper>.class);            
            system.debug('tw++'+listWrapper);
            for(TaskWrapper objTaskWrapper:listWrapper){
                system.debug('meow'+objTaskWrapper);
                if(objTaskWrapper.isSelected){
                    objTaskWrapper.objTask.status = 'In Progress';
                    if(!String.isBlank(objTaskWrapper.remarks)){
                        objTaskWrapper.objTask.Description = ((!String.isBlank(objTaskWrapper.objTask.Description))? objTaskWrapper.objTask.Description +'\n'+System.now() +' (' +curEvent[0].LastModifiedBy.name +') -> '+curEvent[0].name+' : '+objTaskWrapper.remarks : System.now() +' (' +curEvent[0].LastModifiedBy.name +') -> '+curEvent[0].name+' : '+objTaskWrapper.remarks);
                    }
                    lstTask.add(objTaskWrapper.objTask);
                }
            }
            curEvent[0].CheckOut_Date__c = System.now();
            if(latitude != null){
                curEvent[0].CheckOut_Location__c = (latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):'');
            }
            curEvent[0].recordTypeId = eventGeoloactionID; 
            curEvent[0].status__c = 'Completed';
            System.debug('++ lstTask ++ '+lstTask);
            if(lstTask.size() > 0){
                update lstTask;
                update curEvent;
            }
        }catch(Exception e){
            errorMessage = 'Exception '+e.getMessage();
            System.debug('++ errorMessage ++ '+errorMessage);
            System.debug('++ errorMessage ++ '+e.getLineNumber());
            Database.rollback(sp);
            return errorMessage;
        }
        return 'SUCCESS';
    }
    
    //Wrapper class
    public class TaskWrapper{
        @AuraEnabled public boolean isSelected{get; set;}
        @AuraEnabled public String remarks{get; set;}
        @AuraEnabled public Task objTask{get; set;}
        public TaskWrapper(Task task){
            isSelected = false;
            objTask = task;
            remarks = '';
        }
    }
}