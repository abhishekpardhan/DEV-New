/**
    * @File Name          : HttpUtility.cls
    * @Description        : This class is Utility Class for HTTP methods
    * @Author             : Deepak
    * @Group              : Techmatrix
    * @Last Modified By   : Deepak
    * @Last Modified On   : 23-07-2021
    * @Modification Log   :
    *==============================================================================
    * Ver         Date                     Author                 Modification
    *==============================================================================
    * 1.0         07-07-2021              Deepak                 Initial Version
 */

public class HttpUtility {

    /**
   @Author          : Deepak
   @Company         : TechMatrix Consulting
   @Description     : This method is used create the HTTP Request and return the  HttpRequest Instance
   @Date            : 07/07/2021
  */
    public static HttpRequest getHttpRequest(String endpoint, String method, String otherHeaderKey, String otherHeaderValue, String requestBody, String contentType,Blob requestBodyBlob) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(method);
        httpRequest.setEndpoint(endpoint);
        if (requestBody != null) {
            httpRequest.setBody(requestBody);
        }
        if(contentType !=null){
            httpRequest.setHeader('Content-Type', contentType);
        }
        if (otherHeaderKey != null && otherHeaderValue != null) {
            httpRequest.setHeader(otherHeaderKey, otherHeaderValue);
        }
        if (requestBodyBlob != null) {
            httpRequest.setBodyAsBlob(requestBodyBlob);
        }
        httpRequest.setTimeout(ConstantUtility.CALLOUT_TIME_OUT_IN_MS);
        return httpRequest;
    }

    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used create the Make the HTTP Callout and return the HttpResponse Instance
    @input           : This method is used take HttpRequest instance for callout and  apiName for log purpose
    @Date            : 07/07/2021
    */
    public static HttpResponse makeCallout(HttpRequest request,String apiName) {
        try {
            Http http = new Http(); 
            HttpResponse response = http.send(request);
            if(apiName !=null){
                LoggerUtil.createAPILog(apiName,request.getEndpoint(),request.getBody(),response.getBody(),response.getStatusCode());
            }
            return response;
        } catch (CalloutException exp) {
            System.debug(' Exception Message ::' + exp.getMessage() + ' Class Name : HttpUtility at Line ::' + exp.getLineNumber());
            LoggerUtil.createErrorLog('HttpUtility', 'makeCallout', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        return null;
    }
    
     /**
    @Author          : Manshi
    @Company         : IBM
    @Description     : This method is used to return hashMap from response data
    @Date            : 18/06/2025
    */
    public static String createHashMap(String jsonPart){
        jsonPart = '{"' + jsonPart;
        // Parse the JSON into a generic map
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonPart);
        // Remove value of Ticket.Title
        if (jsonMap.containsKey('Ticket')) {
            Map<String, Object> ticket = (Map<String, Object>) jsonMap.get('Ticket');
            if (ticket.containsKey('Title')) {
                ticket.put('Title', ''); // Empty value
            }
        } 
        // Remove value of Article.Subject and Article.Body
        if (jsonMap.containsKey('Article')) {
            Map<String, Object> article = (Map<String, Object>) jsonMap.get('Article');
            if (article.containsKey('Subject')) {
                article.put('Subject', '');
            }
            if (article.containsKey('Body')) {
                article.put('Body', '');
            }
        }
        // Optionally serialize back to JSON
        String updatedJson = JSON.serialize(jsonMap);    
        Blob bodyBlob = Blob.valueOf(updatedJson);
        // Sending the API Request
        String hash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', bodyBlob));
        return hash;
    }
}