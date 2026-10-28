/**
 * Description		:		Test class for Target Trigger apex class
 * 
 * Coverage			:		100%
 **/
@isTest
public class TargetActionsTest
{
    private static testmethod void createAutoTargets()
    {
        
        
        
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        system.runAs(new User(Id=UserInfo.getUserID()))
        {
            UserRole AMRole = new UserRole(Name = 'AM North'); 
            insert AMRole ;
            UserRole BDMRole = new UserRole(Name = 'BDM North', parentRoleId=AMRole.Id );
            insert BDMRole;
            
            User usAm = CommonDataTest.getUserAM();
            usAm.UserRoleId = AMRole.Id;
            usAm.Region__c='MADHYA PRADESH - CHHATTISGARH';
            usAm.Area__c = null;
            insert usAm;
            
            User us = CommonDataTest.getUserBdm();
            us.UserRoleId = BDMRole.Id;
            us.Area__c = null;
            us.Region__c='MADHYA PRADESH - CHHATTISGARH';
            insert us;
                                        
        }
        List<RecordType> lstRecordRegion = [Select Id, DeveloperName from RecordType where SobjectType= 'Target__c' and DeveloperName = 'Region' limit 1] ;
        Id regionId = lstRecordRegion[0].Id; 
        insert new Target__c(Level__c = 'Region Level', Region__c='MADHYA PRADESH - CHHATTISGARH',
                    Area__c='INDORE', Business_Type__c='Credit', recordTypeId = regionId );
                    
    }
}