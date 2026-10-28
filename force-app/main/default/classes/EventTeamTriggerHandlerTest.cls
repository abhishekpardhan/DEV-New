/**
 * Description      :   Test class for Event Team Trigger / EventTeamTriggerHandler
 *                      Covers child event creation, duplicate check,
 *                      child-event member block, checked-in member block, owner change,
 *                      sharing add/remove and exception paths.
 **/
@isTest
public class EventTeamTriggerHandlerTest {

    private static final String DEPT_BDM = 'Test bdm';
    private static final String DEPT_AM  = 'test AM';

    @TestSetup
    static void setupData() {
        User bdmUser = CommonDataTest.getUserBdm();
        User amUser  = CommonDataTest.getUserAM();
        insert new List<User>{ bdmUser, amUser };

        Campaign__c objCam = CommonDataTest.getCampaign();
        insert objCam;

        Event__c parentEvent = CommonDataTest.getEvent();
        parentEvent.Campaign__c = objCam.Id;
        insert parentEvent;
    }

    // ---------------------------------------------------------------- helpers

    private static User getUser(String department) {
        return [SELECT Id FROM User WHERE Department = :department AND LastName = 'XYZ' LIMIT 1];
    }

    private static Event__c getParentEvent() {
        return [SELECT Id, Name, Campaign__c, Contact__c
                FROM Event__c
                WHERE Parent_Event__c = null
                LIMIT 1];
    }

    private static Event_Team__c newTeam(Id eventId, Id userId) {
        Event_Team__c objETeam = new Event_Team__c();
        objETeam.Event__c = eventId;
        objETeam.User__c = userId;
        objETeam.Department__c = 'Account Manager - Manages Credit Customers';
        return objETeam;
    }

    private static Event__c checkInChild(Id parentId) {
        Event__c child = [SELECT Id, OwnerId FROM Event__c WHERE Parent_Event__c = :parentId LIMIT 1];
        child.CheckIn_Date__c = System.now();
        child.CheckIn_Location__c = '28.63,77.25';
        child.ValidationBypassDateTime__c = System.now();
        update child;
        return child;
    }

    // ---------------------------------------------------------------- tests

    // Child event created for team member with values copied from parent
    @isTest
    static void childEventCreatedForTeamMember() {
        User bdmUser = getUser(DEPT_BDM);
        Event__c parentEvent = getParentEvent();

        Test.startTest();
        insert newTeam(parentEvent.Id, bdmUser.Id);
        Test.stopTest();

        List<Event__c> children = [
            SELECT Id, Name, OwnerId, is_Automated__c, Campaign__c, Contact__c
            FROM Event__c
            WHERE Parent_Event__c = :parentEvent.Id
        ];

        System.assertEquals(1, children.size(), 'One child event should be created for the team member');
        Event__c child = children[0];
        System.assertEquals(bdmUser.Id, child.OwnerId, 'Child owner should be the team member');
        System.assertEquals(true, child.is_Automated__c, 'Child should be flagged as automated');
        System.assertEquals(parentEvent.Name, child.Name, 'Name should be copied from parent');
        System.assertEquals(parentEvent.Campaign__c, child.Campaign__c, 'Campaign should be copied from parent');
        System.assertEquals(parentEvent.Contact__c, child.Contact__c, 'Contact should be copied from parent');
    }

