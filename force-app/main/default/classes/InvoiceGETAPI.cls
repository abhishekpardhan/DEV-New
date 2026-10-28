public class InvoiceGETAPI implements Schedulable{
    
     //Executing method of schedulable interface to schedule the class at specific time
     public void execute(SchedulableContext sc) {
        InvoiceGETAPI cs = new InvoiceGETAPI();
        InvoiceGETAPI.caseFromPropel();       
     }
        /**
     * Method to get the 'Invoice' records from third party api
     **/
    	@future(callout=true)
        public static void caseFromPropel(){
            String token;
            List<Invoice__c> lstInvoice = new List<Invoice__c>();
            String Endpoint = System.Label.Case_Authentication_Api;
 			String ClientId = System.Label.Client_Id;
            String ClientSecret = System.Label.Client_Secret;
            String Granttype = System.Label.grant_type;
            
            String Endpoint2 = 'http://proton.safexpress.com/SaleForceApi/SaleForce/Api/getInvDetails?from_dt=';
            Datetime myDatetime = Datetime.now() - 1;
			String myDatetimeStr = myDatetime.format('dd-MMM-yyyy');
            Integer frm = 1;
            Integer to = 1000;
            
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
                jsonParser1 jp = (jsonParser1)JSON.deserializeStrict(response.getBody(),jsonParser1.class); 
           			System.debug('jb'+jp);
                if(jp.access_token != null){
                    token = jp.access_token;
                    system.debug('Access Token: ' +token);
                }}
                if(token != null){
                Http http2 = new Http();        
                HttpRequest request2 = new HttpRequest();
                request2.setEndpoint(Endpoint2+myDatetimeStr+'&to_dt='+myDatetimeStr+'&inv_no=&from='+frm+'&to='+to);
                request2.setMethod('GET');
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
             JSONParser2 Jp2 = (JSONParser2) System.JSON.deserialize(response2.getBody(),JSONParser2.class); 
             system.debug('Count: ' +Jp2.Count);
             if(Jp2.Count <= 1000){
            	//Integer NumberOfLoop = Math.round((Jp2.Count / 1000)) +1;
            	
                System.debug('@@@@@@@@@@ in forr loop');
                for(JSONParser3 Jp3 : Jp2.value){
                    String fromdate = Jp3.bill_fr_dt;
                    system.debug(' before Parsed Date is ' + fromdate);
   					Date fromdt = Date.parse(fromdate);
    				system.debug('after Parsed Date is ' + fromdt);
                    //Parse to date:
                    String todate = Jp3.bill_to_dt;
                    system.debug(' before Parsed Date is ' + todate);
   					Date todt = Date.parse(todate);
    				system.debug('after Parsed Date is ' + todt);
                    //Parse bill_due_dt:
                    String duedate = Jp3.bill_to_dt;
                    system.debug(' before Parsed Date is ' + duedate);
   					Date duedt = Date.parse(duedate);
    				system.debug('after Parsed Date is ' + duedt);
                    //Parse bill_dt:
                    String billdate = Jp3.bill_dt;
                    system.debug(' before Parsed Date is ' + billdate);
   					Date billdt = Date.parse(billdate);
    				system.debug('after Parsed Date is ' + billdt);
                    //Parse submission_date:
                    String subdate = Jp3.submission_date;
                    system.debug(' before Parsed Date is ' + subdate);
   					Date subdt = Date.parse(subdate);
    				system.debug('after Parsed Date is ' + subdt);
                    
                Invoice__c newinvoice = new Invoice__c(Name = Jp3.bill_no,
                                                      Propel_ID__c = Jp3.Id,
                                                      Bill_Number__c = Jp3.bill_no,
                                                      Description__c = Jp3.descr,
                                                      Customer_Contract_ID__c = Jp3.cust_cntr_id,	
                                                      Customer_Contract_Code__c = Jp3.cust_cntr_cd,
                                                      Charged_Freight_Amount__c = Jp3.bill_chgd_frt_amt,
                                                      Charged_ST_Amount__c = Jp3.bill_chgd_st_amt,
                                     				  Charged_Total_Amount__c = Jp3.bill_chgd_tot_amt,
                                     				  Out_Oct_Amount__c = Jp3.bill_out_oct_amt,
                                     				  Out_Total_Amount__c = Jp3.bill_out_tot_amt,
                                                      Status_LID__c = Jp3.Status_LID,                                     
                                                      Bill_Type_Flag__c = Jp3.Bill_Type_Flag,
                                                      Bill_From_Date__c = fromdt,
                                                      Bill_To_Date__c = todt,
                                                      Bill_Due_Date__c = duedt,
                                                      Submission_Date__c = subdt, 
                                                      Account__r = new Account(Composite_Key__c = Jp3.cust_cntr_cd + '-' + String.valueOf(Jp3.bill_br_id))
                                                      ); 
                     system.debug('Propel Id :' +Jp3.Id);
                     lstInvoice.add(newinvoice);
                     system.debug('lstInvoice :' +lstInvoice);
                 }
                     system.debug('lstInvoice size :' +lstInvoice.size());
            //insert lstInvoice[0];
            system.debug('lstInvoice[0] :' +lstInvoice[0]);
            Database.UpsertResult[] results = Database.upsert(lstInvoice, Invoice__c.Fields.Propel_ID__c, false);
            }
            else{
                system.debug('Invoice count more than 1000'); 
                integer NumberOfLoop = Integer.valueof(Jp2.Count / 1000 +1);
                system.debug('NumberOfLoop' +NumberOfLoop);
                for(integer i = 1; i<=NumberOfLoop; i++){
                Http http3 = new Http();        
                HttpRequest request3 = new HttpRequest();
                request3.setEndpoint(Endpoint2+myDatetimeStr+'&to_dt='+myDatetimeStr+'&inv_no=&from='+frm+'&to='+to);
                request3.setMethod('GET');
                request3.setHeader('Authorization','bearer '+token);
                request3.setTimeout(30000); 
                HttpResponse response3 = http2.send(request3); 
                system.debug('response3' +response3);
                system.debug('response3 status code' +response3.getStatusCode());
                system.debug('response3 body' +response3.getBody());
                    // Parse the JSON response
                if (response2.getStatusCode() != 200) {
                    System.debug('The status code returned was not expected: ' +
                    response2.getStatusCode() + ' ' + response2.getStatus());                    
                    
                    JSONParser parser = JSON.createParser(response2.getBody());
                    
                }
        else { 
             JSONParser2 Jp4 = (JSONParser2) System.JSON.deserialize(response2.getBody(),JSONParser2.class);                    
            	
                System.debug('@@@@@@@@@@ in forr loop');
                System.debug('Response: ' +response2.getBody());
            
                for(JSONParser3 Jp5 : Jp4.value){
                    Date subdt;
                    String fromdate = Jp5.bill_fr_dt;
                    system.debug(' before Parsed Date is ' + fromdate);
   					Date fromdt = Date.parse(fromdate);
    				system.debug('after Parsed Date is ' + fromdt);
                    //Parse to date:
                    String todate = Jp5.bill_to_dt;
                    system.debug(' before Parsed Date is ' + todate);
   					Date todt = Date.parse(todate);
    				system.debug('after Parsed Date is ' + todt);
                    //Parse bill_due_dt:
                    String duedate = Jp5.bill_to_dt;
                    system.debug(' before Parsed Date is ' + duedate);
   					Date duedt = Date.parse(duedate);
    				system.debug('after Parsed Date is ' + duedt);
                    //Parse bill_dt:
                    String billdate = Jp5.bill_dt;
                    system.debug(' before Parsed Date is ' + billdate);
   					Date billdt = Date.parse(billdate);
    				system.debug('after Parsed Date is ' + billdt);
                    //Parse submission_date:
                   // if(Jp5.submission_date != null){
                   // String subdate = Jp5.submission_date;
                   // system.debug(' before Parsed Date is ' + subdate);
   					//subdt = Date.parse(subdate);
    				//system.debug('after Parsed Date is ' + subdt);
                   // }
                    
                Invoice__c newinvoice = new Invoice__c(Name = Jp5.bill_no,
                                                      Propel_ID__c = Jp5.Id,
                                                      Bill_Number__c = Jp5.bill_no,
                                                      Description__c = Jp5.descr,
                                                      Customer_Contract_ID__c = Jp5.cust_cntr_id,	
                                                      Customer_Contract_Code__c = Jp5.cust_cntr_cd,
                                                      Charged_Freight_Amount__c = Jp5.bill_chgd_frt_amt,
                                                      Charged_ST_Amount__c = Jp5.bill_chgd_st_amt,
                                     				  Charged_Total_Amount__c = Jp5.bill_chgd_tot_amt,
                                     				  Out_Oct_Amount__c = Jp5.bill_out_oct_amt,
                                     				  Out_Total_Amount__c = Jp5.bill_out_tot_amt,
                                                      Status_LID__c = Jp5.Status_LID,                                     
                                                      Bill_Type_Flag__c = Jp5.Bill_Type_Flag,
                                                      Bill_From_Date__c = fromdt,
                                                      Bill_To_Date__c = todt,
                                                      Bill_Due_Date__c = duedt,
                                                      //Submission_Date__c = subdt, 
                                                      Account__r = new Account(Composite_Key__c = Jp5.cust_cntr_cd + '-' + String.valueOf(Jp5.bill_br_id))
                                                      ); 
                     system.debug('Propel Id :' +Jp5.Id);
                     lstInvoice.add(newinvoice);
                     system.debug('lstInvoice :' +lstInvoice);
                 }
                }
                }
			}
            Database.UpsertResult[] results = Database.upsert(lstInvoice, Invoice__c.Fields.Propel_ID__c, false); 
            system.debug('results :' +results);
            

			}
            }            
            }
        //JSONParser 1
        public class jsonParser1{
        public String access_token;
        public String token_type;
        public String expires_in;
        }
        //JSONParser 2
    	public class JSONParser2{
    	public Integer count;
        public List<JSONParser3> value;
		}
  		public class JSONParser3 {
        public Integer rownum;
        public Integer id;
        public String bill_dt;
        public String bill_no;
        public String descr;
        public Integer cust_cntr_id;
        public String cust_cntr_cd;
        public String bill_br_id;
        public String sub_br_mast_id;
        public String coll_br_id;
        public String bill_fr_dt;
        public String bill_to_dt;
        public String bill_due_dt;
        public Decimal bill_chgd_frt_amt;
        public Decimal bill_chgd_st_amt;
        public Decimal bill_chgd_tot_amt;
        public Decimal bill_out_oct_amt;
        public Decimal bill_out_tot_amt;
        public Integer status_lid;
        public String submission_date;
        public String to_person;
        public String rmks;
        public String bill_type_flag;
    	}
      private class JsonUpsertResult {
       List<Database.Error> Errors;
       String SFId;
       Decimal propelId;
       Boolean isCreated;
       Boolean isSuccess;
  }
        }