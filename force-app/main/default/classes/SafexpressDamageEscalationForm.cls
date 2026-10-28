/**
 * Data type behind the "Safexpress Damage Escalation Form" Lightning Type.
 * Filled by the agentforceImageUpload LWC after the customer submits the form.
 */
@JsonAccess(serializable='always' deserializable='always')
global class SafexpressDamageEscalationForm {
    @AuraEnabled global String waybillNumber;
    @AuraEnabled global String caseNumber;
    @AuraEnabled global String outcome;
    @AuraEnabled global String caseStatus;
    @AuraEnabled global Integer filesAttached;
    @AuraEnabled global String message;
}