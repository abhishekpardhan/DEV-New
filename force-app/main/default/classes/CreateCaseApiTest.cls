/**
 * @File Name          : CreateCaseApiTest.cls
 * @Description        : CreateCaseApiTest is the test class for CreateCaseApi apex class
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 03-11-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        01-11-2021                Deepak                   Initial Version
**/

@isTest
public class CreateCaseApiTest {
    @testSetup
    static void setupTestData() {

    }
    static testMethod void createCaseTest() {
        Test.startTest();
        String myJSON = '{ "caseNature":"Request", "caseType":"Booking Request", "subType":"Retail- PRC", "requesterName":"test name", "requesterAddress":"sampple+address", "requesterPhone":"9987654323", "pickDateTime":"2021-12-10 04:47:43", "numOfPices":1, "fromLocn":"from", "toLocn":"to", "fromPincode":"110002", "toPincode":"121112", "emailId":"emaill22@test.com", "pickType":"C2H", "weight":2.2, "chatDetails":"chat_details", "source":"Website", "remarks" : "df", "waybillnumber" : "" }';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/CreateCaseApi';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        CreateCaseApi.createCase();
        CreateCaseApi.ResponseWrapper res = new CreateCaseApi.ResponseWrapper();
        Test.stopTest();
    }
    static testMethod void createCaseTest1() {
        Test.startTest();
        String myJSON = '{ "caseNature":"' + ConstantUtility.CASE_NATURE_COMPLAINT + '", "caseType":"Feedback", "subType":"Others", "requesterName":"test name", "requesterAddress":"sampple+address", "requesterPhone":"9987654323", "pickDateTime":"2021-12-10 04:47:43", "numOfPices":1, "fromLocn":"from", "toLocn":"to", "fromPincode":"110002", "toPincode":"121112", "emailId":"emaill22@test.com", "pickType":"C2H", "weight":2.2, "chatDetails":"chat_details", "source":"Website", "remarks" : "df", "waybillnumber" : "" }';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/CreateCaseApi';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        CreateCaseApi.createCase();
        CreateCaseApi.ResponseWrapper res = new CreateCaseApi.ResponseWrapper();
        Test.stopTest();
    }

    // Test: Waybill Enquiry case creation from Enterprise App (SAC — Jun 2026)
    static testMethod void createWaybillEnquiryCaseTest() {
        Test.startTest();
        String myJSON = '{"caseNature":"' + ConstantUtility.CASE_NATURE_ENQUIRY + '","caseType":"' + ConstantUtility.CASE_TYPE_WAYBILL_ENQUIRY + '","subType":"' + ConstantUtility.CASE_SUB_TYPE_OTHERS + '","requesterName":"Test User","requesterPhone":"9876543210","emailId":"test@test.com","wayBillNumber":"TEST123456","chatDetails":"Test waybill enquiry","source":"' + ConstantUtility.CASE_ORIGIN_ENTERPRISE_APP + '","remarks":"Test remark"}';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/CreateSupportCase/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        CreateCaseApi.createCase();
        Test.stopTest();

        List<Case> cases = [SELECT Id, Case_Type__c, Origin, WaybillNo__c FROM Case WHERE WaybillNo__c = 'TEST123456' LIMIT 1];
        System.assertEquals(1, cases.size(), 'Waybill Enquiry case should be created');
        System.assertEquals(ConstantUtility.CASE_TYPE_WAYBILL_ENQUIRY, cases[0].Case_Type__c, 'Case type should be Waybill Enquiry');
        System.assertEquals(ConstantUtility.CASE_ORIGIN_ENTERPRISE_APP, cases[0].Origin, 'Origin should be ENTERPRISE APP');
    }

    // Test: Waybill Enquiry duplicate check — same phone + waybill returns existing case
    static testMethod void createWaybillEnquiryDuplicateTest() {
        // Create a Contact so ContactMobile is populated on the Case
        Contact con = new Contact();
        con.LastName    = 'DupTest';
        con.MobilePhone = '9876543211';
        insert con;

        // Insert an existing open enquiry case linked to that Contact
        Case existing = new Case();
        existing.Status         = 'New';
        existing.Origin         = ConstantUtility.CASE_ORIGIN_ENTERPRISE_APP;
        existing.Case_Nature__c = ConstantUtility.CASE_NATURE_ENQUIRY;
        existing.Case_Type__c   = ConstantUtility.CASE_TYPE_WAYBILL_ENQUIRY;
        existing.Sub_Type__c    = ConstantUtility.CASE_SUB_TYPE_OTHERS;
        existing.WaybillNo__c   = 'DUPWAYBILL01';
        existing.ContactId      = con.Id;
        existing.RecordTypeId   = ConstantUtility.ENQUIRY_SUPPORT_CASE_RECORDTYPE_ID;
        insert existing;

        Test.startTest();
        String myJSON = '{"caseNature":"' + ConstantUtility.CASE_NATURE_ENQUIRY + '","caseType":"' + ConstantUtility.CASE_TYPE_WAYBILL_ENQUIRY + '","subType":"' + ConstantUtility.CASE_SUB_TYPE_OTHERS + '","requesterName":"Test User","requesterPhone":"9876543211","emailId":"test@test.com","wayBillNumber":"DUPWAYBILL01","chatDetails":"Dup enquiry","source":"' + ConstantUtility.CASE_ORIGIN_ENTERPRISE_APP + '","remarks":"Dup remark"}';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/CreateSupportCase/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        CreateCaseApi.createCase();
        Test.stopTest();

        // Only one case should exist for this waybill
        List<Case> cases = [SELECT Id FROM Case WHERE WaybillNo__c = 'DUPWAYBILL01'];
        System.assertEquals(1, cases.size(), 'Duplicate Waybill Enquiry should not create a second case');
    }

}