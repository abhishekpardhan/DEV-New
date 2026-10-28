@isTest
private class CheckPincodeTest {

    @testSetup static void createTestData() {
        List<Pincode__c> pincodes = TestDataFactory.createPincode('123456', 'Bihar', 'test', '23fd', 'test', 1);
        insert pincodes;
    }
    static testMethod void checkPinCodeTest() {
        Test.startTest();
        List<CheckPincode.PincodeInput> strings = new List<CheckPincode.PincodeInput>();
        CheckPincode.PincodeInput input =  new CheckPincode.PincodeInput();
        input.pincode = '123456';
        input.countString = '1';
        strings.add(input);
        CheckPincode.checkPinCode(strings);
        Test.stopTest();
    }

}