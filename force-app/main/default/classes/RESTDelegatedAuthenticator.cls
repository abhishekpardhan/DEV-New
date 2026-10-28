//"This class authenticates and accepts the Single-Sign On request from the delegated user.
@RestResource(urlMapping='/delegatedAuth')
global without sharing class RESTDelegatedAuthenticator {
    
    //Post request method to send the Authencticate as true in response
    @HttpPost
    global static void Authenticate() {
        RestResponse response = RestContext.response;
        response.statusCode = 200;
        response.addHeader('Accept', 'application/xml');
        Boolean authResult = true;
        Dom.Document doc = new DOM.Document(); 
        doc.load(RestContext.request.requestBody.toString());  
        DOM.XMLNode root = doc.getRootElement();
        Map<String,String> requestValues = walkThrough(root);
        String soapResp = '<?xml version="1.0" encoding="UTF-8"?>'
            +'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
            +'<soapenv:Body>'
            +'<AuthenticateResult xmlns="urn:authentication.soap.sforce.com">'
            +'<Authenticated>'+authResult+'</Authenticated>'
            +'</AuthenticateResult>'
            +'</soapenv:Body>'
            +'</soapenv:Envelope>';
        if(requestValues.get('password') == 'safexp123'){
            response.responseBody = Blob.valueOf(soapResp);
        }        
    }    
    
/*
* Gets all text elements of the DOM
*/
    private static map<String,String> walkThrough(DOM.XMLNode node) {
        map<String,String> tempMap = new map<String,String>();
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            if (node.getText().trim() != '') {
                tempMap.put(node.getName(), node.getText());
            }
            for (Dom.XMLNode child: node.getChildElements()) {
                tempMap.putAll(walkThrough(child));
            }
        }
        return tempMap; 
    }
}