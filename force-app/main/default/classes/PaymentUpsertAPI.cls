//Rest resource to upsert Payment__c records within SFDC
@RestResource(urlMapping='/SFXPaymentCreate/*')
global with sharing class PaymentUpsertAPI {
    
    //Wrapper class to send the response in jSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        String compositeKey;
        Boolean isCreated;
        Boolean isSuccess;
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
        Integer Doc_ID;
        String compositeKey;
    }
    
    //POST request method to upsert Payment records and sending response in return
    @HttpPost
    global static void createPayment(List<PaymentUpsertAPI.jsonWrap> pymtRecords) {
        Payment__c[] pymts = new Payment__c[]{};
            for(PaymentUpsertAPI.jsonWrap i : pymtRecords) {
                pymts.add(new Payment__c(Bill_ID__c = i.Bill_ID,
                                     Bill_Number__c = i.Bill_Number,
                                     Receipt_Number__c = i.Receipt_Number,
                                     Received_Freight_Amount__c = i.Received_Freight_Amount,
                                     Received_Freight_TDS_Amount__c = i.Received_Freight_TDS_Amount,
                                     Received_OCT_Amount__c = i.Received_OCT_Amount,
                                     Installment_Reference_Date__c = i.Installment_Ref_Date,
                                     Created_Date__c   = i.Created_Date,
                                     Installment_Type__c = i.Installment_Type,
                                     Installment_Reference__c = i.Installment_Reference,
                                     Invoice__r = new Invoice__c(Propel_ID__c = i.Bill_ID),
                                     Receipt_id__c = i.Receipt_Id,
                                     Status_Lid__c = i.Status_Lid,
                                     Updated_Date__c = i.Updated_Date,
                                     Deviation_Id__c = i.Deviation_Id,
                                     Deviation_Date__c = i.Deviation_Date,
                                     Cheque_Dishonor_Remarks__c = i.Cheque_Dishonor_Remarks,
                                     Deviation_Type__c = i.Deviation_Type,
                                     Doc_id__c = i.Doc_ID,
                                     Composite_Key__c = i.Bill_ID + '-' + i.Doc_ID));
            }
        Database.UpsertResult[] results = Database.upsert(pymts, Payment__c.Fields.Composite_Key__c, false);
 
        List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
        for(Integer index = 0, size = results.size(); index < size; index++) {
        JsonUpsertResult resultRow = new JsonUpsertResult();
        resultRow.Errors =  results[index].getErrors();
        resultRow.SFId = results[index].getId();
        resultRow.compositeKey = pymts[index].Composite_Key__c;
        resultRow.isCreated = results[index].isCreated();
        resultRow.isSuccess = results[index].isSuccess();
        lstJsonUpsertResult.add(resultRow);
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
    }
}