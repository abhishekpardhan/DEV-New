public with sharing class FreshserviceHelper {

    private static final Set<String> POST_DELIVERY_SUB_TYPES = new Set<String>{'pilferred', 'wrong delivery', 'short / part shipment', 'damage'};
    private static final Map<String, Integer> FRESHSERVICE_PRIORITY_CODES = new Map<String, Integer>{'low' => 1, 'medium' => 2, 'high' => 3, 'urgent' => 4};

    // Create Freshservice ticket request.
    public static FreshserviceWrapper.CreateTicketResponse createTicket(FreshserviceWrapper.CreateTicketRequest req) {
        if (req == null) {
            throw new CalloutException('Freshservice create ticket request cannot be null.');
        }

        return parseCreateTicketResponse(FreshServiceApi.createTicket(JSON.serialize(req)));
    }

    // Fetch Freshservice ticket details.
    public static FreshserviceWrapper.CreateTicketResponse getTicket(Long ticketId) {
        if (ticketId == null) {
            throw new CalloutException('Freshservice ticket id cannot be null.');
        }

        return parseCreateTicketResponse(FreshServiceApi.getTicket(ticketId));
    }

    // Update Freshservice ticket details.
    public static void updateTicket(Long ticketId, String body) {
        if (ticketId == null) {
            throw new CalloutException('Freshservice ticket id cannot be null for update.');
        }

        if (String.isBlank(body)) {
            throw new CalloutException('Freshservice update body cannot be blank.');
        }

        parseJsonObjectResponse(FreshServiceApi.updateTicket(ticketId, body), 'Freshservice update ticket');
    }

    // Build ticket update payload.
    public static String buildTicketUpdateBody(Case newCase, Case oldCase) {
        if (newCase == null) {
            return null;
        }

        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> customFields = new Map<String, Object>();

        if ((oldCase == null || newCase.Subject != oldCase.Subject) && String.isNotBlank(newCase.Subject)) {
            payload.put('subject', newCase.Subject);
        }

        if ((oldCase == null || newCase.Description != oldCase.Description) && String.isNotBlank(newCase.Description)) {
            payload.put('description', newCase.Description);
        }

        if (oldCase == null || newCase.Priority != oldCase.Priority) {
            Integer priorityCode = getFreshservicePriorityCode(newCase.Priority);
            if (priorityCode != null) {
                payload.put('priority', priorityCode);
            }
        }

        if (oldCase == null || newCase.WaybillNo__c != oldCase.WaybillNo__c) {
            customFields.put('waybill_number', newCase.WaybillNo__c);
        }

        if (oldCase == null || newCase.Service_Region__c != oldCase.Service_Region__c) {
            customFields.put('service_region', newCase.Service_Region__c);
        }

        if ((oldCase == null || newCase.OTRS_Remarks__c != oldCase.OTRS_Remarks__c) && String.isNotBlank(newCase.OTRS_Remarks__c)) {
            customFields.put('remarks', newCase.OTRS_Remarks__c);
        }

        if (!customFields.isEmpty()) {
            payload.put('custom_fields', customFields);
        }

        return payload.isEmpty() ? null : JSON.serialize(payload);
    }

    // Identify post delivery Case.
    public static Boolean isPostDeliveryEscalationCase(Case cseObj) {
        return cseObj != null && String.isNotBlank(cseObj.Sub_Type__c) && POST_DELIVERY_SUB_TYPES.contains(cseObj.Sub_Type__c.trim().toLowerCase());
    }

    // Convert Salesforce priority code.
    private static Integer getFreshservicePriorityCode(String salesforcePriority) {
        return String.isBlank(salesforcePriority) ? null : FRESHSERVICE_PRIORITY_CODES.get(salesforcePriority.trim().toLowerCase());
    }

    // Legacy separate conversations API.
    public static List<Object> getConversationsAsArticles(Long ticketId) {
        if (ticketId == null) {
            throw new CalloutException('Freshservice ticket id cannot be null for conversations.');
        }

        return mapConversationCollectionToArticles(parseJsonObjectResponse(FreshServiceApi.getConversations(ticketId), 'Freshservice conversations').get('conversations'));
    }

    // Create reply article payload.
    public static Map<String, Object> createReplyAsArticle(Long ticketId, String body) {
        if (ticketId == null) {
            throw new CalloutException('Freshservice ticket id cannot be null for reply.');
        }

        if (String.isBlank(body)) {
            throw new CalloutException('Comment cannot be blank.');
        }

        Map<String, Object> conversationMap = toObjectMap(parseJsonObjectResponse(
            FreshServiceApi.createReply(ticketId, JSON.serialize(new Map<String, Object>{'body' => body})),
            'Freshservice create reply'
        ).get('conversation'));

        if (conversationMap == null) {
            throw new CalloutException('Freshservice reply response does not contain conversation.');
        }

        return mapConversationToArticle(conversationMap);
    }

    // Check duplicate by waybill.
    public static String findDuplicateTicketByWaybill(String waybillNo) {
        if (String.isBlank(waybillNo)) {
            return null;
        }

        Map<String, Object> root = parseJsonObjectResponse(FreshServiceApi.searchTicketByWaybill(waybillNo), 'Freshservice duplicate check');
        List<Object> tickets = toObjectList(root.get('tickets'));

        if ((tickets == null || tickets.isEmpty()) && root.containsKey('results')) {
            tickets = toObjectList(root.get('results'));
        }

        return tickets == null || tickets.isEmpty() ? null : getMatchingTicketNumberFromFilterResult(tickets, waybillNo);
    }

    // Place waybill escalation request.
    public static FreshserviceWrapper.ServiceCatalogResponse placeWaybillEscalationRequest(FreshserviceWrapper.ServiceCatalogRequest req) {
        if (req == null) {
            throw new CalloutException('Waybill Escalation request cannot be null.');
        }

        return parseServiceCatalogResponse(FreshServiceApi.placeWaybillEscalationRequest(buildServiceCatalogBody(req)));
    }

    // Place post delivery request.
    public static FreshserviceWrapper.ServiceCatalogResponse placePostDeliveryEscalationRequest(FreshserviceWrapper.ServiceCatalogRequest req) {
        if (req == null) {
            throw new CalloutException('Post Delivery Escalation request cannot be null.');
        }

        return parseServiceCatalogResponse(FreshServiceApi.placePostDeliveryEscalationRequest(buildServiceCatalogBody(req)));
    }

    // Build service catalog body.
    public static String buildServiceCatalogBody(FreshserviceWrapper.ServiceCatalogRequest req) {
        if (req == null) {
            throw new CalloutException('Freshservice service catalog request cannot be null.');
        }

        return JSON.serialize(new Map<String, Object>{
            'email' => req.email,
            'requested_for' => req.requested_for,
            'custom_fields' => req.custom_fields
        });
    }

    // Parse ticket API response.
    public static FreshserviceWrapper.CreateTicketResponse parseCreateTicketResponse(HttpResponse res) {
        Map<String, Object> ticketMap = toObjectMap(parseJsonObjectResponse(res, 'Freshservice create/get ticket').get('ticket'));
        FreshserviceWrapper.CreateTicketResponse response = new FreshserviceWrapper.CreateTicketResponse();
        response.ticket = mapTicket(ticketMap);
        response.articles = mapConversationCollectionToArticles(ticketMap == null ? null : ticketMap.get('conversations'));
        return response;
    }

    // Parse service catalog response.
    public static FreshserviceWrapper.ServiceCatalogResponse parseServiceCatalogResponse(HttpResponse res) {
        FreshserviceWrapper.ServiceCatalogResponse response = new FreshserviceWrapper.ServiceCatalogResponse();
        response.service_request = mapServiceRequest(toObjectMap(parseJsonObjectResponse(res, 'Freshservice service catalog').get('service_request')));
        return response;
    }

    // Map ticket response object.
    private static FreshserviceWrapper.Ticket mapTicket(Map<String, Object> data) {
        if (data == null) {
            return null;
        }

        FreshserviceWrapper.Ticket ticket = new FreshserviceWrapper.Ticket();
        ticket.id = toLong(data.get('id'));
        ticket.display_id = toLong(data.get('display_id'));
        ticket.subject = toStringValue(data.get('subject'));
        ticket.description = toStringValue(data.get('description'));
        ticket.status = toInteger(data.get('status'));
        ticket.priority = toInteger(data.get('priority'));
        ticket.source = toInteger(data.get('source'));
        ticket.type = toStringValue(data.get('type'));
        ticket.workspace_id = toInteger(data.get('workspace_id'));
        ticket.custom_fields = toObjectMap(data.get('custom_fields'));
        return ticket;
    }

    // Map service request object.
    private static FreshserviceWrapper.ServiceRequest mapServiceRequest(Map<String, Object> data) {
        if (data == null) {
            return null;
        }

        FreshserviceWrapper.ServiceRequest serviceRequest = new FreshserviceWrapper.ServiceRequest();
        serviceRequest.id = toLong(data.get('id'));
        serviceRequest.display_id = toLong(data.get('display_id'));
        serviceRequest.subject = toStringValue(data.get('subject'));
        serviceRequest.status = toInteger(data.get('status'));
        serviceRequest.priority = toInteger(data.get('priority'));
        serviceRequest.workspace_id = toInteger(data.get('workspace_id'));
        serviceRequest.custom_fields = toObjectMap(data.get('custom_fields'));
        return serviceRequest;
    }

    // Check private conversation flag.
    private static Boolean isPrivateConversation(Map<String, Object> conversationMap) {
        if (conversationMap == null) {
            return false;
        }

        Object privateValue = conversationMap.get('private') == null ? conversationMap.get('private_note') : conversationMap.get('private');
        return privateValue != null && String.valueOf(privateValue).trim().toLowerCase() == 'true';
    }

    // Map conversations to articles.
    private static List<Object> mapConversationCollectionToArticles(Object conversationsObj) {
        List<Object> articles = new List<Object>();
        List<Object> conversations = toObjectList(conversationsObj);

        if (conversations == null || conversations.isEmpty()) {
            return articles;
        }

        for (Object conversationObj : conversations) {
            Map<String, Object> conversationMap = toObjectMap(conversationObj);
            if (conversationMap != null && !isPrivateConversation(conversationMap)) {
                articles.add(mapConversationToArticle(conversationMap));
            }
        }

        return articles;
    }

    // Map conversation into article.
    private static Map<String, Object> mapConversationToArticle(Map<String, Object> conversationMap) {
        return new Map<String, Object>{
            'ArticleId' => toStringValue(conversationMap.get('id')),
            'From' => getConversationFromValue(conversationMap),
            'To' => getConversationToValue(conversationMap),
            'Subject' => getConversationSubjectValue(conversationMap),
            'Body' => getConversationBodyValue(conversationMap),
            'updateTime' => getConversationTimeValue(conversationMap),
            'Attachment' => mapConversationAttachments(conversationMap)
        };
    }

    // Resolve conversation sender value.
    private static String getConversationFromValue(Map<String, Object> conversationMap) {
        String fromEmail = toStringValue(conversationMap.get('from_email'));
        if (String.isNotBlank(fromEmail)) {
            return fromEmail;
        }

        String supportEmail = toStringValue(conversationMap.get('support_email'));
        if (String.isNotBlank(supportEmail)) {
            return supportEmail;
        }

        String userId = toStringValue(conversationMap.get('user_id'));
        return String.isNotBlank(userId) ? 'User ' + userId : 'Freshservice';
    }

    // Resolve conversation recipient value.
    private static String getConversationToValue(Map<String, Object> conversationMap) {
        List<Object> toEmails = toObjectList(conversationMap.get('to_emails'));
        List<String> values = new List<String>();

        if (toEmails == null || toEmails.isEmpty()) {
            return '';
        }

        for (Object emailObj : toEmails) {
            String email = toStringValue(emailObj);
            if (String.isNotBlank(email)) {
                values.add(email);
            }
        }

        return String.join(values, ', ');
    }

    // Resolve conversation body value.
    private static String getConversationBodyValue(Map<String, Object> conversationMap) {
        String body = toStringValue(conversationMap.get('body'));
        if (String.isNotBlank(body)) {
            return body;
        }

        String bodyText = toStringValue(conversationMap.get('body_text'));
        return String.isNotBlank(bodyText) ? bodyText : '';
    }

    // Resolve conversation time value.
    private static String getConversationTimeValue(Map<String, Object> conversationMap) {
        String updatedAt = toStringValue(conversationMap.get('updated_at'));
        if (String.isNotBlank(updatedAt)) {
            return updatedAt;
        }

        String createdAt = toStringValue(conversationMap.get('created_at'));
        return String.isNotBlank(createdAt) ? createdAt : '';
    }

    // Map conversation attachment records.
    private static List<Object> mapConversationAttachments(Map<String, Object> conversationMap) {
        List<Object> attachments = toObjectList(conversationMap.get('attachments'));
        List<Object> mappedAttachments = new List<Object>();

        if (attachments == null || attachments.isEmpty()) {
            return mappedAttachments;
        }

        for (Object attachmentObj : attachments) {
            Map<String, Object> attachmentMap = toObjectMap(attachmentObj);
            if (attachmentMap == null) {
                continue;
            }

            String fileName = toStringValue(attachmentMap.get('name'));

            mappedAttachments.add(new Map<String, Object>{
                'AttachmentId' => toStringValue(attachmentMap.get('id')),
                'FileName' => String.isNotBlank(fileName) ? fileName : toStringValue(attachmentMap.get('file_name')),
                'ContentType' => toStringValue(attachmentMap.get('content_type')),
                'Content' => '',
                'Url' => toStringValue(attachmentMap.get('attachment_url'))
            });
        }

        return mappedAttachments;
    }

    // Find matching ticket number.
    private static String getMatchingTicketNumberFromFilterResult(List<Object> tickets, String waybillNo) {
        if (tickets == null || tickets.isEmpty()) {
            return null;
        }

        String fallbackTicketNumber;
        String normalizedWaybill = normalizeValue(waybillNo);

        for (Object ticketObj : tickets) {
            Map<String, Object> ticketMap = toObjectMap(ticketObj);

            if (ticketMap == null || toInteger(ticketMap.get('status')) == 5) {
                continue;
            }

            if (fallbackTicketNumber == null) {
                fallbackTicketNumber = getFormattedTicketNumberFromMap(ticketMap);
            }

            Map<String, Object> customFields = toObjectMap(ticketMap.get('custom_fields'));

            if (customFields != null && String.isNotBlank(normalizedWaybill) && normalizeValue(customFields.get('waybill_number')) == normalizedWaybill) {
                return getFormattedTicketNumberFromMap(ticketMap);
            }
        }

        return fallbackTicketNumber;
    }

    // Format Freshservice ticket number.
    private static String getFormattedTicketNumberFromMap(Map<String, Object> ticketMap) {
        if (ticketMap == null) {
            return null;
        }

        Long ticketId = toLong(ticketMap.get('id'));
        if (ticketId != null) {
            return 'FSC-' + ticketId;
        }

        Long displayId = toLong(ticketMap.get('display_id'));
        return displayId == null ? null : 'FSC-' + displayId;
    }

    // Validate Freshservice API response.
    private static void validateResponse(HttpResponse res, String contextName) {
        if (res == null) {
            throw new CalloutException(contextName + ' response cannot be null.');
        }

        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new CalloutException(contextName + ' failed. RAW_STATUS=' + res.getStatusCode() + ', RAW_BODY=' + getSafeBodyForError(res.getBody()));
        }
    }

    // Parse JSON object response.
    private static Map<String, Object> parseJsonObjectResponse(HttpResponse res, String contextName) {
        validateResponse(res, contextName);

        if (String.isBlank(res.getBody())) {
            throw new CalloutException(contextName + ' returned blank response body.');
        }

        String body = res.getBody().trim();

        if (!body.startsWith('{')) {
            throw new CalloutException(contextName + ' returned non-JSON object response. RAW_BODY=' + getSafeBodyForError(body));
        }

        try {
            return (Map<String, Object>) JSON.deserializeUntyped(body);
        } catch (Exception parseExp) {
            throw new CalloutException(contextName + ' response parse failed. ERROR=' + parseExp.getMessage() + ', RAW_BODY=' + getSafeBodyForError(body));
        }
    }

    // Safely cast object map.
    private static Map<String, Object> toObjectMap(Object value) {
        if (value == null) {
            return null;
        }

        try {
            return (Map<String, Object>) value;
        } catch (Exception exp) {
            return null;
        }
    }

    // Safely cast object list.
    private static List<Object> toObjectList(Object value) {
        if (value == null) {
            return null;
        }

        try {
            return (List<Object>) value;
        } catch (Exception exp) {
            return null;
        }
    }

    // Extract ticket response id.
    public static Long getTicketId(FreshserviceWrapper.CreateTicketResponse resp) {
        return resp != null && resp.ticket != null ? resp.ticket.id : null;
    }

    // Build formatted ticket number.
    public static String getTicketNumber(FreshserviceWrapper.CreateTicketResponse resp) {
        Long ticketId = getTicketId(resp);
        return ticketId == null ? null : 'FSC-' + ticketId;
    }

    // Extract service request id.
    public static Long getServiceRequestId(FreshserviceWrapper.ServiceCatalogResponse resp) {
        return resp != null && resp.service_request != null ? resp.service_request.id : null;
    }

    // Build service request number.
    public static String getServiceRequestNumber(FreshserviceWrapper.ServiceCatalogResponse resp) {
        Long serviceRequestId = getServiceRequestId(resp);
        return serviceRequestId == null ? null : 'FSC-' + serviceRequestId;
    }

    // Extract numeric ticket id.
    public static Long extractTicketIdFromFormattedValue(String ticketNo) {
        if (String.isBlank(ticketNo)) {
            return null;
        }

        try {
            return Long.valueOf(ticketNo.replace('FSC-', '').trim());
        } catch (Exception exp) {
            return null;
        }
    }

    // Convert object to Long.
    private static Long toLong(Object value) {
        if (value == null) {
            return null;
        }

        String stringValue = String.valueOf(value).trim();

        if (String.isBlank(stringValue)) {
            return null;
        }

        try {
            return Long.valueOf(stringValue.contains('.') ? stringValue.substring(0, stringValue.indexOf('.')) : stringValue);
        } catch (Exception exp) {
            return null;
        }
    }

    // Convert object to Integer.
    private static Integer toInteger(Object value) {
        if (value == null) {
            return null;
        }

        String stringValue = String.valueOf(value).trim();

        if (String.isBlank(stringValue)) {
            return null;
        }

        try {
            return Integer.valueOf(stringValue.contains('.') ? stringValue.substring(0, stringValue.indexOf('.')) : stringValue);
        } catch (Exception exp) {
            return null;
        }
    }

    private static String getConversationSubjectValue(Map<String, Object> conversationMap) {
        

        Boolean isServiceCloudComment = String.isNotBlank(toStringValue(conversationMap.get('from_email'))) && String.isNotBlank(toStringValue(conversationMap.get('support_email'))) &&
                                        toStringValue(conversationMap.get('from_email')).trim().equalsIgnoreCase(toStringValue(conversationMap.get('support_email')).trim());

        return isServiceCloudComment ? 'Comment from Service Cloud' : 'Comment from Fresh Service';
    }

    // Convert object to String.
    private static String toStringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    // Normalize object string value.
    private static String normalizeValue(Object value) {
        return value == null ? null : String.valueOf(value).trim();
    }

    // Trim error response body.
    private static String getSafeBodyForError(String body) {
        return String.isBlank(body) || body.length() <= 1000 ? body : body.substring(0, 1000) + '...';
    }
}