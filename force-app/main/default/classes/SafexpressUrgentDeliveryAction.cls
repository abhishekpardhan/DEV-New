/**
 * @File Name          : SafexpressUrgentDeliveryAction.cls
 * @Description        : Agentforce action that validates and processes the urgent delivery form
 *                       data, creates the case, and returns the outcome to the chat agent.
 * @Author             : Rohit Deshmukh
 */
public without sharing class SafexpressUrgentDeliveryAction {

    public class Request {
        @InvocableVariable(
            label='Urgent Delivery Form'
            description='Form where the customer enters their mobile, email, and instructions for urgent delivery.'
            required=true
        )
        public SafexpressUrgentDeliveryForm formData;

        @InvocableVariable(
            label='Shipment Status'
            description='The current tracking status of the shipment (e.g. In Transit, Arrived at Destination).'
            required=false
        )
        public String shipmentStatus;
    }

    public class Response {
        @InvocableVariable(label='Result Message' description='Summary of the urgent delivery outcome to share with the customer.')
        public String resultMessage;

        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Outcome' description='CREATED, EXISTING, VALIDATION_ERROR, or ERROR')
        public String outcome;
    }

    @InvocableMethod(
        label='Submit Urgent Delivery Form'
        description='Processes the Safexpress urgent delivery form data, validates it, creates a case if valid, and returns the outcome.'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            SafexpressUrgentDeliveryForm form = req.formData;
            Response res = new Response();

            if (form == null || String.isBlank(form.waybillNumber)) {
                res.outcome = 'VALIDATION_ERROR';
                res.resultMessage = 'The request was missing data. Please fill out the form completely.';
                responses.add(res);
                continue;
            }

            // Delegate server-side validation, deduplication, and DML creation to your existing Controller
            SafexpressUrgentDeliveryController.UrgentDeliveryResult submitRes = 
                SafexpressUrgentDeliveryController.submitRequest(
                    form.waybillNumber,
                    form.mobileNumber,
                    form.emailId,
                    form.instructions,
                    req.shipmentStatus
                );

            res.outcome = submitRes.outcome;
            res.caseNumber = submitRes.caseNumber;

            if (submitRes.outcome == 'CREATED') {
                res.resultMessage = 'Your urgent delivery request has been successfully logged. Case number ' + submitRes.caseNumber + ' created.';
            } else if (submitRes.outcome == 'EXISTING') {
                res.resultMessage = 'An active support case ' + submitRes.caseNumber + ' is already open for this waybill. Our team is actively working on it.';
            } else {
                // This gracefully handles VALIDATION_ERROR and ERROR outcomes, passing your exact Apex rejection reasons back to the AI.
                res.resultMessage = submitRes.message; 
            }

            responses.add(res);
        }

        return responses;
    }
}