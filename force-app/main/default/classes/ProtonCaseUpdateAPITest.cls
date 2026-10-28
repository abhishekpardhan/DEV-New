@isTest
public class ProtonCaseUpdateAPITest {
    @testSetup
    static void setupTestData() {

    }
    static testMethod void createCaseTest() {
//        contact con = CommonDataTest.getContact();

        
        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Booking_Request').getRecordTypeId();
        insert cases;
         Case caseObj = [SELECT Id,CaseNumber FROM Case LIMIT 1];
        system.debug('######'+ caseObj.CaseNumber);
        
        Test.startTest();
    //    Case caseObj = [SELECT Id,CaseNumber FROM Case LIMIT 1];
        String myJSON = '{"caseNumber":"'+caseObj.CaseNumber+'","caseNature":"Request","caseType":"Booking Request","subType":"Retail- PRC","requesterName":"Air force school","requesterAddress":"--","requesterPhone":"9381003021","pickDateTime":"2022-01-31 13:10:55.0","numOfPices":"1","fromLocn":"BANGALORE-11","toLocn":"PUNE","fromPincode":"560006","toPincode":"410501","emailId":"dhananjay.khangal@safexpress.com","pickType":"--","weight":"100","chatDetails":"general","source":"API","remarks":"general","waybillnumber":null,"consigneeName":"--","mode":"SURFACE","product":"","contains":"","mop":"TO-PAY"}';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/ProtonUpdateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        ProtonCaseUpdateAPI.createCase();
        ProtonCaseUpdateAPI.ResponseWrapper res = new ProtonCaseUpdateAPI.ResponseWrapper();
        Test.stopTest();
    }
   /* static testMethod void createCaseTest1() {
         Case caseObj = [SELECT Id,CaseNumber FROM Case LIMIT 1];
        Test.startTest();
        String myJSON = '{"caseNumber":'+caseObj.CaseNumber+',"caseNature":"Request","caseType":"Booking Request","subType":"Retail- PRC","requesterName":"Air force school","requesterAddress":"--","requesterPhone":"9381003021","pickDateTime":"2022-01-31 13:10:55.0","numOfPices":"1","fromLocn":"BANGALORE-11","toLocn":"PUNE","fromPincode":"560006","toPincode":"410501","emailId":"dhananjay.khangal@safexpress.com","pickType":"--","weight":"100","chatDetails":"general","source":"API","remarks":"general","waybillnumber":null,"consigneeName":"--","mode":"SURFACE","product":"","contains":"","mop":"TO-PAY"}';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/ProtonUpdateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        ProtonCaseUpdateAPI.createCase();
        ProtonCaseUpdateAPI.ResponseWrapper res = new ProtonCaseUpdateAPI.ResponseWrapper();
        Test.stopTest();
    } */

}