@isTest
private class TestCCDBDMContactDetails {

    @testSetup
    static void setupData() {
        // Create Branch_Master__c records
        List<Branch_Master__c> branches = new List<Branch_Master__c>();
        for (Integer i = 1; i <= 2; i++) {
            branches.add(new Branch_Master__c(
                Name = 'Branch ' + i,
                PropelI_Branch_ID__c = Decimal.valueOf(i)
            ));
        }
        insert branches;

        // Create Account Hierarchy with SFX and RC codes
        Account parent4 = new Account(Name = 'Parent4', Propel_MSACode__c = 'MSA001');
        insert parent4;
        
        String SFXRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();

        Account parent3 = new Account(Name = 'Parent3', ParentId = parent4.Id, SFX_Code__c = 'SFX001',RecordTypeId = SFXRecordTypeID);
        insert parent3;
        String AirRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        Account parent2 = new Account(Name = 'Parent2', ParentId = parent3.Id,RecordTypeId = AirRecordTypeID);
        insert parent2;
        String RateRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Account parent1 = new Account(Name = 'Parent1', ParentId = parent2.Id,RecordTypeId = RateRecordTypeID);
        insert parent1;

        // Create Account with Billing_Branch__c set
        String AssignRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', ParentId = parent1.Id, Billing_Branch__c = branches[0].Id,RecordTypeId = AssignRecordTypeID);
        insert acc;

        // Create User (BDM)
        User us = CommonDataTest.getUserBdm();
        us.Username = 'testbdmuser@example.com.test';
            us.Email = 'testbdmuser@example.com';
            us.Alias = 'tbdm';
            us.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
            us.TimeZoneSidKey = 'America/Los_Angeles';
            us.LocaleSidKey = 'en_US';
            us.EmailEncodingKey = 'UTF-8';
            us.LanguageLocaleKey = 'en_US';
            us.LastName = 'BDM';
            us.MobilePhone = '1234567890';
            insert us;

        // Create Account_Team__c record
        insert new Account_Team__c(
            Account__c = acc.Id,
            //BranchName__c = 'Branch 1',
            //PropeliBranchId__c = branches[0].PropelI_Branch_ID__c,
            BDMPropelI__c = us.Id,
            National2__c = true,
            Relationship__c = true
        );
    }

    static void callDoPost(String userType, String msaId, List<String> sfxIds, List<String> rcIds, List<Decimal> brIds) {
        // Build request body
        CCDBDMContactDetails.RequestWrapper req = new CCDBDMContactDetails.RequestWrapper();
        req.user_type = userType;
        req.msa_code = msaId;
        req.sfx_code = sfxIds;
        req.rc_name = rcIds;
        req.propel_i_branchid = brIds;

        String jsonBody = JSON.serialize(req);
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/ccdBdmContactDetails/';
        reqMock.httpMethod = 'POST';
        reqMock.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = reqMock;
        RestContext.response = new RestResponse();

        CCDBDMContactDetails.UserListResponse resp = CCDBDMContactDetails.doPost();
        System.assertNotEquals(null, resp);
        System.assertNotEquals(null, resp.users);
       
    }
     static void callDoPost(String userType, String msaId) {
        // Build request body
        CCDBDMContactDetails.RequestWrapper req = new CCDBDMContactDetails.RequestWrapper();
        req.user_type = userType;
        req.msa_code = msaId;
        

        String jsonBody = JSON.serialize(req);
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/ccdBdmContactDetails/';
        reqMock.httpMethod = 'POST';
        reqMock.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = reqMock;
        RestContext.response = new RestResponse();

        CCDBDMContactDetails.UserListResponse resp = CCDBDMContactDetails.doPost();
        System.assertNotEquals(null, resp);
        System.assertNotEquals(null, resp.users);
      
    }
    
    static void callDoPost(String userType, String msaId, List<String> sfxIds) {
        // Build request body
  
        CCDBDMContactDetails.RequestWrapper req = new CCDBDMContactDetails.RequestWrapper();
        req.user_type = userType;
        req.msa_code = msaId;
              if(userType == 'rc'){
                  req.sfx_code = sfxIds;
				}
        else{
             req.rc_name = sfxIds;
        }
        

        String jsonBody = JSON.serialize(req);
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/ccdBdmContactDetails/';
        reqMock.httpMethod = 'POST';
        reqMock.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = reqMock;
        RestContext.response = new RestResponse();

        CCDBDMContactDetails.UserListResponse resp = CCDBDMContactDetails.doPost();
        System.assertNotEquals(null, resp);
        System.assertNotEquals(null, resp.users);
       
    }
	
        static void callDoPost(String userType, String msaId, List<String> rcIds, List<Decimal> brIds) {
        // Build request body
        CCDBDMContactDetails.RequestWrapper req = new CCDBDMContactDetails.RequestWrapper();
        req.user_type = userType;
        req.msa_code = msaId;
        req.rc_name = rcIds;
        req.propel_i_branchid = brIds;

        String jsonBody = JSON.serialize(req);
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/ccdBdmContactDetails/';
        reqMock.httpMethod = 'POST';
        reqMock.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = reqMock;
        RestContext.response = new RestResponse();

        CCDBDMContactDetails.UserListResponse resp = CCDBDMContactDetails.doPost();
        System.assertNotEquals(null, resp);
        System.assertNotEquals(null, resp.users);
      
    }
     @isTest
    static void testDoPostForMSA() {
        callDoPost('msa', 'MSA001');
    }
    @isTest
    static void testDoPostForMSA2() {
        callDoPost('rca', 'MSA001');
    }
     @isTest
    static void testDoPostForMSA1() {
        callDoPost('msa', 'MSA501');
    }
    @isTest
    static void testDoPostForMSAnull() {
        callDoPost('msa', null);
    }
    
    @isTest
    static void testDoPostForSFX() {
        callDoPost('sfx', 'MSA001', new List<String>{'SFX001'});
    }
    @isTest
    static void testDoPostForSFX1() {
        callDoPost('sfx', 'MSA001', new List<String>{'SFX051'});
    }
     @isTest
    static void testDoPostForSFXnull() {
        callDoPost('sfx', 'MSA001', null);
    }
      @isTest
    static void testDoPostForRC() {
        callDoPost('rc', 'MSA001', new List<String>{'Parent1'});
    }
     @isTest
    static void testDoPostForRCwithbr() {
        callDoPost('rc', 'MSA001', new List<String>{'Parent1'},new List<Decimal>{1});
    }
    @isTest
    static void testDoPostForRCwithbr1() {
        callDoPost('rc', 'MSA001', new List<String>{'Parent1'},null);
    }
    
    /*@isTest
    static void testDoPostForMSA() {
        callDoPost('msa', 'MSA001', null, null, null);
    }
   

    @isTest
    static void testDoPostForBranch() {
        callDoPost('br', 'MSA001', null, null, new List<Decimal>{1});
    }

    

  

    @isTest
    static void testDoPostWithBranchFilter() {
        callDoPost('sfx', null, new List<String>{'SFX001'}, null, new List<Decimal>{1});
    }*/
}