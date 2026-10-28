/**
 * @File Name          : CreateCustomCase.cls
 * @Description        : This class will help to create a custom case record in salesforce
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 25-10-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0       25-10-2021                Deepak                   Initial Version
**/
public class CreateCustomCase {
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to create a custom case record from complaint support case for claim request
    @Date            : 27/09/2021
    */
    @AuraEnabled
    public static String createCase(String recordId) {
        try {
            List<Case> cases = new List<Case>();
            cases = [SELECT CaseNumber,Sub_Type__c,WaybillNo__c,Have_Claim_Request__c,SFX__c,PRC__c FROM Case WHERE Id = :recordId LIMIT 1];
            if (cases.size() > 0) {
                Case__c customCase = new Case__c();
                customCase.Account__c = cases[0].SFX__c != null ? cases[0].SFX__c : cases[0].PRC__c;
                customCase.Support_Case__c = cases[0].Id;
                customCase.Case_Typee__c = ConstantUtility.CLAIM_ISSUES;
                customCase.Case_Type__c = cases[0].Sub_Type__c;
                customCase.Waybill_No__c = cases[0].WaybillNo__c;
                customCase.RecordTypeId = Schema.SObjectType.Case__c.getRecordTypeInfosByDeveloperName().get('Claim_Issues').getRecordTypeId();
                insert customCase;
                cases[0].Have_Claim_Request__c = true;
                TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
                update cases;
                TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);
                return 'Claim Request Created Successfully';
            }
            return null;
        } catch (Exception exp) {
            System.debug(' Exception Message ::' + exp.getMessage() + ' Class Name : CreateCustomCase at Line ::' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CreateCustomCase', 'createCase', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
            throw new AuraHandledException(exp.getMessage());
        }
    }
}