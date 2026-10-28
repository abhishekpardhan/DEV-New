//Class to grab the sport fire reports for the currently logged in user and show them on custom page
public class SportFireReports {
    
    //Method to get the SPOT Fire reports for the current user
    @AuraEnabled
    public static List<SportWrapper> getReportLinks(){ 
        List<SportWrapper> lstWrap = new List<SportWrapper>();
        Integer srNo=0;
        try{
            String curUserId = userInfo.getUserId();
            List<User> lstUser = [select id ,Sportfire_Group__c from User where Id =: curUserId limit 1];
            //List<UserLogin> lstStandUser= [SELECT IsFrozen, UserId FROM UserLogin WHERE UserId IN (SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND UserType = 'Standard' AND IsActive=True) and IsFrozen = false limit 1];
            if( !String.isBlank(lstUser[0].Sportfire_Group__c)){
            	List<SpotFire_Group__c> lstSpotGroup = [Select id ,Group__c,Report_Link__c,Name from SpotFire_Group__c where Group__c =: lstUser[0].Sportfire_Group__c];
                if(!lstSpotGroup.isEmpty() && lstSpotGroup.size() > 0)
                for(SpotFire_Group__c objSpG : lstSpotGroup){
                    srNo++;
					lstWrap.add(new SportWrapper(objSpG, String.ValueOf(srNo)));
                }
            }
            System.debug('<< lstWrap >> '+lstWrap);
            return lstWrap;
        }catch(Exception e){
            lstWrap.add(new SportWrapper(new SpotFire_Group__c(), 'Exception '+e.getMessage()));
            System.debug('++ errorMessage ++ '+e.getMessage());
            System.debug('++ errorMessage ++ '+e.getLineNumber());
            return lstWrap;
        }
    }
    
    //Wrapper Class
    public class SportWrapper{
        @AuraEnabled public String srNo{get; set;}
        @AuraEnabled public SpotFire_Group__c objSGroup{get; set;}
        public SportWrapper(SpotFire_Group__c objSG , String sr){
            srNo = sr;
            objSGroup = objSG;
        }
    }
}