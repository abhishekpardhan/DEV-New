/**
 * Description		:		Class to send the 'Case__c' object records (Operation Issues cases) to Safexpress by hitting thier endpoint
 * Created By       :       Shubham Girdhar
 * Created Date     :       
 * Release          :       18th August, 2019
 * Last Modified on :       8th August, 2019
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
public class CasePushApi implements Schedulable {   
    
    //Executing method of schedulable interface to schedule the class at specific time
    public void execute(SchedulableContext sc) {
        CasePushApi cs = new CasePushApi();
        CasePushApi.caseFromSF();       
    }
    
    /**
     * Method to send the 'Case__c' records to third party api
     **/
    @future(callout=true)
    public static void caseFromSF(){
        String token;        
        try{
            Id rIdOpr = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Operation Issues').getRecordTypeId();
            map<Id,case__c> mapCases = new map<Id,case__c>([select id,name,Case_Type__c,Case_Raised_By__c,Name__c,Phone__c,Email__c,Status__c,Remarks__c,Waybill_Numbers__c,Proton_Token_No__c,Integration_Error_Message__c from case__c where recordtypeid=:rIdOpr and Proton_Token_No__c = null and Status__c = 'Active']);            
            if(!mapCases.isEmpty()){                            
            String Endpoint = System.Label.Case_Authentication_Api;
            String ClientId = System.Label.Client_Id;
            String ClientSecret = System.Label.Client_Secret;
            String Granttype = System.Label.grant_type;
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
                if(jp.access_token != null){
                    token = jp.access_token;
                }
                
            }            
            //After token generated then send json
            if(token != null){
                map<Id,String> mapCaseIdTokenNo = new map<Id,String>();                                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeFieldName('New_Operational_Cases');
                gen.writeStartArray();
                for(case__c cs: mapCases.values()){
                    gen.writeStartObject();
                    if(cs.Case_Type__c != null){
                        gen.writeStringField('C_Type', cs.Case_Type__c);            
                    }
                    else{
                        gen.writeStringField('C_Type', '');
                    }
                    if(cs.Case_Raised_By__c != null){
                        gen.writeStringField('RaisedBy', cs.Case_Raised_By__c);
                    }
                    else{
                        gen.writeStringField('RaisedBy', '');
                    }
                    if(cs.Name__c != null){
                        gen.writeStringField('ContactPerson', cs.Name__c);
                    }
                    else{
                        gen.writeStringField('ContactPerson', '');
                    }
                    if(cs.Phone__c != null){
                        gen.writeStringField('Phone', cs.Phone__c);
                    }
                    else{
                        gen.writeStringField('Phone', '');
                    }
                    if(cs.Email__c != null){
                        gen.writeStringField('Email', cs.Email__c);
                    }
                    else{
                        gen.writeStringField('Email', '');
                    }
                    if(cs.Status__c != null){
                        gen.writeStringField('Status', cs.Status__c);
                    }
                    else{
                        gen.writeStringField('Status', '');
                    }
                    if(cs.Remarks__c != null){
                        gen.writeStringField('Remarks', cs.Remarks__c);
                    }
                    else{
                        gen.writeStringField('Remarks', '');
                    }
                    if(cs.Waybill_Numbers__c != null){                            
                        gen.writeStringField('WaybillNo', cs.Waybill_Numbers__c);
                    }
                    else{
                        gen.writeStringField('WaybillNo', '');
                    }
                    if(cs.Id != null){
                        gen.writeStringField('SFId', cs.Id);
                    }
                    else{
                        gen.writeStringField('SFId', '');
                    }
                    gen.writeEndObject();
                }
                gen.writeEndArray();
                //end of the parent JSON object
                gen.writeEndObject();
                String jsonString = gen.getAsString();                                
                String CaseEndPoint = System.Label.Case_Api;
                Http http2 = new Http();        
                HttpRequest request2 = new HttpRequest();
                request2.setEndpoint(CaseEndPoint);
                request2.setMethod('POST');
                request2.setHeader('Content-Type','application/json;charset=UTF-8');
                request2.setHeader('Authorization','bearer '+token);
                request2.setTimeout(30000);
                request2.setbody(jsonString);        
                HttpResponse response2 = http2.send(request2);
                // Parse the JSON response
                if (response2.getStatusCode() != 200) {
                    System.debug('The status code returned was not expected: ' +
                                 response2.getStatusCode() + ' ' + response2.getStatus());                    
                    
                    JSONParser parser = JSON.createParser(response2.getBody());
                    
                } else {
                    map<String,Id> mapId = new map<String,Id>();                    
                    List<jsonParser3> lstJp = (List<jsonParser3>) System.JSON.deserialize(response2.getBody(),List<jsonParser3>.class);                    
                    for(jsonParser3 jp3 : lstJp){
                        if(jp3.SFId != null && jp3.TokenNo != null && jp3.Status.equals('Success')){
                            mapCases.get(jp3.SFId).Proton_Token_No__c = jp3.TokenNo;
                            mapCases.get(jp3.SFId).Integration_Error_Message__c = '';
                        }
                        else if(jp3.Status != 'Success'){
                            mapCases.get(jp3.SFId).Integration_Error_Message__c = jp3.Message[0];
                        }
                    }
                    }
                if(!mapCases.isEmpty()){
                    List<case__c> updateCase = mapCases.values();
                    update updateCase;
                }
                }                                
                }
            
        }catch(Exception e){  // Added by shubham Girdhar reffering jira ticket: SD-417  
            system.debug('Exception:'+e.getMessage());
           String name = 'Case';
            String ClassName = 'CasePushAPI';
            ExceptionHandling.Exception( name, ClassName, e);            
        
}
    }
    
    //JSONParser 1
    public class jsonParser2{
        public String access_token;
        public String token_type;
        public String expires_in;
        
    }
    
    //JSONParser 2
    public class jsonParser3{
        public String TokenNo;
        public String Status;
        public String[] Message;
        public Id SFId;        
    }
}