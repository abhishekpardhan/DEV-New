/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : FreshserviceQueueableTest
 * Author          : <Rishank Bhardwaj>
 * Created Date    : Aug 12, 2026
 * Last Modified By: <Rishank Bhardwaj>
 * Last Modified On: Aug 12, 2026
 * Description     : This test class is for FreshserviceQueueable
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 12, 2026  │ <Rishank Bhardwaj>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@IsTest
private class FreshserviceQueueableTest {

	private class FreshserviceQueuableMock implements HttpCalloutMock{
		public HttpResponse respond (HttpRequest req){
			HttpResponse response = new Httpresponse();
			response.setStatusCode(200);
			if(req.getEndpoint().contains('/tickets/filter')){
				response.setBody('{"tickets":[]}');
			}else if(req.getEndpoint().contains('/service_catalog')){
				response.setBody('{"service_request": {"id":3001}}');
			}else{
				response.setBody('{}');
			} return response;
		}
	}
	@IsTest
	static void testQueueableCreate(){
		List<Case> cases = new List<Case> {
			new Case ( Subject = 'Waybill Test',Status = [Select Masterlabel from CaseStatus where IsClosed =false limit 1].Masterlabel,
			Origin=Case.Origin.getDescribe().getPicklistvalues()[0].getValue(),WaybillNo__c = 'WBQ1'),
			new Case(Subject ='Damange test', Status = [select Masterlabel from CaseStatus where IsClosed = false limit 1 ].Masterlabel,
			Origin= Case.Origin.getDescribe().getPicklistvalues()[0].getValue(),WaybillNo__c='WBQ2', Sub_Type__c = 'Damage')
		};
		Freshservice_UtilClass.skipFreshserviceCaseSync= true;
		insert cases;
		Freshservice_UtilClass.skipFreshserviceCaseSync = false;
		Test.setMock(HttpCalloutMock.class,new FreshserviceQueuableMock());
		Test.startTest();
		new FreshserviceQueueable(new Map<Id,String>{cases[0].Id => '{"subject":"Updated"}'}).execute(null);
		new FreshserviceQueueable(new Set<Id>{cases[0].Id,cases[1].Id}).execute(null);
		test.stopTest();
		cases = [Select Fresh_Service_Ticket_No__c from Case where id IN :cases];
		System.assertEquals('FSC-3001',cases[0].Fresh_Service_Ticket_No__c);
		System.assertEquals('FSC-3001',cases[1].Fresh_Service_Ticket_No__c);
	}
	@IsTest
	static void testQueueableBuilders(){
		Case caseRecord = new Case(
			Subject = 'test', Description = 'test description', SuppliedEmail = 'test@test.com',OTRS_Remarks__c='remarks',
			Case_Type__c ='Incident', Main_Category__c='Test',Sub_Type__c='damage',Issue_Type__c = 'test',Service_Region__c='Delhi', WaybillNo__c= 'WB123'
		);
		System.assertEquals(10,FreshserviceQueueable.buildCreateTicketRequest(caseRecord).source);
		System.assertEquals(242,FreshserviceQueueable.buildWaybillEscalationRequest(caseRecord).itemId);
		System.assertEquals(258,FreshserviceQueueable.buildpostDeliveryEscalationRequest(caseRecord).itemId);
		new FreshserviceQueueable((set<Id>)null).execute(null);
		new FreshserviceQueueable(new Set<Id>(),null).execute(null);
		new FreshserviceQueueable(new Set<Id>(),null).execute(null);
		new FreshserviceQueueable(new Map<Id,String>(),null).execute(null);

	}
	private class FreshserviceQueueableErrorMock implements HttpCalloutMock{
			public HttpResponse respond(HttpRequest req){
				HttpResponse response = new HttpResponse();

				if(req.getEndpoint().contains('/tickets/filter') && req.getEndpoint().contains('DUP1')){
					response.setStatusCode(200);
					response.setBody('{"tickets":[{"id":5001,"custom_fields":{"waybill_number":"DUP1"}}]}');
				}else if(req.getEndpoint().contains('/tickets/filter')){
					response.setStatusCode(200);
					response.setBody('{"tickets":[]}');
				}else{
					response.setStatusCode(500);
					response.setBody('{"message":"Test Error"}');
				}
				return response;
			}
		}
	
	@IsTest
	static void testQueueableBranches(){
		String status =[select Masterlabel from CaseStatus where IsClosed = false Limit 1].Masterlabel;
		String Origin = Case.Origin.getDescribe().getPicklistValues()[0].getValue();
		List<Case>cases =new List<Case>{
		new Case(Subject = 'test', Status = status,Origin=origin,WaybillNo__c='DUP1'),
		new Case(Subject='Create Error',Status=status,Origin=origin,WaybillNo__c='FAIL1'),
		new Case(Subject='No Ticket',Status=status,Origin=origin),
		new Case(Subject='Invalid Ticket',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='INVALID'),
		new Case(Subject='Blank Body',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-1001'),
		new Case(Subject='Update Error',Status=status,Origin=origin,Fresh_Service_Ticket_No__c='FSC-1002')
		};

		Freshservice_UtilClass.skipFreshserviceCaseSync=true;
		insert cases;
		Freshservice_UtilClass.skipFreshserviceCaseSync=false;
		Test.setMock(HttpCalloutMock.class,new FreshserviceQueueableErrorMock());
		Test.startTest();
		new FreshserviceQueueable(new Set<Id>{cases[0].Id,cases[1].id},null,2).execute(null);
		new FreshserviceQueueable(new Map<Id,String>{
			cases[2].Id => '{"subject":"Test"}',
			cases[3].Id => '{"subject":"Test"}',
			cases[4].Id => '',
			cases[5].Id => '{"Subject":"test"}'
		},2).execute(null);
		Test.stopTest();
		System.assertEquals(null,[select Fresh_Service_Ticket_No__c from case where Id=: cases[0].Id].Fresh_Service_Ticket_No__c);
	}
}