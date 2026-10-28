/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : FreshServiceApiTest
 * Author          : <Rishank Bhardwaj>
 * Created Date    : Aug 12, 2026
 * Last Modified By: <Rishank Bhardwaj>
 * Last Modified On: Aug 12, 2026
 * Description     : This test class is for FreshServiceApi
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 12, 2026 │ <Rishank Bhardwaj> │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@IsTest
private class FreshServiceApiTest {

	private class FreshserviceApiMock implements HttpCalloutMock{
		public HttpResponse respond(HttpRequest req){
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setBody('{"success":true}');
			return response;
		}
	}

	// Test Freshservice APIs.
	@IsTest
	static void testFreshserviceApi(){
		Test.setMock(HttpCalloutMock.class,new FreshserviceApiMock());

		Test.startTest();
		System.assertEquals(200,FreshServiceApi.createTicket('{"subject":"Test"}').getStatusCode());
		System.assertEquals(200,FreshServiceApi.getTicket(1001).getStatusCode());
		System.assertEquals(200,FreshServiceApi.updateTicket(1001,'{"priority":3}').getStatusCode());
		System.assertEquals(200,FreshServiceApi.getConversations(1001).getStatusCode());
		System.assertEquals(200,FreshServiceApi.createReply(1001,'{"body":"Test"}').getStatusCode());
		System.assertEquals(200,FreshServiceApi.searchTicketByWaybill('WB123').getStatusCode());
		System.assertEquals(200,FreshServiceApi.placeWaybillEscalationRequest('{}').getStatusCode());
		System.assertEquals(200,FreshServiceApi.placePostDeliveryEscalationRequest('{}').getStatusCode());
		Test.stopTest();
	}

	// Test API validations.
	@IsTest
	static void testFreshserviceApiValidations(){
		try{ FreshServiceApi.createTicket(null); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.getTicket(null); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.updateTicket(null,'{}'); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.updateTicket(1001,null); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.getConversations(null); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.createReply(null,'{}'); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.createReply(1001,null); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.searchTicketByWaybill(null); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.placeWaybillEscalationRequest(null); System.assert(false); }catch(CalloutException exp){}
		try{ FreshServiceApi.placePostDeliveryEscalationRequest(null); System.assert(false); }catch(CalloutException exp){}
	}
}