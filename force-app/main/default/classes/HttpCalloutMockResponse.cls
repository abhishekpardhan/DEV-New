@isTest

global class HttpCalloutMockResponse implements HttpCalloutMock {
// Implement this interface method
  //Boolean called = false;

global HTTPResponse respond(HTTPRequest request) {
  
    String jsonResponse1 = '[{"SALE_DOC_#:"ENQ20191118001098","REMARK2":"Out for Delivery GJ18BT1861","status":"Active"}]';
    // String jsonResponse ='{"client_id=''&client_secret='+ClientSecret+'&grant_type='+Granttype"}';
    HttpResponse response2 = new HttpResponse();
    response2.setHeader('Content-Type','application/json');
     response2.setBody(jsonResponse1);
    response2.setStatusCode(100);
    return response2;
    
 }
}