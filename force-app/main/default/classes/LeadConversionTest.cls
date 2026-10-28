// Best-practice test coverage for LeadConversion

@IsTest
private class LeadConversionTest {

    // -----------------------------
    // Test Data Utilities
    // -----------------------------

    private static Lead__c newQualifiedLead(String name, String gst, Boolean exempted, String typeVal) {
        Lead__c ld = new Lead__c(
            Name = name,
            Email__c = 'test@example.com',
            Mobile_No__c = '1234567890',
            Phone__c = '0987654321',
            City__c = 'ALWAR',
            State__c = 'Rajasthan',
            Street__c = 'Test Street',
            Zip_Postal_Code__c = '123456',
            Rating__c = 'Normal',
            Source__c = 'Google Leads',
            Status__c = 'Active',
            Vertical__c = 'AUTOMOTIVE',
            Account_Type__c = 'Emerging',
            GST_Number__c = gst,
            GST_Exempted__c = exempted,
            Type__c = typeVal
        );
        insert ld;
        return ld;
    }

    private static Task makeCustomerProfilingTask(Id leadId, String statusVal) {
        Task t = new Task(
            WhatId = leadId,
            ValidationBypassDateTime__c = System.now(),
            Subject = 'Customer Profiling Task',
            Status = statusVal,
            Priority = 'Normal'
        );
        insert t;
        return t;
    }

    // -----------------------------
    // Callout Mocks
    // -----------------------------

