/**
 * @File Name          : SafexpressUrgentDeliveryForm.cls
 * @Description        : Data type behind the "Safexpress Urgent Delivery Form" Lightning Type.
 *                       Filled by the LWC after the customer submits their request.
 * @Author             : Rohit Deshmukh
 */
@JsonAccess(serializable='always' deserializable='always')
global class SafexpressUrgentDeliveryForm {
    
    @AuraEnabled 
    @InvocableVariable 
    global String waybillNumber;
    
    @AuraEnabled 
    @InvocableVariable 
    global String mobileNumber;
    
    @AuraEnabled 
    @InvocableVariable 
    global String emailId;
    
    @AuraEnabled 
    @InvocableVariable 
    global String instructions;
    
    @AuraEnabled 
    @InvocableVariable 
    global String caseNumber;
    
    @AuraEnabled 
    @InvocableVariable 
    global String outcome;
    
    @AuraEnabled 
    @InvocableVariable 
    global String message;
    
    @AuraEnabled 
    @InvocableVariable 
    global String shipmentStatus;
}