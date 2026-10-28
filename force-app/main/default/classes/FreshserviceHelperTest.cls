/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : FreshserviceHelperTest
 * Author          : <Rishank Bhardwaj>
 * Created Date    : Aug 12, 2026
 * Last Modified By: <Rishank Bhardwaj>
 * Last Modified On: Aug 12, 2026
 * Description     : This test class is for FreshserviceHelper
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 12, 2026  │ <Rishank Bhardwaj>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

@IsTest
private class FreshserviceHelperTest {
	private class FreshserviceHelperMock implements HttpCalloutMock{
		public HttpResponse respond(HttpRequest req){
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);

			if(req.getEndpoint().contains('/tickets/filter')){
				if(req.getEndpoint().contains('CLOSEDWB')){
					response.setBody('{"tickets":[{"id":1002,"status":5,"custom_fields":{"waybill_number":"12345678"}}]}');
				}else{
					response.setBody('{"tickets":[{"id":1001,"status":2,"custom_fields":{"waybill_number":"22222222"}}]}');
				}
			}else if(req.getEndpoint().contains('/conversations')){
				response.setBody('{"conversations":[{"id":1,"body":"Test Comment","private":false,"from_email":"test@test.com","created_at":"2026-08-05"}]}');
			}else if(req.getEndpoint().contains('/reply')){
				response.setBody('{"conversation":{"id":1,"body":"Test Reply","private":false,"from_email":"test@test.com","created_at":"2026-08-05"}}');
			}else if(req.getEndpoint().contains('/service_catalog')){
				response.setBody('{"service_request":{"id":2001,"display_id":2001,"subject":"Test","status":2,"priority":2,"workspace_id":5,"custom_fields":{}}}');
			}else if(req.getMethod() == 'PUT'){
				response.setBody('{}');
			}else{
				response.setBody('{"ticket":{"id":1001,"display_id":1001,"subject":"Test","description":"Test Description","status":2,"priority":3,"source":10,"type":"Incident","workspace_id":5,"custom_fields":{},"conversations":[{"id":1,"body":"Comment","private":false}]}}');
			}