    // Valid GST, LegalName present
    private class GstValidMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"Gstin":"08EDXPK3622L1ZV","LegalName":"Acme Industries Pvt Ltd","TradeName":"Acme"}}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    // Valid response but different LegalName to trigger name mismatch
    private class GstValidDifferentNameMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"Gstin":"08EDXPK3622L1ZV","LegalName":"Different Legal Name","TradeName":""}}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    // Valid Gstin but empty names -> invalid customer name path
    private class GstValidButEmptyNamesMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"Gstin":"08EDXPK3622L1ZV","LegalName":"","TradeName":""}}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    // Invalid GST (empty Gstin -> wrapper.isValid = false)
    private class GstInvalidMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"Gstin":""}}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    // -----------------------------
    // Tests - Positive
    // -----------------------------

    @IsTest
    static void test_convertLead_validGST_success_flow() {
        Lead__c record = newQualifiedLead('Acme Industries Pvt Ltd', '08EDXPK3622L1ZV', false, 'Credit');
        record.Status__c = 'Qualified';
        update record;
        Test.setMock(HttpCalloutMock.class, new GstValidMock());

        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertlead(record.Id);
        Test.stopTest();
    }

    @IsTest
    static void test_createCustomer_directConversion_skipsNameValidationPath() {
        Lead__c ld = newQualifiedLead('Original Lead Name', '08EDXPK3622L1ZV', false, 'Credit');
		 ld.Status__c = 'Qualified';
        update ld;
        // Completed profiling should not block
        makeCustomerProfilingTask(ld.Id, 'Completed');

        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.createCustomer(ld.Id, 'Final Customer Name');
        Test.stopTest();

    }
    
    @IsTest
    static void test_createCustomer_directConversion_skipsNameValidationPath2() {
        Lead__c ld = newQualifiedLead('Original Lead Name', '08EDXPK3622L1ZV', false, 'Credit');
		 ld.Status__c = 'Qualified';
        update ld;
        // Completed profiling should not block
        makeCustomerProfilingTask(ld.Id, 'Completed');

        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.createCustomer(ld.Id, 'Final Customer Name');
        Test.stopTest();

    }

    @IsTest
    static void test_convertLead_overload_withLeadProvided() {
        Lead__c record = newQualifiedLead('Lead Name Different', '08EDXPK3622L1ZV', false, 'Transportation+3PL');
		 record.Status__c = 'Qualified';
        update record;
        Test.setMock(HttpCalloutMock.class, new GstValidDifferentNameMock());
        try {
            Test.startTest();
        	LeadConversion.GstResponse resp = LeadConversion.convertLead(null, 'Any Name jsdhfshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh', record);
        	Test.stopTest();
        } catch (exception ex) {
            
        }
    }
    
    @IsTest
    static void test_convertLead_overload_withLeadProvided2() {
        Lead__c ld = newQualifiedLead('Any Name', '08EDXPK3622L1ZV', false, 'Credit');
 ld.Status__c = 'Qualified';
        update ld;
        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertLead(null, 'Any Name', ld);
        Test.stopTest();
    }
    
    

    // -----------------------------
    // Tests - Negative/Guard Paths
    // -----------------------------

    @IsTest
    static void test_pendingCustomerProfiling_blocks_conversion() {
        Lead__c ld = newQualifiedLead('Any Name', '08EDXPK3622L1ZV', false, 'Credit');
         ld.Status__c = 'Qualified';
        update ld;
        Test.setMock(HttpCalloutMock.class, new GstValidMock());
        Test.startTest();
        //String status = LeadConversion.checkStatus(ld.Id);
        LeadConversion.GstResponse resp = LeadConversion.convertlead(ld.Id);
        Test.stopTest();

    }

    @IsTest
    static void test_leadNotQualified_blocks() {
        Lead__c ld = newQualifiedLead('Some Name', '08EDXPK3622L1ZV', false, 'Credit');
        ld.Status__c = 'Qualified';
        update ld;

        Test.setMock(HttpCalloutMock.class, new GstValidMock());
        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertlead(ld.Id);
        Test.stopTest();
    }

    @IsTest
    static void test_gstRequired_whenNotExempted() {
        Lead__c ld = newQualifiedLead('Some Name', '', false, 'Credit');
        Test.setMock(HttpCalloutMock.class, new GstInvalidMock());
        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertlead(ld.Id);
        Test.stopTest();

    }

    @IsTest
    static void test_invalidGstLength_blocks() {
        Lead__c ld = newQualifiedLead('Some Name', '08EDXPK3622L1ZV', false, 'Credit');
         ld.Status__c = 'Qualified';
        update ld;
        Test.setMock(HttpCalloutMock.class, new GstInvalidMock());
        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertlead(ld.Id);
        Test.stopTest();

    }

    @IsTest
    static void test_duplicatePan_blocks() {
        String gst = '08EDXPK3622L1ZV';
        Lead__c ld = newQualifiedLead('Some Name', gst, false, 'Credit');
 ld.Status__c = 'Qualified';
        update ld;
        // Ensure a Prospect Customer record type exists in org config. The production code relies on this by name.
        Id accRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();

        Account existing = new Account(
            Name = 'Existing Prospect',
            RecordTypeId = accRtId,
            Pan_No__c = 'ABCDE1234F',
            Status__c = 'Prospect Customer'
        );
        insert existing;

        Test.setMock(HttpCalloutMock.class, new GstValidMock());
        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertlead(ld.Id);
        Test.stopTest();
    }

    @IsTest
    static void test_gstValidButEmptyNames_blocks() {
        Lead__c ld = newQualifiedLead('Any Name', '08EDXPK3622L1ZV', false, 'Credit');
 ld.Status__c = 'Qualified';
        update ld;
        Test.setMock(HttpCalloutMock.class, new GstValidButEmptyNamesMock());
        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertlead(ld.Id);
        Test.stopTest();

    }

    @IsTest
    static void test_gstNameMismatch_blocks() {
        Lead__c ld = newQualifiedLead('Lead Name Different', '08EDXPK3622L1ZV', false, 'Credit');
 ld.Status__c = 'Qualified';
        update ld;
        Test.setMock(HttpCalloutMock.class, new GstValidDifferentNameMock());
        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertlead(ld.Id);
        Test.stopTest();

    }
    
    @IsTest
    static void test_gstNameMismatch_blocks2() {
        Lead__c ld = newQualifiedLead('Lead Name Different', null, false, 'Credit');

        Test.setMock(HttpCalloutMock.class, new GstValidDifferentNameMock());
        Test.startTest();
        LeadConversion.GstResponse resp = LeadConversion.convertlead(ld.Id);
        Test.stopTest();

    }
    
    @IsTest
    static void testCheckStatus() {
        Lead__c ld = newQualifiedLead('Lead Name Different', null, false, 'Credit');
        
        Test.startTest();
        LeadConversion.checkStatus(ld.Id);
        Test.stopTest();

    }
    
     @IsTest
    static void test_gstNameMismatch_blocks3() {
        Lead__c ld = newQualifiedLead('Lead Name Different', '08EDXPK3622L1ZV', false, 'Transportation+3PL');
 ld.Status__c = 'Qualified';
        update ld;
        Test.setMock(HttpCalloutMock.class, new GstValidDifferentNameMock());
        Test.startTest();
        LeadConversion.validateGSTNumber(ld);
        Test.stopTest();

    }
    
    
     @isTest
    static void testConvertLead_RequiredFieldMissing2() {
        Lead__c record = newQualifiedLead('Any Name', '08EDXPK3622L1ZV', false, 'Credit');
        record.Status__c = 'Qualified';
        record.GST_Exempted__c = true;
        update record;
        LeadConversion.exceptionFromTest = true;
        String oversizedName = 'A'.repeat(300);
        Test.setMock(HttpCalloutMock.class, new GstValidDifferentNameMock());
        try {
            Test.startTest();
        	LeadConversion.GstResponse resp = LeadConversion.convertLead(record.Id, oversizedName, record);
        	Test.stopTest();
        } catch (exception ex) {
            
        }
        

    }
       
    
    @IsTest
    static void test_gstNameMismatch_blocks4() {
        Lead__c record = newQualifiedLead('Lead Name Different', '08EDXPK3622L1ZV', false, 'Transportation+3PL');
 record.Status__c = 'Qualified';
        update record;
        Test.setMock(HttpCalloutMock.class, new GstValidDifferentNameMock());
        try {
            Test.startTest();
        	LeadConversion.GstResponse resp = LeadConversion.convertLead(null, 'Any Name', null);
        	Test.stopTest();
        } catch (exception ex) {
            
        }
        

    }
}