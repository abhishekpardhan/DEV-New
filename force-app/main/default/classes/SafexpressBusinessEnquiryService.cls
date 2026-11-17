/**
 * @File Name   : SafexpressBusinessEnquiryService.cls
 * @Description : Business Enquiry (B2B) for the Safexpress Agentforce chat agent (replaces the
 *                "Create Business Enquiry Case" flow).
 *
 *  LWC (sfxBusinessEnquiryForm):
 *    checkPincode()   - live pincode check. Any pincode with a valid format is ACCEPTED:
 *                       found in Pincode__c -> isServiceable = true + city / district / state (location card)
 *                       not found, or the lookup fails -> accepted silently (no card, no message)
 *    checkDuplicate() - runs once pincode, mobile and email are valid. Also tells the form whether the
 *                       enquiry was registered by THIS form a moment ago (isJustRegistered = created in the
 *                       last few minutes AND same name, designation and organisation), so the copy of the
 *                       form redrawn by the chat after its Submit shows the registration summary. An
 *                       enquiry found by the duplicate check (details hidden, so empty) keeps the banner.
 *    submitEnquiry()  - the form's own "Submit Request" button, same order as the flow:
 *        1. pincode, mobile, email valid   2. pincode location (if listed)   3. duplicate check
 *        4. name, designation, organisation valid   5. find / create Contact   6. create case
 *  Agentforce action (chat "Submit" button):
 *    createBusinessEnquiry() - CONFIRMS what the form registered. It never creates a case.
 *        CREATED             - the form registered the enquiry a moment ago (same details)
 *        DUPLICATE           - the form found an enquiry that was already registered (banner)
 *        FORM_INCOMPLETE     - the customer clicked the chat Submit before completing the form
 *        ERROR               - the confirmation could not be read
 *
 *  Duplicate rule: ANY Business Enquiry (B2B) case (any status - WEB enquiries are auto-completed)
 *  with the SAME mobile AND the SAME email. Pincode is ignored.
 *
 *  Contact: same mobile + email -> same mobile -> same email -> create new.
 *  Blank Email / Mobile on an existing Contact are filled; existing values are never overwritten.
 *
 *  Owner: the service agent user (CASE_OWNER_USERNAME). If that user is not found or inactive,
 *  the case keeps the default owner.
 */
