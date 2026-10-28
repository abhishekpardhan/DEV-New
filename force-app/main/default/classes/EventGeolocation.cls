/**
* Description		:		Controller class for EventGeolocation Lightning Component to get the current latitue/Longitude and time information and updation them on CheckIn/CheckOut Fields
* Updated By       :       Shubham Girdhar
* Created Date     :       
* Release          :       17th july, 2019
* Last Modified on :       10th july, 2019
* Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-411
**/

public with sharing class EventGeolocation{
    
    public Id eventId {get; set;}
    public List<TaskWrapper> lstTaskWrapper{get;set;}
    public String lat_long{get;set;}
    public String taskCheckOutAccuracy{get;set;} //check out accuracy
    
    //Constructor
    public EventGeolocation(ApexPages.StandardController stdController) {
        Event__c currentEvent = (Event__c)stdController.getRecord();
        eventId = currentEvent.Id;
        Id userId = UserInfo.getUserId();
        
        lstTaskWrapper = new List<TaskWrapper>();
        List<Event__c> curEvent = [Select id ,name,Account__c from Event__c where id=:eventId and Account__c != null limit 1]; 
        
        if(curEvent != null && curEvent.size() > 0){
            List<Task> lstTask = [Select Id,Type__c ,Purpose__c,subject,recordType.id,RecordType.Name,status,Description,whatId from Task where whatId =:curEvent[0].Account__c and status ='Open' and OwnerId =:userId];
            if(lstTask.size() > 0){
                for(Task objTask : lstTask){
                   
                    lstTaskWrapper.add(new TaskWrapper(objTask));
                }
            }                 
        }
       
    }
    
    //Method to get the current location of user and populating them on CheckIn/Checkout Fields
    @RemoteAction
    public static String eventLocation(Id eId ,String latitude ,String longitude ,String purpose,String accuracy){  
        
        Id Eventid = eId;
       
        Savepoint sp = Database.setSavepoint();
        DateTime now= System.Now();
        String lat = latitude;  //  added by shubham
        String longi = longitude; // added by shubham
      
        String userId = userinfo.getUserId();
        
        String errorMessage =''; 
        Boolean hasCustomPermission = FeatureManagement.checkPermission('Device_Native_ID');
        try{
           
            Event__c curEvent = [Select Id,Is_Claim__c ,Contact__c,Contact__r.Is_Complete__c,ownerId,Start__c,Campaign__c,Activity__c,Account__c,recordTypeId,CheckIn_Date__c ,Remarks__c,
                                 Status__c,CheckOut_Date__c,CheckIn_Location__c ,CheckOut_Location__c,Distance__c,Journey__c,Check_In_Accuracy__c from Event__c where Id =: eId limit 1];
           
            Datetime startDate = curEvent.Start__c;
            Datetime checkinDate = curEvent.CheckIn_Date__c;
            
            // system.debug('@@@@@@@@@@@'+ checkinDate.date());
            
            if(userId != curEvent.ownerId){
                errorMessage = 'You are not able to checkIn/checkout this Event.';
                return errorMessage;
            }
            if(curEvent.Status__c == 'Cancelled'){
                errorMessage = 'Not possible as Event is Cancelled.';
                return errorMessage;
            }
            if(purpose == 'checkin'){
                String CurrentUser = UserInfo.getUserId();
                curEvent.Status__c = 'In Progress';
              
                if(curEvent.CheckIn_Date__c != null){
                   
                    errorMessage = 'Current Event is already Check In.';
                    return errorMessage;
                }else if(curEvent.Is_Claim__c && String.isBlank(curEvent.Journey__c)){
                    errorMessage = 'Please create journey record as you want to claim this Event.';
                    return errorMessage;
                }
                else if(startDate.date() != date.today()){
                   
                    errorMessage = 'Checkin Date Should be same as start date.';
                    return errorMessage;
                }
                else{
                    List<Event__c> exsEvent = [Select Id,name from Event__c where ownerId =:userId and CheckIn_Date__c != null and CheckOut_Date__c = null and id !=: eId limit 1];
                    
                    if(exsEvent.size() > 0){
                        errorMessage = 'PLease checkout last Event : '+exsEvent[0].name +'.';
                        return errorMessage;
                    }
                    // method to calculate distance between existing event checkout geolocation and new event checking geolocation
                    else{
                       
                        
                        List<Journey__c> relJourney = [Select Id,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,
                                                       (Select Id,CheckIn_Date__c ,CheckOut_Date__c,CheckIn_Location__c ,CheckOut_Location__c from Events__r where CheckOut_Date__c != null order by CheckOut_Date__c DESC limit 1)
                                                       from Journey__C where Id =: curEvent.Journey__c limit 1];  
                        
                        if(relJourney != null && relJourney.size() > 0){
                            if(relJourney[0].CheckOut_Date__c != null){
                                errorMessage = 'Journey is already completed.Please ask administrator to Re-open the journey.';
                                return errorMessage;
                            }
                            else if(relJourney[0].CheckIn_Date__c != null){
                                if(relJourney[0].Events__r.size() > 0){
                                    curEvent.CheckIn_Date__c = now;
                                    if(hasCustomPermission){
                                        curEvent.CheckIn_DeviceNativeUid__c=JourneyDeviceNativeId.getDeviceNativeId(userId);
                                    }
                                    if(String.isNotBlank(latitude) != null){
                                        curEvent.CheckIn_Location__c = latitude+','+longitude;
                                        curEvent.Check_In_Accuracy__c = Decimal.ValueOf(accuracy);
                                        if(String.isNotBlank(relJourney[0].Events__r[0].CheckOut_Location__c)){
                                            String[] checkoutEvent = relJourney[0].Events__r[0].CheckOut_Location__c.split(',');
                                            if(checkoutEvent.size() > 0 && !String.isBLANK(checkoutEvent[0])){
                                                
                                                //   Location loc1 = Location.newInstance((checkoutEvent[0] != null?Double.valueOf(checkoutEvent[0]):null),(checkoutEvent[1] != null?Double.valueOf(checkoutEvent[1]):null));
                                                //   Location loc2 = Location.newInstance((latitude != null?Double.valueOf(latitude):null) ,(longitude != null?Double.valueOf(longitude):null));
                                                //   Double dist = Location.getDistance(loc1, loc2, 'km');  
                                            }
                                            // Calling the API to calculate distance between existing event checkout and new event checkin
                                            DistanceCalculationApi.TotalArea(eId);
                                        }
                                        
                                    }
                                    update curEvent;
                                    return 'checkIn success';
                                    
                                }
                                // Method to calculate distance between journey checkIn geolocation and new event checkIn geolocation
                                else{
                                    curEvent.CheckIn_Date__c = now;
                                    if(hasCustomPermission){
                                        curEvent.CheckIn_DeviceNativeUid__c=JourneyDeviceNativeId.getDeviceNativeId(userId);
                                    }
                                    if(String.isNotBlank(latitude)){
                                        curEvent.CheckIn_Location__c = latitude  +','+longitude;
                                        curEvent.Check_In_Accuracy__c = Decimal.ValueOf(accuracy);
                                      
                                        if(String.isNotBlank(relJourney[0].CheckIn_Location__c)){
                                            String[] checkInJourney = relJourney[0].CheckIn_Location__c.split(','); 
                                            if(checkInJourney.size() > 0 && !String.isBLANK(checkInJourney[0])){
                                                //     Location loc1 = Location.newInstance((checkInJourney[0] != null?Double.valueOf(checkInJourney[0]):null),(checkInJourney[1] != null?Double.valueOf(checkInJourney[1]):null));
                                                //    Location loc2 = Location.newInstance((latitude != null?Double.valueOf(latitude):null) ,(longitude != null?Double.valueOf(longitude):null));
                                                //    Double dist = Location.getDistance(loc1, loc2, 'km'); 
                                            }
                                            // calling the API to calculate distance between journey checkin and new event checkin
                                            DistanceCalculationApi.TotalArea(eId);
                                        }
                                    }
                                    update curEvent;
                                    return 'CheckIn Success';
                                    
                                }
                                
                            }else{
                                errorMessage = 'Please first checkIn related Journey.';
                                return errorMessage;
                            }
                        }else{
                            curEvent.CheckIn_Date__c = now;
                            curEvent.Check_In_Accuracy__c = Decimal.ValueOf(accuracy);
                            if(latitude != null){
                                curEvent.CheckIn_Location__c = (latitude != null?String.valueOf(latitude):'') +','+(longitude != null?String.valueOf(longitude):'');
                            }
                            update curEvent;
                            return 'checkIn success';
                        }
                    }
                    
                }
                
            }else if(purpose =='checkOut'){
               
                curEvent.Status__c = 'Completed';
                 
                if(curEvent.Contact__c!=null){
                    Boolean isComplete=EventController.isContactComplete(curEvent.Contact__c);
                    If(!isComplete){
                        errorMessage = 'Contact is not complete. Please complete the contact before check out.';
                        return errorMessage;
                    }     
                }
                
                if(curEvent.CheckIn_Date__c != null){
                    
                    if(curEvent.CheckOut_Date__c != null){
                        
                        errorMessage = 'Current Event is already Check Out.';
                        return errorMessage;
                        
                    } else if(String.isBlank(curEvent.Remarks__c)){
                        errorMessage = 'Please Enter the recap of meeting in Event.';
                        return errorMessage;
                    }
                    
                    else{
                        List<Task> lstTask = [Select Id,Type__c ,Purpose__c,subject,recordType.id,RecordType.Name,status,Description,whatId from Task where whatId =: curEvent.Account__c and status !='Completed' and  whatId != null and OwnerId =:userId];
                       
                        if(lstTask!= null && lstTask.size() > 0){
                           
                            return 'checkOut success Task';  
                        }else{
                           
                            Id eventGeoloactionID = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event Geolocation Completed').getRecordTypeId();        
                            curEvent.CheckOut_Date__c = now;
                            if(hasCustomPermission){
                                curEvent.CheckOut_DeviceNativeUid__c=JourneyDeviceNativeId.getDeviceNativeId(userId);
                            }
                            if(String.isNotBlank(latitude)){
                                curEvent.CheckOut_Location__c = latitude +','+longitude;
                                curEvent.Check_Out_Accuracy__c = Decimal.ValueOf(accuracy);
                                //curEvent.CheckOut_Address__c = 'CheckOut Successful';
                            }
                            curEvent.recordTypeId = eventGeoloactionID;
                            try{
                                     update curEvent;
                                     if(!Test.IsRunningTest()){
                                System.enqueueJob(new AddressCalculationQueueable(eId, null, true, 'checkout' ));
                                }
                            }
                            catch(Exception e){
                                return e.getMessage();
                            }
                           
                            
                           
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
           
            Database.rollback(sp);
            return errorMessage;
        }
        return 'success';
        
    }         
    //Method to update the task status as 'Task Performed' if tasks are tagged to that account to which event is also tagged are pending and user selects them to update remarks
    @RemoteAction
    Public static String eventTaskCheck(Id EventId){
        try{
            return journeyTaskCheckController.eventTaskCheck(EventId);
        }
        catch(Exception e){
            ExceptionHandling.Exception('EventGeolocation','eventTaskCheck',e);
            Throw e;
        }
    }
    public void changeStatusTask(){
        String userId = userinfo.getUserId();
        Boolean hasCustomPermission = FeatureManagement.checkPermission('Device_Native_ID');
       
        Savepoint sp = Database.setSavepoint();
        
        String errorMessage='';
        Id eventGeoloactionID = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event Geolocation Completed').getRecordTypeId();        
        List<Event__c> curEvent = [Select id ,LastModifiedBy.name ,name,recordTypeId,CheckOut_Date__c,CheckOut_Location__c,Check_In_Accuracy__c from Event__c where id=:eventId limit 1]; 
        List<Task> lstTask = new List<Task>();
        try{  
            
            for(TaskWrapper objTaskWrapper:lstTaskWrapper){
               
                if(objTaskWrapper.isSelected){
                    objTaskWrapper.objTask.status = 'In Progress';
                    if(!String.isBlank(objTaskWrapper.remarks)){
                        objTaskWrapper.objTask.Description = ((!String.isBlank(objTaskWrapper.objTask.Description))? objTaskWrapper.objTask.Description +'\n'+System.now() +' (' +curEvent[0].LastModifiedBy.name +') -> '+curEvent[0].name+' : '+objTaskWrapper.remarks : System.now() +' (' +curEvent[0].LastModifiedBy.name +') -> '+curEvent[0].name+' : '+objTaskWrapper.remarks);
                    }
                    lstTask.add(objTaskWrapper.objTask);
                }
            }
            curEvent[0].CheckOut_Date__c = System.now();
            if(hasCustomPermission){
                                curEvent[0].CheckOut_DeviceNativeUid__c=JourneyDeviceNativeId.getDeviceNativeId(userId);
                            }
            if(String.isNotBlank(lat_long)){
                curEvent[0].CheckOut_Location__c = lat_long;
                curEvent[0].Check_Out_Accuracy__c = Decimal.ValueOf(taskCheckOutAccuracy);
            }
            curEvent[0].recordTypeId = eventGeoloactionID; 
            curEvent[0].status__c = 'Completed';
            
            if(lstTask.size() > 0){
                update lstTask;
            }
            update curEvent;
            if(!Test.IsRunningTest()){
                System.enqueueJob(new AddressCalculationQueueable(eventId, null, true, 'checkout' ));
            }
            
        }
        catch(Exception e){
            errorMessage = 'Exception '+e.getMessage();
            Database.rollback(sp);
        }
    }
    //Wrapper Class
    public class TaskWrapper{
        public boolean isSelected{get; set;}
        public String remarks{get; set;}
        public Task objTask{get; set;}
        public TaskWrapper(Task task){
            isSelected = false;
            objTask = task;
            remarks = '';
        }
    }
}