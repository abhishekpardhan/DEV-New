/**
 * Description		:	Class to send the Journey__c record which were modified yesterday to third party system by hitting thier apis
 * 
 * Revision Logs	:	V_1.0 - Created
 * 
 **/
public class ExpenseDataPush implements schedulable{
    
    //Execute method of schedulable interface to schedule the class at specific time
    public void execute(SchedulableContext sc)
    {
        sendExpense();
    }
    
    /**
     * Method to send the Journey__c record which were modified yesterday to third party system by hitting thier apis
     **/
    public static void sendExpense()
    {
        String token;
        try
        {
            
            List<Journey__c> expenseList = new List<Journey__c>();
            if(Test.isRunningTest()) {
                
                expenseList = [Select Id, Name,  CreatedBy.Name,  LastModifiedBy.Name,  Owner.Name,  Actual_Amount__c,  Actual_KM__c,  
                                    CheckIn_Date__c, CheckIn_Location__c, CheckOut_Date__c, CheckOut_Location__c, Final_Amount__c, 
                                    Journey_Amount__c, Journey_KM__c, Manual_Expense_Amount__c
                                    from Journey__c where lastmodifieddate = today ]; //limit 1 
            }
            else {
                expenseList = [Select Id, Name,  CreatedBy.Name,  LastModifiedBy.Name,  Owner.Name,  Actual_Amount__c,  Actual_KM__c,  
                                                CheckIn_Date__c, CheckIn_Location__c, CheckOut_Date__c, CheckOut_Location__c, Final_Amount__c, 
                                                Journey_Amount__c, Journey_KM__c, Manual_Expense_Amount__c
                                                from Journey__c where lastmodifieddate = Yesterday ]; //limit 1 
                
            }
            if(expenseList.size() > 0 )
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
                    gen.writeFieldName('ExpenseMgr');
                    gen.writeStartArray();
                    string tempStr;
                    for(Journey__c jr : expenseList )
                    {
                        gen.writeStartObject();
                        gen.writeStringField('Name', jr.Name); 
                        gen.writeStringField('CreatedBy', jr.CreatedBy.Name);
                        gen.writeStringField('LastModifiedBy', jr.LastModifiedBy.Name);
                        gen.writeStringField('Owner', jr.Owner.Name); 
                         
                        tempStr = jr.Actual_Amount__c != null ? string.valueOf(jr.Actual_Amount__c): '' ;   
                        gen.writeStringField('Actual_Amount__c', tempStr);
                        
                        tempStr = jr.Actual_KM__c != null ? string.valueOf(jr.Actual_KM__c): '' ;   
                        gen.writeStringField('Actual_KM__c', tempStr);
                        
                        tempStr = jr.CheckIn_Date__c != null ? jr.CheckIn_Date__c.format('dd/MM/yyyy HH:mm:ss'): '' ;   
                        gen.writeStringField('CheckIn_Date__c', tempStr);
                        
                        tempStr = string.isNotBlank(jr.CheckIn_Location__c) ? string.valueOf(jr.CheckIn_Location__c): '' ;  
                        gen.writeStringField('CheckIn_Location__c', tempStr);
                        
                        tempStr = jr.CheckOut_Date__c != null ? jr.CheckOut_Date__c.format('dd/MM/yyyy HH:mm:ss'): '' ; 
                        gen.writeStringField('CheckOut_Date__c', tempStr);
                        
                        tempStr = string.isNotBlank(jr.CheckOut_Location__c) ? string.valueOf(jr.CheckOut_Location__c): '' ;    
                        gen.writeStringField('CheckOut_Location__c', tempStr);
                        
                        tempStr = jr.Final_Amount__c != null ? string.valueOf(jr.Final_Amount__c) : '' ;    
                        gen.writeStringField('Final_Amount__c', tempStr);
                        
                        tempStr = jr.Journey_Amount__c != null ? string.valueOf(jr.Journey_Amount__c) : '' ;    
                        gen.writeStringField('Journey_Amount__c', tempStr);
                        
                        tempStr = jr.Journey_KM__c != null ? string.valueOf(jr.Journey_KM__c) : '' ;    
                        gen.writeStringField('Journey_KM__c', tempStr);
                        
                        tempStr = jr.Manual_Expense_Amount__c != null ? string.valueOf(jr.Manual_Expense_Amount__c) : '' ;  
                        gen.writeStringField('Manual_Expense_Amount__c', tempStr);
                        
                        gen.writeEndObject();
                    }
                    gen.writeEndArray();
                    gen.writeEndObject();
                    String jsonString = gen.getAsString();                                
                    system.debug('jsonString++'+jsonString); 
                    
                    String expenseAPIEndPoint = System.Label.ExpenseAPI;
                    Http http2 = new Http();        
                    HttpRequest request2 = new HttpRequest();
                    request2.setEndpoint(expenseAPIEndPoint);
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
    
    //Wrapper class
    public class jsonParser2{
        public String access_token;
        public String token_type;
        public String expires_in;
        
    }
    
}