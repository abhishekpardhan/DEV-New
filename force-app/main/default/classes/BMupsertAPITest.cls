/**
* Description    :    Test class for BMupsertAPI apex class
* 
* Coverage      :    
**/
@IsTest
private class BMupsertAPITest{
    static testMethod void testPostMethod()
    {
        Branch_Master__c bm = CommonDataTest.getBranchMaster();
        bm.PropelI_Branch_ID__c = 785;
        bm.Branch_Type__c = 'TERRITORY';
        insert bm;
       
       
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/BMcreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        BMUpsertAPI.dataWrap cust = new BMUpsertAPI.dataWrap();
        BMUpsertAPI.branchListWrap blw = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw1 = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw2 = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw3 = new BMUpsertAPI.branchListWrap();
        cust.branchList= new list<BMUpsertAPI.branchListWrap>();

        blw.id = 9999;
        blw.branchName = 'CHANDIGARH-SHIMLA-BRANCH';
        blw.branchCode = 'CHANDIGARH-SHIMLA-BR';
        blw.effectiveDate = Date.today();
        blw.expiryDate = Date.today()+ 10;
        blw.operationalBranchId = 785;
        blw.branchType = 'CLB';
        
        blw1.id = 785;
        blw1.branchName = 'SHIMLA-BRANCH';
        blw1.branchCode = 'SHIMLA-BR';
        blw1.branchType = 'TERRITORY';
        blw1.effectiveDate = Date.today();
        blw1.operationalBranchId = 786;
        blw1.expiryDate = Date.today()+ 10;
        
        blw2.id = 786;
        blw2.branchName = 'SHIMLA-BRANCH';
        blw2.branchCode = 'SHIMLA-BR';
        blw2.branchType = 'AREA';
        blw2.operationalBranchId = 99;
        blw2.effectiveDate = Date.today();
        blw2.expiryDate = Date.today()+ 10;
        blw3.id = 99;
        blw3.branchName = 'SHIMLA-BRANCH';
        blw3.branchCode = 'SHIMLA-BR';
        blw3.branchType = 'REGION';
        blw3.operationalBranchId = 9;
        blw3.effectiveDate = Date.today();
        blw3.expiryDate = Date.today()+ 10;
        //system.debug('blw: ' +blw);
        //system.debug('blw1: ' +blw1);
        cust.branchList.add(blw);
        cust.branchList.add(blw1);
        //system.debug('blw:' +blw);
        //system.debug('cust:' +cust);
        List<BMUpsertAPI.dataWrap> lstWrap = new List<BMUpsertAPI.dataWrap>();
        lstWrap.add(cust);
        system.debug('===lstWrap'+lstWrap);
        Test.startTest();
        BMUpsertAPI.createBM(lstWrap);
        Test.stopTest();
        //String testStr = resp.responseBody.toString();        
        //System.assert(testStr != null);
        //integer i = testStr.IndexOf('Id');        
        //System.assertEquals('43521', testStr.subString(i+11,i+16));
        
    }
     static testMethod void testPostMethod1()
    {
        Branch_Master__c bm = CommonDataTest.getBranchMaster();
       
        Branch_Master__c bm1 = CommonDataTest.getBranchMaster();
        bm1.PropelI_Branch_ID__c = 786;
        bm1.Branch_Type__c = 'AREA';
        insert bm1;
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/BMcreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        BMUpsertAPI.dataWrap cust = new BMUpsertAPI.dataWrap();
        BMUpsertAPI.branchListWrap blw = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw1 = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw2 = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw3 = new BMUpsertAPI.branchListWrap();
        cust.branchList= new list<BMUpsertAPI.branchListWrap>();

        blw.id = 9999;
        blw.branchName = 'CHANDIGARH-SHIMLA-BRANCH';
        blw.branchCode = 'CHANDIGARH-SHIMLA-BR';
        blw.effectiveDate = Date.today();
        blw.expiryDate = Date.today()+ 10;
        blw.operationalBranchId = 785;
        blw.branchType = 'CLB';
        
        blw1.id = 785;
        blw1.branchName = 'SHIMLA-BRANCH';
        blw1.branchCode = 'SHIMLA-BR';
        blw1.branchType = 'TERRITORY';
        blw1.effectiveDate = Date.today();
        blw1.operationalBranchId = 786;
        blw1.expiryDate = Date.today()+ 10;
        
      
        blw3.branchName = 'SHIMLA-BRANCH';
        blw3.branchCode = 'SHIMLA-BR';
        blw3.branchType = 'REGION';
        blw3.operationalBranchId = 9;
        blw3.effectiveDate = Date.today();
        blw3.expiryDate = Date.today()+ 10;
        //system.debug('blw: ' +blw);
        //system.debug('blw1: ' +blw1);
        cust.branchList.add(blw);
        cust.branchList.add(blw1);
        //system.debug('blw:' +blw);
        //system.debug('cust:' +cust);
        List<BMUpsertAPI.dataWrap> lstWrap = new List<BMUpsertAPI.dataWrap>();
        lstWrap.add(cust);
        system.debug('===lstWrap'+lstWrap);
        Test.startTest();
        BMUpsertAPI.createBM(lstWrap);
        Test.stopTest();
        //String testStr = resp.responseBody.toString();        
        //System.assert(testStr != null);
        //integer i = testStr.IndexOf('Id');        
        //System.assertEquals('43521', testStr.subString(i+11,i+16));
        
    }
      static testMethod void testPostMethod2()
    {
        Branch_Master__c bm = CommonDataTest.getBranchMaster();
      
        Branch_Master__c bm1 = CommonDataTest.getBranchMaster();
        bm1.PropelI_Branch_ID__c = 786;
        bm1.Branch_Type__c = 'REGION';
        insert bm1;
     
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/BMcreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        BMUpsertAPI.dataWrap cust = new BMUpsertAPI.dataWrap();
        BMUpsertAPI.branchListWrap blw = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw1 = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw2 = new BMUpsertAPI.branchListWrap();
        BMUpsertAPI.branchListWrap blw3 = new BMUpsertAPI.branchListWrap();
        cust.branchList= new list<BMUpsertAPI.branchListWrap>();

        blw.id = 9999;
        blw.branchName = 'CHANDIGARH-SHIMLA-BRANCH';
        blw.branchCode = 'CHANDIGARH-SHIMLA-BR';
        blw.effectiveDate = Date.today();
        blw.expiryDate = Date.today()+ 10;
        blw.operationalBranchId = 785;
        blw.branchType = 'CLB';
        
        blw1.id = 785;
        blw1.branchName = 'SHIMLA-BRANCH';
        blw1.branchCode = 'SHIMLA-BR';
        blw1.branchType = 'TERRITORY';
        blw1.effectiveDate = Date.today();
        blw1.operationalBranchId = 786;
        blw1.expiryDate = Date.today()+ 10;
        blw2.id = 786;
        blw2.branchName = 'SHIMLA-BRANCH';
        blw2.branchCode = 'SHIMLA-BR';
        blw2.branchType = 'AREA';
        blw2.operationalBranchId = 99;
        blw2.effectiveDate = Date.today();
        blw2.expiryDate = Date.today()+ 10;
               
        //system.debug('blw: ' +blw);
        //system.debug('blw1: ' +blw1);
        cust.branchList.add(blw);
        cust.branchList.add(blw1);
        //system.debug('blw:' +blw);
        //system.debug('cust:' +cust);
        List<BMUpsertAPI.dataWrap> lstWrap = new List<BMUpsertAPI.dataWrap>();
        lstWrap.add(cust);
        system.debug('===lstWrap'+lstWrap);
        Test.startTest();
        BMUpsertAPI.createBM(lstWrap);
        Test.stopTest();
        //String testStr = resp.responseBody.toString();        
        //System.assert(testStr != null);
        //integer i = testStr.IndexOf('Id');        
        //System.assertEquals('43521', testStr.subString(i+11,i+16));
        
    }

    
}