public class GetPropelIToken 
{
    //  @future(callout=true)
    public static String getToken()
    {
        //Akshay(09/30): Created to hold the generated access token.
        String str_PropelIAccessToken;
        JSONGenerator gen1 = JSON.createGenerator(true);
        gen1.writeStartObject();
        gen1.writeNumberField('channelId', 0);  
        gen1.writeStringField('password', System.Label.Propeli_Password);
        gen1.writeStringField('username', System.Label.Propeli_Username);
        gen1.writeEndObject();
        String jsonString1 = gen1.getAsString(); 
        system.debug(jsonString1);
        String EndPoint =System.Label.PropeliTokenEndpoint;

        Http http = new Http();  
        HttpRequest request = new HttpRequest();
        request.setEndpoint(EndPoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('X-Content-Type-Options',System.Label.X_Content_Type_Options);
        request.setHeader('X-XSS-Protection', System.Label.X_XSS_Protection);
        request.setHeader('X-Frame-Options', System.Label.X_Frame_Options);
        request.setHeader('X-API-Key', System.Label.X_API_Key);
        request.setHeader('userId','pisfintg');
        request.setHeader('tokenReq','tokenReq');
        request.setTimeout(30000);
        request.setbody(jsonString1);
        system.debug(EndPoint);
            
        HttpResponse response = http.send(request);
        // Parse the JSON response            
        System.debug('@@@@@@@@@'+ response.getBody());
        if (response.getStatusCode() != 200)
        {
            System.debug('The status code returned was not expected: ' +
                            response.getStatusCode() + ' ' + response.getStatus()); 
            JSONParser parser = JSON.createParser(response.getBody());
            // Advance to the next token.
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                    (parser.getText() == 'error_description')) 
                {                            
                    parser.nextToken();
                }
            }
        }else 
        {            
            System.debug('++++'+response.getBody());
            // Parse JSON response to get the token value.
            jsonParser2 jp = (jsonParser2)JSON.deserialize(response.getBody(),jsonParser2.class);             
            system.debug('###########'+jp);
            if(jp.data.responseData != null)
            {

                str_PropelIAccessToken = jp.data.responseData;
                //PropelIToken.addToken(jp.data.responseData, '0057F000002y4xPQAQ');
                System.debug('token: '+jp.data.responseData);
            } 
        }

        System.debug('str_PropelIAccessToken---------->'+str_PropelIAccessToken);
        return str_PropelIAccessToken;
    }

    // JSONParser 2
    public class jsonParser2{
        public String message;
        public jsonParser3 data;
        public String status;
    }   
    public class jsonParser3{
        public String responseData;
    }
}