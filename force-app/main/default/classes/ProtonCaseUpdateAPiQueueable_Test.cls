/**
* @File Name          : ProtonCaseUpdateAPiQueueable.cls
* @Description        : This class will used to cover code of ProtonCaseUpdateAPiQueueable
* @Author             : HIMANSHI DANG
* @Group              : IBM
* @Last Modified By   : HIMANSHI DANG
* @Last Modified On   : 16/06/2024
**/

@isTest
public class ProtonCaseUpdateAPiQueueable_Test {
     
    public class MockHttpResponseProton implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req){
            
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"statusCode": "0000","statusDesc": "Sucessfull"}');
            return res;
        }
    }
     
    @isTest
    static void updateCaseSuccessTest(){
        
        Case ca = new Case();
        ca.Subject = 'request';
        ca.Origin = 'Reverse Pickup';
        ca.Description = 'testing description';
        ca.Status ='In Progress';
        ca.SuppliedEmail = 'test@test.com';
        ca.Case_Nature__c = 'request';
        ca.PropelI_PreBooking_Id__c = '111';
        insert ca;        
        // Retrieve the case number of newly created case 
        ca = [SELECT Id, CaseNumber FROM Case Where Id =: ca.Id];
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = ca.CaseNumber;
        fakeResponse.preBookingRequestId = '111'; 
        fakeResponse.lastupdatedate = Date.today().Day()+'/'+Date.today().month()+'/'+Date.today().year();
        fakeResponse.rescheduledate = (Date.today().Day()+1)+'/'+Date.today().month()+'/'+Date.today().year();
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new MockHttpResponseProton());
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
         
    }
    
    
}