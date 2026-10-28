@IsTest(SeeAllData = true)
public class MSAPushApiTest {
    private class MockHttpResponseGenerator2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            String jsonResponse = 
                '{"message": "MSA Created, Oppertunity Created with ID = 6766", "data": {"responseData": {"MSA_CODE": "MSA10002804","MSA_CUST_KEY": 2990}, "referenceData": {}}, "status": "SUCCESS"}';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setHeader('Authorization','00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW');
            //objResponse.setTimeout(30000);      
            objResponse.setBody(jsonResponse);
            objResponse.setStatusCode(200);
            return objResponse;
        }
    }
    
    private class MockHttpResponseGenerator3 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            String jsonResponse =  '{"message": "MSA Created, Oppertunity Created with ID = 6766", "data": {"responseData": {"MSA_CODE": "MSA10002804","MSA_CUST_KEY": 2990}, "referenceData": {}}, "status": "SUCCESS"}';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setBody(jsonResponse);
            objResponse.setStatusCode(401);
            return objResponse;
        }
    } 
    static testMethod void testPostMethod(){
        Account Parent = CommonDataTest.getParentAccount();
        Account objPro = new Account(
            name = 'TEST PROSPECT ACCOUNT',
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId(),
            Type = 'Credit',
            region__c = 'DELHI'
        );
        Insert objPro;
        Opportunity__c Opp = new Opportunity__c(
            Name = 'Test',
            Account__c = objPro.id,
            Type__c = 'Retail',
            X3PL_Potential__c = 23       
        );
        Insert Opp;
        
        Branch_Master__c Branch = new Branch_Master__c(
            Name = 'Test Branch',
            Branch_Code__c= 'TBB'
        );   
        Insert Branch;
        
        /*Business_Detail__c BD = New Business_Detail__c (
            Opportunity__c = Opp.id,
            Collection_Branch__c = Branch.Id,
            Submission_Branch__c = Branch.Id,
            Booking_Branch__c = Branch.Id
        );
        Insert BD; */
        User usrBDM =  CommonDataTest.getUserBdm();
        insert usrBDM;
        Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            insert msaAccount;
            System.assertNotEquals(msaAccount.Id, Null);
            
        Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon ;
            Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        Contract__c c = new Contract__c();
            c.Account__c = objPro.Id;
            c.Contract_Start_Date_MOU_Date__c = Date.today();
            c.Is_valid__c = True;
            c.Credit_Term__c = 'GB';
            c.Contract_End_Date__c = date.newInstance(2025, 12, 31);
            c.Bill_Cycle__c = 'Fortnightly';
            c.Service_Requirements__c = 'service';
            c.Claim_Understanding__c = 'Owners Risk';
            c.Description__c = 'description';
            c.Contract_Copy_enclosed__c = 'Yes';
            c.MOU_enclosed__c = 'Yes';
            c.Bill_Submission__c = 'Local';
            c.Bill_Collection__c = 'Local';
            c.Customer_Signed_by_Customer__c = objCon.Id;
            c.Customer_Signed_date__c = Date.Today();
            c.Contract_Signed_by_Safexpress__c = usrBDM.Id;
            c.Safexpress_signed_date__c = Date.today();
            c.Freight_MIS_required__c = 'Yes';
            c.POD_Link_Required__c = 'Yes';
            c.RecordTypeId = openRecordTypeId;
            insert c;
            
            Id rIdquoteNew = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId();
            
            Quote__c objQuo = CommonDataTest.getQuote();
            objQuo.Opportunity__c = Opp.Id;  
            objQuo.Enter_Remarks__c = null;
            objQuo.recordTypeId = rIdquoteNew;
            objQuo.Status__c = 'Sent to Customer';
            insert objQuo;
            
        
        Opp.Stage__c = 'Closed Won';
        Opp.Contract__c = c.Id;
            Opp.LatestQuote__c = objQuo.Id;
        Update Opp;
        
        Integration_Transaction__c reqDetail = new Integration_Transaction__c();
        reqDetail.Object_Name__c = 'Opportunity__c';
        reqDetail.record_id__c = Opp.Id; 
        reqDetail.Operation_Type__c = 'CreateOpportunityPropeli' ;
        reqDetail.No_of_Retries__c = 1;
        reqDetail.MSAPushEndpoint__c = 'www.google.com';
        insert reqDetail;
        
        
        Test.startTest();
        cls_RecursiveHandler.bol_isTesting2= true;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
        //  Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator3());
        MSAPushApi.MSAFromSF(reqDetail.Record_Id__c, System.Label.MSAPushEndpointCC, reqDetail.Id);
        Test.stopTest();    
        
    } 
    
    static testMethod void testPostMethod1(){
        //jsonParser2 JSONTest2 = new jsonParser2(); 
        Account Parent = CommonDataTest.getParentAccount();
        Account objPro = new Account(
            name = 'TEST PROSPECT ACCOUNT',
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId(),
            Type = 'Credit',
            region__c = 'DELHI'
        );
        Insert objPro;
        Opportunity__c Opp = new Opportunity__c(
            Name = 'Test',
            Account__c = objPro.id,
            Type__c = 'Retail',
            X3PL_Potential__c = 23       
        );
        Insert Opp;
        
        Branch_Master__c Branch = new Branch_Master__c(
            Name = 'Test Branch',
            Branch_Code__c= 'TBB'
        );   
        Insert Branch;
        
        /*Business_Detail__c BD = New Business_Detail__c (
            Opportunity__c = Opp.id,
            Collection_Branch__c = Branch.Id,
            Submission_Branch__c = Branch.Id,
            Booking_Branch__c = Branch.Id
        );
        Insert BD;  */
        User usrBDM =  CommonDataTest.getUserBdm();
        insert usrBDM;
        Account msaAccount = CommonDataTest.getMSAAccount();
            String msaNumber = msaAccount.Propel_MSACode__c;
            insert msaAccount;
            System.assertNotEquals(msaAccount.Id, Null);
            
        Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon ;
            Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        Contract__c c = new Contract__c();
            c.Account__c = objPro.Id;
            c.Contract_Start_Date_MOU_Date__c = Date.today();
            c.Is_valid__c = True;
            c.Credit_Term__c = 'GB';
            c.Contract_End_Date__c = date.newInstance(2025, 12, 31);
            c.Bill_Cycle__c = 'Fortnightly';
            c.Service_Requirements__c = 'service';
            c.Claim_Understanding__c = 'Owners Risk';
            c.Description__c = 'description';
            c.Contract_Copy_enclosed__c = 'Yes';
            c.MOU_enclosed__c = 'Yes';
            c.Bill_Submission__c = 'Local';
            c.Bill_Collection__c = 'Local';
            c.Customer_Signed_by_Customer__c = objCon.Id;
            c.Customer_Signed_date__c = Date.Today();
            c.Contract_Signed_by_Safexpress__c = usrBDM.Id;
            c.Safexpress_signed_date__c = Date.today();
            c.Freight_MIS_required__c = 'Yes';
            c.POD_Link_Required__c = 'Yes';
            c.RecordTypeId = openRecordTypeId;
            insert c;
            
            Id rIdquoteNew = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId();
            
            Quote__c objQuo = CommonDataTest.getQuote();
            objQuo.Opportunity__c = Opp.Id;  
            objQuo.Enter_Remarks__c = null;
            objQuo.recordTypeId = rIdquoteNew;
            objQuo.Status__c = 'Sent to Customer';
            insert objQuo;
            
        
        Opp.Stage__c = 'Closed Won';
        Opp.Contract__c = c.Id;
            Opp.LatestQuote__c = objQuo.Id;
        Update Opp;
        
        
        
        
        Integration_Transaction__c reqDetail = new Integration_Transaction__c();
        reqDetail.Object_Name__c = 'Opportunity__c';
        reqDetail.record_id__c = Opp.Id; 
        reqDetail.Operation_Type__c = 'CreateOpportunityPropeli' ;
        reqDetail.No_of_Retries__c = 1;
        reqDetail.MSAPushEndpoint__c = 'www.google.com';
        insert reqDetail;
        
        Test.startTest();
        cls_RecursiveHandler.bol_isTesting1= false;
        cls_RecursiveHandler.bol_isTesting2 = true;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator3());
        //  Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator3());
        //MSAPushApi.MSAFromSF(Opp.id, System.Label.MSAPushEndpointCC);
     
        //IntegrationUtility.createIntegrationTransaction(objIntegrationlog1);
        MSAPushApi.MSAFromSF(reqDetail.Record_Id__c, System.Label.MSAPushEndpointCC, reqDetail.Id);
        Test.stopTest();    
        
    } 
    
    static testMethod void testPostMethod2(){
        //test method to cover the access token
        Test.startTest();
        cls_RecursiveHandler.bol_isTesting1= false;
        cls_RecursiveHandler.bol_isTesting2 = true;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator3());
        cls_AddTokenBillingSystem.addToken('HSGDGGDGGDGDGGDG6cv8c2s96nia5tditi4101uae6', '0052y000000SXgbAAG');
        String tokenAuth = cls_AddTokenBillingSystem.GetToken('0052y000000SXgbAAG');
        Test.stopTest();    
        
    } 
}