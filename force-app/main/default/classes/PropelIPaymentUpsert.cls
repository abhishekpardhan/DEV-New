/**
 * Description    :    Rest resource to insert/update the payment details in SFDC. 
 * Created By       :       
 * Created Date     :       
 * Release          :      16th Dec, 2020
 * Last Modified on :     24-06-2026
 * Last Modified by :     Rishank Bhardwaj
 * Jira Ticket      :     SAC-2648 
 **/
@RestResource(urlMapping='/PropelIPaymentUpsert/*')
global with sharing class PropelIPaymentUpsert  {
    
    //Wrapper class to send the response in jSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        String compositeKey;
        Boolean isCreated;
        Boolean isSuccess;
    }

    // Set the response body.
    Global class APIResponse extends cls_APIResponse
    {
        Global  String SF_PaymentId; 
        Global String  Bill_Number;
        Global Integer Application_Doc_Id;
        Global  Date SF_CreatedDate; 
        Global  Date SF_LastModifiedDate;        
    }
    
    //Wrapper class
    global class jsonWrap {
        public Integer Bill_ID;
        public String Bill_Number;
        public String Receipt_Number;
        public Double Received_Freight_Amount;
        public Double Received_Freight_TDS_Amount;
        public Double Received_OCT_Amount;
        public Date Installment_Ref_Date;
        public Date Created_Date;
        String Installment_Type;
        String Installment_Reference;
        Integer Receipt_Id;
        Integer Status_Lid;
        Date Updated_Date;
        Integer Deviation_Id;
        Date Deviation_Date;
        String Cheque_Dishonor_Remarks;
        String Deviation_Type;
        public Integer Application_Doc_Id;
        String Action_Type;
        String Attribute2;
        String Attribute3;
        String Attribute4;
    }
    
    //POST request method to upsert Payment records and sending response in return
    @HttpPost
    global static void createPayment(List<PropelIPaymentUpsert.jsonWrap> lstPymntRecords) {
        
        // Create an object to return the API response. 
        
        Payment__c[] pymts = new Payment__c[]{};
        // List of exceptions. 
        List<APIResponse> lst_APIResponses = new List<APIResponse>();
        // Set of Bill Number.
        Set<String> set_BillNumber = new Set<String>();
        //Map of Billing Number and their SFDC invoice id.
        Map<String, Id> map_InvoiceIds =new Map<String, Id>();
        for(PropelIPaymentUpsert.jsonWrap eachPaymntRecord: lstPymntRecords)
        {
            if(String.isNotBlank(eachPaymntRecord.Bill_Number))
                set_BillNumber.add(eachPaymntRecord.Bill_Number);
        }
        System.debug('set_BillNumber------>'+set_BillNumber);
        if(! set_BillNumber.isEmpty())
        {
            List<Invoice__c> lst_Invoice = [Select id,name from Invoice__c where Name IN : set_BillNumber  limit 9999];
            System.debug('lst_Invoice------------->'+lst_Invoice);
            if(! lst_Invoice.isEmpty())
            {
                for(Invoice__c eachInvc : lst_Invoice)
                {
                    map_InvoiceIds.put(eachInvc.name, eachInvc.Id);
                }
            }
        }
        System.debug('map_InvoiceIds------------->'+map_InvoiceIds);
        
        // Iterate the payment records.     
        for(PropelIPaymentUpsert.jsonWrap eachPaymntRecord: lstPymntRecords) {
            // Each API request response. 
            APIResponse cls_APIResponse = new APIResponse();
            if(String.isNotBlank(String.valueOf(eachPaymntRecord.Application_Doc_Id)))
            {
                if(String.isNotBlank(eachPaymntRecord.Bill_Number))
                {
                    if(! map_InvoiceIds.isEmpty() && map_InvoiceIds.keySet().contains(eachPaymntRecord.Bill_Number))
                    {
                        // Add the code to insert/update the Payment records. 
                        Payment__c obj_upsertPayment = new Payment__c();
                        obj_upsertPayment.Bill_ID__c = eachPaymntRecord.Bill_ID;
                        obj_upsertPayment.Bill_Number__c = eachPaymntRecord.Bill_Number;
                        obj_upsertPayment.Receipt_Number__c = eachPaymntRecord.Receipt_Number;
                        obj_upsertPayment.Received_Freight_Amount__c  = eachPaymntRecord.Received_Freight_Amount;
                        obj_upsertPayment.Received_Freight_TDS_Amount__c = eachPaymntRecord.Received_Freight_TDS_Amount;
                        obj_upsertPayment.Received_OCT_Amount__c = eachPaymntRecord.Received_OCT_Amount;
                        obj_upsertPayment.Installment_Reference_Date__c = eachPaymntRecord.Installment_Ref_Date;
                        obj_upsertPayment.Created_Date__c   = eachPaymntRecord.Created_Date;
                        obj_upsertPayment.Installment_Type__c = eachPaymntRecord.Installment_Type;
                        obj_upsertPayment.Installment_Reference__c = eachPaymntRecord.Installment_Reference;
                        obj_upsertPayment.Invoice__c= map_InvoiceIds.get(eachPaymntRecord.Bill_Number);
                        obj_upsertPayment.Receipt_id__c = eachPaymntRecord.Receipt_Id;
                        obj_upsertPayment.Status_Lid__c = eachPaymntRecord.Status_Lid;
                        obj_upsertPayment.Updated_Date__c = eachPaymntRecord.Updated_Date;
                        obj_upsertPayment.Deviation_Id__c = eachPaymntRecord.Deviation_Id;
                        obj_upsertPayment.Deviation_Date__c = eachPaymntRecord.Deviation_Date;
                        obj_upsertPayment.Cheque_Dishonor_Remarks__c = eachPaymntRecord.Cheque_Dishonor_Remarks;
                        obj_upsertPayment.Deviation_Type__c = eachPaymntRecord.Deviation_Type;
                        obj_upsertPayment.Doc_id__c = eachPaymntRecord.Application_Doc_Id;
                        // SAC- 2648 Composite Key formate has been changed
                        //obj_upsertPayment.Composite_Key__c = eachPaymntRecord.Receipt_Id + '-' + eachPaymntRecord.Bill_Number;
                        /*as  disscued reverting composite key again */
                        obj_upsertPayment.Composite_Key__c = eachPaymntRecord.Application_Doc_Id+ '-' + eachPaymntRecord.Bill_Number; 
                        obj_upsertPayment.Action_Type__c    = eachPaymntRecord.Action_Type;
                        pymts.add(obj_upsertPayment);

                    }else{
                        //702: Bill Number does not exist.
                        cls_APIResponse.SF_PaymentId = null; 
                        cls_APIResponse.Bill_Number = eachPaymntRecord.Bill_Number;
                        cls_APIResponse.Application_Doc_Id= eachPaymntRecord.Application_Doc_Id;
                        cls_APIResponse.StatusCode = '702';
                        cls_APIResponse.StatusMessage = 'Bill number does not exist in SFDC, please insert an existing bill number.'; 
                        lst_APIResponses.add(cls_APIResponse);
                    }

                }else{
                    //701: Bill number can not be blank. 
                    cls_APIResponse.SF_PaymentId = null; 
                    cls_APIResponse.Bill_Number = eachPaymntRecord.Bill_Number;
                    cls_APIResponse.Application_Doc_Id= eachPaymntRecord.Application_Doc_Id;
                    cls_APIResponse.StatusCode = '701';
                    cls_APIResponse.StatusMessage = 'Bill number can not be blank, please insert a bill number.'; 
                    lst_APIResponses.add(cls_APIResponse);
                }

            }else
            {
                // 701: Receipt Id can not be blank. 
                cls_APIResponse.SF_PaymentId = null; 
                cls_APIResponse.Bill_Number = eachPaymntRecord.Bill_Number;
                cls_APIResponse.Application_Doc_Id= eachPaymntRecord.Application_Doc_Id;
                cls_APIResponse.StatusCode = '700';
                cls_APIResponse.StatusMessage = 'Application_Doc_Id can not be blank, please insert a Application_Doc_Id.'; 
                lst_APIResponses.add(cls_APIResponse);
            }
        }
        if(pymts != null && pymts.size() > 0)
        {
            try{
                Database.UpsertResult[] results = Database.upsert(pymts, Payment__c.Fields.Composite_Key__c, false);
                List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
                for(Integer index = 0, size = results.size(); index < size; index++) {
                    // Each API request response. 
                    APIResponse cls_APIResponse = new APIResponse();
                    List<Database.Error> Errors = results[index].getErrors(); 
                    System.debug('Errors------------->'+Errors);
                    if(Errors != null && Errors.size() > 0)
                    {
                        for(Database.Error eachError : Errors){

                            cls_APIResponse.StatusCode = String.valueOf(eachError.getStatusCode());
                            cls_APIResponse.StatusMessage = eachError.getMessage();
                            cls_APIResponse.Bill_Number = pymts[index].Bill_Number__c;
                            cls_APIResponse.Application_Doc_Id= Integer.valueOf(pymts[index].Doc_id__c); 
                            cls_APIResponse.isCreated = results[index].isCreated(); 
                            cls_APIResponse.isSuccess = results[index].isSuccess();
                            // Create an entry in exception handling table. 
                        }

                    }else{    
                        cls_APIResponse.SF_PaymentId = results[index].getId();
                        cls_APIResponse.Bill_Number = pymts[index].Bill_Number__c;
                        cls_APIResponse.Application_Doc_Id= Integer.valueOf(pymts[index].Doc_id__c);
                        cls_APIResponse.isCreated = results[index].isCreated();
                        if(cls_APIResponse.isCreated)
                            cls_APIResponse.StatusMessage = 'The Payment record has been created successfully in SFDC.' ;
                        else
                            cls_APIResponse.StatusMessage = 'The Payment record has been updated successfully in SFDC.';
                        cls_APIResponse.StatusCode = '200';    
                        cls_APIResponse.isSuccess = results[index].isSuccess();
                        lst_APIResponses.add(cls_APIResponse);
                    }
                }
            }catch(Exception excep){
                System.debug('There is an internal error, please reach out to SFDC Admin team:'+excep.getTypeName()+'::'+excep.getMessage()+':'+excep.getStackTraceString());
                // Create an entry in exception handling table. 
                ExceptionHandling.Exception( 'Payment', 'PropelIPaymentUpsert', excep);  
            }
        }
        // Set the response body.
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lst_APIResponses));
    }
}