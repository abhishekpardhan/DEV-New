/**
* @File Name          : FussionSupplierDataAPI.apxc
* @Description        : FussionSupplierDataAPI is a Scheduled class to update supplier data in User Table
* @Author             : Shubham
* @Group              : Safexpress
* @Last Modified By   : Shubham
* @Last Modified On   : 05-01-2022
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        05-01-2022                Shubham                  Initial Version
**/
public class FussionSupplierDataAPI implements Schedulable
{
    public void execute(SchedulableContext sc)
    {
        FussionSupplierDataAPI FussionAPI = new FussionSupplierDataAPI();
        FussionSupplierDataAPI.getSupplerData();
    }
    @future(callout=true)
    public static void getSupplerData(){
        
        Propeli_API__c fussionAPICustomSetting = Propeli_API__c.getValues('Fusion Supplier API');
        String contentType = fussionAPICustomSetting.Authorisation_Type__c ;
        String tokenAuth = '';
        String method = 'GET';
        String api_Endpoint = fussionAPICustomSetting.Endpoint__c ;
        system.debug('ENDPOINTTTTTTTTTTTTTTTT:'+ api_Endpoint);
        String xAPIKey = fussionAPICustomSetting.Access_Key__c; 
        system.debug('APIKEYYYYYYYYYYYYYYYYYY:'+ xAPIKey);
        // String userName = fussionAPICustomSetting.UserName__c ; 
        String userName = System.label.Propeli_Username;
        
        system.debug('$$$$$$$$$$$$$$$$$$$$$$$$:'+ userName);
        String str_pltIntegrationProfileId = System.label.Platform_Integration_Profile_ID;
        String Token1 = cls_AddTokenBillingSystem.GetToken(str_pltIntegrationProfileId);
        
        HttpRequest htpReq = new HttpRequest();
        htpReq.setMethod(method);
        htpReq.setHeader('Authorization', Token1);
        htpReq.setHeader('x-api-key', xAPIKey);
        htpReq.setHeader('Content-Type', contentType);
        htpReq.setHeader('userid', userName);
        htpReq.setEndpoint(api_Endpoint);
        htpReq.setTimeout(120000);
        Http htp = new Http();
        HttpResponse htpRes = htp.send(htpReq);
        system.debug('Status Code:'+ htpRes.getStatusCode());
        system.debug('ResponceData:'+ htpRes.getBody());         
        Map<String,User> MapOfEmpCodeWithEmp = new Map<String,User>();
        
        JSON2Apex apiRes ;
        if(htpRes.getStatusCode() == 401 || htpRes.getStatusCode() == 403) // ||  cls_RecursiveHandler.bol_isTesting1
        {     
            
            system.debug('In the token expire loop');
            JSONGenerator genAuth = JSON.createGenerator(true);
            genAuth.writeStartObject();
            genAuth.writeStringField('grant_type', 'client_credentials');
            genAuth.writeEndObject();
            String jsonAuthString = genAuth.getAsString(); 
            
            HttpResponse htpTokenRes =  cls_PropelICallout.propelITokenCallout(System.Label.Propeli_Username, System.Label.Propeli_Password,'POST',jsonAuthString,System.Label.PropeliTokenEndpoint);
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
            }  
            HttpRequest htpReq1 = new HttpRequest();
            htpReq1.setMethod(method);
            htpReq1.setHeader('Authorization',tokenAuth );
            htpReq1.setHeader('x-api-key', xAPIKey);
            htpReq1.setHeader('Content-Type', contentType);
            system.debug('##############:'+ userName);
            htpReq1.setHeader('userid', userName);
            htpReq1.setEndpoint(api_Endpoint);
            htpReq1.setTimeout(120000);
            Http htp1 = new Http();
            HttpResponse htpRes1 = htp1.send(htpReq1);
            system.debug('Status Code:'+ htpRes1.getStatusCode());
            system.debug('ResponceData:'+ htpRes1.getBody());
            apiRes = (JSON2Apex) System.JSON.deserialize(htpRes1.getBody(), JSON2Apex.class);
            system.debug('apiRes:'+ apiRes);
            ExceptionHandling.createAPILog('FussionSupplierDataAPI', 'https://qdtnufu29a.execute-api.ap-south-1.amazonaws.com', api_Endpoint,htpRes.getBody() , htpRes.getStatusCode());
            
        }else if (htpRes.getStatusCode() == 200){
            apiRes = (JSON2Apex) System.JSON.deserialize(htpRes.getBody(), JSON2Apex.class);
            system.debug('apiRes:'+ apiRes);
            ExceptionHandling.createAPILog('FussionSupplierDataAPI', 'https://qdtnufu29a.execute-api.ap-south-1.amazonaws.com', api_Endpoint,htpRes.getBody() , htpRes.getStatusCode());            
        } 
        
        if(apiRes != null){ 
        	List<User> listToUpdate = new List<User> (); 
            // RC update 
            for(User usr : [SELECT Id, Name , AD_Id__c FROM User WHERE IsActive = TRUE]){
                if(!MapOfEmpCodeWithEmp.containsKey(usr.AD_Id__c))
                    MapOfEmpCodeWithEmp.put(usr.AD_Id__c,usr);
            }
            
            if(apiRes.suppInfoList.size() != null){  
                for(SuppInfoList eachData : apiRes.suppInfoList){
                    if(MapOfEmpCodeWithEmp.containsKey(eachData.employeeCode)){
                        System.debug('eachData.employeeCode-->'+eachData.employeeCode);
                        User newUser = New User (
                            AD_Id__c = eachData.employeeCode,
                            Supplier_Name__c = eachData.supplierName,
                            Supplier_Num__c = decimal.valueof(eachData.supplierNumber),
                            Supplier_Site_Code__c = eachData.supplierSite,
                            //        Supplier__c = eachData.status);
                            Supplier__c = eachData.status != 'A' ? 'Deactive' : 'Active');
                        listToUpdate.add(newUser);
                    }
                }
                Database.UpsertResult[] resultsacc = Database.upsert(listToUpdate, User.Fields.AD_Id__c, false);           
            }
        
        }
    }
    
    public class JSON2Apex {
        public List<SuppInfoList> suppInfoList;
        public String message;
        public String status;
        public Integer totalCount;
    }
    public class SuppInfoList {
        public Long supplierId;
        public String supplierName;
        public String supplierSite;
        public String supplierNumber;
        public String employeeCode;
        public String status;
    }
    Public class jsonParser2
    {
        public String access_token;
        public String token_type;
        public String expires_in;
    }  
    
}