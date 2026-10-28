/**
 * Description      :   Class to send the SMS to user according to specified phone number
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
public class EventLeadHandler {
    
    /**
     * Method to send the SMS on specific mobile numbers by hitting api
     **/
    @future(callout=true)
    public static void sendSMS(List<String> lstMobile){
        
        String smsEndPoint = System.label.SMS_End_Point;
        String paramter1 = System.label.SMS_API_Parameter_1;
        String parameter2 = System.label.SMS_API_Parameter_2;
        String CustMsg = System.label.SMS_API_Messages;
        String str_smsKey = System.label.SMS_API_Key;
        System.debug('smsEndPoint------->'+smsEndPoint);
        System.debug('paramter1------->'+paramter1);
        System.debug('parameter2---------->'+parameter2);
        System.debug('CustMsg------------>'+CustMsg);
        System.debug('str_smsKey----->'+str_smsKey);
        for(String mob : lstMobile){
            System.debug('mob------------->'+mob);
            Http http = new Http();        
            HttpRequest request = new HttpRequest();
            
            request.setHeader('x-api-key', str_smsKey);
            String Endpoint = smsEndPoint+paramter1+mob+parameter2+CustMsg;
            //'https://api.safexpress.com/sms-uat/sendsms?receipientno='+mob+'&msgtxt=Thank you for contacting Safexpress. Your pickup request reference is REQ20181031000420. Our business representative will contact you shortly.';
            //As this SMS API has been decommisioned, therefore it is commented. 
            //'http://proton.safexpress.com/FareyeService/SfxDataSource.svc/SafexSmsApiJson?_sSMSText=Thank%20you%20for%20contacting%20Safexpress.%20For%20further%20information,%20please%20visit%20our%20website%20www.safexpress.com%20or%20email%20us%20at%20info@safexpress.com&_sMobile=';
            //Endpoint += mob;
            System.debug('Endpoint------------->'+Endpoint);
            request.setEndpoint(Endpoint);
            request.setMethod('GET');                         
            HttpResponse response = http.send(request);
            // Parse the JSON response    
            system.debug('response++'+response.getStatusCode()+response.getBody());
            if (response.getStatusCode() != 200) {
            }
        }
    }
}