@isTest
public class CommonControllerTest {

    @isTest
    static void testGetList_Success() {
        // Create test data
        Account parentAccount = new Account(Name = 'Parent Account');
        insert parentAccount;

        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = parentAccount.Id);
        insert testContact;

        // Define parameters
        String fields = 'FirstName, LastName';
        String objAPIName = 'Contact';
        String relationshipWithObj = 'AccountId';
        Id recordId = parentAccount.Id;

        // Execute the method
        Test.startTest();
        List<SObject> results = CommonController.getList(fields, objAPIName, relationshipWithObj, recordId);
        Test.stopTest();

        // Validate results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one record returned');
        Contact resultContact = (Contact) results[0];
        System.assertEquals('John', resultContact.FirstName, 'FirstName should match');
        System.assertEquals('Doe', resultContact.LastName, 'LastName should match');
    }

    @isTest
    static void testGetList_NoAccessibleFields() {
        // Define parameters with fields not accessible
        String fields = 'NonExistentField';
        String objAPIName = 'Contact';
        String relationshipWithObj = 'AccountId';
        Id recordId = UserInfo.getUserId(); // Dummy ID

        // Expect an exception due to no accessible fields
        Test.startTest();
        try {
            CommonController.getList(fields, objAPIName, relationshipWithObj, recordId);
            System.assert(false, 'An exception should have been thrown');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

}