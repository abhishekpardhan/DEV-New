/**
 * Description		:	This class has functionality for the user to login into the lightning app. An Http request is sent and if the response is error, 
 * 						 then it shows the error message and if the response is success then it redirects to URL of the lightning app.
 * 
 * Revision			:	V_1.0 - Created
 * 
 **/
public class CustomLoginController {
    
    public String username {get;set;}
    public String password {get;set;}
    public String Errormessage{get;set;}
    
    public PageReference doLogin() {
        String url;
        try{
        Http http = new Http();
        String Endpoint = System.Label.AD_API;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setTimeout(60000);
        // Set the body as a JSON object
        //String body = 'username='+username+'&password='+password+'&grant_type=password';
        String body = '{"grant_type":"password"' + ',"username":"' + username + '","password":"' + password + '"}';
        request.setbody(body);        
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus());            
            if(response.getStatusCode() == 504){
                Errormessage = 'Gateway Timeout Error';
            }
            else{
            JSONParser parser = JSON.createParser(response.getBody());
            // Advance to the next token.
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                    (parser.getText() == 'error_description')) {                        
                        parser.nextToken();
                        
                        Errormessage = parser.getText();
                        break;
                    }
                
                System.debug('Current token: ' +
                             parser.getCurrentToken());
            }
                }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,Errormessage));
            return null;
        } else {                        
            // Parse JSON response to get the token value.
            jsonParser2 jp = (jsonParser2)JSON.deserializeStrict(
                response.getBody(),jsonParser2.class);            
            if(jp.access_token != null){
                user u = [select id,username from user where AD_Id__c =: username limit 1];
                String uname = u.Username;
                String pword = 'safexp123';
                String SFUrl = System.label.AD_URL;
                String InstanceUrl = System.Label.Instance_Url;
                url = InstanceUrl+'?un='+EncodingUtil.urlEncode(uname, 'utf8')+'&pw='+EncodingUtil.urlEncode(pword, 'utf8')+'&rememberUn=0&startURL='+SFUrl;
            }
            PageReference page = new PageReference(url);
            page.setRedirect(false);
            return page;
        }
                
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
            return null;
        }
    }
    public class jsonParser2{
        public String access_token;
        public String token_type;
        public String expires_in;
        
    }
}