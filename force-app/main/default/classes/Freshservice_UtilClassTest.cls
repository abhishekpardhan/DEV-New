/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : Freshservice_UtilClassTest
 * Author          : <Rishank Bhardwaj>
 * Created Date    : Aug 12, 2026
 * Last Modified By: <Rishank Bhardwaj>
 * Last Modified On: Aug 12, 2026
 * Description     : This test class is for Freshservice_UtilClass
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 12, 2026 │ <Rishank Bhardwaj> │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@IsTest
private class Freshservice_UtilClassTest {

	@TestSetup
	static void setupData(){
		String status = [Select MasterLabel from CaseStatus where IsClosed=false LIMIT 1].MasterLabel;
		String origin = Case.Origin.getDescribe().getPicklistValues()[0].getValue();

		try{
			Freshservice_UtilClass.skipFreshserviceCaseSync = true;
			insert new List<Case>{
				new Case(Subject='Detail Test',Status=status,Origin=origin,SuppliedEmail='test@test.com',
					SuppliedPhone='9999999999',Fresh_Service_Ticket_No__c='FSC-1001',Sub_Type__c='Damage'),
				new Case(Subject='Detail Open',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-1101'),
				new Case(Subject='Detail Pending',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-1102'),
				new Case(Subject='Detail Resolved',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-1103'),
				new Case(Subject='Detail Unknown',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-1104'),
				new Case(Subject='Detail Empty',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-1105'),
				new Case(Subject='Detail Missing',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-9999'),
				new Case(Subject='No Ticket',Status=status,Origin=origin),
				new Case(Subject='Invalid Ticket',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='INVALID'),
				new Case(Subject='Existing Ticket',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-2001'),
				new Case(Subject='Create Test',Status=status,Origin=origin,WaybillNo__c='UTIL123'),
				new Case(Subject='Normal Closed',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-3001')
			};
		}finally{
			Freshservice_UtilClass.skipFreshserviceCaseSync = false;
		}
	}

	private class FreshserviceUtilMock implements HttpCalloutMock{
		public HttpResponse respond(HttpRequest req){
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);

			if(req.getEndpoint().contains('/reply')){
				response.setBody('{"conversation":{"id":10,"body":"Test Reply","private":false,"from_email":"test@test.com","to_emails":["user@test.com"],"created_at":"2026-08-12T10:00:00Z","attachments":[]}}');
			}else if(req.getEndpoint().contains('/9999')){
				response.setBody('{"ticket":null}');
			}else if(req.getEndpoint().contains('/1101')){
				response.setBody(ticketResponse(1101,2,1,true));
			}else if(req.getEndpoint().contains('/1102')){
				response.setBody(ticketResponse(1102,3,2,true));
			}else if(req.getEndpoint().contains('/1103')){
				response.setBody(ticketResponse(1103,4,3,true));
			}else if(req.getEndpoint().contains('/1104')){
				response.setBody(ticketResponse(1104,9,9,true));
			}else if(req.getEndpoint().contains('/1105')){
				response.setBody('{"ticket":{"id":1105,"subject":"Test","status":null,"priority":null,"type":"Request","custom_fields":{},"conversations":[]}}');
			}else{
				response.setBody(ticketResponse(1001,5,4,true));
			}

			return response;
		}

		private String ticketResponse(Integer id,Integer status,Integer priority,Boolean customFields){
			return '{"ticket":{"id":'+id+',"display_id":'+id+',"subject":"Freshservice Test","description":"Test Description",' +
				'"status":'+status+',"priority":'+priority+',"source":10,"type":"Incident","workspace_id":5,' +
				'"custom_fields":'+(customFields ? '{"group_name":"Support","sr_service_region":"North","impact":"High","agent_name":"Test Agent"}' : '{}')+',' +
				'"conversations":[]}}';
		}
	}

	private class FreshserviceErrorMock implements HttpCalloutMock{
		public HttpResponse respond(HttpRequest req){
			HttpResponse response = new HttpResponse();
			response.setStatusCode(500);
			response.setBody('{"message":"Test Error"}');
			return response;
		}
	}

	// Test create and sync.
	@IsTest
	static void testCreateAndSync(){
		Case createCase = [
			Select Id,CaseNumber,Subject,ContactEmail,Service_Region__c,OTRS_Remarks__c,WaybillNo__c,Sub_Type__c
			from Case where Subject='Create Test' LIMIT 1
		];

		Case existingCase = [
			Select Id,Subject,Fresh_Service_Ticket_No__c
			from Case where Subject='Existing Ticket' LIMIT 1
		];

		String requestBody = FreshserviceHelper.buildServiceCatalogBody(
			FreshserviceQueueable.buildWaybillEscalationRequest(createCase)
		);

		LoggerUtil.createOrUpdateAPILog(
			new API_Logger__c(),
			true,
			'Freshservice Waybill Escalation',
			'/api/v2/service_catalog/items/242/place_request',
			requestBody,
			null,
			null
		);

		Map<String,Object> duplicateResponse = response(
			Freshservice_UtilClass.createFreshserviceTicket(createCase.Id)
		);

		Map<String,Object> existingResponse = response(
			Freshservice_UtilClass.createFreshserviceTicket(existingCase.Id)
		);

		System.assertEquals('Please wait, Freshservice API is running',duplicateResponse.get('message'));
		System.assertEquals('SKIP',existingResponse.get('type'));
		System.assertEquals('ERROR',response(Freshservice_UtilClass.createFreshserviceTicket(null)).get('type'));
		System.assertEquals('ERROR',response(Freshservice_UtilClass.createFreshserviceTicket(UserInfo.getUserId())).get('type'));

		Freshservice_UtilClass.skipFreshserviceCaseSync = true;
		Freshservice_UtilClass.syncMappedCaseUpdatesToFreshservice(new List<Case>{existingCase},null);
		Freshservice_UtilClass.skipFreshserviceCaseSync = false;

		Freshservice_UtilClass.syncMappedCaseUpdatesToFreshservice(null,null);
		Freshservice_UtilClass.syncMappedCaseUpdatesToFreshservice(new List<Case>{null,new Case()},null);
	}

    // Test Freshservice details.
    @IsTest
    static void testFreshserviceDetails(){
        Case detailCase = [Select Id from Case where Subject='Detail Test' LIMIT 1];
        Test.setMock(HttpCalloutMock.class,new FreshserviceUtilMock());
    
        Test.startTest();
        Map<String,Object> result = response(
            Freshservice_UtilClass.getFreshserviceTicketDetails(detailCase.Id)
        );
        Test.stopTest();
    
        System.assertEquals('SUCCESS',result.get('type'),String.valueOf(result.get('message')));
    }

    // Test detail mappings.
    @IsTest
    static void testFreshserviceDetailMappings(){
        Test.setMock(HttpCalloutMock.class,new FreshserviceUtilMock());
    
        Test.startTest();
        for(Case caseRecord : [
            Select Id from Case
            where Subject IN ('Detail Open','Detail Pending','Detail Resolved','Detail Unknown','Detail Empty')
        ]){
            Map<String,Object> result = response(
                Freshservice_UtilClass.getFreshserviceTicketDetails(caseRecord.Id)
            );
    
            System.assertEquals('SUCCESS',result.get('type'),String.valueOf(result.get('message')));
        }
        Test.stopTest();
    }

	// Test missing ticket response.
	@IsTest
	static void testFreshserviceMissingTicket(){
		Case caseRecord = [Select Id from Case where Subject='Detail Missing' LIMIT 1];
		Test.setMock(HttpCalloutMock.class,new FreshserviceUtilMock());

		System.assertEquals(
			'ERROR',
			response(Freshservice_UtilClass.getFreshserviceTicketDetails(caseRecord.Id)).get('type')
		);
	}

    // Test Freshservice reply.
    @IsTest
    static void testFreshserviceReply(){
        Case detailCase = [Select Id from Case where Subject='Detail Test' LIMIT 1];
        Test.setMock(HttpCalloutMock.class,new FreshserviceUtilMock());
    
        Test.startTest();
        Map<String,Object> result = response(
            Freshservice_UtilClass.createFreshserviceReply(null,detailCase.Id,'Test Reply')
        );
        Test.stopTest();
    
        System.assertEquals('SUCCESS',result.get('type'),String.valueOf(result.get('message')));
    }

	// Test Util validations.
	@IsTest
	static void testFreshserviceValidations(){
		Map<String,Case> cases = new Map<String,Case>();

		for(Case caseRecord : [
			Select Id,Subject from Case
			where Subject IN ('Detail Test','No Ticket','Invalid Ticket')
		]){
			cases.put(caseRecord.Subject,caseRecord);
		}

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.getFreshserviceTicketDetails(null)).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.getFreshserviceTicketDetails(UserInfo.getUserId())).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.getFreshserviceTicketDetails(cases.get('No Ticket').Id)).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.getFreshserviceTicketDetails(cases.get('Invalid Ticket').Id)).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.createFreshserviceReply(null,null,'Test')).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.createFreshserviceReply(null,cases.get('Detail Test').Id,null)).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.createFreshserviceReply(null,cases.get('No Ticket').Id,'Test')).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.createFreshserviceReply('INVALID',cases.get('Detail Test').Id,'Test')).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.createFreshserviceReply(null,UserInfo.getUserId(),'Test')).get('type'));
	}

	// Test status update.
	@IsTest
	static void testFreshserviceStatus(){
		Case damageCase = [Select Id from Case where Subject='Detail Test' LIMIT 1];
		Case normalCase = [Select Id from Case where Subject='Normal Closed' LIMIT 1];

		System.assertEquals('SUCCESS',response(
			Freshservice_UtilClass.updateFreshserviceStatus('Closed',damageCase.Id)).get('type'));

		System.assertEquals('SUCCESS',response(
			Freshservice_UtilClass.updateFreshserviceStatus('Open',damageCase.Id)).get('type'));

		System.assertEquals('SUCCESS',response(
			Freshservice_UtilClass.updateFreshserviceStatus(null,damageCase.Id)).get('type'));

		System.assertEquals('SUCCESS',response(
			Freshservice_UtilClass.updateFreshserviceStatus('Closed',normalCase.Id)).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.updateFreshserviceStatus('Closed',null)).get('type'));

		System.assertEquals('ERROR',response(
			Freshservice_UtilClass.updateFreshserviceStatus('Closed',UserInfo.getUserId())).get('type'));

		System.assertEquals(false,Freshservice_UtilClass.skipFreshserviceCaseSync);
	}

	// Test callout error.
	@IsTest
	static void testFreshserviceError(){
		Case detailCase = [Select Id from Case where Subject='Detail Test' LIMIT 1];
		Test.setMock(HttpCalloutMock.class,new FreshserviceErrorMock());

		System.assertEquals(
			'ERROR',
			response(Freshservice_UtilClass.getFreshserviceTicketDetails(detailCase.Id)).get('type')
		);
	}

	// Parse Util response.
	private static Map<String,Object> response(String value){
		return (Map<String,Object>)JSON.deserializeUntyped(value);
	}
}