public without sharing class SafexpressDamageEscalationAction {

    public class Request {
        @InvocableVariable(label='Waybill Number')
        public String waybillNumber;
    }

    public class Response {
        @InvocableVariable(label='Damage Escalation Form' description='The form object rendered via LWC')
        public SafexpressDamageEscalationForm formData;

        @InvocableVariable(label='Result Message')
        public String resultMessage;
    }

    @InvocableMethod(
        label='Submit Damage Escalation Form'
        description='Displays the damage escalation form in the chat interface.'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            SafexpressDamageEscalationForm form = new SafexpressDamageEscalationForm();
            
            // Initialize empty form fields for the LWC input interface to render
            form.waybillNumber = req.waybillNumber != null ? req.waybillNumber : '';
            form.outcome = 'NOT_SUBMITTED';

            res.formData = form;
            res.resultMessage = 'Please fill in your details and upload the required proof of damage using the form below.';
            responses.add(res);
        }

        return responses;
    }
}