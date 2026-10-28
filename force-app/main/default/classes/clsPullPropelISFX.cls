public class clsPullPropelISFX {
    
    // method to get response code 
    public static HttpResponse pullRecords_API(String SFXEndPoint, String usrName, String tokenAuth){
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(SFXEndPoint);
        httpReq.setMethod('GET');
        httpReq.setHeader('Content-Type','application/json;charset=UTF-8');
        httpReq.setHeader('X-Content-Type-Options',System.Label.X_Content_Type_Options);
        httpReq.setHeader('X-XSS-Protection', System.Label.X_XSS_Protection);
        httpReq.setHeader('X-Frame-Options', System.Label.X_Frame_Options);
        httpReq.setHeader('X-API-Key', System.Label.X_API_Key);
        httpReq.setHeader('userId',usrName);
        httpReq.setHeader('Accept','*/*');
        httpReq.setHeader('Authorization',tokenAuth);
        httpReq.setTimeout(120000);
        //httpReq.setbody(jsonString);
        System.debug('httpReq---------->'+httpReq);
        Http htp = new Http();
        HttpResponse htpRes = htp.send(httpReq);
        System.debug('htpRes-------------->'+htpRes);
        
        if(htpRes.getStatusCode() != 400 && htpRes.getStatusCode() != 401 && htpRes.getStatusCode() != 500 && htpRes.getStatusCode() != 200)
        {
            ExceptionHandling.createAPILog('clsPullPropelISFX', SFXEndPoint, httpReq.getBody(), htpRes.getBody(), htpRes.getStatusCode());
        }
        return htpRes;
    }
    public static void pullSFXData(String sfx)
    {
        system.debug('sfx------>'+sfx);
        if(String.isNotEmpty(sfx))
        {
            String SFXEndPoint = System.label.UploadSFXEndPoint;
            SFXEndPoint +=sfx ;
            String usrName = System.label.Propeli_Username;
            String password = System.label.Propeli_Password;
            String channelId = System.label.PropelIChannelId;
            String xAPIKey = System.label.X_API_Key;
            String tokenEndPoint = System.label.PropeliTokenEndpoint;
            String usrId = System.label.PropelIIntegrationUsrId;
            
            String str_pltIntegrationProfileId = System.label.Platform_Integration_Profile_ID;
            System.debug('str_pltIntegrationProfileId--------------->'+str_pltIntegrationProfileId);
            
            String tokenAuth = cls_AddTokenBillingSystem.GetToken(usrId);
            System.debug('tokenAuth----------->'+tokenAuth);
            
            HttpResponse htpRes = pullRecords_API(SFXEndPoint, usrName, tokenAuth);
            if(htpRes.getStatusCode() == 200)
            {
                //Code to upsert the SFX
                System.debug('Response Body------>'+htpRes.getBody());
                temp_PropelISFXUpsert.createCustomer(htpRes.getBody());
                
            }
            else if(htpRes.getStatusCode() == 400 || htpRes.getStatusCode() == 401 || htpRes.getStatusCode() == 500){
                JSONGenerator genAuth = JSON.createGenerator(true);
                genAuth.writeStartObject();
                genAuth.writeStringField('grant_type', 'client_credentials');
                genAuth.writeStringField('scope', 'server/sfdc');
                genAuth.writeEndObject();
                String jsonAuthString = genAuth.getAsString(); 
                System.debug('jsonAuthString------------------------>'+jsonAuthString);
                
                HttpResponse htpTokenRes = cls_PropelICallout.propelITokenCallout(usrName, password,'POST',jsonAuthString,tokenEndPoint);
                System.debug('htpTokenRes------------->'+htpTokenRes);
                
                if(htpTokenRes.getStatusCode() == 200 || cls_RecursiveHandler.bol_isTesting2)
                {
                    System.debug('htpTokenRes.getBody()--------------->'+htpTokenRes.getBody());
                    //Parse the token response
                    if(! Test.isRunningTest())
                    {
                        jsonParser2 tokenRes = (jsonParser2)JSON.deserialize(htpTokenRes.getBody(), jsonParser2.class);
                        System.debug('tokenRes.access_token----------->'+tokenRes.access_token);
                        tokenAuth = tokenRes.access_token;
                        system.debug('tokenAuth----->'+tokenAuth);
                    }    
                    HttpResponse htpRes1 = pullRecords_API(SFXEndPoint, usrName, tokenAuth);
                    System.debug('htpRes-------------->'+htpRes1);
                    
                    if(htpRes1.getStatusCode() == 200)
                    {
                        system.debug('Response Body------>'+htpRes1.getBody());
                        //cls_TempUpsertSFX.createCustomer(htpRes1.getBody());
                        temp_PropelISFXUpsert.createCustomer(htpRes1.getBody());
                    }
                }
            }
        }
    }
    
    @future(callout=true)
    public static void pullSFXRecords(String sfx)
    {
        system.debug('sfx------>'+sfx);
        if(String.isNotEmpty(sfx))
        {
            
            String SFXEndPoint = System.label.UploadSFXEndPoint;
            SFXEndPoint +=sfx ;
            String str_pltIntegrationProfileId = System.label.Platform_Integration_Profile_ID;
            String usrName = System.label.Propeli_Username;
            String password = System.label.Propeli_Password;
            String channelId = System.label.PropelIChannelId;
            String xAPIKey = System.label.X_API_Key;
            String tokenEndPoint = System.label.PropeliTokenEndpoint;
            String usrId = System.label.PropelIIntegrationUsrId;
            System.debug('str_pltIntegrationProfileId--------------->'+str_pltIntegrationProfileId);
            
            String tokenAuth = cls_AddTokenBillingSystem.GetToken(usrId);
            System.debug('tokenAuth----------->'+tokenAuth);
            
            // When the token is already in the system.
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(SFXEndPoint);
            httpReq.setMethod('GET');
            httpReq.setHeader('Content-Type','application/json;charset=UTF-8');
            httpReq.setHeader('X-Content-Type-Options',System.Label.X_Content_Type_Options);
            httpReq.setHeader('X-XSS-Protection', System.Label.X_XSS_Protection);
            httpReq.setHeader('X-Frame-Options', System.Label.X_Frame_Options);
            httpReq.setHeader('X-API-Key', System.Label.X_API_Key);
            httpReq.setHeader('userId',usrName);
            httpReq.setHeader('Accept','*/*');
            httpReq.setHeader('Authorization',tokenAuth);
            httpReq.setTimeout(120000);
            //httpReq.setbody(jsonString);
            System.debug('httpReq---------->'+httpReq);
            Http htp = new Http();
            HttpResponse htpRes = htp.send(httpReq);
            System.debug('htpRes-------------->'+htpRes);
            if(htpRes.getStatusCode() == 200)
            {
                //Code to upsert the SFX
                //SFX_RATE_UpsertAPI.createCustomer(htpRes.getBody());
                System.debug('Response Body------>'+htpRes.getBody());
                //cls_TempUpsertSFX.createCustomer(htpRes.getBody());
                temp_PropelISFXUpsert.createCustomer(htpRes.getBody());
            }
            else if(htpRes.getStatusCode() == 400 || htpRes.getStatusCode() == 401 || htpRes.getStatusCode() == 500)
            {
                JSONGenerator genAuth = JSON.createGenerator(true);
                genAuth.writeStartObject();
                genAuth.writeStringField('grant_type', 'client_credentials');
                genAuth.writeStringField('scope', 'server/sfdc');
                genAuth.writeEndObject();
                String jsonAuthString = genAuth.getAsString(); 
                System.debug('jsonAuthString------------------------>'+jsonAuthString);
                HttpResponse htpTokenRes = cls_PropelICallout.propelITokenCallout(usrName, password,'POST',jsonAuthString,tokenEndPoint);
                System.debug('htpTokenRes------------->'+htpTokenRes);
                if(htpTokenRes.getStatusCode() == 200 || cls_RecursiveHandler.bol_isTesting2)
                {
                    System.debug('htpTokenRes.getBody()--------------->'+htpTokenRes.getBody());
                    //Parse the token response
                    if(! Test.isRunningTest())
                    {
                        jsonParser2 tokenRes = (jsonParser2)JSON.deserialize(htpTokenRes.getBody(), jsonParser2.class);
                        System.debug('tokenRes.access_token----------->'+tokenRes.access_token);
                        tokenAuth = tokenRes.access_token;
                        system.debug('tokenAuth----->'+tokenAuth);
                    }    
                    HttpRequest httpReq1 = new HttpRequest();
                    httpReq1.setEndpoint(SFXEndPoint);
                    httpReq1.setMethod('GET');
                    httpReq1.setHeader('Content-Type','application/json');
                    httpReq1.setHeader('X-Content-Type-Options',System.Label.X_Content_Type_Options);
                    httpReq1.setHeader('X-XSS-Protection', System.Label.X_XSS_Protection);
                    httpReq1.setHeader('X-Frame-Options', System.Label.X_Frame_Options);
                    httpReq1.setHeader('x-api-key', System.Label.X_API_Key);
                    httpReq1.setHeader('userId',usrName);
                    httpReq1.setHeader('Accept','*/*');
                    httpReq1.setHeader('Authorization', tokenAuth);
                    //String tokenAPI = 'eyJraWQiOiJ4ZStWNmxscE9XWHM4NitFZ1JhWTdSTkIwdzhFZGNWR1UwZm5qWWw3bkNzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIybG1iZG8xbTYwZDk3YXNma2U4cXFma2VkcyIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoic2VydmVyXC9zZmRjIiwiYXV0aF90aW1lIjoxNjY1NTU5OTIyLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAuYXAtc291dGgtMS5hbWF6b25hd3MuY29tXC9hcC1zb3V0aC0xXzJrR25OTFQwMiIsImV4cCI6MTY2NTY0NjMyMiwiaWF0IjoxNjY1NTU5OTIyLCJ2ZXJzaW9uIjoyLCJqdGkiOiI0NGFjOThmZS1hYjZiLTRlODctOWVkNC1mMjNjNDE5NjA0OTkiLCJjbGllbnRfaWQiOiIybG1iZG8xbTYwZDk3YXNma2U4cXFma2VkcyJ9.1VdFnGftWjhRzCH2WY8XrUKMoOtwmx5pPx3R9hu_9deeUBZd5_xmu8ICs3waRZ363JcHhr9RcVRa2AUZzamrs9tdR9HPHD5GsJ16VYZvccyRGM3roq0sJUT6aN6Bso5wYfJgVhebWPT_3jSgA1xPJqm013Pt8MNL7YrVqaGtPfrLG78x6S_5Dl9DeY5P4zM5YPXOkBPpb23Dk0ELZaPc8sM7kWRuFSDz35gttvg8qMLG_yjyyenrPsAmTciJCZZrqCSdU7Uwdg1ew1TaoeqdpMqE700RvK95SnC65b07upD0RGVZK9RZosEjguHzTlBbPt4vkIm5WuW151IKDteOGQ';
                    //httpReq1.setHeader('Authorization', tokenAPI);
                    
                    httpReq1.setTimeout(120000);
                    //httpReq1.setbody(jsonString);
                    Http htp1 = new Http();
                    HttpResponse htpRes1 = htp1.send(httpReq1);
                    System.debug('htpRes-------------->'+htpRes1);
                    if(htpRes1.getStatusCode() == 200)
                    {
                        
                        system.debug('Response Body------>'+htpRes1.getBody());
                        //cls_TempUpsertSFX.createCustomer(htpRes1.getBody());
                        temp_PropelISFXUpsert.createCustomer(htpRes1.getBody());
                    }
                    else {
                        ExceptionHandling.createAPILog('clsPullPropelISFX', SFXEndPoint, httpReq1.getBody(), htpRes1.getBody(), htpRes1.getStatusCode());
                    }
                }
            }
            else {
                ExceptionHandling.createAPILog('clsPullPropelISFX', SFXEndPoint, httpReq.getBody(), htpRes.getBody(), htpRes.getStatusCode());
            }
        }
        
    }
    
    //For fetching on-demand MSA
    @future(callout=true)
    public static void pullMSARecords(String sfxCode)
    {
        System.debug('sfxCode------>'+sfxCode);
        if(String.isNotEmpty(sfxCode))
        {
            String MSAEndPoint = System.label.UploadMSAEndPoint;
            MSAEndPoint +=sfxCode;
            String str_pltIntegrationProfileId = System.label.Platform_Integration_Profile_ID;
            String usrName = System.label.Propeli_Username;
            String password = System.label.Propeli_Password;
            String channelId = System.label.PropelIChannelId;
            String xAPIKey = System.label.X_API_Key;
            String tokenEndPoint = System.label.PropeliTokenEndpoint;
            String usrId = System.label.PropelIIntegrationUsrId;
            System.debug('str_pltIntegrationProfileId--------------->'+str_pltIntegrationProfileId);
            String tokenAuth = cls_AddTokenBillingSystem.GetToken(usrId);
            //String tokenAuth = 'eyJraWQiOiJ4ZStWNmxscE9XWHM4NitFZ1JhWTdSTkIwdzhFZGNWR1UwZm5qWWw3bkNzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIybG1iZG8xbTYwZDk3YXNma2U4cXFma2VkcyIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoic2VydmVyXC9zZmRjIiwiYXV0aF90aW1lIjoxNjY1NTU5OTIyLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAuYXAtc291dGgtMS5hbWF6b25hd3MuY29tXC9hcC1zb3V0aC0xXzJrR25OTFQwMiIsImV4cCI6MTY2NTY0NjMyMiwiaWF0IjoxNjY1NTU5OTIyLCJ2ZXJzaW9uIjoyLCJqdGkiOiI0NGFjOThmZS1hYjZiLTRlODctOWVkNC1mMjNjNDE5NjA0OTkiLCJjbGllbnRfaWQiOiIybG1iZG8xbTYwZDk3YXNma2U4cXFma2VkcyJ9.1VdFnGftWjhRzCH2WY8XrUKMoOtwmx5pPx3R9hu_9deeUBZd5_xmu8ICs3waRZ363JcHhr9RcVRa2AUZzamrs9tdR9HPHD5GsJ16VYZvccyRGM3roq0sJUT6aN6Bso5wYfJgVhebWPT_3jSgA1xPJqm013Pt8MNL7YrVqaGtPfrLG78x6S_5Dl9DeY5P4zM5YPXOkBPpb23Dk0ELZaPc8sM7kWRuFSDz35gttvg8qMLG_yjyyenrPsAmTciJCZZrqCSdU7Uwdg1ew1TaoeqdpMqE700RvK95SnC65b07upD0RGVZK9RZosEjguHzTlBbPt4vkIm5WuW151IKDteOGQ';//cls_AddTokenBillingSystem.GetToken(usrId);
            System.debug('tokenAuth----------->'+tokenAuth);
            // When the token is already in the system.
            
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(MSAEndPoint);
            httpReq.setMethod('GET');
            httpReq.setHeader('Content-Type','application/json;charset=UTF-8');
            httpReq.setHeader('X-Content-Type-Options',System.Label.X_Content_Type_Options);
            httpReq.setHeader('X-XSS-Protection', System.Label.X_XSS_Protection);
            httpReq.setHeader('X-Frame-Options', System.Label.X_Frame_Options);
            httpReq.setHeader('X-API-Key', System.Label.X_API_Key);
            httpReq.setHeader('userId',usrName);
            httpReq.setHeader('Accept','*/*');
            httpReq.setHeader('Authorization',tokenAuth);
            httpReq.setTimeout(120000);
            //httpReq.setbody(jsonString);
            System.debug('httpReq---------->'+httpReq);
            Http htp = new Http();
            HttpResponse htpRes = htp.send(httpReq);
            System.debug('htpRes-------------->'+htpRes);
            if(htpRes.getStatusCode() == 200)
            {
                System.debug('Response Body------>'+htpRes.getBody());
                cls_PullMSAOnDemand.upsertMSA(htpRes.getBody());
            }
            else if(htpRes.getStatusCode() == 400 || htpRes.getStatusCode() == 401 || htpRes.getStatusCode() == 500)
            {
                JSONGenerator genAuth = JSON.createGenerator(true);
                genAuth.writeStartObject();
                genAuth.writeStringField('grant_type', 'client_credentials');
                genAuth.writeStringField('scope', 'server/sfdc');
                genAuth.writeEndObject();
                String jsonAuthString = genAuth.getAsString(); 
                System.debug('jsonAuthString------------------------>'+jsonAuthString);
                HttpResponse htpTokenRes = cls_PropelICallout.propelITokenCallout(usrName, password,'POST',jsonAuthString,tokenEndPoint);
                System.debug('htpTokenRes------------->'+htpTokenRes);
                if(htpTokenRes.getStatusCode() == 200 || cls_RecursiveHandler.bol_isTesting2)
                {
                    System.debug('htpTokenRes.getBody()--------------->'+htpTokenRes.getBody());
                    //Parse the token response
                    if(! Test.isRunningTest())
                    {
                        jsonParser2 tokenRes = (jsonParser2)JSON.deserialize(htpTokenRes.getBody(), jsonParser2.class);
                        System.debug('tokenRes.access_token----------->'+tokenRes.access_token);
                        tokenAuth = tokenRes.access_token;
                        system.debug('tokenAuth----->'+tokenAuth);
                    }    
                    HttpRequest httpReq1 = new HttpRequest();
                    httpReq1.setEndpoint(MSAEndPoint);
                    httpReq1.setMethod('GET');
                    httpReq1.setHeader('Content-Type','application/json');
                    httpReq1.setHeader('X-Content-Type-Options',System.Label.X_Content_Type_Options);
                    httpReq1.setHeader('X-XSS-Protection', System.Label.X_XSS_Protection);
                    httpReq1.setHeader('X-Frame-Options', System.Label.X_Frame_Options);
                    httpReq1.setHeader('x-api-key', System.Label.X_API_Key);
                    httpReq1.setHeader('userId',usrName);
                    httpReq1.setHeader('Accept','*/*');
                    httpReq1.setHeader('Authorization', tokenAuth);
                    //String tokenAPI = 'eyJraWQiOiJ4ZStWNmxscE9XWHM4NitFZ1JhWTdSTkIwdzhFZGNWR1UwZm5qWWw3bkNzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIybG1iZG8xbTYwZDk3YXNma2U4cXFma2VkcyIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoic2VydmVyXC9zZmRjIiwiYXV0aF90aW1lIjoxNjY1NTU5OTIyLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAuYXAtc291dGgtMS5hbWF6b25hd3MuY29tXC9hcC1zb3V0aC0xXzJrR25OTFQwMiIsImV4cCI6MTY2NTY0NjMyMiwiaWF0IjoxNjY1NTU5OTIyLCJ2ZXJzaW9uIjoyLCJqdGkiOiI0NGFjOThmZS1hYjZiLTRlODctOWVkNC1mMjNjNDE5NjA0OTkiLCJjbGllbnRfaWQiOiIybG1iZG8xbTYwZDk3YXNma2U4cXFma2VkcyJ9.1VdFnGftWjhRzCH2WY8XrUKMoOtwmx5pPx3R9hu_9deeUBZd5_xmu8ICs3waRZ363JcHhr9RcVRa2AUZzamrs9tdR9HPHD5GsJ16VYZvccyRGM3roq0sJUT6aN6Bso5wYfJgVhebWPT_3jSgA1xPJqm013Pt8MNL7YrVqaGtPfrLG78x6S_5Dl9DeY5P4zM5YPXOkBPpb23Dk0ELZaPc8sM7kWRuFSDz35gttvg8qMLG_yjyyenrPsAmTciJCZZrqCSdU7Uwdg1ew1TaoeqdpMqE700RvK95SnC65b07upD0RGVZK9RZosEjguHzTlBbPt4vkIm5WuW151IKDteOGQ';
                    //httpReq1.setHeader('Authorization', tokenAPI);
                    
                    httpReq1.setTimeout(120000);
                    //httpReq1.setbody(jsonString);
                    Http htp1 = new Http();
                    HttpResponse htpRes1 = htp1.send(httpReq1);
                    System.debug('htpRes-------------->'+htpRes1);
                    if(htpRes1.getStatusCode() == 200)
                    {
                        system.debug('Response Body------>'+htpRes1.getBody());
                        cls_PullMSAOnDemand.upsertMSA(htpRes1.getBody());
                    }
                    else {
                        ExceptionHandling.createAPILog('clsPullPropelISFX', MSAEndPoint, httpReq1.getBody(), htpRes1.getBody(), htpRes1.getStatusCode());
                    }
                }
            }
            else {
                ExceptionHandling.createAPILog('clsPullPropelISFX', MSAEndPoint, httpReq.getBody(), htpRes.getBody(), htpRes.getStatusCode());
            }
        }   
    }
    
    //JSONParser 1
    Public class jsonParser2
    {
        public String access_token;
        public String token_type;
        public String expires_in;
    } 
}