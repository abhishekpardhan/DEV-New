/**
@File Name : ContractRenewalBatch.cls
@Description : Batch class used to execute the ContractRenewalBatch
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
public class ContractRenewalBatch implements Database.Batchable<SObject>{

    public Database.QueryLocator start(Database.BatchableContext bc){

        Date today = Date.today();

        Date day60 = today.addDays(ConstantUtility.REMINDER_DAY_60);
        Date day30 = today.addDays(ConstantUtility.REMINDER_DAY_30);
        Date day90 = today.addDays(ConstantUtility.REMINDER_DAY_90);
         
        return Database.getQueryLocator([
            SELECT Id, Name, Contract_End_Date__c,
                   Account__r.Name, Account__c,Account__r.Propel_MSACode__c, RecordType.DeveloperName,
                   (SELECT Id, SFX_Code__c FROM Accounts__r)
            FROM Contract__c
            WHERE Contract_End_Date__c != NULL
            AND RecordTypeId = :ConstantUtility.CONTRACT_CLOSED_RECORDTYPE_ID
            AND Contract_End_Date__c IN :new List<Date>{day60, day30, day90}
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Contract__c> scope){

        ContractRenewalService.processContracts(scope);

    }

    public void finish(Database.BatchableContext bc){
        // Optional: Replace with proper logging if needed
        System.debug('Contract Renewal Batch Finished');
    }
}