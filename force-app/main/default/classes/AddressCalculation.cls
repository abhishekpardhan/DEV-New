/**
* Description		:		Calling google Distance Matrix API for CheckIn address of Journey & CheckOut address of event
* Created By       :       Raghav, IBM
* Created Date     :       7th, Feb, 2024
* Release          :       
* Last Modified on :      13th, Feb, 2024
* Jira Ticket      :     https://safexpress.atlassian.net/browse/SAC-365
**/

public class AddressCalculation {
    public static HttpRequest request_build(String url){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        return request;
    }
    public static String parseAddress(HttpResponse response, String token){
        JSONParser parser = JSON.createParser(response.getBody());
        parser.nextToken();
        while(parser.hasCurrentToken()){
            if(parser.getText()==token){
                System.debug('Addresss token ->'+parser.getText());
                break;
            }
            parser.nextToken();
        }
        parser.nextToken();
        parser.nextToken();
        System.debug('Address Value ->'+parser.getText());
        return parser.getText();
    }
    
    
    public static string getAddress(String destination){
        String key =System.Label.MapKey;
        String Origins =destination;
        String Destinations =destination;
        String url= 'https://maps.googleapis.com/maps/api/distancematrix/json?&origins='+Origins+'&destinations='+Destinations+'&key='+Key+'';
        Http http = new Http();
        HttpRequest request =request_build(url);
        HttpResponse response = http.send(request);
        String address = '';
        if (response.getStatusCode()==200){
            address = parseAddress(response,'destination_addresses');
        }
        ExceptionHandling.createAPILog('AddressCalculation', url,request.getBody(),response.getBody(),response.getStatusCode());
        return address;
    }   
     
}