/**
* Description		:		Test class to get fake responce for API Callout
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th july, 2019
 * Release          :       17th july, 2019
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/

@isTest
global class mockRespoceCaseTriggerHelper implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
       HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatus('OK');
        res.setStatusCode(200);
        res.setBody('{"destination_addresses" : [ "Charkhi Dadri - Kanina Rd, Haryana 127306, India" ],"origin_addresses" : [ "Unnamed Road, Shankar Vihar, New Delhi, Delhi 110037, India" ],"rows" : [{"elements" : [{"distance" : {"text" : "116 km","value" : 116244},"duration" : {"text" : "2 hours 35 mins","value" : 9303},"status" : "OK"}]}],"status" : "OK"}');
        return res;
    }
}