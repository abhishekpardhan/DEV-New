/**
 * Description      :   Class to send the 'Campaign__c' object records to third party API System (proton)
 *  
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
public class CampaignDataPush implements schedulable {
    
    //Executing method of schedulable interface to schedule the class at specific time
    public void execute(SchedulableContext sc)
    {
        sendCampaign();
    }
    
    /**
     * Method to send the campaign to third party API
     **/
    public static void sendCampaign()
    {
        String token;
        try
        {
            List<Campaign__c> campaignList = [Select Id, Name,  CreatedBy.Name,  LastModifiedBy.Name,  Owner.Name,  Actual_Amount__c,  Address__c,  
                                    Budgeted_Amount__c, City__c, Country__c, End_Date__c, Valid_Upto_for_Lead_Generation__c, 
                                    Pin_Code__c, Region__c, Start_Date__c, State__c, Status__c, CreatedDate
                                    from Campaign__c limit 5 ]; //limit 1  
                                    
            if(campaignList.size() > 0 )
            {
                String Endpoint = System.Label.Case_Authentication_Api;
                String ClientId = System.Label.Client_Id;
                String ClientSecret = System.Label.Client_Secret_AccountTeam;
                String Granttype = System.Label.grant_type;
                Http http = new Http();        
                HttpRequest request = new HttpRequest();
                request.setEndpoint(Endpoint);
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                request.setTimeout(30000);
                String body = 'client_id='+ClientId+'&client_secret='+ClientSecret+'&grant_type='+Granttype;
                request.setbody(body);        
                HttpResponse response = http.send(request);
                
                if (response.getStatusCode() != 200) {
                    System.debug('The status code returned was not expected: ' +
                                 response.getStatusCode() + ' ' + response.getStatus());                
                    
                    JSONParser parser = JSON.createParser(response.getBody());
                    // Advance to the next token.
                    while (parser.nextToken() != null) {
                        if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                            (parser.getText() == 'error_description')) {                            
                                parser.nextToken();
                                system.debug('parser.getText()--'+parser.getText());
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
                
                if(token != null)
                {
                    JSONGenerator gen = JSON.createGenerator(false);
                    gen.writeStartObject();
                    gen.writeFieldName('CampaignMgr');
                    gen.writeStartArray();
                    string tempStr;
                    for(Campaign__c cmp : campaignList )
                    {
                        gen.writeStartObject();
                        gen.writeStringField('Name', cmp.Name); 
                        gen.writeStringField('CreatedBy', cmp.CreatedBy.Name);
                        gen.writeStringField('LastModifiedBy', cmp.LastModifiedBy.Name);
                        gen.writeStringField('Owner', cmp.Owner.Name); 
                         
                        tempStr = cmp.Actual_Amount__c != null ? string.valueOf(cmp.Actual_Amount__c): '' ; 
                        gen.writeStringField('Actual_Amount__c', tempStr);
                        
                        tempStr = string.isNotBlank(cmp.Address__c) ? string.valueOf(cmp.Address__c): '' ;  
                        gen.writeStringField('Address__c', tempStr);
                        
                        tempStr = cmp.Budgeted_Amount__c != null ? string.valueOf(cmp.Budgeted_Amount__c): '' ; 
                        gen.writeStringField('Budgeted_Amount__c', tempStr);
                        
                        tempStr = string.isNotBlank(cmp.City__c) ? string.valueOf(cmp.City__c): '' ;    
                        gen.writeStringField('City__c', tempStr);
                        
                        tempStr = string.isNotBlank(cmp.Country__c) ? string.valueOf(cmp.Country__c): '' ;  
                        gen.writeStringField('Country__c', tempStr);
                        
                        DateTime dt;
                        if(cmp.End_Date__c != null)
                        {
                            Date d = cmp.End_Date__c;
                            dt = DateTime.newInstanceGMT(d.year(), d.month(), d.day());
                        } 
                        tempStr = dt != null ? dt.format('d MMM yyyy'): '' ;    //dd/MM/yyyy HH:mm:ss 
                        gen.writeStringField('End_Date__c', tempStr);
                        
                        dt=null;
                        if(cmp.Valid_Upto_for_Lead_Generation__c != null)
                        {
                            Date d = cmp.Valid_Upto_for_Lead_Generation__c;
                            dt = DateTime.newInstanceGMT(d.year(), d.month(), d.day());
                        } 
                        
                        tempStr = dt != null ? dt.format('d MMM yyyy'): '' ;    //dd/MM/yyyy HH:mm:ss 
                        gen.writeStringField('Expire_On__c', tempStr);
                        
                        tempStr = string.isNotBlank(cmp.Pin_Code__c) ? string.valueOf(cmp.Pin_Code__c): '' ;    
                        gen.writeStringField('Pin_Code__c', tempStr);
                        
                        tempStr = string.isNotBlank(cmp.Region__c) ? string.valueOf(cmp.Region__c): '' ;    
                        gen.writeStringField('Region__c', tempStr);
                        
                        dt = null;
                        if(cmp.Start_Date__c != null)
                        {
                            Date d = cmp.Start_Date__c;
                            dt = DateTime.newInstanceGMT(d.year(), d.month(), d.day());
                        } 
                        
                        tempStr = dt != null ? dt.format('d MMM yyyy'): '' ;    //dd/MM/yyyy HH:mm:ss 
                        gen.writeStringField('Start_Date__c', tempStr);
                        
                        tempStr = string.isNotBlank(cmp.State__c) ? string.valueOf(cmp.State__c): '' ;  
                        gen.writeStringField('State__c', tempStr);
                        
                        tempStr = string.isNotBlank(cmp.Status__c) ? string.valueOf(cmp.Status__c): '' ;    
                        gen.writeStringField('Status__c', tempStr);
                        
                        gen.writeStringField('CrDt', cmp.CreatedDate.format('d MMM yyyy')); 
                        
                        gen.writeEndObject();
                    }
                    gen.writeEndArray();
                    gen.writeEndObject();
                    String jsonString = gen.getAsString();                                
                    system.debug('jsonString++'+jsonString); 
                    
                    String campaignAPIEndPoint = System.Label.CampaignAPIEndpoint;
                    Http http2 = new Http();        
                    HttpRequest request2 = new HttpRequest();
                    request2.setEndpoint(campaignAPIEndPoint);
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
        } catch(Exception e)
        {
            system.debug('Exception--'+e.getMessage());
        }
                                
    }
    
    //JSON Parser class
    public class jsonParser2{
        public String access_token;
        public String token_type;
        public String expires_in;
        
    }
}