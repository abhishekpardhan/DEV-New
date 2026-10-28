/**
 * @File Name          : CaseContactHelperTest.cls
 * @Description        : CaseContactHelperTest is the test class for CaseContactHelper apex class
 * @Author             : Manshi Joshi
 * @Group              : IBM
 * @Coverage		   : 95%
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        21-07-2025                Manshi                   Initial Version
* 1.1        11-02-2026                Rudra Singh              As per latest on contact we use MobilePhone Field instead of phone
**/
@isTest
public class CaseContactHelperTest {

    @TestSetup
    static void setupTestData() {
        // Existing contact with matching MobilePhone
        Contact existingContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            MobilePhone = '9998887777',
            Email = 'john.doe@example.com',
            Is_Active__c = true
        );
        insert existingContact;
        
        // Case with matching MobilePhone to existing contact
        Case caseWithMatch = new Case(
            Origin = 'Web',
            SuppliedPhone = '9998887777',
            Requester_Name__c = 'John Doe',
            SuppliedEmail = 'john.doe@example.com',
            Subject = 'Test Case With Match',
            Status = 'New'
        );
        
        // Case with no matching MobilePhone (should create new contact)
        Case caseWithNoMatch = new Case(
            Origin = 'Web',
            SuppliedPhone = '8887776666',
            Requester_Name__c = 'Jane Smith',
            SuppliedEmail = 'jane.smith@example.com',
            Subject = 'Test Case With No Match',
            Status = 'New'
        );
        
        
        
        insert new List<Case>{ caseWithMatch, caseWithNoMatch };
    }
    
    
    
    @isTest
    static void testTagContactsToCases() {
        // Fetch cases
        List<Case> cases = [SELECT Id, SuppliedPhone FROM Case];
        List<Id> caseIds = new List<Id>();
        for (Case c : cases) {
            caseIds.add(c.Id);
        }
        
        // Invoke the method
        Test.startTest();
        CaseContactHelper.tagContactsToCases(caseIds);
        Test.stopTest();
        
        // Reload cases to verify updates
        List<Case> updatedCases = [SELECT Id, ContactId, SuppliedPhone FROM Case];
        
        System.assertEquals(2, updatedCases.size(), 'Both cases should be processed');
        
        for (Case c : updatedCases) {
            System.assertNotEquals(null, c.ContactId, 'Each case should have a ContactId after processing');
        }
        
        // Assert new contact is created
        List<Contact> newContacts = [SELECT Id, MobilePhone FROM Contact WHERE MobilePhone = '8887776666'];
        System.assertEquals(1, newContacts.size(), 'One new contact should be created for unmatched MobilePhone');
    }
}