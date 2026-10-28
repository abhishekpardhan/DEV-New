/**
 * @File Name          : GetWaybillStatusAPITest.cls
 * @Description        : GetWaybillStatusAPITest is the test class for GetWaybillStatusAPI apex class
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 09-07-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        09-07-2021                Deepak                   Initial Version
**/

@isTest
private class GetWaybillStatusAPITest {

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{ "status": "Ok", "data": { "waybillNo": "95713989", "mop": "Credit", "pickupDate": "12-Jun-2021", "shipDate": "12-Jun-2021", "bookingBranch": "PITHAMPUR-13", "mode": "SURFACE", "dodDaccType": "DOD", "pinode": 226001, "dlvryCity": "LUCKNOW", "dlvryGty": "LUCKNOW-11", "sfxPrcCode": "SFX1071", "sfxPrcName": "HETTICH INDIA PVT LTD", "consignor": "HETTICH  INDIA  LIMITED", "cnorGstn": "23AAACH8849M1Z5", "cnorAddress": "SECTOR  5,PITHAMPUR,PITHAMPUR, DHAR, MADHYA PRADESH, 454775, IND", "cnorMobNo": "9607992836", "cnorEmailId": null, "consignee": "KRISHNA   PLY   &  HARDWARE  PVT  LTD", "cneeGstn": null, "cneeAddress": "102   KRISHNA  PLAZA,LUCKNOW,LUCKNOW, LUCKNOW, UTTAR PRADESH, 454775, IND", "cneeMob": "8127300000", "cneeEmailId": null, "freight": 910.2, "freightSt": 163.84, "edd": "18-Jun-2021", "dlvryDate": "17-Jun-2021", "dlvryType": "Scheduled", "dodDacc": { "payType": null, "insmtType": "PDC (Post Dated Cheque)", "insmNo": null, "dodDaccAmt": 111483, "inFavOf": "HETTICH", "pbleAt": "PMp", "pdcDate": "12-Jul-2021", "bankType": null, "bankName": null }, "track": [ { "eventDate": "17-Jun-2021 13:15:02", "qty": "0", "eventDescr": "Waybill Delivered: Delivered Date: 17/06/2021", "websiteMsg": "Waybill Delivered" }, { "eventDate": "17-Jun-2021 12:21:01", "qty": "10", "eventDescr": "Waybill updated delivered through SAFEDROP at 17-Jun-2021 12:20:51", "websiteMsg": "Waybill Undelivered" }, { "eventDate": "17-Jun-2021 07:45:58", "qty": "10", "eventDescr": "Out for Delivery UP32JN7386", "websiteMsg": "Waybill Out for Delivery " }, { "eventDate": "17-Jun-2021 07:45:43", "qty": "10", "eventDescr": "Gatepass Created.", "websiteMsg": "Gatepass created" }, { "eventDate": "15-Jun-2021 14:41:29", "qty": "0", "eventDescr": "Waybill updated undelivered through SAFEDROP at 15-Jun-2021 14:41:28 (Reason : DOD/COD REFUSED)", "websiteMsg": "Waybill Undelivered" }, { "eventDate": "15-Jun-2021 08:17:02", "qty": "10", "eventDescr": "Out for Delivery UP32JN7386", "websiteMsg": "Waybill Out for Delivery " }, { "eventDate": "15-Jun-2021 07:40:11", "qty": "10", "eventDescr": "Gatepass Created.", "websiteMsg": "Gatepass created" }, { "eventDate": "14-Jun-2021 23:02:12", "qty": "10", "eventDescr": "Hub Unloading Tally Updated / Consignment received at LKW402", "websiteMsg": "Waybill Arrived At LUCKNOW-402" }, { "eventDate": "14-Jun-2021 20:06:48", "qty": "10", "eventDescr": "RPS Created/Updated,Vehicle UP32MN1987 is Departed LKW402", "websiteMsg": "Waybill In Transit To Next Hub " }, { "eventDate": "14-Jun-2021 13:16:53", "qty": "10", "eventDescr": "Waybill reached final destination", "websiteMsg": "Waybill Arrived At LUCKNOW-11" }, { "eventDate": "13-Jun-2021 14:35:24", "qty": "10", "eventDescr": "RPS Created/Updated,Vehicle UP70HT1230 is Departed LKW11", "websiteMsg": "Waybill In Transit To Next Hub " }, { "eventDate": "12-Jun-2021 23:41:39", "qty": "10", "eventDescr": "Hub Unloading Tally Updated / Consignment received at IDR11", "websiteMsg": "Waybill Arrived At INDORE-11" }, { "eventDate": "12-Jun-2021 20:39:05", "qty": "10", "eventDescr": "RPS Created/Updated,Vehicle MP41HA0626 is Departed IDR11", "websiteMsg": "Waybill In Transit To Next Hub " }, { "eventDate": "12-Jun-2021 19:52:56", "qty": "10", "eventDescr": "Hub Unloading Tally Updated / Consignment received at PMP11", "websiteMsg": "Waybill Arrived At PITHAMPUR-11" }, { "eventDate": "12-Jun-2021 13:31:51", "qty": "10", "eventDescr": "Waybill Generated For LUCKNOW(LUCKNOW-11) - Pickup Date: 12/06/2021 13:08 and Ship Date: 12/06/2021", "websiteMsg": "Waybill Generated at PITHAMPUR-13" } ] }, "message": null, "responseId": "0a424991-135b-4a6c-9165-9e48985d37f2" }');
            return res;
        }
    }
    @testSetup static void createTestData() {
        String endpoint = 'www.google.com';
        Safex_API__c safexApi = TestDataFactory.createSafexAPI(ConstantUtility.WAY_BILL_API_NAME,'test','basic',null,null,endpoint,'testUser','testPassword');
        insert safexApi;
        
        id recordId=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();  //recordId Added by sourabh Singh
        List<Case> cases = TestDataFactory.createCases('Test', recordId ,ConstantUtility.NEW_STATUS,1);
        cases[0].WaybillNo__c = '12345678';
        insert cases;


    }
    static testMethod void getWayBillInfoTest() {
        Test.startTest();
        try {
            Test.setMock(HttpCalloutMock.class, new Mock());
            GetWaybillStatusAPI.getWayBillInfo('95713989');
        } catch (exception e) {}
        Test.stopTest();
    }
    static testMethod void getWayBillInfoTest_ForCallOutException() {
        Test.startTest();
        try {
            GetWaybillStatusAPI.getWayBillInfo('95713989');
        } catch (exception e) {}
        Test.stopTest();
    }
    static testMethod void getWayBillInfoTest_ForNoAPIInfoException() {
        Test.startTest();
        Safex_API__c safexApi = [SELECT Username__c FROM Safex_API__c LIMIT 1];
        safexApi.Username__c = null;
        update safexApi;
        try {
            Test.setMock(HttpCalloutMock.class, new Mock());
            GetWaybillStatusAPI.getWayBillInfo('95713989');
        } catch (exception e) {}
        Test.stopTest();
    }
    static testMethod void getCasesTest() {
        Test.startTest();
        String casesString =  GetWayBillStatusAPI.getCases('12345678',1);
        Test.stopTest();
    }
    //added by Sourabh Singh to cover the catch Block
    static testMethod void getCasesCoverExceptionCases()
    {
        try{
            Test.startTest();
            String casesString =  GetWayBillStatusAPI.getCases('12345678',NUll);
            Test.stopTest();
        }
        catch(Exception ex)
        {
            system.debug('inside Exception case');
        }     
    }
    
    static testMethod void getWayBillInfoTest_UpdateWayBillNumber() {
        List<Case> cases = [SELECT Id FROM Case];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        	GetWaybillStatusAPI.getWayBillInfo('95713989', cases[0].Id, true);         
        Test.stopTest();
        // Asserts
        cases = [SELECT Id, WaybillNo__c FROM Case WHERE Id =: cases[0].Id];
        System.assertEquals('95713989', cases[0].WaybillNo__c);
    }
    
    static testMethod void getWayBillInfoTest_UserNotHavingAccessToUpdateWayBillNumber() {
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        List<Case> cases = [SELECT Id FROM Case];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
            System.runAs(us){
                GetWaybillStatusAPI.getWayBillInfo('95713989', cases[0].Id, true); 
            }
        	        
        Test.stopTest();
        // Asserts
        cases = [SELECT Id, WaybillNo__c FROM Case WHERE Id =: cases[0].Id];
        System.assertNotEquals('95713989', cases[0].WaybillNo__c);
    }
    
    static testMethod void getWayBillInfoTest_ClosedCaseUpdateCheck() {
        User us = CommonDataTest.getUserServiceCloudExecutive();
        insert us;
        
        Case closedcase = [SELECT Id FROM Case LIMIT 1];
        closedcase.OwnerId = us.Id;
        closedcase.Status = 'Completed';
        update closedcase;
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new Mock());
            System.runAs(us){
                GetWaybillStatusAPI.getWayBillInfo('95713989', closedcase.Id, true); 
            }
        	        
        Test.stopTest();
        
        // Asserts
        closedcase = [SELECT Id, WaybillNo__c FROM Case WHERE Id =: closedcase.Id];
        System.assertNotEquals('95713989', closedcase.WaybillNo__c);
    }
    
}