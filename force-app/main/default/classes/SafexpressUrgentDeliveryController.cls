/**
 * @File Name          : SafexpressUrgentDeliveryController.cls
 * @Description        : Handles Urgent Delivery requests from the Agentforce LWC form.
 * @Author             : Rohit Deshmukh
**/
public without sharing class SafexpressUrgentDeliveryController {

    public class UrgentDeliveryResult {
        @AuraEnabled public String outcome; 
        @AuraEnabled public String message;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String caseStatus; 
        @AuraEnabled public Boolean isError;
    }

    @AuraEnabled
    public static UrgentDeliveryResult checkExistingCase(String waybillNumber) {
        UrgentDeliveryResult result = new UrgentDeliveryResult();
        result.isError = false;

        String rawWaybill = waybillNumber != null ? waybillNumber.trim() : '';
        String waybillNum = rawWaybill.replaceAll('[^0-9]', '');

        if (String.isBlank(waybillNum)) {
            result.outcome = 'NEW';
            return result;
        }

        try {
            List<Case> existingCases = Database.queryWithBinds(
                'SELECT Id, CaseNumber, Status FROM Case ' +
                'WHERE WaybillNo__c = :waybill ' +
                'AND Case_Nature__c = \'Enquiry\' ' +
                'AND Case_Type__c = \'Waybill Enquiry\' ' +
                'AND IsClosed = false ' +
                'ORDER BY CreatedDate DESC LIMIT 1',
                new Map<String, Object>{ 'waybill' => waybillNum },
                AccessLevel.SYSTEM_MODE
            );

            if (!existingCases.isEmpty()) {
                Case existing = existingCases[0];
                result.outcome = 'EXISTING';
                result.caseNumber = existing.CaseNumber;
                result.caseStatus = existing.Status;
                result.message = 'An active case (' + existing.CaseNumber + ') is already open for this waybill. Our team is actively working on it.';
                return result;
            }

            result.outcome = 'NEW';
            return result;
        } catch (Exception ex) {
            result.isError = true;
            result.outcome = 'ERROR';
            result.message = 'An error occurred checking the waybill: ' + ex.getMessage();
            return result;
        }
    }

    @AuraEnabled
    public static UrgentDeliveryResult submitRequest(String waybillNumber, String mobileNumber, String emailId, String instructions, String shipmentStatus) {
        UrgentDeliveryResult result = new UrgentDeliveryResult();
        result.isError = false;

        String rawWaybill = waybillNumber != null ? waybillNumber.trim() : '';
        String waybillNum = rawWaybill.replaceAll('[^0-9]', '');
        String cleanMobile = normaliseMobile(mobileNumber);
        String cleanEmail = emailId != null ? emailId.trim() : '';

        // 1. WAYBILL NUMBER VALIDATION (Strictly 12 digits)
        if (String.isBlank(waybillNum) || (!Pattern.matches('^\\d{12}$', waybillNum))) {
            return validationError(result, 'Please provide a valid 12-digit waybill number.');
        }

        // 2. STATUS RESOLUTION & GATE
        String statusCheck = shipmentStatus != null ? shipmentStatus.trim().toUpperCase() : '';
        
        // Fallback: If Agentforce failed to pass shipmentStatus down to LWC, attempt API lookup
        if (String.isBlank(statusCheck)) {
            try {
                // If your org has GetWayBillStatusAPI, retrieve the real-time status dynamically
                Type apiType = Type.forName('GetWayBillStatusAPI');
                if (apiType != null) {
                    Map<String, Object> apiRes = (Map<String, Object>) JSON.deserializeUntyped(
                        GetWayBillStatusAPI.getWayBillInfo(waybillNum)
                    );
                    if (apiRes != null && apiRes.containsKey('currentStatus')) {
                        statusCheck = String.valueOf(apiRes.get('currentStatus')).toUpperCase();
                    }
                }
            } catch (Exception e) {
                System.debug('Dynamic status lookup bypassed: ' + e.getMessage());
            }
        }

        // Check against allowed statuses
        Boolean isEligible = String.isNotBlank(statusCheck) && 
            (statusCheck.contains('TRANSIT') || statusCheck.contains('ARRIVED'));

        // If status is confirmed and NOT eligible, reject
        if (String.isNotBlank(statusCheck) && !isEligible) {
            return validationError(result, 'Urgent delivery is strictly restricted to shipments currently In Transit or Arrived at Destination.');
        }

        // 3. CONTACT VALIDATION
        if (String.isBlank(cleanMobile)) return validationError(result, 'Please provide your 10-digit mobile number.');
        if (String.isBlank(cleanEmail)) return validationError(result, 'Please provide your email address.');
        
        String emailProblem = emailRejectionReason(cleanEmail);
        if (emailProblem != null) return validationError(result, emailProblem);
        
        if (!isValidMobile(cleanMobile)) {
            return validationError(result, 'Invalid mobile number. Please provide a genuine 10-digit Indian mobile number.');
        }

        try {
            // Deduplication Check
            List<Case> existingCases = Database.queryWithBinds(
                'SELECT Id, CaseNumber, Status FROM Case ' +
                'WHERE WaybillNo__c = :waybill ' +
                'AND Case_Nature__c = \'Enquiry\' ' +
                'AND Case_Type__c = \'Waybill Enquiry\' ' +
                'AND IsClosed = false ' +
                'ORDER BY CreatedDate DESC LIMIT 1',
                new Map<String, Object>{ 'waybill' => waybillNum },
                AccessLevel.SYSTEM_MODE
            );

            if (!existingCases.isEmpty()) {
                Case existing = existingCases[0];
                result.outcome = 'EXISTING';
                result.caseNumber = existing.CaseNumber;
                result.caseStatus = existing.Status;
                result.message = 'An active case (' + existing.CaseNumber + ') is already open for this waybill. Our team is actively working on it.';
                return result;
            }

            Case newCase = new Case();
            newCase.Origin = 'Chat';
            newCase.Priority = 'High';
            newCase.Status = 'New';
            newCase.WaybillNo__c = waybillNum;
            newCase.SuppliedPhone = cleanMobile;
            newCase.SuppliedEmail = cleanEmail;
            newCase.Case_Nature__c = 'Enquiry';
            newCase.Case_Type__c = 'Waybill Enquiry';
            
            if (String.isNotBlank(instructions)) {
                newCase.Description = 'Customer Instructions: ' + instructions + '\nRaised via: Safexpress chat (Urgent Delivery form)';
            } else {
                newCase.Description = 'Raised via: Safexpress chat (Urgent Delivery form)';
            }

            Database.insert(newCase, AccessLevel.SYSTEM_MODE);
            Case insertedCase = [SELECT CaseNumber, Status FROM Case WHERE Id = :newCase.Id LIMIT 1];
            
            result.outcome = 'CREATED';
            result.caseNumber = insertedCase.CaseNumber;
            result.caseStatus = insertedCase.Status;
            result.message = 'Your complaint has been registered. Case #' + insertedCase.CaseNumber + ' created.';
            return result;

        } catch (Exception ex) {
            result.isError = true;
            result.outcome = 'ERROR';
            result.message = 'An error occurred while processing your request: ' + ex.getMessage();
            return result;
        }
    }

    private static UrgentDeliveryResult validationError(UrgentDeliveryResult result, String msg) {
        result.isError = true;
        result.outcome = 'VALIDATION_ERROR';
        result.message = msg;
        return result;
    }

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

    private static final List<String> SAFEXPRESS_VARIANTS = new List<String>{ 'safexpres', 'safeexpres', 'safexprs' };
    
    private static final Set<String> INVALID_DOMAINS = new Set<String>{
        'gmai.com', 'gamil.com', 'yhoo.com', 'hotmai.com', 'outlok.com', 'yahmail.com'
    };
    
    private static final List<String> PROFANITY = new List<String>{
        'fuck', 'shit', 'bitch', 'asshole', 'dick', 'cunt', 'bastard', 'slut', 'whore', 'porn', 'scam', 'spam'
    };

    private static Boolean isSafexpressEmail(String email) {
        if (String.isBlank(email)) return false;
        String compact = email.toLowerCase().replaceAll('[^a-z0-9]', '');
        for (String variant : SAFEXPRESS_VARIANTS) {
            if (compact.contains(variant)) return true;
        }
        return false;
    }

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

    private static Boolean regexFind(String regex, String value) {
        return Pattern.compile(regex).matcher(value).find();
    }

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

    private static String emailRejectionReason(String rawEmail) {
        String e = rawEmail == null ? '' : rawEmail.trim().toLowerCase();
        if (String.isBlank(e)) return 'Please provide your email address.';
        if (isSafexpressEmail(e)) return 'Safexpress email addresses can\'t be used. Please enter your personal or company email address.';

        List<String> parts = e.split('@', -1);
        if (parts.size() != 2) return 'Please enter a valid email address.';
        String localPart = parts[0];
        String domain = parts[1];

        if (!Pattern.matches('^[a-z][a-z0-9.]{1,38}[a-z0-9]$', localPart) || localPart.contains('..')) return 'Please enter a valid email address.';
        if (regexFind('[0-9]', domain)) return 'The email domain (after @) cannot contain numbers.';
        if (!Pattern.matches('^[a-z]+(-[a-z]+)*(\\.[a-z]+(-[a-z]+)*)*\\.[a-z]{2,6}$', domain)) return 'Please enter a valid email address.';

        if (INVALID_DOMAINS.contains(domain)) return 'Please check the email domain for typos.';
        
        for (String profanityWord : PROFANITY) {
            if (localPart.contains(profanityWord)) return 'Please provide a valid and appropriate email address.';
        }

        if (localPart.replaceAll('[^0-9]', '').length() > 2) return 'Email name can contain at most 2 numbers.';
        
        if (regexFind('(.)\\1{2,}', localPart)) return 'This email address doesn\'t look valid. Please enter your real email address.';
        
        if (regexFind('(.{2,})\\1{2,}', localPart)) return 'This email address doesn\'t look valid. Please enter your real email address.';

        String letters = localPart.replaceAll('[^a-z]', '');
        if (letters.length() < 3) return 'This email address doesn\'t look valid. Please enter your real email address.';

        if (BLOCKED_EMAIL_NAMES.contains(letters)) return 'Test, dummy or temporary email addresses are not accepted.';
        for (String prefix : BLOCKED_EMAIL_NAME_PREFIXES) {
            if (letters.startsWith(prefix)) return 'Test, dummy or temporary email addresses are not accepted.';
        }

        List<String> labels = domain.split('\\.');
        List<String> nameLabels = new List<String>();
        for (Integer i = 0; i < labels.size() - 1; i++) nameLabels.add(labels[i]);
        for (String label : nameLabels) {
            if (BLOCKED_DOMAIN_WORDS.contains(label.replace('-', ''))) return 'Test, dummy or temporary email addresses are not accepted.';
        }
        for (String part : DISPOSABLE_DOMAIN_PARTS) {
            if (domain.contains(part)) return 'Test, dummy or temporary email addresses are not accepted.';
        }

        for (String seg : localPart.split('\\.')) {
            if (looksRandom(seg.replaceAll('[^a-z]', ''))) return 'This email address doesn\'t look valid.';
        }
        if (letters.length() >= 5 && !regexFind('[aeiouy]', letters)) return 'This email address doesn\'t look valid.';

        for (String label : nameLabels) {
            for (String piece : label.split('-')) {
                if (looksRandom(piece)) return 'This email address doesn\'t look valid.';
            }
        }
        return null;
    }

    private static Boolean isValidMobile(String mobile) {
        if (String.isBlank(mobile)) return false;
        String cleanMobile = mobile.trim();
        if (!Pattern.matches('^[6-9]\\d{9}$', cleanMobile)) return false;
        if (Pattern.matches('^(\\d)\\1{9}$', cleanMobile)) return false;
        return true;
    }
}