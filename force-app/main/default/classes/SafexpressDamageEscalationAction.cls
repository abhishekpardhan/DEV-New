/**
 * Agentforce action: shows the damage escalation form (agentforceImageUpload LWC via Lightning Type)
 * and returns the outcome to the agent.
 *
 * The LWC itself validates, de-duplicates, uploads proof and creates / updates the case.
 * This action only confirms the result against the database, so the agent never relies on
 * values typed or altered in the browser.
 */
public without sharing class SafexpressDamageEscalationAction {

    public class Request {
        @InvocableVariable(
            label='Damage Escalation Form'
            description='Form where the customer enters waybill, mobile, email and uploads proof of damage.'
            required=true
        )
        public SafexpressDamageEscalationForm formData;
    }

    public class Response {
        @InvocableVariable(label='Result Message' description='Summary of the complaint outcome to share with the customer.')
        public String resultMessage;

        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Outcome' description='CREATED, PROOF_ADDED, EXISTING, EXISTING_WITH_PROOF or NOT_SUBMITTED')
        public String outcome;
    }

    @InvocableMethod(
        label='Submit Damage Escalation Form'
        description='Shows the Safexpress damage escalation form to collect waybill, mobile, email and proof of damage, then returns the case outcome.'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            SafexpressDamageEscalationForm form = req.formData;
            Response res = new Response();

            if (form == null || String.isBlank(form.caseNumber)) {
                res.outcome = 'NOT_SUBMITTED';
                res.resultMessage = 'The form has not been submitted yet. Please fill in the waybill number, mobile number, email ID and upload proof of damage, then submit.';
                responses.add(res);
                continue;
            }

            // Confirm the case really exists (system mode - case may be owned by a queue)
            List<Case> cases = Database.queryWithBinds(
                'SELECT CaseNumber, Status, WaybillNo__c FROM Case WHERE CaseNumber = :caseNumber LIMIT 1',
                new Map<String, Object>{ 'caseNumber' => form.caseNumber.trim() },
                AccessLevel.SYSTEM_MODE
            );

            if (cases.isEmpty()) {
                res.outcome = 'NOT_SUBMITTED';
                res.resultMessage = 'We could not confirm your complaint. Please submit the form again.';
                responses.add(res);
                continue;
            }

            Case c = cases[0];
            res.caseNumber = c.CaseNumber;
            res.outcome = form.outcome;

            if (form.outcome == SafexpressPostDeliveryStatusAction.OUTCOME_CREATED) {
                res.resultMessage = 'Your complaint has been registered. Case number ' + c.CaseNumber
                    + ' for waybill ' + c.WaybillNo__c + ' (Status: ' + c.Status + ').';
            } else if (form.outcome == SafexpressPostDeliveryStatusAction.OUTCOME_PROOF_ADDED) {
                res.resultMessage = 'Your documents have been added to the existing case ' + c.CaseNumber
                    + ' for waybill ' + c.WaybillNo__c + ' (Status: ' + c.Status + ').';
            } else if (form.outcome == SafexpressPostDeliveryStatusAction.OUTCOME_EXISTING) {
                res.resultMessage = 'An active case ' + c.CaseNumber + ' is already open for waybill '
                    + c.WaybillNo__c + '. Your details have been added to it (Status: ' + c.Status + ').';
            } else {
                res.resultMessage = 'An active case ' + c.CaseNumber + ' is already open for waybill '
                    + c.WaybillNo__c + ' and your documents are already on record (Status: ' + c.Status + ').';
            }

            responses.add(res);
        }

        return responses;
    }
}