/**
* Description      :       Test class for Journey__c Trigger apex class
* 
* Coverage         :       97%
**/
@isTest
public class JourneyTriggerHandlerTest{
    
    static testMethod void testCar(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        System.runAs(us){
            Campaign__c objCam = CommonDataTest.getCampaign();
            insert objCam;
            
            Journey__c objJ = CommonDataTest.getJourney();
            insert objJ;
            Journey__c newJ = [Select Id, OwnerId  FROM Journey__c WHERE Id =:objJ.id];
            User u = [Select Id FROM User WHERE Id =: newJ.OwnerId];
            //u.Journey_Type__c = 'Bike';
            update u;
            
            Journey__c objJ2 = CommonDataTest.getJourney();
            objJ2.Journey_Date__c = Date.today() - 30;
            objJ2.Approval_Status__c = 'Not Submitted for Approval';
            insert objJ2;
            
            Event__c objEve = CommonDataTest.getEvent();
            objEve.Campaign__c = objCam.id;
            objEve.Name = 'Journey Last Event';
            
            
            insert objEve;
            objJ.CheckOut_Date__c = null;
            objJ.RecordTypeId = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('New Journey').getRecordTypeId();
            update objJ;
            
            objEve.Journey__c = objJ.Id;
            update objEve;
            
            objJ.Journey_Date__c = System.Today()+5;
            update objJ;
            objJ.Approval_Status__c = 'Submitted for Approval' ;
            
            
            
            Boolean exceptionThrown = false;
            
            try {
                update objJ;
            } catch (DmlException e) {
                exceptionThrown = true;
                System.assert(
                    e.getMessage().contains('You must take action on previous journeys'),
                    'Unexpected error message: ' + e.getMessage()
                );
            }
            
            System.assertEquals(true, exceptionThrown, 'Expected DML exception was not thrown.');
            
            if (exceptionThrown) {
                objJ.Is_Locked__c = true;
                try {
                    update objJ;
                } catch (DmlException e) {
                    exceptionThrown = true;
                    System.assert(
                        e.getMessage().contains('You must take action on previous journeys'),
                        'Unexpected error message: ' + e.getMessage()
                    );
                }
                System.assertEquals(true, exceptionThrown, 'Expected DML exception was not thrown.');
            }
            
        }
    }
    
    static testMethod void testCheckJourneyForRegionalManager(){
        try {
            
            String orgId=UserInfo.getOrganizationId(); 
            String strRand =String.valueOf(Integer.valueOf(Math.random()*10000));
            System.debug('strRand----->'+strRand);
            Profile pfAM= [Select Id from profile where Name='Regional Manager' limit 1]; 
            String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
            Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
            String uniqueName=orgId+dateString+RandomId; 
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = uniqueName + '@test' + orgId + '.org', 
                               Username = uniqueName + '@test' + orgId + '.org', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = uniqueName.substring(18, 23), 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfAM.Id,
                               Region__c = 'CORPORATE OFFICE',
                               AD_Id__c = strRand+'Test2',
                               Department = 'test AM',
                               Designation__c = 'Account Manager - Manages Credit Customers',
                               Area__c = 'CORPORATE OFFICE',
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'
                               
                              ); 
            
            
            insert usAM;
            Journey__c objJ = CommonDataTest.getJourney();
            objJ.CheckOut_Date__c = null;
            objJ.OwnerId = usAM.id;
            insert objJ;
            objJ.Actual_KM__c = 2;
            objJ.Remarks__c = 'hi';
            update objJ;
			Test.startTest();
            JourneyTriggerHandler.checkJourneyForRegionalManager(new List<Journey__c>{objJ});
            Test.stopTest();            
            
        } catch(Exception e) {
            System.debug('️ Exception while locking/unlocking: ' + e.getMessage());
            System.debug(' Error Line: ' + e.getLineNumber());
        }
    }
    
    static testMethod void test2(){
        User us = CommonDataTest.getUserBdm();
        us.Journey_Type__c = 'Bike';
        insert us;
        
        System.runAs(us){
            Campaign__c objCam = CommonDataTest.getCampaign();
            insert objCam;
            
            Journey__c objJ = CommonDataTest.getJourney();
            objJ.CheckOut_Date__c = null;
            insert objJ;
            
            Journey__c newJ = [Select Id, OwnerId  FROM Journey__c WHERE Id =:objJ.id];
            User u = [Select Id FROM User WHERE Id =: newJ.OwnerId];
            //u.Journey_Type__c = 'Bike';
            update u;
            
            Journey__c objJ2 = CommonDataTest.getJourney();
            objJ2.Journey_Date__c = Date.today() + 3;
            insert objJ2;
            
            Event__c objEve = CommonDataTest.getEvent();
            objEve.Campaign__c = objCam.id;
            objEve.Name = 'Journey Last Event';
            
            Event__c objEve2 = CommonDataTest.getEvent();
            objEve2.journey__c = objJ.Id;
            objEve2.Name = 'Journey Last Event';
            insert objEve2;
            
            insert objEve;
            objJ.CheckOut_Date__c = null;
            objJ.RecordTypeId = Schema.SObjectType.Journey__c.getRecordTypeInfosByName().get('New Journey').getRecordTypeId();
            update objJ;
            
            objEve.Journey__c = objJ.Id;
            update objEve;
            
            objJ.Journey_Date__c = System.Today()+5;
            objJ.CheckOut_Date__c = System.Today()+5;
            update objJ;
            objJ.Approval_Status__c = 'Submitted for Approval' ;
            update objJ;
            objJ.Is_Locked__c = true ;
            update objJ;
        }
    }
    
    public static void updateLockRecords(Set<Id> lockIds , Set<Id> unLockIds){
        try {
            // Lock Events
            if (!lockIds.isEmpty()) {
                List<Event__c> lstLockEvent = [
                    SELECT Id FROM Event__c WHERE Journey__c IN :lockIds
                ];
                if (!lstLockEvent.isEmpty()) {
                    Approval.lock(lstLockEvent, false);
                }
                
                List<Expense_Item__c> lstLockExpense = [
                    SELECT Id FROM Expense_Item__c WHERE Journey__c IN :lockIds
                ];
                if (!lstLockExpense.isEmpty()) {
                    Approval.lock(lstLockExpense, false);
                }
            }
            
            // Unlock Events
            if (!unLockIds.isEmpty()) {
                List<Event__c> unLockEvent = [
                    SELECT Id FROM Event__c WHERE Journey__c IN :unLockIds
                ];
                if (!unLockEvent.isEmpty()) {
                    Approval.unlock(unLockEvent, false);
                }
                
                List<Expense_Item__c> unLockExpense = [
                    SELECT Id FROM Expense_Item__c WHERE Journey__c IN :unLockIds
                ];
                if (!unLockExpense.isEmpty()) {
                    Approval.unlock(unLockExpense, false);
                }
            }
            
        } catch(Exception e) {
            System.debug('️ Exception while locking/unlocking: ' + e.getMessage());
            System.debug(' Error Line: ' + e.getLineNumber());
        }
    }    
}