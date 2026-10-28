@isTest
public class MockHttpResponsePreBooking implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req){
        
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody('{ "data": { "responseData": "1234567890" } }');
        return res;
    }
}