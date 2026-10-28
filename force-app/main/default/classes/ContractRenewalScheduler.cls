/**
@File Name : ContractRenewalScheduler.cls
@Description : Scheduler class used to execute the ContractRenewalBatch
@Author : Anand Raju
@Group : Grant Thornton Bharat
@Last Modified By : Anand Raju
@Last Modified On : 13-03-2026
@Modification Log :
*==============================================================================

  Ver                Date                 Author                  Modification
*==============================================================================

1.0               13-03-2026            Anand Raju               Initial Version SAC-2368
**/

public class ContractRenewalScheduler implements Schedulable {

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new ContractRenewalBatch(), 200);
    }
}