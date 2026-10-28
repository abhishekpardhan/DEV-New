/**
* Description		:		This Batch class will send an Email alert to the users having Journey opened for more then 2 days.
* Created By       :       Shubham Girdhar
* Created Date     :       23rd September, 2019
* Release          :       23rd September, 2019
* Last Modified on :
* Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-463
**/
global class BatchJourneyClosingEmailAlert implements
Database.Batchable<SObject>, Schedulable {
// method to schedule the batch at specific time
global void execute(SchedulableContext sc) {
    BatchJourneyClosingEmailAlert jor = new BatchJourneyClosingEmailAlert();
    Database.executeBatch(jor,200);
}

// Start method to query journeys remained open for more then a week 
global string query = 'select id, Name , OwnerId, owner.Email, CheckIn_Date__c, CheckOut_Date__c, Journey_Date__c from Journey__c where CheckIn_Date__c != null and CheckOut_Date__c = null and Journey_Date__c < Last_N_Days:2';
global database.QueryLocator start (Database.BatchableContext BC)
{
    return Database.getQueryLocator(query);
}
// Execute method to send email alert to users with their journey Id
global void execute(Database.BatchableContext BC, List<Journey__c> scope){
try{
List < Messaging.SingleEmailMessage > emails = new List < Messaging.SingleEmailMessage > ();
for(Journey__c jor : scope){
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();                
        String[] toadd=new String[] {jor.owner.Email};
        email.setToAddresses(toadd);
        email.setSaveAsActivity(false);
        email.setSubject('Your Journey No. '+jor.Name+' was not checked out from last 2 days');
        email.setPlainTextBody('Dear User, \nYour Journey No. '+jor.Name+' was not checked out from last 2 days, So it has been auto checked out at your last event location. Now you would be able to create new journeys.\n\nThanks\nSafeforce1');
        emails.add(email);
        System.debug('Test');
}
Messaging.sendEmail(emails);
}catch(Exception e){
string Name ='EmailAlert';
String ClassName = 'BatchJourneyClosingEmailAlert';
ExceptionHandling.Exception(Name, ClassName, e);
}
} 
// Finish Method
global void finish(Database.BatchableContext BC){

}
}