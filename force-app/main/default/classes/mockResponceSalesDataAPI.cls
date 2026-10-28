/**
 * Description      :   mock responce for sales data API
 * Release          :   17th may, 2021
 * Created by       :   Shubham Girdhar
 * Revision Logs    :   V_1.0 - Created
 **/
@isTest
global class mockResponceSalesDataAPI implements HttpCalloutMock{
   global  HTTPResponse respond(HTTPRequest req) {
       HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatus('OK');
        res.setStatusCode(200);
        res.setBody('{"status": "Ok","data": [{"contractId": 1518,"sfxCode": "SFX1111","bookingBranchId": 1306007,"bookingBranchName": "TIRUVALLUR-251","totalWaybillBookedPre": 10,"mtdBookedCur": 0,"mtdBookedPre": 10,"totalSalesPre": 12949.3,"mtdSalesCur": 0,"mtdSalesPre": 12949.3,"unDelivered": 0},{"contractId": 28546,"sfxCode": "SFX14878","bookingBranchId": 37263,"bookingBranchName": "KOLKATA CITY-401","totalWaybillBookedPre": 297,"mtdBookedCur": 0,"mtdBookedPre": 192,"totalSalesPre": 126390,"mtdSalesCur": 0,"mtdSalesPre": 81600,"unDelivered": 6}],"message": null,"responseId": "c8dc36b5-d761-4228-bf09-87dcd551b5f9"}');
        return res;
    }
}