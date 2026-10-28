/**
 * @File Name          : OTRS_StatusUpdateBatchScheduler.cls
 * @Description        : This class is a scheduler class for the OTRS_StatusUpdateBatch
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 04-08-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        04-08-2021                Deepak                   Initial Version
**/
public class OTRS_StatusUpdateBatchScheduler implements Schedulable {
    public void execute(SchedulableContext SC) {
        OTRS_StatusUpdateBatch batch = new OTRS_StatusUpdateBatch();
        Database.executeBatch(batch,1); // Always run on one size so we can have the API logs
    }
    /** Cron Express to schedule the batch class
    * NEED TO RUN EVERY HOUR*/
   /* OTRS_StatusUpdateBatchScheduler otrsStatusUpdateBatchScheduler = new OTRS_StatusUpdateBatchScheduler();
    String sch = '0 0 0/1 1/1 * ? *';
    String jobID = system.schedule('Update OTRS Status On Case - Every Hour', sch, otrsStatusUpdateBatchScheduler);
    */
}