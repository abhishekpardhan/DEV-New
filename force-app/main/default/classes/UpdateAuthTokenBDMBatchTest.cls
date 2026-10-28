@isTest
public class UpdateAuthTokenBDMBatchTest {

    @isTest
    public static void testBatch(){
        User us = CommonDataTest.getUserBdm();        
        insert us;            
        
        UpdateAuthTokenBDMBatch obj = new UpdateAuthTokenBDMBatch('SELECT Id FROM User LIMIT 1');
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new MockRespond());
        	Database.executeBatch(obj);
        
        Test.stopTest();
    }
    
    @isTest

    public static void deleteTokenTest(){

        OauthToken oto = new OauthToken();  
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockRespond());         
        HttpResponse res = OauthFactory.deleteToken(oto);
        String contentType = res.getHeader('Content-Type');
        System.assertEquals(200, res.getStatusCode());
    }
    
    
}