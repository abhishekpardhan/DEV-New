/**
    * @Description        : This class is the scheduler class for the Batch class PincodeInfoBatch
    * @Author             : Deepak
    * @Group              : Techmatrix
    * @Last Modified By   : Deepak
    * @Last Modified On   : 08/12/2021
    * @Modification Log   :
    *==============================================================================
    * Ver         Date                     Author                    Modification
    *==============================================================================
    * 1.0        08/12/2021                Deepak                   Initial Version
**/


public class PincodeInfoBatchScheduler implements Schedulable{

    public void execute(SchedulableContext SC) {
        PincodeInfoBatch pincodeInfoBatch = new PincodeInfoBatch();
        Database.executeBatch(pincodeInfoBatch,1); // Always run on batch size 1
    }

    /**
        EXPRESS TO SCHEDULE THIS CLASS FOR EVERYDAY AT 12:00 AM NIGHT

        PincodeInfoBatchScheduler schObj  = new PincodeInfoBatchScheduler();
        String runTime = '0 0 0 1/1 * ? *';
        String jobID = system.schedule('Update Pincode Table/Object Daily at 12:00 AM', runTime, schObj);

    */
}