public class AgentforceAgentChatWaybillStatusRequest {

    @InvocableVariable(required=true label='Waybill Number'
        description='12-digit Safexpress waybill number')
    public String waybillNumber;

    @InvocableVariable(label='E-Waybill Number'
        description='15-digit E-Waybill number as fallback')
    public String eWaybillNumber;

    @InvocableVariable(label='Is Urgent Delivery Request'
        description='Set to true when customer explicitly requests urgent delivery')
    public Boolean isUrgentDeliveryRequest;

    @InvocableVariable(label='Customer Concern'
        description='Customer concern for urgent delivery request')
    public String customerConcern;

    @InvocableVariable(label='Messaging Session Id')
    public String messagingSessionId;
}