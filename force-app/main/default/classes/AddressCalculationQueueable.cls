/**
* Description		:	Calling google Distance Matrix API for CheckIn/Checkout address of Journey & event in queue
* Created By       :       K R SANSI, IBM
* Created Date     :       13th, Feb, 2024
* Release          :       
* Last Modified on :      13th, Feb, 2024
* Jira Ticket      :     https://safexpress.atlassian.net/browse/SAC-364
**/
public class AddressCalculationQueueable implements Queueable, Database.AllowsCallouts{

	public boolean executeAgain;  
    public String eventId;
    public String journeyId;
    public String eventType;
    public AddressCalculationQueueable(String eventId, String journeyId, boolean executeAgain, String eventType ){
        this.executeAgain = executeAgain;
        this.eventId = eventId;
        this.journeyId = journeyId;
        this.eventType = eventType;
    }
    public void execute(QueueableContext qc){
                
        Journey__c curJourney;
        Event__c curEvent;
        if(journeyId != null){
            curJourney = [SELECT Id, CheckIn_Location__c, CheckOut_Location__c, CheckIn_Address__c, CheckOut_Address__c 
                          	FROM Journey__c
                          	WHERE Id =: this.journeyId limit 1];
        }
        if(eventId != null){
            curEvent = [SELECT Id, CheckIn_Location__c, CheckOut_Location__c, CheckIn_Address__c, CheckOut_Address__c
                                 FROM Event__c WHERE Id =: eventId limit 1];
        }
        
        if(this.eventType == 'checkin'){
            if(eventId != null){
                String address = AddressCalculation.getAddress(curEvent.CheckIn_Location__c);
                if(address != ''){
                    curEvent.CheckIn_Address__c =  address;
                    update curEvent;
                }else{
                    if(this.executeAgain){
                        System.enqueueJob(new AddressCalculationQueueable(eventId, null, false, 'checkin' ));
                    }                    	
                }
            }
            if(journeyId != null){ 
                String address = AddressCalculation.getAddress(curJourney.CheckIn_Location__c);
                if(address != ''){
                    curJourney.CheckIn_Address__c =  address;
                    update curJourney;
                }else{
                    if(this.executeAgain){
                        System.enqueueJob(new AddressCalculationQueueable(null, journeyId, false, 'checkin' ));
                    }                    	
                }
            }
        }
        
        if(this.eventType == 'checkout'){
            if(eventId != null){
                String address = AddressCalculation.getAddress(curEvent.CheckOut_Location__c);
                if(address != ''){
                    curEvent.CheckOut_Address__c =  address;
                    update curEvent;
                }else{
                    if(this.executeAgain){
                        System.enqueueJob(new AddressCalculationQueueable(eventId, null, false, 'checkout' ));
                    }                    	
                }
            }
            if(journeyId != null){
                String address = AddressCalculation.getAddress(curJourney.CheckOut_Location__c);
                if(address != ''){
                    curJourney.CheckOut_Address__c =  address;
                    update curJourney;
                }else{
                    if(this.executeAgain){
                        System.enqueueJob(new AddressCalculationQueueable(null, journeyId, false, 'checkout' ));
                    }                    	
                }
            }
        }
        
    }
    
    
    
}