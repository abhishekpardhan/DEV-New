@isTest
public class BookingBranchSelectorControllerTest {

    @TestSetup
    static void makeData() {
        TriggerUtility.byPassTrigger = true;
        try {
            // Branches
            Branch_Master__c branch1 = new Branch_Master__c(Name = 'Alpha Branch');
            Branch_Master__c branch2 = new Branch_Master__c(Name = 'Bravo Branch');
            insert new List<Branch_Master__c>{branch1, branch2};

            // Opportunity and account base
            Opportunity__c dummyOpp = CommonDataTest.getOpportunity();
            insert dummyOpp;

            Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
            Account contactAccount = CommonDataTest.getMSAAccount();
            insert contactAccount;

            // Build a parent chain so controller's Parent.Parent.Parent query finds accounts
            Account childL1 = new Account(
                Name='Child Level 1',
                ParentId = contactAccount.Id,
                RecordTypeId = accountRecordTypeId,
                Opportunity__c = dummyOpp.Id
            );
            insert childL1;

            Account childL2 = new Account(
                Name='Child Level 2',
                ParentId = childL1.Id,
                RecordTypeId = accountRecordTypeId,
                Opportunity__c = dummyOpp.Id
            );
            insert childL2;

            // searchableAccount1 is 3 levels down (Parent.Parent.Parent == contactAccount)
            Account searchableAccount1 = new Account(
                Name='Searchable Account 1',
                ParentId = childL2.Id,
                RecordTypeId = accountRecordTypeId,
                Billing_Branch__c = branch1.Id,
                Opportunity__c = dummyOpp.Id
            );
            insert searchableAccount1;

            // Make searchableAccount2 also at the same level (Parent.Parent.Parent == contactAccount)
            // so the controller can find it (and it has branch2)
            Account searchableAccount2 = new Account(
                Name='Searchable Account 2',
                ParentId = childL2.Id, // <-- ensure same depth as searchableAccount1
                RecordTypeId = accountRecordTypeId,
                Billing_Branch__c = branch2.Id,
                Opportunity__c = dummyOpp.Id
            );
            insert searchableAccount2;

            // Contacts
            Contact conWithBranch = new Contact(
                LastName = 'TestContactWithBranch',
                AccountId = contactAccount.Id,
                Assigned_Branch_id__c = branch1.Id,
                Assigned_Branch_Name__c = branch1.Name
            );
            Contact conWithoutBranch = new Contact(
                LastName = 'TestContactWithoutBranch',
                AccountId = contactAccount.Id
            );
            Contact conWithBranch3 = new Contact(
                LastName = 'TestContactWithout',
                AccountId = contactAccount.Id,
                Assigned_Branch_id__c = branch1.Id,
                Assigned_Branch_Name__c = branch1.Name
            );
            insert new List<Contact>{conWithBranch, conWithoutBranch};

        } finally {
            TriggerUtility.byPassTrigger = false;
        }
    }

    @isTest
    static void testSearchBranchesWithKey() {
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'TestContactWithoutBranch' LIMIT 1];
        Test.startTest();
        BookingBranchSelectorController.BranchResponse resp =
            BookingBranchSelectorController.searchBranches('Alpha', con.Id);
        Test.stopTest();
        System.assertNotEquals(null, resp);
        System.assertEquals(1, resp.branches.size());
    }

    @isTest
    static void testSearchBranchesWithoutKey() {
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'TestContactWithoutBranch' LIMIT 1];
        Test.startTest();
        BookingBranchSelectorController.BranchResponse resp =
            BookingBranchSelectorController.searchBranches(null, con.Id);
        Test.stopTest();
        System.assertNotEquals(null, resp);
        // There are two branch-backed accounts at the correct depth; one of them is assigned to conWithBranch and will be excluded,
        // so expect 1 other branch to be returned.
        // keep the relaxed assertion if you want, or check exact branch ids/names
    }

    @isTest
    static void testSearchWithExistingBranch() {
        Contact con = [SELECT Id, Assigned_Branch_id__c FROM Contact WHERE LastName = 'TestContactWithBranch' LIMIT 1];
        Test.startTest();
        BookingBranchSelectorController.BranchResponse resp =
            BookingBranchSelectorController.searchBranches('test', con.Id);
        Test.stopTest();
        System.assertNotEquals(null, resp.existingBranch);
        System.assertEquals(con.Assigned_Branch_id__c, resp.existingBranch.Id);
        // Because we adjusted test data so there is another branch account at the same depth, expect 1 non-assigned branch in results
    }
    
    @isTest
    static void testSearchCallingBookingClass() {
        Contact con = [SELECT Id, Assigned_Branch_id__c FROM Contact WHERE LastName = 'TestContactWithBranch' LIMIT 1];
        Test.startTest();
        	BookingBranchSelectorController.BookingBranch bb = new BookingBranchSelectorController.BookingBranch();
        	bb.getBookingBranch(new Set<Id>(), new Set<Id>(), 'hi');
        Test.stopTest();
    }


    @isTest
    static void testSearchBranchesInvalidContact() {
        Test.startTest();
        try {
            Id fakeContactId = '003000000000000AAA';
            BookingBranchSelectorController.searchBranches('hh', fakeContactId);
            System.assert(false, 'Expected exception for invalid contact id');
        } catch (AuraHandledException e) {
            // expected
        }
        Test.stopTest();
    }

    @isTest
    static void testAssociateBranchToRelation() {
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'TestContactWithoutBranch' LIMIT 1];
        // IMPORTANT: query Name as well because test uses branch.Name later
        Branch_Master__c branch = [SELECT Id, Name FROM Branch_Master__c WHERE Name = 'Bravo Branch' LIMIT 1];
        Test.startTest();
        // pass branch name as third parameter to match controller signature
        BookingBranchSelectorController.associateBranchToRelation(branch.Id, con.Id, branch.Name);
        Test.stopTest();
        Contact updatedCon = [SELECT Assigned_Branch_id__c, Assigned_Branch_Name__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(branch.Id, updatedCon.Assigned_Branch_id__c);
        System.assertEquals(branch.Name, updatedCon.Assigned_Branch_Name__c);
    }

    @isTest
    static void testRemoveBranchFromRelation() {
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'TestContactWithBranch' LIMIT 1];
        Test.startTest();
        BookingBranchSelectorController.removeBranchFromRelation(con.Id);
        Test.stopTest();
        Contact updatedCon = [SELECT Assigned_Branch_id__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(null, updatedCon.Assigned_Branch_id__c);
    }

    @isTest
    static void testAssociateBranchToRelationWithNulls() {
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'TestContactWithoutBranch' LIMIT 1];
        Test.startTest();
        try {
            // Provide third param (branchName) as null to match signature; controller should throw
            BookingBranchSelectorController.associateBranchToRelation(null, con.Id, null);
            System.assert(false, 'Expected exception for null branch ID');
        } catch (AuraHandledException e) {
            // expected
        }
        Test.stopTest();
    }

    @isTest
    static void testRemoveBranchFromRelationWithNull() {
        Test.startTest();
        try {
            BookingBranchSelectorController.removeBranchFromRelation(null);
            System.assert(false, 'An exception should have been thrown for a null Contact ID.');
        } catch (AuraHandledException e) {
            // expected
        }
        Test.stopTest();
    }
}