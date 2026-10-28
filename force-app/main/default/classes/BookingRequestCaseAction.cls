/**
 * Agent action "Create_Booking_Request_Case".
 * Re-validates, finds/creates the Contact by mobile, creates the Booking Request case,
 * links the messaging session. Mapping follows the flow "Create Booking Request From ChatBot".
 * varStatus: SUCCESS | INVALID_DATA | NOT_SERVICEABLE | ERROR
 */
public with sharing class BookingRequestCaseAction {

    @TestVisible static final String CASE_NATURE = 'Request';
    @TestVisible static final String CASE_TYPE = 'Booking Request';
    @TestVisible static final String SUB_TYPE = 'Retail-Non-PRC';
    @TestVisible static final String BOOKING_CHANNEL = 'WEB';
    @TestVisible static final String CASE_ORIGIN = 'WEB';
    static final Boolean USE_DEFAULT_ASSIGNMENT_RULE = false;

    public class Request {
        @InvocableVariable(label='varName' required=true) public String varName;
        @InvocableVariable(label='varPhone' required=true) public String varPhone;
        @InvocableVariable(label='varEmail' required=true) public String varEmail;
        @InvocableVariable(label='varPickupPincode' required=true) public String varPickupPincode;
        @InvocableVariable(label='varDeliveryPincode' required=true) public String varDeliveryPincode;
        @InvocableVariable(label='varPickupAddress' required=true) public String varPickupAddress;
        @InvocableVariable(label='varApproxWeight' required=true) public String varApproxWeight;
        @InvocableVariable(label='varPackageCount' required=true) public String varPackageCount;
        @InvocableVariable(label='varContactId' description='Optional. Linked Contact Id.')
        public String varContactId;
        @InvocableVariable(label='varMessagingSessionId' description='Optional. Messaging session Id.')
        public String varMessagingSessionId;
    }

    public class Response {
        @InvocableVariable(label='varCaseNumber') public String varCaseNumber;
        @InvocableVariable(label='varStatus') public String varStatus;
    }

    private class Booking {
        String name;
        String phone;
        String email;
        String pickupPin;
        String deliveryPin;
        String address;
        String contactId;
        String sessionId;
        Decimal weight;
        Integer packages;
        Boolean valid = true;
    }

    @InvocableMethod(
        label='Create Booking Request Case'
        description='Creates a Booking Request support case from validated booking details and returns the case number.'
    )
    public static List<Response> create(List<Request> requests) {
        List<Response> responses = new List<Response>();
        List<Booking> bookings = new List<Booking>();
        Set<String> pins = new Set<String>();

        // 1. Validate again on the server.
        for (Request req : requests) {
            Booking b = toBooking(req);
            bookings.add(b);
            Response res = new Response();
            res.varStatus = b.valid ? 'SUCCESS' : 'INVALID_DATA';
            responses.add(res);
            if (b.valid) {
                pins.add(b.pickupPin);
                pins.add(b.deliveryPin);
            }
        }

        // 2. Both pincodes must still be serviceable.
        Map<String, PincodeLookupService.PincodeResult> pinResults = PincodeLookupService.checkAll(pins);
        for (Integer i = 0; i < bookings.size(); i++) {
            Booking b = bookings[i];
            if (!b.valid) continue;
            String pickup = pinResults.get(b.pickupPin).status;
            String delivery = pinResults.get(b.deliveryPin).status;
            if (pickup == 'ERROR' || delivery == 'ERROR') {
                b.valid = false;
                responses[i].varStatus = 'ERROR';
            } else if (pickup != 'SERVICEABLE' || delivery != 'SERVICEABLE') {
                b.valid = false;
                responses[i].varStatus = 'NOT_SERVICEABLE';
            }
        }

        // 3. Contact, then Case.
        try {
            resolveContacts(bookings);
            insertCases(bookings, responses);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '##BOOKING EXCEPTION## ' + e.getMessage() + ' | ' + e.getStackTraceString());
            for (Integer i = 0; i < bookings.size(); i++) {
                if (responses[i].varStatus == 'SUCCESS' && String.isBlank(responses[i].varCaseNumber)) {
                    responses[i].varStatus = 'ERROR';
                }
            }
        }
        return responses;
    }

    private static Booking toBooking(Request req) {
        Booking b = new Booking();
        BookingRequestValidator.FieldResult name = BookingRequestValidator.validateName(req.varName);
        BookingRequestValidator.FieldResult phone = BookingRequestValidator.validatePhone(req.varPhone);
        BookingRequestValidator.FieldResult email = BookingRequestValidator.validateEmail(req.varEmail);
        BookingRequestValidator.FieldResult pickup = BookingRequestValidator.validatePincodeFormat(req.varPickupPincode);
        BookingRequestValidator.FieldResult delivery = BookingRequestValidator.validatePincodeFormat(req.varDeliveryPincode);
        BookingRequestValidator.FieldResult address = BookingRequestValidator.validateAddress(req.varPickupAddress);
        BookingRequestValidator.FieldResult weight = BookingRequestValidator.validateWeight(req.varApproxWeight);
        BookingRequestValidator.FieldResult packages = BookingRequestValidator.validatePackages(req.varPackageCount);

        b.valid = name.valid && phone.valid && email.valid && pickup.valid && delivery.valid
            && address.valid && weight.valid && packages.valid
            && BookingRequestValidator.validateWeightPerPackage(weight.value, packages.value).valid;
        if (!b.valid) return b;

        b.name = name.value;
        b.phone = phone.value;
        b.email = email.value;
        b.pickupPin = pickup.value;
        b.deliveryPin = delivery.value;
        b.address = address.value;
        b.weight = Decimal.valueOf(weight.value).setScale(2);
        b.packages = Integer.valueOf(packages.value);
        b.contactId = isIdOf(req.varContactId, Contact.SObjectType) ? req.varContactId : null;
        b.sessionId = isIdOf(req.varMessagingSessionId, MessagingSession.SObjectType) ? req.varMessagingSessionId : null;
        return b;
    }

    /**
     * Uses the linked Contact, else an existing Contact with the same mobile, else creates one.
     * If a duplicate rule blocks the new Contact, the Contact it matched is reused.
     * A Contact problem never fails the booking: the Case is still created.
     */
    private static void resolveContacts(List<Booking> bookings) {
        Set<String> variants = new Set<String>();
        for (Booking b : bookings) {
            if (b.valid && b.contactId == null) variants.addAll(phoneVariants(b.phone));
        }
        if (variants.isEmpty()) return;

        // 1. Existing Contact with the same mobile (stored with or without +91 / 91 / 0, in Mobile or Phone).
        Map<String, Id> contactByPhone = new Map<String, Id>();
        for (Contact c : [
            SELECT Id, MobilePhone, Phone FROM Contact
            WHERE MobilePhone IN :variants OR Phone IN :variants
            ORDER BY CreatedDate ASC
        ]) {
            for (String p : new List<String>{ c.MobilePhone, c.Phone }) {
                BookingRequestValidator.FieldResult n = BookingRequestValidator.validatePhone(p);
                if (n.valid && !contactByPhone.containsKey(n.value)) contactByPhone.put(n.value, c.Id);
            }
        }

        // 2. Create the missing ones (one per mobile number).
        List<Contact> toCreate = new List<Contact>();
        Set<String> queued = new Set<String>();
        for (Booking b : bookings) {
            if (!b.valid || b.contactId != null) continue;
            if (contactByPhone.containsKey(b.phone)) {
                b.contactId = contactByPhone.get(b.phone);
            } else if (!queued.contains(b.phone)) {
                // Same as the flow: the full name goes into LastName.
                toCreate.add(new Contact(LastName = b.name, Email = b.email, MobilePhone = b.phone));
                queued.add(b.phone);
            }
        }
        if (toCreate.isEmpty()) return;

        Map<String, Id> resolved = new Map<String, Id>();
        Database.SaveResult[] results = Database.insert(toCreate, false);
        for (Integer i = 0; i < toCreate.size(); i++) {
            String phone = toCreate[i].MobilePhone;
            if (results[i].isSuccess()) {
                resolved.put(phone, results[i].getId());
                continue;
            }
            Id matched = duplicateMatch(results[i]);
            if (matched != null) {
                resolved.put(phone, matched);   // duplicate rule found an existing Contact: reuse it
            } else {
                System.debug(LoggingLevel.ERROR, '##BOOKING CONTACT FAILED## ' + results[i].getErrors());
            }
        }
        for (Booking b : bookings) {
            if (b.valid && b.contactId == null && resolved.containsKey(b.phone)) {
                b.contactId = resolved.get(b.phone);
            }
            // If still null, the Case is created without ContactId; it is not treated as an error.
        }
    }

    /** Returns the Id of the record a duplicate rule matched, if the insert was blocked as a duplicate. */
    private static Id duplicateMatch(Database.SaveResult sr) {
        for (Database.Error err : sr.getErrors()) {
            if (err instanceof Database.DuplicateError) {
                Datacloud.DuplicateResult dup = ((Database.DuplicateError) err).getDuplicateResult();
                for (Datacloud.MatchResult mr : dup.getMatchResults()) {
                    for (Datacloud.MatchRecord rec : mr.getMatchRecords()) {
                        if (rec.getRecord() != null && rec.getRecord().Id != null) {
                            return rec.getRecord().Id;
                        }
                    }
                }
            }
        }
        return null;
    }

    private static Set<String> phoneVariants(String phone) {
        return new Set<String>{ phone, '+91' + phone, '+91 ' + phone, '91' + phone, '0' + phone };
    }

    private static void insertCases(List<Booking> bookings, List<Response> responses) {
        List<Case> cases = new List<Case>();
        List<Integer> caseFor = new List<Integer>();
        for (Integer i = 0; i < bookings.size(); i++) {
            Booking b = bookings[i];
            if (!b.valid) continue;
            cases.add(new Case(
                ContactId = b.contactId,
                Origin = CASE_ORIGIN,
                Booking_Channel__c = BOOKING_CHANNEL,
                Case_Nature__c = CASE_NATURE,
                Case_Type__c = CASE_TYPE,
                Sub_Type__c = SUB_TYPE,
                Consignor_Address_Line_1__c = b.address,
                Consignor_Email__c = b.email,
                Consignor_Phone__c = b.phone,
                Origin_Pincode__c = b.pickupPin,
                Destination_PinCode__c = b.deliveryPin,
                Total_Weight__c = b.weight,
                Total_Package_Count__c = b.packages
            ));
            caseFor.add(i);
        }
        if (cases.isEmpty()) return;

        Database.DMLOptions options = new Database.DMLOptions();
        options.optAllOrNone = false;
        options.assignmentRuleHeader.useDefaultRule = USE_DEFAULT_ASSIGNMENT_RULE;
        Database.SaveResult[] results = Database.insert(cases, options);

        Set<Id> createdIds = new Set<Id>();
        for (Integer k = 0; k < results.size(); k++) {
            if (results[k].isSuccess()) {
                createdIds.add(results[k].getId());
            } else {
                System.debug(LoggingLevel.ERROR, '##BOOKING CASE FAILED## ' + results[k].getErrors());
                responses[caseFor[k]].varStatus = 'ERROR';
            }
        }
        if (createdIds.isEmpty()) return;

        // Read back without sharing: the Case trigger can move the case to a queue the agent user cannot see.
        Map<Id, Case> created = new CaseReader().read(createdIds);
        List<MessagingSession> sessions = new List<MessagingSession>();
        for (Integer k = 0; k < results.size(); k++) {
            if (!results[k].isSuccess()) continue;
            Integer i = caseFor[k];
            Id caseId = results[k].getId();
            Case createdCase = created.get(caseId);
            if (createdCase == null) {
                System.debug(LoggingLevel.ERROR, '##BOOKING CASE NOT READABLE## ' + caseId);
                responses[i].varStatus = 'ERROR';
                continue;
            }
            responses[i].varCaseNumber = createdCase.CaseNumber;
            if (bookings[i].sessionId != null) {
                sessions.add(new MessagingSession(Id = bookings[i].sessionId, CaseId = caseId));
            }
        }

        // Linking the session is helpful but must never fail the booking.
        if (!sessions.isEmpty()) {
            Database.SaveResult[] sessionResults = Database.update(sessions, false);
            for (Database.SaveResult sr : sessionResults) {
                if (!sr.isSuccess()) {
                    System.debug(LoggingLevel.ERROR, '##BOOKING SESSION LINK FAILED## ' + sr.getErrors());
                }
            }
        }
    }

    private static Boolean isIdOf(String value, Schema.SObjectType expected) {
        if (String.isBlank(value)) return false;
        try {
            return Id.valueOf(value).getSObjectType() == expected;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Reads back the Case Number without sharing, because the Case trigger can move
     * the new case to a branch queue that the agent user is not allowed to see.
     * Only Id and CaseNumber are read.
     */
        private without sharing class CaseReader {
        Map<Id, Case> read(Set<Id> ids) {
            return new Map<Id, Case>([SELECT Id, CaseNumber FROM Case WHERE Id IN :ids WITH SYSTEM_MODE]);
        }
    }
}