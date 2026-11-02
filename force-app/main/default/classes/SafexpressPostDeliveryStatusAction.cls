/**
 * Post-delivery complaints for the Safexpress Agentforce chat agent.
 *
 * Entry points:
 *  1. execute()            - Agentforce invocable action (unchanged contract, returns SafexpressWaybillEnquiryCard)
 *  2. precheckEscalation() - called by LWC before uploading documents: validates + checks for an open complaint
 *  3. submitEscalation()   - called by LWC after uploading documents: creates case OR updates the existing case
 *
 * Issue types (form dropdown) and the Sub Type saved on the case:
 *   MATERIAL_DAMAGED -> Material Damaged                  (material group, documents required)
 *   SHORTAGE         -> Short Delivery                    (material group, documents required)
 *   NOT_RECEIVED     -> Delivery not done                 (material group, documents required)
 *   SHOWN_DELIVERED  -> Delivery not done                 (material group, documents required)
 *   (NOT_RECEIVED and SHOWN_DELIVERED share the Sub Type; the exact issue is written in Case.Description)
 *   STAFF_BEHAVIOUR  -> Branch / Office / Staff           (staff group, documents optional, description required)
 *
 * De-duplication (per group): one OPEN complaint per waybill per group.
 *   - Material group: any open complaint on the waybill whose Sub Type is NOT the staff sub type.
 *   - Staff group:    any open complaint on the waybill whose Sub Type IS the staff sub type.
 *
 * Open complaint found:
 *   - Material group: case without files -> files attached (PROOF_ADDED); case with files -> EXISTING_WITH_PROOF.
 *   - Staff group:    files attached if provided (PROOF_ADDED), otherwise EXISTING.
 *   - The customer's description is always added to the existing case as a Case Comment.
 */
public without sharing class SafexpressPostDeliveryStatusAction {

    private static final String DEFAULT_SUBTYPE = 'Material Damaged';
    private static final String STAFF_SUBTYPE = 'Branch / Office / Staff';
    private static final String TIMEZONE_IST = 'Asia/Kolkata';
    // Uploaded files are only accepted as proof if uploaded by the same user within this window
    private static final Integer PROOF_UPLOAD_WINDOW_HOURS = 2;
    // New complaint cases are owned by this queue (Group.DeveloperName)
    private static final String COMPLAINTS_QUEUE_DEV_NAME = 'Complaints';
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
            Case existing = lookup.findLatestOpenComplaint(inp.waybillVariants(), inp.isStaff);

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
    }

    /**
     * Step 1 (before any upload): validate inputs and check for an open complaint in the same group.
     * Tells the LWC whether documents are required and whether to upload them.
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
            Case existing = lookup.findLatestOpenComplaint(inp.waybillVariants(), inp.isStaff);

            if (existing == null) {
                EscalationResult r = baseResult(inp, OUTCOME_NEW);
                r.proofRequired = !inp.isStaff;
                r.uploadFiles = true;
                r.message = 'No open complaint found for this waybill.';
                return r;
            }

            // Material group: an open case that already has documents does not need more
            if (!inp.isStaff && lookup.hasProof(existing.Id)) {
                EscalationResult r = existingWithProofResult(inp, existing);
                r.uploadFiles = false;
                return r;
            }

            EscalationResult r = existingResult(
                inp, existing, OUTCOME_EXISTING_NEEDS_PROOF,
                'An active case (' + existing.CaseNumber + ') is already open for this waybill. Your details will be added to it.'
            );
            r.proofRequired = !inp.isStaff;
            r.uploadFiles = true;
            return r;

        } catch (Exception ex) {
            return errorResult(inp, ex);
        }
    }

    /**
     * Step 2 (after documents are uploaded via AgentforceImageUploadController.uploadProofFile):
     * re-runs de-duplication and either creates the case or updates the existing one.
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

        Savepoint sp = Database.setSavepoint();
        try {
            CaseLookup lookup = new CaseLookup();
            Set<Id> docIds = lookup.verifiedUploads(contentDocumentIds);
            Case existing = lookup.findLatestOpenComplaint(inp.waybillVariants(), inp.isStaff);

            // --- Open complaint in the same group: never create a new case ---
            if (existing != null) {
                Boolean caseHasProof = lookup.hasProof(existing.Id);

                if (!inp.isStaff && !caseHasProof && docIds.isEmpty()) {
                    return proofRequiredResult(inp);
                }

                // Keep the customer's new details on the existing case
                lookup.addCaseComment(existing.Id, inp.caseCommentText());
                lookup.linkSessionToCase(messagingSessionId, existing.Id);

                if (!inp.isStaff && caseHasProof) {
                    return existingWithProofResult(inp, existing);   // new files ignored
                }
                if (!docIds.isEmpty()) {
                    Integer linked = lookup.linkFiles(existing.Id, docIds);
                    return proofAddedResult(inp, existing, linked);
                }
                return existingUpdatedResult(inp, existing);         // staff group, no files
            }

            // --- No open complaint: documents are mandatory for material issues ---
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

        // Text added as a Case Comment on an existing case
        String caseCommentText() {
            return 'Additional details received via chat\n' + caseDescriptionText();
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

    private static EscalationResult existingWithProofResult(Inputs inp, Case c) {
        EscalationResult r = existingResult(
            inp, c, OUTCOME_EXISTING_WITH_PROOF,
            'An active case (' + c.CaseNumber + ') is already open for this waybill and your documents are already on record.'
        );
        r.agentMessage = 'An open complaint ' + c.CaseNumber + ' already exists for waybill '
            + inp.formattedWaybill + ' and documents are already on record.';
        return r;
    }

    private static EscalationResult existingUpdatedResult(Inputs inp, Case c) {
        EscalationResult r = existingResult(
            inp, c, OUTCOME_EXISTING,
            'An active case (' + c.CaseNumber + ') is already open for this waybill. Your details have been added to it.'
        );
        r.agentMessage = 'An open complaint ' + c.CaseNumber + ' already exists for waybill '
            + inp.formattedWaybill + '. The new details have been added to it.';
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

        // One OPEN complaint per waybill per group (material vs staff behaviour)
        Case findLatestOpenComplaint(Set<String> waybillVariants, Boolean staffGroup) {
            String groupFilter = staffGroup
                ? 'AND Sub_Type__c = :staffSubType '
                : 'AND (Sub_Type__c = null OR Sub_Type__c != :staffSubType) ';
            String soql =
                'SELECT Id, CaseNumber, Status, CreatedDate, Subject, Sub_Type__c ' +
                'FROM Case ' +
                'WHERE WaybillNo__c IN :waybills ' +
                'AND IsClosed = false ' +
                'AND (Case_Nature__c = \'Complaint\' OR Type = \'Complaint\') ' +
                groupFilter +
                'ORDER BY CreatedDate DESC ' +
                'LIMIT 1';
            List<Case> cases = Database.queryWithBinds(
                soql,
                new Map<String, Object>{ 'waybills' => waybillVariants, 'staffSubType' => STAFF_SUBTYPE },
                AccessLevel.SYSTEM_MODE
            );
            return cases.isEmpty() ? null : cases[0];
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

        // Internal (not published) comment with the customer's new details
        void addCaseComment(Id caseId, String body) {
            if (String.isBlank(body)) return;
            CaseComment cc = new CaseComment(
                ParentId = caseId,
                CommentBody = body.abbreviate(3900),
                IsPublished = false
            );
            Database.insert(cc, AccessLevel.SYSTEM_MODE);
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