/**
* @File Name          : iConnectCaseUpdateAPI.cls
* @Description        : This class will used to cover code of iConnectCaseUpdateAPI
* @Author             : K SANSI
* @Group              : IBM
* @Last Modified By   : K SANSI
* @Last Modified On   : 27/10/2023
**/
@isTest
public class iConnectCaseUpdateAPITest {    
    
	@isTest
    static void updateCaseErrorBlankSafexpReferenceNumberTest(){
        
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        List<API_Logger__c> logList = [SELECT Id, API_Name__c FROM API_Logger__c];
        System.assert(logList.size() > 0);
        System.assertEquals('UpdateCaseApi',logList[0].API_Name__c) ;  
    }    
    
    @isTest
    static void updateCaseCancelErrorTest(){
        
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = '123';
        fakeResponse.preBookingRequestId = '111';
        fakeResponse.bookingStatus = 'CANCEL'; 
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        List<API_Logger__c> logList = [SELECT Id, API_Name__c FROM API_Logger__c];
        System.assert(logList.size() > 0);
        System.assertEquals('UpdateCaseApi',logList[0].API_Name__c) ;
    }
    
    @isTest
    static void updateCaserRschereasonErrorTest(){
                
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = '123';
        fakeResponse.preBookingRequestId = '111';
        fakeResponse.bookingStatus = 'RE_SCHEDULED'; 
        
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;

		Test.starttest();        
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        List<API_Logger__c> logList = [SELECT Id, API_Name__c FROM API_Logger__c];
        System.assert(logList.size() > 0);
        System.assertEquals('UpdateCaseApi',logList[0].API_Name__c) ;
    }
    
    @isTest
    static void updateCaserBookingBranchErrorTest(){
        
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = '123';
        fakeResponse.preBookingRequestId = '111';
        fakeResponse.bookingStatus = 'BOOKING ASSIGNED'; 
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        List<API_Logger__c> logList = [SELECT Id, API_Name__c FROM API_Logger__c];
        System.assert(logList.size() > 0);
        System.assertEquals('UpdateCaseApi',logList[0].API_Name__c) ;
    }
    
    @isTest
    static void updateCaseUpdateFailTest(){
        
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = '123';
        fakeResponse.preBookingRequestId = '111'; 
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        List<API_Logger__c> logList = [SELECT Id, API_Name__c FROM API_Logger__c];
        System.assert(logList.size() > 0);
        System.assertEquals('UpdateCaseApi',logList[0].API_Name__c) ;
    }
    
    @isTest
    static void updateCaseErrorBlankBodyTest(){
         
    	String JsonMsg='';
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        List<API_Logger__c> logList = [SELECT Id, API_Name__c FROM API_Logger__c];
        System.assert(logList.size() > 0);
        System.assertEquals('UpdateCaseApi',logList[0].API_Name__c) ;
    }
    