public without sharing class SafexpressBusinessEnquiryService {

    public static final String STATUS_CREATED          = 'CREATED';
    public static final String STATUS_DUPLICATE        = 'DUPLICATE';
    public static final String STATUS_VALIDATION_ERROR = 'VALIDATION_ERROR';
    public static final String STATUS_FORM_INCOMPLETE  = 'FORM_INCOMPLETE';
    public static final String STATUS_ERROR            = 'ERROR';

    // Case mapping - same values as the flow
    @TestVisible private static final String CASE_TYPE = 'Business Enquiry (B2B)';
    private static final String CASE_NATURE          = 'Enquiry';
    private static final String CASE_SUB_TYPE        = 'Others';
    private static final String CASE_SUBJECT         = 'Business Enquiry (B2B)';
    private static final String CASE_PRIORITY        = 'Medium';
    private static final String CASE_STATUS          = 'New';
    @TestVisible private static final String CASE_ORIGIN = 'WEB';
    private static final String ENQUIRY_RECORD_TYPE  = 'Enquiry';

    // Service agent user who owns new business enquiries (Setup > Users > Username)
    @TestVisible private static final String CASE_OWNER_USERNAME = 'sfdc.admin.dev@safexpress.com';

    // A registration made by the form in the last few minutes counts as "just registered":
    // the chat Submit confirms it as CREATED and the redrawn form copy shows its summary
    private static final Integer RECENT_REGISTRATION_MINUTES = 15;

    private static final String MSG_DUPLICATE_CHECK_FAILED = 'We could not verify your details right now. Please try again.';
    private static final String MSG_SYSTEM_ERROR           = 'We could not register your enquiry right now. Please try again in a few minutes.';
    private static final String MSG_FORM_REQUIRED          = 'Please fill in the business enquiry form.';
    public static final String MSG_FORM_INCOMPLETE =
        'Please fill out the secure form displayed to submit your business enquiry request. '
        + 'Once you complete the form, I will update you with your case reference number and next steps.'
        + '\n\nDo you need any help with the form or have other questions?';

    public static String duplicateMessage(String caseNumber) {
        return 'We already have a business enquiry registered with these details (Reference No. ' + caseNumber
            + '). Our team will contact you shortly. Thank you!';
    }

    // Chat reply when the customer clicks the chat Submit on the "Enquiry already registered" banner
    public static String chatDuplicateMessage(String caseNumber) {
        return 'Your business enquiry is already registered with us (Reference No. ' + caseNumber
            + '). Our team is already working on it and will contact you shortly. Thank you!';
    }

    private static String createdMessage(String fullName, String caseNumber) {
        String firstName = String.isBlank(fullName) ? '' : fullName.trim().split(' ')[0];
        String greeting = String.isBlank(firstName) ? 'Thank you! ' : 'Thank you, ' + firstName + '! ';
        return greeting + 'Your business enquiry has been registered successfully. '
            + 'Your reference number is ' + caseNumber + '. Our team will contact you shortly.';
    }

    // =====================================================================
    // 1. LWC - PINCODE
    // =====================================================================
    public class PincodeResult {
        @AuraEnabled public Boolean isAccepted = false;     // valid format -> the form accepts the pincode
        @AuraEnabled public Boolean isServiceable = false;  // found in Pincode__c -> show the location card
        @AuraEnabled public String message;
        @AuraEnabled public String pincode;
        @AuraEnabled public String city;
        @AuraEnabled public String district;
        @AuraEnabled public String state;
    }

    @AuraEnabled
    public static PincodeResult checkPincode(String pincode) {
        PincodeResult res = new PincodeResult();
        String pin = pincode == null ? '' : pincode.trim();
        res.pincode = pin;

        String err = SafexpressBusinessEnquiryValidator.pincodeError(pin);
        if (err != null) {
            res.message = err;
            return res;
        }
        // Valid format: always accepted. A pincode not in Pincode__c (or a failed lookup) is accepted
        // silently - no location card and no message.
        res.isAccepted = true;
        try {
            Pincode__c rec = findPincode(pin);
            if (rec != null) {
                res.isServiceable = true;
                res.city = rec.City__c;
                res.district = rec.District__c;
                res.state = rec.State__c;
            }
        } catch (Exception ex) {
            logError('checkPincode', ex);
        }
        return res;
    }

    // =====================================================================
    // 2. LWC - DUPLICATE CHECK
    // =====================================================================
    public class DuplicateResult {
        @AuraEnabled public Boolean isError = false;
        @AuraEnabled public Boolean isDuplicate = false;
        @AuraEnabled public Boolean isRecent = false;          // registered in the last RECENT_REGISTRATION_MINUTES
        @AuraEnabled public Boolean isJustRegistered = false;  // recent AND same name, designation, organisation
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String message;
    }

    // fullName, designation and organisationName are optional: the form sends what it shows
    @AuraEnabled
    public static DuplicateResult checkDuplicate(
        String pincode, String mobile, String email,
        String fullName, String designation, String organisationName
    ) {
        DuplicateResult res = new DuplicateResult();
        String m = SafexpressBusinessEnquiryValidator.normaliseMobile(mobile);
        String e = SafexpressBusinessEnquiryValidator.normaliseEmail(email);

        String err = SafexpressBusinessEnquiryValidator.firstError(new List<String>{
            SafexpressBusinessEnquiryValidator.pincodeError(pincode),
            SafexpressBusinessEnquiryValidator.mobileError(m),
            SafexpressBusinessEnquiryValidator.emailError(e)
        });
        if (err != null) {
            res.isError = true;
            res.message = err;
            return res;
        }
        try {
            Case existing = findExistingEnquiry(m, e);
            if (existing != null) {
                res.isDuplicate = true;
                res.caseNumber = existing.CaseNumber;
                res.message = duplicateMessage(existing.CaseNumber);
                // Same rule as the chat Submit confirmation (CREATED vs DUPLICATE)
                res.isRecent = isRecent(existing);
                res.isJustRegistered = res.isRecent
                    && matchesDetails(existing, fullName, designation, organisationName);
            }
        } catch (Exception ex) {
            logError('checkDuplicate', ex);
            res.isError = true;
            res.message = MSG_DUPLICATE_CHECK_FAILED;
        }
        return res;
    }

    // =====================================================================
    // 3. LWC - "SUBMIT REQUEST" BUTTON (registers the enquiry)
    // =====================================================================
    @AuraEnabled
    public static EnquiryResponse submitEnquiry(
        String pincode, String mobileNumber, String emailAddress,
        String fullName, String designation, String organisationName, String messagingSessionId
    ) {
        SafexpressBusinessEnquiryForm f = new SafexpressBusinessEnquiryForm();
        f.pincode = pincode;
        f.mobileNumber = mobileNumber;
        f.emailAddress = emailAddress;
        f.fullName = fullName;
        f.designation = designation;
        f.organisationName = organisationName;
        f.messagingSessionId = messagingSessionId;
        return processEnquiry(f);
    }

    // =====================================================================
    // 4. AGENTFORCE ACTION (chat "Submit" button) - confirms, never creates
    // =====================================================================
    public class EnquiryRequest {
        @InvocableVariable(
            label='Business Enquiry Form'
            description='The Business Enquiry form exactly as the customer submitted it with the chat Submit button. Always collected from the customer through the form, never filled by the agent.'
            required=true)
        public SafexpressBusinessEnquiryForm enquiryForm;
    }

    public class EnquiryResponse {
        @InvocableVariable(label='Status' description='CREATED = the form registered a new business enquiry. DUPLICATE = a business enquiry already exists with the same mobile number and email. FORM_INCOMPLETE = the customer clicked the chat Submit before completing the form with its Submit Request button. VALIDATION_ERROR = a detail is missing or not valid (form only). ERROR = the request could not be processed.')
        @AuraEnabled public String status;
        @InvocableVariable(label='Message' description='The message to show the customer, exactly as it is.')
        @AuraEnabled public String message;
        @InvocableVariable(label='Case Number' description='Reference number of the new (CREATED) or already existing (DUPLICATE) business enquiry. Blank otherwise.')
        @AuraEnabled public String caseNumber;
        @InvocableVariable(label='Customer Name') @AuraEnabled public String customerName;
        @InvocableVariable(label='Mobile Number') @AuraEnabled public String mobileNumber;
        @InvocableVariable(label='Email Address') @AuraEnabled public String emailAddress;
        @InvocableVariable(label='Pincode') @AuraEnabled public String pincode;
        @InvocableVariable(label='City') @AuraEnabled public String city;
        @InvocableVariable(label='District') @AuraEnabled public String district;
        @InvocableVariable(label='State') @AuraEnabled public String state;
        @InvocableVariable(label='Organisation Name') @AuraEnabled public String organisationName;
        @InvocableVariable(label='Designation') @AuraEnabled public String designation;
    }

    @InvocableMethod(
        label='Create Business Enquiry'
        description='Shows the customer the Business Enquiry form. The customer registers the enquiry inside the form with its Submit Request button; when the customer then clicks the chat Submit button, this action confirms the registration and returns the status, the reference number and the exact message to show the customer. It never creates a case itself.')
    public static List<EnquiryResponse> createBusinessEnquiry(List<EnquiryRequest> requests) {
        List<EnquiryResponse> responses = new List<EnquiryResponse>();
        for (EnquiryRequest req : requests) {
            responses.add(confirmSubmission(req == null ? null : req.enquiryForm));
        }
        return responses;
    }

    // Chat "Submit": finds what the form registered, by the same mobile + email
    private static EnquiryResponse confirmSubmission(SafexpressBusinessEnquiryForm form) {
        if (form == null) {
            return fail(new EnquiryResponse(), STATUS_FORM_INCOMPLETE, MSG_FORM_INCOMPLETE);
        }
        EnquiryData d = new EnquiryData(form);
        EnquiryResponse res = newResponse(d);
        if (d.stepOneError() != null) {
            return fail(res, STATUS_FORM_INCOMPLETE, MSG_FORM_INCOMPLETE);
        }
        try {
            // 1. Registered by THIS form's Submit Request a moment ago: recent AND the submitted
            //    name, designation and organisation are the ones saved on the case
            Case recent = findRecentEnquiry(d.mobile, d.email);
            if (recent != null && matchesDetails(recent, d.name, d.designation, d.organisation)) {
                return confirmed(res, recent, false);
            }

            // 2. Found by the duplicate check (the form showed the "already registered" banner,
            //    details hidden): nothing new was created - however recent the existing case is
            Case existing = findExistingEnquiry(d.mobile, d.email);
            if (existing != null) return confirmed(res, existing, true);
        } catch (Exception ex) {
            logError('createBusinessEnquiry', ex);
            return fail(res, STATUS_ERROR, MSG_SYSTEM_ERROR);
        }
        // 3. Nothing registered yet: ask the customer to complete the form (it stays on screen)
        return fail(res, STATUS_FORM_INCOMPLETE, MSG_FORM_INCOMPLETE);
    }

    private static EnquiryResponse confirmed(EnquiryResponse res, Case c, Boolean duplicate) {
        res.status = duplicate ? STATUS_DUPLICATE : STATUS_CREATED;
        res.caseNumber = c.CaseNumber;
        String name = String.isNotBlank(res.customerName) ? res.customerName : c.Requester_Name__c;
        res.message = duplicate ? chatDuplicateMessage(c.CaseNumber) : createdMessage(name, c.CaseNumber);
        return res;
    }

    // =====================================================================
    // REGISTRATION (used by submitEnquiry)
    // =====================================================================
    private static EnquiryResponse processEnquiry(SafexpressBusinessEnquiryForm form) {
        if (form == null) {
            return fail(new EnquiryResponse(), STATUS_VALIDATION_ERROR, MSG_FORM_REQUIRED);
        }

        EnquiryData d = new EnquiryData(form);
        EnquiryResponse res = newResponse(d);

        // 1. Pincode, mobile, email
        String stepOneErr = d.stepOneError();
        if (stepOneErr != null) return fail(res, STATUS_VALIDATION_ERROR, stepOneErr);

        // 2. Pincode location: filled when the pincode is in Pincode__c. A pincode that is not listed
        //    (or a failed lookup) is accepted - the enquiry continues without City / District / State.
        try {
            Pincode__c loc = findPincode(d.pincode);
            if (loc != null) {
                res.city = loc.City__c;
                res.district = loc.District__c;
                res.state = loc.State__c;
            }
        } catch (Exception ex) {
            logError('submitEnquiry.pincodeLookup', ex);
        }

        Savepoint sp = null;
        try {

            // 3. Duplicate (any status)
            Case existing = findExistingEnquiry(d.mobile, d.email);
            if (existing != null) {
                res.status = STATUS_DUPLICATE;
                res.caseNumber = existing.CaseNumber;
                res.message = duplicateMessage(existing.CaseNumber);
                return res;
            }

            // 4. Name, designation, organisation
            String detailsErr = d.detailsError();
            if (detailsErr != null) return fail(res, STATUS_VALIDATION_ERROR, detailsErr);

            // 5 + 6. Contact and case
            sp = Database.setSavepoint();
            Id contactId = findOrCreateContact(d);
            Case created = insertEnquiryCase(d, contactId);
            linkSessionToCase(d.messagingSessionId, created.Id);

            res.status = STATUS_CREATED;
            res.caseNumber = created.CaseNumber;
            res.message = createdMessage(d.name, created.CaseNumber);
            return res;

        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            logError('submitEnquiry', ex);
            return fail(res, STATUS_ERROR, MSG_SYSTEM_ERROR);
        }
    }

    // =====================================================================
    // DATA
    // =====================================================================
    private class EnquiryData {
        String pincode;
        String mobile;
        String email;
        String name;
        String designation;
        String organisation;
        String messagingSessionId;

        EnquiryData(SafexpressBusinessEnquiryForm f) {
            pincode            = SafexpressBusinessEnquiryValidator.normaliseText(f.pincode);
            mobile             = SafexpressBusinessEnquiryValidator.normaliseMobile(f.mobileNumber);
            email              = SafexpressBusinessEnquiryValidator.normaliseEmail(f.emailAddress);
            name               = SafexpressBusinessEnquiryValidator.normaliseText(f.fullName);
            designation        = SafexpressBusinessEnquiryValidator.normaliseText(f.designation);
            organisation       = SafexpressBusinessEnquiryValidator.normaliseText(f.organisationName);
            messagingSessionId = f.messagingSessionId;
        }

        String stepOneError() {
            return SafexpressBusinessEnquiryValidator.firstError(new List<String>{
                SafexpressBusinessEnquiryValidator.pincodeError(pincode),
                SafexpressBusinessEnquiryValidator.mobileError(mobile),
                SafexpressBusinessEnquiryValidator.emailError(email)
            });
        }

        String detailsError() {
            return SafexpressBusinessEnquiryValidator.firstError(new List<String>{
                SafexpressBusinessEnquiryValidator.nameError(name),
                SafexpressBusinessEnquiryValidator.designationError(designation),
                SafexpressBusinessEnquiryValidator.organisationError(organisation)
            });
        }
    }

    private static EnquiryResponse newResponse(EnquiryData d) {
        EnquiryResponse r = new EnquiryResponse();
        r.customerName = d.name;
        r.mobileNumber = d.mobile;
        r.emailAddress = d.email;
        r.pincode = d.pincode;
        r.organisationName = d.organisation;
        r.designation = d.designation;
        return r;
    }

    private static EnquiryResponse fail(EnquiryResponse res, String status, String message) {
        res.status = status;
        res.message = message;
        return res;
    }

    private static Boolean isRecent(Case c) {
        return c != null && c.CreatedDate != null
            && c.CreatedDate >= Datetime.now().addMinutes(-RECENT_REGISTRATION_MINUTES);
    }

    // True when the submitted name, designation and organisation are the ones saved on the case,
    // i.e. this form registered it. On the duplicate banner these fields are hidden (empty), so false.
    private static Boolean matchesDetails(Case c, String name, String designation, String organisation) {
        return sameText(name, c.Requester_Name__c)
            && sameText(designation, c.Requester_Designation__c)
            && sameText(organisation, c.SuppliedCompany);
    }

    private static Boolean sameText(String submitted, String saved) {
        String a = submitted == null ? '' : SafexpressBusinessEnquiryValidator.normaliseText(submitted);
        String b = saved == null ? '' : SafexpressBusinessEnquiryValidator.normaliseText(saved);
        a = a == null ? '' : a;
        b = b == null ? '' : b;
        return String.isNotBlank(a) && a.equalsIgnoreCase(b);
    }

    // Older records may store the mobile as +91..., 91..., 0...
    private static Set<String> mobileVariants(String mobile) {
        return new Set<String>{ mobile, '+91' + mobile, '91' + mobile, '0' + mobile, '+91 ' + mobile, '+91-' + mobile };
    }

    private static Pincode__c findPincode(String pin) {
        List<Pincode__c> rows = Database.queryWithBinds(
            'SELECT Pincode__c, City__c, District__c, State__c FROM Pincode__c WHERE Pincode__c = :pin LIMIT 1',
            new Map<String, Object>{ 'pin' => pin },
            AccessLevel.SYSTEM_MODE
        );
        return rows.isEmpty() ? null : rows[0];
    }

    // Same mobile AND same email, any status (email comparison is case-insensitive in SOQL)
    private static Case findExistingEnquiry(String mobile, String email) {
        List<Case> rows = Database.queryWithBinds(
            'SELECT Id, CaseNumber, Status, CreatedDate, Requester_Name__c, Requester_Designation__c, SuppliedCompany FROM Case ' +
            'WHERE Case_Type__c = :caseType ' +
            'AND SuppliedPhone IN :phones ' +
            'AND SuppliedEmail = :email ' +
            'ORDER BY CreatedDate DESC LIMIT 1',
            new Map<String, Object>{ 'caseType' => CASE_TYPE, 'phones' => mobileVariants(mobile), 'email' => email },
            AccessLevel.SYSTEM_MODE
        );
        return rows.isEmpty() ? null : rows[0];
    }

    // Same mobile AND same email, created in the last few minutes
    private static Case findRecentEnquiry(String mobile, String email) {
        List<Case> rows = Database.queryWithBinds(
            'SELECT Id, CaseNumber, SuppliedEmail, CreatedDate, Requester_Name__c, Requester_Designation__c, SuppliedCompany FROM Case ' +
            'WHERE Case_Type__c = :caseType ' +
            'AND SuppliedPhone IN :phones ' +
            'AND SuppliedEmail = :email ' +
            'AND CreatedDate >= :since ' +
            'ORDER BY CreatedDate DESC LIMIT 1',
            new Map<String, Object>{
                'caseType' => CASE_TYPE,
                'phones' => mobileVariants(mobile),
                'email' => email,
                'since' => Datetime.now().addMinutes(-RECENT_REGISTRATION_MINUTES)
            },
            AccessLevel.SYSTEM_MODE
        );
        return rows.isEmpty() ? null : rows[0];
    }

    // =====================================================================
    // CONTACT: reuse first, create only when nothing matches
    // =====================================================================
    private static Id findOrCreateContact(EnquiryData d) {
        Set<String> phones = mobileVariants(d.mobile);
        List<Contact> candidates = Database.queryWithBinds(
            'SELECT Id, MobilePhone, Email FROM Contact ' +
            'WHERE MobilePhone IN :phones OR Email = :email ' +
            'ORDER BY CreatedDate ASC LIMIT 50',
            new Map<String, Object>{ 'phones' => phones, 'email' => d.email },
            AccessLevel.SYSTEM_MODE
        );

        Contact byBoth;
        Contact byMobile;
        Contact byEmail;
        for (Contact c : candidates) {
            Boolean mobileMatch = c.MobilePhone != null && phones.contains(c.MobilePhone);
            Boolean emailMatch = String.isNotBlank(c.Email) && c.Email.equalsIgnoreCase(d.email);
            if (mobileMatch && emailMatch && byBoth == null) byBoth = c;
            if (mobileMatch && byMobile == null) byMobile = c;
            if (emailMatch && byEmail == null) byEmail = c;
        }
        Contact match = byBoth != null ? byBoth : (byMobile != null ? byMobile : byEmail);

        if (match != null) {
            fillBlankDetails(match, d);
            return match.Id;
        }

        Contact newContact = new Contact(
            LastName = d.name,           
            MobilePhone = d.mobile,
            Email = d.email
        );
        Database.SaveResult sr = Database.insert(newContact, dmlOptions(), AccessLevel.SYSTEM_MODE);
        if (sr.isSuccess()) return sr.getId();

        // A Duplicate Rule blocked the insert -> tag the Contact the rule matched
        Id matchedId = contactFromDuplicateRule(sr.getErrors());
        if (matchedId != null) return matchedId;

        // Any other failure (e.g. a validation rule): keep the enquiry, log the problem
        logDmlErrors('findOrCreateContact.insert', sr.getErrors());
        return null;
    }

    // Fills only empty fields - never overwrites existing values
    private static void fillBlankDetails(Contact c, EnquiryData d) {
        Boolean changed = false;
        if (String.isBlank(c.Email)) {
            c.Email = d.email;
            changed = true;
        }
        if (String.isBlank(c.MobilePhone)) {
            c.MobilePhone = d.mobile;
            changed = true;
        }
        if (!changed) return;
        Database.SaveResult sr = Database.update(c, dmlOptions(), AccessLevel.SYSTEM_MODE);
        if (!sr.isSuccess()) logDmlErrors('fillBlankDetails', sr.getErrors());
    }

    private static Id contactFromDuplicateRule(List<Database.Error> errors) {
        for (Database.Error err : errors) {
            if (!(err instanceof Database.DuplicateError)) continue;
            Datacloud.DuplicateResult dup = ((Database.DuplicateError) err).getDuplicateResult();
            for (Datacloud.MatchResult mr : dup.getMatchResults()) {
                for (Datacloud.MatchRecord rec : mr.getMatchRecords()) {
                    SObject matched = rec.getRecord();
                    if (matched != null && matched.getSObjectType() == Contact.SObjectType) {
                        return matched.Id;
                    }
                }
            }
        }
        return null;
    }

    private static Database.DMLOptions dmlOptions() {
        Database.DMLOptions opts = new Database.DMLOptions();
        opts.DuplicateRuleHeader.allowSave = true;   // "alert" rules don't stop the save
        opts.OptAllOrNone = false;                   // return errors instead of throwing
        return opts;
    }

    // =====================================================================
    // CASE (flow mapping - identical to the reference class) + owner
    // =====================================================================
    private static Case insertEnquiryCase(EnquiryData d, Id contactId) {
        Case c = new Case();
        Id rtId = enquiryRecordTypeId();
        if (rtId != null) c.RecordTypeId = rtId;
        c.Case_Nature__c           = CASE_NATURE;
        c.Case_Type__c             = CASE_TYPE;
        c.Sub_Type__c              = CASE_SUB_TYPE;
        c.Subject                  = CASE_SUBJECT;
        c.Priority                 = CASE_PRIORITY;
        c.Status                   = CASE_STATUS;
        c.Origin                   = CASE_ORIGIN;
        c.ContactId                = contactId;
        c.Requester_Name__c        = d.name;
        c.Requester_Designation__c = d.designation;
        c.Supplied_Pincode__c    = d.pincode;
        c.SuppliedCompany          = d.organisation;
        c.SuppliedEmail            = d.email;
        c.SuppliedPhone            = d.mobile;

        // Owner: the service agent user (default owner if the user is not found)
        Id ownerId = caseOwnerId();
        if (ownerId != null) c.OwnerId = ownerId;
        Database.insert(c, AccessLevel.SYSTEM_MODE);

        List<Case> rows = Database.queryWithBinds(
            'SELECT Id, CaseNumber FROM Case WHERE Id = :caseId LIMIT 1',
            new Map<String, Object>{ 'caseId' => c.Id },
            AccessLevel.SYSTEM_MODE
        );
        return rows.isEmpty() ? c : rows[0];
    }

    @TestVisible
    private static Id caseOwnerId() {
        List<User> users = Database.queryWithBinds(
            'SELECT Id FROM User WHERE Username = :username AND IsActive = true LIMIT 1',
            new Map<String, Object>{ 'username' => CASE_OWNER_USERNAME },
            AccessLevel.SYSTEM_MODE
        );
        return users.isEmpty() ? null : users[0].Id;
    }

    private static Id enquiryRecordTypeId() {
        Schema.RecordTypeInfo info = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ENQUIRY_RECORD_TYPE);
        return (info != null && info.isActive()) ? info.getRecordTypeId() : null;
    }

    // Best effort: shows the case on the Messaging Session. Never fails the enquiry.
    private static void linkSessionToCase(String messagingSessionId, Id caseId) {
        if (String.isBlank(messagingSessionId)) return;
        try {
            Id sessionId = Id.valueOf(messagingSessionId.trim());
            if (sessionId.getSObjectType() != MessagingSession.SObjectType) return;
            List<MessagingSession> sessions = Database.queryWithBinds(
                'SELECT Id, CaseId FROM MessagingSession WHERE Id = :sessionId LIMIT 1',
                new Map<String, Object>{ 'sessionId' => sessionId },
                AccessLevel.SYSTEM_MODE
            );
            if (sessions.isEmpty() || sessions[0].CaseId != null) return;
            sessions[0].CaseId = caseId;
            Database.update(sessions, false, AccessLevel.SYSTEM_MODE);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'linkSessionToCase skipped: ' + e.getMessage());
        }
    }

    // =====================================================================
    // LOGGING (never throws)
    // =====================================================================
    private static void logError(String method, Exception ex) {
        System.debug(LoggingLevel.ERROR, 'SafexpressBusinessEnquiryService.' + method + ' :: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
        try {
            LoggerUtil.createErrorLog('SafexpressBusinessEnquiryService', method, ex.getTypeName(), ex.getMessage(), ex.getStackTraceString(), null);
        } catch (Exception ignore) {
            System.debug(LoggingLevel.ERROR, 'LoggerUtil failed: ' + ignore.getMessage());
        }
    }

    private static void logDmlErrors(String method, List<Database.Error> errors) {
        List<String> msgs = new List<String>();
        for (Database.Error e : errors) msgs.add(e.getStatusCode() + ': ' + e.getMessage());
        String text = String.join(msgs, ' | ');
        System.debug(LoggingLevel.ERROR, 'SafexpressBusinessEnquiryService.' + method + ' :: ' + text);
        try {
            LoggerUtil.createErrorLog('SafexpressBusinessEnquiryService', method, 'DmlError', text, '', null);
        } catch (Exception ignore) {
            System.debug(LoggingLevel.ERROR, 'LoggerUtil failed: ' + ignore.getMessage());
        }
    }
}