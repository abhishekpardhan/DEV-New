/**
 * Agentforce action: actively creates/updates the damage escalation case via Single Button architecture.
 */
public without sharing class SafexpressDamageEscalationAction {

    public class Request {
        @InvocableVariable(label='Damage Escalation Form' required=true)
        public SafexpressDamageEscalationForm formData;
    }

    public class Response {
        @InvocableVariable(label='Result Message')
        public String resultMessage;

        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Outcome')
        public String outcome;
    }

    @InvocableMethod(label='Submit Damage Escalation Form')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            SafexpressDamageEscalationForm form = req.formData;
            Response res = new Response();

            if (form == null || String.isBlank(form.waybillNumber)) {
                res.outcome = 'VALIDATION_ERROR';
                res.resultMessage = 'Please complete all required fields and wait for uploads to finish before submitting.';
                responses.add(res);
                continue;
            }

            try {
                // REVERTED: Directly use the List from the form
                List<String> docIds = form.contentDocumentIds != null ? form.contentDocumentIds : new List<String>();
                
                SafexpressPostDeliveryStatusAction.EscalationResult submitRes;

                if (form.checkOutcome == 'OPEN_CASE') {
                    submitRes = SafexpressPostDeliveryStatusAction.addDocumentsToExistingCase(
                        form.waybillNumber, form.issueType, docIds, form.messagingSessionId
                    );
                } else {
                    submitRes = SafexpressPostDeliveryStatusAction.submitEscalation(
                        form.waybillNumber, form.mobileNumber, form.emailId, form.issueType, 
                        form.instructions, form.incidentDate, docIds, form.messagingSessionId
                    );
                }

                if (submitRes.isError) {
                    res.outcome = 'VALIDATION_ERROR';
                    res.resultMessage = submitRes.message;
                    responses.add(res);
                    continue;
                }

                res.caseNumber = submitRes.caseNumber;
                res.outcome = submitRes.outcome;

                if (submitRes.outcome == SafexpressPostDeliveryStatusAction.OUTCOME_CREATED || submitRes.outcome == 'CREATED') {
                    res.resultMessage = 'Your complaint has been registered. Case number ' + submitRes.caseNumber + '.';
                } else if (submitRes.outcome == SafexpressPostDeliveryStatusAction.OUTCOME_PROOF_ADDED || submitRes.outcome == 'PROOF_ADDED') {
                    res.resultMessage = 'Your documents have been added to the existing case ' + submitRes.caseNumber + '.';
                } else if (submitRes.outcome == SafexpressPostDeliveryStatusAction.OUTCOME_EXISTING || submitRes.outcome == 'EXISTING') {
                    res.resultMessage = 'An active case ' + submitRes.caseNumber + ' is already open for this waybill. Your details have been added to it.';
                } else {
                    res.resultMessage = submitRes.message;
                }
                responses.add(res);

            } catch (Exception ex) {
                res.outcome = 'VALIDATION_ERROR';
                res.resultMessage = 'An error occurred while processing your request: ' + ex.getMessage();
                responses.add(res);
            }
        }
        return responses;
    }
}