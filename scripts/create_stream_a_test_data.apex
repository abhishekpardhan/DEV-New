// Dev1 Stream A test data. Safe to rerun: reference mappings are refreshed and
// Leads are inserted only when the exact test LastName does not already exist.
Map<String, Branch_Master__c> existingBranches = new Map<String, Branch_Master__c>();
for (Branch_Master__c branch : [
    SELECT Id, Branch_Code__c
    FROM Branch_Master__c
    WHERE Branch_Code__c IN ('STMA_NOIDA', 'STMA_BHIW', 'STMA_MULTI')
]) {
    existingBranches.put(branch.Branch_Code__c, branch);
}

List<Branch_Master__c> branches = new List<Branch_Master__c>();
for (List<String> value : new List<List<String>>{
    new List<String>{'STMA_NOIDA', 'NOIDA', 'UTTAR PRADESH'},
    new List<String>{'STMA_BHIW', 'BHIWANDI', 'MUMBAI'},
    new List<String>{'STMA_MULTI', 'NORTH-EAST SOUTH', 'NORTH EAST'}
}) {
    Branch_Master__c branch = existingBranches.get(value[0]);
    if (branch == null) {
        branch = new Branch_Master__c(Name = 'Stream A Test ' + value[0]);
    }
    branch.Branch_Code__c = value[0];
    branch.Area__c = value[1];
    branch.Region__c = value[2];
    branch.is_PropelI_Branch__c = true;
    branches.add(branch);
}
upsert branches;

upsert new List<Pincode__c>{
    new Pincode__c(Pincode__c = '990101', Branch_Cd__c = 'STMA_NOIDA'),
    new Pincode__c(Pincode__c = '990102', Branch_Cd__c = 'STMA_BHIW'),
    new Pincode__c(Pincode__c = '990103', Branch_Cd__c = 'STMA_MULTI')
} Pincode__c;

Set<String> testNames = new Set<String>{
    'STREAM-A-01-UNIQUE-AM',
    'STREAM-A-02-NO-AM',
    'STREAM-A-03-MULTIPLE-AM',
    'STREAM-A-04-CREATOR-OWNER',
    'STREAM-A-05-WEBSITE',
    'STREAM-A-06-ASYNC-NOT-FOUND'
};
Set<String> existingNames = new Set<String>();
for (Lead row : [SELECT LastName FROM Lead WHERE LastName IN :testNames]) {
    existingNames.add(row.LastName);
}

List<Lead> leads = new List<Lead>();
for (List<String> value : new List<List<String>>{
    new List<String>{'STREAM-A-01-UNIQUE-AM', '990101', 'true', 'Directory',
        'Expected: NOIDA / UTTAR PRADESH, exactly one Area Manager, checkbox false, Completed.'},
    new List<String>{'STREAM-A-02-NO-AM', '990102', 'true', 'Directory',
        'Expected: BHIWANDI / MUMBAI, no Area Manager, Central Desk, Completed.'},
    new List<String>{'STREAM-A-03-MULTIPLE-AM', '990103', 'true', 'Directory',
        'Expected: NORTH-EAST SOUTH / NORTH EAST, multiple Area Managers, Central Desk, Completed.'},
    new List<String>{'STREAM-A-04-CREATOR-OWNER', '990101', 'false', 'Directory',
        'Expected: local Area and Region populated; creator remains Owner; evaluated false.'},
    new List<String>{'STREAM-A-05-WEBSITE', '990101', 'false', 'Website',
        'Expected: Website automatically marks Central Desk, then assigns the unique NOIDA Area Manager.'},
    new List<String>{'STREAM-A-06-ASYNC-NOT-FOUND', '990199', 'true', 'Directory',
        'Expected: Pending initially; API lookup; Not Found and Central Desk if API returns SUCCESS with empty data.'}
}) {
    if (existingNames.contains(value[0])) continue;
    leads.add(new Lead(
        LastName = value[0],
        Company = 'Stream A Test Data - Delete After Testing',
        Status = 'Active',
        LeadSource = value[3],
        PostalCode = value[1],
        MobilePhone = '9999999999',
        Email = value[0].toLowerCase() + '@example.invalid',
        Street = 'Test data only',
        City = 'Test City',
        State = 'Test State',
        Assign_to_Central_Desk__c = Boolean.valueOf(value[2]),
        Description = 'STREAM_A_TEST_DATA_2026_10_26. ' + value[4]
    ));
}

Database.SaveResult[] results = Database.insert(leads, false);
for (Integer i = 0; i < results.size(); i++) {
    if (results[i].isSuccess()) {
        System.debug(LoggingLevel.ERROR, 'CREATED LEAD: ' + leads[i].LastName + ' => ' + results[i].getId());
    } else {
        for (Database.Error error : results[i].getErrors()) {
            System.debug(LoggingLevel.ERROR,
                'FAILED LEAD: ' + leads[i].LastName + ' => ' + error.getStatusCode() + ': ' + error.getMessage());
        }
    }
}
System.debug(LoggingLevel.ERROR, 'REFERENCE RECORDS READY: 3 branches and 3 local pincodes.');
