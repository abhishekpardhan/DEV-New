/**
 * @File Name          : UpdateCaseApiTest.cls
 * @Description        : UpdateCaseApiTest is the test class for UpdateCaseApi apex class
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 03-11-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        03-11-2021                Deepak                   Initial Version
**/

@isTest
private class UpdateCaseApiTest {
    @testSetup
    static void setupTestData() {
        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        cases[0].Pre_Booking_Id__c = '234555';
        cases[0].WaybillNo__c = '12121212';
        insert cases;
    }
    static testMethod void createCaseTest() {
        Test.startTest();
        String myJSON = '{ "preBookingRequestId":234555, "lkpBookingRequestTypeId":32323, "bookingStatus": null, "safexpReferenceNumber": 2333, "waybillNo":"12121212", "rescheduledate" : "20/10/2021", "reschereason":"Test reson", "lastupdatedate" : "20/10/2021" }';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/UpdateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        UpdateCaseApi.updateCase();
        CreateCaseApi.ResponseWrapper res = new CreateCaseApi.ResponseWrapper();
        Test.stopTest();
    }
    static testMethod void createCaseNoCaseTest() {
        Test.startTest();
        String myJSON = '{ "preBookingRequestId":2345552, "lkpBookingRequestTypeId":32323, "bookingStatus": null, "safexpReferenceNumber": 2333, "waybillNo":"12121212", "rescheduledate" : "20/10/2021", "reschereason":"Test reson", "lastupdatedate" : "20/10/2021" }';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/UpdateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        UpdateCaseApi.updateCase();
        CreateCaseApi.ResponseWrapper res = new CreateCaseApi.ResponseWrapper();
        Test.stopTest();
    }
    static testMethod void invalidRequestTest() {
        Test.startTest();
        String myJSON = '{ "preBookingRequestId":"2323", "lkpBookingRequestTypeId":32323, "bookingStatus": null, "safexpReferenceNumber": 2333, "waybillNo":"12121212", "rescheduledate" : "20/10/2021", "reschereason":"Test reson", "lastupdatedate" : "20/10/2021" }';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/UpdateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        UpdateCaseApi.updateCase();
        CreateCaseApi.ResponseWrapper res = new CreateCaseApi.ResponseWrapper();
        Test.stopTest();
    }
    static testMethod void blankReqBodyTest() {
        //  String myJSON = '{ "preBookingRequestId":2345552, "lkpBookingRequestTypeId":32323, "bookingStatus": null, "safexpReferenceNumber": 2333, "waybillNo":"12121212", "rescheduledate" : "20/10/2021", "reschereason":"Test reson", "lastupdatedate" : "20/10/2021" }';
        Test.startTest();
        String myJSON = '';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/UpdateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        UpdateCaseApi.updateCase();
        CreateCaseApi.ResponseWrapper res = new CreateCaseApi.ResponseWrapper();
        Test.stopTest();
    }


}