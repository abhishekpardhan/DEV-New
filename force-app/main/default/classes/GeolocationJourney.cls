/**
 * Description      :       Controller class for JourneyGeolocation Lightning Component to get the current latitue/Longitude and time information and updation them on CheckIn/CheckOut Fields
 * Updated By       :       Monika Rawat
 * Created Date     :       
 * Release          :       17th july, 2019
 * Last Modified on :       26th august, 2019
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-411
                            https://safexpress.atlassian.net/browse/SD-456
**/

public with sharing class GeolocationJourney{
    
    public Id JourneyId {get; set;}
    
    //Constructor
    public GeolocationJourney(ApexPages.StandardController stdController) {
        Journey__c currentEvent = (Journey__c)stdController.getRecord();
        JourneyId = currentEvent.Id;
    }
    
    //Method to get the current location of user and populating them on CheckIn/Checkout Fields
    @RemoteAction
    public static String JourneyLocation(Id eId ,String latitude ,String longitude ,String purpose,String accuracy){    
        Savepoint sp = Database.setSavepoint();
        DateTime now= System.Now();
        String userId = userinfo.getUserId();
        String errorMessage = ''; 
        Boolean hasCustomPermission = FeatureManagement.checkPermission('Device_Native_ID');

      
        try{
            Journey__C curJourney = [Select Id,OwnerId ,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckIn_Address__c,CheckOut_Address__c,CheckOut_Location__c,Journey_Date__c,Check_In_Accuracy__c,Check_Out_Accuracy__c,
                                     (Select Id ,Distance__c,Is_Claim__c from Events__r)
                                     from Journey__C where Id =: eId limit 1];    
          
            String tasknotCompleted = 'False';
            if(userId != curJourney.ownerId){
                errorMessage = 'You are not able to checkIn/checkout this Event.';
                return errorMessage;
            }
            if(purpose == 'checkin'){
               // if(curJourney.Journey_Date__c == date.today()){ 
                List<Journey__C> exsExpense = [Select Id,Name from Journey__C where ownerId =: userId and CheckIn_Date__c != null and CheckOut_Date__c = null and id !=: eId limit 1];
                
               
                if(exsExpense.size() > 0){
                    errorMessage = 'PLease checkout last Journey '+exsExpense[0].Name+'.';
                    return errorMessage;
                }else{  
                    if(curJourney.CheckIn_Date__c != null){
                        errorMessage = 'Current Journey is already CheckIn.';
                        return errorMessage;
                    }
                    // Error If user is CHecking In to a future Journey added by Shubham on 04/11/2019
                    else if(curJourney.Journey_Date__c > date.today()){
                      
                        errorMessage = 'You can not CheckIn The Journey with Future Date';
                        return errorMessage;
                    }
                    else If(curJourney.Journey_Date__c != date.today()){
                      
                      errorMessage = 'Checkin Date should be same as Journey Date';
                      return errorMessage;  
                    }
                    else{
                        //store latitude and longitude and current date to expense. 
                            
                        curJourney.CheckIn_Date__c = now; 
                        curJourney.Check_In_Accuracy__c = Decimal.ValueOf(accuracy);
                        curJourney.CheckIn_Address__c = 'CheckIn Successful';
                        if(String.isNotBlank(latitude)){
                            curJourney.CheckIn_Location__c = latitude +','+longitude;
                        }
                         if(hasCustomPermission){
                        curJourney.CheckIn_DeviceNativeUid__c =JourneyDeviceNativeId.getDeviceNativeId(userId);
                         }
                        update curJourney; 
                        System.enqueueJob(new AddressCalculationQueueable(null, eId, true, 'checkin' ));
                        return 'checkIn success';
                    }
                }
                /*}else{
                    system.debug('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa');
                     errorMessage = 'You can not CheckIn The Journey with Future Date';
               return errorMessage;
                }*/
            }else if(purpose =='checkOut'){
               
                if(curJourney.CheckIn_Date__c != null){
                    if(curJourney.CheckOut_Date__c != null){
                        errorMessage = 'Journey is already checkout.';
                        return errorMessage;
                    }else{
                        List<Event__c> lstEveErr = [Select id, CheckIn_Date__c ,CheckOut_Date__c from Event__c where (CheckIn_Date__c = null or CheckOut_Date__c = null) and Status__c !='Cancelled' and Journey__c =:eId limit 1];
                        
                        if(lstEveErr != null && lstEveErr.size() > 0){ 
                            errorMessage = 'Please first CheckIn/checkout all related Event.';
                            return errorMessage;
                        }
                        tasknotCompleted = journeyTaskCheck(eId);
                        if(tasknotCompleted == 'True'){
                             
                             errorMessage = 'Please take action on General/CRP/Onboarding task with open status to proceed with journey checkout.';
                             return errorMessage;
                        }
                        else{
                            //store latitude and langitude and checkout date to current date.
                            curJourney.CheckOut_Date__c = now;
                            curJourney.Check_Out_Accuracy__c = Decimal.ValueOf(accuracy);
                            if(String.isNotBlank(latitude)){
                                curJourney.CheckOut_Location__c = latitude+','+longitude;
                            }
                            if(hasCustomPermission){
                            curJourney.CheckOut_DeviceNativeUid__c =JourneyDeviceNativeId.getDeviceNativeId(userId);
                            }
                             
                            // Method to create an automated event named Journey Last Event
                            if(curJourney.Events__r.size() > 0 || Test.isRunningTest()){
                                List<Event__c> lstexisEve = [Select Id,Start__c ,End__c,Is_Claim__c,CheckIn_Date__c ,CheckOut_Date__c,CheckOut_Location__c from Event__C where Journey__c =:eId and CheckOut_Date__c != null order by CheckOut_Date__c DESC limit 1];
                                if(lstexisEve != null && lstexisEve.size() > 0){
                                  //Commented by Monika  List<Account> lstAcc = [Select id from ACcount where name =: 'NON PRC PICKUP ACCOUNT' limit 1];
                                    Id eventGeoloactionID = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event Geolocation Completed').getRecordTypeId();        
                                    Event__c objEve = new Event__c();
                                    objEve.Name = 'System Event';
                                    objEve.Start__c = lstexisEve[0].End__c;
                                    objEve.End__c = lstexisEve[0].End__c;
                                    objEve.Status__c = 'Completed';
                                    objEve.Journey__c = eId;
                                    objEve.Is_Claim__c = lstexisEve[0].Is_Claim__c;
                                    objEve.CheckIn_Date__c = now;
                                    objEve.is_Automated__c = true;
                                    objEve.recordtypeId = eventGeoloactionID;
                                    objEve.Activity__c = 'General'; //Added by Monika
                                    if(String.isNotBlank(latitude)){
                                        objEve.CheckIn_Location__c = latitude +','+longitude;
                                        objEve.CheckOut_Location__c = latitude+','+longitude;
                                    }
                                    objEve.CheckOut_Date__c = now;
                                    
                                  /*  if(lstAcc.size() > 0){
                                          List<Contact> lstCon = [Select id from Contact where AccountId =: lstAcc[0].id limit 1];
                                          objEve.Account__c = lstAcc[0].Id;
                                          if(lstCon.size() > 0){
                                          objEve.Contact__c = lstCon[0].Id;
                                        }
                                    } Commented out by Monika*/
                                    insert objEve;
                                    if(!String.isBlank(lstexisEve[0].CheckOut_Location__c)){
                                        String[] chekout = lstexisEve[0].CheckOut_Location__c.split(',');
                                        if(String.isNotBlank(lstexisEve[0].CheckOut_Location__c)){
                                            if(chekout.size() > 0 && !String.isBLANK(chekout[0])){
                                                Location loc1 = Location.newInstance((!String.isBlank(chekout[0])?Double.valueOf(chekout[0]):null) ,(!String.isBlank(chekout[1])?Double.valueOf(chekout[1]):null));
                                                Location loc2 = Location.newInstance((latitude != null?Double.valueOf(latitude):null) ,(longitude != null?Double.valueOf(longitude):null));
                                                update objEve;
                                            }
                                        }
}
                                        // Calling the API to calculate distance between event checkout and journey checkout    
                                   JourneyDistanceCalculationApi.journeyArea(eid);
                                }
                              
                            } else{
                                System.enqueueJob(new AddressCalculationQueueable(null, eid, false, 'checkout' ));
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
          // method to handle exception added by Shubham Girdhar on 26/7/2019
            String name = 'Journey';
            String ClassName = 'GeolocationJourney';
            ExceptionHandling.Exception( name, ClassName, e);
            
          //  errorMessage = 'Exception '+e.getMessage();
          // System.debug('++ errorMessage ++ '+errorMessage);
          //  System.debug('++ errorMessage ++ '+e.getLineNumber());
          //  Database.rollback(sp);
          //  return errorMessage;
        }
        return 'success';
    }
    
     public static String journeyTaskCheck(Id JourneyId){
        try{
           return journeyTaskCheckController.journeyTaskCheck(JourneyId);
        }
        catch (Exception e) {
           ExceptionHandling.Exception('TaskCompletedCheck','GeolocationJourney',e);
           Throw e;
        }   
    }
}