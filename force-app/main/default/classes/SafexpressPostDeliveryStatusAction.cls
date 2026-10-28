/**
 * Post-delivery escalation (Material Damaged etc.) for the Safexpress Agentforce chat agent.
 *
 * Entry points:
 *  1. execute()            - Agentforce invocable action (unchanged contract, returns SafexpressWaybillEnquiryCard)
 *  2. precheckEscalation() - called by LWC before uploading proof: validates + checks for an open complaint
 *  3. submitEscalation()   - called by LWC after uploading proof: creates case OR adds proof to existing case
 *
 * De-duplication rule (unchanged): any OPEN complaint on the same waybill blocks a new case.
 * Proof rule: a case "has proof" when at least one file (ContentDocumentLink) is linked to it.
 *   - No open complaint            -> create case + attach proof (proof mandatory)
 *   - Open complaint without files -> attach proof to that case, no new case
 *   - Open complaint with files    -> nothing created / attached, show existing case
 */
public without sharing class SafexpressPostDeliveryStatusAction {

    private static final String DEFAULT_SUBTYPE = 'Material Damaged';
    private static final String TIMEZONE_IST = 'Asia/Kolkata';
    // Uploaded files are only accepted as proof if uploaded by the same user within this window
    private static final Integer PROOF_UPLOAD_WINDOW_HOURS = 2;

    public static final String OUTCOME_NEW                  = 'NEW';                  // precheck: no open case, proof needed
    public static final String OUTCOME_EXISTING_NEEDS_PROOF = 'EXISTING_NEEDS_PROOF'; // precheck: open case without proof
    public static final String OUTCOME_EXISTING_WITH_PROOF  = 'EXISTING_WITH_PROOF';  // open case already has proof
    public static final String OUTCOME_EXISTING             = 'EXISTING';             // invocable: open case found
    public static final String OUTCOME_CREATED              = 'CREATED';
    public static final String OUTCOME_PROOF_ADDED          = 'PROOF_ADDED';
    public static final String OUTCOME_PROOF_REQUIRED       = 'PROOF_REQUIRED';
    public static final String OUTCOME_VALIDATION_ERROR     = 'VALIDATION_ERROR';
    public static final String OUTCOME_ERROR                = 'ERROR';

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
            Inputs inp = new Inputs(
                req.waybillNumber, req.customerEmail, req.customerMobile,
                req.subtype, req.caseNature, req.caseType
            );

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
            Case existing = lookup.findLatestOpenComplaint(inp.waybillVariants());

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
        @AuraEnabled public Boolean proofRequired;
        @AuraEnabled public String headerTitle;
        @AuraEnabled public String message;
        @AuraEnabled public String lastEvent;
        @AuraEnabled public String footerNote;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String caseStatus;
        @AuraEnabled public String waybillFormatted;
        @AuraEnabled public String createdOn;
        @AuraEnabled public Integer filesAttached;
        @AuraEnabled public String agentMessage;   // text the LWC posts back into the chat
    }

    /**
     * Step 1 (before any upload): validate inputs and check for an open complaint.
     * If an open complaint already has proof, the LWC shows the result and skips the upload.
     */
    @AuraEnabled
    public static EscalationResult precheckEscalation(String waybillNumber, String mobileNumber, String emailId) {
        Inputs inp = new Inputs(waybillNumber, emailId, mobileNumber, null, null, null);

        String validationMsg = validate(inp, true);
        if (validationMsg != null) {
            return validationErrorResult(inp, validationMsg);
        }

        try {
            CaseLookup lookup = new CaseLookup();
            Case existing = lookup.findLatestOpenComplaint(inp.waybillVariants());

            if (existing == null) {
                EscalationResult r = baseResult(inp, OUTCOME_NEW);
                r.proofRequired = true;
                r.message = 'No open complaint found for this waybill. Proof is required to register a new complaint.';
                return r;
            }

            if (lookup.hasProof(existing.Id)) {
                return existingWithProofResult(inp, existing);
            }

            EscalationResult r = existingResult(
                inp, existing, OUTCOME_EXISTING_NEEDS_PROOF,
                'An active case (' + existing.CaseNumber + ') is already open for this waybill. Your proof will be added to it.'
            );
            r.proofRequired = true;
            return r;

        } catch (Exception ex) {
            return errorResult(inp, ex);
        }
    }

    /**
     * Step 2 (after files are uploaded via AgentforceImageUploadController.uploadProofFile):
     * re-runs de-duplication and either creates the case or adds proof to the existing one.
     * Everything is rolled back if any step fails, so no case is left without proof.
     */
    @AuraEnabled
    public static EscalationResult submitEscalation(
        String waybillNumber,
        String mobileNumber,
        String emailId,
        List<String> contentDocumentIds,
        String messagingSessionId
    ) {
        Inputs inp = new Inputs(waybillNumber, emailId, mobileNumber, null, null, null);

        String validationMsg = validate(inp, true);
        if (validationMsg != null) {
            return validationErrorResult(inp, validationMsg);
        }

        Savepoint sp = Database.setSavepoint();
        try {
            CaseLookup lookup = new CaseLookup();
            Set<Id> proofDocIds = lookup.verifiedUploads(contentDocumentIds);
            Case existing = lookup.findLatestOpenComplaint(inp.waybillVariants());

            // --- Open complaint exists: never create a new case ---
            if (existing != null) {
                if (lookup.hasProof(existing.Id)) {
                    return existingWithProofResult(inp, existing);   // new files ignored
                }
                if (proofDocIds.isEmpty()) {
                    return proofRequiredResult(inp);
                }
                Integer linked = lookup.linkFiles(existing.Id, proofDocIds);
                lookup.linkSessionToCase(messagingSessionId, existing.Id);
                return proofAddedResult(inp, existing, linked);
            }

            // --- No open complaint: proof is mandatory for a new case ---
            if (proofDocIds.isEmpty()) {
                return proofRequiredResult(inp);
            }

            Case created = createCase(inp, lookup);
            Integer linked = lookup.linkFiles(created.Id, proofDocIds);
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
        String subType;
        String caseNature;
        String caseType;

        Inputs(String waybill, String email, String mobile, String subtype, String caseNature, String caseType) {
            // Normalise waybill: digits only so "1000 4224 1409" and "100042241409" match
            this.rawWaybill = waybill != null ? waybill.trim() : '';
            String digits = this.rawWaybill.replaceAll('[^0-9]', '');
            this.waybillNum = String.isNotBlank(digits) ? digits : this.rawWaybill;
            this.formattedWaybill = this.waybillNum.length() == 12
                ? this.waybillNum.substring(0, 4) + ' ' + this.waybillNum.substring(4, 8) + ' ' + this.waybillNum.substring(8, 12)
                : this.waybillNum;

            this.email = email != null ? email.trim() : '';
            this.mobile = normaliseMobile(mobile);
            this.subType = String.isNotBlank(subtype) ? subtype : DEFAULT_SUBTYPE;
            this.caseNature = String.isNotBlank(caseNature) ? caseNature : 'Complaint';
            this.caseType = String.isNotBlank(caseType) ? caseType : 'Complaint';
        }

        Set<String> waybillVariants() {
            return new Set<String>{ this.waybillNum, this.formattedWaybill, this.rawWaybill };
        }
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
        if (String.isNotBlank(inp.email) && !isValidEmail(inp.email)) {
            return 'Invalid email address provided (' + inp.email + '). Please enter a valid email address.';
        }
        if (String.isNotBlank(inp.mobile) && !isValidMobile(inp.mobile)) {
            return 'Invalid mobile number provided (' + inp.mobile + '). Please provide a genuine 10-digit mobile number.';
        }
        return null;
    }

    private static Case createCase(Inputs inp, CaseLookup lookup) {
        Case newCase = new Case();
        newCase.Origin = 'Chat';
        newCase.WaybillNo__c = inp.waybillNum;
        newCase.SuppliedEmail = inp.email;
        newCase.SuppliedPhone = inp.mobile;
        newCase.Type = inp.caseType;
        newCase.Sub_Type__c = inp.subType;
        newCase.Case_Nature__c = inp.caseNature;
        newCase.Subject = 'Chat Escalation - ' + inp.subType + ' for Waybill ' + inp.waybillNum;
        newCase.Status = 'New';

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
        r.filesAttached = 0;
        r.waybillFormatted = inp.formattedWaybill;
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
            'An active case (' + c.CaseNumber + ') is already open for this waybill and your proof is already on record.'
        );
        r.agentMessage = 'An open complaint ' + c.CaseNumber + ' already exists for waybill '
            + inp.formattedWaybill + ' and proof is already on record.';
        return r;
    }

    private static EscalationResult proofAddedResult(Inputs inp, Case c, Integer filesLinked) {
        EscalationResult r = baseResult(inp, OUTCOME_PROOF_ADDED);
        applyCase(r, c);
        r.filesAttached = filesLinked;
        r.headerTitle = 'Proof Added to Existing Case';
        r.lastEvent = 'Created on: ' + r.createdOn;
        r.message = 'Your proof has been added to the active case (' + c.CaseNumber + ') for this waybill.';
        r.footerNote = 'Thank you for choosing Safexpress. 😊';
        r.agentMessage = 'Proof (' + filesLinked + ' file(s)) added to existing case ' + c.CaseNumber
            + ' for waybill ' + inp.formattedWaybill + '.';
        return r;
    }

    private static EscalationResult createdResult(Inputs inp, Case c, Integer filesLinked) {
        EscalationResult r = baseResult(inp, OUTCOME_CREATED);
        applyCase(r, c);
        r.filesAttached = filesLinked;
        r.headerTitle = 'Escalation Registered';
        r.lastEvent = 'Complaint Registered for ' + inp.subType;
        r.message = String.isNotBlank(c.CaseNumber)
            ? 'Your complaint has been registered. Case #' + c.CaseNumber + ' created.'
            : 'Your complaint has been registered.';
        r.footerNote = String.isNotBlank(c.CaseNumber)
            ? 'Case #' + c.CaseNumber + ' created. Thank you for choosing Safexpress. 😊'
            : 'Your complaint has been registered. Thank you for choosing Safexpress. 😊';
        r.agentMessage = 'Complaint registered. Case ' + (String.isNotBlank(c.CaseNumber) ? c.CaseNumber : '')
            + ' created for waybill ' + inp.formattedWaybill
            + (filesLinked > 0 ? ' with ' + filesLinked + ' proof file(s).' : '.');
        return r;
    }

    private static EscalationResult proofRequiredResult(Inputs inp) {
        EscalationResult r = baseResult(inp, OUTCOME_PROOF_REQUIRED);
        r.isError = true;
        r.proofRequired = true;
        r.headerTitle = 'Proof Required';
        r.message = 'Please upload at least one photo or PDF of the damaged goods.';
        r.footerNote = 'Please re-submit with proof attached.';
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

        // Any OPEN complaint on this waybill blocks a new one, regardless of sub type / subject
        Case findLatestOpenComplaint(Set<String> waybillVariants) {
            String soql =
                'SELECT Id, CaseNumber, Status, CreatedDate, Subject, Sub_Type__c ' +
                'FROM Case ' +
                'WHERE WaybillNo__c IN :waybills ' +
                'AND IsClosed = false ' +
                'AND (Case_Nature__c = \'Complaint\' OR Type = \'Complaint\') ' +
                'ORDER BY CreatedDate DESC ' +
                'LIMIT 1';
            List<Case> cases = Database.queryWithBinds(
                soql,
                new Map<String, Object>{ 'waybills' => waybillVariants },
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

        // Links files to the case (skips files already linked); returns number of proof files
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
    // VALIDATION (unchanged)
    // =====================================================================

    private static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) return false;
        String lowerEmail = email.toLowerCase().trim();
        if (lowerEmail == 'user@domain' || lowerEmail == 'name@company.com' || lowerEmail.contains('@test.com')) {
            return false;
        }
        return Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$').matcher(lowerEmail).matches();
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