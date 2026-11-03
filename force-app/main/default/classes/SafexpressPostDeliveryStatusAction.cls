/**
 * Post-delivery complaints for the Safexpress Agentforce chat agent.
 *
 * Entry points:
 *  1. execute()                    - Agentforce invocable action (unchanged contract, returns SafexpressWaybillEnquiryCard)
 *  2. checkWaybill()               - called by LWC as soon as Issue Type + Waybill are entered:
 *                                    tracking API status check (Delivered only) + open-case check for the same issue
 *  3. precheckEscalation()         - called by LWC before uploading documents: validates all fields
 *  4. submitEscalation()           - called by LWC after uploading documents: re-checks Delivered + duplicates, creates the case
 *  5. addDocumentsToExistingCase() - called by LWC when the same issue is already open: attaches documents only
 *
 * Issue types (form dropdown) and the Sub Type saved on the case:
 *   MATERIAL_DAMAGED -> Material Damaged          (documents required)
 *   SHORTAGE         -> Short Delivery            (documents required)
 *   NOT_RECEIVED     -> Delivery not done         (documents required)
 *   SHOWN_DELIVERED  -> Delivery not done         (documents required)
 *   (NOT_RECEIVED and SHOWN_DELIVERED share the Sub Type; the exact issue is written in Case.Description)
 *   STAFF_BEHAVIOUR  -> Branch / Office / Staff   (documents optional, description required)
 *
 * Rules:
 *   - A complaint can be raised only when the waybill status (tracking API) is Delivered.
 *   - De-duplication per issue type: one OPEN complaint per waybill per issue type.
 *     A different issue type on the same waybill creates a new case.
 *   - Same issue already open: the form shows the case and allows adding documents only
 *     (mandatory if the case has none, optional extra documents otherwise).
 */
