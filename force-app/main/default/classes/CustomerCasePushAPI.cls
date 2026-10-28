/**
 * Description		:		Class to send the 'Case__c' object records (Customer Technology/IT request Cases) to JIRA
 * Created By       :       Monika Rawat
 * Created Date     :       19th Feb, 2020
 * Release          :       
 * Last Modified on :       
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-538
 **/

public class CustomerCasePushAPI {   
    public static  boolean firstRun = true;
    //Method to send the 'Case__c' records to JIRA
        @future(callout=true)
    public static void caseFromSF(ID cseId){
         Case__c cse = [select name, Account__r.name, Assigned_To__c, Customer_Case_Type__c, JIRA_Ticket__c, Case_Sub_Type__c, Assigned_To__r.name from Case__c where id =:cseId AND JIRA_Ticket__c = NULL]; 		
        JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeFieldName('fields');
                gen.writeStartObject();
                gen.writeFieldName('project');
                gen.writeStartObject();
                gen.writeStringField('key', 'CUS'); 
                gen.writeEndObject();
                if(cse.Account__r.name != null){
                gen.writeStringField('summary', cse.Name + '-' + cse.Account__r.name);
                    }
                gen.writeFieldName('issuetype');
                gen.writeStartObject();
                gen.writeStringField('name', 'Task');
                        gen.writeEndObject();
                    if(cse.Customer_Case_Type__c != null){
                gen.writeFieldName('customfield_10131');
                gen.writeStartObject();
                gen.writeStringField('value', cse.Customer_Case_Type__c);
                        gen.writeEndObject();
                    }
                  if(cse.Case_Sub_Type__c != null){
                gen.writeStringField('customfield_10166', cse.Case_Sub_Type__c);
                    }
                gen.writeFieldName('assignee');
                gen.writeStartObject();
                gen.writeStringField('id', '5ca5a592e623ae19ec54eeb6');
                        gen.writeEndObject();
        
                        gen.writeEndObject();
    
            String jsonString = gen.getAsString();
            system.debug('jsonString: '+jsonString);
        //	String Endpoint = 'https://safexpress.atlassian.net/rest/api/2/issue/';
        String Endpoint = System.Label.Jira_Endpoint;
        //    String Username1 = 'jira.integration@safexpress.com'; 
        //    String Password1 = 'vsPQOqG6MKuBdQswLJ1A1A3C';
           String Username1 = System.Label.Jira_Username; 
            String Password1 = System.Label.Jira_Password;
            Http http = new Http();        
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Endpoint);
            request.setMethod('POST');
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setbody(jsonString);        
        	Blob headerValue = Blob.valueOf(Username1 + ':' + Password1);
        	system.debug('headerValue: ' +headerValue);
			String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            system.debug('authorizationHeader: ' +authorizationHeader);
			request.setHeader('Authorization', authorizationHeader);
            request.setTimeout(30000);
            HttpResponse response = http.send(request); 
                system.debug('request: ' +request);
                system.debug('response: ' +response);
           
       jsonParser Jp = (jsonParser) System.JSON.deserialize(response.getBody(),jsonParser.class);                    
                system.debug('Jp: ' +Jp);     
                system.debug('Issue id: '+Jp.id); 
                system.debug('Issue Key: '+Jp.key); 
                system.debug('Issue link: '+Jp.self); 
        cse.JIRA_Ticket__c = Jp.key;
        update cse; 
    	    }
    
    //JSONParser
    public class jsonParser{
        public String id;
        public String key;
        public String self;
    }
}