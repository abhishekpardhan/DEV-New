String marker = 'STREAM-A-DURGANATH-' + String.valueOf(DateTime.now().getTime());

Lead testLead = new Lead(
    LastName = marker,
    Company = 'Stream A Durganath User Test',
    Status = 'Active',
    LeadSource = 'Directory',
    PostalCode = '990199',
    MobilePhone = '9999999999',
    Email = marker.toLowerCase() + '@example.invalid',
    Street = 'Test data only',
    City = 'Test City',
    State = 'Test State',
    Assign_to_Central_Desk__c = true,
    Description = 'DURGANATH_CALLOUT_TEST. Expected: async API lookup under Durganath user.'
);

insert testLead;

System.debug(LoggingLevel.ERROR, 'DURGANATH TEST LEAD ID=' + testLead.Id);
System.debug(LoggingLevel.ERROR, 'DURGANATH TEST MARKER=' + marker);