public without sharing class SafexpressPostDeliveryStatusAction {

    private static final String DEFAULT_SUBTYPE = 'Material Damaged';
    private static final String STAFF_SUBTYPE = 'Branch / Office / Staff';
    private static final String TIMEZONE_IST = 'Asia/Kolkata';
    // Uploaded files are only accepted as proof if uploaded by the same user within this window
    private static final Integer PROOF_UPLOAD_WINDOW_HOURS = 2;
    // New complaint cases are owned by this queue (Group.DeveloperName)
    private static final String COMPLAINTS_QUEUE_DEV_NAME = 'Complaints';
    private static final String DELIVERY_NOT_DONE_SUBTYPE = 'Delivery not done';
    private static final Integer MIN_STAFF_DESCRIPTION = 20;
    private static final Integer MAX_DESCRIPTION = 2000;

    public static final String OUTCOME_NEW                  = 'NEW';                  // precheck: no open case
    public static final String OUTCOME_EXISTING_NEEDS_PROOF = 'EXISTING_NEEDS_PROOF'; // precheck: open case without documents
    public static final String OUTCOME_EXISTING_WITH_PROOF  = 'EXISTING_WITH_PROOF';  // open case already has documents
    public static final String OUTCOME_EXISTING             = 'EXISTING';             // open case found (details added)
    public static final String OUTCOME_CREATED              = 'CREATED';
    public static final String OUTCOME_PROOF_ADDED          = 'PROOF_ADDED';
    public static final String OUTCOME_PROOF_REQUIRED       = 'PROOF_REQUIRED';
    public static final String OUTCOME_VALIDATION_ERROR     = 'VALIDATION_ERROR';
    public static final String OUTCOME_ERROR                = 'ERROR';
    // checkWaybill outcomes
    public static final String OUTCOME_READY                = 'READY';            // Delivered, no open case for this issue
    public static final String OUTCOME_OPEN_CASE            = 'OPEN_CASE';        // same issue already open -> documents only
    public static final String OUTCOME_NOT_DELIVERED        = 'NOT_DELIVERED';    // status is not Delivered
    public static final String OUTCOME_INVALID_WAYBILL      = 'INVALID_WAYBILL';  // not 12 digits / API returned nothing
    public static final String OUTCOME_API_ERROR            = 'API_ERROR';        // tracking API unavailable

    private static final String MSG_INVALID_WAYBILL = 'Please provide a valid waybill number.';
    private static final String MSG_API_ERROR = 'We couldn\'t check your waybill right now. Please try again in a few minutes.';
    private static final String MSG_OPEN_CASE = 'A complaint is already open for this waybill. Our team is working on it.';

    // ---------- Issue types offered in the form ----------
    private class IssueType {
        String label;
        String subType;
        Boolean isStaff;
        IssueType(String label, String subType, Boolean isStaff) {
            this.label = label;
            this.subType = subType;
            this.isStaff = isStaff;
        }
    }

    private static final Map<String, IssueType> ISSUE_TYPES = new Map<String, IssueType>{
        'MATERIAL_DAMAGED' => new IssueType('Material Damaged', 'Material Damaged', false),
        'SHORTAGE'         => new IssueType('Shortage in the delivered material', 'Short Delivery', false),
        'NOT_RECEIVED'     => new IssueType('Expected material not received', 'Delivery not done', false),
        'SHOWN_DELIVERED'  => new IssueType('Material not received even though the status shows Delivered', 'Delivery not done', false),
        'STAFF_BEHAVIOUR'  => new IssueType('Bad behaviour of the delivery staff', STAFF_SUBTYPE, true)
    };

    // =====================================================================
    // 1. AGENTFORCE INVOCABLE ACTION (contract unchanged)
    // =====================================================================

    public class ActionRequest {
        @InvocableVariable(label='Waybill Number' required=true)
        public String waybillNumber;

        @InvocableVariable(label='Subtype')
        public String subtype;

        @InvocableVariable(label='Customer Email')
        public String customerEmail;

        @InvocableVariable(label='Customer Mobile')
        public String customerMobile;

        @InvocableVariable(label='Case Nature')
        public String caseNature;

        @InvocableVariable(label='Case Type')
        public String caseType;
    }

    public class ActionResponse {
        @InvocableVariable(label='Waybill Card')
        public SafexpressWaybillEnquiryCard waybillCard;

        @InvocableVariable(label='Waybill Status')
        public String waybillStatus;
    }

    @InvocableMethod(
        label='Process Post Delivery Escalation Chat Agent'
        description='Prevents duplicate cases, fetches latest open case, formats waybill, and returns clean card output.'
    )
    public static List<ActionResponse> execute(List<ActionRequest> requests) {
        List<ActionResponse> responseList = new List<ActionResponse>();

        for (ActionRequest req : requests) {
            Inputs inp = new Inputs(req.waybillNumber, req.customerEmail, req.customerMobile);
            inp.setSubType(req.subtype);
            inp.caseNature = String.isNotBlank(req.caseNature) ? req.caseNature : 'Complaint';
            inp.caseType = String.isNotBlank(req.caseType) ? req.caseType : 'Complaint';

            ActionResponse res = new ActionResponse();
            res.waybillCard = toCard(processWithoutProof(inp));
            res.waybillStatus = '';
            responseList.add(res);
        }

        return responseList;
    }

    // Same behaviour as before: existing open complaint -> show it, otherwise create a case
    private static EscalationResult processWithoutProof(Inputs inp) {
        String validationMsg = validate(inp, false);
        if (validationMsg != null) {
            return validationErrorResult(inp, validationMsg);
        }

        try {
            CaseLookup lookup = new CaseLookup();
            Case existing = lookup.findOpenComplaintForIssue(inp);

            if (existing != null) {
                return existingResult(
                    inp, existing, OUTCOME_EXISTING,
                    'An active case (' + existing.CaseNumber + ') is already open for this waybill.'
                );
            }

            Case created = createCase(inp, lookup);
            return createdResult(inp, created, 0);

        } catch (Exception ex) {
            return errorResult(inp, ex);
        }
    }

    // =====================================================================
    // 2. LWC METHODS (Enhanced Chat v2 form)
    // =====================================================================

    public class EscalationResult {
        @AuraEnabled public String outcome;
        @AuraEnabled public Boolean isError;
        @AuraEnabled public Boolean proofRequired;   // documents are mandatory for this submission
        @AuraEnabled public Boolean uploadFiles;     // LWC should upload the selected documents before submit
        @AuraEnabled public String headerTitle;
        @AuraEnabled public String message;
        @AuraEnabled public String lastEvent;
        @AuraEnabled public String footerNote;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String caseStatus;
        @AuraEnabled public String waybillFormatted;
        @AuraEnabled public String issueLabel;
        @AuraEnabled public String createdOn;
        @AuraEnabled public Integer filesAttached;
        @AuraEnabled public String agentMessage;   // text the LWC posts back into the chat
        @AuraEnabled public String waybillStatus;  // tracking status, e.g. Delivered / In Transit
        @AuraEnabled public Boolean docsOnly;      // same issue already open: only documents can be added
        @AuraEnabled public Boolean caseHasDocuments;
    }

    /**
     * Called as soon as Issue Type and Waybill are entered (before any other field is unlocked):
     *   1. waybill format, 2. tracking API status = Delivered, 3. open case for the same issue type.
     */
    @AuraEnabled
    public static EscalationResult checkWaybill(String waybillNumber, String issueType) {
        Inputs inp = new Inputs(waybillNumber, null, null);
        inp.setIssue(issueType);

        if (!inp.hasValidIssue()) {
            return validationErrorResult(inp, 'Please select the type of issue you are facing.');
        }
        if (!Pattern.matches('^\\d{12}$', inp.waybillNum)) {
            return waybillProblemResult(inp, OUTCOME_INVALID_WAYBILL, MSG_INVALID_WAYBILL, null);
        }

        try {
            // Callout first (no DML/savepoint before it)
            WaybillStatus ws = fetchWaybillStatus(inp.waybillNum);
            if (ws.outcome != OUTCOME_READY) {
                return waybillProblemResult(inp, ws.outcome, ws.message, ws.currentStatus);
            }

            CaseLookup lookup = new CaseLookup();
            Case existing = lookup.findOpenComplaintForIssue(inp);
            if (existing != null) {
                EscalationResult r = openCaseResult(inp, existing, lookup.hasProof(existing.Id));
                r.waybillStatus = ws.currentStatus;
                return r;
            }

            EscalationResult r = baseResult(inp, OUTCOME_READY);
            r.waybillStatus = ws.currentStatus;
            r.proofRequired = !inp.isStaff;
            r.uploadFiles = true;
            r.message = '';
            return r;

        } catch (Exception ex) {
            return waybillProblemResult(inp, OUTCOME_API_ERROR, MSG_API_ERROR, null);
        }
    }

    /**
     * Step 1 of submit (before any upload): validates all fields and checks for an open case for the same issue.
     */
    @AuraEnabled
    public static EscalationResult precheckEscalation(
        String waybillNumber,
        String mobileNumber,
        String emailId,
        String issueType,
        String description,
        String incidentDate
    ) {
        Inputs inp = formInputs(waybillNumber, mobileNumber, emailId, issueType, description, incidentDate);

        String validationMsg = validate(inp, true);
        if (validationMsg != null) {
            return validationErrorResult(inp, validationMsg);
        }

        try {
            CaseLookup lookup = new CaseLookup();
            Case existing = lookup.findOpenComplaintForIssue(inp);
            if (existing != null) {
                return openCaseResult(inp, existing, lookup.hasProof(existing.Id));
            }

            EscalationResult r = baseResult(inp, OUTCOME_NEW);
            r.proofRequired = !inp.isStaff;
            r.uploadFiles = true;
            r.message = 'No open complaint found for this waybill and issue.';
            return r;

        } catch (Exception ex) {
            return errorResult(inp, ex);
        }
    }

    /**
     * Step 2 of submit (after documents are uploaded via AgentforceImageUploadController.uploadProofFile):
     * re-checks Delivered on the server and the duplicate rule, then creates the case.
     * Everything is rolled back if any step fails.
     */
    @AuraEnabled
    public static EscalationResult submitEscalation(
        String waybillNumber,
        String mobileNumber,
        String emailId,
        String issueType,
        String description,
        String incidentDate,
        List<String> contentDocumentIds,
        String messagingSessionId
    ) {
        Inputs inp = formInputs(waybillNumber, mobileNumber, emailId, issueType, description, incidentDate);

        String validationMsg = validate(inp, true);
        if (validationMsg != null) {
            return validationErrorResult(inp, validationMsg);
        }

        // Server-side Delivered re-check (callout must run before any DML / savepoint)
        WaybillStatus ws;
        try {
            ws = fetchWaybillStatus(inp.waybillNum);
        } catch (Exception ex) {
            return waybillProblemResult(inp, OUTCOME_API_ERROR, MSG_API_ERROR, null);
        }
        if (ws.outcome != OUTCOME_READY) {
            return waybillProblemResult(inp, ws.outcome, ws.message, ws.currentStatus);
        }

        Savepoint sp = Database.setSavepoint();
        try {
            CaseLookup lookup = new CaseLookup();
            Case existing = lookup.findOpenComplaintForIssue(inp);

            // Same issue already open: never create a new case (form switches to documents-only)
            if (existing != null) {
                return openCaseResult(inp, existing, lookup.hasProof(existing.Id));
            }

            Set<Id> docIds = lookup.verifiedUploads(contentDocumentIds);
            if (!inp.isStaff && docIds.isEmpty()) {
                return proofRequiredResult(inp);
            }

            Case created = createCase(inp, lookup);
            Integer linked = docIds.isEmpty() ? 0 : lookup.linkFiles(created.Id, docIds);
            lookup.linkSessionToCase(messagingSessionId, created.Id);
            return createdResult(inp, created, linked);

        } catch (Exception ex) {
            Database.rollback(sp);
            return errorResult(inp, ex);
        }
    }

    /**
     * Same issue already open: attach the uploaded documents to that case (no new case, no other changes).
     * Documents are mandatory when the open case has none.
     */
    @AuraEnabled
    public static EscalationResult addDocumentsToExistingCase(
        String waybillNumber,
        String issueType,
        List<String> contentDocumentIds,
        String messagingSessionId
    ) {
        Inputs inp = new Inputs(waybillNumber, null, null);
        inp.setIssue(issueType);

        if (!inp.hasValidIssue()) {
            return validationErrorResult(inp, 'Please select the type of issue you are facing.');
        }
        if (!Pattern.matches('^\\d{12}$', inp.waybillNum)) {
            return waybillProblemResult(inp, OUTCOME_INVALID_WAYBILL, MSG_INVALID_WAYBILL, null);
        }

        Savepoint sp = Database.setSavepoint();
        try {
            CaseLookup lookup = new CaseLookup();
            Case existing = lookup.findOpenComplaintForIssue(inp);
            if (existing == null) {
                return validationErrorResult(inp,
                    'The open complaint for this waybill could not be found. Please refresh and submit a new complaint.');
            }

            Set<Id> docIds = lookup.verifiedUploads(contentDocumentIds);
            if (docIds.isEmpty()) {
                return lookup.hasProof(existing.Id)
                    ? validationErrorResult(inp, 'Please upload at least one document to add to your complaint.')
                    : proofRequiredResult(inp);
            }

            Integer linked = lookup.linkFiles(existing.Id, docIds);
            lookup.linkSessionToCase(messagingSessionId, existing.Id);
            return proofAddedResult(inp, existing, linked);

        } catch (Exception ex) {
            Database.rollback(sp);
            return errorResult(inp, ex);
        }
    }

    // =====================================================================
    // WAYBILL STATUS (tracking API) - same logic as SafexpressWaybillEnquiryAction
    // =====================================================================

    private class WaybillStatus {
        String outcome;        // READY (Delivered) / NOT_DELIVERED / INVALID_WAYBILL / API_ERROR
        String currentStatus;
        String message;
    }

    private static WaybillStatus fetchWaybillStatus(String waybillNum) {
        WaybillStatus ws = new WaybillStatus();

        String rawJson;
        try {
            rawJson = GetWayBillStatusAPI.getWayBillInfo(waybillNum);
        } catch (Exception ex) {
            ws.outcome = OUTCOME_API_ERROR;
            ws.message = MSG_API_ERROR;
            return ws;
        }

        // NULL / not found -> invalid waybill
        if (String.isBlank(rawJson) || rawJson.contains('Not Found')) {
            ws.outcome = OUTCOME_INVALID_WAYBILL;
            ws.message = MSG_INVALID_WAYBILL;
            return ws;
        }

        WayBillResponseWrapper wrapper;
        try {
            wrapper = (WayBillResponseWrapper) JSON.deserialize(rawJson, WayBillResponseWrapper.class);
        } catch (Exception ex) {
            ws.outcome = OUTCOME_API_ERROR;
            ws.message = MSG_API_ERROR;
            return ws;
        }
        if (wrapper == null || wrapper.data == null) {
            ws.outcome = OUTCOME_INVALID_WAYBILL;
            ws.message = MSG_INVALID_WAYBILL;
            return ws;
        }

        String currentStatus = null;
        if (wrapper.data.track != null && !wrapper.data.track.isEmpty()) {
            WayBillResponseWrapper.Track latest = wrapper.data.track[0];
            String cleanWebsite = normalizeStatus(latest.websiteMsg);
            String cleanEvent = normalizeStatus(latest.eventDescr);
            currentStatus = String.isNotBlank(cleanWebsite) ? cleanWebsite : cleanEvent;
        }
        ws.currentStatus = String.isNotBlank(currentStatus) ? currentStatus : 'Not available';

        Boolean isDelivered = String.isNotBlank(currentStatus)
            && currentStatus.toLowerCase().contains('delivered')
            && !currentStatus.toLowerCase().contains('undelivered');

        if (isDelivered) {
            ws.outcome = OUTCOME_READY;
        } else {
            ws.outcome = OUTCOME_NOT_DELIVERED;
            ws.message = 'The current status of your consignment is ' + ws.currentStatus
                + '. A complaint can be raised only when the status is Delivered.';
        }
        return ws;
    }

    // Copied from SafexpressWaybillEnquiryAction so the form and the enquiry card always agree
    private static String normalizeStatus(String raw) {
        if (String.isBlank(raw)) return null;
        String s = raw.toLowerCase();
        if (s.contains('out for delivery'))                         return 'Out for Delivery';
        if (s.contains('delivered') && !s.contains('undelivered')) return 'Delivered';
        if (s.contains('undelivered'))                             return 'Undelivered';
        if (s.contains('arrived at destination'))                  return 'Arrived at Destination';
        if (s.contains('arrived'))                                 return 'Arrived at Destination';
        if (s.contains('in transit'))                              return 'In Transit';
        if (s.contains('departed') || s.contains('transit'))       return 'In Transit';
        if (s.contains('booked') || s.contains('rps created'))     return 'Booked';
        if (s.contains('picked up') || s.contains('pickup'))       return 'Picked Up';
        if (s.contains('cancelled') || s.contains('canceled'))     return 'Cancelled';
        if (s.contains('pending'))                                 return 'Pending';
        if (s.contains('waybill arrived'))                         return 'Arrived at Destination';
        if (s.contains('waybill in transit') || s.contains('is departed') || s.contains('vehicle')) return 'In Transit';
        return raw;
    }

    // =====================================================================
    // SHARED HELPERS
    // =====================================================================

    private class Inputs {
        String rawWaybill;
        String waybillNum;
        String formattedWaybill;
        String email;
        String mobile;
        String subType = DEFAULT_SUBTYPE;
        String caseNature = 'Complaint';
        String caseType = 'Complaint';
        Boolean isStaff = false;

        // form-only fields
        String issueKey;
        String issueLabel;
        Boolean issueRequired = false;
        String description = '';
        String incidentDateRaw = '';
        Date incidentDate;

        Inputs(String waybill, String email, String mobile) {
            // Normalise waybill: digits only so "1000 4224 1409" and "100042241409" match
            this.rawWaybill = waybill != null ? waybill.trim() : '';
            String digits = this.rawWaybill.replaceAll('[^0-9]', '');
            this.waybillNum = String.isNotBlank(digits) ? digits : this.rawWaybill;
            this.formattedWaybill = this.waybillNum.length() == 12
                ? this.waybillNum.substring(0, 4) + ' ' + this.waybillNum.substring(4, 8) + ' ' + this.waybillNum.substring(8, 12)
                : this.waybillNum;

            this.email = email != null ? email.trim() : '';
            this.mobile = normaliseMobile(mobile);
        }

        // Invocable path: free-text sub type
        void setSubType(String value) {
            this.subType = String.isNotBlank(value) ? value.trim() : DEFAULT_SUBTYPE;
            this.isStaff = this.subType == STAFF_SUBTYPE;
            this.issueLabel = this.subType;
        }

        // Form path: dropdown key
        void setIssue(String key) {
            this.issueRequired = true;
            this.issueKey = key != null ? key.trim().toUpperCase() : '';
            IssueType it = ISSUE_TYPES.get(this.issueKey);
            if (it != null) {
                this.subType = it.subType;
                this.isStaff = it.isStaff;
                this.issueLabel = it.label;
            }
        }

        Boolean hasValidIssue() {
            return !this.issueRequired || ISSUE_TYPES.containsKey(this.issueKey);
        }

        Set<String> waybillVariants() {
            return new Set<String>{ this.waybillNum, this.formattedWaybill, this.rawWaybill };
        }

        // Text saved in Case.Description for a new case
        String caseDescriptionText() {
            List<String> lines = new List<String>{ 'Issue: ' + (String.isNotBlank(this.issueLabel) ? this.issueLabel : this.subType) };
            if (this.incidentDate != null) {
                lines.add('Incident date: ' + Datetime.newInstance(this.incidentDate, Time.newInstance(0, 0, 0, 0)).format('dd-MMM-yyyy'));
            }
            if (String.isNotBlank(this.description)) {
                lines.add('Customer description: ' + this.description);
            }
            lines.add('Raised via: Safexpress chat (Post Delivery Complaint form)');
            return String.join(lines, '\n');
        }
    }

    private static Inputs formInputs(
        String waybillNumber, String mobileNumber, String emailId,
        String issueType, String description, String incidentDate
    ) {
        Inputs inp = new Inputs(waybillNumber, emailId, mobileNumber);
        inp.setIssue(issueType);
        inp.description = description != null ? description.trim() : '';
        inp.incidentDateRaw = incidentDate != null ? incidentDate.trim() : '';
        if (String.isNotBlank(inp.incidentDateRaw)) {
            try {
                inp.incidentDate = Date.valueOf(inp.incidentDateRaw);   // yyyy-MM-dd from <input type="date">
            } catch (Exception e) {
                inp.incidentDate = null;
            }
        }
        return inp;
    }

    // "+91 98765 43210" / "09876543210" -> "9876543210"
    private static String normaliseMobile(String mobile) {
        if (String.isBlank(mobile)) return '';
        String digits = mobile.replaceAll('[^0-9]', '');
        if (digits.length() == 12 && digits.startsWith('91')) {
            digits = digits.substring(2);
        } else if (digits.length() == 11 && digits.startsWith('0')) {
            digits = digits.substring(1);
        }
        return String.isNotBlank(digits) ? digits : mobile.trim();
    }

    // requireAll = true for the LWC form (all fields mandatory)
    private static String validate(Inputs inp, Boolean requireAll) {
        if (!inp.hasValidIssue()) {
            return 'Please select the type of issue you are facing.';
        }
        if (String.isBlank(inp.waybillNum)) {
            return 'Please provide your 12-digit waybill number.';
        }
        if (requireAll && !Pattern.matches('^\\d{12}$', inp.waybillNum)) {
            return 'Invalid waybill number (' + inp.rawWaybill + '). Please enter your 12-digit waybill number.';
        }
        if (requireAll && String.isBlank(inp.mobile)) {
            return 'Please provide your 10-digit mobile number.';
        }
        if (requireAll && String.isBlank(inp.email)) {
            return 'Please provide your email address.';
        }
        if (String.isNotBlank(inp.email)) {
            String emailProblem = emailRejectionReason(inp.email);
            if (emailProblem != null) {
                return emailProblem;
            }
        }
        if (String.isNotBlank(inp.mobile) && !isValidMobile(inp.mobile)) {
            return 'Invalid mobile number provided (' + inp.mobile + '). Please provide a genuine 10-digit mobile number.';
        }
        if (requireAll && inp.isStaff && inp.description.length() < MIN_STAFF_DESCRIPTION) {
            return 'Please describe what happened (at least ' + MIN_STAFF_DESCRIPTION + ' characters).';
        }
        if (inp.description.length() > MAX_DESCRIPTION) {
            return 'Description is too long. Please keep it under ' + MAX_DESCRIPTION + ' characters.';
        }
        if (String.isNotBlank(inp.incidentDateRaw) && inp.incidentDate == null) {
            return 'Please enter a valid incident date.';
        }
        if (inp.incidentDate != null && inp.incidentDate > Date.today()) {
            return 'Incident date cannot be in the future.';
        }
        return null;
    }

    private static Case createCase(Inputs inp, CaseLookup lookup) {
        Case newCase = new Case();
        newCase.Origin = 'Chat';
        newCase.WaybillNo__c = inp.waybillNum;
        newCase.SuppliedEmail = inp.email;
        newCase.SuppliedPhone = inp.mobile;
        newCase.Type = inp.caseType;            // kept: de-duplication query also checks Type
        newCase.Case_Type__c = inp.caseType;    // "Case Type" shown on the page layout
        newCase.Sub_Type__c = inp.subType;
        newCase.Case_Nature__c = inp.caseNature;
        newCase.Status = 'New';
        if (inp.issueRequired) {
            newCase.Description = inp.caseDescriptionText();
        }
        // Subject intentionally not set: CaseTriggerHandler.updateSubject() builds
        // "<CaseNumber>-Complaint-Complaint-<Sub Type>" when Subject is blank

        // Assign to Complaints Queue (looked up by DeveloperName, so it works in every org)
        Id complaintsQueueId = lookup.getQueueId(COMPLAINTS_QUEUE_DEV_NAME);
        if (complaintsQueueId != null) {
            newCase.OwnerId = complaintsQueueId;
        }

        Database.insert(newCase, AccessLevel.SYSTEM_MODE);

        // Re-read in system mode; never throws if the row is not visible
        Case inserted = lookup.getById(newCase.Id);
        return inserted != null ? inserted : newCase;
    }

    // ---------- Result builders ----------

    private static EscalationResult baseResult(Inputs inp, String outcome) {
        EscalationResult r = new EscalationResult();
        r.outcome = outcome;
        r.isError = false;
        r.proofRequired = false;
        r.uploadFiles = false;
        r.docsOnly = false;
        r.caseHasDocuments = false;
        r.filesAttached = 0;
        r.waybillFormatted = inp.formattedWaybill;
        r.issueLabel = inp.issueLabel;
        return r;
    }

    private static void applyCase(EscalationResult r, Case c) {
        r.caseNumber = c.CaseNumber;
        r.caseStatus = String.isNotBlank(c.Status) ? c.Status : 'New';
        r.createdOn = c.CreatedDate != null ? c.CreatedDate.format('dd-MMM-yyyy HH:mm', TIMEZONE_IST) : '';
    }

    private static EscalationResult existingResult(Inputs inp, Case c, String outcome, String note) {
        EscalationResult r = baseResult(inp, outcome);
        applyCase(r, c);
        r.headerTitle = 'Existing Case Details';
        r.lastEvent = 'Created on: ' + r.createdOn;
        r.message = note;
        r.footerNote = note;
        return r;
    }

    // Same issue already open for this waybill -> form shows the case, documents only
    private static EscalationResult openCaseResult(Inputs inp, Case c, Boolean hasDocuments) {
        EscalationResult r = existingResult(inp, c, OUTCOME_OPEN_CASE, MSG_OPEN_CASE);
        r.docsOnly = true;
        r.caseHasDocuments = hasDocuments;
        r.proofRequired = !hasDocuments;
        r.uploadFiles = true;
        r.agentMessage = 'An open complaint ' + c.CaseNumber + ' already exists for waybill '
            + inp.formattedWaybill + '. Our team is working on it.';
        return r;
    }

    // Waybill could not be used: invalid / not delivered / API error
    private static EscalationResult waybillProblemResult(Inputs inp, String outcome, String msg, String currentStatus) {
        EscalationResult r = baseResult(inp, outcome);
        r.isError = true;
        r.waybillStatus = currentStatus;
        r.headerTitle = 'Waybill Check';
        r.message = msg;
        r.footerNote = msg;
        return r;
    }

    private static EscalationResult proofAddedResult(Inputs inp, Case c, Integer filesLinked) {
        EscalationResult r = baseResult(inp, OUTCOME_PROOF_ADDED);
        applyCase(r, c);
        r.filesAttached = filesLinked;
        r.headerTitle = 'Documents Added to Existing Case';
        r.lastEvent = 'Created on: ' + r.createdOn;
        r.message = 'Your documents have been added to the active case (' + c.CaseNumber + ') for this waybill.';
        r.footerNote = 'Thank you for choosing Safexpress. 😊';
        r.agentMessage = 'Documents (' + filesLinked + ' file(s)) added to existing case ' + c.CaseNumber
            + ' for waybill ' + inp.formattedWaybill + '.';
        return r;
    }

    private static EscalationResult createdResult(Inputs inp, Case c, Integer filesLinked) {
        EscalationResult r = baseResult(inp, OUTCOME_CREATED);
        applyCase(r, c);
        r.filesAttached = filesLinked;
        r.headerTitle = 'Escalation Registered';
        r.lastEvent = 'Complaint Registered for ' + (String.isNotBlank(inp.issueLabel) ? inp.issueLabel : inp.subType);
        r.message = String.isNotBlank(c.CaseNumber)
            ? 'Your complaint has been registered. Case #' + c.CaseNumber + ' created.'
            : 'Your complaint has been registered.';
        r.footerNote = String.isNotBlank(c.CaseNumber)
            ? 'Case #' + c.CaseNumber + ' created. Thank you for choosing Safexpress. 😊'
            : 'Your complaint has been registered. Thank you for choosing Safexpress. 😊';
        r.agentMessage = 'Complaint registered. Case ' + (String.isNotBlank(c.CaseNumber) ? c.CaseNumber : '')
            + ' created for waybill ' + inp.formattedWaybill
            + (filesLinked > 0 ? ' with ' + filesLinked + ' supporting document(s).' : '.');
        return r;
    }

    private static EscalationResult proofRequiredResult(Inputs inp) {
        EscalationResult r = baseResult(inp, OUTCOME_PROOF_REQUIRED);
        r.isError = true;
        r.proofRequired = true;
        r.uploadFiles = true;
        r.headerTitle = 'Documents Required';
        r.message = 'Please upload at least one image or PDF of the issue.';
        r.footerNote = 'Please re-submit with supporting documents attached.';
        return r;
    }

    private static EscalationResult validationErrorResult(Inputs inp, String msg) {
        EscalationResult r = baseResult(inp, OUTCOME_VALIDATION_ERROR);
        r.isError = true;
        r.headerTitle = 'Validation Error';
        r.message = msg;
        r.footerNote = 'Please re-submit with valid details.';
        return r;
    }

    private static EscalationResult errorResult(Inputs inp, Exception ex) {
        EscalationResult r = baseResult(inp, OUTCOME_ERROR);
        r.isError = true;
        r.headerTitle = 'System Error';
        r.message = 'An error occurred while processing your complaint: ' + ex.getMessage();
        r.footerNote = 'Please try again later.';
        return r;
    }

    // Maps a result onto the existing Agentforce output card
    private static SafexpressWaybillEnquiryCard toCard(EscalationResult r) {
        SafexpressWaybillEnquiryCard card = new SafexpressWaybillEnquiryCard();
        card.headerTitle = r.headerTitle;
        card.waybillNumberFormatted = r.waybillFormatted;
        card.footerNote = r.footerNote;

        if (r.isError) {
            card.errorMessage = r.message;
        } else {
            card.caseNumber = r.caseNumber;
            card.currentStatus = r.caseStatus;
            card.lastEvent = r.lastEvent;
        }
        return card;
    }

    // =====================================================================
    // SYSTEM-MODE DATA ACCESS
    // Agent / site guest user may not see queue-owned cases, so everything runs in system mode.
    // =====================================================================
    private without sharing class CaseLookup {

        // One OPEN complaint per waybill per issue type
        Case findOpenComplaintForIssue(Inputs inp) {
            String soql =
                'SELECT Id, CaseNumber, Status, CreatedDate, Subject, Sub_Type__c, Description ' +
                'FROM Case ' +
                'WHERE WaybillNo__c IN :waybills ' +
                'AND IsClosed = false ' +
                'AND (Case_Nature__c = \'Complaint\' OR Type = \'Complaint\') ' +
                'AND Sub_Type__c = :subType ' +
                'ORDER BY CreatedDate DESC ' +
                'LIMIT 50';
            List<Case> cases = Database.queryWithBinds(
                soql,
                new Map<String, Object>{ 'waybills' => inp.waybillVariants(), 'subType' => inp.subType },
                AccessLevel.SYSTEM_MODE
            );

            for (Case c : cases) {
                if (isSameIssue(c, inp)) return c;
            }
            return null;
        }

        // "Delivery not done" is shared by two issues: tell them apart by the issue text in Description
        Boolean isSameIssue(Case c, Inputs inp) {
            if (inp.subType != DELIVERY_NOT_DONE_SUBTYPE || !inp.issueRequired || String.isBlank(inp.issueLabel)) {
                return true;
            }
            String descr = c.Description != null ? c.Description : '';
            if (descr.contains('Issue: ' + inp.issueLabel)) return true;
            // Older cases without an "Issue:" line count as "Expected material not received"
            return !descr.contains('Issue: ') && inp.issueKey == 'NOT_RECEIVED';
        }

        Case getById(Id caseId) {
            List<Case> cases = Database.queryWithBinds(
                'SELECT Id, CaseNumber, Status, CreatedDate FROM Case WHERE Id = :caseId LIMIT 1',
                new Map<String, Object>{ 'caseId' => caseId },
                AccessLevel.SYSTEM_MODE
            );
            return cases.isEmpty() ? null : cases[0];
        }

        // Queue Id by DeveloperName; null if the queue does not exist
        Id getQueueId(String developerName) {
            List<Group> queues = Database.queryWithBinds(
                'SELECT Id FROM Group WHERE Type = \'Queue\' AND DeveloperName = :devName LIMIT 1',
                new Map<String, Object>{ 'devName' => developerName },
                AccessLevel.SYSTEM_MODE
            );
            return queues.isEmpty() ? null : queues[0].Id;
        }

        // Proof = at least one file linked to the case
        Boolean hasProof(Id caseId) {
            List<ContentDocumentLink> links = Database.queryWithBinds(
                'SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :caseId LIMIT 1',
                new Map<String, Object>{ 'caseId' => caseId },
                AccessLevel.SYSTEM_MODE
            );
            return !links.isEmpty();
        }

        // Only accept files uploaded by the current user in the last few hours
        // (stops someone passing arbitrary file Ids to attach to a case)
        Set<Id> verifiedUploads(List<String> contentDocumentIds) {
            Set<Id> requested = new Set<Id>();
            if (contentDocumentIds != null) {
                for (String rawId : contentDocumentIds) {
                    if (String.isBlank(rawId)) continue;
                    try {
                        Id docId = Id.valueOf(rawId.trim());
                        if (docId.getSObjectType() == ContentDocument.SObjectType) {
                            requested.add(docId);
                        }
                    } catch (Exception e) {
                        // invalid Id - skip
                    }
                }
            }

            Set<Id> verified = new Set<Id>();
            if (requested.isEmpty()) return verified;

            List<ContentVersion> versions = Database.queryWithBinds(
                'SELECT ContentDocumentId FROM ContentVersion ' +
                'WHERE ContentDocumentId IN :docIds ' +
                'AND IsLatest = true ' +
                'AND CreatedById = :userId ' +
                'AND CreatedDate >= :cutoff',
                new Map<String, Object>{
                    'docIds' => requested,
                    'userId' => UserInfo.getUserId(),
                    'cutoff' => Datetime.now().addHours(-PROOF_UPLOAD_WINDOW_HOURS)
                },
                AccessLevel.SYSTEM_MODE
            );
            for (ContentVersion cv : versions) {
                verified.add(cv.ContentDocumentId);
            }
            return verified;
        }

        // Links files to the case (skips files already linked); returns number of files
        Integer linkFiles(Id caseId, Set<Id> docIds) {
            List<ContentDocumentLink> existingLinks = Database.queryWithBinds(
                'SELECT ContentDocumentId FROM ContentDocumentLink ' +
                'WHERE LinkedEntityId = :caseId AND ContentDocumentId IN :docIds',
                new Map<String, Object>{ 'caseId' => caseId, 'docIds' => docIds },
                AccessLevel.SYSTEM_MODE
            );
            Set<Id> alreadyLinked = new Set<Id>();
            for (ContentDocumentLink l : existingLinks) {
                alreadyLinked.add(l.ContentDocumentId);
            }

            List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
            for (Id docId : docIds) {
                if (alreadyLinked.contains(docId)) continue;
                toInsert.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId = caseId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
            if (!toInsert.isEmpty()) {
                Database.insert(toInsert, AccessLevel.SYSTEM_MODE);
            }
            return docIds.size();
        }

        // Best effort: show the case on the Messaging Session for agents. Never fails the request.
        void linkSessionToCase(String messagingSessionId, Id caseId) {
            if (String.isBlank(messagingSessionId)) return;
            Id sessionId;
            try {
                sessionId = Id.valueOf(messagingSessionId.trim());
            } catch (Exception e) {
                return;
            }
            if (sessionId.getSObjectType() != MessagingSession.SObjectType) return;

            List<MessagingSession> sessions = Database.queryWithBinds(
                'SELECT Id, CaseId FROM MessagingSession WHERE Id = :sessionId LIMIT 1',
                new Map<String, Object>{ 'sessionId' => sessionId },
                AccessLevel.SYSTEM_MODE
            );
            if (sessions.isEmpty() || sessions[0].CaseId != null) return;

            sessions[0].CaseId = caseId;
            Database.update(sessions, false, AccessLevel.SYSTEM_MODE);   // allOrNone = false
        }
    }

    // =====================================================================
    // VALIDATION
    // =====================================================================

    // Blocks any email containing Safexpress in any spelling, case or position:
    // safexpress@gmail.com, abc@safexpress.co.in, abc@mail.safexpress.company.com,
    // Safe.Express@x.com, safe-xpress@x.com, safeexpress@x.com, safexpres@x.com ...
    private static final List<String> SAFEXPRESS_VARIANTS = new List<String>{ 'safexpres', 'safeexpres', 'safexprs' };

    private static Boolean isSafexpressEmail(String email) {
        if (String.isBlank(email)) return false;
        // lower-case + keep only letters/digits, so dots, hyphens, underscores, spaces etc. are ignored
        String compact = email.toLowerCase().replaceAll('[^a-z0-9]', '');
        for (String variant : SAFEXPRESS_VARIANTS) {
            if (compact.contains(variant)) return true;
        }
        return false;
    }

    // ---------- Email rules ----------
    private static final Set<String> BLOCKED_EMAIL_NAMES = new Set<String>{
        'test', 'testing', 'tester', 'testuser', 'testmail', 'dummy', 'fake', 'sample', 'demo',
        'abc', 'abcd', 'abcde', 'xyz', 'asdf', 'qwerty', 'user', 'admin', 'example', 'temp',
        'none', 'null', 'na', 'nil', 'xxx', 'aaa', 'name', 'email', 'mail', 'noreply', 'noemail'
    };
    private static final List<String> BLOCKED_EMAIL_NAME_PREFIXES = new List<String>{ 'dummy', 'fake', 'asdf', 'qwert', 'zxcv' };
    private static final Set<String> BLOCKED_DOMAIN_WORDS = new Set<String>{
        'test', 'testmail', 'testing', 'example', 'sample', 'dummy', 'fake', 'fakemail', 'abc', 'xyz',
        'temp', 'tempmail', 'domain', 'email', 'mailinator', 'yopmail', 'guerrillamail', 'trashmail',
        'throwaway', 'throwawaymail', 'getnada', 'sharklasers', 'dispostable', 'maildrop', 'mintemail',
        'mohmal', 'emailondeck', 'spamgourmet', 'discard', 'discardmail'
    };
    private static final List<String> DISPOSABLE_DOMAIN_PARTS = new List<String>{
        'mailinator', 'yopmail', 'tempmail', 'guerrillamail', 'trashmail', 'fakemail', 'throwaway', 'disposable', '10minute'
    };
    private static final List<String> KEYBOARD_RUNS = new List<String>{
        'qwert', 'werty', 'asdfg', 'sdfgh', 'zxcvb', 'xcvbn', 'yuiop', 'hjkl', 'qazwsx'
    };

    private static final String MSG_EMAIL_FORMAT =
        'Please enter a valid email address. Use only letters, numbers and dots before @ (starting with a letter), e.g. name.surname@gmail.com.';
    private static final String MSG_EMAIL_DOMAIN_DIGITS = 'The email domain (after @) cannot contain numbers.';
    private static final String MSG_EMAIL_TOO_MANY_DIGITS = 'Email name can contain at most 4 numbers.';
    private static final String MSG_EMAIL_TEST =
        'Test, dummy or temporary email addresses are not accepted. Please enter your real email address.';
    private static final String MSG_EMAIL_RANDOM = 'This email address doesn\'t look valid. Please enter your real email address.';
    private static final String MSG_EMAIL_SAFEXPRESS =
        'Safexpress email addresses can\'t be used. Please enter your personal or company email address.';

    private static Boolean regexFind(String regex, String value) {
        return Pattern.compile(regex).matcher(value).find();
    }

    // A word looks random: aaaa, titititi, 5+ consonants in a row, keyboard runs
    private static Boolean looksRandom(String letters) {
        if (String.isBlank(letters)) return false;
        if (regexFind('(.)\\1{3,}', letters)) return true;
        if (regexFind('(..+?)\\1{2,}', letters)) return true;
        if (regexFind('[bcdfghjklmnpqrstvwxz]{5,}', letters)) return true;
        for (String run : KEYBOARD_RUNS) {
            if (letters.contains(run)) return true;
        }
        return false;
    }

    // Returns the message to show, or null when the email is acceptable (same rules as the LWC)
    private static String emailRejectionReason(String rawEmail) {
        String e = rawEmail == null ? '' : rawEmail.trim().toLowerCase();
        if (String.isBlank(e)) return 'Please provide your email address.';
        if (isSafexpressEmail(e)) return MSG_EMAIL_SAFEXPRESS;

        List<String> parts = e.split('@', -1);
        if (parts.size() != 2) return MSG_EMAIL_FORMAT;
        String localPart = parts[0];
        String domain = parts[1];

        // Name: letters, digits, dots; starts with a letter; 3-40 chars; no "..", no trailing dot
        if (!Pattern.matches('^[a-z][a-z0-9.]{1,38}[a-z0-9]$', localPart) || localPart.contains('..')) return MSG_EMAIL_FORMAT;
        // Domain: no digits; letters/hyphens per part; ending of 2-6 letters
        if (regexFind('[0-9]', domain)) return MSG_EMAIL_DOMAIN_DIGITS;
        if (!Pattern.matches('^[a-z]+(-[a-z]+)*(\\.[a-z]+(-[a-z]+)*)*\\.[a-z]{2,6}$', domain)) return MSG_EMAIL_FORMAT;

        if (localPart.replaceAll('[^0-9]', '').length() > 4) return MSG_EMAIL_TOO_MANY_DIGITS;
        if (regexFind('(.)\\1{3,}', localPart)) return MSG_EMAIL_RANDOM;

        String letters = localPart.replaceAll('[^a-z]', '');
        if (letters.length() < 3) return MSG_EMAIL_RANDOM;

        // Test / dummy names
        if (BLOCKED_EMAIL_NAMES.contains(letters)) return MSG_EMAIL_TEST;
        for (String prefix : BLOCKED_EMAIL_NAME_PREFIXES) {
            if (letters.startsWith(prefix)) return MSG_EMAIL_TEST;
        }

        // Test / dummy / disposable domains
        List<String> labels = domain.split('\\.');
        List<String> nameLabels = new List<String>();
        for (Integer i = 0; i < labels.size() - 1; i++) {
            nameLabels.add(labels[i]);
        }
        for (String label : nameLabels) {
            if (BLOCKED_DOMAIN_WORDS.contains(label.replace('-', ''))) return MSG_EMAIL_TEST;
        }
        for (String part : DISPOSABLE_DOMAIN_PARTS) {
            if (domain.contains(part)) return MSG_EMAIL_TEST;
        }

        // Meaningless name: checked per dot-separated part, plus "no vowels at all"
        for (String seg : localPart.split('\\.')) {
            if (looksRandom(seg.replaceAll('[^a-z]', ''))) return MSG_EMAIL_RANDOM;
        }
        if (letters.length() >= 5 && !regexFind('[aeiouy]', letters)) return MSG_EMAIL_RANDOM;

        // Meaningless domain name
        for (String label : nameLabels) {
            for (String piece : label.split('-')) {
                if (looksRandom(piece)) return MSG_EMAIL_RANDOM;
            }
        }
        return null;
    }

    private static Boolean isValidEmail(String email) {
        return emailRejectionReason(email) == null;
    }

    private static Boolean isValidMobile(String mobile) {
        if (String.isBlank(mobile)) return false;
        String cleanMobile = mobile.trim();
        if (!Pattern.matches('^\\d{10}$', cleanMobile)) return false;
        if (Pattern.matches('^(\\d)\\1{9}$', cleanMobile)) return false;
        Set<String> blockedSequences = new Set<String>{
            '1234567890', '0123456789', '9876543210', '0987654321', '5555555555', '0000000000'
        };
        return !blockedSequences.contains(cleanMobile);
    }
}