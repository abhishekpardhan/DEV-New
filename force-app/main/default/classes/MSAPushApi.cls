public class MSAPushApi
{
    public static boolean firstCheck = true;
    public static void MSAFromSF(id objId, String Endpoint)
    {
		MSAFromSF(objId, Endpoint, null);        
    }
    @future(callout=true)
    public static void MSAFromSF(id objId, String Endpoint, String itRecordId)
    {
        try
        {
            Opportunity__c opp = [select Id, Name, X3PL_Potential__c,
                                  AccId__c,Billing_Street__c,Billing_City__c,
                                  Billing_Country__c,Billing_Zip_Postal_Code__c,
                                  Billing_State__c,Close_Date__c,Contact_Person_Name__c,
                                  Email__c,Gst_Exempted__c,  GST_Number__c,Insurance__c,
                                  Monthly_Potential_Air__c,Monthly_Potential_Surface__c,
                                  Opportunity_Id__c,Type__c,Customer_Type__c,PAN_No__c,
                                  Product_Category__c,Stage__c,TAN_Exempted__c,
                                  TAN_No__c,Type_of_Packaging__c,Website__c,CreatedById,
                                  Corporate_Office_Location__c,CreatedDate,
                                  Vertical__c, Sub_Vertical__c,Account__c, Account__r.Vertical__c,Account__r.Sub__c from opportunity__c where Stage__c = 'Closed Won' and id=:objId]; 
            Account acc = [select id, Name,Propel_MSAcode__c,Propel_key__c from Account where Id=:opp.Account__c];
            String token; 
            system.debug('Opp:' +opp);
            Account updatedaccount = new Account();
            if(opp !=null)
            {
                // if(Toke.CurrentToken__c != null){  
                JSONGenerator gen = JSON.createGenerator(true);
                // gen.writeStartArray();
                if(opp !=null)
                {
                    gen.writeStartObject();
                    if(opp.X3PL_Potential__c != null){
                        gen.writeNumberField('X3PL_POTENTIAL', opp.X3PL_Potential__c);            
                    }
                    else{
                        gen.writeNumberField('X3PL_POTENTIAL',0);
                        }
                    if(opp.AccId__c != null){
                        gen.writeStringField('ACCID', opp.Account__c);            
                        }
                    else{
                        gen.writeStringField('ACCID', '');
                    }
                    if(opp.Billing_Street__c != null){
                        gen.writeStringField('BILLING_STREET', opp.Billing_Street__c);            
                        }
                    else{
                        gen.writeStringField('BILLING_STREET', '');
                    }
                    if(opp.Billing_City__c != null){
                        gen.writeStringField('BILLING_CITY', opp.Billing_City__c);            
                        }
                    else{
                        gen.writeStringField('BILLING_CITY', '');
                        }
                    if(opp.Billing_Country__c != null){
                        gen.writeStringField('BILLING_COUNTRY', opp.Billing_Country__c);            
                        }
                    else{
                        gen.writeStringField('BILLING_COUNTRY', '');
                    }
                    if(opp.Billing_Zip_Postal_Code__c != null){
                        gen.writeStringField('BILLING_ZIP_POSTAL_CODE', opp.Billing_Zip_Postal_Code__c);            
                        }
                    else{
                        gen.writeStringField('BILLING_ZIP_POSTAL_CODE', '');
                        }
                    if(opp.Billing_State__c != null){
                        gen.writeStringField('BILLING_STATE', opp.Billing_State__c);            
                        }
                    else{
                        gen.writeStringField('BILLING_STATE', '');
                        }
                    if(opp.Close_Date__c != null){
                        gen.writeDateField('CLOSE_DATE', opp.Close_Date__c);            
                        }
                    else{
                        gen.writeDateField('CLOSE_DATE',null);
                        }
                    if(opp.Contact_Person_Name__c != null){
                        gen.writeStringField('CONTACT_PERSON_NAME', opp.Contact_Person_Name__c);            
                        }
                    else{
                        gen.writeStringField('CONTACT_PERSON_NAME', '');
                        }
                    if(opp.Email__c != null){
                        gen.writeStringField('EMAIL', opp.Email__c);            
                        }
                    else{
                        gen.writeStringField('EMAIL', '');
                        }
                    if(opp.Gst_Exempted__c  != null){
                        gen.writeBooleanField('GST_EXEMPTED', opp.Gst_Exempted__c );            
                        }
                    else{
                        gen.writeBooleanField('GST_EXEMPTED',null);
                        }
                    if(opp.GST_Number__c  != null){
                        gen.writeStringField('GST_NUMBER', opp.GST_Number__c );            
                        }
                    else{
                        gen.writeStringField('GST_NUMBER', '');
                        }
                    if(opp.Insurance__c  != null){
                        gen.writeStringField('INSURANCE', opp.Insurance__c );            
                        }
                    else{
                        gen.writeStringField('INSURANCE', '');
                        }
                    if(opp.Monthly_Potential_Air__c  != null){
                        gen.writeNumberField('MONTHLY_POTENTIAL_AIR', opp.Monthly_Potential_Air__c );            
                        }
                    else{
                        gen.writeNumberField('MONTHLY_POTENTIAL_AIR',0);
                        }
                    if(opp.Monthly_Potential_Surface__c  != null){
                        gen.writeNumberField('MONTHLY_POTENTIAL_SURFACE', opp.Monthly_Potential_Surface__c );            
                        }
                    else{
                        gen.writeNumberField('MONTHLY_POTENTIAL_SURFACE',0);
                        }
                    if(opp.Opportunity_Id__c  != null){
                        gen.writeStringField('OPPORTUNITY_ID', opp.Opportunity_Id__c );            
                        }
                    else{
                        gen.writeStringField('OPPORTUNITY_ID', '');
                        }
                    if(opp.Name  != null){
                        gen.writeStringField('NAME', opp.Name );            
                        }
                    else{
                        gen.writeStringField('NAME', '');
                        }
                    if(opp.Type__c  != null){
                        gen.writeStringField('CUSTOMER_TYPE', opp.Type__c );            
                        }
                    else{
                        gen.writeStringField('CUSTOMER_TYPE', '');
                        }
                    if(opp.Customer_Type__c  != null && (opp.Customer_Type__c == 'New Opportunity' || opp.Customer_Type__c == 'Existing-New')){
                        gen.writeStringField('OPPORTUNITY_TYPE', 'New Opportunity');            
                        }
                    else{
                        gen.writeStringField('OPPORTUNITY_TYPE', '');
                        }
                    if(opp.PAN_No__c  != null){
                        gen.writeStringField('PAN_NO', opp.PAN_No__c );            
                        }
                    else{
                        gen.writeStringField('PAN_NO', '');
                        }
                    // added by KR SANSI, SAC-707, product category always be blank
                    /*if(opp.Product_Category__c  != null){
                        gen.writeStringField('PRODUCT_CATEGORY', opp.Product_Category__c );            
                        }
                    else{
                        gen.writeStringField('PRODUCT_CATEGORY', '');
                        }*/
                    gen.writeStringField('PRODUCT_CATEGORY', '');
                    if(opp.Stage__c  != null){
                        gen.writeStringField('STAGE',opp.Stage__c );            
                            }
                    else{
                        gen.writeStringField('STAGE', '');
                        }
                    if(opp.TAN_Exempted__c  != null){
                        gen.writeBooleanField('TAN_EXEMPTED', opp.TAN_Exempted__c );            
                        }
                    else{
                        gen.writeBooleanField('TAN_EXEMPTED',null);
                        }
                    if(opp.TAN_No__c  != null){
                        gen.writeStringField('TAN_NO', opp.TAN_No__c );            
                        }
                    else{
                        gen.writeStringField('TAN_NO', '');
                        }
                    if(opp.Type_of_Packaging__c  != null){
                        gen.writeStringField('TYPE_OF_PACKAGING', opp.Type_of_Packaging__c );            
                        }
                    else{
                        gen.writeStringField('TYPE_OF_PACKAGING', '');
                        }
                    if(opp.Website__c  != null){
                        gen.writeStringField('WEBSITE', opp.Website__c );            
                        }
                    else{
                        gen.writeStringField('WEBSITE', '');
                        }
                    if(opp.CreatedDate  != null){
                        gen.writeDateTimeField('CREATED_DATE', opp.CreatedDate );            
                        }
                    else{
                        gen.writeDateTimeField('CREATED_DATE',null);
                        }
                    if(opp.Corporate_Office_Location__c  != null){
                        gen.writeStringField('CORPORATE_OFFICE_LOCATION', opp.Corporate_Office_Location__c ); 
                        }
                    else{
                        gen.writeStringField('CORPORATE_OFFICE_LOCATION', '');
                        }
                    if(opp.Account__r.Vertical__c!= null){
                        gen.writeObjectField('VERTICAL', opp.Vertical__c);  
                        }
                    else{
                        gen.writeObjectField('VERTICAL', '');
                        }
                    if(opp.Account__r.Sub__c!= null){
                        gen.writeStringField('SUBVERTICAL', opp.Sub_Vertical__c);
                        }
                    else{
                        gen.writeStringField('SUBVERTICAL', '');
                        }
                    gen.writeEndObject();
                }
            
                //  gen.writeEndArray();
                String jsonString = gen.getAsString(); 
                system.debug('JSONNNNNNNNNNN'+jsonString);
                String MSAEndPoint = Endpoint;
                // String MSAEndPoint = 'https://sfi-sit.sfxapps.com/v2/sfi/cc/msa';
                // Custom label to fetch platform integration user id. 
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
                if(! cls_RecursiveHandler.bol_FlagToStopMSAPushAPI)
                {
                    HttpRequest httpReq = new HttpRequest();
                    httpReq.setEndpoint(MSAEndPoint);
                    httpReq.setMethod('POST');
                    httpReq.setHeader('Content-Type','application/json;charset=UTF-8');
                    httpReq.setHeader('X-Content-Type-Options',System.Label.X_Content_Type_Options);
                    httpReq.setHeader('X-XSS-Protection', System.Label.X_XSS_Protection);
                    httpReq.setHeader('X-Frame-Options', System.Label.X_Frame_Options);
                    httpReq.setHeader('X-API-Key', System.Label.X_API_Key);
                    httpReq.setHeader('userId',usrName);
                    httpReq.setHeader('Accept','*/*');
                    httpReq.setHeader('Authorization',tokenAuth);
                    httpReq.setTimeout(120000);
                    httpReq.setbody(jsonString);
                    System.debug('httpReq---------->'+httpReq);
                    Http htp = new Http();
                    HttpResponse htpRes = htp.send(httpReq);
                    System.debug('htpRes-------------->'+htpRes);
                    

                    if(htpRes.getStatusCode() == 200 || cls_RecursiveHandler.bol_isTesting1)
                    {
                        IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
                        updateITLogObject.recordId = itRecordId;
                        updateITLogObject.request = httpReq.getBody();
                        updateITLogObject.response = htpRes.getBody();
                        IntegrationUtility.updateIntegrationTransaction(updateITLogObject); 
                        
                        system.debug('status code 200 response body:' +htpRes.getBody());
                        JSONParser parser =JSON.createParser(htpRes.getBody());
                        System.debug('parser--------------->'+parser);
                        // used to capture the Propel-I response.
                        String str_MSACode;
                        String str_PropelKey;
                        String strOppCode;
                        
                        while (parser.nextToken() != null)
                        {
                            system.debug('in while loop');
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                                (parser.getText() == 'message'))
                            {
                                parser.nextToken();
                                String strResMsg = parser.getText();
                                System.debug('strResMsg----->'+strResMsg);
                                if(String.isNotBlank(strResMsg) && strResMsg.contains('='))
                                {
                                    if(String.isNotBlank(strResMsg.subStringAfter('=')))
                                        strOppCode = strResMsg.subStringAfter('=').trim();
                                    System.debug('strOppCode---------------->'+strOppCode);    
                                }
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                                (parser.getText() == 'MSA_CODE')){
                                    parser.nextToken();
                                    // parser.nextToken(); 
                                    str_MSACode = parser.getText();
                                    system.debug('Propel_MSAcode__c in account:' +acc.Propel_MSAcode__c);
                                }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                                (parser.getText() == 'MSA_CUST_KEY')) 
                            {
                                parser.nextToken();
                                // parser.nextToken(); 
                                str_PropelKey = parser.getText();
                                system.debug('Propel_key__c in account:' +acc.Propel_key__c);
                            }
                        }
                        // To populate the MSA code and propel key on account. 
                        if(String.isNotBlank(str_MSACode))
                        {
                            List<Account> lst_Account = [SELECT Id, Propel_MSACode__c from Account where Propel_MSACode__c =: str_MSACode];
                            if(lst_Account != null && lst_Account.size() > 0)
                            {
                                System.debug('MSA Already Exist into the system--->'+lst_Account);
                            }
                            else{
                                
                                // Update MSA code and Propel Key on Account. 
                                acc.Propel_MSAcode__c = str_MSACode;
                                acc.Propel_key__c = str_PropelKey;
                                
                                Update acc;
                            }
                        }
                        
                        // update the Opp code as opportunity is successfully created in Propel-I.
                        if(String.isNotBlank(strOppCode))
                        {
                            System.debug('strOppCode--------------->'+strOppCode);
                            opp.Opp_Code__c = Integer.valueOf(strOppCode); 
                            
                            update opp;
                        }
                        
                        //Akshay(09/29): Update the custom setting to keep the re-generated token.
                        if(String.isNotBlank(tokenAuth))
                        {
                            cls_AddTokenBillingSystem.addToken(tokenAuth, usrId);
                        }        
                    }
                    else if(htpRes.getStatusCode() == 400 || htpRes.getStatusCode() == 401 || htpRes.getStatusCode() == 500 ||cls_RecursiveHandler.bol_isTesting1)
                    {
                        JSONGenerator genAuth = JSON.createGenerator(true);
                        genAuth.writeStartObject();
                        genAuth.writeStringField('grant_type', 'client_credentials');
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
                            }    
                            HttpRequest httpReq1 = new HttpRequest();
                            httpReq1.setEndpoint(MSAEndPoint);
                            httpReq1.setMethod('POST');
                            httpReq1.setHeader('Content-Type','application/json;charset=UTF-8');
                            httpReq1.setHeader('X-Content-Type-Options',System.Label.X_Content_Type_Options);
                            httpReq1.setHeader('X-XSS-Protection', System.Label.X_XSS_Protection);
                            httpReq1.setHeader('X-Frame-Options', System.Label.X_Frame_Options);
                            httpReq1.setHeader('X-API-Key', System.Label.X_API_Key);
                            httpReq1.setHeader('userId',usrName);
                            httpReq1.setHeader('Accept','*/*');
                            httpReq1.setHeader('Authorization',tokenAuth);
                            httpReq1.setTimeout(120000);
                            httpReq1.setbody(jsonString);
                            Http htp1 = new Http();
                            HttpResponse htpRes1 = htp1.send(httpReq1);
                            System.debug('htpRes-------------->'+htpRes1);
                            IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
                            updateITLogObject.recordId = itRecordId;
                            updateITLogObject.request = httpReq1.getBody();
                            updateITLogObject.response = htpRes1.getBody();
                            IntegrationUtility.updateIntegrationTransaction(updateITLogObject); 
                            if(htpRes1.getStatusCode() == 200 || cls_RecursiveHandler.bol_isTesting2)
                            {
                                
                                system.debug('status code 200 response body:' +htpRes1.getBody());
                                JSONParser parser =JSON.createParser(htpRes1.getBody());
                                System.debug('parser--------------->'+parser);
                                // used to capture the Propel-I response.
                                String str_MSACode;
                                String str_PropelKey;
                                String strOppCode;               
                                while (parser.nextToken() != null)
                                {
                                    system.debug('in while loop');
                                    if((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                                       (parser.getText() == 'message'))
                                    {
                                        parser.nextToken();
                                        String strResMsg = parser.getText();
                                        System.debug('strResMsg----->'+strResMsg);
                                        if(String.isNotBlank(strResMsg) && strResMsg.contains('='))
                                        {
                                            if(String.isNotBlank(strResMsg.subStringAfter('=')))
                                                strOppCode = strResMsg.subStringAfter('=').trim();
                                            System.debug('strOppCode---------------->'+strOppCode);    
                                        }
                                    }
                                    if((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                                       (parser.getText() == 'MSA_CODE')){
                                           parser.nextToken();
                                           // parser.nextToken(); 
                                           str_MSACode = parser.getText();
                                           system.debug('Propel_MSAcode__c in account:' +acc.Propel_MSAcode__c);
                                       }
                                    if((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                                       (parser.getText() == 'MSA_CUST_KEY')) 
                                    {
                                        parser.nextToken();
                                        // parser.nextToken(); 
                                        str_PropelKey = parser.getText();
                                        system.debug('Propel_key__c in account:' +acc.Propel_key__c);
                                    }
                                }
                                // To populate the MSA code and propel key on account. 
                                if(String.isNotBlank(str_MSACode))
                                {
                                    List<Account> lst_Account = [SELECT Id, Propel_MSACode__c from Account where Propel_MSACode__c =: str_MSACode];
                                    if(lst_Account != null && lst_Account.size() > 0)
                                    {
                                        System.debug('MSA Already Exist into the system--->'+lst_Account);
                                    }
                                    else{
                                        
                                        // Update MSA code and Propel Key on Account. 
                                        acc.Propel_MSAcode__c = str_MSACode;
                                        acc.Propel_key__c = str_PropelKey;
                                        
                                        Update acc;
                                    }
                                }
                                
                                // update the Opp code as opportunity is successfully created in Propel-I.
                                if(String.isNotBlank(strOppCode))
                                {
                                    System.debug('strOppCode--------------->'+strOppCode);
                                    opp.Opp_Code__c = Integer.valueOf(strOppCode); 
                                    
                                    update opp;
                                }
                                
                                //Akshay(09/29): Update the custom setting to keep the re-generated token.
                                if(String.isNotBlank(tokenAuth))
                                {
                                    cls_AddTokenBillingSystem.addToken(tokenAuth, usrId);
                                }        
                            }
                            
                        }
                    }
                }
            }     
        }catch(Exception e){

            IntegrationUtility.IntegrationLog updateITLogObject = new IntegrationUtility.IntegrationLog();
            updateITLogObject.recordId = itRecordId;
            updateITLogObject.errorMessage = e.getMessage();
            IntegrationUtility.updateIntegrationTransaction(updateITLogObject); 

            String name = 'MSA';
            String ClassName = 'MSAPushAPI';
            ExceptionHandling.Exception( name, ClassName, e);
        
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