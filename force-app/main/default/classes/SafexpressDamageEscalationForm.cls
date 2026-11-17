/**
 * Data type behind the "Safexpress Damage Escalation Form" Lightning Type.
 */
@JsonAccess(serializable='always' deserializable='always')
global class SafexpressDamageEscalationForm {
    
    @AuraEnabled @InvocableVariable global String waybillNumber;
    @AuraEnabled @InvocableVariable global String mobileNumber;
    @AuraEnabled @InvocableVariable global String emailId;
    @AuraEnabled @InvocableVariable global String instructions;
    @AuraEnabled @InvocableVariable global String issueType;
    @AuraEnabled @InvocableVariable global String incidentDate;
    @AuraEnabled @InvocableVariable global List<String> contentDocumentIds; 
    @AuraEnabled @InvocableVariable global String checkOutcome; 
    @AuraEnabled @InvocableVariable global String messagingSessionId;
    @AuraEnabled @InvocableVariable global String caseNumber;
    @AuraEnabled @InvocableVariable global String outcome;
    @AuraEnabled @InvocableVariable global String caseStatus;
    @AuraEnabled @InvocableVariable global Integer filesAttached;
    @AuraEnabled @InvocableVariable global String message;
}