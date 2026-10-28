/**
 * Description		:		Test class for CaseUpdateApi apex class
 * JIRA ticket       :		https://safexpress.atlassian.net/browse/SD-453
 * Last Modified By  :      Shubham Girdhar
 * Last Modified Date:      06/01/2020
 * Coverage			:		78%
 **/
@isTest 
public class CaseUpdateApiTest{
    static testMethod void testMethod1() {

        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
                
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
                      
        Case__c objCase = CommonDataTest.getCase('Operation Issues');
        objCase.Account__c  = objSfx.Id;
        objCase.Assigned_To__c = us.Id;
        objCase.Status__c = 'Active';
        objCase.Waybill_Numbers__c = '12345678';
        insert objCase;
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/CasesUpdate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        CaseUpdateApi.jsonWrap caseJsn = new CaseUpdateApi.jsonWrap();
        caseJsn.Case_Id = objCase.Id;
        caseJsn.Token_No = '12345';
        caseJsn.Proton_Remarks = 'Test proton';
        
        List<CaseUpdateApi.jsonWrap> lstWrap = new List<CaseUpdateApi.jsonWrap>();
        lstWrap.add(caseJsn);
        Test.startTest();
        CaseUpdateApi.updateOperationalCase(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        System.debug('====testStr ===='+testStr);
        System.assert(testStr != null);
        integer i = testStr.IndexOf('isSuccess');
        System.debug('====I===='+i);
        System.assertEquals('true', testStr.subString(i+11,i+15));
        
        
    }
}