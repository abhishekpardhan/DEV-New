@isTest
private class ScheduleCancelledInvoicesTest {
    static testmethod void testIsValidFromToDate() {
        String cronExp = '0 0 0 15 3 ? 2030'; // Midnight on March 15, 2030
        
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', cronExp, new ScheduleCancelledInvoices());
        Test.stopTest();
    }
    
}