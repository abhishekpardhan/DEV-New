/**
 * @File Name          : AddressControllerTest.cls
 * @Description        : AddressControllerTest is the test class for AddressController apex class
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
private class AddressControllerTest {

    @testSetup static void createTestData() {

        List<Pincode__c> pincodes = TestDataFactory.createPincode('123456', 'Delhi', 'DELHI', 'DEL12', 'Delhi', 1);
        insert pincodes;

    }
    static testMethod void getAddressTest() {
        Test.startTest();
        AddressController.getAddress('123456');
        Test.stopTest();
    }
    static testMethod void getAddressTest1() {
        Test.startTest();
        AddressController.getAddress(null);
        AddressController.dummyMethod();
        Test.stopTest();
    }
}