    // Bulk: one child per team member
    @isTest
    static void bulkTeamMembersCreateOneChildEach() {
        User bdmUser = getUser(DEPT_BDM);
        User amUser  = getUser(DEPT_AM);
        Event__c parentEvent = getParentEvent();

        Test.startTest();
        insert new List<Event_Team__c>{
            newTeam(parentEvent.Id, bdmUser.Id),
            newTeam(parentEvent.Id, amUser.Id)
        };
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM Event__c WHERE Parent_Event__c = :parentEvent.Id],
            'Two child events should be created');
    }

    // Same user cannot be added twice to the same event
    @isTest
    static void duplicateUserIsBlocked() {
        User bdmUser = getUser(DEPT_BDM);
        Event__c parentEvent = getParentEvent();
        insert newTeam(parentEvent.Id, bdmUser.Id);

        Test.startTest();
        Database.SaveResult sr = Database.insert(newTeam(parentEvent.Id, bdmUser.Id), false);
        Test.stopTest();

        System.assertEquals(false, sr.isSuccess(), 'Duplicate team member should be blocked');
        System.assert(sr.getErrors()[0].getMessage().contains('Duplicate user'), 'Unexpected error: ' + sr.getErrors()[0].getMessage());
    }

    // Team member cannot be added on a child event
    @isTest
    static void teamOnChildEventIsBlocked() {
        User bdmUser = getUser(DEPT_BDM);
        User amUser  = getUser(DEPT_AM);
        Event__c parentEvent = getParentEvent();
        insert newTeam(parentEvent.Id, bdmUser.Id);

        Event__c child = [SELECT Id FROM Event__c WHERE Parent_Event__c = :parentEvent.Id LIMIT 1];

        Test.startTest();
        Database.SaveResult sr = Database.insert(newTeam(child.Id, amUser.Id), false);
        Test.stopTest();

        System.assertEquals(false, sr.isSuccess(), 'Adding a team member on a child event should be blocked');
        System.assert(sr.getErrors()[0].getMessage().contains('not able to add child member'), 'Unexpected error: ' + sr.getErrors()[0].getMessage());
    }

    // Change member -> owner change platform event + sharing remove/add
    @isTest
    static void changeMemberUpdatesTeam() {
        User bdmUser = getUser(DEPT_BDM);
        User amUser  = getUser(DEPT_AM);
        Event__c parentEvent = getParentEvent();

        Event_Team__c team = newTeam(parentEvent.Id, bdmUser.Id);
        insert team;

        Test.startTest();
        team.User__c = amUser.Id;
        update team;
        Test.stopTest(); // delivers Update_Event__e

        System.assertEquals(amUser.Id, [SELECT User__c FROM Event_Team__c WHERE Id = :team.Id].User__c,
            'Team member should be updated');
    }

    // Member cannot be changed once child event is checked in
    @isTest
    static void changeMemberBlockedWhenCheckedIn() {
        User bdmUser = getUser(DEPT_BDM);
        User amUser  = getUser(DEPT_AM);
        Event__c parentEvent = getParentEvent();

        Event_Team__c team = newTeam(parentEvent.Id, bdmUser.Id);
        insert team;
        checkInChild(parentEvent.Id);

        Test.startTest();
        team.User__c = amUser.Id;
        Database.SaveResult sr = Database.update(team, false);
        Test.stopTest();

        System.assertEquals(false, sr.isSuccess(), 'Member change should be blocked after check-in');
        System.assert(sr.getErrors()[0].getMessage().contains('already checked in'), 'Unexpected error: ' + sr.getErrors()[0].getMessage());
    }

    // Delete team member -> sharing removal
    @isTest
    static void deleteTeamMember() {
        User bdmUser = getUser(DEPT_BDM);
        Event__c parentEvent = getParentEvent();

        Event_Team__c team = newTeam(parentEvent.Id, bdmUser.Id);
        insert team;

        Test.startTest();
        delete team;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Event_Team__c WHERE Id = :team.Id], 'Team member should be deleted');
    }

    // Direct handler calls - guarantees coverage of every method regardless of trigger wiring
    @isTest
    static void directHandlerCalls() {
        User bdmUser = getUser(DEPT_BDM);
        User amUser  = getUser(DEPT_AM);
        Event__c parentEvent = getParentEvent();

        Event_Team__c team = newTeam(parentEvent.Id, bdmUser.Id);
        insert team;
        Event__c child = checkInChild(parentEvent.Id);

        Set<Id> eventIds = new Set<Id>{ parentEvent.Id };
        Set<Id> ownerIds = new Set<Id>{ bdmUser.Id };
        String key = String.valueOf(parentEvent.Id) + String.valueOf(bdmUser.Id);

        Test.startTest();

        Event_Team__c dupTeam = newTeam(parentEvent.Id, bdmUser.Id);
        EventTeamTriggerHandler.stopDuplicateRecord(new List<Event_Team__c>{ dupTeam });

        Event_Team__c childTeam = newTeam(child.Id, amUser.Id);
        EventTeamTriggerHandler.errorNewEvent(new List<Event_Team__c>{ childTeam }, new Set<Id>{ child.Id });

        EventTeamTriggerHandler.memberEventAlreadyCheckedIn(
            new Map<String, Id>{ key => team.Id },
            new Map<Id, Event_Team__c>{ team.Id => team },
            eventIds,
            ownerIds
        );

        EventTeamTriggerHandler.changeOwner(new Map<String, Id>{ key => amUser.Id }, eventIds, ownerIds);
        EventTeamTriggerHandler.addSharing(new List<Event_Team__c>{ newTeam(parentEvent.Id, amUser.Id) });
        EventTeamTriggerHandler.removeSharing(new List<Event_Team__c>{ team }, eventIds);
        EventTeamTriggerHandler.manageEventSync(new List<Event_Team__c>{ team }, eventIds, false);

        List<Event__c> childEvents = new EventTeamTriggerHandler.GetDataInSystemMode().getChildEvents(eventIds, ownerIds);

        Test.stopTest();

        System.assert(dupTeam.hasErrors(), 'Duplicate should get an error');
        System.assert(childTeam.hasErrors(), 'Child event team should get an error');
        System.assert(team.hasErrors(), 'Checked-in member change should get an error');
        System.assertEquals(1, childEvents.size(), 'getChildEvents should return the child event');
        System.assertEquals(false, EventTeamTriggerHandler.isSyncRunning, 'isSyncRunning should be reset');
    }

    // Exception paths - covers all catch blocks
    @isTest
    static void exceptionPaths() {
        User bdmUser = getUser(DEPT_BDM);
        Event__c parentEvent = getParentEvent();

        insert newTeam(parentEvent.Id, bdmUser.Id);
        checkInChild(parentEvent.Id);

        Set<Id> eventIds = new Set<Id>{ parentEvent.Id };
        Set<Id> ownerIds = new Set<Id>{ bdmUser.Id };

        Test.startTest();
        EventTeamTriggerHandler.stopDuplicateRecord(null);
        EventTeamTriggerHandler.errorNewEvent(null, new Set<Id>());
        EventTeamTriggerHandler.memberEventAlreadyCheckedIn(null, null, eventIds, ownerIds);
        EventTeamTriggerHandler.changeOwner(null, eventIds, ownerIds);
        EventTeamTriggerHandler.addSharing(null);
        EventTeamTriggerHandler.removeSharing(null, new Set<Id>());
        EventTeamTriggerHandler.manageEventSync(null, new Set<Id>(), true);
        Test.stopTest();

        System.assertEquals(false, EventTeamTriggerHandler.isSyncRunning, 'finally block should reset isSyncRunning');
    }
}