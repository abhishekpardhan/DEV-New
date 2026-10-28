String stamp = String.valueOf(DateTime.now().getTime());

List<String> scenarioNames = new List<String>{'T02', 'T03', 'T04', 'T19_WEB'};
List<Lead> rows = new List<Lead>{
    new Lead(LastName = 'DURGANATH-T02-' + stamp, Company = 'Stream A Scenario Test',
        Status = 'Active', LeadSource = 'Directory', PostalCode = '990102',
        MobilePhone = '9999999999', Email = 't02-' + stamp + '@example.invalid',
        Street = 'Test data only', City = 'Test City', State = 'Test State',
        Assign_to_Central_Desk__c = true, Description = 'STREAM_A_T02_DURGANATH'),
    new Lead(LastName = 'DURGANATH-T03-' + stamp, Company = 'Stream A Scenario Test',
        Status = 'Active', LeadSource = 'Directory', PostalCode = '990103',
        MobilePhone = '9999999999', Email = 't03-' + stamp + '@example.invalid',
        Street = 'Test data only', City = 'Test City', State = 'Test State',
        Assign_to_Central_Desk__c = true, Description = 'STREAM_A_T03_DURGANATH'),
    new Lead(LastName = 'DURGANATH-T04-' + stamp, Company = 'Stream A Scenario Test',
        Status = 'Active', LeadSource = 'Directory', PostalCode = '990101',
        MobilePhone = '9999999999', Email = 't04-' + stamp + '@example.invalid',
        Street = 'Test data only', City = 'Test City', State = 'Test State',
        Assign_to_Central_Desk__c = false, Description = 'STREAM_A_T04_DURGANATH'),
    new Lead(LastName = 'DURGANATH-T19-WEB-' + stamp, Company = 'Stream A Scenario Test',
        Status = 'Active', LeadSource = 'Web', PostalCode = '990101',
        MobilePhone = '9999999999', Email = 't19-' + stamp + '@example.invalid',
        Street = 'Test data only', City = 'Test City', State = 'Test State',
        Assign_to_Central_Desk__c = false, Description = 'STREAM_A_T19_WEB_DURGANATH')
};

Database.SaveResult[] inserts = Database.insert(rows, false);
for (Integer i = 0; i < inserts.size(); i++) {
    if (inserts[i].isSuccess()) {
        System.debug(LoggingLevel.ERROR, scenarioNames[i] + '_INSERT_ID=' + inserts[i].getId());
    } else {
        System.debug(LoggingLevel.ERROR, scenarioNames[i] + '_INSERT_FAIL=' +
            inserts[i].getErrors()[0].getStatusCode() + ':' + inserts[i].getErrors()[0].getMessage());
    }
}

