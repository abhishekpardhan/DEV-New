global class JourneyDeletion implements Schedulable{
    global void execute(SchedulableContext SC){
        try{ 
            list<Journey__C> JunkJourney = [select id, name, Journey_Date__c,owner.email, CheckIn_Date__c,CheckIn_Location__c, CheckOut_Date__c,CheckOut_Location__c from Journey__c where CheckIn_Date__c = null and CheckIn_Location__c = null and CheckOut_Date__c = null and CheckOut_Location__c = null and Journey_Date__c < Last_N_Days:1];
            list<Journey__c> deleteJourney = new list<Journey__c>();
            list < Messaging.SingleEmailMessage > emails = new List < Messaging.SingleEmailMessage > ();

            for(Journey__c jor : JunkJourney){
                
                if(jor.CheckIn_Date__c == null && jor.CheckIn_Location__c == null && jor.CheckOut_Date__c == null && jor.CheckOut_Location__c == null){    
                    deleteJourney.add(jor);
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
                    String[] toadd=new String[] {jor.owner.Email};
                        email.setToAddresses(toadd);
                    email.setSaveAsActivity(false);
                    email.setSubject('Your Journey No. '+jor.Name+' has been auto deleted');
                    email.setPlainTextBody('Dear User, \n\n Your Journey No. '+jor.Name+' has been auto deleted from Safeforce1, as it was unused for the travel and no event was associated with journey.\n\n\n Thanks\n Safeforce1');
                    emails.add(email);                
                }
                
            }
            delete deleteJourney;
            Messaging.sendEmail(emails);
        }catch(exception e){
            string Name ='Journey Deletion Process';
            String ClassName = 'Journey Deletion';
            ExceptionHandling.Exception(Name, ClassName, e);
        }
    }
}