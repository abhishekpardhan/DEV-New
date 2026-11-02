/**
 * @File Name   : SafexpressBusinessEnquiryForm.cls
 * @Description : Data of the Business Enquiry form (Custom Lightning Type "SafexpressBusinessEnquiryForm").
 *                Filled by the sfxBusinessEnquiryForm LWC and passed to SafexpressBusinessEnquiryService.createBusinessEnquiry.
 */
public class SafexpressBusinessEnquiryForm {
    @AuraEnabled public String pincode;
    @AuraEnabled public String mobileNumber;
    @AuraEnabled public String emailAddress;
    @AuraEnabled public String fullName;
    @AuraEnabled public String designation;
    @AuraEnabled public String organisationName;
    @AuraEnabled public String messagingSessionId;
}