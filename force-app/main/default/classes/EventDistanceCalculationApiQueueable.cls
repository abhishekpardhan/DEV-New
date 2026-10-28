public class EventDistanceCalculationApiQueueable implements Queueable, Database.AllowsCallouts {
    public List<Event__c> lstEvent = new List<Event__c>();
    public Id eventId;
    
    public EventDistanceCalculationApiQueueable(List<Event__c> lstEvent){
        this.lstEvent = lstEvent;
    }
    
    public void execute(QueueableContext context){
        
        String key =  System.Label.MapKey;
        String Origins ='';
        String Destinations ='';
        String Distance1 = '';
        String Distance2 = '';
        String Address1 = '';
        try{
            Event__c curEvent = lstEvent[0];
            
            
            system.debug('curEvent---->'+curEvent);
            // Querry to check if the journey has existing event or not
            List<Journey__c> relJourney = [Select Id,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c, CheckIn_Address__c,                            
                                           CheckOut_Address__c,(Select Id,CheckIn_Date__c ,CheckOut_Date__c,CheckIn_Address__c,                            
                                                                CheckOut_Address__c,CheckIn_Location__c ,
                                                                CheckOut_Location__c from Events__r where CheckOut_Date__c != null AND Name != 'System Event'
                                                                AND CheckOut_Date__c <: curEvent.CheckOut_Date__c
                                                                order by CheckOut_Date__c DESC limit 1)
                                           from Journey__C where Id =: curEvent.Journey__c limit 1];  
            system.debug('relJourney---->'+relJourney);
            
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
        } catch(Exception e){ 
            String name = 'Event';
            String ClassName = 'DistanceCalculationApi';
            ExceptionHandling.Exception( name, ClassName, e);
        }
        
        if(this.lstEvent.size() > 0 && !Test.isRunningTest()){
            this.lstEvent.remove(0);
            System.debug('this.lstEvent-->'+this.lstEvent);
            if(this.lstEvent.size() > 0){
                System.enqueueJob(new EventDistanceCalculationApiQueueable(this.lstEvent));
            } 
        }   
        
        
    }
    
}