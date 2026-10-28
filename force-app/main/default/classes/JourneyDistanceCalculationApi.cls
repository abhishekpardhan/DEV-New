/**
* Description		:		Future calss for calling google Distance Metrix API wile Journey CheckOut
* Created By       :       Shubham Girdhar
* Created Date     :       10th july, 2019
* Release          :       17th july, 2019
* Last Modified on :
* Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
**/
public class JourneyDistanceCalculationApi {
    @future (callout=true)
    public Static void journeyArea(Id jourId){
        system.debug('In The API');
        String key =  System.Label.MapKey;
        String Origins ='';
        String Destinations ='';
        String Distance1 = '';
        String Distance2 = '';
        String Address1 = '';
        try{
            Journey__C curJourney = [Select Id,OwnerId ,CheckIn_Date__c,CheckIn_Location__c,CheckOut_Date__c,CheckOut_Location__c,CheckIn_Address__c,                            
                                     CheckOut_Address__c,Journey_Date__c,Journey_KM__c,
                                     (Select Id ,Distance__c,Is_Claim__c from Events__r)
                                     from Journey__C where Id =: jourId limit 1];
            //Querry to get last ecent from the journey which is already checkedOut    
            List<Event__c> lstexisEve = [Select Id,Start__c ,End__c ,CheckIn_Date__c ,CheckOut_Date__c,CheckOut_Location__c,CheckIn_Address__c,CheckOut_Address__c
                                         from Event__C where Journey__c =:jourId and CheckOut_Date__c != null order by CheckOut_Date__c DESC limit 1 OFFSET 1];
            // Querry to get Journey last Event event from the journey 
            List<Event__c> journeyLastEvent = [Select Id, name, checkIn_Location__c, checkOut_Location__c, CheckIn_Address__c, checkOut_Address__c,
                                               Distance__c from Event__c where journey__c=: jourId and name = 'System Event'];
            
            // Method to calculate the distance between event checkOut geolocation and Journey Checkin geolocation
            Destinations = curJourney.CheckOut_Location__c; 
            Origins = lstexisEve[0].CheckOut_Location__c;
            //  system.debug('In the first loop');
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://maps.googleapis.com/maps/api/distancematrix/json?&origins='+Origins+'&destinations='+Destinations+'&key='+Key+'');
            //  system.debug('Request sent');
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            ExceptionHandling.createAPILog('JourneyCheckOutAPI-'+ lstexisEve[0].id, 'https://maps.googleapis.com/maps/api/distancematrix/json?&origins='+Origins+'&destinations='+Destinations+'&key='+Key+'',request.getBody(),response.getBody(),response.getStatusCode());
            if (response.getStatusCode() == 200) {
                JSONParser parser = JSON.createParser(response.getBody());
                //      system.debug('got responce');
                while (parser.nextToken() != null){
                    //          system.debug('in while loop');
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                        (parser.getText() == 'destination_addresses')) {
                            parser.nextToken();
                            parser.nextToken();
                            curJourney.CheckOut_Address__c= parser.getText();
                            //                system.debug('Address1'+ curJourney.CheckOut_Address__c);
                        }
                    else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                             (parser.getText() == 'origin_addresses')) {
                                 parser.nextToken();
                                 parser.nextToken();
                                 lstexisEve[0].CheckOut_Address__c = parser.getText(); 
                                 //                   system.debug('Address2'+ lstexisEve[0].CheckOut_Address__c);
                                 
                             } 
                    else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                             (parser.getText() == 'distance')){
                                 //                 system.debug('in if loop');
                                 parser.nextToken();
                                 parser.nextToken();
                                 parser.nextToken();
                                 //               system.debug('Doing Parsing');
                                 Distance1 = parser.getText();
                                 
                                 if(Distance1.Contains('km')){ // checking if responce is in KM or M
                                     Distance2 = Distance1.replace('km','');
                                     //                 system.debug('Contain km in distance'+Distance2);
                                     journeyLastEvent[0].Distance__c = Double.valueOf(Distance2);
                                     //               system.debug('curEvent.Distance__c'+journeyLastEvent[0].Distance__c);
                                 }else{// RoundingOff the distance to zero if responce is im meter 
                                     
                                     journeyLastEvent[0].Distance__c = 0;
                                     //             system.debug('curEvent.Distance__c'+journeyLastEvent[0].Distance__c);
                                 }
                                 
                                 
                             }
                    // assigning same address to journey last event Checkin/checkout address field
                    journeyLastEvent[0].CheckIn_Address__c = journeyLastEvent[0].CheckOut_Address__c =  lstexisEve[0].CheckOut_Address__c;
                    
                    
                    
                }
                
                
                update lstexisEve;
                update journeyLastEvent;
                
                // Mathod to calculate total distance of events and update it into journey_km__c field
                AggregateResult[] totalDis  = [SELECT sum(Distance__c)avgDis FROM Event__c where Journey__C =:jourId and Is_Claim__c = true GROUP BY Journey__C];
                if(totalDis.size() > 0 && (Decimal)totalDis[0].get('avgDis') > 0){
                    curJourney.Journey_KM__c = ((Decimal)totalDis[0].get('avgDis')).round(System.RoundingMode.HALF_UP);
                    //       system.debug('!!!!!!!!!'+curJourney.Journey_KM__c);
                } 
                update  curJourney;
            }else{
                System.enqueueJob(new AddressCalculationQueueable(null, jourId, false, 'checkout' ));
            }
        } catch(Exception e){ // Added by shubham Girdhar reffering jira ticket: SD-417
            // method to handle exception added by Shubham Girdhar on 26/7/2019
            /* ExceptionHandler__c exc = new ExceptionHandler__c();
exc.Name = 'Journey';
exc.Class_Name__c = 'JourneyDistanceCalculationApi';
exc.Error_Message__c = e.getMessage();
exc.Exception_Time__c = System.now();
exc.Exception_Type__c = e.getTypeName();
exc.Line_Number__c = e.getLineNumber();
exc.User__c = UserInfo.getUserName();
insert exc; */
            String name = 'Journey';
            String ClassName = 'JourneyDistanceCalculationApi';
            ExceptionHandling.Exception( name, ClassName, e);   
        }
    }
}