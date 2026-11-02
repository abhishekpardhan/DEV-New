/**
 * @File Name          : SafexpressUrgentDeliveryAction.cls
 * @Description        : Agentforce action that shows the urgent delivery form to the user
 *                       and returns the case outcome back to the chat agent.
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

        @InvocableVariable(label='Outcome' description='CREATED, EXISTING, or NOT_SUBMITTED')
        public String outcome;
    }

    @InvocableMethod(
        label='Submit Urgent Delivery Form'
        description='Shows the Safexpress urgent delivery form to collect contact details and returns the case outcome.'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            SafexpressUrgentDeliveryForm form = req.formData;
            Response res = new Response();

            if (form == null || String.isBlank(form.caseNumber)) {
                res.outcome = 'NOT_SUBMITTED';
                res.resultMessage = 'The request was not submitted. Please fill in your mobile number and email ID, then submit the form.';
                responses.add(res);
                continue;
            }

            // Confirm the case really exists in the database
            List<Case> cases = Database.queryWithBinds(
                'SELECT CaseNumber, Status, WaybillNo__c FROM Case WHERE CaseNumber = :caseNumber LIMIT 1',
                new Map<String, Object>{ 'caseNumber' => form.caseNumber.trim() },
                AccessLevel.SYSTEM_MODE
            );

            if (cases.isEmpty()) {
                res.outcome = 'NOT_SUBMITTED';
                res.resultMessage = 'We could not confirm your urgent delivery request. Please submit the form again.';
                responses.add(res);
                continue;
            }

            Case c = cases[0];
            res.caseNumber = c.CaseNumber;
            res.outcome = form.outcome;

            if (form.outcome == 'CREATED') {
                res.resultMessage = 'Your urgent delivery request has been successfully logged. Case number ' + c.CaseNumber 
                    + ' for waybill ' + c.WaybillNo__c + '.';
            } else if (form.outcome == 'EXISTING') {
                res.resultMessage = 'An active support case ' + c.CaseNumber + ' is already open for waybill ' 
                    + c.WaybillNo__c + '. Our team is actively working on it.';
            } else {
                res.resultMessage = form.message;
            }

            responses.add(res);
        }

        return responses;
    }
}