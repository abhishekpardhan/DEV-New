@IsTest
private class Freshservice_DeploymentTest {
    private class ServiceMock implements HttpCalloutMock {
        private Boolean failUpdate;
        ServiceMock(Boolean failUpdate) { this.failUpdate = failUpdate; }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/tickets/filter')) {
                res.setBody('{"tickets":[]}');
            } else if (req.getMethod() == 'PUT') {
                System.assert(req.getEndpoint().contains('/tickets/7001'));
                if (failUpdate) {
                    res.setStatusCode(400);
                    res.setBody('{"description":"Invalid update"}');
                } else {
                    System.assert(req.getBody().contains('Changed subject'));
                    res.setBody('{"ticket":{"id":7001}}');
                }
            } else {
                System.assert(req.getEndpoint().contains('/service_catalog/items/242/place_request'));
                System.assertEquals('POST', req.getMethod());
                Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(req.getBody());
                System.assert(body.containsKey('custom_fields'));
                res.setStatusCode(201);
                res.setBody('{"service_request":{"id":7001}}');
            }
            return res;
        }
    }
    private static Case makeCase(String ticket) {
        Case c = new Case(Subject='Freshservice deployment test',
            Status=[SELECT MasterLabel FROM CaseStatus WHERE IsClosed=false LIMIT 1].MasterLabel,
            Origin=Case.Origin.getDescribe().getPicklistValues()[0].getValue(),
            Fresh_Service_Ticket_No__c=ticket, WaybillNo__c='FSDEPLOY7001');
        Freshservice_UtilClass.skipFreshserviceCaseSync=true;
        try { insert c; } finally { Freshservice_UtilClass.skipFreshserviceCaseSync=false; }
        return c;
    }
    @IsTest static void createTicketLinksCase() {
        Case c=makeCase(null);
        Test.setMock(HttpCalloutMock.class,new ServiceMock(false));
        Test.startTest();
        Map<String,Object> result=(Map<String,Object>)JSON.deserializeUntyped(
            Freshservice_UtilClass.createFreshserviceTicket(c.Id));
        System.assertEquals('SUCCESS',result.get('type'),JSON.serialize(result));
        Test.stopTest();
        System.assertEquals('FSC-7001',[SELECT Fresh_Service_Ticket_No__c FROM Case WHERE Id=:c.Id].Fresh_Service_Ticket_No__c);
        System.assertEquals(1,[SELECT COUNT() FROM API_Logger__c WHERE Request_Hash__c != null]);
    }
    @IsTest static void changedFieldsAreSynced() {
        Case c=makeCase('FSC-7001');
        c=[SELECT Id,Subject,Description,Priority,WaybillNo__c,Service_Region__c,OTRS_Remarks__c,Fresh_Service_Ticket_No__c FROM Case WHERE Id=:c.Id];
        Case oldCase=c.clone(true,true,false,false);
        c.Subject='Changed subject';
        Test.setMock(HttpCalloutMock.class,new ServiceMock(false));
        Test.startTest();
        Freshservice_UtilClass.syncMappedCaseUpdatesToFreshservice(new List<Case>{c},new Map<Id,Case>{c.Id=>oldCase});
        System.assertEquals(1,Limits.getQueueableJobs());
        Test.stopTest();
        System.assertEquals(0,[SELECT COUNT() FROM Error_Log__c WHERE Class_Name__c='FreshserviceQueueable']);
    }
    @IsTest static void failedUpdateLogsErrorAndKeepsLink() {
        Case c=makeCase('FSC-7001');
        Test.setMock(HttpCalloutMock.class,new ServiceMock(true));
        Test.startTest();
        System.enqueueJob(new FreshserviceQueueable(new Map<Id,String>{c.Id=>'{"subject":"Changed subject"}'},2));
        Test.stopTest();
        System.assertEquals('FSC-7001',[SELECT Fresh_Service_Ticket_No__c FROM Case WHERE Id=:c.Id].Fresh_Service_Ticket_No__c);
        List<Error_Log__c> logs=[SELECT Exception_Message__c FROM Error_Log__c WHERE Class_Name__c='FreshserviceQueueable' AND Method_Name__c='updateFreshserviceTickets'];
        System.assertEquals(1,logs.size());
        System.assert(logs[0].Exception_Message__c.contains('RAW_STATUS=400'));
    }

    private class RetryCreateMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res=new HttpResponse();
            if(req.getEndpoint().contains('/tickets/filter')) {
                res.setStatusCode(200); res.setBody('{"tickets":[]}');
            } else { res.setStatusCode(503); res.setBody('{"message":"Temporary outage"}'); }
            return res;
        }
    }
    @IsTest static void retryStopsAtLimitAndLogsFailure() {
        Case c=makeCase(null);
        Test.setMock(HttpCalloutMock.class,new RetryCreateMock());
        Test.startTest();
        new FreshserviceQueueable(new Set<Id>{c.Id},null,1).execute(null);
        System.assertEquals(1,Limits.getQueueableJobs(),'Transient failure should enqueue the final retry.');
        Test.stopTest();
        System.assertEquals(null,[SELECT Fresh_Service_Ticket_No__c FROM Case WHERE Id=:c.Id].Fresh_Service_Ticket_No__c);
        List<Error_Log__c> logs=[SELECT Exception_Message__c FROM Error_Log__c WHERE Class_Name__c='FreshserviceQueueable' AND Method_Name__c='createFreshserviceTickets'];
        System.assertEquals(1,logs.size(),'The final failed retry must be logged.');
        System.assert(logs[0].Exception_Message__c.contains('RAW_STATUS=503'));
    }

}