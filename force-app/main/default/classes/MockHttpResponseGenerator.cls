@istest
public class MockHttpResponseGenerator implements HttpCalloutMock {
	    
    public HTTPResponse respond(HTTPRequest req){
    	
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if (req.getEndpoint().contains('token')) {
            // Return a fake access token
            res.setBody('{"access_token": "fake_token", "token_type": "Bearer", "expires_in": 3600}');
        }else if (req.getEndpoint().contains('updtBranchesOrRateCard')) {
            // Return a fake response data with one SFX code
            res.setBody('{"message": "Request Successfully completed", "data": {"responseData": ["SFX00010643"], "referenceData": {}}, "status": "SUCCESS"}');
        }
        return res;
    }	
    
}