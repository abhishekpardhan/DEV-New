/**
 * Description		:		Test class for RESTDelegatedAuthenticator apex class
 * 
 * Coverage			:		95%
 **/
@isTest 
public class RESTDelegatedAuthenticatorTest{
    static testMethod void testMethod1() {        
        RestRequest req1 = new RestRequest(); 
        RestResponse res1 = new RestResponse();
        
        String soapResp = '<?xml version="1.0" encoding="UTF-8"?>'
            +'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
            +'<soapenv:Body>'
            +'<AuthenticateResult xmlns="urn:authentication.soap.sforce.com">'
            +'<Authenticated>+true+</Authenticated>'
            +'</AuthenticateResult>'
            +'</soapenv:Body>'
            +'</soapenv:Envelope>';
        req1.requestBody = Blob.valueOf(soapResp);
        
        req1.requestURI = '/services/apexrest/RESTDelegatedAuthenticator';
        req1.httpMethod = 'POST';
        RestContext.request = req1;
        RestContext.response = res1;

        RESTDelegatedAuthenticator.Authenticate();

    }
}