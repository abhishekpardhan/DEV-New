/**
 * Description		:		Future calss for calling google Distance Metrix API wile event CheckIn
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th july, 2019
 * Release          :       17th july, 2019
 * Last Modified on :       8th August, 2019
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
Public class DistanceCalculationApi {
    
    @future (callout=true)
    public Static void TotalArea(Id eventId){
        system.debug('In The API');
        String key =  System.Label.MapKey;
        String Origins ='';
        String Destinations ='';
        String Distance1 = '';
        String Distance2 = '';
        String Address1 = '';
        try{
            Event__c curEvent = [Select Id,Is_Claim__c ,ownerId,Campaign__c,Activity__c,Account__c,recordTypeId,CheckIn_Date__c,CheckIn_Address__c,                            
                             CheckOut_Address__c,Remarks__c,Status__c,CheckOut_Date__c,CheckIn_Location__c ,CheckOut_Location__c,Distance__c,
                             Journey__c from Event__c where Id =:eventId limit 1];
        // Querry to check if the journey has existing event or not
        List<Journey__c> relJourney = [Select Id,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c, CheckIn_Address__c,                            
                                       CheckOut_Address__c,(Select Id,CheckIn_Date__c ,CheckOut_Date__c,CheckIn_Address__c,                            
                                                            CheckOut_Address__c,CheckIn_Location__c ,
                                                            CheckOut_Location__c from Events__r where CheckOut_Date__c != null 
                                                            order by CheckOut_Date__c DESC limit 1)
                                       from Journey__C where Id =: curEvent.Journey__c limit 1];  
        
        // method to call distance matrix API if Journey has existing event
        // this method will calculate the distance between existing event checkout geolocation and new event checkIn location
        if(relJourney[0].Events__r.size() > 0){            
            Destinations = curEvent.CheckIn_Location__c;     
            Origins = relJourney[0].Events__r[0].CheckOut_Location__c;
            system.debug('In the first loop');
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://maps.googleapis.com/maps/api/distancematrix/json?&origins='+Origins+'&destinations='+Destinations+'&key='+Key+'');
            system.debug('Request sent');
            request.setMethod('GET');
            HttpResponse response = http.send(request); 
            ExceptionHandling.createAPILog('DistanceCalculationAPI-'+ relJourney[0].Events__r[0].id , 'https://maps.googleapis.com/maps/api/distancematrix/json?&origins='+Origins+'&destinations='+Destinations+'&key='+Key+'',request.getBody(),response.getBody(),response.getStatusCode());
            if (response.getStatusCode() == 200) {
                JSONParser parser = JSON.createParser(response.getBody());
                system.debug('got responce');
                while (parser.nextToken() != null){
                    system.debug('in while loop');
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                        (parser.getText() == 'destination_addresses')) {
                            parser.nextToken();
                            parser.nextToken();
                            curEvent.CheckIn_Address__c= parser.getText();
                            system.debug('Address1'+ curEvent.CheckIn_Address__c);
                        }
                    else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                             (parser.getText() == 'origin_addresses')) {
                                 parser.nextToken();
                                 parser.nextToken();
                                 relJourney[0].Events__r[0].CheckOut_Address__c = parser.getText(); 
                                 system.debug('Address2'+ relJourney[0].Events__r[0].CheckOut_Address__c);
                                 //     system.debug('CheckOut Geolocation'+ relJourney[0].Events__r[0].CheckOut_Location__c);
                             } 
                    else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                             (parser.getText() == 'distance')){
                                 system.debug('in if loop');
                                 parser.nextToken();
                                 parser.nextToken();
                                 parser.nextToken();
                                 system.debug('Doing Parsing');
                                 Distance1 = parser.getText();
                                 if(Distance1.Contains('km')){ // checking if responce is in KM or M
                                     Distance2 = Distance1.replace('km','');
                                 curEvent.Distance__c = Double.valueOf(Distance2);
                                 system.debug('curEvent.Distance__c'+curEvent.Distance__c);
                                 }else{ // roundingOff the distance to zero if responce is in Meters
                                     curEvent.Distance__c = 0;
                                 system.debug('curEvent.Distance__c'+curEvent.Distance__c);
                             }
                             }
                }
                update curEvent;
                update relJourney[0].Events__r[0];
            }else{
                System.enqueueJob(new AddressCalculationQueueable(eventId, null, false, 'checkin' ));
            }
        }
         // method to call distance matrix API if Journey has no existing event
        // this method will calculate the distance between Journey checkin geolocation and new event checkIn location
        else{
            Origins = relJourney[0].CheckIn_Location__c;
            Destinations = curEvent.CheckIn_Location__c;
            system.debug('In the Second loop');
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://maps.googleapis.com/maps/api/distancematrix/json?&origins='+Origins+'&destinations='+Destinations+'&key='+Key+'');
            system.debug('Request sent');
            request.setMethod('GET');
            HttpResponse response = http.send(request); 
            ExceptionHandling.createAPILog('DistanceCalculationAPI-'+ relJourney[0].id , 'https://maps.googleapis.com/maps/api/distancematrix/json?&origins='+Origins+'&destinations='+Destinations+'&key='+Key+'',request.getBody(),response.getBody(),response.getStatusCode());
            if (response.getStatusCode() == 200) {
                JSONParser parser = JSON.createParser(response.getBody());
                system.debug('got responce');
                while (parser.nextToken() != null){
                    system.debug('in while loop');
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                        (parser.getText() == 'destination_addresses')) {
                            system.debug('in while loop1');
                            parser.nextToken();
                            parser.nextToken();
                            curEvent.CheckIn_Address__c = parser.getText();
                            system.debug('Address1'+ curEvent.CheckIn_Address__c);
                        }
                    else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                             (parser.getText() == 'origin_addresses')) {
                                 system.debug('in while loop2');
                                 parser.nextToken();
                                 parser.nextToken();
                                 system.debug('Address2'+parser.getText());
                                 relJourney[0].CheckIn_Address__c = parser.getText();
                                 
                                 
                             } 
                    else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                             (parser.getText() == 'distance')){
                                 system.debug('in if loop');
                                 parser.nextToken();
                                 parser.nextToken();
                                 parser.nextToken();
                                 system.debug('Doing Parsing');
                                 Distance1 = parser.getText();
                                 if(Distance1.Contains('km')){   // checking if responce is in KM or M
                                     Distance2 = Distance1.replace('km','');
                                     system.debug('Contain km in distance'+Distance2);
                                     curEvent.Distance__c = Double.valueOf(Distance2);
                                     system.debug('curEvent.Distance__c'+curEvent.Distance__c);
                                 }
                                 else{ // roundingOff the distance to zero if responce is in Meters 
                                     curEvent.Distance__c = 0;
                                     system.debug('curEvent.Distance__c'+curEvent.Distance__c);
                                 }
                             }
                }
            }
            update curEvent;
            update relJourney;
        }
        } catch(Exception e){ // Added by shubham Girdhar reffering jira ticket: SD-417
          // method to handle exception added by Shubham Girdhar on 26/7/2019
          /*  ExceptionHandler__c exc = new ExceptionHandler__c();
            exc.Name = 'Event';
            exc.Class_Name__c = 'DistanceCalculationApi';
            exc.Error_Message__c = e.getMessage();
            exc.Exception_Time__c = System.now();
            exc.Exception_Type__c = e.getTypeName();
            exc.Line_Number__c = e.getLineNumber();
            exc.User__c = UserInfo.getUserName();
            insert exc;  
            */
            String name = 'Event';
            String ClassName = 'DistanceCalculationApi';
            ExceptionHandling.Exception( name, ClassName, e);
 }
     }
}