public with sharing class PropeliCancelledInvoiceService {
    public static void getCancelledInvoices(String fromDate, String toDate) {
        
        if(!isValidFromToDate(String.valueOf(fromDate), String.valueOf(toDate))) {
            return;
        }

        try {
            
            String accessToken = getToken();
            if(accessToken == null) {
                return;
            }
            List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem> results = new List<PropeliCancelledInvoiceWrappers.CancelledInvoiceItem>();
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.Label.Cancel_Invoices_Endpoint);
            req.setMethod('POST');
            req.setTimeout(60000);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-api-key', System.Label.API_KEY);
            req.setHeader('Authorization', 'Bearer ' + accessToken);

            req.setBody('{"fromDate":"'+fromDate+'","toDate":"'+toDate+'"}');

            HttpResponse res = http.send(req);
            if(res.getStatusCode() == 200) {
                PropeliCancelledInvoiceWrappers.CancelledInvoiceResponse responseWrapper =(PropeliCancelledInvoiceWrappers.CancelledInvoiceResponse)JSON.deserialize(
                        res.getBody(),
                        PropeliCancelledInvoiceWrappers.CancelledInvoiceResponse.class
                    );
                    
                System.debug('Total Records: ' + responseWrapper.data.size());
                
                System.debug(responseWrapper.data);
                if(responseWrapper != null && responseWrapper.status == 'SUCCESS' ) {
                    results = responseWrapper.data;
                } else {
                    ExceptionHandling.Exception( 'PropeliCancelledInvoiceService', 'PropeliCancelledInvoiceService', 'Failed to fetch cancelled invoices from Propeli. Status: ' + responseWrapper.status + ', Response Body: ' + responseWrapper.message);
                    return;
                }
            } else {
                ExceptionHandling.Exception( 'PropeliCancelledInvoiceService', 'PropeliCancelledInvoiceService', 'Failed to fetch cancelled invoices from Propeli. Status Code: ' + res.getStatusCode() + ', Response Body: ' + res.getBody());
                return;
            }
            
            if(!results.isEmpty() && !Test.isRunningTest()) {
                Database.executeBatch(
                    new BatchPropeliCancelledInvoices(results),
                    200
                );
            }
        } catch (Exception ex) {
            ExceptionHandling.Exception( 'PropeliCancelledInvoiceService', 'PropeliCancelledInvoiceService' , ex.getMessage());
        }
    }

    public static String getToken() {
        String accessToken;
        try {
            String tokenEndpoint = system.label.PropeliTokenEndpoint;
            String username = system.label.Propeli_Username;
            String password = system.label.Propeli_Password;
            HttpResponse res = cls_PropelICallout.propelITokenCallout(
               username, password, 'POST', '', tokenEndpoint
            );

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                accessToken = (String) responseMap.get('access_token');
            } else {
                ExceptionHandling.Exception( 'PropeliCancelledInvoiceService', 'getToken', 'Failed to fetch token from Propeli. Status Code: ' + res.getStatusCode() + ', Response Body: ' + res.getBody());
            }
            return accessToken;
        } catch (Exception ex) {
            ExceptionHandling.Exception( 'PropeliCancelledInvoiceService', 'getToken', ex.getMessage());
            return null;
        }
    }

    public static Boolean isValidFromToDate(String fromDate, String toDate) {
        try {
            
            Pattern pattern = Pattern.compile('\\d{2}-\\d{2}-\\d{4}');
            if (!pattern.matcher(fromDate).matches() || 
                !pattern.matcher(toDate).matches()) {

                ExceptionHandling.Exception(
                    'PropeliCancelledInvoiceService', 
                    'isValidFromToDate', 
                    'Date must be in format dd-MM-yyyy'
                );
                return false;
            }

            List<String> fromParts = fromDate.split('-');
            List<String> toParts = toDate.split('-');

            Date fromDt = Date.newInstance(
                Integer.valueOf(fromParts[2]),
                Integer.valueOf(fromParts[1]),
                Integer.valueOf(fromParts[0])
            );

            Date toDt = Date.newInstance(
                Integer.valueOf(toParts[2]),
                Integer.valueOf(toParts[1]),
                Integer.valueOf(toParts[0])
            );

            if (toDt < fromDt) {
                ExceptionHandling.Exception(
                    'PropeliCancelledInvoiceService',
                    'isValidFromToDate',
                    'FromDate cannot be after ToDate'
                );
                return false;
            }

            return true;

        } catch (Exception e) {
            ExceptionHandling.Exception(
                'PropeliCancelledInvoiceService',
                'isValidFromToDate',
                'Invalid date value'
            );
            return false;
        }
    }
}