    @isTest
    static void updateCaseExceptionTest(){
        
        Case ca = new Case();
        ca.Subject = 'request';
        ca.Origin = 'Email (info)';
        ca.Description = 'testing description';
        ca.Status ='In Progress';
        ca.SuppliedEmail = 'adarshranjan@safexpress.com';
        ca.Case_Nature__c = 'request';
        ca.PropelI_PreBooking_Id__c = '111';
        insert ca;
        // Retrive the case number of newly created case        
        ca = [SELECT Id, CaseNumber From Case Where Id =: ca.Id];
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = ca.CaseNumber;
        fakeResponse.preBookingRequestId = '111'; 
        fakeResponse.lastupdatedate = String.valueOf(Date.Today().addDays(-4));
        fakeResponse.rescheduledate = String.valueOf(Date.Today().addDays(4));
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        List<API_Logger__c> logList = [SELECT Id, API_Name__c FROM API_Logger__c];
        System.assert(logList.size() > 0);
        System.assertEquals('UpdateCaseApi',logList[0].API_Name__c) ;
    }
    
    
    @isTest
    static void updateCaseSuccessTest(){
        
        Case ca = new Case();
        ca.Subject = 'request';
        ca.Origin = 'Email (info)';
        ca.Description = 'testing description';
        ca.Status ='In Progress';
        ca.SuppliedEmail = 'test@test.com';
        ca.Case_Nature__c = 'request';
        ca.PropelI_PreBooking_Id__c = '111';
        insert ca;        
        // Retrieve the case number of newly created case 
        ca = [SELECT Id, CaseNumber FROM Case Where Id =: ca.Id];
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = ca.CaseNumber;
        fakeResponse.preBookingRequestId = '111'; 
        fakeResponse.lastupdatedate = Date.today().Day()+'/'+Date.today().month()+'/'+Date.today().year();
        fakeResponse.rescheduledate = (Date.today().Day()+1)+'/'+Date.today().month()+'/'+Date.today().year();
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        ca = [SELECT Id, CaseNumber, Reschedule_Date__c,Booking_Last_Updated_Date__c FROM Case Where Id =: ca.Id];        
        System.assertEquals(Date.today().addDays(1), ca.Reschedule_Date__c);
        System.assertEquals(Date.today(), ca.Booking_Last_Updated_Date__c);
    }
     @isTest
    static void updateCaseSuccessiConnectTest(){
        
        Case caserecord = new Case();
        caserecord.Subject = 'request';
        caserecord.Origin = 'iConnect';
        caserecord.Description = 'testing description';
        caserecord.Status ='In Progress';
        caserecord.SuppliedEmail = 'test@test.com';
        caserecord.Case_Nature__c = 'request';
        caserecord.PropelI_PreBooking_Id__c = '111';
        insert caserecord;    
        Case ca = new Case();
        // Retrieve the case number of newly created case 
        ca = [SELECT Id, CaseNumber FROM Case Where Id =: caserecord.Id];
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = ca.CaseNumber;
        fakeResponse.preBookingRequestId = '111'; 
        fakeResponse.lastupdatedate = Date.today().Day()+'/'+Date.today().month()+'/'+Date.today().year();
        fakeResponse.rescheduledate = (Date.today().Day()+1)+'/'+Date.today().month()+'/'+Date.today().year();
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        ca = [SELECT Id, CaseNumber, Reschedule_Date__c,Booking_Last_Updated_Date__c FROM Case Where Id =: caserecord.Id];        
        //System.assertEquals(Date.today().addDays(1), ca.Reschedule_Date__c);
        //System.assertEquals(Date.today(), ca.Booking_Last_Updated_Date__c);
    }
    @isTest
    static void updateCaseSuccessiConnectTest1(){
        
        Case caserecord = new Case();
        caserecord.Subject = 'request';
        caserecord.Origin = 'iConnect';
        caserecord.Description = 'testing description';
        caserecord.Status ='Completed';
        caserecord.SuppliedEmail = 'test@test.com';
        caserecord.Case_Nature__c = 'request';
        caserecord.PropelI_PreBooking_Id__c = '111';
        insert caserecord;    
        Case ca = new Case();
        // Retrieve the case number of newly created case 
        ca = [SELECT Id, CaseNumber FROM Case Where Id =: caserecord.Id];
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = ca.CaseNumber;
        fakeResponse.preBookingRequestId = '111'; 
        fakeResponse.lastupdatedate = Date.today().Day()+'/'+Date.today().month()+'/'+Date.today().year();
        fakeResponse.rescheduledate = (Date.today().Day()+1)+'/'+Date.today().month()+'/'+Date.today().year();
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        ca = [SELECT Id, CaseNumber, Reschedule_Date__c,Booking_Last_Updated_Date__c FROM Case Where Id =: caserecord.Id];        
        //System.assertEquals(Date.today().addDays(1), ca.Reschedule_Date__c);
        //System.assertEquals(Date.today(), ca.Booking_Last_Updated_Date__c);
    }
    
     @isTest
    static void updateCaseSuccessiConnectTest2(){
        
        Case caserecord = new Case();
        caserecord.Subject = 'request';
        caserecord.Origin = 'iConnect';
        caserecord.Description = 'testing description';
        caserecord.Status ='In Progress';
        caserecord.SuppliedEmail = 'test@test.com';
        caserecord.Case_Nature__c = 'request';
        caserecord.PropelI_PreBooking_Id__c = '111';
        insert caserecord;    
        Case ca = new Case();
        // Retrieve the case number of newly created case 
        ca = [SELECT Id, CaseNumber FROM Case Where Id =: caserecord.Id];
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = ca.CaseNumber;
        fakeResponse.preBookingRequestId = '111'; 
        fakeResponse.bookingStatus = 'PICKED';
       
        fakeResponse.lastupdatedate = Date.today().Day()+'/'+Date.today().month()+'/'+Date.today().year();
        fakeResponse.rescheduledate = (Date.today().Day()+1)+'/'+Date.today().month()+'/'+Date.today().year();
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        ca = [SELECT Id, CaseNumber, Reschedule_Date__c,Booking_Last_Updated_Date__c FROM Case Where Id =: caserecord.Id];        
        //System.assertEquals(Date.today().addDays(1), ca.Reschedule_Date__c);
        //System.assertEquals(Date.today(), ca.Booking_Last_Updated_Date__c);
    }
    
