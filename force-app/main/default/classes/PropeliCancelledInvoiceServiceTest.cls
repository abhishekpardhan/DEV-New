@isTest
private class PropeliCancelledInvoiceServiceTest {
    static testmethod void validateSuccessAndBadDates() {
        // success response mock
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        PropeliCancelledInvoiceService.getCancelledInvoices('0','1'); // should run without exception
    }
    
    static testmethod void validateSuccessAndBadDates2() {
        // success response mock
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        PropeliCancelledInvoiceService.getCancelledInvoices('16-02-2026','18-02-2026'); // should run without exception

    } 
    
    static testmethod void validateSuccessAndBadDates3() {
        // success response mock
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        PropeliCancelledInvoiceService.getCancelledInvoices('19-02-2026','18-02-2026'); // should run without exception

    }
    
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();            
            if(req.getEndpoint().contains('token')) {
                // 🔹 Mock Token Response
                res.setStatusCode(200);
                res.setBody('{"access_token":"test_token_123"}');
            } 
            else {
                res.setStatusCode(200);
                res.setBody('{"message":"Data Found","status":"SUCCESS","data":[{"billNumber":"243110004472","billType":"CREDIT_BILL","status":"CANCELLED","actualOutstandingAmount":333709.65,"outstandingAmount":333709.47,"msaCode":"MSA00000701","sfRecordId":"a04C500000315kcIAA","updatedDate":"22-08-2025"}]}');
            }
            
            return res;
        }
    }
}