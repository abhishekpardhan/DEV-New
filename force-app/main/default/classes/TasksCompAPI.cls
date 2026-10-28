public class TasksCompAPI implements Schedulable{   
    
    //Executing method of schedulable interface to schedule the class at specific time
     public void execute(SchedulableContext sc) {
        TasksCompAPI cs = new TasksCompAPI();
        TasksCompAPI.taskFromSF();       
     }
    
    /**
     * Method to update the 'submission tasks' records in third party api
     **/
    @future(callout=true)
    public static void taskFromSF(){
        system.debug('API method called');
        String token;        
        try{
            Id rIdSub = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
            list<Task> lstTasks = new list<Task>([select id,Whatid,What.Name,Owner.name,submitted_to__r.name,Submitted_Date__c from task where recordtypeid=:rIdSub and Status = 'Completed' and Propel_task_status__c != 'success' LIMIT 100 ]); //and lastmodifieddate > yesterday            
            system.debug('mapTasks' +lstTasks);
            list<Task> updatedtasks = new list<Task>();
            if(!lstTasks.isEmpty()){                            
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
                map<Id,String> mapTaskIdTokenNo = new map<Id,String>();                                
                JSONGenerator gen = JSON.createGenerator(true);
              //  gen.writeStartObject();
              //  gen.writeFieldName('Task');
                gen.writeStartArray();
                for(task cs: lstTasks){
                    gen.writeStartObject();
                    if(cs.submitted_to__r.name != null){
                    gen.writeStringField('TO_PERSON', cs.submitted_to__r.name);            
                    }
                    else{
                        gen.writeStringField('TO_PERSON', '');
                    }
                    if(cs.what.name != null){
                        gen.writeStringField('BILL_NO', cs.what.name);
                    }
                    else{
                        gen.writeStringField('BILL_NO', '');
                    }
                    if(cs.Submitted_Date__c  != null){
                      // Datetime dt = (Datetime)Account.Start_Date__c; 
					  // Date d = dt.format('MM/dd/yyyy');
                       gen.writeDateField('SUBMISSION_DT', cs.Submitted_Date__c);
                    }
                    else{
                       gen.writeDateField('SUBMISSION_DT',null);
                    }
                    if(cs.Owner.Name  != null){
                      //  String Ownn = [Select AD_Id__c from user where name =: cs.Owner.Name];
                      //  String own = cs.Owner.Name.right(5);
                        List<String> updated_user_id=cs.Owner.Name.split('-');
                        if(updated_user_id.size()>1){
                      gen.writeStringField('UPD_BY',updated_user_id[1]);
                        }
                    }
                    else{
                      gen.writeStringField('UPD_BY','');
                    }                  
                    gen.writeEndObject();
                }
                gen.writeEndArray();
                //end of the parent JSON object
             //   gen.writeEndObject();
                String jsonString = gen.getAsString();  
                system.debug('gen: ' +gen);
                system.debug('jsonString: ' +jsonString);
                String TaskEndPoint = System.Label.Propel_SubmissionTasks;
                Http http2 = new Http();        
                HttpRequest request2 = new HttpRequest();
                request2.setEndpoint(TaskEndPoint);
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
                    system.debug('response2.getBody()' +response2.getBody());
                    system.debug('lstJp' +lstJp);
                    for(jsonParser3 jp3 : lstJp){
                        system.debug('inside for loop');
                        if(jp3.Status.equals('success') && jp3.TokenNo !=null){
                            system.debug('jp3.status' +jp3.Status);
                            //Invoice__c inv = new invoice__c();
                            for(task tt :lstTasks){
                                if(tt.what.name == jp3.TokenNo){
                                    tt.Propel_task_status__c = jp3.Status;
                                    tt.Comments_Added__c = 'Updated by Propel';
                                    system.debug('tt.Propel_task_status__c' +tt.Propel_task_status__c);
                                updatedtasks.add(tt);
                                            system.debug('updated taks' +updatedtasks);

                                }
                            }
                        }
                    }
                    
                  }
                
                update updatedtasks;
            }
               // if(!mapTasks.isEmpty()){
               //     List<Task> updateTask = mapTasks.values();
               //     update updateTask;
              //  }
                  
            }
            
        }catch(Exception e){  // Added by shubham Girdhar reffering jira ticket: SD-417  
            system.debug('Exception:'+e.getMessage());
           String name = 'Task';
            String ClassName = 'TasksCompAPI';
            ExceptionHandling.Exception(name, ClassName, e);            
        
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