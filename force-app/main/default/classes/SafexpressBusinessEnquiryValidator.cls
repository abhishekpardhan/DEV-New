/**
 * @File Name   : SafexpressBusinessEnquiryValidator.cls
 * @Description : Hard validation for the Business Enquiry form: pincode, mobile, email,
 *                full name, designation, organisation name.
 *                Every *Error() method returns the message to show the customer, or null when valid.
 *                The SAME rules and messages are mirrored in sfxBusinessEnquiryForm.js - change both together.
 *
 * EMAIL = standard syntax (RFC 5321/5322 dot-atom) plus these deliberate application policies:
 *   - leading/trailing spaces trimmed; internal whitespace rejected (never removed)
 *   - ASCII only (internationalised addresses are rejected explicitly)
 *   - local part limited to letters, digits and dots (no _ - + or other symbols), like Gmail
 *   - local part must contain at least 3 letters or digits (symbols and a +tag are not counted)
 *   - domain must end in an alphabetic extension of 2+ letters
 *   - maximum 80 characters (length of Case.SuppliedEmail / Contact.Email)
 *   - Safexpress domains blocked in any spelling (domain only - the name part is not checked)
 *   - Gmail (gmail.com / googlemail.com): 3 to 30 characters (dots and +tag not counted; minimum
 *     kept at 3 so existing shorter Gmail addresses in our records are accepted), only letters /
 *     digits / dots, starts and ends with a letter or digit, 8+ characters must include a letter
 *   - known disposable mailbox domains blocked (exact domain match)
 *   Syntax validation does not prove that the mailbox exists or belongs to the customer.
 */
