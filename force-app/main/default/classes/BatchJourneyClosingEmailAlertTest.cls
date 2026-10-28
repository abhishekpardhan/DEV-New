@isTest 
public class BatchJourneyClosingEmailAlertTest {
   static testMethod void testMethod1(){
    User User1 = CommonDataTest.getUserAM();
       User1.Email = 'random@gmail.com';
        insert User1;
       
       
       Journey__c objJ = new Journey__c();
        objJ.Journey_Date__c    = System.TODAY()-3;
        objJ.CheckIn_Date__c = SYstem.now()-3;
        objJ.CheckIn_Location__c = '28.4595,77.0266';
       objJ.Mode_of_transport__c = 'Public';
      objJ.OwnerId = user1.Id;
       // objJ.Mode_of_transport__c = 'Public';
        insert ObjJ;
        
        Event__c objEve = new Event__c();
        objEve.Start__c = System.Today()-3;
        objEve.End__c = System.Today()-3;
        objEve.CheckIn_Date__c = System.now()-3;
        objEve.CheckIn_Location__c = '24.4089,77.3178';
        objEve.CheckOut_Date__c = System.now()-3 ; 
        objEve.CheckOut_Location__c = '28.63,77.25';
        objEve.Is_Claim__c = false;
        objEve.Activity__c = 'Others';
      objEve.If_Others_Please_Specify__c = 'ok';
        objEve.Journey__c = objJ.Id;
       objEve.OwnerId = user1.Id;
        Insert objEve;

         Test.StartTest();
        BatchJourneyClosingEmailAlert Task = new BatchJourneyClosingEmailAlert();
      //  ID batchprocessid = Database.executeBatch(Task);

        String sch = '0 0 10 * * ?';
        system.schedule('Test Territory Check', sch, Task);
       
        Test.stopTest();  
    }
}