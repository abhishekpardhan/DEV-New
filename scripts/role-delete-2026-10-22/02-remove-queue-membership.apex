String expectedOrgId = '00DC1000005VGonMAG';
System.assertEquals(expectedOrgId, UserInfo.getOrganizationId(), 'Wrong Salesforce org');

Id x3plHeadRoleId = '00E7F000001M693UAC';
List<GroupMember> queueMemberships = [
    SELECT Id, GroupId, UserOrGroupId
    FROM GroupMember
    WHERE Group.DeveloperName = 'Lead_Central_Team_3PL'
    AND UserOrGroupId IN (
        SELECT Id
        FROM Group
        WHERE RelatedId = :x3plHeadRoleId
        AND Type = 'Role'
    )
];
System.assert(queueMemberships.size() <= 1, 'Unexpected duplicate 3PL queue memberships');
if (!queueMemberships.isEmpty()) {
    delete queueMemberships;
}
System.debug(LoggingLevel.ERROR, 'REMOVED_QUEUE_MEMBERSHIPS=' + queueMemberships.size());
