@isTest(SeeAllData = true)
global class mockTestClass implements  HttpCalloutMock 
{
    global String json;
    global String auth;
    global String status;
    global Integer statusCode;
    global  mockTestClass(String json, String auth, String status, Integer statusCode)
    {
        this.json = json;
        this.auth = auth;
        this.status = status;
        this.statusCode = statusCode;
    }

    global HTTPResponse respond(HTTPRequest req) 
    {
            String jsonResponse = 
                '[{"billId":893,"billNumber":"21020100003","status":"ERROR","message":""},{"billId":892,"billNumber":"211703000014","status":"ERROR","message":""}]';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setHeader('Authorization',auth);
            //objResponse.setTimeout(30000);      
            objResponse.setBody(json);
            objResponse.setStatus(status);
            objResponse.setStatusCode(statusCode);
            return objResponse;
      }
    

    /*global class MockHttpErrorResponseSubmissionAPI implements  HttpCalloutMock  {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            String jsonResponse = 
                '[{"billId":893,"billNumber":"211703000015","status":"ERROR","message":""},{"billId":892,"billNumber":"211703000014","status":"ERROR","message":""}]';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setHeader('Authorization','00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW');
            //objResponse.setTimeout(30000);      
            objResponse.setBody(jsonResponse);
            objResponse.setStatus('success');
            objResponse.setStatusCode(400);
            return objResponse;
        }
    } */
    /* global class MockHttpTokenResponse implements  HttpCalloutMock  {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            String jsonResponse = 
                '{"access_token":"GSGDGFSFSFFSFSFFSFFSFSFFSFSFSFSFSFFSFFSFSFSFFSFSF","expires_in":18000, "token_type":"Bearer"}';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setHeader('Authorization','00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW');
            //objResponse.setTimeout(30000);      
            objResponse.setBody(jsonResponse);
            objResponse.setStatus('success');
            objResponse.setStatusCode(200);
            return objResponse;
        }
    } */
}