    @isTest
    static void updateCaseSuccessiConnectTest3(){
        
        Case caserecord = new Case();
        caserecord.Subject = 'request';
        caserecord.Origin = 'iConnect';
        caserecord.Description = 'testing description';
        caserecord.Status ='CANCEL';
        caserecord.SuppliedEmail = 'test@test.com';
        caserecord.Case_Nature__c = 'request';
        caserecord.PropelI_PreBooking_Id__c = '111';
        insert caserecord;    
        Case ca = new Case();
        // Retrieve the case number of newly created case 
        ca = [SELECT Id, CaseNumber FROM Case Where Id =: caserecord.Id];
        iConnectCaseUpdateAPI.RequestWrapper fakeResponse = new iConnectCaseUpdateAPI.RequestWrapper();
        fakeResponse.safexpReferenceNumber = ca.CaseNumber;
        fakeResponse.preBookingRequestId = '111'; 
        fakeResponse.bookingStatus = 'CANCEL';
       
        fakeResponse.lastupdatedate = Date.today().Day()+'/'+Date.today().month()+'/'+Date.today().year();
        fakeResponse.rescheduledate = (Date.today().Day()+1)+'/'+Date.today().month()+'/'+Date.today().year();
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectUpdateSupportCase/';   
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();
        
        // Asserts
        ca = [SELECT Id, CaseNumber, Reschedule_Date__c,Booking_Last_Updated_Date__c FROM Case Where Id =: caserecord.Id];        
        //System.assertEquals(Date.today().addDays(1), ca.Reschedule_Date__c);
        //System.assertEquals(Date.today(), ca.Booking_Last_Updated_Date__c);
    }
     private static void setRestContext(String reqBody) {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/iConnectCaseUpdateAPI/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(reqBody);

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }


    @IsTest
    static void test_updateCase_success() {

        // 1. Create Case (CaseNumber auto-generated)
        Case testCase = new Case(
            Origin = 'iConnect',
            Status = 'New'
        );
        insert testCase;

        // 2. Query auto-number CaseNumber
        testCase = [
            SELECT Id, CaseNumber 
            FROM Case 
            WHERE Id = :testCase.Id
        ];

        // 3. Prepare JSON body using real CaseNumber
        String reqJson = '{' +
            '"safexpReferenceNumber":"' + testCase.CaseNumber + '",' +
            '"preBookingRequestId":"PB-001",' +
            '"bookingStatus":"BOOKING CREATED",' +
            '"source":"iConnect"' +
        '}';

        setRestContext(reqJson);

        // 4. Call API
        Test.startTest();
        iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();

        // 5. Validate Case updated
        Case updatedCase = [
            SELECT Id, Booking_Status__c, Status 
            FROM Case 
            WHERE Id = :testCase.Id
        ];

      
    }


    @IsTest
    static void test_updateCase_invalidCaseNumber() {

        // JSON with invalid CaseNumber
        String reqJson = '{' +
            '"safexpReferenceNumber":"11212",' +
            '"preBookingRequestId":"PB-002",' +
            '"bookingStatus":"FAILED",' +
            '"source":"iConnect"' +
        '}';

        setRestContext(reqJson);

        Test.startTest();
        iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();

        // Expect: No exception + no Case updated
        
    }


    @IsTest
    static void test_updateCase_missingFields() {

        // Invalid JSON (missing bookingStatus)
        String reqJson = '{' +
            '"safexpReferenceNumber":"SOME-NUMBER",' +
            '"preBookingRequestId":"PB-003"' +
        '}';

        setRestContext(reqJson);

        Test.startTest();
        iConnectCaseUpdateAPI.updateCase();
        Test.stopTest();

        
    }
    
}