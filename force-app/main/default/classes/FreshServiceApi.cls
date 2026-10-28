public with sharing class FreshServiceApi {

    private static final String BASE_URL = 'callout:Safex_Freshservice_NC/api/v2';
    private static final String WAYBILL_FIELD_API_NAME = 'waybill_number';

    // Create Freshservice ticket.
    public static HttpResponse createTicket(String body) {
        if (String.isBlank(body)) {
            throw new CalloutException('Freshservice create ticket body cannot be blank.');
        }

        return sendJsonRequest('POST', '/tickets', body);
    }

    // Get Freshservice ticket.
    public static HttpResponse getTicket(Long ticketId) {
        if (ticketId == null) {
            throw new CalloutException('Freshservice ticket id cannot be null.');
        }

        return sendJsonRequest('GET', '/tickets/' + ticketId + '?include=conversations', null);
    }

    // Update Freshservice ticket.
    public static HttpResponse updateTicket(Long ticketId, String body) {
        if (ticketId == null) {
            throw new CalloutException('Freshservice ticket id cannot be null for update.');
        }

        if (String.isBlank(body)) {
            throw new CalloutException('Freshservice update body cannot be blank.');
        }

        return sendJsonRequest('PUT', '/tickets/' + ticketId, body);
    }

    // Get ticket conversations.
    public static HttpResponse getConversations(Long ticketId) {
        if (ticketId == null) {
            throw new CalloutException('Freshservice ticket id cannot be null for conversations.');
        }

        return sendJsonRequest('GET', '/tickets/' + ticketId + '/conversations', null);
    }

    // Create ticket reply.
    public static HttpResponse createReply(Long ticketId, String body) {
        if (ticketId == null) {
            throw new CalloutException('Freshservice ticket id cannot be null for reply creation.');
        }

        if (String.isBlank(body)) {
            throw new CalloutException('Freshservice reply body cannot be blank.');
        }

        return sendJsonRequest('POST', '/tickets/' + ticketId + '/reply', body);
    }

    // Search ticket by waybill.
    public static HttpResponse searchTicketByWaybill(String waybillNo) {
        if (String.isBlank(waybillNo)) {
            throw new CalloutException('Waybill number cannot be blank for Freshservice duplicate check.');
        }

        String query = '"' + WAYBILL_FIELD_API_NAME + ':\'' + String.escapeSingleQuotes(waybillNo.trim()) + '\'"';
        return sendJsonRequest('GET', '/tickets/filter?workspace_id=5&query=' + EncodingUtil.urlEncode(query, 'UTF-8'), null);
    }

    // Place waybill request.
    public static HttpResponse placeWaybillEscalationRequest(String body) {
        if (String.isBlank(body)) {
            throw new CalloutException('Waybill escalation body cannot be blank.');
        }

        return sendJsonRequest('POST', '/service_catalog/items/242/place_request', body);
    }

    // Place post delivery request.
    public static HttpResponse placePostDeliveryEscalationRequest(String body) {
        if (String.isBlank(body)) {
            throw new CalloutException('Post delivery escalation body cannot be blank.');
        }

        return sendJsonRequest('POST', '/service_catalog/items/258/place_request', body);
    }

    // Send Freshservice HTTP request.
    private static HttpResponse sendJsonRequest(String method, String endpoint, String body) {
        if (String.isBlank(method)) {
            throw new CalloutException('Freshservice HTTP method cannot be blank.');
        }

        if (String.isBlank(endpoint)) {
            throw new CalloutException('Freshservice endpoint cannot be blank.');
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + endpoint);
        req.setMethod(method);
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        if (String.isNotBlank(body)) {
            req.setBody(body);
        }

        return new Http().send(req);
    }
}