@isTest
public class PreBookingAPISchedulableTest {
    
    @testSetup
    public static void dataSetupMethod() {
        List <Account> listAccount = new List<Account>();
        listAccount.add(new Account(Name = 'test1'));        
        insert listAccount; 
        
        Integration_Transaction__c reqDetail = new Integration_Transaction__c();
        reqDetail.Object_Name__c = 'Account';
        reqDetail.record_id__c = listAccount[0].Id; 
        reqDetail.Operation_Type__c = 'Create customer' ;
        reqDetail.No_of_Retries__c = 1;
        reqDetail.MSAPushEndpoint__c = 'www.google.com';
        reqDetail.Status__c = 'Fail';
        reqDetail.Operation_Type__c = 'PropelICaseCreation';
        insert reqDetail;
    }
    
    static testMethod void testschedule() {
        Test.startTest();
        String sch = '0 0 * * * ?';
        PreBookingAPISchedulable job = new PreBookingAPISchedulable();
        String jobName = 'PreBookingAPISchedulable';
        System.schedule(jobName, sch, job);
        Test.stopTest();
    }

}