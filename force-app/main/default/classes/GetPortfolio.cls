/**
* @File Name          : CreateCaseApi.cls
* @Description        : This class will used to create complain Cases in salesforce using API.
* @Author             : Shubham
* @Group              : Safexpress
* @Last Modified By   : Shubham
* @Last Modified On   : 30/01/2021
**/
@RestResource(urlMapping='/GetPortfolio/*')
global with sharing class GetPortfolio {
     

    @HttpPost
    global static void GetPortfolio() {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        RestRequest request = RestContext.request; 
        String requestBody = request.requestBody != null ? request.requestBody.toString() : '';
        System.debug('########'+ request);
        System.debug('@@@@@@@@@@'+ requestBody);
     try{
        if(!String.isBlank(requestBody)){
            RequestWrapper requestWrapper = (RequestWrapper) System.JSON.deserialize(requestBody, RequestWrapper.class);
          if(requestWrapper != null){
 system.debug('Response wrapper:'+  requestWrapper );

List<Account> AccList = new List<Account>();
List<Account_Team__c> AccTeamList = new List<Account_Team__c>();
Id sfxAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();


system.debug('SFX:'+ requestWrapper.sfx);
system.debug('branch:'+ requestWrapper.branch);
if(requestWrapper.sfx != ''){
string integrationUserId = system.label.branchMasterUserId;
Id amProfileId = [select id, name From profile where name = 'Area Manager'].id;
Id rmProfileId = [select id, name From profile where name = 'Regional Manager'].id;
Account acc = [Select id, name , Booking_Branch__c,Booking_Branch__r.name, SFX_Code__c  from Account where SFX_Code__c  =: requestWrapper.sfx AND Booking_Branch__r.name =: requestWrapper.branch and recordtypeid =: sfxAccount limit 1];
Branch_Master__c branch = [select id, name,Area__c,Region__c, Branch_Code__c,  City__c, Fusion_Branch_Id__c from Branch_Master__c where name =:requestWrapper.branch AND createdbyId =: integrationUserId limit 1 ];
User areaManager = [select id, FirstName,LastName,Name, Email,MobilePhone,Region__c,area__c From user where area__c =: branch.Area__c AND profileId =: amProfileId and IsActive = true LIMIT 1];
User regionalManager = [select id, FirstName,LastName,Name ,Email,MobilePhone,Region__c,area__c From user where Region__c =: branch.Region__c AND profileId =: rmProfileId and IsActive = true LIMIT 1];
system.debug('AccountList:'+ Acc);
system.debug('Branch Detail:'+ branch);
system.debug('Area Manager:'+ areaManager);
system.debug('Regional Manager:'+ regionalManager);
if(acc != null ){
    AccTeamList = getAccTeam(acc);
    system.debug('Account team Data:'+ AccTeamList);
 }
list<cls_data> accountTeamList = new list<cls_data>();
for(Account_Team__c ateam : AccTeamList ){
    cls_data accteam =  new cls_data();
        accteam.bdm = string.valueOf(ateam.BDM__r.Name);
        accteam.phone = string.valueOf(ateam.BDM__r.MobilePhone);
        accteam.email = string.valueOf(ateam.BDM__r.Email);
        accteam.relationship = string.valueOf(ateam.Relationship__c);
        accteam.collection = string.valueOf(ateam.Collection__c);
        accteam.submittion = string.valueOf(ateam.Submission__c);
        accteam.nsm = string.valueof(ateam.NSM__c);
        accteam.ccd = string.valueOf(ateam.National1__c);
        accteam.localNam = string.valueOf(ateam.National2__c);
        accteam.qrm = string.valueOf(ateam.National3__c);
        accteam.revenueManagement = string.valueOf(ateam.National4__c); 
        accountTeamList.add(accteam);     
    }

    system.debug('##########'+ accountTeamList);

    Portfolio createPortfolio = new Portfolio();
    createPortfolio.sfx = string.valueOf(acc.SFX_Code__c);
    createPortfolio.branch = string.valueOf(acc.Booking_Branch__r.name);
    createPortfolio.amName = string.valueOf(areaManager.Name);
    createPortfolio.amPhone = string.valueOf(areaManager.MobilePhone);
    createPortfolio.amEmail = string.valueOf(areaManager.Email);
    createPortfolio.rmName = string.valueOf(regionalManager.Name);
    createPortfolio.rmPhone = string.valueOf(regionalManager.MobilePhone);
    createPortfolio.rmEmail = string.valueOf(regionalManager.Email);
    createPortfolio.accountTeam = accountTeamList;

    system.debug('&&&&&&&&&&&&&&&&json responce'+createPortfolio );

    String str = JSON.serialize(createPortfolio);

    system.debug('Json string:'+str);
 
    responseWrapper = createResponse(createPortfolio , '200', 'Success'); 
}else{
    responseWrapper = createResponse(null , '500', 'SFX code is missing');
 }
           }
           // responseWrapper = createResponse('Sucess', '200','00001411'); 
           }
        }catch(exception exp){
            responseWrapper = createResponse(null,'501' ,exp.getMessage());
            LoggerUtil.createErrorLog('CreateComplainCaseAPI','createCase', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
       // LoggerUtil.createAPILog('CreateComplainCaseAPI', 'TO Salesforce', requestBody, JSON.serialize(responseWrapper), null);
           if(!Test.isRunningTest()){
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
        }

     }

     public static ResponseWrapper createResponse(Portfolio Portfolio, String status, String message) {
        ResponseWrapper responseWrapper = new ResponseWrapper();
        responseWrapper.Portfolio = Portfolio;
        responseWrapper.status = status;
        responseWrapper.message = message; 
        return responseWrapper;
    }
    global class ResponseWrapper {
        
        global String status;
        global Portfolio Portfolio;
        global String message;
        
    }

   /* global class RequestWrapper {
        global String sfx;
        global String branch;
        } */
 /*public class RequestWrapper{
	public List<cls_Data> Data;
}*/
	class RequestWrapper {
		public String sfx;	//SFX16881
		public String branch;	//NOIDA-12
	}

public static List<Account_Team__c> getAccTeam(Account acc){    
Set<Id> accId = new set<Id>();
List<Account_Team__c> accTeamlist = new List<Account_Team__c>();
accTeamlist = [SELECT Account_Name__c,Account__c,Account__r.name,Account__r.Booking_Branch__r.name,BDM__c,BDM__r.Name,BDM__r.Email,BDM__r.MobilePhone,Collection__c,National1__c,National2__c,National3__c,National4__c,Composite_key__c,NSM__c,CRS__c,Id,Is_PropelI__c,MSA__c,Name,Parent_Account_Id__c,Parent_Parent_Id__c,Relationship__c,Submission__c FROM Account_Team__c where Account__c =: acc.id AND Is_PropelI__c = false ];
return accTeamlist;
}

public class Portfolio{
	public String sfx;	//SFX0001
	public String branch;	//Delhi11
	public String amName;	//Mintu Kumar
	public String amPhone;	//1234567890
	public String amEmail;	//test@gmail.com
	public String rmName;	//Niyaz Ahemad
	public String rmPhone;	//1234567890
	public String rmEmail;	//Niyaz@gmail.com
	public List<cls_data> accountTeam;
}
public class cls_data {
		public String bdm;
        public String phone;
        public String email;	//Shubham Girdhar
		public String relationship;	//true
		public String collection;	//true
		public String submittion;	//true
		public String nsm;	//false
		public String ccd;	//false
		public String localNam;	//false
		public String qrm;	//false
		public String revenueManagement;	//true
	}

}