/**
 * Description:    Rest resource to insert/update the debit details in SFDC. 
 * Created By:    Akshay Kumar   
 * Created Date:    16th Dec, 2020   
 * Test Class:
 * Release          :      
 * Last Modified on :      
 * Jira Ticket      :      
 **/
@RestResource(urlMapping='/PropelICreditNoteUpsert/*')
global with sharing class PropelICreditNoteUpsert{
    
    //Wrapper class
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        String compositeKey;
        Boolean isCreated;
        Boolean isSuccess;
    }
    // Wrapper class to prepare the response body.
    Global class APIResponse extends cls_APIResponse
    {
        Global  String SF_CreditNoteId; 
        Global String  Bill_Number;
        Global String CreditNote_Number;
        Global String ID;
        Global  Date SF_CreatedDate; 
        Global  Date SF_LastModifiedDate;        
    }
    
    //JSON parser
        global class jsonWrap {
        public Integer ID;
        public String Document_Type;
        public Integer Document_Type_ID;
        public String Note_Number;
        public Decimal Bill_ID;
        public String Bill_Number;
        public String Remarks;
        public String Note_Type;
        public Decimal Note_Amount_Total;
        public Decimal IGST;
        public Decimal CGST;
        public Decimal SGST;
        public Date Created_Date;
        public Date Update_Date;
        Public String Attribute1;
        Public String Attribute2;
        Public String Attribute3;
        Public String Attribute4;
        public String E_Bill;
        public String Submitted_to_Email_IDs;
        public String BDM_Email_IDs;
    }
    
    /**
     * POST request method to create Debit_Credit_Note__c records
     **/
    @HttpPost   
    global static void createDebitNote(List<PropelICreditNoteUpsert.jsonWrap> lstCreditNoteRecords) {
        // List of credit note records which has to be inserted/updated in SFDC. 
        List<Debit_Credit_Note__c> lst_CreditNotetoUpsert = new List<Debit_Credit_Note__c>();
        // List of exception. 
        List<APIResponse> lst_APIResponses = new List<APIResponse>();
        // Set of Bill Number.
        Set<String> set_BillNumber = new Set<String>();
        //Map of Billing Number and their SFDC invoice id.
        Map<String, Id> map_InvoiceIds =new Map<String, Id>();
        for(PropelICreditNoteUpsert.jsonWrap eachCreditNote: lstCreditNoteRecords)
        {
            if(String.isNotBlank(eachCreditNote.Bill_Number))
                set_BillNumber.add(eachCreditNote.Bill_Number);
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
        for(PropelICreditNoteUpsert.jsonWrap eachCreditNote : lstCreditNoteRecords) {
            
            // Each API request response. 
            APIResponse cls_APIResponse = new APIResponse();
            // Check the credit note Id. 
            if(eachCreditNote.ID != null)
            {
                //Check the invoice number. 
                if(String.isNotBlank(eachCreditNote.Bill_Number))
                {
                    if(! map_InvoiceIds.isEmpty() && map_InvoiceIds.keySet().contains(eachCreditNote.Bill_Number))
                    {
                        // insert the code to insert/update the credit note. 
                        Debit_Credit_Note__c obj_upesrtCreditNote = new Debit_Credit_Note__c();
                        obj_upesrtCreditNote.ID__c = eachCreditNote.ID;
                        obj_upesrtCreditNote.Document_Type__c = eachCreditNote.Document_Type;
                        obj_upesrtCreditNote.Document_Type_ID__c = eachCreditNote.Document_Type_ID;
                        obj_upesrtCreditNote.Note_Number__c = eachCreditNote.Note_Number;
                        obj_upesrtCreditNote.Invoice_Name__c = map_InvoiceIds.get(eachCreditNote.Bill_Number);
                        obj_upesrtCreditNote.Bill_Number__c = eachCreditNote.Bill_Number;
                        obj_upesrtCreditNote.Remarks__c = eachCreditNote.Remarks;
                        obj_upesrtCreditNote.Note_Type__c = eachCreditNote.Note_Type;
                        obj_upesrtCreditNote.Note_Amount_Total__c = eachCreditNote.Note_Amount_Total;
                        obj_upesrtCreditNote.Created_Date__c = eachCreditNote.Created_Date;
                        obj_upesrtCreditNote.Update_Date__c = eachCreditNote.Update_Date;
                        obj_upesrtCreditNote.IGST__c = eachCreditNote.IGST;
                        obj_upesrtCreditNote.CGST__c = eachCreditNote.CGST;
                        obj_upesrtCreditNote.SGST__c = eachCreditNote.SGST;
                        obj_upesrtCreditNote.Composite_Key__c = eachCreditNote.ID + '-' + eachCreditNote.Bill_Number;
                        lst_CreditNotetoUpsert.add(obj_upesrtCreditNote);

                    }else {

                        //802: the billing number does not exist, please insert an existing billing number. 
                        cls_APIResponse.SF_CreditNoteId = null; 
                        cls_APIResponse.Bill_Number = eachCreditNote.Bill_Number;
                        cls_APIResponse.CreditNote_Number = eachCreditNote.Note_Number;
                        cls_APIResponse.ID = String.valueOf(eachCreditNote.ID);
                        cls_APIResponse.StatusCode = '802';
                        cls_APIResponse.StatusMessage = 'Bill number does not exist in SFDC, please insert an existing bill number.'; 
                        lst_APIResponses.add(cls_APIResponse);

                    }
                }else{
                    //801: the billing number can not be blank, please insert a bill number.
                    cls_APIResponse.SF_CreditNoteId = null; 
                    cls_APIResponse.Bill_Number = eachCreditNote.Bill_Number;
                    cls_APIResponse.CreditNote_Number = eachCreditNote.Note_Number;
                    cls_APIResponse.ID = String.valueOf(eachCreditNote.ID);
                    cls_APIResponse.StatusCode = '801';
                    cls_APIResponse.StatusMessage = 'Bill number can not be blank, please insert a valid bill number.'; 
                    lst_APIResponses.add(cls_APIResponse);
                }

            }else
            {
                //800: ID can not blank, please insert a valid Id. 
                cls_APIResponse.SF_CreditNoteId = null; 
                cls_APIResponse.Bill_Number = eachCreditNote.Bill_Number;
                cls_APIResponse.CreditNote_Number = eachCreditNote.Note_Number;
                cls_APIResponse.ID = String.valueOf(eachCreditNote.ID);
                cls_APIResponse.StatusCode = '800';
                cls_APIResponse.StatusMessage = 'Id can not be blank, please insert a valid Id.'; 
                lst_APIResponses.add(cls_APIResponse);
            }
        }   

        System.debug('lst_CreditNotetoUpsert---------------->'+lst_CreditNotetoUpsert);
        System.debug('lst_APIResponses-------------->'+lst_APIResponses);

        if(lst_CreditNotetoUpsert != null && lst_CreditNotetoUpsert.size() > 0)
        {
            try{
                // upsert the credit records.   
                Database.UpsertResult[] results = Database.upsert(lst_CreditNotetoUpsert, Debit_Credit_Note__c.Fields.Composite_Key__c, false);
                List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
                for(Integer index = 0, size = results.size(); index < size; index++) {
                    // Each API request response. 
                    APIResponse cls_APIResponse = new APIResponse();
                    List<Database.Error> Errors = results[index].getErrors(); 
                    System.debug('Errors------------->'+Errors);
                    if(Errors != null && Errors.size() > 0)
                    {
                        for(Database.Error eachError : Errors){

                            cls_APIResponse.StatusCode = '806';
                            cls_APIResponse.StatusMessage = eachError.getMessage();
                            cls_APIResponse.ID =String.valueOf(lst_CreditNotetoUpsert[index].ID__c);
                            cls_APIResponse.Bill_Number = lst_CreditNotetoUpsert[index].Bill_Number__c;
                            cls_APIResponse.CreditNote_Number = lst_CreditNotetoUpsert[index].Note_Number__c;
                            cls_APIResponse.isCreated = results[index].isCreated(); 
                            cls_APIResponse.isSuccess = results[index].isSuccess();
                            lst_APIResponses.add(cls_APIResponse);
                            // Create an entry in exception handling table. 
                        }

                    }else{    
                        cls_APIResponse.SF_CreditNoteId = results[index].getId();
                        cls_APIResponse.ID =String.valueOf(lst_CreditNotetoUpsert[index].ID__c);
                        cls_APIResponse.Bill_Number = lst_CreditNotetoUpsert[index].Bill_Number__c;
                        cls_APIResponse.CreditNote_Number = lst_CreditNotetoUpsert[index].Note_Number__c;
                        cls_APIResponse.isCreated = results[index].isCreated();
                        if(cls_APIResponse.isCreated)
                            cls_APIResponse.StatusMessage = 'The Credit Note has been created successfully in SFDC.' ;
                        else
                            cls_APIResponse.StatusMessage = 'The Credit Note has been updated successfully in SFDC.';
                        cls_APIResponse.StatusCode = '200';    
                        cls_APIResponse.isSuccess = results[index].isSuccess();
                        lst_APIResponses.add(cls_APIResponse);
                    }
                }

            }catch(Exception excep)
            {
                System.debug('There is an internal error, please reach out to SFDC Admin team:'+excep.getTypeName()+'::'+excep.getMessage()+':'+excep.getStackTraceString());
                // Create an entry in exception handling table. 
                ExceptionHandling.Exception( 'DebitCreditNote', 'PropelICreditNoteUpsert', excep);  
                // Each API request response. 
                APIResponse cls_APIResponse = new APIResponse();
                cls_APIResponse.StatusCode = '805';
                cls_APIResponse.StatusMessage = excep.getMessage();
                cls_APIResponse.isSuccess = false;
                lst_APIResponses.add(cls_APIResponse);  

            }


        }
        // Return the API response. 
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lst_APIResponses));
    }
}