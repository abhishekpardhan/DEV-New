/**
* @File Name          : cls_BillingSubmissionRequest.apxc
* @Description        : cls_BillingSubmissionRequest is used for sending submission date to propeli
* @Author             : Adarsh
* @Group              : Safexpress
* @Last Modified By   : Adarsh
* @Last Modified On   : 08-11-2023
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        19-10-2023                Adarsh                  Initial Version
**/
Public Class cls_BillingSubmissionRequest implements Queueable, Database.AllowsCallouts
{
    Public List<Task> subTskIdList;
    public cls_BillingSubmissionRequest(List<Task> subTskIdList){
        this.subTskIdList = subTskIdList ;  
    }
    Public void execute(QueueableContext qc)
    {
        try
        {
            system.debug('start'+subTskIdList.size());
            String str_CreditEndPoint = System.label.PropelICreditEndPoint;
            String str_AlliedEndPoint = System.label.PropelIAlliedEndPoint;
            String str_WMSEndPoint = System.label.PropelIWMSBill;
            List<Invoice_Submission_Response__c> lstInvoiceSubRes = new List<Invoice_Submission_Response__c>();
            // Response JSON
            List<resJSON> lstResponse = new List<resJSON>();
            // API JSON
            upperJSONReq alliedJSONData  = new upperJSONReq();
            upperJSONReq wmsJSONData  = new upperJSONReq();
            upperJSONReq creditJSONData  = new upperJSONReq();
            // to hold all the allied type bills.
            List<jsonRequestBody> lstAlliedJSONBody = new List<jsonRequestBody>();
            //to hold all the WMS type of bills. 
            List<jsonRequestBody> lstWMSJSONBody = new List<jsonRequestBody>();
            // to hold all the credit type bills. 
            List<jsonRequestBody> lstCreditJSONBody = new List<jsonRequestBody>();
            
            Id subrecId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
            Task tsk = this.subTskIdList[0];
            if(tsk.whatId != null)
            {
                List<Invoice__c> invData = [SELECT Id, Name, Bill_Type__c,Propel_ID__c, Remarks__c,Submission_Date__c, Submitted_To__r.name, Submitted_To__r.MobilePhone, Submitted_To__r.email,Is_Submission_Synced__c,CreatedDate from Invoice__c where Id =: tsk.whatId AND Is_Submission_Synced__c = false limit 1];
                System.debug('invData------------------>'+invData);
                if(invData.size() > 0)
                {
                    jsonRequestBody eachRequest = new jsonRequestBody();
                    eachRequest.billId =Integer.valueOf(invData[0].Propel_ID__c);
                    eachRequest.billNumber = invData[0].name;
                    eachRequest.billType = invData[0].Bill_Type__c;
                    eachRequest.submsnPersonName = invData[0].Submitted_To__r.name;
                    eachRequest.submsnContactNum = invData[0].Submitted_To__r.MobilePhone;
                    eachRequest.submsnNote = invData[0].Remarks__c;
                    eachRequest.subsnMail = invData[0].Submitted_To__r.email;
                    if(invData[0].Submission_Date__c != null)
                    {
                        String sMonth = String.valueof(invData[0].Submission_Date__c.month());
                        String sDay = String.valueof(invData[0].Submission_Date__c.day());
                        if(sMonth.length()==1){
                            sMonth = '0' + sMonth;
                        }
                        if(sDay.length()==1){
                            sDay = '0' + sDay;
                        }
						eachRequest.submsnDt = sDay+'/'+sMonth+'/'+String.valueOf(invData[0].Submission_Date__c.year());   //Date format: 'DD/MM/YYYY'
                    }
                    
                    if(eachRequest.billType != null && eachRequest.billType == 'CREDIT_BILL')
                        lstCreditJSONBody.add(eachRequest);
                    if(eachRequest.billType != null && eachRequest.billType == 'ALLIED_CREDIT_BILL')
                        lstAlliedJSONBody.add(eachRequest);
                    if(eachRequest.billType != null && eachRequest.billType == 'WMS_BILL')
                        lstWMSJSONBody.add(eachRequest);
                }
                
                System.debug('lstCreditJSONBody---------------->'+lstCreditJSONBody);
                if(! lstCreditJSONBody.isEmpty())
                {
                    creditJSONData.data = lstCreditJSONBody;
                    System.debug('creditJSONData------------->'+creditJSONData);
                    lstInvoiceSubRes = invSubResponse(str_CreditEndPoint, JSON.serialize(creditJSONData));
                    System.debug('lstInvoiceSubRes credit---------------->'+lstInvoiceSubRes);
                    
                }
                // allied bill type request. 
                System.debug('lstAlliedJSONBody---------------->'+lstAlliedJSONBody);
                if(! lstAlliedJSONBody.isEmpty())
                {
                    alliedJSONData.data = lstAlliedJSONBody;
                    System.debug('alliedJSONData------------->'+alliedJSONData);
                    lstInvoiceSubRes = invSubResponse(str_AlliedEndPoint, JSON.serialize(alliedJSONData));
                    System.debug('lstInvoiceSubRes allied--------------->'+lstInvoiceSubRes);
                    
                }
                // WMS bill type request. 
                System.debug('lstWMSJSONBody---------------->'+lstWMSJSONBody);
                if(! lstWMSJSONBody.isEmpty())
                {
                    wmsJSONData.data = lstWMSJSONBody;
                    System.debug('wmsJSONData------------->'+wmsJSONData);
                    lstInvoiceSubRes = invSubResponse(str_WMSEndPoint, JSON.serialize(wmsJSONData));
                    System.debug('lstInvoiceSubRes wms---------------->'+lstInvoiceSubRes);
                    
                }
                System.debug('lstInvoiceSubRes--------------->'+lstInvoiceSubRes);
                if(! lstInvoiceSubRes.isEmpty()){
                    insert lstInvoiceSubRes;
                }
                
                List<Task> tskListRemain = this.subTskIdList;
                tskListRemain.remove(0);
                system.debug('remove'+subTskIdList.size());
                if(tskListRemain.size() > 0){
                    system.debug('again'+subTskIdList.size());
                    System.enqueueJob(new cls_BillingSubmissionRequest(tskListRemain));
                }
            }
        }Catch(Exception exc){
            // capture the error in error log table.
            String name = 'Billing Submission';
            String ClassName = 'cls_BillingSubmissionRequest';
            System.debug('Error Message: '+exc.getMessage());
            System.debug('Error Message: '+exc.getLineNumber());
            System.debug('Error Message: '+exc.getCause()+'Line---->'+exc.getTypeName());
            ExceptionHandling.Exception( name, ClassName, exc);
        }
    }
   
    //JSONParser 1
    Public class jsonParser2
    {
        public String access_token;
        public String token_type;
        public String expires_in;
    } 

    Private Class upperJSONReq
    {
        List<jsonRequestBody> data;
        upperJSONReq(){
            
        }
    }
    Public Class jsonRequestBody
    {
        Public Integer billId;
        Public String billNumber;
        Public String billType;
        Public String submsnPersonName;
        Public String submsnContactNum;
        Public String submsnNote;
        Public String subsnMail;
        Public String submsnDt;

    }
    Public class responseOuter
    {
        Public List<resJSON> lstResponse; 
    }
    //Response JSON
    Public class resJSON
    {
        Public Integer billId;
        Public String billNumber;
        Public String status;
        Public String message;
    }
    //Http propeli callout
    Public static HttpResponse propelIBillSysCallout(String endPoint, String body)
    {
        String str_method = 'POST';
        String str_xAPIKey = System.label.X_API_Key;
        String str_Token = newBillToken();
        // Http request. 
        HttpRequest htpReq = new HttpRequest();
        htpReq.setMethod(str_method);
        htpReq.setHeader('Authorization', str_Token);
        htpReq.setHeader('x-api-key', str_xAPIKey);
        htpReq.setHeader('Content-Type', 'application/json');
        htpReq.setEndpoint(endPoint);
        htpReq.setBody(body);
        //Make Propel-I billing system callout. 
        Http htp = new Http();
        HttpResponse htpRes;
		htpRes = htp.send(htpReq);
        return htpRes;
        
    }
    
    //Invoice submission response after propeli callout.
    Public static List<Invoice_Submission_Response__c> invSubResponse(String endPoint, String body)
    {
        System.debug('endPoint----------------------->'+endPoint);
        System.debug('body------------------->'+body);
        List<Invoice_Submission_Response__c> lstInvSubRes = new List<Invoice_Submission_Response__c>();
        HttpResponse htresponse = propelIBillSysCallout(endPoint, body);
        
        if(htresponse.getStatusCode() == 200)
        {
            List<resJSON> lstSubResponse = (List<resJSON>)JSON.deserialize(htresponse.getBody(),List<resJSON>.class);  
            System.debug('lstSubResponse--------------->'+lstSubResponse);
            if(! lstSubResponse.isEmpty())
            {
                lstInvSubRes =  invPayloadCall(lstSubResponse);
            }
        }
        return lstInvSubRes;
    }
    //Get token
    Private static String newBillToken()
    {
        
        String usrName = System.label.Propeli_Username;
        String password = System.label.Propeli_Password;
        String tokenEndPoint = System.label.PropeliTokenEndpoint;
        String newtkn;
        // generate token request body
        JSONGenerator genAuth = JSON.createGenerator(true);
        genAuth.writeStartObject();
        genAuth.writeStringField('grant_type', 'client_credentials');
        genAuth.writeEndObject();
        String jsonAuthString = genAuth.getAsString(); 
        System.debug('jsonAuthString------------------------>'+jsonAuthString);
        
        HttpResponse htpTokenRes = Test.isRunningTest() ?  setTestResponse() : cls_PropelICallout.propelITokenCallout(usrName, password,'POST',jsonAuthString,tokenEndPoint);
        if(htpTokenRes.getStatusCode() == 200)
        {
            jsonParser2 tokenRes = (jsonParser2)JSON.deserialize(htpTokenRes.getBody(), jsonParser2.class);
            if(tokenRes.access_token != null)
            {
                newtkn = tokenRes.access_token;
            }
        }
        system.debug('new token---->'+newtkn);
        return newtkn;
    }
    //Invoice submission response
    Public static Invoice_Submission_Response__c invResponse(resJSON apiRes, String invId){
        resJSON resjson = apiRes;
        Invoice_Submission_Response__c eachResponse = new Invoice_Submission_Response__c();
        eachResponse.Bill_Id__c = resjson.billId;
        eachResponse.Bill_Number__c = resjson.billNumber;
        eachResponse.Message__c = resjson.message;
        eachResponse.Status__c = resjson.status;
        eachResponse.Invoice__c = invId;
        system.debug('eachResponse'+eachResponse);
        return eachResponse;
    }
    //json payload
    Public static List<Invoice_Submission_Response__c> invPayloadCall(List<resJSON> jsonPayloadList){
        List<Invoice_Submission_Response__c> lstInvoiceSubRes = new List<Invoice_Submission_Response__c>();
        Map<String, Id> mapInvoiceIds = new Map<String, Id>();
        Set<String> setInvoiceNumber = new Set<String>();
        for(resJSON apiRes : jsonPayloadList)
        {
            setInvoiceNumber.add(apiRes.billNumber);
        }
        System.debug('setInvoiceNumber-------------->'+setInvoiceNumber);
        if(! setInvoiceNumber.isEmpty())
        {
            List<Invoice__c> lstInvoice = [SELECT Id, name from Invoice__c where Name IN :setInvoiceNumber];
            System.debug('lstInvoice------------>'+lstInvoice);
            if(! lstInvoice.isEmpty())
            {
                for(Invoice__c eachInvc : lstInvoice)
                    mapInvoiceIds.put(eachInvc.name, eachInvc.id);
            }
            System.debug('mapInvoiceIds---------------->'+mapInvoiceIds);
        }
        for(resJSON apiRes : jsonPayloadList)
        {
            if(! mapInvoiceIds.isEmpty() && mapInvoiceIds.containsKey(apiRes.billNumber))
            {
                Invoice_Submission_Response__c invres = invResponse(apiRes,mapInvoiceIds.get(apiRes.billNumber));
                lstInvoiceSubRes.add(invres);
            }                                        
        }
        return lstInvoiceSubRes;
    }
    Private static  HttpResponse setTestResponse()
    {
        HttpResponse htpRes = new HttpResponse();
        htpRes.setStatus('Success');
        htpRes.setStatusCode(200);
        htpRes.setBody('{"access_token":"GSGDGFSFSFFSFSFFSFFSFSFFSFSFSFSFSFFSFFSFSFSFFSFSF","expires_in":18000, "token_type":"Bearer"}');
        return htpRes;
        
    }
}