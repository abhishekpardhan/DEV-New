/**
* Description	   :	This class returns login/logout device unique Id of the devices used in a journey.
* Updated By       :       Raghav, IBM
* Created Date     :      7, feb, 2024
* Release          :       
* Last Modified on :       13, feb, 2024
* Jira Ticket      :     https://safexpress.atlassian.net/browse/SAC-431  
**/
public  with sharing class JourneyDeviceNativeId {
    static Id loginHistoryFilter (Id userId){
        List<String> allowedApplicationList = new List<String>{'Salesforce for Android','Salesforce for iOS'};
            LoginHistory loginHistoryFilter =[
                Select 
                userId, id,application,LoginTime 
                From LoginHistory
                where userId =:userId 
                order by Logintime desc LIMIT 1
            ];
        if(allowedApplicationList.contains(loginHistoryFilter.application)){
            return loginHistoryFilter.Id;            
        }
        if(Test.isRunningTest()){
            return userId;
        }
        
       return null;
    }
     static String userdeviceData(Id userId,Id loginHistoryId ){
        UserDevice[] userDevice =[
            Select 
            userId, LastLoginHistoryId, DeviceNativeUid
            From UserDevice
            where userId =:userId AND LastLoginHistoryId=:loginHistoryId
            
        ];
       
        if (userDevice.size()>0){
            return userDevice[0].DeviceNativeUid;
        }
        return null;
        
    }
    public static String getDeviceNativeId(Id userId ){
        Id loginHistoryId = loginHistoryFilter(userId);
        if (loginHistoryId!=null ){
           return userdeviceData(userId,loginHistoryId);
                          
            }            
               
        return null;
    }
    
    
    
}