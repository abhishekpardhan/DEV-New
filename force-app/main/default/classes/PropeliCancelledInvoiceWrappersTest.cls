@isTest
private class PropeliCancelledInvoiceWrappersTest {
    static testmethod void testWrappers() {
        PropeliCancelledInvoiceWrappers.CancelledInvoiceRequest req = new PropeliCancelledInvoiceWrappers.CancelledInvoiceRequest('1','0');
        PropeliCancelledInvoiceWrappers.CancelledInvoiceRequest req2 = new PropeliCancelledInvoiceWrappers.CancelledInvoiceRequest();
        PropeliCancelledInvoiceWrappers.CancelledInvoiceItem item = new PropeliCancelledInvoiceWrappers.CancelledInvoiceItem();
        PropeliCancelledInvoiceWrappers.CancelledInvoiceResponse resp = new PropeliCancelledInvoiceWrappers.CancelledInvoiceResponse();
        resp.message = 'test';
        System.assertEquals('test', resp.message);
    }
}