/*------------------------------------------------------------
 * Author: Safexpress team
 * Description: used to update the "is Synced Successfully" checkbox on invoice when submission is successfully sent to propel-I billing system.
 * Test Class:
 * Code Coverage: 
 * History:
 *Modified By:                  Description:      Modified Date:

------------------------------------------------------------------------------------------------------------*/
trigger InvoiceSubmissionTrg on Invoice_Submission_Response__c (after insert, after update 
                                                               ) {
    
    // Invoke handler class to update the invoice sync flag.
    InvoiceSubmissionTrgHandler.updateSyncToInvoice(Trigger.new);

}