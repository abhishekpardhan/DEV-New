/**
 * Description		:		Test class for BranchMasterUpsertAPI apex class
 * 
 * Coverage			:		100%
 **/
@IsTest
private class BranchMasterUpsertAPITest{
    static testMethod void testPostMethod()
    {
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/SFXBranchCreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        BranchMasterUpsertAPI.jsonWrap cust = new BranchMasterUpsertAPI.jsonWrap();
        cust.Branch_ID = 43521;
        cust.Branch_Code = 'KOL1';
        cust.Branch_Type = 'FOR';
        cust.Effective_Date= Date.today();
        cust.Expiry_Date= Date.today()+10;
        
        List<BranchMasterUpsertAPI.jsonWrap> lstWrap = new List<BranchMasterUpsertAPI.jsonWrap>();
        lstWrap.add(cust);
        Test.startTest();
        BranchMasterUpsertAPI.createBranch(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();        
        System.assert(testStr != null);
        integer i = testStr.IndexOf('Branch_ID');        
        System.assertEquals('43521', testStr.subString(i+11,i+16));
        
    }

}