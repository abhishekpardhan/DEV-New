/*-----------------------------------------------------------------------------------
 * Author:Safexpress
 * Description: implemented to make the propel-I callout. 
 * Test Class:
 * Code Coverage:
 * History:
 * Modified Date :              
 * Description:
 * Modified By:
 * 
 -----------------------------------------------------------------------------------*/ 
public class cls_PropelICallout {
    
    // implemented to make the callout to propel-I system to generate the token
    Public Static HttpResponse propelITokenCallout(String username, String password, String method, String body, String endPoint)
    {
        System.debug('username-------------->'+username);
        System.debug('password-------------------->'+password);
        System.debug('method-------------->'+method);
        System.debug('body--------------->'+body);
        //make http request
        HttpRequest htpReq = new HttpRequest();
        Blob bbUserPass = Blob.valueOf(username+':'+password);
        String str_auth = EncodingUtil.base64Encode(bbUserPass);
        System.debug('str_auth------------------->'+str_auth);
        htpReq.setEndpoint(endPoint);
        String payLoad = 'grant_type=client_credentials';
        htpReq.setMethod(method);
        htpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        htpReq.setHeader('Authorization',' Basic '+str_auth);
        htpReq.setBody(payLoad);
        System.debug('htpReq--------------->'+htpReq);
        //send request to proepl-I.
        http htp = new Http();
        HttpResponse htpRes = htp.send(htpReq);
        System.debug('htpRes---------->'+htpRes);
        return htpRes;        
    }
    // implemented to make the callout to propel-I system to pull the sales data.
  /*  Public Static HttpResponse PropelISalesData_Callout(String auth, String userId, String xAPIKey, String contentType,String method, String endPoint)
    {
        System.debug('auth--------------->'+auth);
        System.debug('userId----------->'+userId);
        System.debug('xAPIKey------------->'+xAPIKey);
        System.debug('contentType--------------->'+contentType);
        System.debug('method-------------->'+method);
        System.debug('endPoint------------->'+endPoint);
        HttpRequest htpReq = new HttpRequest();
        htpReq.setMethod(method);
        htpReq.setHeader('Authorization', auth);
        htpReq.setHeader('userId', userId);
        htpReq.setHeader('x-api-key', xAPIKey);
        htpReq.setHeader('Content-Type', contentType);
        htpReq.setEndpoint(endPoint);
        //Make callout
        Http htp = new Http();
        HttpResponse htpRes = htp.send(htpReq);
        return htpRes;
    }  */

}