public inherited sharing class SafexpressBusinessEnquiryValidator {

    // =====================================================================
    // MESSAGES (identical to sfxBusinessEnquiryForm.js)
    // =====================================================================
    public static final String MSG_PINCODE_REQUIRED        = 'Pincode is required.';
    public static final String MSG_PINCODE_FORMAT          = 'Please enter a valid 6-digit pincode.';
    public static final String MSG_PINCODE_NOT_SERVICEABLE = 'Sorry, we are not serviceable in this area yet. Please try another pincode.';

    public static final String MSG_MOBILE_REQUIRED = 'Mobile number is required.';
    public static final String MSG_MOBILE_FORMAT   = 'Please enter a valid 10-digit Indian mobile number starting with 6, 7, 8 or 9.';
    public static final String MSG_MOBILE_FAKE     = 'This mobile number doesn\'t look genuine. Please enter your real mobile number.';

    public static final String MSG_EMAIL_REQUIRED        = 'Email address is required.';
    public static final String MSG_EMAIL_SPACES          = 'Spaces are not allowed in the email address.';
    public static final String MSG_EMAIL_NON_ASCII       = 'Please use an email address with English letters, numbers and symbols only.';
    public static final String MSG_EMAIL_NO_AT           = 'Email address must contain an @ symbol, e.g. name@gmail.com.';
    public static final String MSG_EMAIL_MULTIPLE_AT     = 'Email address can contain only one @ symbol.';
    public static final String MSG_EMAIL_NO_LOCAL        = 'Please enter the part before @, e.g. name@gmail.com.';
    public static final String MSG_EMAIL_NO_DOMAIN       = 'Please enter the domain after @, e.g. name@gmail.com.';
    public static final String MSG_EMAIL_SAFEXPRESS      = 'Safexpress email addresses can\'t be used. Please enter your personal or company email address.';
    public static final String MSG_EMAIL_LENGTH          = 'Email address cannot be longer than 80 characters.';
    public static final String MSG_EMAIL_LOCAL_LENGTH    = 'The part before @ cannot be longer than 64 characters.';
    public static final String MSG_EMAIL_LOCAL_SHORT     = 'The part before @ must have at least 3 letters or numbers, e.g. abc@gmail.com.';
    public static final String MSG_EMAIL_LOCAL_CHARS     = 'Sorry, only letters (a-z), numbers (0-9), and periods (.) are allowed.';
    public static final String MSG_EMAIL_LOCAL_DOT_EDGE  = 'The part before @ cannot start or end with a dot.';
    public static final String MSG_EMAIL_LOCAL_DOTS      = 'The part before @ cannot contain two dots in a row.';
    public static final String MSG_EMAIL_DOMAIN_CHARS    = 'The domain after @ can contain only letters, numbers, hyphens and dots.';
    public static final String MSG_EMAIL_DOMAIN_DOT_EDGE = 'The domain after @ cannot start or end with a dot.';
    public static final String MSG_EMAIL_DOMAIN_DOTS     = 'The domain after @ cannot contain two dots in a row.';
    public static final String MSG_EMAIL_NO_EXTENSION    = 'Please add a domain extension, e.g. .com or .in.';
    public static final String MSG_EMAIL_LABEL_LENGTH    = 'Each part of the domain can be at most 63 characters long.';
    public static final String MSG_EMAIL_DOMAIN_HYPHEN   = 'Each part of the domain must start and end with a letter or number, not a hyphen.';
    public static final String MSG_EMAIL_EXTENSION       = 'The domain extension must be at least 2 letters with no numbers, e.g. .com or .in.';
    public static final String MSG_EMAIL_TEMPORARY       = 'Temporary or disposable email addresses are not accepted. Please enter your regular email address.';

    public static final String MSG_GMAIL_CHARS        = 'Gmail addresses can contain only letters (a-z), numbers (0-9) and dots before the @.';
    public static final String MSG_GMAIL_EDGE         = 'A Gmail username must start and end with a letter or number.';
    public static final String MSG_GMAIL_LENGTH       = 'A Gmail username must be 3 to 30 characters long (dots are not counted).';
    public static final String MSG_GMAIL_NEEDS_LETTER = 'A Gmail username of 8 or more characters must include at least one letter (a-z).';

    public static final String MSG_NAME_REQUIRED = 'Full name is required.';
    public static final String MSG_NAME_LENGTH   = 'Full name must be 2 to 80 characters long.';
    public static final String MSG_NAME_FORMAT   = 'Name can contain only letters, spaces, dots, hyphens and apostrophes.';
    public static final String MSG_NAME_INVALID  = 'Please enter your real full name.';

    public static final String MSG_DESIGNATION_REQUIRED = 'Designation is required.';
    public static final String MSG_DESIGNATION_LENGTH   = 'Designation must be 2 to 60 characters long.';
    public static final String MSG_DESIGNATION_FORMAT   = 'Designation can contain only letters, numbers, spaces and the symbols & . , ( ) / -';
    public static final String MSG_DESIGNATION_INVALID  = 'Please enter your real designation, e.g. Manager, Director or Owner.';

    public static final String MSG_ORG_REQUIRED = 'Organisation name is required.';
    public static final String MSG_ORG_LENGTH   = 'Organisation name must be 2 to 80 characters long.';
    public static final String MSG_ORG_FORMAT   = 'Organisation name can contain only letters, numbers, spaces and the symbols & . , ( ) / -';
    public static final String MSG_ORG_INVALID  = 'Please enter your real organisation name.';

    // =====================================================================
    // PINCODE
    // =====================================================================
    public static String pincodeError(String pincode) {
        String p = pincode == null ? '' : pincode.trim();
        if (String.isBlank(p)) return MSG_PINCODE_REQUIRED;
        if (!Pattern.matches('^[1-9][0-9]{5}$', p)) return MSG_PINCODE_FORMAT;
        return null;
    }

    // =====================================================================
    // MOBILE
    // =====================================================================
    private static final Set<String> BLOCKED_MOBILES = new Set<String>{
        '9876543210', '9123456789', '9012345678', '6789012345', '7894561230', '9638527410',
        '9999999999', '8888888888', '7777777777', '6666666666'
    };
    private static final Integer MIN_SEQUENTIAL_RUN = 6;   // 6+ digits counting up/down (e.g. 123456) = fake
    private static final Integer MIN_DISTINCT_DIGITS = 3;  // 9999911111, 9090909090 = fake

    // "+91 70148 01885" / "917014801885" / "07014801885" -> "7014801885"
    // If letters or other symbols are present the raw value is returned so validation fails.
    public static String normaliseMobile(String raw) {
        if (String.isBlank(raw)) return '';
        String trimmed = raw.trim();
        if (!Pattern.matches('^[0-9+\\-\\s()]+$', trimmed)) return trimmed;
        String digits = trimmed.replaceAll('[^0-9]', '');
        if (digits.length() == 12 && digits.startsWith('91')) return digits.substring(2);
        if (digits.length() == 11 && digits.startsWith('0')) return digits.substring(1);
        return digits;
    }

    public static String mobileError(String mobile) {
        String m = mobile == null ? '' : mobile.trim();
        if (String.isBlank(m)) return MSG_MOBILE_REQUIRED;
        if (!Pattern.matches('^[6-9][0-9]{9}$', m)) return MSG_MOBILE_FORMAT;
        if (BLOCKED_MOBILES.contains(m)
            || regexFind('(\\d)\\1{5,}', m)                 // same digit 6+ times in a row
            || distinctDigitCount(m) < MIN_DISTINCT_DIGITS  // only 1-2 different digits
            || isRepeatingPattern(m)                        // 9898989898, 9876598765, 9879879879
            || hasSequentialRun(m, MIN_SEQUENTIAL_RUN)) {   // 9123456780, 6789012345, 9876543201
            return MSG_MOBILE_FAKE;
        }
        return null;
    }

    private static Integer distinctDigitCount(String d) {
        Set<String> seen = new Set<String>();
        for (Integer i = 0; i < d.length(); i++) {
            seen.add(d.substring(i, i + 1));
        }
        return seen.size();
    }

    private static Boolean isRepeatingPattern(String d) {
        for (Integer k = 1; k <= 5; k++) {
            if (d.substring(0, k).repeat(10).left(d.length()) == d) return true;
        }
        return false;
    }

    // Counts up (…7,8,9,0,1…) or down (…3,2,1,0,9…) - wraps around 9/0
    private static Boolean hasSequentialRun(String d, Integer minRun) {
        Integer up = 1;
        Integer down = 1;
        for (Integer i = 1; i < d.length(); i++) {
            Integer prev = Integer.valueOf(d.substring(i - 1, i));
            Integer cur = Integer.valueOf(d.substring(i, i + 1));
            up = (cur == Math.mod(prev + 1, 10)) ? up + 1 : 1;
            down = (cur == Math.mod(prev + 9, 10)) ? down + 1 : 1;
            if (up >= minRun || down >= minRun) return true;
        }
        return false;
    }

    // =====================================================================
    // EMAIL
    // =====================================================================
    private static final Integer EMAIL_MAX_LENGTH = 80;   // Case.SuppliedEmail / Contact.Email
    private static final Integer LOCAL_MAX_LENGTH = 64;   // RFC 5321
    private static final Integer LABEL_MAX_LENGTH = 63;   // RFC 1035
    private static final Integer LOCAL_MIN_ALNUM  = 3;    // letters + digits before @ (symbols and a +tag not counted)

    // Gmail username rules
    private static final Set<String> GMAIL_DOMAINS = new Set<String>{ 'gmail.com', 'googlemail.com' };
    private static final Integer GMAIL_MIN_LENGTH = 3;    // kept at 3 so existing shorter Gmail addresses are accepted
    private static final Integer GMAIL_MAX_LENGTH = 30;
    private static final Integer GMAIL_LETTER_REQUIRED_FROM = 8;

    // Safexpress in the DOMAIN (after @), any spelling, case or position:
    // abc@safexpress.com, abc@safe-xpress.co.in, abc@mail.safexpress.in, abc@SafeExpress.com, abc@safxpress.com
    private static final List<String> SAFEXPRESS_VARIANTS = new List<String>{
        'safexpres', 'safeexpres', 'safexprs', 'safxpres', 'saffexpres', 'safexpers'
    };

    // Throwaway mailbox services - matched on the exact domain (or its sub-domains) only
    private static final Set<String> DISPOSABLE_DOMAINS = new Set<String>{
        'mailinator.com', 'yopmail.com', 'yopmail.fr', 'guerrillamail.com', 'guerrillamail.net', 'sharklasers.com',
        '10minutemail.com', 'tempmail.com', 'temp-mail.org', 'throwawaymail.com', 'trashmail.com', 'getnada.com',
        'dispostable.com', 'maildrop.cc', 'mintemail.com', 'mohmal.com', 'emailondeck.com', 'spamgourmet.com',
        'discard.email', 'fakemail.net', 'mailnesia.com', 'tempail.com', 'tempr.email', 'emailfake.com'
    };

    // Value saved on the Case / Contact and used for the duplicate check (trim ends + lowercase)
    public static String normaliseEmail(String raw) {
        return raw == null ? '' : raw.trim().toLowerCase();
    }

    public static Boolean isSafexpressEmail(String email) {
        if (String.isBlank(email) || !email.contains('@')) return false;
        return isSafexpressDomain(email.substring(email.lastIndexOf('@') + 1));
    }

    private static Boolean isSafexpressDomain(String domain) {
        String compact = domain.toLowerCase().replaceAll('[^a-z0-9]', '');
        for (String variant : SAFEXPRESS_VARIANTS) {
            if (compact.contains(variant)) return true;
        }
        return false;
    }

    private static Boolean isDisposableDomain(String domain) {
        for (String d : DISPOSABLE_DOMAINS) {
            if (domain == d || domain.endsWith('.' + d)) return true;
        }
        return false;
    }

    // Letters and digits before any "+tag": "ab@x.com" -> 2, "a.b.c@x.com" -> 3, "ab+news@x.com" -> 2
    private static Integer localAlnumCount(String localPart) {
        Integer plus = localPart.indexOf('+');
        String base = plus >= 0 ? localPart.substring(0, plus) : localPart;
        return base.replaceAll('[^A-Za-z0-9]', '').length();
    }

    // Gmail ignores dots and treats anything after "+" as a delivery tag, so neither is counted.
    private static String gmailError(String localPart) {
        String lower = localPart.toLowerCase();
        Integer plus = lower.indexOf('+');
        String username = plus >= 0 ? lower.substring(0, plus) : lower;
        if (String.isEmpty(username)) return MSG_GMAIL_LENGTH;
        if (!Pattern.matches('^[a-z0-9.]+$', username)) return MSG_GMAIL_CHARS;
        if (username.startsWith('.') || username.endsWith('.')) return MSG_GMAIL_EDGE;
        String counted = username.replace('.', '');
        if (counted.length() < GMAIL_MIN_LENGTH || counted.length() > GMAIL_MAX_LENGTH) return MSG_GMAIL_LENGTH;
        if (counted.length() >= GMAIL_LETTER_REQUIRED_FROM && !regexFind('[a-z]', counted)) return MSG_GMAIL_NEEDS_LETTER;
        return null;
    }

    public static String emailError(String rawEmail) {
        // Policy: accidental spaces at the start/end are ignored; anything inside is validated as typed
        String e = rawEmail == null ? '' : rawEmail.trim();
        if (String.isBlank(e)) return MSG_EMAIL_REQUIRED;
        if (regexFind('\\s', e)) return MSG_EMAIL_SPACES;
        if (!Pattern.matches('^[\\x21-\\x7E]+$', e)) return MSG_EMAIL_NON_ASCII;

        // Exactly one @
        Integer atCount = e.length() - e.replace('@', '').length();
        if (atCount == 0) return MSG_EMAIL_NO_AT;
        if (atCount > 1) return MSG_EMAIL_MULTIPLE_AT;

        Integer at = e.indexOf('@');
        String localPart = e.substring(0, at);
        String domain = e.substring(at + 1).toLowerCase();
        if (String.isEmpty(localPart)) return MSG_EMAIL_NO_LOCAL;
        if (String.isEmpty(domain)) return MSG_EMAIL_NO_DOMAIN;

        if (isSafexpressDomain(domain)) return MSG_EMAIL_SAFEXPRESS;

        // Length limits
        if (e.length() > EMAIL_MAX_LENGTH) return MSG_EMAIL_LENGTH;
        if (localPart.length() > LOCAL_MAX_LENGTH) return MSG_EMAIL_LOCAL_LENGTH;

        // Part before @
        if (!Pattern.matches('^[A-Za-z0-9.]+$', localPart)) return MSG_EMAIL_LOCAL_CHARS;
        if (localPart.startsWith('.') || localPart.endsWith('.')) return MSG_EMAIL_LOCAL_DOT_EDGE;
        if (localPart.contains('..')) return MSG_EMAIL_LOCAL_DOTS;
        if (localAlnumCount(localPart) < LOCAL_MIN_ALNUM) return MSG_EMAIL_LOCAL_SHORT;

        // Domain
        if (!Pattern.matches('^[a-z0-9.-]+$', domain)) return MSG_EMAIL_DOMAIN_CHARS;
        if (domain.startsWith('.') || domain.endsWith('.')) return MSG_EMAIL_DOMAIN_DOT_EDGE;
        if (domain.contains('..')) return MSG_EMAIL_DOMAIN_DOTS;

        List<String> labels = domain.split('\\.');
        if (labels.size() < 2) return MSG_EMAIL_NO_EXTENSION;
        for (String label : labels) {
            if (label.length() > LABEL_MAX_LENGTH) return MSG_EMAIL_LABEL_LENGTH;
            if (label.startsWith('-') || label.endsWith('-')) return MSG_EMAIL_DOMAIN_HYPHEN;
        }
        if (!Pattern.matches('^[a-z]{2,}$', labels[labels.size() - 1])) return MSG_EMAIL_EXTENSION;

        // Provider rules
        if (GMAIL_DOMAINS.contains(domain)) {
            String gmailProblem = gmailError(localPart);
            if (gmailProblem != null) return gmailProblem;
        }

        if (isDisposableDomain(domain)) return MSG_EMAIL_TEMPORARY;
        return null;
    }

    // =====================================================================
    // FULL NAME
    // =====================================================================
    private static final List<String> KEYBOARD_RUNS = new List<String>{
        'qwert', 'werty', 'asdfg', 'sdfgh', 'zxcvb', 'xcvbn', 'yuiop', 'hjkl', 'qazwsx'
    };
    private static final Set<String> BLOCKED_NAME_WORDS = new Set<String>{
        'test', 'testing', 'tester', 'dummy', 'fake', 'sample', 'demo', 'name', 'fullname', 'myname',
        'xyz', 'abc', 'abcd', 'na', 'nil', 'none', 'null', 'user', 'customer', 'admin', 'unknown',
        'asdf', 'qwerty', 'anonymous', 'guest', 'nobody'
    };
    private static final List<String> NAME_KEYBOARD_RUNS = new List<String>{ 'asdf', 'qwer', 'zxcv', 'hjkl', 'abcde' };

    public static String nameError(String raw) {
        String n = normaliseText(raw);
        if (String.isBlank(n)) return MSG_NAME_REQUIRED;
        if (n.length() < 2 || n.length() > 80) return MSG_NAME_LENGTH;
        if (!Pattern.matches('^[A-Za-z][A-Za-z .\'-]*[A-Za-z.]$', n) || regexFind('[.\'-]{2,}', n)) return MSG_NAME_FORMAT;

        String lower = n.toLowerCase();
        String letters = lower.replaceAll('[^a-z]', '');
        if (letters.length() < 2 || !regexFind('[aeiouy]', letters)) return MSG_NAME_INVALID;
        if (regexFind('([a-z])\\1\\1', lower)) return MSG_NAME_INVALID;
        for (String run : NAME_KEYBOARD_RUNS) {
            if (lower.contains(run)) return MSG_NAME_INVALID;
        }
        if (isBlockedValue(lower, BLOCKED_NAME_WORDS)) return MSG_NAME_INVALID;
        for (String word : lower.split('[^a-z]+')) {
            if (looksRandom(word)) return MSG_NAME_INVALID;
        }
        return null;
    }

    // =====================================================================
    // DESIGNATION
    // =====================================================================
    private static final Set<String> BLOCKED_DESIGNATION_WORDS = new Set<String>{
        'test', 'testing', 'dummy', 'fake', 'sample', 'demo', 'na', 'nil', 'none', 'null', 'xyz', 'abc',
        'abcd', 'asdf', 'qwerty', 'designation', 'job', 'title', 'post', 'any', 'nothing', 'no', 'unknown'
    };

    public static String designationError(String raw) {
        return businessTextError(raw, 60, BLOCKED_DESIGNATION_WORDS,
            MSG_DESIGNATION_REQUIRED, MSG_DESIGNATION_LENGTH, MSG_DESIGNATION_FORMAT, MSG_DESIGNATION_INVALID);
    }

    // =====================================================================
    // ORGANISATION NAME (80 = length of Case.SuppliedCompany)
    // =====================================================================
    private static final Set<String> BLOCKED_ORG_WORDS = new Set<String>{
        'test', 'testing', 'dummy', 'fake', 'sample', 'demo', 'na', 'nil', 'none', 'null', 'xyz', 'abc',
        'abcd', 'asdf', 'qwerty', 'company', 'organisation', 'organization', 'org', 'business', 'firm',
        'unknown', 'no', 'nothing'
    };

    public static String organisationError(String raw) {
        return businessTextError(raw, 80, BLOCKED_ORG_WORDS,
            MSG_ORG_REQUIRED, MSG_ORG_LENGTH, MSG_ORG_FORMAT, MSG_ORG_INVALID);
    }

    // Shared rules for designation and organisation
    private static String businessTextError(String raw, Integer maxLen, Set<String> blocked,
            String msgRequired, String msgLength, String msgFormat, String msgInvalid) {
        String v = normaliseText(raw);
        if (String.isBlank(v)) return msgRequired;
        if (v.length() < 2 || v.length() > maxLen) return msgLength;
        if (!Pattern.matches('^[A-Za-z0-9][A-Za-z0-9 &.,()/\'-]*$', v) || regexFind('[&.,()/\'-]{3,}', v)) return msgFormat;

        String lower = v.toLowerCase();
        if (lower.replaceAll('[^a-z]', '').length() < 2) return msgInvalid;
        if (regexFind('(.)\\1{3,}', lower)) return msgInvalid;
        if (isBlockedValue(lower, blocked)) return msgInvalid;
        for (String word : lower.split('[^a-z0-9]+')) {
            if (looksRandom(word.replaceAll('[^a-z]', ''))) return msgInvalid;
        }
        return null;
    }

    // =====================================================================
    // HELPERS
    // =====================================================================
    public static String normaliseText(String raw) {
        return raw == null ? '' : raw.replaceAll('\\s+', ' ').trim();
    }

    public static String firstError(List<String> errors) {
        for (String err : errors) {
            if (err != null) return err;
        }
        return null;
    }

    private static Boolean regexFind(String regex, String value) {
        return Pattern.compile(regex).matcher(value).find();
    }

    // aaaa, titititi, 5+ consonants in a row, keyboard runs (used for name / designation / organisation)
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

    // Blocked if the whole value ("test") or EVERY word ("test company") is a blocked word.
    // "ABC Traders" is allowed because "traders" is not blocked.
    private static Boolean isBlockedValue(String lower, Set<String> blocked) {
        if (blocked.contains(lower.replaceAll('[^a-z0-9]', ''))) return true;
        Boolean anyWord = false;
        for (String w : lower.split('[^a-z0-9]+')) {
            if (String.isBlank(w)) continue;
            anyWord = true;
            if (!blocked.contains(w)) return false;
        }
        return anyWord;
    }
}