HttpRequest request = new HttpRequest();
request.setEndpoint('callout:Propeli_Token_API/oauth2/token');
request.setMethod('POST');
request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
request.setTimeout(7000);
request.setBody('grant_type=client_credentials&scope=' +
    EncodingUtil.urlEncode('authtest/waybillapps', 'UTF-8'));

try {
    HttpResponse response = new Http().send(request);
    System.debug(LoggingLevel.ERROR, 'TOKEN TEST STATUS=' + response.getStatusCode());
    System.debug(LoggingLevel.ERROR, 'TOKEN TEST BODY OMITTED');
} catch (Exception ex) {
    System.debug(LoggingLevel.ERROR, 'TOKEN TEST EXCEPTION TYPE=' + ex.getTypeName());
    System.debug(LoggingLevel.ERROR, 'TOKEN TEST EXCEPTION MESSAGE=' + ex.getMessage());
}
