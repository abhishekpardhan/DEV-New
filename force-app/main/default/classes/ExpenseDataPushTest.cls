/**
 * Description		:		Test class for ExpenseDataPush apex class
 * 
 * Coverage			:		97%
 **/
@isTest
private class ExpenseDataPushTest{
    //status code != 200
    private class MockHttpResponseGenerator1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            String jsonResponse = '{"access_token":"ajidjsnfn12433","token_type":"abc","expires_in":"12345"}';          
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setBody(jsonResponse);
            objResponse.setStatusCode(100);
            return objResponse;
        }
    }
    //status code == 200
    private class MockHttpResponseGenerator2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            String jsonResponse = '{"access_token":"ajidjsnfn12433","token_type":"abc","expires_in":"12345"}';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setBody(jsonResponse);
            objResponse.setStatusCode(200);
            return objResponse;
        }
    }
    
    @isTest 
    private static void myTest1(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        System.runAs(us){
            Journey__c objJourney = CommonDataTest.getJourney(); 
            insert objJourney;
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1());
            
            Test.startTest();
                ExpenseDataPush.sendExpense();
            Test.stopTest();
        }
    }
    
    @isTest 
    private static void myTest2(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        System.runAs(us){
            Journey__c objJourney = CommonDataTest.getJourney(); 
            insert objJourney;
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
            
            Test.startTest();
                ExpenseDataPush.sendExpense();
            Test.stopTest();
        }
    }
    @isTest 
    private static void myTest3(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        System.runAs(us){
            Journey__c objJourney = CommonDataTest.getJourney(); 
            insert objJourney;
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
            
            Test.startTest();                
                ExpenseDataPush objEDP = new ExpenseDataPush();
                String sch = '0 0 23 * * ?';
                System.schedule('Test',sch,objEDP);
            Test.stopTest();
        }
    }
}