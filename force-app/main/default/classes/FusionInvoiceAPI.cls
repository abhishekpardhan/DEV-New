/**
    @Description          : This API class is use to send Fusion_Invoice__c record to fusion
    * @Author             : Shubham 
    * @Group              : Safexpress
    * @Last Modified By   : Shubham
    * @Last Modified On   : 17-Feb-21
    * @Modification Log   :
    *==============================================================================
    * Ver         Date                     Author                    Modification
    *==============================================================================
    * 1.0        17-Feb-21                Shubham                   Initial Version
    * 2.0        13-Jan-22                Shubham                   converted it to realtime 
**/
public class FusionInvoiceAPI {
    @future(callout=true)
    public static void invoiceFromSF(id invoiceId){
        
        String Endpoint = System.Label.Fusion_Test_Endpoint; 
        String Username = System.Label.FUsion_Test_Username;
        String Password = System.Label.Fusion_Test_Password;
        Integer num =  Integer.valueof(system.label.FusionInvoiceAPILimit.trim());
        system.debug('LIMIT'+ num);
        
        list<Fusion_Invoice__c> FI = new list<Fusion_Invoice__c>();
        list<Fusion_Invoice__c> updateFI = new list<Fusion_Invoice__c>(); 
        
        FI = [select id, name,Amount__c,PaymentMethod__c,Date__c,Supplier__c,Supplier_Site__c,Description__c,Payment_Terms__c,PayGroup__c,Accounting_Date__c,Type__c,Invoice_Group__c from Fusion_Invoice__c where Fusion_Invoice_Id__c = null and Id =: invoiceId ];
        system.debug('FI:  '+FI);
        for(Fusion_Invoice__c inv: FI){ 
            list <Line_and_Distribution__c> lines = new list <Line_and_Distribution__c>();
            lines = [select id,Name,Line_Number__c,Line_Amount__c,Distribution_Line_Number__c,Distribution_Combination__c,Distribution_Amount__c from Line_and_Distribution__c where Fusion_Invoice__c =:inv.Id];
            system.debug('LINES:  '+lines); 
            
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            if(inv.name != null){
                gen.writeStringField('InvoiceNumber', inv.name);
            }
            else{
                gen.writeStringField('InvoiceNumber', '');
            }
            gen.writeStringField('InvoiceCurrency', 'INR');
            if(inv.Amount__c != null){
                gen.writeNumberField('InvoiceAmount', inv.Amount__c);
            }
            else{
                gen.writeNumberField('InvoiceAmount', 0);
            }
            if(inv.Date__c != null){
                gen.writeDateField('InvoiceDate', inv.Date__c);
            }
            else{
                gen.writeDateField('InvoiceDate', date.today());
            }
            if(inv.Accounting_Date__c != null){
                gen.writeDateField('AccountingDate',inv.Accounting_Date__c);
            }
            else{
                gen.writeDateField('AccountingDate', date.today());
            }
            if(inv.PaymentMethod__c != null){
                gen.writeStringField('PaymentMethod', inv.PaymentMethod__c );
            }
            else{
                gen.writeStringField('PaymentMethod', '');
            }
            if(inv.Type__c != null){
                gen.writeStringField('InvoiceType', inv.Type__c);
            }
            else{
                gen.writeStringField('InvoiceType', '');
            }
            gen.writeStringField('BusinessUnit', 'SAFEXPRESS');
            if(inv.Supplier__c != null){
                gen.writeStringField('Supplier', inv.Supplier__c);
            }
            else{
                gen.writeStringField('Supplier', '');
            }
            if(inv.Supplier_Site__c != null){
                gen.writeStringField('SupplierSite', inv.Supplier_Site__c);
            }
            else{
                gen.writeStringField('SupplierSite', '');
            }if(inv.Invoice_Group__c != null){
                gen.writeStringField('InvoiceGroup', inv.Invoice_Group__c);
            }else{
                gen.writeStringField('InvoiceGroup', '');        
            }
            if(inv.Description__c != null){
                gen.writeStringField('Description', inv.Description__c);
            }
            else{
                gen.writeStringField('Description', '');
            }
            if(inv.Payment_Terms__c!= null){
                gen.writeStringField('PaymentTerms', inv.Payment_Terms__c);
            }
            else{
                gen.writeStringField('PaymentTerms', '');
            }
            if(inv.PayGroup__c != null){    
                gen.writeStringField('PayGroup', inv.PayGroup__c);
            }
            else{
                gen.writeStringField('PayGroup', '');
            }
            gen.writeFieldName('invoiceDff');
            gen.writeStartArray();
            gen.writeStartObject();
            //  gen.writeStringField('ngTestApi', 'RESTAPI');
            //  gen.writeStringField('__FLEX_Context', 'Ship to State');
            gen.writeStringField('__FLEX_Context_DisplayValue', 'Ship to State');
            gen.writeStringField('shipToState', '06');
            gen.writeEndObject();
            gen.writeEndArray();
            
            
            gen.writeFieldName('invoiceLines');
            gen.writeStartArray();
            for(Line_and_Distribution__c ln : lines){
                gen.writeStartObject();
                if(ln.Line_Number__c != null){
                    gen.writeNumberField('LineNumber', ln.Line_Number__c);
                }
                else {
                    gen.writeNumberField('LineNumber', 0);
                }
                if(ln.Line_Amount__c != null){
                    gen.writeNumberField('LineAmount', ln.Line_Amount__c);
                }
                else{
                    gen.writeNumberField('LineAmount', 0);
                }
                
                gen.writeFieldName('invoiceDistributions');
                gen.writeStartArray();
                gen.writeStartObject();
                if(ln.Distribution_Line_Number__c != null){
                    gen.writeNumberField('DistributionLineNumber', ln.Distribution_Line_Number__c);
                }
                else{
                    gen.writeNumberField('DistributionLineNumber', 0);
                }
                gen.writeStringField('DistributionLineType', 'Item');
                if(ln.Distribution_Amount__c != null){
                    gen.writeNumberField('DistributionAmount', ln.Distribution_Amount__c);
                }
                else{
                    gen.writeNumberField('DistributionAmount', 0);
                }
                if(ln.Distribution_Combination__c != null){
                    gen.writeStringField('DistributionCombination', ln.Distribution_Combination__c);
                }
                else
                    gen.writeStringField('DistributionCombination', '');
                gen.writeEndObject();
                gen.writeEndArray();
                
                gen.writeEndObject();
                
            }
            
            gen.writeEndArray();
            
            gen.writeEndObject(); 
            
            String jsonString = gen.getAsString();
            system.debug('jsonString: '+jsonString);
            
            Http http = new Http();        
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Endpoint);
            request.setMethod('POST');
            request.setbody(jsonString);        
            request.setHeader('Content-Type', 'application/json');
            Blob headerValue = Blob.valueOf(Username + ':' + Password);
            system.debug('headerValue: ' +headerValue);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            system.debug('authorizationHeader: ' +authorizationHeader);
            request.setHeader('Authorization', authorizationHeader);
            //request.setbody();        
            request.setTimeout(100000);
            HttpResponse response = http.send(request); 
            system.debug('request: ' +request);
            system.debug('response: ' +response);
            if (response.getStatusCode() == 201) {
                jsonParser Jp = (jsonParser) System.JSON.deserialize(response.getBody(),jsonParser.class);                    
                system.debug('Jp: ' +Jp);     
                system.debug('Invoice id: '+Jp.InvoiceId); 
                inv.Fusion_Invoice_Id__c = Jp.InvoiceId;
                updateFI.add(inv);          
            }
            else{
               ExceptionHandling.createAPILog('FusionInvoiceAPI: '+ invoiceId ,Endpoint,request.getBody(),response.getBody(),response.getStatusCode());
                // inv.Failure_Reason__c = response.getBody();
               // updateFI.add(inv);  
            }
        }
        update updateFI;
    }
    //JSONParser
    public class jsonParser{
        public String InvoiceId;
    }
}