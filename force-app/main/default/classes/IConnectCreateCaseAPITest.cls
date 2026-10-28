/**
* @File Name          : IConnectCreateCaseAPI.cls
* @Description        : This class will used to cover code of IConnectCreateCaseAPI
* @Author             : K SANSI
* @Group              : IBM
* @Last Modified By   : K SANSI
* @Last Modified On   : 27/10/2023
**/
@isTest
public class IConnectCreateCaseAPITest {
	
    @isTest
    static void createCaseErrorTest(){
        
        IConnectCreateCaseAPI.RequestWrapper fakeResponse = new IConnectCreateCaseAPI.RequestWrapper();
    	String JsonMsg=JSON.serialize(fakeResponse);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/iConnectCreateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	IConnectCreateCaseAPI.createCase();
        Test.stopTest();
        
        // Asserts
        List<API_Logger__c> logList = [SELECT Id, API_Name__c FROM API_Logger__c];
        System.assert(logList.size() > 0);
        System.assertEquals('iConnectCreateSupportCase',logList[0].API_Name__c) ;
        
    }
    
    @isTest
    static void createCaseSuccessTest(){
        
        IConnectCreateCaseAPI.RequestWrapper fakeResponse = new IConnectCreateCaseAPI.RequestWrapper();
        fakeResponse.caseNature ='Request';
        fakeResponse.caseType ='Booking Request';
        fakeResponse.subType ='Retail- PRC';
        fakeResponse.requesterName ='Air force school';
        fakeResponse.requesterPhone ='1231231231';
        fakeResponse.requesterAddress ='--';
        fakeResponse.requesterGSTIN ='';
        fakeResponse.pickDateTime = Date.today().year()+'-'+Date.today().month()+'-'+Date.today().day()+' 15:38:13';// JSON.serialize(Datetime.now()).replace('"','');
        fakeResponse.numOfPices =123;
        fakeResponse.fromLocn ='BANGALORE-11';        
        fakeResponse.toLocn ='';
        fakeResponse.fromPincode ='302018';
        fakeResponse.toPincode ='341514';
        fakeResponse.mop ='TO-PAY';
        fakeResponse.mode ='SURFACE';
        fakeResponse.requesterEmail ='test@test.com';
        fakeResponse.consigneeEmail ='';
        fakeResponse.pickType ='';
        fakeResponse.weight =123;
        fakeResponse.chatDetails ='';
        fakeResponse.source ='API';
        fakeResponse.remarks ='remarks';        
        fakeResponse.wayBillNumber ='';
        fakeResponse.consigneeName ='';
        fakeResponse.consigneeGSTIN ='';
        fakeResponse.reqNo ='';
        fakeResponse.sfxPrcCode ='';
        fakeResponse.msaCode ='';
        fakeResponse.requesterDealerCode ='';
        fakeResponse.consigneeDealerCode ='';
        fakeResponse.ewaybills ='';             
        fakeResponse.Consignor_Address_Line_1 ='Delhi 11'; 
        
    	String JsonMsg=JSON.serialize(fakeResponse);
                  
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();        
        req.requestURI = '/iConnectCreateSupportCase/';   
        req.httpMethod = 'POST';         
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        	IConnectCreateCaseAPI.createCase();
        Test.stopTest();
        
        // Asserts        
        List<Case> caseList = [SELECT Id FROM Case];
        System.assert(caseList.size() > 0);
        
    }
}