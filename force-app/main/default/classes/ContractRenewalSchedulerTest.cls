@isTest
public class ContractRenewalSchedulerTest {

    @isTest
    static void testSchedulerExecution() {
        
        // Start test context
        Test.startTest();
        
        // Schedule the job (cron expression: run immediately in test context)
        String cronExp = '0 0 0 1 1 ? 2050';
        ContractRenewalScheduler scheduler = new ContractRenewalScheduler();
        System.schedule('Test Contract Renewal Scheduler', cronExp, scheduler);
        
        // Stop test context → this triggers scheduled job execution
        Test.stopTest();
        
        // Assert that the scheduled job was created
        List<CronTrigger> cronList = [
            SELECT Id, CronExpression, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Test Contract Renewal Scheduler'
        ];
        
        System.assertEquals(1, cronList.size(), 'Scheduler job should be created');
    }
}