/*------------------------------------------------------------
 * Author: Safexpress team
 * Description: used to update the "is Synced Successfully" checkbox on invoice when submission is successfully sent to propel-I billing system.
 * Trigger Class: InvoiceSubmissionTrg
 * Test Class:
 * Code Coverage: 
 * History:
 *Modified By:                  Description:      Modified Date:

------------------------------------------------------------------------------------------------------------*/
public class InvoiceSubmissionTrgHandler {
    
    //Update a flag on invoice on successfull submission to propel-i billing system.
    public static void updateSyncToInvoice(List<Invoice_Submission_Response__c> lstInvSub)
    {
        System.debug('lstInvSub----------->'+lstInvSub);
        if(! lstInvSub.isEmpty())
        {
            Map<String, Invoice_Submission_Response__c> mapInvoiceSubmission = new Map<String, Invoice_Submission_Response__c>();
            for(Invoice_Submission_Response__c eachResponse : lstInvSub)
            {
                if(String.isNotBlank(eachResponse.Bill_Number__c)   && String.isNotBlank(eachResponse.Status__c)  &&  eachResponse.Status__c =='SUCCESS')
                {
                    mapInvoiceSubmission.put(eachResponse.Bill_Number__c, eachResponse);
                }
            }
            System.debug('mapInvoiceSubmission-------------->'+mapInvoiceSubmission);
            if(! mapInvoiceSubmission.isEmpty())
            {
                List<Invoice__c> lstInvoiceToUpdate = [SELECT Id, Is_Submission_Synced__c,Name from Invoice__c where Name IN :mapInvoiceSubmission.keySet() AND Is_Submission_Synced__c != TRUE];
                System.debug('lstInvoiceToUpdate------------>'+lstInvoiceToUpdate);
                if(! lstInvoiceToUpdate.isEmpty())
                {
                    for(Invoice__c eachInvoice : lstInvoiceToUpdate)
                    {
                        if(mapInvoiceSubmission.containsKey(eachInvoice.Name))
                        {
                            eachInvoice.Is_Submission_Synced__c = true;
                        }
                           
                    }
                    
                    //update invoices. 
                    update lstInvoiceToUpdate;
                }
            }
        }
    }

}