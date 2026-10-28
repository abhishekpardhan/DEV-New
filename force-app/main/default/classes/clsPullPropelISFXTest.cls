@IsTest
public class clsPullPropelISFXTest {
    private class MockHttpPropelITokenResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            String jsonResponse =  '{"grant_type":"client_credentials", "scope":"sfdc/server"}';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setHeader('username','unittesting');
            objResponse.setHeader('password','unittesting123');
            objResponse.setBody(jsonResponse);
            objResponse.setStatusCode(200);
            return objResponse;
        }
    } 
    private class MockHttpPropelITokenResponse2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            String jsonResponse =  '{"grant_type":"client_credentials", "scope":"sfdc/server"}';
            HttpResponse objResponse = new HttpResponse();
            objResponse.setHeader('Content-Type','application/json');
            objResponse.setHeader('username','unittesting');
            objResponse.setHeader('password','unittesting123');
            objResponse.setBody(jsonResponse);
            objResponse.setStatusCode(400);
            return objResponse;
        }
    }
    static testMethod void unitTestMethod1(){
        Test.startTest();
        cls_RecursiveHandler.bol_isTesting2= true;
        Test.setMock(HttpCalloutMock.class, new MockHttpPropelITokenResponse());
        clsPullPropelISFX.pullSFXRecords('SFX10001');
        Test.stopTest();  
    }
    static testMethod void unitTestMethod2(){
        Test.startTest();
        cls_RecursiveHandler.bol_isTesting2= true;
        Test.setMock(HttpCalloutMock.class, new MockHttpPropelITokenResponse2());
        clsPullPropelISFX.pullSFXRecords('SFX10001');
        Test.stopTest();    
        
    }
    static testMethod void unitTestMethod3(){
        Test.startTest();
        cls_RecursiveHandler.bol_isTesting2= true;
        Test.setMock(HttpCalloutMock.class, new MockHttpPropelITokenResponse());
        clsPullPropelISFX.pullMSARecords('SFX10001');
        Test.stopTest();  
    }
    static testMethod void unitTestMethod4(){
        Test.startTest();
        cls_RecursiveHandler.bol_isTesting2= true;
        Test.setMock(HttpCalloutMock.class, new MockHttpPropelITokenResponse2());
        clsPullPropelISFX.pullMSARecords('SFX10001');
        Test.stopTest();  
    }
    static testMethod void unitTestSFXUpsert1()
    {        
        // Create MSA account. 
        Account msaAccount = CommonDataTest.getMSAAccount();
        msaAccount.Propel_MSACode__c = 'MSA00000030';
        insert msaAccount;
        String sfxJSON = '{"message":"Request Successfully completed","data":{"responseData":[{"Propel_MSACode":"MSA00000030","Msa_name":"CLAIR ELECTRONICS PVT LTD","Propel_Key":83,"id":"44","Account_Id":"0012y000009AVg6AAG","SFXCode":"SFX00000111","Contract_Sign_date":"2019-09-05","Contract_Start_date":"2019-09-05","Contract_Expiry_date":"2020-08-30","Direct_Pickup":"NO","Delivery_Hold":"NO","Business_Type":"OUTBOUND","Service_line":"DISTRIBUTION","Opportunity":"a062y000005latXAAQ","Offerings":[{"Service_Offering":"SURFACE","Rate_card":[{"rate_card_name":"RC52","id":52,"start_date":"2019-09-06","end_date":"2020-08-31","base_location":"575","status":"ACTIVE","assign_branch":[{"assign_branch_id":"66","MDM_branch_id":"552","Effective_date":"2019-09-24","Booking_hold":"0","delivery_hold":"0"}]}]},{"Service_Offering":"AIR","Rate_card":[{"rate_card_name":"RC53","id":53,"start_date":"2019-09-06","end_date":"2020-08-31","base_location":"575","status":"ACTIVE","assign_branch":[{"assign_branch_id":"67","MDM_branch_id":"552","Effective_date":"2019-09-24","Booking_hold":"0","delivery_hold":"0"}]}]}],"Billing_Info":[{"Billing_Level":"MSA","Billing_type":"CONSOLIDATION","Sfx_no":"SFX00000111","msa":"MSA00000030","Start_date":"2021-01-06","alias_name":"CLAIR ELECTRONICS PVT LTD","Billing_config_id":201,"billing_by":[{"Billing_by_id":216,"Billing_Branch":"1","Submission_branch":"575","Collection_branch":"575","Billing_address":"6-B, KHIZARABAD, 4TH FLOOR, NEW FRIENDS COLONY, KHIZARABAD,,  SOUTH DELHI 110025","Minimum_Billing":0,"Comm_bill_email":"KAMALENDU227@YAHOO.CO.IN","Monthly_Potential":0,"Credit_Risk":0}]}]}],"referenceData":{}},"status":"SUCCESS"}';
        temp_PropelISFXUpsert.createCustomer(sfxJSON);
    }
    static testMethod void unitTestPullMSAData()
    {
        String msaJSON = '{"message": "Request Successfully completed","data": {"responseData": {"x3PLPotential": 0.00,"Account_Name": "INDIAN TEA SUPPLIER","Propel_MSACode": "MSA90000383","Vertical": "APPARELS","Sub_Vertical": "READYMADE GARMENTS","Propel_Key": 0,"Contact_Person_Name": "SURAJ","Email": "SJ@GMAIL.COM","Customer_Type": "CREDIT","PAN": "CNTPN1629Q","Opportunity_Name": "INDIAN TEA SUPPLIER","Opportunity_Type": "NEW OPPORTUNITY","X3PL_Potential": 0.00,"GST_Exempted": false,"TAN_Exempted": false,"MONTHLY_POTENTIAL_AIR": 110000,"MONTHLY_POTENTIAL_SURFACE": 10000.00,"Value_of_goods_waybill": 0,"Opp_Code": "903621","BILLING_STREET": "","BILLING_CITY": "DELHI","BILLING_COUNTRY": "INDIA","BILLING_ZIP_POSTAL_CODE": 110045,"BILLING_STATE": "DELHI","INSURANCE": "No","CREATED_DATE": "2022-09-07T00:00:00.000+0530","CORPORATE_OFFICE_LOCATION": "","Account_Id": "001710000094pgIAAQ","Opportunity": "a0671000002P6gzAAC"},"referenceData": {}},"status": "SUCCESS"}';
        
        cls_PullMSAOnDemand.upsertMSA(msaJSON);
    }
    
    @isTest
    static void unitTestMethod5()
    {
        Test.startTest();
        cls_RecursiveHandler.bol_isTesting2= true;
        Test.setMock(HttpCalloutMock.class, new MockHttpPropelITokenResponse2());
        Account objSFX = CommonDataTest.getNewSFXAccount();
        insert objSFX;
        
        BatchToPullSFX objBatch = new BatchToPullSFX();
        Database.executeBatch(objBatch);
        Test.stopTest();  
    }
    
    @isTest
    static void unitTestMethod6()
    {
        Test.startTest();
        BatchToPullSFX objBatch = new BatchToPullSFX();
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, objBatch);
        Test.stopTest();  
    }
    
    @isTest
    static void unitTestMethod7()
    {
        Test.startTest();
        Account objSFX = CommonDataTest.getNewSFXAccount();
        objSFX.SFX_Code__c = null;
        insert objSFX;
        
        BatchToPullSFX objBatch = new BatchToPullSFX();
        Database.executeBatch(objBatch);
        
        Test.stopTest();  
    }
}