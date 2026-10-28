String stamp = String.valueOf(DateTime.now().getTime());
Id durganathId = '0057F000004esDwQAI';
List<Lead> rows = new List<Lead>{
    new Lead(LastName = 'DURGANATH-T16-' + stamp, Company = 'Stream A Scenario Test',
        Status = 'Active', LeadSource = 'Directory', PostalCode = '990101',
        MobilePhone = '9999999999', Email = 't16-' + stamp + '@example.invalid',
        Street = 'Test data only', City = 'Test City', State = 'Test State', OwnerId = durganathId,
        Area__c = 'NOIDA', Region__c = 'UTTAR PRADESH', Assign_to_Central_Desk__c = false,
        Assignment_Evaluated__c = true, Pincode_Lookup_Status__c = 'Completed',
        Description = 'STREAM_A_T16_DURGANATH'),
    new Lead(LastName = 'DURGANATH-T17-' + stamp, Company = 'Stream A Scenario Test',
        Status = 'Active', LeadSource = 'Directory', PostalCode = '990102',
        MobilePhone = '9999999999', Email = 't17-' + stamp + '@example.invalid',
        Street = 'Test data only', City = 'Test City', State = 'Test State', OwnerId = durganathId,
        Area__c = 'BHIWANDI', Region__c = 'MUMBAI', Assign_to_Central_Desk__c = true,
        Assignment_Evaluated__c = true, Pincode_Lookup_Status__c = 'Completed',
        Description = 'STREAM_A_T17_DURGANATH')
};
TriggerHandler.bypass('LeadTriggerHandler');
try {
    insert rows;
} finally {
    TriggerHandler.clearBypass('LeadTriggerHandler');
}
System.debug(LoggingLevel.ERROR, 'T16_PREP_ID=' + rows[0].Id);
System.debug(LoggingLevel.ERROR, 'T17_PREP_ID=' + rows[1].Id);
