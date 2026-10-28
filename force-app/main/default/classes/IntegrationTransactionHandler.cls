/**
* @File Name          : IntegrationTransactionHandler.cls
* @Description        : Main handler class for the Integration Transaction trigger
* @Author             : KR SANSI
* @Group              : IBM
* @Last Modified By   : Rudra Singh | GT Bharat
* @Last Modified On   : 12/06/2026
*==============================================================================
* Ver         Date              Author              Modification
*==============================================================================
* 1.0         08/05/2024        KR SANSI            Initial Version
* 1.1         [Today]           [Your Name]         Added Slack operation routing;
*                                                   added SLACK_ prefix guard for Case query (SAC-XXXX)
* 1.2         13/05/2026        Rudra Singh         Added Enterprise App afterUpdate retry logic
* 1.3         12/06/2026        Rudra Singh         Added routing for OperationType_Enterprise_EnquiryCaseStatus
*                                                   → ExternalCaseStatusQueueable (Enterprise Enquiry Case API)
*                                                   in both afterInsert and afterUpdate (retry)
**/
public class IntegrationTransactionHandler extends TriggerHandler {

    private List<Integration_Transaction__c>    newRecords;
    private Map<Id, Integration_Transaction__c> oldRecordsMap;

    public IntegrationTransactionHandler() {
        this.newRecords    = (List<Integration_Transaction__c>) Trigger.new;
        this.oldRecordsMap = (Map<Id, Integration_Transaction__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {}

    public override void beforeUpdate() {}

    public override void afterInsert() {

        Map<String, String> propelIAPIMap          = new Map<String, String>();
        Map<String, String> iConnectAPIMap         = new Map<String, String>();
        Map<String, String> protonAPIMap           = new Map<String, String>();
        Map<String, String> enterpriseAppMap       = new Map<String, String>();
        Map<String, String> enterpriseEnquiryMap   = new Map<String, String>();
        Map<String, String> slackAPIMap            = new Map<String, String>(); // ← new
        Map<String, String> pincodeLookupMap = new Map<String, String>();

        for(Integration_Transaction__c record : this.newRecords){

            // ── Existing integrations ────────────────────────────────────────
            if(record.Operation_Type__c == System.Label.OperationType_PropelI_CaseCreation){
                propelIAPIMap.put(record.Id, record.Record_Id__c);
            }
            if(record.Operation_Type__c == System.Label.OperationType_Enterprise_UpdateCase){
                enterpriseAppMap.put(record.Id, record.Record_Id__c);
            }
            if(record.Operation_Type__c == System.Label.OperationType_Enterprise_EnquiryCaseStatus){
                enterpriseEnquiryMap.put(record.Id, record.Record_Id__c);
            }
            if(record.Operation_Type__c == System.Label.OperationType_iConnect_UpdateCase){
                iConnectAPIMap.put(record.Id, record.Record_Id__c);
            }
            if(record.Operation_Type__c == System.Label.OperationType_PropelI_CreateOpportunityPropeli){
                MSAPushApi.MSAFromSF(record.Record_Id__c, record.MSAPushEndpoint__c, record.Id);
            }
            if(record.Operation_Type__c == System.Label.OperationType_Proton_UpdateCase){
                protonAPIMap.put(record.Id, record.Record_Id__c);
            }
            if(record.Operation_Type__c == System.Label.OperationType_PropelI_PincodeLookup){
                pincodeLookupMap.put(record.Id, record.Record_Id__c);
            }

            // ── Slack operations — route all SLACK_* types ───────────────────
            // SlackQueueable is already enqueued by SlackService directly
            // IT record is used here only for audit + retry tracking
            // No additional enqueue needed — Queueable handles its own status
        }

        if(propelIAPIMap.size() > 0){
            system.debug('propelIAPIMap'+propelIAPIMap);
            PreBookingAPIQueueable propelIQueueableObj = new PreBookingAPIQueueable(propelIAPIMap);
            System.enqueueJob(propelIQueueableObj);
        }
        if(iConnectAPIMap.size() > 0){
            IConnectUpdateAPIQueueable iconnectQueueableObj = new IConnectUpdateAPIQueueable(iConnectAPIMap);
            System.enqueueJob(iconnectQueueableObj);
        }
        if(protonAPIMap.size() > 0){
            ProtonCaseUpdateAPiQueueable protonQueueableObj = new ProtonCaseUpdateAPiQueueable(protonAPIMap);
            System.enqueueJob(protonQueueableObj);
        }
        if(enterpriseAppMap.size() > 0){
            EnterpriseAppUpdateAPIQueueable enterpriseQueueableObj = new EnterpriseAppUpdateAPIQueueable(enterpriseAppMap);
            System.enqueueJob(enterpriseQueueableObj);
        }
        if(enterpriseEnquiryMap.size() > 0){
            System.enqueueJob(new ExternalCaseStatusQueueable(enterpriseEnquiryMap, 'Enterprise_Enquiry_Case_API'));
        }
        if(pincodeLookupMap.size() > 0){
            PincodeLookupQueueable.enqueueInChunks(pincodeLookupMap, 0);
        }
    }

    public override void afterUpdate() {

        System.debug('entered after update');

        Map<String, String> propelIAPIMap        = new Map<String, String>();
        Map<String, String> slackRetryMap        = new Map<String, String>(); // ← new
        Map<String, String> enterpriseAppMap     = new Map<String, String>();
        Map<String, String> enterpriseEnquiryMap = new Map<String, String>();
        Map<String, String> pincodeLookupMap = new Map<String, String>();
        for(Integration_Transaction__c record : newRecords){

            Integration_Transaction__c oldRec = oldRecordsMap.get(record.Id);

            // ── PropelI retry ────────────────────────────────────────────────
            if(record.Operation_Type__c == System.Label.OperationType_PropelI_CaseCreation
               && record.No_of_Retries__c != oldRec.No_of_Retries__c
               && record.No_of_Retries__c <= 3){
                propelIAPIMap.put(record.Id, record.Record_Id__c);
            }

            //-- Enterprise Application Retry (booking status) ----------------
            if(record.Operation_Type__c == System.Label.OperationType_Enterprise_UpdateCase
               && record.No_of_Retries__c != oldRec.No_of_Retries__c
               && record.No_of_Retries__c <= 3){
                enterpriseAppMap.put(record.Id, record.Record_Id__c);
            }

            //-- Enterprise Enquiry Case Status Retry -------------------------
            if(record.Operation_Type__c == System.Label.OperationType_Enterprise_EnquiryCaseStatus
               && record.No_of_Retries__c != oldRec.No_of_Retries__c
               && record.No_of_Retries__c <= 3){
                enterpriseEnquiryMap.put(record.Id, record.Record_Id__c);
            }

            //-- Pincode lookup retry --------------------------------------------
            if(record.Operation_Type__c == System.Label.OperationType_PropelI_PincodeLookup
                && record.Status__c == 'Draft'
                && record.No_of_Retries__c != oldRec.No_of_Retries__c
                && record.No_of_Retries__c <= 3){
                    pincodeLookupMap.put(record.Id, record.Record_Id__c);
            }

            // ── Slack retry — re-enqueue if No_of_Retries__c incremented ────
            // SlackQueueable handles its own retry internally
            // This block only fires if someone manually bumps No_of_Retries__c
            // on a failed IT record to force a retry from the UI
            if(record.Operation_Type__c != null
               && record.Operation_Type__c.startsWith('SLACK_')
               && record.Status__c == 'Draft'
               && record.No_of_Retries__c != oldRec.No_of_Retries__c
               && record.No_of_Retries__c <= 3){
                slackRetryMap.put(record.Id, record.Request__c);
            }
        }

        if(propelIAPIMap.size() > 0){
            PreBookingAPIQueueable propelIQueueableObj = new PreBookingAPIQueueable(propelIAPIMap);
            System.enqueueJob(propelIQueueableObj);
        }
        if(enterpriseAppMap.size() > 0){
            EnterpriseAppUpdateAPIQueueable enterpriseQueueableObj = new EnterpriseAppUpdateAPIQueueable(enterpriseAppMap);
            System.enqueueJob(enterpriseQueueableObj);
        }
        if(enterpriseEnquiryMap.size() > 0){
            System.enqueueJob(new ExternalCaseStatusQueueable(enterpriseEnquiryMap, 'Enterprise_Enquiry_Case_API'));
        }

        if(pincodeLookupMap.size() > 0){
            PincodeLookupQueueable.enqueueInChunks(pincodeLookupMap, 1); // 1 minute retry delay
        }

        // if(slackRetryMap.size() > 0){
        //     for(String txnId : slackRetryMap.keySet()){
        //         String requestJson = slackRetryMap.get(txnId);
        //         try {
        //             // SlackService.SlackRequest req =
        //             //     (SlackService.SlackRequest) JSON.deserialize(
        //             //         requestJson,
        //             //         SlackService.SlackRequest.class
        //             //     );
        //             // System.enqueueJob(new SlackQueueable(req, 0, txnId));
        //         } catch(Exception e){
        //             LoggerUtil.createErrorLog(
        //                 'IntegrationTransactionHandler',
        //                 'afterUpdate',
        //                 e.getTypeName(),
        //                 e.getMessage(),
        //                 e.getStackTraceString(),
        //                 'TxnId: ' + txnId
        //             );
        //         }
        //     }
        // }
    }
}