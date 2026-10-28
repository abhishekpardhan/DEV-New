/**
 * Description      :   Rest resource to upsert the Debit_Credit_Note__c within SFDC from third party system
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
@RestResource(urlMapping='/SFXDebitCreditNoteCreate/*')
global with sharing class DebitCreditNoteAPI {
    
    //Wrapper class
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        String compositeKey;
        Boolean isCreated;
        Boolean isSuccess;
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
        public String E_Bill;
        public String Submitted_to_Email_IDs;
        public String BDM_Email_IDs;
    }
    
    /**
     * POST request method to create Debit_Credit_Note__c records
     **/
    @HttpPost
    global static void createDebitCreditNote(List<DebitCreditNoteAPI.jsonWrap> dcnRecords) {
        Debit_Credit_Note__c[] dcns = new Debit_Credit_Note__c[]{};
            for(DebitCreditNoteAPI.jsonWrap i : dcnRecords) {
                dcns.add(new Debit_Credit_Note__c(ID__c = i.ID, 
                                     Document_Type__c = i.Document_Type,
                                     Document_Type_ID__c = i.Document_Type_ID,
                                     Note_Number__c = i.Note_Number,
                                     Invoice_Name__r = new Invoice__c(Propel_ID__c  = i.Bill_ID),
                                     Bill_Number__c = i.Bill_Number,
                                     Remarks__c = i.Remarks,
                                     Note_Type__c = i.Note_Type,
                                     Note_Amount_Total__c = i.Note_Amount_Total,
                                     Created_Date__c = i.Created_Date,
                                     Update_Date__c = i.Update_Date,
                                     IGST__c = i.IGST,
                                     CGST__c = i.CGST,
                                     SGST__c = i.SGST,
                                     Composite_Key__c = i.ID + '-' + i.Bill_ID));
            }
        Database.UpsertResult[] results = Database.upsert(dcns, Debit_Credit_Note__c.Fields.Composite_Key__c, false);
 
        List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
        for(Integer index = 0, size = results.size(); index < size; index++) {
        JsonUpsertResult resultRow = new JsonUpsertResult();
        resultRow.Errors =  results[index].getErrors();
        resultRow.SFId = results[index].getId();
        resultRow.CompositeKey = dcns[index].Composite_Key__c;
        resultRow.isCreated = results[index].isCreated();
        resultRow.isSuccess = results[index].isSuccess();
        lstJsonUpsertResult.add(resultRow);
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
    }
}