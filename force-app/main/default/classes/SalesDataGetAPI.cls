/**
 * Description      :   API to get sales data from propel-i to salesforce regularly
 * Release          :   17th may, 2021
 * Created by       :   Shubham Girdhar
 * Revision Logs    :   V_1.0 - Created
 **/
public class SalesDataGetAPI {

    @future(callout=true)
    public static void GetSalesData(){
     HttpRequest req = new HttpRequest();
req.setEndpoint(system.label.Sales_Data_API_Endpoint);
req.setMethod('GET'); 
        req.setTimeout(50000);
        list<Sales_Data__c> SDlist = new list<Sales_Data__c>();
String username = system.label.Sales_Data_API_Username;
String password = system.label.Sales_Data_API_Password;
Blob headerValue = Blob.valueOf(username + ':' + password);
String authorizationHeader = 'BASIC ' +
EncodingUtil.base64Encode(headerValue);
req.setHeader('Authorization', authorizationHeader);
Http http = new Http();
HTTPResponse res = http.send(req);
System.debug('@@@@@@@@@@@@@@@@@@@@@@@@'+res.getBody());   
        if (res.getStatusCode() == 200){
            JsonParser sales = (JsonParser) System.JSON.deserialize(res.getBody(),JsonParser.class);
            system.debug('%%%%%%%%%%%%%%%'+sales.data);
            if(sales.data.size() > 0){
            for(Salesdata sal : sales.data){
                 sales_Data__c newSalesData = new sales_data__c(
                 Total_Booked_Previous__c = sal.totalWaybillBookedPre,
                     MTD_Booked_Current__c = sal.mtdBookedCur,
                     Customer_Contract_ID__c = sal.contractId,
                     MTD_Booked_Previous__c = sal.mtdBookedPre,
                     Undelivered__c = sal.unDelivered,
                     MTD_Sale_Current__c = sal.mtdSalesCur,
                     Total_sale_Previous__C = sal.totalSalesPre,
                     MTD_Sale_Previous__c = sal.mtdSalesPre,
                     SFX_Code__c = sal.sfxCode,
                     Composite_Key__c = sal.sfxCode+'-'+String.valueOf(sal.bookingBranchId),
                Account__r = new Account(Composite_Key__c = sal.sfxCode+'-'+String.valueOf(sal.bookingBranchId))
                     );
             
                     SDlist.add(newSalesData);   
            }
            
        }else{
        system.debug('######### Not working');
        }
        }
       // insert SDlist;
        Database.UpsertResult[] results = Database.upsert(SDlist, sales_Data__c.Fields.Composite_Key__c, false); 
    }
    
    public class JsonParser{
		public String message;
        public list<Salesdata> data;
		public String responseId;
		public String status;
    }
  public class Salesdata{
		public Integer mtdBookedPre;
		public Integer mtdBookedCur;
		public Integer totalWaybillBookedPre;
		public Decimal totalSalesPre;
		public String bookingBranchName;
		public Decimal mtdSalesCur;
		public Integer bookingBranchId;
		public Decimal mtdSalesPre;
		public String sfxCode;
		public Integer unDelivered;
		public Integer contractId;
}
    
}