public class AgentforceAgentDelayCaseRequest {

    @InvocableVariable(
        label       = 'Waybill Number'
        description = 'Waybill number confirmed from Intent 1 lookup. Primary key for all Case operations.'
        required    = true
    )
    public String waybillNumber;

    @InvocableVariable(
        label       = 'Customer Concern'
        description = 'Customer concern captured by the agent in natural language.'
        required    = true
    )
    public String customerConcern;

    @InvocableVariable(
        label       = 'Contact Phone'
        description = 'Caller phone number to find or create Contact.'
        required    = true
    )
    public String contactPhone;

    @InvocableVariable(
        label       = 'Expected Delivery Date'
        description = 'EDD from waybill lookup in Intent 1. Format DD-MM-YYYY. Used to calculate delay severity and set Case priority dynamically.'
        required    = false
    )
    public String expectedDeliveryDate;

    @InvocableVariable(
        label       = 'Messaging Session Id'
        description = 'Active Messaging Session Id to link to the Case via SourceId.'
        required    = false
    )
    public String messagingSessionId;
}