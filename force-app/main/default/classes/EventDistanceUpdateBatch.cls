public class EventDistanceUpdateBatch implements Database.Batchable<sObject> , Database.Allowscallouts{
    public Boolean isEvent;
    public String query;
   	public EventDistanceUpdateBatch(Boolean isEvent, String query){
        this.isEvent=isEvent;
        this.query = query;
    }
    // public String query;
    public Database.QueryLocator start(Database.BatchableContext BC ){
        // return Database.getQueryLocator(this.query);      
        return Database.getQueryLocator(this.query);
    }
    
    public void execute( Database.BatchableContext BC, List<Journey__c> lstJourney){
        system.debug('lstJourney-->'+lstJourney);
        string curJourneyId = lstJourney[0].id;
        if(!this.isEvent){
            journeyArea(curJourneyId);
        }
        if(this.isEvent){
            List<Event__c> lstEvent = [Select Id,Is_Claim__c ,ownerId,Campaign__c,Activity__c,Account__c,recordTypeId,CheckIn_Date__c,CheckIn_Address__c,                            
                                       CheckOut_Address__c,Remarks__c,Status__c,CheckOut_Date__c,CheckIn_Location__c ,CheckOut_Location__c,Distance__c,
                                       Journey__c from Event__c where Journey__c=:curJourneyId /*and id='a0K7200000AVXQ9EAP'*/];
            system.debug('lstEvent---->'+lstEvent);
            List<Event__c> eveToUpdatelist = new List<Event__c>();
            for(Event__c eve :lstEvent){
                if(eve.CheckOut_Location__c ==''){
                    eve.CheckOut_Location__c=eve.CheckIn_Location__c;
                }
                if(eve.CheckIn_Location__c ==''){
                    eve.CheckIn_Location__c =eve.CheckOut_Location__c;
                }
                eveToUpdatelist.add(eve);
            }
            if(!eveToUpdatelist.isEmpty()){
				 update eveToUpdatelist;
                System.enqueueJob(new EventDistanceCalculationApiQueueable(eveToUpdatelist));
                System.debug('eveToUpdatelist-->'+eveToUpdatelist);
                
            }
           
        }  
    }
    public void finish(Database.BatchableContext BC){
        
    }
    
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
                                     from Journey__C where Id =: jourId limit 1 ];
            system.debug('curJourney'+curJourney);
            //Querry to get last ecent from the journey which is already checkedOut    
            List<Event__c> lstexisEve = [Select Id,Start__c ,End__c ,CheckIn_Date__c ,CheckOut_Date__c,CheckOut_Location__c,CheckIn_Address__c,CheckOut_Address__c
                                         from Event__C where Journey__c =:jourId and CheckOut_Date__c != null order by CheckOut_Date__c DESC limit 2 ];
            if(lstexisEve.size()==2){
               lstexisEve.remove(0);
            }
            system.debug('lstexisEve'+lstexisEve);
            // Querry to get Journey last Event event from the journey 
            List<Event__c> journeyLastEvent = [Select Id, name, checkIn_Location__c, checkOut_Location__c, CheckIn_Address__c, checkOut_Address__c,
                                               Distance__c from Event__c where journey__c=: jourId and name = 'System Event'];
            system.debug('journeyLastEvent'+journeyLastEvent);
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
            system.debug('response-->'+response.getbody());
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
                    system.debug('Journey Distance update'+curJourney.Journey_KM__c);
                }
                system.debug('curJourney'+curJourney); 
                system.debug('curJourney'+curJourney.Journey_KM__c);
                system.debug('curJourney'+curJourney.id);
                update  curJourney;
            }else{
                System.debug('AddressCalculationQueueable'+jourId);
                System.enqueueJob(new AddressCalculationQueueable(null, jourId, false, 'checkout' ));
            }
        } catch(Exception e){ // Added by shubham Girdhar reffering jira ticket: SD-417
            
            system.debug('exception'+e.getmessage());
            String name = 'Journey';
            String ClassName = 'JourneyDistanceCalculationApi';
            ExceptionHandling.Exception( name, ClassName, e);   
        }
    }}