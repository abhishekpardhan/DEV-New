/**
 * An apex class to generate the mock response for the test classes
 **/
@isTest
global class HttpCalloutMockClass implements HttpCalloutMock {
// Implement this interface method
  //Boolean called = false;

global HTTPResponse respond(HTTPRequest request) {
  
    // Create a fake response
    system.debug('request.getEndpoint()++'+request.getEndpoint());
    if(request.getEndpoint().endsWith('token')){
     String jsonResponse = '{"access_token":"ajidjsnfn12433","token_type":"abc","expires_in":"12345"}';
    HttpResponse response = new HttpResponse();
    response.setHeader('Content-Type','application/json');
    //String body = '{"response": "Records Synced"}';
   // response.setBody('{"username":"05116"},{"password":"man@4321"},{"grant_type":"password"}');
   response.setBody(jsonResponse);
    response.setStatusCode(200);
    return response;
    }
    else{
    
    String jsonResponse1 = '[{"TokenNo":"ajidjsnfn12433","Status":"Success","Message":[""],"SFId":"a095D000000rbXp"}]';
    // String jsonResponse ='{"client_id=''&client_secret='+ClientSecret+'&grant_type='+Granttype"}';
    HttpResponse response2 = new HttpResponse();
    response2.setHeader('Content-Type','application/json');
     response2.setBody(jsonResponse1);
    response2.setStatusCode(200);
    return response2;
    
    }
 }
}