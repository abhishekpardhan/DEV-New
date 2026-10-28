/**
    * @File Name          : TestDataFactory.cls
    * @Description        : This class will be used to create the instances of the record, so can be used in the test classes.
    * @Author             : Deepak
    * @Group              : TMC
    * @Last Modified By   : Deepak
    * @Last Modified On   : 09-07-2021
    * @Modification Log   :
    * Ver       Date              Author                    Modification
    * ==================================================================
    * 1.0    09/07/2021             Deepak                    Initial Version
**/
@isTest
public class TestDataFactory {


    // Create PropelI_API_PreBooking__c Custom Setting Record
    public static PropelI_API_PreBooking__c createPropelIApiRecord(String name, String grantType, String scope, String userId, String xAPiKey, String endpoint, String username, String password) {
        PropelI_API_PreBooking__c apiPreBooking = new PropelI_API_PreBooking__c();
        apiPreBooking.Name = name;
        apiPreBooking.grant_type__c = grantType;
        apiPreBooking.scope__c = scope;
        apiPreBooking.userid__c = userId;
        apiPreBooking.x_api_key__c = xAPiKey;
        apiPreBooking.Endpoint__c = endpoint;
        apiPreBooking.Username__c = username;
        apiPreBooking.Password__c = password;
        return apiPreBooking;
    }
    // Create Safex_API__c  Custom Setting Record
    public static Safex_API__c createSafexAPI(String name, String accessKey, String authorisationType, String customerUserLogin, String agentLogin, String endpoint, String username, String password) {
        Safex_API__c safexApi = new Safex_API__c();
        safexApi.Name = name;
        safexApi.Access_Key__c = accessKey;
        safexApi.Authorisation_Type__c = authorisationType;
        safexApi.Customer_User_Login__c = customerUserLogin;
        safexApi.Agent_User_Login__c = agentLogin;
        safexApi.Endpoint__c = endpoint;
        safexApi.Username__c = username;
        safexApi.Password__c = password;
        return safexApi;
    }
    // Create Case Records
    public static List<Case> createCases(String subject, String recordTypeId, String status, Integer noOfRecords) {
        LIst<Case> cases = new List<Case>();
        for (Integer i = 0; i < noOfRecords; i++) {
            Case newCase = new Case();
            newCase.Subject = subject;
            newCase.recordTypeId = recordTypeId;
            newCase.Status = status;
            cases.add(newCase);
        }
        return cases;
    }
    // Create Pincode__c Records
    public static List<Pincode__c> createPincode(String pincodeValue, String State, String branchName, String branchId, String district, Integer noOfRecords) {
        LIst<Pincode__c> pincodes = new List<Pincode__c>();
        for (Integer i = 0; i < noOfRecords; i++) {
            Pincode__c pincode = new Pincode__c();
            pincode.Pincode__c = pincodeValue;
            pincode.State__c = State;
            pincode.Branch_Name__c = branchName;
            pincode.Branch_Id__c = branchId;
            pincode.District__c = district;
            pincodes.add(pincode);
        }
        return pincodes;
    }
    // Create createPinCode_API Record
    public static PinCode_API__c createPinCode_API(String username, String password, String endpoint, Integer maxStateId) {
        PinCode_API__c pinCodeApi = new PinCode_API__c();
        pinCodeApi.Username__c = username;
        pinCodeApi.Password__c = password;
        pinCodeApi.Endpoint__c = endpoint;
        pinCodeApi.Max_StateId__c = maxStateId;
        return pinCodeApi;
    }

    // ── Waybill Enquiry Case (Enterprise App) ────────────────────────────────
    // Returns an unsaved Case. Caller must insert.
    public static Case createWaybillEnquiryCase(String phone, String waybillNumber) {
        Case c = new Case();
        c.Status         = 'New';
        c.Origin         = ConstantUtility.CASE_ORIGIN_ENTERPRISE_APP;
        c.Case_Nature__c = ConstantUtility.CASE_NATURE_ENQUIRY;
        c.Case_Type__c   = ConstantUtility.CASE_TYPE_WAYBILL_ENQUIRY;
        c.Sub_Type__c    = ConstantUtility.CASE_SUB_TYPE_OTHERS;
        c.WaybillNo__c   = waybillNumber;
        c.Consignor_Phone__c = phone;
        c.RecordTypeId   = ConstantUtility.ENQUIRY_SUPPORT_CASE_RECORDTYPE_ID;
        return c;
    }

    // ── Integration_Transaction__c record ────────────────────────────────────
    // Returns an unsaved IT record. Caller must insert.
    public static Integration_Transaction__c createIntegrationTransaction(String recordId, String operationType) {
        Integration_Transaction__c it = new Integration_Transaction__c();
        it.Object_Name__c    = 'Case';
        it.Record_Id__c      = recordId;
        it.Operation_Type__c = operationType;
        it.No_of_Retries__c  = 0;
        return it;
    }

}