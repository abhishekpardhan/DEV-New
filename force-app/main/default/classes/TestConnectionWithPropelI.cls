/* Test class to test ConnectionWithPropelI */

@isTest
public class TestConnectionWithPropelI {
    
    static testMethod void unitTestMethod1(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ConnectionWithPropelI.connectWithPropelI();
        Test.stopTest(); 
        // Verify the results
        
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'BackSFXUpdateFuture'];
        
    }
    
    static testMethod void unitTestMethodSchedular(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Scheduler_ConnectionWithPropelI schedular = new Scheduler_ConnectionWithPropelI();
        
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Scheduler_ConnectionWithPropelI Check', sch, schedular); 
        
        
        
        Test.stopTest(); 
        
    }
    
}