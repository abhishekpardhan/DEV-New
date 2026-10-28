/**
 * An apex class to generate the mock response for the test classes
 **/
@isTest
global class HttpCalloutMockClass1 implements HttpCalloutMock {
// Implement this interface method
  //Boolean called = false;

global HTTPResponse respond(HTTPRequest request) {
  
    String jsonResponse1 = '[{"TokenNo":"ajidjsnfn12433","Status":"Success","Message":[""],"SFId":"a095D000000rbXp"}]';
    // String jsonResponse ='{"client_id=''&client_secret='+ClientSecret+'&grant_type='+Granttype"}';
    HttpResponse response2 = new HttpResponse();
    response2.setHeader('Content-Type','application/json');
     response2.setBody(jsonResponse1);
    response2.setStatusCode(100);
    return response2;
    
 }
}