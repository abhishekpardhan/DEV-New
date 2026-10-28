@isTest
private class CheckFutureDateTest {
    static testMethod void checkDateTest() {
        Test.startTest();
        List<CheckFutureDate.DateInput> strings = new List<CheckFutureDate.DateInput>();
        CheckFutureDate.DateInput input = new CheckFutureDate.DateInput();
        input.dateString = '12/12/2030';
        input.countString = '1';
        strings.add(input);
        CheckFutureDate.checkDate(strings);
        Test.stopTest();
    }
    static testMethod void checkDateTest2() {
        Test.startTest();
        List<CheckFutureDate.DateInput> strings = new List<CheckFutureDate.DateInput>();
        CheckFutureDate.DateInput input = new CheckFutureDate.DateInput();
        input.dateString = '12/12/2020';
        input.countString = null;
        strings.add(input);
        CheckFutureDate.checkDate(strings);
        Test.stopTest();
    }

}