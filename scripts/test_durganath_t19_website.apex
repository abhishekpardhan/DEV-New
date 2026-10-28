String stamp = String.valueOf(DateTime.now().getTime());
Lead row = new Lead(LastName = 'DURGANATH-T19-WEBSITE-' + stamp,
    Company = 'Stream A Scenario Test', Status = 'Active', LeadSource = 'Website',
    PostalCode = '990101', MobilePhone = '9999999999',
    Email = 't19-website-' + stamp + '@example.invalid', Street = 'Test data only',
    City = 'Test City', State = 'Test State', Assign_to_Central_Desk__c = false,
    Description = 'STREAM_A_T19_WEBSITE_DURGANATH');
insert row;
System.debug(LoggingLevel.ERROR, 'T19_WEBSITE_INSERT_ID=' + row.Id);
