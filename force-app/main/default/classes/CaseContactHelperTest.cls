@IsTest
private class CaseContactHelperTest {

    private static Case createB2BCase(String name, String phone, String email, String pincode) {
        return CommonDataTest.getSupportCase(name, phone, email, ConstantUtility.CASE_TYPE_B2B, ConstantUtility.CASE_NATURE_ENQUIRY, pincode);
    }

    @IsTest
    static void taggedContact() {
        Contact con = CommonDataTest.getContact();
        con.MobilePhone = '8887776666';
        con.Email = 'jane@test.com';
        insert con;

        Case newCasewithContact = createB2BCase('Jane Smith', '8887776666', 'jane@test.com', '122002');
        newCasewithContact.ContactId = con.Id;

        Test.startTest();
        insert newCasewithContact;
        Test.stopTest();

        Case updatedCase = [SELECT Id, ContactId, Status FROM Case WHERE Id = :newCasewithContact.Id];
        System.assertEquals(con.Id, updatedCase.ContactId, 'Existing Contact should be associated with the Case.');
    }

    @IsTest
    static void noExistingContact() {
        Case newCasewithoutContact = createB2BCase('Jane Smith', '8887776676', 'jane@test.com', '122002');
        Test.startTest();
        insert newCasewithoutContact;
        Test.stopTest();

        Case updatedCase = [SELECT Id, ContactId, Status FROM Case WHERE Id = :newCasewithoutContact.Id];
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Case__c = :newCasewithoutContact.Id], 'A Lead should be created for the eligible Case.');
    }

    @IsTest
    static void existingAccount() {
        Account acc = CommonDataTest.getParentAccount();
        acc.Mobile_No__c = '7829183918';
        insert acc;

        Case newTestCase = createB2BCase('Jane Smith', '7829183918', 'jane@test.com', '122002');

        Test.startTest();
        insert newTestCase;
        Test.stopTest();

        Case updatedCase = [SELECT Id, ContactId, Status FROM Case WHERE Id = :newTestCase.Id];

        System.assertNotEquals(null, updatedCase.ContactId, 'A Contact should be associated with the Case.');
        System.assertEquals(ConstantUtility.COMPLETED, updatedCase.Status, 'B2B Enquiry Case should be marked Completed.');
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE Case__c = :newTestCase.Id], 'Lead should not be created when an existing Account matches the mobile number.');
    }

    @IsTest
    static void existingLead() {
        Lead existLead = CommonDataTest.getLead('Existing Lead', 'Active', null, null);
        existLead.MobilePhone = '7829183918';
        existLead.Email = 'jane@test.com';
        insert existLead;
        Case newTestCase = createB2BCase('Jane Smith', '7829183918', 'jane@test.com', '122002');

        Test.startTest();
        insert newTestCase;
        Test.stopTest();

        Case updatedCase = [SELECT Id, ContactId, Status FROM Case WHERE Id = :newTestCase.Id];
        System.assertNotEquals(null, updatedCase.ContactId, 'A Contact should be associated with the Case.');
    }

    @IsTest
    static void bookingRequestcase() {
        Case bookingCase = CommonDataTest.getSupportCase('Jane Smith', '8887775576', 'jane@test.com', ConstantUtility.CASE_TYPE_BUSINESS_REQUEST, 
                                                         ConstantUtility.CASE_NATURE_REQUEST, '122002');
        Test.startTest();
        insert bookingCase;
        Test.stopTest();
        Case updatedCase = [SELECT Id, ContactId, Status FROM Case WHERE Id = :bookingCase.Id];
        
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Case__c = :bookingCase.Id], 'A Lead should be created for an eligible Booking Request.');
    }

    @IsTest
    static void leadInserterror() {
        Case newTestCase = createB2BCase('Jane Smith', '8887776676', null, '122002');
        newTestCase.Requester_Location__c = null;
        Test.startTest();
        insert newTestCase;
        Test.stopTest();

        Case updatedCase = [SELECT Id, ContactId, Status FROM Case WHERE Id = :newTestCase.Id];
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Case__c = :newTestCase.Id], 'Lead should be created when the mobile number and pincode are available, even if email is missing.');
    }

    @IsTest
    static void missingPincode() {
        Case newTestCase = createB2BCase('Jane Smith', '8887776676', 'jane@test.com', null);

        Test.startTest();
        insert newTestCase;
        Test.stopTest();

        Case updatedCase = [SELECT Id, ContactId, Status FROM Case WHERE Id = :newTestCase.Id];
        System.assertNotEquals(null, updatedCase.ContactId, 'Contact should be created even when the pincode is missing.');
    }

    @IsTest
    static void contactInsertError() {
        Case newTestCase = createB2BCase('Jane Smith', '888777667', 'jane@test.com', '122002');

        Test.startTest();
        insert newTestCase;
        Test.stopTest();
        Case updatedCase = [SELECT Id, ContactId, Status FROM Case WHERE Id = :newTestCase.Id];

        System.assertEquals('New', updatedCase.Status,'B2B Enquiry Case should be marked New.');
    }
}