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

System.assertEquals(
    0,
    [SELECT COUNT() FROM User WHERE UserRoleId IN :targetRoleIds],
    'Users remain assigned to target roles'
);
System.assertEquals(
    0,
    [SELECT COUNT() FROM UserRole WHERE ParentRoleId IN :targetRoleIds AND Id NOT IN :targetRoleIds],
    'A child role outside the approved target set remains'
);
System.assertEquals(
    0,
    [
        SELECT COUNT()
        FROM GroupMember
        WHERE Group.DeveloperName = 'Lead_Central_Team_3PL'
        AND UserOrGroupId IN (
            SELECT Id
            FROM Group
            WHERE RelatedId = '00E7F000001M693UAC'
            AND Type = 'Role'
        )
    ],
    '3PL Head remains a queue member'
);

List<UserRole> currentRoles = [
    SELECT Id, Name, ParentRoleId
    FROM UserRole
    WHERE Id IN :targetRoleIds
];
System.assert(currentRoles.size() <= 14, 'Unexpected target-role count before deletion');

Map<Id, UserRole> remaining = new Map<Id, UserRole>(currentRoles);
Integer deletedCount = 0;
Integer levelCount = 0;

while (!remaining.isEmpty()) {
    Set<Id> parentIds = new Set<Id>();
    for (UserRole roleRecord : remaining.values()) {
        if (roleRecord.ParentRoleId != null && remaining.containsKey(roleRecord.ParentRoleId)) {
            parentIds.add(roleRecord.ParentRoleId);
        }
    }

    List<UserRole> leaves = new List<UserRole>();
    for (UserRole roleRecord : remaining.values()) {
        if (!parentIds.contains(roleRecord.Id)) {
            leaves.add(roleRecord);
        }
    }
    System.assert(!leaves.isEmpty(), 'Cycle detected in target role hierarchy');

    Database.DeleteResult[] results = Database.delete(leaves, false);
    List<String> errors = new List<String>();
    for (Integer index = 0; index < results.size(); index++) {
        if (!results[index].isSuccess()) {
            for (Database.Error errorItem : results[index].getErrors()) {
                errors.add(leaves[index].Id + ': ' + errorItem.getStatusCode() + ': ' + errorItem.getMessage());
            }
        }
    }
    System.assert(errors.isEmpty(), String.join(errors, ' | '));

    for (UserRole roleRecord : leaves) {
        remaining.remove(roleRecord.Id);
        deletedCount++;
    }
    levelCount++;
}

System.debug(LoggingLevel.ERROR, 'DELETED_ROLES=' + deletedCount + '; LEVELS=' + levelCount);
