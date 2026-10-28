String stamp = String.valueOf(DateTime.now().getTime());
List<Lead> rows = new List<Lead>();
for (Integer i = 0; i < 200; i++) {
    Boolean local = i < 100;
    rows.add(new Lead(LastName = 'DURGANATH-T21-' + stamp + '-' + i,
        Company = 'Stream A Bulk Scenario Test', Status = 'Active', LeadSource = 'Directory',
        PostalCode = local ? '990101' : '990198', MobilePhone = '9999999999',
        Email = 't21-' + stamp + '-' + i + '@example.invalid', Street = 'Test data only',
        City = 'Test City', State = 'Test State', Assign_to_Central_Desk__c = false,
        Description = 'STREAM_A_T21_DURGANATH;' + (local ? 'LOCAL' : 'ASYNC')));
}
Integer jobsBefore = Limits.getQueueableJobs();
Database.SaveResult[] results = Database.insert(rows, false);
Integer successes = 0;
Integer failures = 0;
for (Database.SaveResult result : results) {
    if (result.isSuccess()) successes++; else failures++;
}
System.debug(LoggingLevel.ERROR, 'T21_SUCCESS_COUNT=' + successes);
System.debug(LoggingLevel.ERROR, 'T21_FAILURE_COUNT=' + failures);
System.debug(LoggingLevel.ERROR, 'T21_QUEUEABLES_ADDED=' + (Limits.getQueueableJobs() - jobsBefore));
System.debug(LoggingLevel.ERROR, 'T21_SOQL_USED=' + Limits.getQueries());
System.debug(LoggingLevel.ERROR, 'T21_DML_USED=' + Limits.getDmlStatements());
