/**
 * @File Name          : GetInvoiceUrl.cls
 * @Description        : GetInvoiceUrl class take waybill no. as input and return back Invoice Pdf URL
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 01/12/2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        01/12/2021                Deepak                   Initial Version
**/

public with sharing class GetInvoiceUrl {
    @InvocableMethod(label='Get Invoice URL')
    public static List<String> getInvoiceUrl(List<String> wayBills) {
        try {
            List<String> outputStrings = new List<String>();
            List<Safex_API__c> wayApiInfo = QueryUtil.getSafexApiInfo(ConstantUtility.INVOICE_URL_API_NAME);
            if (wayApiInfo.size() > 0 && wayApiInfo[0].Endpoint__c != null && wayApiInfo[0].Access_Key__c != null && wayApiInfo[0].Authorisation_Type__c != null) {
                String endPoint = wayApiInfo[0].Endpoint__c + wayBills[0];
                HttpRequest request = HttpUtility.getHttpRequest(endPoint, ConstantUtility.GET, wayApiInfo[0].Authorisation_Type__c, wayApiInfo[0].Access_Key__c, null, ConstantUtility.APPLICATION_JSON, null);
                HttpResponse response = HttpUtility.makeCallout(request, 'Invoice URL API');
                if (response.getStatusCode() == 200) {
                    ResponseWrapper responseWrapper = (ResponseWrapper) System.JSON.deserialize(response.getBody(), ResponseWrapper.class);
                    if (responseWrapper.status == 'success') {
                        outputStrings.add(responseWrapper.output);
                    } else {
                        outputStrings.add('null');
                    }
                }
            } else {
                outputStrings.add(ConstantUtility.INVALID_ACCESS_TOKEN_ERROR);
            }
            return outputStrings;
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : GetInvoiceUrl at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('GetInvoiceUrl', 'getInvoiceUrl', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        return null;
    }
    public class ResponseWrapper {
        public String output ;
        public String status;
    }
}