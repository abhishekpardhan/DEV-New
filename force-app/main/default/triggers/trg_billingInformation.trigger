/***********************************************************
**Author: Safexpress Private limited
**Description:  trigger is written to auto-populate the billing level at SFX(Account Type).
**JIRA Ticket: https://safexpress.atlassian.net/browse/SD-862
**Test Class:
History: 
Modified By:
Modified Date: 
Comment: 

************************************************************/
trigger trg_billingInformation on Billing_Information__c (After Insert, After Update) {

    // trigger handler class to auto-populate biling level on SFX. 
    trg_billingInformationHandler.handlerOperations(Trigger.newMap, Trigger.OldMap, Trigger.operationType, Trigger.isInsert, Trigger.isUpdate);

}