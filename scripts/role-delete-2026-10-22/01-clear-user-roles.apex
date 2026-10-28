String expectedOrgId = '00DC1000005VGonMAG';
System.assertEquals(expectedOrgId, UserInfo.getOrganizationId(), 'Wrong Salesforce org');

Set<Id> targetRoleIds = new Set<Id>{
    '00E2y000000MP1SEAW',
    '00E7F000001M67UUAS',
    '00E7F000001M67XUAS',
    '00E7F000001M67ZUAS',
    '00E7F000001M691UAC',
    '00E7F000001M693UAC',
    '00E7F000001MCikUAG',
    '00EC5000000HbhDMAS',
    '00EC5000000HbyYMAS',
    '00EC5000000HbynMAC',
    '00EC5000000Hbz2MAC',
    '00EC5000000Hbz7MAC',
    '00EC5000000HbzCMAS',
    '00EOX00000P8Egv2AF'
};

List<UserRole> roles = [SELECT Id FROM UserRole WHERE Id IN :targetRoleIds];
System.assert(roles.size() <= 14, 'Unexpected target-role count');

List<User> users = [
    SELECT Id, Name, IsActive, UserRoleId
    FROM User
    WHERE UserRoleId IN :targetRoleIds
];
System.assert(users.size() <= 23, 'Unexpected assigned-user count');

for (User userRecord : users) {
    userRecord.UserRoleId = null;
}

Database.SaveResult[] results = Database.update(users, false);
List<String> errors = new List<String>();
for (Integer index = 0; index < results.size(); index++) {
    if (!results[index].isSuccess()) {
        for (Database.Error errorItem : results[index].getErrors()) {
            errors.add(users[index].Id + ': ' + errorItem.getStatusCode() + ': ' + errorItem.getMessage());
        }
    }
}
System.assert(errors.isEmpty(), String.join(errors, ' | '));
System.debug(LoggingLevel.ERROR, 'CLEARED_USER_ROLES=' + users.size());
