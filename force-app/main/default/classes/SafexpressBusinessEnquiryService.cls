/**
 * @File Name   : SafexpressBusinessEnquiryService.cls
 * @Description : Business Enquiry (B2B) for the Safexpress Agentforce chat agent (replaces the
 *                "Create Business Enquiry Case" flow).
 *
 *  LWC (sfxBusinessEnquiryForm):
 *    checkPincode()   - live serviceability check, returns city / district / state
 *    checkDuplicate() - runs once pincode, mobile and email are valid
 *  Agentforce action:
 *    createBusinessEnquiry() - same order as the form:
 *        1. pincode, mobile, email valid   2. pincode serviceable   3. duplicate check
 *        4. name, designation, organisation valid   5. find / create Contact   6. create case
 *
 *  Duplicate rule: ANY Business Enquiry (B2B) case (any status - WEB enquiries are auto-completed)
 *  with the SAME mobile AND the SAME email. Pincode is ignored.
 *
 *  Contact: same mobile + email -> same mobile -> same email -> create new.
 *  Blank Email / Mobile on an existing Contact are filled; existing values are never overwritten.
 */
public without sharing class SafexpressBusinessEnquiryService {

    public static final String STATUS_CREATED          = 'CREATED';
    public static final String STATUS_DUPLICATE        = 'DUPLICATE';
    public static final String STATUS_VALIDATION_ERROR = 'VALIDATION_ERROR';
    public static final String STATUS_ERROR            = 'ERROR';

    // Case mapping - same values as the flow
    @TestVisible private static final String CASE_TYPE = 'Business Enquiry (B2B)';
    private static final String CASE_NATURE          = 'Enquiry';
    private static final String CASE_SUB_TYPE        = 'Others';
    private static final String CASE_SUBJECT         = 'Business Enquiry (B2B)';
    private static final String CASE_PRIORITY        = 'Medium';
    private static final String CASE_STATUS          = 'New';
    private static final String CASE_ORIGIN          = 'WEB';
    private static final String ENQUIRY_RECORD_TYPE  = 'Enquiry';

    private static final String MSG_PINCODE_CHECK_FAILED   = 'We could not check this pincode right now. Please try again.';
    private static final String MSG_DUPLICATE_CHECK_FAILED = 'We could not verify your details right now. Please try again.';
    private static final String MSG_SYSTEM_ERROR           = 'We could not register your enquiry right now. Please try again in a few minutes.';
    private static final String MSG_FORM_REQUIRED          = 'Please fill in the business enquiry form.';

    public static String duplicateMessage(String caseNumber) {
        return 'We already have a business enquiry registered with these details (Reference No. ' + caseNumber
            + '). Our team will contact you shortly. Thank you!';
    }

    private static String createdMessage(String fullName, String caseNumber) {
        String firstName = String.isBlank(fullName) ? '' : fullName.split(' ')[0];
        return 'Thank you, ' + firstName + '! Your business enquiry has been registered successfully. '
            + 'Your reference number is ' + caseNumber + '. Our team will contact you shortly.';
    }

    // =====================================================================
    // 1. LWC - PINCODE
    // =====================================================================
    public class PincodeResult {
        @AuraEnabled public Boolean isServiceable = false;
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
        try {
            Pincode__c rec = findPincode(pin);
            if (rec == null) {
                res.message = SafexpressBusinessEnquiryValidator.MSG_PINCODE_NOT_SERVICEABLE;
                return res;
            }
            res.isServiceable = true;
            res.city = rec.City__c;
            res.district = rec.District__c;
            res.state = rec.State__c;
        } catch (Exception ex) {
            logError('checkPincode', ex);
            res.message = MSG_PINCODE_CHECK_FAILED;
        }
        return res;
    }

    // =====================================================================
    // 2. LWC - DUPLICATE CHECK
    // =====================================================================
    public class DuplicateResult {
        @AuraEnabled public Boolean isError = false;
        @AuraEnabled public Boolean isDuplicate = false;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String message;
    }

    @AuraEnabled
    public static DuplicateResult checkDuplicate(String pincode, String mobile, String email) {
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
            }
        } catch (Exception ex) {
            logError('checkDuplicate', ex);
            res.isError = true;
            res.message = MSG_DUPLICATE_CHECK_FAILED;
        }
        return res;
    }

    // =====================================================================
    // 3. AGENTFORCE ACTION
    // =====================================================================
    public class EnquiryRequest {
        @InvocableVariable(
            label='Business Enquiry Form'
            description='Details entered by the customer in the Business Enquiry form. Always collected from the customer through the form, never filled by the agent.'
            required=true)
        public SafexpressBusinessEnquiryForm enquiryForm;
    }

    public class EnquiryResponse {
        @InvocableVariable(label='Status' description='CREATED = new business enquiry registered. DUPLICATE = a business enquiry already exists with the same mobile number and email. VALIDATION_ERROR = a detail in the form is missing or not valid. ERROR = the enquiry could not be registered.')
        public String status;
        @InvocableVariable(label='Message' description='The message to show the customer, exactly as it is.')
        public String message;
        @InvocableVariable(label='Case Number' description='Reference number of the new (CREATED) or already existing (DUPLICATE) business enquiry. Blank otherwise.')
        public String caseNumber;
        @InvocableVariable(label='Customer Name') public String customerName;
        @InvocableVariable(label='Mobile Number') public String mobileNumber;
        @InvocableVariable(label='Email Address') public String emailAddress;
        @InvocableVariable(label='Pincode') public String pincode;
        @InvocableVariable(label='City') public String city;
        @InvocableVariable(label='District') public String district;
        @InvocableVariable(label='State') public String state;
        @InvocableVariable(label='Organisation Name') public String organisationName;
        @InvocableVariable(label='Designation') public String designation;
    }

    @InvocableMethod(
        label='Create Business Enquiry'
        description='Shows the Business Enquiry form to the customer and registers the enquiry: validates every detail, blocks duplicates (same mobile number and email), finds or creates the Contact and creates the Business Enquiry (B2B) case. Returns the status, the reference number and the exact message to show the customer.')
    public static List<EnquiryResponse> createBusinessEnquiry(List<EnquiryRequest> requests) {
        // Agentforce always sends one request per call
        List<EnquiryResponse> responses = new List<EnquiryResponse>();
        for (EnquiryRequest req : requests) {
            responses.add(processEnquiry(req == null ? null : req.enquiryForm));
        }
        return responses;
    }

    private static EnquiryResponse processEnquiry(SafexpressBusinessEnquiryForm form) {
        if (form == null) {
            return fail(new EnquiryResponse(), STATUS_VALIDATION_ERROR, MSG_FORM_REQUIRED);
        }

        EnquiryData d = new EnquiryData(form);
        EnquiryResponse res = newResponse(d);

        // 1. Pincode, mobile, email
        String stepOneErr = d.stepOneError();
        if (stepOneErr != null) return fail(res, STATUS_VALIDATION_ERROR, stepOneErr);

        Savepoint sp = null;
        try {
            // 2. Pincode serviceable
            Pincode__c loc = findPincode(d.pincode);
            if (loc == null) {
                return fail(res, STATUS_VALIDATION_ERROR, SafexpressBusinessEnquiryValidator.MSG_PINCODE_NOT_SERVICEABLE);
            }
            res.city = loc.City__c;
            res.district = loc.District__c;
            res.state = loc.State__c;

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
            logError('createBusinessEnquiry', ex);
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
            'SELECT Id, CaseNumber, Status, CreatedDate FROM Case ' +
            'WHERE Case_Type__c = :caseType ' +
            'AND SuppliedPhone IN :phones ' +
            'AND SuppliedEmail = :email ' +
            'ORDER BY CreatedDate DESC LIMIT 1',
            new Map<String, Object>{ 'caseType' => CASE_TYPE, 'phones' => mobileVariants(mobile), 'email' => email },
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
            LastName = d.name,           // same as the flow
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
    // CASE (flow mapping)
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
        c.Requester_Location__c    = d.pincode;
        c.SuppliedCompany          = d.organisation;
        c.SuppliedEmail            = d.email;
        c.SuppliedPhone            = d.mobile;
        Database.insert(c, AccessLevel.SYSTEM_MODE);

        List<Case> rows = Database.queryWithBinds(
            'SELECT Id, CaseNumber FROM Case WHERE Id = :caseId LIMIT 1',
            new Map<String, Object>{ 'caseId' => c.Id },
            AccessLevel.SYSTEM_MODE
        );
        return rows.isEmpty() ? c : rows[0];
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