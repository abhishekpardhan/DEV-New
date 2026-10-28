/**
 * @File Name          : QueryUtilTest.cls
 * @Description        : QueryUtilTest is the test class for QueryUtil apex class
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 01-11-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        01-11-2021                Deepak                   Initial Version
**/

@IsTest
private class QueryUtilTest {

    @testSetup static void createTestData() {

        Safex_API__c safexApi = TestDataFactory.createSafexAPI('WayBill', 'test', 'password', 't1',null, 'wwww.google.com', 'test', 'test');
        insert safexApi;

        List<Case> cases = TestDataFactory.createCases('Test', null, ConstantUtility.NEW_STATUS, 1);
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        cases[0].WaybillNo__c = '12345678';

        insert cases;

        List<Pincode__c> pincodes = TestDataFactory.createPincode('123456', 'Delhi', 'DELHI', 'DEL12', 'Delhi', 1);
        insert pincodes;

    }
    static testMethod void getSafexApiInfoTest() {
        Test.startTest();
        QueryUtil.getSafexApiInfo('WayBill');
        Test.stopTest();
    }
    static testMethod void getPropelApiInfoTest() {
        Test.startTest();
        QueryUtil.getPropelApiInfo('Test');
        Test.stopTest();
    }
    static testMethod void getCaseObjectTest() {
        Test.startTest();
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        QueryUtil.getCaseObject(caseObj.Id);
        Test.stopTest();
    }
    static testMethod void getAddressTest() {
        Test.startTest();
        QueryUtil.getAddress('123456');
        Test.stopTest();
    }


}