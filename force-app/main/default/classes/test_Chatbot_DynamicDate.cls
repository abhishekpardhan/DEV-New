@isTest
public class test_Chatbot_DynamicDate {
static testMethod void checkDateTest() {
        Test.startTest();
        List<Chatbot_DynamicDate.DateInput> strings = new List<Chatbot_DynamicDate.DateInput>();
        Chatbot_DynamicDate.DateInput input = new Chatbot_DynamicDate.DateInput();
        input.dateString = '12/12/2030';
        
        input.dateString =string.valueof(system.today());
        input.dateString = Date.today().format();
        
        //System.assertEquals(strings[0].dateString, Date.today().format(), 'Input date string should match the current date.');
        
        strings.add(input);
        Chatbot_DynamicDate.checkCurrentDate(strings);
        Test.stopTest();
    }
    
}