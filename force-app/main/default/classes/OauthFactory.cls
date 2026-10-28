public class OauthFactory implements Database.AllowsCallouts {

    public static HttpResponse deleteToken(OauthToken oto){
        String URL = URL.getSalesforceBaseUrl().toExternalForm();
        String urlRevoke = '/services/oauth2/revoke?token=';
        String tokenEncode = '';
        if(oto.DeleteToken != null){
            tokenEncode = EncodingUtil.URLENCODE(oto.DeleteToken,'UTF-8');
        }

        URL += urlRevoke += tokenEncode;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse res = http.send(req);  
        return res;
    }

}