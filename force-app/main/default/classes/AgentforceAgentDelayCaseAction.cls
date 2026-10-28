public class AgentforceAgentDelayCaseAction {

    private static final String RECORD_TYPE_DEV_NAME = 'Complaint';
    private static final String CASE_NATURE          = 'Complaint';
    private static final String CASE_TYPE            = 'Service Issue';
    private static final String CASE_SUB_TYPE        = 'Delay in delivery';
    private static final String CASE_ORIGIN          = 'WhatsApp';
    private static final String CASE_STATUS          = 'New';
    private static final String QUEUE_DEV_NAME       = 'Complaints';

    @InvocableMethod(
        label       = 'Agentforce Agent — Create Delay In Delivery Case'
        description = 'Creates a Complaint Case with Type: Service Issue and Sub-Type: Delay in delivery. Waybill number is the primary key. Performs duplicate check, finds or creates Contact by phone, calculates priority dynamically from EDD and customer concern keywords, assigns to Complaints queue, and returns Case Number to the agent.'
        category    = 'Safexpress Agent Actions'
    )
    public static List<AgentforceAgentDelayCaseResult> createDelayCase(
                       List<AgentforceAgentDelayCaseRequest> requests) {

        List<AgentforceAgentDelayCaseResult> results =
            new List<AgentforceAgentDelayCaseResult>();

        for (AgentforceAgentDelayCaseRequest req : requests) {
            AgentforceAgentDelayCaseResult result =
                new AgentforceAgentDelayCaseResult();

            try {

                // ── Edge 8: Validate required inputs ─────────────────────
                if (String.isBlank(req.waybillNumber)
                    || String.isBlank(req.customerConcern)
                    || String.isBlank(req.contactPhone)) {

                    result.success      = false;
                    result.errorMessage = 'Waybill number, customer concern '
                                       + 'and contact phone are all required.';
                    results.add(result);
                    continue;
                }

                // ── Edge 9: Clean waybill and phone ──────────────────────
                String cleanWaybill = req.waybillNumber.trim().toUpperCase();
                String cleanPhone   = req.contactPhone.trim();

                // ── Edge 2 + 3: Duplicate check — waybill is primary key ─
                List<Case> existingCases = [
                    SELECT Id, CaseNumber, Status, CreatedDate
                    FROM Case
                    WHERE WaybillNo__c  = :cleanWaybill
                    AND   Case_Type__c  = :CASE_TYPE
                    AND   Sub_Type__c   = :CASE_SUB_TYPE
                    AND   Status NOT IN ('Closed', 'Resolved', 'Cancelled')
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (!existingCases.isEmpty()) {
                    result.success          = true;
                    result.isDuplicate      = true;
                    result.caseId           = existingCases[0].Id;
                    result.caseNumber       = existingCases[0].CaseNumber;
                    result.duplicateMessage = 'You already have an open case '
                        + 'for waybill ' + cleanWaybill
                        + '. Your existing case reference number is '
                        + existingCases[0].CaseNumber
                        + '. Our team is already working on this.';
                    results.add(result);
                    continue;
                }

                // ── Edge 4 + 5: Find or create Contact ───────────────────
                Id resolvedContactId    = findOrCreateContact(cleanPhone);
                result.contactId        = resolvedContactId;

                // ── Get Record Type Id ────────────────────────────────────
                Id recordTypeId = Schema.SObjectType.Case
                    .getRecordTypeInfosByDeveloperName()
                    .get(RECORD_TYPE_DEV_NAME)
                    .getRecordTypeId();

                // ── Edge 7: Get Queue Id — graceful if missing ────────────
                Id queueId = getQueueId(QUEUE_DEV_NAME);

                // ── Edge 6: Build subject safely within 255 chars ─────────
                String subject = 'Delay in Delivery - ' + cleanWaybill;
                if (subject.length() > 255) {
                    subject = subject.substring(0, 255);
                }

                // ── Dynamic priority — Option 2 + 3 combined ─────────────
                String priority = determinePriority(
                    req.expectedDeliveryDate,
                    req.customerConcern
                );

                // ── Build the Case ────────────────────────────────────────
                Case newCase           = new Case();
                newCase.RecordTypeId   = recordTypeId;
                newCase.Case_Nature__c = CASE_NATURE;
                newCase.Case_Type__c   = CASE_TYPE;
                newCase.Sub_Type__c    = CASE_SUB_TYPE;
                newCase.Origin         = CASE_ORIGIN;
                newCase.Status         = CASE_STATUS;
                newCase.Priority       = priority;
                newCase.WaybillNo__c   = cleanWaybill;
                newCase.Description    = req.customerConcern;
                newCase.Subject        = subject;
                newCase.ContactId      = resolvedContactId;

                if (queueId != null) {
                    newCase.OwnerId = queueId;
                }

                // ── Edge 10: Link Messaging Session safely ────────────────
                if (String.isNotBlank(req.messagingSessionId)) {
                    try {
                        newCase.SourceId = req.messagingSessionId;
                    } catch (Exception sessionEx) {
                        // SourceId invalid — skip, still create the Case
                    }
                }

                insert newCase;

                // ── Get CaseNumber (auto-number field) ────────────────────
                Case inserted = [
                    SELECT CaseNumber
                    FROM Case
                    WHERE Id = :newCase.Id
                    LIMIT 1
                ];

                result.success         = true;
                result.isDuplicate     = false;
                result.caseId          = newCase.Id;
                result.caseNumber      = inserted.CaseNumber;
                result.casePrioritySet = priority;

            } catch (Exception e) {
                result.success      = false;
                result.errorMessage = 'Unable to create case: ' + e.getMessage();
                LoggerUtil.createErrorLog(
                    'AgentforceAgentDelayCaseAction',
                    'createDelayCase',
                    e.getTypeName(),
                    e.getMessage(),
                    e.getStackTraceString(),
                    null
                );
            }

            results.add(result);
        }

        return results;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRIORITY LOGIC — Option 2 + 3 combined
    //
    // Step 1: Check urgency keywords in customer concern — always overrides
    // Step 2: If no keyword — calculate from EDD (days delayed)
    //         0-1 days → Medium
    //         2+ days  → High
    // Step 3: If EDD unavailable — default Medium
    // ─────────────────────────────────────────────────────────────────────────
    private static String determinePriority(String edd, String concern) {

        // Step 1 — keyword check overrides everything
        if (String.isNotBlank(concern)) {
            String lowerConcern = concern.toLowerCase();
            List<String> urgencyKeywords = new List<String>{
                'urgent', 'medical', 'medicine', 'hospital',
                'client', 'business', 'wedding', 'emergency',
                'penalty', 'loss', 'critical', 'immediate',
                'court', 'legal', 'factory', 'production',
                'shutdown', 'expire', 'perishable'
            };
            for (String keyword : urgencyKeywords) {
                if (lowerConcern.contains(keyword)) {
                    return 'High';
                }
            }
        }

        // Step 2 — EDD-based calculation
        if (String.isBlank(edd)) {
            return 'Medium';
        }

        try {
            // API returns EDD as DD-MM-YYYY
            List<String> parts = edd.split('-');
            if (parts.size() != 3) {
                return 'Medium';
            }

            Date expectedDate  = Date.newInstance(
                Integer.valueOf(parts[2]),
                Integer.valueOf(parts[1]),
                Integer.valueOf(parts[0])
            );

            Integer daysDelayed = expectedDate.daysBetween(Date.today());

            if (daysDelayed >= 2) {
                return 'High';
            } else {
                return 'Medium';
            }

        } catch (Exception e) {
            // EDD parsing failed — safe default
            return 'Medium';
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONTACT RESOLUTION
    // Edge 4: Creates Contact if not found
    // Edge 5: ORDER BY CreatedDate DESC handles multiple matches
    // ─────────────────────────────────────────────────────────────────────────
    private static Id findOrCreateContact(String phone) {

        List<Contact> contacts = [
            SELECT Id
            FROM Contact
            WHERE Phone       = :phone
            OR    MobilePhone = :phone
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!contacts.isEmpty()) {
            return contacts[0].Id;
        }

        String lastFour = phone.length() >= 4
            ? phone.substring(phone.length() - 4)
            : phone;

        Contact newContact     = new Contact();
        newContact.LastName    = 'Customer ' + lastFour;
        newContact.MobilePhone = phone;
        newContact.Phone       = phone;
        insert newContact;

        return newContact.Id;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // QUEUE RESOLUTION
    // Edge 7: Returns null if queue not found
    //         Case still created, assigned to default owner
    // ─────────────────────────────────────────────────────────────────────────
    private static Id getQueueId(String devName) {

        List<Group> queues = [
            SELECT Id
            FROM Group
            WHERE Type          = 'Queue'
            AND   DeveloperName = :devName
            LIMIT 1
        ];

        return queues.isEmpty() ? null : queues[0].Id;
    }
}