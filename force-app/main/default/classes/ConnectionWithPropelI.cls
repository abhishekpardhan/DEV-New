/*********************************************************************************************
**Author: Safexpress.com
**Description: This class is implemented for Propeli Backend Update Syncing in Salesforce 
**JIRA Ticket: SAC-108
**Test Class: TestConnectionWithPropelI
**History: 
**Modified Date: 01/09/2023                
**Created By: Megha kumar
*************************************************************************************************** */

public class ConnectionWithPropelI {
    
    @future(callout=true)
    public static void connectWithPropelI(){
        
        String username = system.label.Propeli_Username;
        String password = system.label.Propeli_Password;
        //String apiKey = system.label.PropelIUATPreBookingAPIKey;
        String tokenEndPoint = system.label.PropeliTokenEndpoint;
        //String endpoint = 'https://apigateway-test.safexpress.com/cc/v1/sfi/cc/updtBranchesOrRateCard?updtDt=2023-09-12';
        //String endpoint = 'https://apigateway-test.safexpress.com/cc/v1/sfi/cc/updtBranchesOrRateCard?updtDt=';
        String endpoint = system.label.PropeliEndpoint;
        Date dToday = Date.today() -1;
        String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
        endpoint +=dateStr;
        String tokenAuth;
        try{
            
            if(tokenEndPoint != null && username != null && password != null){
                JSONGenerator genAuth = JSON.createGenerator(true);
                genAuth.writeStartObject();
                genAuth.writeStringField('grant_type', 'client_credentials');
                genAuth.writeStringField('scope', 'propeli-test/sfdc');
                //genAuth.writeStringField('x-apikey', apiKey);
                genAuth.writeEndObject();
                String jsonAuthString = genAuth.getAsString();                
                HttpResponse res = cls_PropelICallout.propelITokenCallout(username, password,'POST',jsonAuthString, tokenEndPoint);
                system.debug('res body ==>'+res.getBody());
                
                if(res.getStatusCode() == 200)
                {                   
                    jsonParser2 tokenRes = (jsonParser2)JSON.deserialize(res.getBody(), jsonParser2.class);
                    tokenAuth = tokenRes.access_token;
                    system.debug('tokenAuth----->'+tokenAuth);
                }
                
                HttpRequest httpReq = new HttpRequest();
                httpReq.setEndpoint(endpoint);
                httpReq.setMethod('GET');
                httpReq.setHeader('Content-Type','application/json');
                httpReq.setHeader('userId', username);
                httpReq.setHeader('Authorization',tokenAuth);
                httpReq.setHeader('Accept', 'application/json');
                httpReq.setTimeout(120000);
                System.debug('httpReq---------->'+httpReq);
                Http htp = new Http();
                HttpResponse htpRes = htp.send(httpReq);
                System.debug('Body--->'+htpRes.getBody());
                String jsonBody = htpRes.getBody();
                //String jsonBody = '{"message": "Request Successfully completed", "data": {"responseData": ["SFX00010643"], "referenceData": {}}, "status": "SUCCESS"}';
                Response response = (Response) JSON.deserialize(jsonBody, Response.class);
                String message = response.message;
                List<String> responseData = response.data.responseData;
                system.debug('responseData--->'+responseData);
                String status = response.status; 
                
                ID jobId = System.enqueueJob(new BackSFXUpdateFuture(responseData));
                /*
                for(Integer i=0;i<responseData.size();i++){
                    
                    string sfxCode = responseData[i];
                    ID jobId = System.enqueueJob(new BackSFXUpdateFuture(sfxCode));
                }*/
                                              
            }
        }catch(Exception e){            
        }
    }    
    Public class jsonParser2
    {
        public String access_token;
        public String token_type;
        public String expires_in;
    }  
       
    public class Response {
    public String message;
    public Data data;
    public String status;
    }

    public class Data {
        public List<String> responseData;
        public Map<String, Object> referenceData;
    } 
    
}