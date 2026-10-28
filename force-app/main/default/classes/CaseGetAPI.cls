public class CaseGetAPI implements Schedulable {   
    
    //Executing method of schedulable interface to schedule the class at specific time
    public void execute(SchedulableContext sc) {
        CaseGetAPI cs = new CaseGetAPI();
        CaseGetAPI.caseFromProton();       
    }
    
    /**
     * Method to get the 'Case__c' status from third party api
     **/
    @future(callout=true)
    public static void caseFromProton(){
        String token;        
            Id rIdOpr = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Operation Issues').getRecordTypeId();
            list<Case__c> listCases = new list<Case__c>([select id,name,Case_Type__c,Case_Raised_By__c,Name__c,Phone__c,Email__c,Status__c,Remarks__c,Waybill_Numbers__c,Proton_Token_No__c,Integration_Error_Message__c from case__c where recordtypeid=:rIdOpr and Proton_Token_No__c != null and Status__c = 'Active']);
            System.debug('listCases'+listCases);
       		if(!listCases.isEmpty()){                            
            String Endpoint = System.Label.Case_Authentication_Api;
            String ClientId = System.Label.Client_Id;
            String ClientSecret = System.Label.Client_Secret;
            String Granttype = System.Label.grant_type;
            list<Case__c> cseupdate = new list<case__c>();
            Http http = new Http();        
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setTimeout(30000);
            // Set the body as a JSON object
            String body = 'client_id='+ClientId+'&client_secret='+ClientSecret+'&grant_type='+Granttype;
            request.setbody(body);        
            HttpResponse response = http.send(request);
            // Parse the JSON response            
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus());                
                
                JSONParser parser = JSON.createParser(response.getBody());
                // Advance to the next token.
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                        (parser.getText() == 'error_description')) {                            
                            parser.nextToken();
                        }
                }
                
            } else {            
                System.debug('++++'+response.getBody());
                // Parse JSON response to get the token value.
                jsonParser2 jp = (jsonParser2)JSON.deserializeStrict(
                    response.getBody(),jsonParser2.class); 
           			System.debug('jb'+jp);
                if(jp.access_token != null){
                    token = jp.access_token;
                }
                
            }
                //list<case__c> casetoupdate = new list<case__c>();
            if(token != null){
                Http http2 = new Http();        
                HttpRequest request2 = new HttpRequest();
                String TokentoSearch;
                String CaseEndPoint;
                for(Case__c cse : listCases){
                system.debug('case' +cse);
                TokentoSearch = cse.Proton_Token_No__c; 
                system.debug('TokentoSearch' +TokentoSearch);
                CaseEndPoint = System.Label.CaseGETAPI+TokentoSearch;
                system.debug('CaseEndPoint' +CaseEndPoint);
                //request2.setbody(CaseEndPoint); 
                request2.setEndpoint(CaseEndPoint);
                request2.setMethod('GET');
                request2.setHeader('Content-Type','application/json;charset=UTF-8');
                request2.setHeader('Authorization','bearer '+token);
                request2.setTimeout(30000); 
                HttpResponse response2 = http2.send(request2); 
                system.debug('response2' +response2);
                system.debug('response2 status code' +response2.getStatusCode());
                system.debug('response2 body' +response2.getBody());
                // Parse the JSON response
                if (response2.getStatusCode() != 200) {
                    System.debug('The status code returned was not expected: ' +
                                 response2.getStatusCode() + ' ' + response2.getStatus());                    
                    
                    JSONParser parser = JSON.createParser(response2.getBody());
                    
                }
        else {
                   List<jsonParser3> lstJp = (List<jsonParser3>) System.JSON.deserialize(response2.getBody(),List<jsonParser3>.class);                    
                       system.debug('lstJp' +lstJp);
            		   for(jsonParser3 jp3 : lstJp){
                       cse.Proton_Remarks__c= jp3.REMARK2; 
                       cse.Status__c= jp3.status;
                       system.debug('jp3.REMARK2' +jp3.REMARK2);
                       system.debug('jp3.Status' +jp3.Status);                        
                       cseupdate.add(cse);                          
                   }
                        }}
            //}
                        //system.debug('Status'+ cseupdate.Status__c);
                        update cseupdate;
                		system.debug('updated case' +cseupdate); 
            }}}
                                          
                    
    //JSONParser 1
        public class jsonParser2{
        public String access_token;
        public String token_type;
        public String expires_in;
        }
    
        //JSONParser 2
   		public class jsonParser3{
        public String REMARK2;
        public String Status;
    }
}