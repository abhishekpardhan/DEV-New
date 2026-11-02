/**
 * @File Name          : SafexpressUrgentDeliveryForm.cls
 * @Description        : Data type behind the "Safexpress Urgent Delivery Form" Lightning Type.
 *                       Filled by the LWC after the customer submits their request.
 * @Author             : Rohit Deshmukh
 */
@JsonAccess(serializable='always' deserializable='always')
global class SafexpressUrgentDeliveryForm {
    @AuraEnabled global String waybillNumber;
    @AuraEnabled global String mobileNumber;
    @AuraEnabled global String emailId;
    @AuraEnabled global String instructions;
    @AuraEnabled global String caseNumber;
    @AuraEnabled global String outcome;
    @AuraEnabled global String message;
    @AuraEnabled global String shipmentStatus; // NEW: Receives status from Agentforce to block ineligible requests
}