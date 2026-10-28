/**
* Description      : Test class for OpportunityTeamsTrigger
*
* Best Practice Version
**/
@IsTest
private class OpportunityTeamsTriggerTest {

    /**
     * Test Setup
     */
    @testSetup
    static void setupData() {

        User defaultUser = CommonDataTest.getUserAM();
        defaultUser.Username = 'defaultuser' + System.currentTimeMillis() + '@test.com';
        defaultUser.Email = 'defaultuser@test.com';

        User nonDefaultUser = CommonDataTest.getUserAM();
        nonDefaultUser.Username = 'nondefaultuser' + System.currentTimeMillis() + '@test.com';
        nonDefaultUser.Email = 'nondefaultuser@test.com';

        insert new List<User>{ defaultUser, nonDefaultUser };

        Opportunity__c opp = CommonDataTest.getOpportunity();
        insert opp;

        insert new List<Opportunity_Teams__c>{

            new Opportunity_Teams__c(
                Opportunity__c = opp.Id,
                User__c = defaultUser.Id
            ),

            new Opportunity_Teams__c(
                Opportunity__c = opp.Id,
                User__c = nonDefaultUser.Id
            )
        };
    }

    /**
     * Get Default User
     */
    private static User getDefaultUser() {

        return [
            SELECT Id, Username
            FROM User
            WHERE Username LIKE 'defaultuser%'
            LIMIT 1
        ];
    }

    /**
     * Get Non Default User
     */
    private static User getNonDefaultUser() {

        return [
            SELECT Id, Username
            FROM User
            WHERE Username LIKE 'nondefaultuser%'
            LIMIT 1
        ];
    }

    /**
     * Test Insert
     */
    @IsTest
    static void testInsertTeamMember() {

        Opportunity__c opp = [
            SELECT Id
            FROM Opportunity__c
            LIMIT 1
        ];

        User usr = getNonDefaultUser();

        Test.startTest();

        Opportunity_Teams__c team = new Opportunity_Teams__c(
            Opportunity__c = opp.Id,
            User__c = usr.Id
        );

        insert team;

        Test.stopTest();
    }

    /**
     * Test Update Non Default User
     */
    @IsTest
    static void testUpdateNonDefaultUser() {

        User usr = getNonDefaultUser();

        Opportunity_Teams__c team = [
            SELECT Id
            FROM Opportunity_Teams__c
            WHERE User__c = :usr.Id
            LIMIT 1
        ];

        Test.startTest();

        OpportunityTeamsTriggerHelper.clearCache();

        Database.SaveResult sr =
            Database.update(team, false);

        Test.stopTest();
    }

    /**
     * Test Update Default User
     */
    @IsTest
    static void testUpdateDefaultUser() {

        User usr = getDefaultUser();

        Opportunity_Teams__c team = [
            SELECT Id
            FROM Opportunity_Teams__c
            WHERE User__c = :usr.Id
            LIMIT 1
        ];

        Test.startTest();

        OpportunityTeamsTriggerHelper.clearCache();

        Database.SaveResult sr =
            Database.update(team, false);

        Test.stopTest();

    }

    /**
     * Test Delete Non Default User
     */
    @IsTest
    static void testDeleteNonDefaultUser() {

        User usr = getNonDefaultUser();

        Opportunity_Teams__c team = [
            SELECT Id
            FROM Opportunity_Teams__c
            WHERE User__c = :usr.Id
            LIMIT 1
        ];

        Test.startTest();

        OpportunityTeamsTriggerHelper.clearCache();

        Database.DeleteResult dr =
            Database.delete(team, false);

        Test.stopTest();

    }

    /**
     * Test Delete Default User
     */
    @IsTest
    static void testDeleteDefaultUser() {

        User usr = getDefaultUser();

        Opportunity_Teams__c team = [
            SELECT Id
            FROM Opportunity_Teams__c
            WHERE User__c = :usr.Id
            LIMIT 1
        ];

        Test.startTest();

        OpportunityTeamsTriggerHelper.clearCache();

        Database.DeleteResult dr =
            Database.delete(team, false);

        Test.stopTest();

    }

    /**
     * Test Cache
     */
    @IsTest
    static void testHelperCache() {

        Test.startTest();

        OpportunityTeamsTriggerHelper.clearCache();

        Set<Id> firstCall =
            OpportunityTeamsTriggerHelper.getDefaultUserIds();

        Set<Id> secondCall =
            OpportunityTeamsTriggerHelper.getDefaultUserIds();

        Test.stopTest();
    }

    /**
     * Test Trigger Bypass
     */
    @IsTest
    static void testTriggerBypass() {

        User usr = getDefaultUser();

        Opportunity_Teams__c team = [
            SELECT Id
            FROM Opportunity_Teams__c
            WHERE User__c = :usr.Id
            LIMIT 1
        ];

        Test.startTest();

        TriggerUtility.byPassTrigger = true;

        Database.SaveResult sr =
            Database.update(team, false);

        TriggerUtility.byPassTrigger = false;

        Test.stopTest();
    }
}