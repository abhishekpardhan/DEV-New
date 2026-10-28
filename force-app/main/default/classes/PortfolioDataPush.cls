//Class to send the Account_Team__c records which were modified yesterday to third party by hitting thier endpoints
public class PortfolioDataPush  implements schedulable {
	
    //Execute method of schedulable interface to schedule the class at specific time
    public void execute(SchedulableContext sc)
    {
        sendAccountTeam();
    }
    
    //Method to send the Account Team records to third party
    public static void sendAccountTeam(){
        
        String token;        
        try{
            
            map<Id,Account_team__c> mapAccountTeam = new map<Id,Account_team__c>();
            
            if(Test.isRunningTest()) {
                
                mapAccountTeam = new map<Id,Account_team__c>([select id,name,createdbyid,lastmodifiedbyid,Account__r.name,account__r.sfx_code__c,
                                                              account__r.booking_branch__r.name,account__r.booking_branch__r.Branch_ID__c,account__r.collection_branch__r.name,
                                                              account__r.collection_branch__r.Branch_ID__c,account__r.submission_branch__r.name,
                                                              account__r.submission_branch__r.Branch_ID__c,bdm__r.name,bdm__r.ad_id__c,collection__c,crs__c,national1__c,national2__c,
                                                              national3__c,national4__c,relationship__c,submission__c,nsm__c from account_team__c where lastmodifieddate = today]);
                
            }else {
                mapAccountTeam = new map<Id,Account_team__c>([select id,name,createdbyid,lastmodifiedbyid,Account__r.name,account__r.sfx_code__c,
                                                              account__r.booking_branch__r.name,account__r.booking_branch__r.Branch_ID__c,account__r.collection_branch__r.name,
                                                              account__r.collection_branch__r.Branch_ID__c,account__r.submission_branch__r.name,
                                                              account__r.submission_branch__r.Branch_ID__c,bdm__r.name,bdm__r.ad_id__c,collection__c,crs__c,national1__c,national2__c,
                                                              national3__c,national4__c,relationship__c,submission__c,nsm__c from account_team__c where lastmodifieddate = Yesterday]);
            }
            
            
            if(!mapAccountTeam.isEmpty()){
            String Endpoint = System.Label.Case_Authentication_Api;
            String ClientId = System.Label.Client_Id;
            String ClientSecret = System.Label.Client_Secret;
            String Granttype = System.Label.grant_type;
            Http http = new Http();        
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Endpoint);
            //request.setEndpoint('http://proton.safexpress.com/SaleForceTestApi/token');
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
		
            if(token != null){
                
                system.debug('mapAccountTeam++'+mapAccountTeam.size());                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeFieldName('portfolioMgs');
                gen.writeStartArray();
                for(Account_team__c at: mapAccountTeam.values()){
                    gen.writeStartObject();
                    if(at.name != null){
                        gen.writeStringField('AccountName', at.account__r.name);            
                    }
                    else{
                        gen.writeStringField('AccountName', '');
                    }
                    if(at.account__r.sfx_code__c != null){
                        gen.writeStringField('SFXCode', at.account__r.sfx_code__c);            
                    }
                    else{
                        gen.writeStringField('SFXCode', '');
                    }
                    if(at.account__r.booking_branch__r.name != null){
                        gen.writeStringField('BookingBranch', at.account__r.booking_branch__r.name);            
                    }
                    else{
                        gen.writeStringField('BookingBranch', '');
                    }
                    if(at.account__r.booking_branch__r.branch_id__c != null){
                        gen.writeNumberField('BookingBranchID', at.account__r.booking_branch__r.branch_id__c);
                    }
                    else{
                        gen.writeStringField('BookingBranchID', '');
                    }
                    if(at.account__r.collection_branch__r.name != null){
                        gen.writeStringField('CollectionBranch', at.account__r.collection_branch__r.name);            
                    }
                    else{
                        gen.writeStringField('CollectionBranch', '');
                    }
                    if(at.account__r.collection_branch__r.branch_id__c != null){
                        gen.writeNumberField('CollectionBranchID', at.account__r.collection_branch__r.branch_id__c);
                    }
                    else{
                        gen.writeStringField('CollectionBranchID', '');
                    }
                    if(at.account__r.submission_branch__r.name != null){
                        gen.writeStringField('SubmissionBranch', at.account__r.submission_branch__r.name);            
                    }
                    else{
                        gen.writeStringField('SubmissionBranch', '');
                    }
                    if(at.account__r.submission_branch__r.branch_id__c != null){
                        gen.writeNumberField('SubmissionBranchID', at.account__r.submission_branch__r.branch_id__c);
                    }
                    else{
                        gen.writeStringField('SubmissionBranchID', '');
                    }
                    if(at.createdbyid != null){
                        gen.writeStringField('CreatedById', at.createdbyid);
                    }
                    else{
                        gen.writeStringField('CreatedById', '');
                    }
                    if(at.lastmodifiedbyid != null){
                        gen.writeStringField('LastModifiedById', at.lastmodifiedbyid);
                    }
                    else{
                        gen.writeStringField('LastModifiedById', '');
                    }
                    if(at.account__c != null){
                        gen.writeStringField('Name', at.name);
                    }
                    else{
                        gen.writeStringField('Name', '');
                    }
                    if(at.bdm__c != null){
                        gen.writeStringField('BDM', at.bdm__r.name);
                    }
                    else{
                        gen.writeStringField('BDM', '');
                    }
                    if(at.bdm__r.ad_id__c != null){
                        gen.writeStringField('ADId', at.bdm__r.ad_id__c);
                    }
                    else{
                        gen.writeStringField('ADId', '');
                    }
                        gen.writeBooleanField('Collection', at.collection__c);
                    
                        gen.writeBooleanField('CRS', at.crs__c);

                        gen.writeBooleanField('National1', at.National1__c);

                        gen.writeBooleanField('National2', at.National2__c);
 
                        gen.writeBooleanField('National3', at.National3__c);
 
                        gen.writeBooleanField('National4', at.National4__c);
 
                        gen.writeBooleanField('Relationship', at.relationship__c);
                        
                    	gen.writeBooleanField('Submission', at.submission__c);
 
                        gen.writeBooleanField('NSM', at.nsm__c);
                     
                    gen.writeEndObject();
                }
                gen.writeEndArray();
                //end of the parent JSON object
                gen.writeEndObject();
                String jsonString = gen.getAsString();                                
                system.debug('jsonString++'+jsonString);
                String PortfolioAPI = System.Label.Portfolio_API;
                Http http2 = new Http();        
                HttpRequest request2 = new HttpRequest();
                request2.setEndpoint(PortfolioAPI);
                request2.setMethod('POST');
                request2.setHeader('Content-Type','application/json;charset=UTF-8');
                request2.setHeader('Authorization','bearer '+token);
                request2.setTimeout(30000);
                request2.setbody(jsonString);        
                HttpResponse response2 = http2.send(request2);
                system.debug('response2++'+response2);
                system.debug('response2body++'+response2.getBody());
            }
        }
    
}
        catch(Exception e){
            
        }
    }
    
    public class jsonParser2{
        public String access_token;
        public String token_type;
        public String expires_in;
        
    }
}