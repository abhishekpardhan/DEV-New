@JsonAccess(serializable='always' deserializable='always')
global class SafexpressWaybillStatusRequest {

    @InvocableVariable(required=true label='Waybill Number' description='12-digit Safexpress waybill number or customer query input')
    global String waybillNumber;

    @InvocableVariable(label='E-Waybill Number' description='15-digit E-Waybill number as fallback')
    global String eWaybillNumber;

    @InvocableVariable(label='Is Urgent Delivery Request' description='Set to true when customer explicitly requests urgent delivery')
    global Boolean isUrgentDeliveryRequest;

    @InvocableVariable(label='Customer Concern' description='Customer concern for urgent delivery request')
    global String customerConcern;

    @InvocableVariable(label='Messaging Session Id')
    global String messagingSessionId;
}