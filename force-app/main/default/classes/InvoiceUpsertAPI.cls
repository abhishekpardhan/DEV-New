/**
 * Description		:		Rest resource to recieve the incoming flow of invoice records from propel and create corresponsing invoice records in Salesforce with compositekey as Propel_ID. 
 * Created By       :       Shubham Girdhar
 * Created Date     :       
 * Release          :       18th August, 2019
 * Last Modified on :       8th August, 2019
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
@RestResource(urlMapping='/SFXInvoiceCreate/*')
global with sharing class InvoiceUpsertAPI {
 
  private class JsonUpsertResult {
       List<Database.Error> Errors;
       String SFId;
       Decimal propelId;
       Boolean isCreated;
       Boolean isSuccess;
  }
  
  //Wrapper class
  global class jsonWrap {
        public String Bill_Number;
        public Integer Propel_ID;
        public String Description;
        public Integer Customer_Contract_ID;
        public String Customer_Contract_Code;
        public Integer Bill_Branch_ID;
        public Integer Collection_Branch_ID;
        public Integer Sub_Branch_Master_ID;
        public Decimal Charged_Freight_Amount;
        public Decimal Charged_ST_Amount;
        public Decimal Charged_Total_Amount;
        public Decimal Out_Oct_Amount;
        public Decimal Out_Total_Amount;
        public Integer Status_LID;
        public String Bill_Type_Flag;
        public Date Bill_From_Date;
        public Date Bill_To_Date;
        public Date Bill_Due_Date;
      	public Date Bill_Date;
        public Date Submission_Date;
        public String e_Bill;
        public String Submitted_to_Email_IDs;
        public String BDM_Email_IDs;
     }
    
    //POST Request method to upsert the invoices within SFDC
     @HttpPost
     global static void createInvoice(List<InvoiceUpsertAPI.jsonWrap> invRecords) {
          try{
                Invoice__c[] invoices = new Invoice__c[]{};
            for(InvoiceUpsertAPI.jsonWrap inv : invRecords) {
                Invoice__c newInvoice = new Invoice__c( 
                                     Propel_ID__c = inv.Propel_ID,
                                     Name = inv.Bill_Number,
                    				 Bill_Number__c = inv.Bill_Number,
                                     Description__c = inv.Description,
                                     Customer_Contract_ID__c = inv.Customer_Contract_ID,
                                     Customer_Contract_Code__c = inv.Customer_Contract_Code,
                                     Charged_Freight_Amount__c = inv.Charged_Freight_Amount,
                                     Charged_ST_Amount__c = inv.Charged_ST_Amount,
                                     Charged_Total_Amount__c = inv.Charged_Total_Amount,
                                     Out_Oct_Amount__c = inv.Out_Oct_Amount,
                                     Out_Total_Amount__c = inv.Out_Total_Amount,
                                     Status_LID__c = inv.Status_LID,                                     
                                     Bill_Type_Flag__c = inv.Bill_Type_Flag,
                                     Bill_From_Date__c = inv.Bill_From_Date,
                                     Bill_To_Date__c = inv.Bill_To_Date,
                                     Bill_Due_Date__c = inv.Bill_Due_Date,
                                     Bill_Date__c = inv.Bill_Date,   
                                     e_Bill__c = String.isBlank(inv.e_Bill) ? 'No' : inv.e_Bill,
                                     Remarks__c = inv.Submitted_to_Email_IDs,
                                     BDM_Email_IDs__c = inv.BDM_Email_IDs,
                                     Account__r = new Account(Composite_Key__c = inv.Customer_Contract_Code + '-' + String.valueOf(inv.Bill_Branch_ID)));
            if (!(inv.Bill_Branch_ID == null))
                newInvoice.Bill_Branch__r = new Branch_Master__c(Branch_ID__c = inv.Bill_Branch_ID);
            if (!(inv.Collection_Branch_ID == null))
                newInvoice.Collection_Branch__r = new Branch_Master__c(Branch_ID__c = inv.Collection_Branch_ID);
            if (!(inv.Sub_Branch_Master_ID == null))
                newInvoice.Sub_Branch_Master__r = new Branch_Master__c(Branch_ID__c = inv.Sub_Branch_Master_ID);
            invoices.add(newInvoice);
           	system.debug('In for Loop');
            }
            Database.UpsertResult[] results = Database.upsert(invoices, Invoice__c.Fields.Propel_ID__c, false);
           system.debug('Size of List:'+ invoices.size());
            List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
            for(Integer index = 0, size = results.size(); index < size; index++) {
                JsonUpsertResult resultRow = new JsonUpsertResult();
                resultRow.Errors =  results[index].getErrors();
                resultRow.SFId = results[index].getId();
           		system.debug('SFId:' +results[index].getId());
                resultRow.propelId = invoices[index].Propel_ID__c;
                resultRow.isCreated = results[index].isCreated();
           		system.debug('isSuccess:' +results[index].isCreated());
                resultRow.isSuccess = results[index].isSuccess();
           		system.debug('isSuccess:' +results[index].isSuccess());
                lstJsonUpsertResult.add(resultRow);
            }
           	system.debug('lstJsonUpsertResult:' +lstJsonUpsertResult);
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
    }catch(Exception e ){ // Added by shubham Girdhar reffering jira ticket: SD-417
        String name = 'Invoice';
            String ClassName = 'InvoiceUpsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);      
    }
     }
}