@JsonAccess(serializable='always' deserializable='always')
global class WaybillData {

    @AuraEnabled global Boolean success;
    @AuraEnabled global String errorMessage;
    @AuraEnabled global String shipmentState;
    @AuraEnabled global String currentStatus;
    @AuraEnabled global String lastEventDate;
    @AuraEnabled global String expectedDeliveryDate;
    @AuraEnabled global String actualDeliveryDate;
    @AuraEnabled global String deliveryCity;
    @AuraEnabled global String bookingBranch;
    @AuraEnabled global String consignorName;
    @AuraEnabled global String consigneeName;
    @AuraEnabled global String caseNumber;
    @AuraEnabled global String caseId;
    @AuraEnabled global Boolean isDuplicateCase;
    @AuraEnabled global String inputTypeUsed;
    @AuraEnabled global String headerTitle;
    @AuraEnabled global String headerColor;
    @AuraEnabled global String footerNote;
}