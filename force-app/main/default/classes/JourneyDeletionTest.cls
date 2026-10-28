@isTest 
public class JourneyDeletionTest {
    static testMethod void testMethod1(){
        //    Journey__c objJ = new Journey__c();
        //    objJ.Journey_Date__c    = System.TODAY();
        //  insert objJ;
        User User1 = CommonDataTest.getUserAM();
        User1.Email = 'random@gmail.com';
        insert User1;
        
        
        Journey__c objJ = new Journey__c();
        objJ.Journey_Date__c    = System.TODAY()-3;
        objJ.OwnerId = User1.Id;
        objJ.Mode_of_transport__c = 'Public';
        insert ObjJ;
        
        
        Test.StartTest();
        JourneyDeletion Task = new JourneyDeletion();
        String sch = '0 0 10 * * ?';
        system.schedule('Test status Check', sch, Task );      
        Test.stopTest();  
    }
}