			return response;
		}
	}

	// Test Helper main methods.
	@IsTest
	static void testFreshserviceHelper(){
		Test.setMock(HttpCalloutMock.class,new FreshserviceHelperMock());

		FreshserviceWrapper.CreateTicketRequest ticketRequest = new FreshserviceWrapper.CreateTicketRequest();
		ticketRequest.email = 'test@test.com';
		ticketRequest.subject = 'Test';
		ticketRequest.description = 'Test';

		FreshserviceWrapper.ServiceCatalogRequest catalogRequest = new FreshserviceWrapper.ServiceCatalogRequest();
		catalogRequest.email = 'test@test.com';
		catalogRequest.requested_for = 'test@test.com';

		Test.startTest();
		FreshserviceWrapper.CreateTicketResponse response = FreshserviceHelper.createTicket(ticketRequest);
		FreshserviceWrapper.CreateTicketResponse getResponse = FreshserviceHelper.getTicket(1001);
		FreshserviceHelper.updateTicket(1001,'{"priority":3}');
		List<Object> articles = FreshserviceHelper.getConversationsAsArticles(1001);
		Map<String,Object> reply = FreshserviceHelper.createReplyAsArticle(1001,'Test Reply');
		String duplicateTicket = FreshserviceHelper.findDuplicateTicketByWaybill('WB123');
		String closedTicket = FreshserviceHelper.findDuplicateTicketByWaybill('CLOSEDWB');
		FreshserviceWrapper.ServiceCatalogResponse waybillResponse = FreshserviceHelper.placeWaybillEscalationRequest(catalogRequest);
		FreshserviceWrapper.ServiceCatalogResponse postDeliveryResponse = FreshserviceHelper.placePostDeliveryEscalationRequest(catalogRequest);
		Test.stopTest();

		System.assertEquals(1001,FreshserviceHelper.getTicketId(response));
		System.assertEquals('FSC-1001',FreshserviceHelper.getTicketNumber(getResponse));
		System.assertEquals(1,articles.size());
		System.assertEquals('Test Reply',reply.get('Body'));
		System.assertEquals('FSC-1001',duplicateTicket);
		System.assertEquals(null,closedTicket);
		System.assertEquals(2001,FreshserviceHelper.getServiceRequestId(waybillResponse));
		System.assertEquals('FSC-2001',FreshserviceHelper.getServiceRequestNumber(postDeliveryResponse));
	}

	// Test conversation mapping branches.
	@IsTest
	static void testHelperConversationBranches(){
		HttpResponse response = new HttpResponse();
		response.setStatusCode(200);
		response.setBody('{"ticket":{"id":1001.9,"display_id":1001,"status":2.0,"priority":3.0,"source":10.0,"workspace_id":5.0,"custom_fields":{"waybill_number":"WB1"},"conversations":[' +
			'{"id":1,"private":true},' +
			'{"id":2,"private_note":true},' +
			'"invalid",' +
			'{"id":3,"support_email":"support@test.com","to_emails":["a@test.com","b@test.com"],"body_text":"Body Text","created_at":"2026-08-05","attachments":[{"id":11,"file_name":"test.pdf","content_type":"application/pdf","attachment_url":"test-url"},"invalid"]},' +
			'{"id":4,"user_id":55,"body":"Body","updated_at":"2026-08-06","attachments":[{"id":12,"name":"image.png"}]},' +
			'{"id":5}' +
		']}}');

		FreshserviceWrapper.CreateTicketResponse ticketResponse = FreshserviceHelper.parseCreateTicketResponse(response);

		System.assertEquals(1001,ticketResponse.ticket.id);
		System.assertEquals(3,ticketResponse.articles.size());
		System.assertEquals('support@test.com',((Map<String,Object>)ticketResponse.articles[0]).get('From'));
		System.assertEquals('User 55',((Map<String,Object>)ticketResponse.articles[1]).get('From'));
		System.assertEquals('Freshservice',((Map<String,Object>)ticketResponse.articles[2]).get('From'));
	}

	// Test Helper remaining branches.
	@IsTest
	static void testHelperRemainingBranches(){
		System.assertEquals(null,FreshserviceHelper.buildTicketUpdateBody(null,null));
		System.assertEquals(null,FreshserviceHelper.buildTicketUpdateBody(new Case(),new Case()));
		System.assertEquals(false,FreshserviceHelper.isPostDeliveryEscalationCase(null));
		System.assertEquals(false,FreshserviceHelper.isPostDeliveryEscalationCase(new Case()));
		System.assertEquals(true,FreshserviceHelper.isPostDeliveryEscalationCase(new Case(Sub_Type__c='Damage')));

		FreshserviceHelper.buildTicketUpdateBody(new Case(Priority='Low'),null);
		FreshserviceHelper.buildTicketUpdateBody(new Case(Priority='Medium'),null);
		FreshserviceHelper.buildTicketUpdateBody(new Case(Priority='High'),null);
		FreshserviceHelper.buildTicketUpdateBody(new Case(Priority='Urgent'),null);
		FreshserviceHelper.buildTicketUpdateBody(new Case(Priority='Unknown'),null);

		System.assertEquals(null,FreshserviceHelper.getTicketId(null));
		System.assertEquals(null,FreshserviceHelper.getTicketNumber(null));
		System.assertEquals(null,FreshserviceHelper.getServiceRequestId(null));
		System.assertEquals(null,FreshserviceHelper.getServiceRequestNumber(null));
		System.assertEquals(null,FreshserviceHelper.extractTicketIdFromFormattedValue(null));
		System.assertEquals(null,FreshserviceHelper.extractTicketIdFromFormattedValue('ABC'));
		System.assertEquals(1001,FreshserviceHelper.extractTicketIdFromFormattedValue(' FSC-1001 '));
		System.assertEquals(null,FreshserviceHelper.findDuplicateTicketByWaybill(null));
	}
}