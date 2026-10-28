String marker = 'STREAM-A-DURGANATH-LOCAL-' + String.valueOf(DateTime.now().getTime());

Lead testLead = new Lead(
    LastName = marker,
    Company = 'Stream A Durganath Local Test',
    Status = 'Active',
    LeadSource = 'Directory',
    PostalCode = '990101',
    MobilePhone = '9999999999',
    Email = marker.toLowerCase() + '@example.invalid',
    Street = 'Test data only',
    City = 'Test City',
    State = 'Test State',
    Assign_to_Central_Desk__c = true,
    Description = 'DURGANATH_LOCAL_TEST. Expected: local NOIDA mapping and unique Area Manager assignment.'
);

insert testLead;

System.debug(LoggingLevel.ERROR, 'DURGANATH LOCAL TEST LEAD ID=' + testLead.Id);
System.debug(LoggingLevel.ERROR, 'DURGANATH LOCAL TEST MARKER=' + marker);
