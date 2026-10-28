/**
 * Description		:		Test class for CampaignDataPush apex class
 * 
 * Coverage			:		98%
 **/
@isTest
private class CampaignDataPushTest{
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
            Campaign__c objCam = CommonDataTest.getCampaign();
            objCam.Country__c = 'IN';
            insert objCam;
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1());
            
            Test.startTest();
                CampaignDataPush.sendCampaign();
            Test.stopTest();
        }
    }
    
    @isTest 
    private static void myTest2(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        System.runAs(us){
            Campaign__c objCam = CommonDataTest.getCampaign();
            objCam.Country__c = 'IN';
            insert objCam;
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
            
            Test.startTest();
                CampaignDataPush.sendCampaign();
            Test.stopTest();
        }
    }
    @isTest 
    private static void myTest3(){
        User us = CommonDataTest.getUserBdm();
        insert us;
        System.runAs(us){
            Campaign__c objCam = CommonDataTest.getCampaign();
            objCam.Country__c = 'IN';
            insert objCam;
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
            
            Test.startTest();                
                CampaignDataPush objCDP = new CampaignDataPush();
                String sch = '0 0 23 * * ?';
                System.schedule('Test',sch,objCDP);
            Test.stopTest();
        }
    }
}