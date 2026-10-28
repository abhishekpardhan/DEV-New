/** ---------------------------------------------------------
    Author:        KR SANSI
    Description:   Integration Transaction Trigger
    History
    Date            Author             Comments
    ----------------------------------------------------------
    08/05/2024     KR SANSI          Initial Release
    -----------------------------------------------------------
*/
trigger IntegrationTransactionTrigger on Integration_Transaction__c (before insert, before update, after insert, after update) {

    new IntegrationTransactionHandler().run();   
    
}