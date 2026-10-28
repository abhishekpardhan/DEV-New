/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : FreshserviceWebServiceTest
 * Author          : <Rishank Bhardwaj>
 * Created Date    : Aug 6, 2026
 * Last Modified By: <Rishank Bhardwaj>
 * Last Modified On: Aug 6, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 6, 2026  │ <Rishank Bhardwaj>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

@IsTest
private class FreshserviceWebServiceTest {

	@TestSetup
	static void setupData(){
		Case caseRecord = buildCase('FSC-900001');

		try{
			Freshservice_UtilClass.skipFreshserviceCaseSync = true;
			insert caseRecord;
		}
		finally{
			Freshservice_UtilClass.skipFreshserviceCaseSync = false;
		}

		Test.setCreatedDate(caseRecord.Id,Datetime.newInstanceGMT(2026,8,5,10,0,0));
	}

	// Test Case Number update.
	@IsTest
	static void testCaseNumberUpdate(){
		Case caseRecord = [Select Id,CaseNumber,Subject from Case where Fresh_Service_Ticket_No__c = 'FSC-900001' LIMIT 1];

		Test.startTest();
		Map<String,Object> response = executeRequest(buildRequest(caseRecord.CaseNumber,null,new Map<String,Object>{
			'Subject' => 'Updated through Case Number'
		}));
		Test.stopTest();

		System.assertEquals(200,RestContext.response.statusCode);
		System.assertEquals(true,response.get('success'));
		System.assertEquals(String.valueOf(caseRecord.Id),String.valueOf(response.get('caseId')));
		System.assertEquals('Case updated successfully.',response.get('message'));
		System.assert(((List<Object>)response.get('updatedFields')).contains('Subject'));
		System.assertEquals('Updated through Case Number',[Select Subject from Case where Id = :caseRecord.Id].Subject);
		System.assertEquals(false,Freshservice_UtilClass.skipFreshserviceCaseSync);
	}

	// Test Freshservice ticket update.
	@IsTest
	static void testFreshserviceTicketUpdate(){
		Case caseRecord = [Select Id from Case where Fresh_Service_Ticket_No__c = 'FSC-900001' LIMIT 1];

		Test.startTest();
		Map<String,Object> response = executeRequest(buildRequest('900001','2026-08-05',new Map<String,Object>{
			'Subject' => 'Updated through Freshservice Ticket'
		}));
		Test.stopTest();

		System.assertEquals(200,RestContext.response.statusCode);
		System.assertEquals(true,response.get('success'));
		System.assertEquals('Updated through Freshservice Ticket',[Select Subject from Case where Id = :caseRecord.Id].Subject);
		System.assertEquals(false,Freshservice_UtilClass.skipFreshserviceCaseSync);
	}

	// Test blank request body.
	@IsTest
	static void testBlankRequestBody(){
		Test.startTest();
		Map<String,Object> response = executeRequest(null);
		Test.stopTest();

		System.assertEquals(400,RestContext.response.statusCode);
		System.assertEquals(false,response.get('success'));
		System.assertEquals('Request Body can not be Blank',response.get('message'));
	}

	// Test invalid JSON body.
	@IsTest
	static void testInvalidJsonBody(){
		Test.startTest();
		Map<String,Object> response = executeRequest('{');
		Test.stopTest();

		System.assertEquals(400,RestContext.response.statusCode);
		System.assertEquals(false,response.get('success'));
		System.assert(String.valueOf(response.get('message')).startsWith('Invalid JSON request body:'));
	}

	// Test blank ticket number.
	@IsTest
	static void testBlankTicketNumber(){
		Test.startTest();
		Map<String,Object> response = executeRequest(buildRequest('',null,new Map<String,Object>{
			'Subject' => 'Test Subject'
		}));
		Test.stopTest();

		System.assertEquals(400,RestContext.response.statusCode);
		System.assertEquals(false,response.get('success'));
		System.assertEquals('Ticket number cannot be blank.',response.get('message'));
	}

	// Test blank Case fields.
	@IsTest
	static void testBlankCaseFields(){
		Test.startTest();
		Map<String,Object> response = executeRequest(buildRequest('900001',null,new Map<String,Object>()));
		Test.stopTest();

		System.assertEquals(400,RestContext.response.statusCode);
		System.assertEquals(false,response.get('success'));
		System.assertEquals('Case fields cannot be blank.',response.get('message'));
	}

	// Test missing Case record.
	@IsTest
	static void testCaseNotFound(){
		Test.startTest();
		Map<String,Object> response = executeRequest(buildRequest('999999999',null,new Map<String,Object>{
			'Subject' => 'Test Subject'
		}));
		Test.stopTest();

		System.assertEquals(404,RestContext.response.statusCode);
		System.assertEquals(false,response.get('success'));
		System.assertEquals('No case found with this ticket: 999999999',response.get('message'));
	}

	// Test invalid Case field.
	@IsTest
	static void testInvalidCaseField(){
		Test.startTest();
		Map<String,Object> response = executeRequest(buildRequest('900001',null,new Map<String,Object>{
			'Wrong_Field__c' => 'Test Value'
		}));
		Test.stopTest();

		System.assertEquals(400,RestContext.response.statusCode);
		System.assertEquals(false,response.get('success'));
		System.assertEquals('Invalid Salesforce Case field: Wrong_Field__c',response.get('message'));
	}

	// Test multiple matching Cases.
	@IsTest
	static void testMultipleCases(){
		List<Case> caseList = new List<Case>{
			buildCase('FSC-DUPL-1'),
			buildCase('FSC-DUPL-1')
		};

		try{
			Freshservice_UtilClass.skipFreshserviceCaseSync = true;
			insert caseList;
		}
		finally{
			Freshservice_UtilClass.skipFreshserviceCaseSync = false;
		}

		Test.startTest();
		Map<String,Object> response = executeRequest(buildRequest('FSC-DUPL-1',null,new Map<String,Object>{
			'Subject' => 'Test Subject'
		}));
		Test.stopTest();

		System.assertEquals(409,RestContext.response.statusCode);
		System.assertEquals(false,response.get('success'));
		System.assertEquals('Multiple cases found with this ticket number FSC-DUPL-1',response.get('message'));
	}

	// Build Case test record.
	private static Case buildCase(String ticketNumber){
		return new Case(
			Subject = 'Freshservice Web Service Test',
			Status = getOpenCaseStatus(),
			Origin = getCaseOrigin(),
			Fresh_Service_Ticket_No__c = ticketNumber
		);
	}

	// Get available Case status.
	private static String getOpenCaseStatus(){
		return [Select MasterLabel from CaseStatus where IsClosed = false order by SortOrder LIMIT 1].MasterLabel;
	}

	
	// Get available Case origin.
	private static String getCaseOrigin(){
		return Case.Origin.getDescribe().getPicklistValues()[0].getValue();
	}

	// Build REST request body.
	private static String buildRequest(String ticketNumber,String createdDate,Map<String,Object> fields){
		Map<String,Object> requestBody = new Map<String,Object>{
			'ticketNumber' => ticketNumber,
			'fields' => fields
		};

		if(createdDate != null){
			requestBody.put('createdDate',createdDate);
		}

		return JSON.serialize(requestBody);
	}

	// Execute REST web service.
	private static Map<String,Object> executeRequest(String requestBody){
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/salesforce/case-update';
		request.httpMethod = 'POST';

		if(requestBody != null){
			request.requestBody = Blob.valueOf(requestBody);
		}

		RestContext.request = request;
		RestContext.response = new RestResponse();

		FreshserviceWebService.updateCase();

		return (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
	}
}