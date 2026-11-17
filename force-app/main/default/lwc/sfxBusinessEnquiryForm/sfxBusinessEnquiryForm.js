import { LightningElement, api } from 'lwc';
import checkPincode from '@salesforce/apex/SafexpressBusinessEnquiryService.checkPincode';
import checkDuplicate from '@salesforce/apex/SafexpressBusinessEnquiryService.checkDuplicate';
import submitEnquiry from '@salesforce/apex/SafexpressBusinessEnquiryService.submitEnquiry';
import SFX_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';
import IOS_BADGE from '@salesforce/resourceUrl/IosStoreLogo';      // App Store badge
import ANDROID_BADGE from '@salesforce/resourceUrl/AppStoreLogo';  // Google Play badge

const COMPONENT_VERSION = 'v19-pincode-accept-unlisted';
const DEBUG = true; // set to false before go-live

const STATUS_CREATED = 'CREATED';
const STATUS_DUPLICATE = 'DUPLICATE';

// =====================================================================
// VALIDATION - must stay identical to SafexpressBusinessEnquiryValidator.cls
// =====================================================================
const MSG = {
    PINCODE_REQUIRED: 'Pincode is required.',
    PINCODE_FORMAT: 'Please enter a valid 6-digit pincode.',
    PINCODE_NOT_SERVICEABLE: 'Sorry, we are not serviceable in this area yet. Please try another pincode.',
    PINCODE_CHECK_FAILED: 'We could not check this pincode right now. Please try again.',
    DUPLICATE_CHECK_FAILED: 'We could not verify your details right now. Please try again.',
    SUBMIT_FAILED: 'We could not register your enquiry right now. Please try again in a few minutes.',

    MOBILE_REQUIRED: 'Mobile number is required.',
    MOBILE_FORMAT: 'Please enter a valid 10-digit Indian mobile number starting with 6, 7, 8 or 9.',
    MOBILE_FAKE: "This mobile number doesn't look genuine. Please enter your real mobile number.",

    EMAIL_REQUIRED: 'Email address is required.',
    EMAIL_SPACES: 'Spaces are not allowed in the email address.',
    EMAIL_NON_ASCII: 'Please use an email address with English letters, numbers and symbols only.',
    EMAIL_NO_AT: 'Email address must contain an @ symbol, e.g. name@gmail.com.',
    EMAIL_MULTIPLE_AT: 'Email address can contain only one @ symbol.',
    EMAIL_NO_LOCAL: 'Please enter the part before @, e.g. name@gmail.com.',
    EMAIL_NO_DOMAIN: 'Please enter the domain after @, e.g. name@gmail.com.',
    EMAIL_SAFEXPRESS: "Safexpress email addresses can't be used. Please enter your personal or company email address.",
    EMAIL_LENGTH: 'Email address cannot be longer than 80 characters.',
    EMAIL_LOCAL_LENGTH: 'The part before @ cannot be longer than 64 characters.',
    EMAIL_LOCAL_SHORT: 'The part before @ must have at least 3 letters or numbers, e.g. abc@gmail.com.',
    EMAIL_LOCAL_CHARS: 'Sorry, only letters (a-z), numbers (0-9), and periods (.) are allowed.',
    EMAIL_LOCAL_DOT_EDGE: 'The part before @ cannot start or end with a dot.',
    EMAIL_LOCAL_DOTS: 'The part before @ cannot contain two dots in a row.',
    EMAIL_DOMAIN_CHARS: 'The domain after @ can contain only letters, numbers, hyphens and dots.',
    EMAIL_DOMAIN_DOT_EDGE: 'The domain after @ cannot start or end with a dot.',
    EMAIL_DOMAIN_DOTS: 'The domain after @ cannot contain two dots in a row.',
    EMAIL_NO_EXTENSION: 'Please add a domain extension, e.g. .com or .in.',
    EMAIL_LABEL_LENGTH: 'Each part of the domain can be at most 63 characters long.',
    EMAIL_DOMAIN_HYPHEN: 'Each part of the domain must start and end with a letter or number, not a hyphen.',
    EMAIL_EXTENSION: 'The domain extension must be at least 2 letters with no numbers, e.g. .com or .in.',
    EMAIL_TEMPORARY: 'Temporary or disposable email addresses are not accepted. Please enter your regular email address.',

    GMAIL_CHARS: 'Gmail addresses can contain only letters (a-z), numbers (0-9) and dots before the @.',
    GMAIL_EDGE: 'A Gmail username must start and end with a letter or number.',
    GMAIL_LENGTH: 'A Gmail username must be 3 to 30 characters long (dots are not counted).',
    GMAIL_NEEDS_LETTER: 'A Gmail username of 8 or more characters must include at least one letter (a-z).',

    NAME_REQUIRED: 'Full name is required.',
    NAME_LENGTH: 'Full name must be 2 to 80 characters long.',
    NAME_FORMAT: 'Name can contain only letters, spaces, dots, hyphens and apostrophes.',
    NAME_INVALID: 'Please enter your real full name.',

    DESIGNATION_REQUIRED: 'Designation is required.',
    DESIGNATION_LENGTH: 'Designation must be 2 to 60 characters long.',
    DESIGNATION_FORMAT: 'Designation can contain only letters, numbers, spaces and the symbols & . , ( ) / -',
    DESIGNATION_INVALID: 'Please enter your real designation, e.g. Manager, Director or Owner.',

    ORG_REQUIRED: 'Organisation name is required.',
    ORG_LENGTH: 'Organisation name must be 2 to 80 characters long.',
    ORG_FORMAT: 'Organisation name can contain only letters, numbers, spaces and the symbols & . , ( ) / -',
    ORG_INVALID: 'Please enter your real organisation name.'
};

// Messages shown while typing (all other email messages appear when the field loses focus)
const EMAIL_INSTANT_MESSAGES = [MSG.EMAIL_SAFEXPRESS, MSG.EMAIL_SPACES, MSG.EMAIL_MULTIPLE_AT, MSG.EMAIL_NON_ASCII];

// ---------- Mobile ----------
const BLOCKED_MOBILES = [
    '9876543210', '9123456789', '9012345678', '6789012345', '7894561230', '9638527410',
    '9999999999', '8888888888', '7777777777', '6666666666'
];
const MIN_SEQUENTIAL_RUN = 6;
const MIN_DISTINCT_DIGITS = 3;

function hasSequentialRun(d, minRun) {
    let up = 1;
    let down = 1;
    for (let i = 1; i < d.length; i++) {
        const prev = Number(d[i - 1]);
        const cur = Number(d[i]);
        up = cur === (prev + 1) % 10 ? up + 1 : 1;
        down = cur === (prev + 9) % 10 ? down + 1 : 1;
        if (up >= minRun || down >= minRun) return true;
    }
    return false;
}

function isRepeatingPattern(d) {
    for (let k = 1; k <= 5; k++) {
        if (d.substring(0, k).repeat(10).slice(0, d.length) === d) return true;
    }
    return false;
}

function mobileRejectionReason(raw) {
    const m = (raw || '').trim();
    if (!m) return MSG.MOBILE_REQUIRED;
    if (!/^[6-9][0-9]{9}$/.test(m)) return MSG.MOBILE_FORMAT;
    if (
        BLOCKED_MOBILES.includes(m) ||
        /(\d)\1{5,}/.test(m) ||
        new Set(m.split('')).size < MIN_DISTINCT_DIGITS ||
        isRepeatingPattern(m) ||
        hasSequentialRun(m, MIN_SEQUENTIAL_RUN)
    ) {
        return MSG.MOBILE_FAKE;
    }
    return '';
}

// Typing / pasting: digits only, "+91 98765 43210" and "098765 43210" become 10 digits
function toMobileDigits(raw) {
    let d = (raw || '').replace(/\D/g, '');
    if (d.length === 12 && d.startsWith('91')) d = d.slice(2);
    else if (d.length === 11 && d.startsWith('0')) d = d.slice(1);
    return d.slice(0, 10);
}

// ---------- Pincode ----------
function pincodeRejectionReason(raw) {
    const p = (raw || '').trim();
    if (!p) return MSG.PINCODE_REQUIRED;
    if (!/^[1-9][0-9]{5}$/.test(p)) return MSG.PINCODE_FORMAT;
    return '';
}

// ---------- Email (standard syntax + application policies) ----------
const EMAIL_MAX_LENGTH = 80;
const LOCAL_MAX_LENGTH = 64;
const LABEL_MAX_LENGTH = 63;
const LOCAL_MIN_ALNUM = 3; // letters + digits before @ (symbols and a +tag not counted)

const GMAIL_DOMAINS = ['gmail.com', 'googlemail.com'];
const GMAIL_MIN_LENGTH = 3;
const GMAIL_MAX_LENGTH = 30;
const GMAIL_LETTER_REQUIRED_FROM = 8;

const SAFEXPRESS_VARIANTS = ['safexpres', 'safeexpres', 'safexprs', 'safxpres', 'saffexpres', 'safexpers'];
const DISPOSABLE_DOMAINS = [
    'mailinator.com', 'yopmail.com', 'yopmail.fr', 'guerrillamail.com', 'guerrillamail.net', 'sharklasers.com',
    '10minutemail.com', 'tempmail.com', 'temp-mail.org', 'throwawaymail.com', 'trashmail.com', 'getnada.com',
    'dispostable.com', 'maildrop.cc', 'mintemail.com', 'mohmal.com', 'emailondeck.com', 'spamgourmet.com',
    'discard.email', 'fakemail.net', 'mailnesia.com', 'tempail.com', 'tempr.email', 'emailfake.com'
];

function isSafexpressDomain(domain) {
    const compact = (domain || '').toLowerCase().replace(/[^a-z0-9]/g, '');
    return SAFEXPRESS_VARIANTS.some((v) => compact.includes(v));
}

// Letters and digits before any "+tag": "ab@x.com" -> 2, "a.b.c@x.com" -> 3, "ab+news@x.com" -> 2
function localAlnumCount(local) {
    const plus = local.indexOf('+');
    const base = plus >= 0 ? local.slice(0, plus) : local;
    return base.replace(/[^A-Za-z0-9]/g, '').length;
}

function isDisposableDomain(domain) {
    return DISPOSABLE_DOMAINS.some((d) => domain === d || domain.endsWith('.' + d));
}

function gmailRejectionReason(local) {
    const lower = local.toLowerCase();
    const plus = lower.indexOf('+');
    const username = plus >= 0 ? lower.slice(0, plus) : lower;
    if (!username) return MSG.GMAIL_LENGTH;
    if (!/^[a-z0-9.]+$/.test(username)) return MSG.GMAIL_CHARS;
    if (username.startsWith('.') || username.endsWith('.')) return MSG.GMAIL_EDGE;
    const counted = username.replace(/\./g, '');
    if (counted.length < GMAIL_MIN_LENGTH || counted.length > GMAIL_MAX_LENGTH) return MSG.GMAIL_LENGTH;
    if (counted.length >= GMAIL_LETTER_REQUIRED_FROM && !/[a-z]/.test(counted)) return MSG.GMAIL_NEEDS_LETTER;
    return '';
}

function emailRejectionReason(rawEmail) {
    const e = (rawEmail || '').trim();
    if (!e) return MSG.EMAIL_REQUIRED;
    if (/\s/.test(e)) return MSG.EMAIL_SPACES;
    if (!/^[\x21-\x7E]+$/.test(e)) return MSG.EMAIL_NON_ASCII;

    const atCount = e.split('@').length - 1;
    if (atCount === 0) return MSG.EMAIL_NO_AT;
    if (atCount > 1) return MSG.EMAIL_MULTIPLE_AT;

    const at = e.indexOf('@');
    const local = e.slice(0, at);
    const domain = e.slice(at + 1).toLowerCase();
    if (!local) return MSG.EMAIL_NO_LOCAL;
    if (!domain) return MSG.EMAIL_NO_DOMAIN;

    if (isSafexpressDomain(domain)) return MSG.EMAIL_SAFEXPRESS;

    if (e.length > EMAIL_MAX_LENGTH) return MSG.EMAIL_LENGTH;
    if (local.length > LOCAL_MAX_LENGTH) return MSG.EMAIL_LOCAL_LENGTH;

    if (!/^[A-Za-z0-9.]+$/.test(local)) return MSG.EMAIL_LOCAL_CHARS;
    if (local.startsWith('.') || local.endsWith('.')) return MSG.EMAIL_LOCAL_DOT_EDGE;
    if (local.includes('..')) return MSG.EMAIL_LOCAL_DOTS;
    if (localAlnumCount(local) < LOCAL_MIN_ALNUM) return MSG.EMAIL_LOCAL_SHORT;

    if (!/^[a-z0-9.-]+$/.test(domain)) return MSG.EMAIL_DOMAIN_CHARS;
    if (domain.startsWith('.') || domain.endsWith('.')) return MSG.EMAIL_DOMAIN_DOT_EDGE;
    if (domain.includes('..')) return MSG.EMAIL_DOMAIN_DOTS;

    const labels = domain.split('.');
    if (labels.length < 2) return MSG.EMAIL_NO_EXTENSION;
    for (const label of labels) {
        if (label.length > LABEL_MAX_LENGTH) return MSG.EMAIL_LABEL_LENGTH;
        if (label.startsWith('-') || label.endsWith('-')) return MSG.EMAIL_DOMAIN_HYPHEN;
    }
    if (!/^[a-z]{2,}$/.test(labels[labels.length - 1])) return MSG.EMAIL_EXTENSION;

    if (GMAIL_DOMAINS.includes(domain)) {
        const gmailProblem = gmailRejectionReason(local);
        if (gmailProblem) return gmailProblem;
    }

    if (isDisposableDomain(domain)) return MSG.EMAIL_TEMPORARY;
    return '';
}

// ---------- Name / designation / organisation ----------
const KEYBOARD_RUNS = ['qwert', 'werty', 'asdfg', 'sdfgh', 'zxcvb', 'xcvbn', 'yuiop', 'hjkl', 'qazwsx'];
const BLOCKED_NAME_WORDS = [
    'test', 'testing', 'tester', 'dummy', 'fake', 'sample', 'demo', 'name', 'fullname', 'myname',
    'xyz', 'abc', 'abcd', 'na', 'nil', 'none', 'null', 'user', 'customer', 'admin', 'unknown',
    'asdf', 'qwerty', 'anonymous', 'guest', 'nobody'
];
const NAME_KEYBOARD_RUNS = ['asdf', 'qwer', 'zxcv', 'hjkl', 'abcde'];
const BLOCKED_DESIGNATION_WORDS = [
    'test', 'testing', 'dummy', 'fake', 'sample', 'demo', 'na', 'nil', 'none', 'null', 'xyz', 'abc',
    'abcd', 'asdf', 'qwerty', 'designation', 'job', 'title', 'post', 'any', 'nothing', 'no', 'unknown'
];
const BLOCKED_ORG_WORDS = [
    'test', 'testing', 'dummy', 'fake', 'sample', 'demo', 'na', 'nil', 'none', 'null', 'xyz', 'abc',
    'abcd', 'asdf', 'qwerty', 'company', 'organisation', 'organization', 'org', 'business', 'firm',
    'unknown', 'no', 'nothing'
];

function looksRandom(letters) {
    if (!letters) return false;
    if (/(.)\1{3,}/.test(letters)) return true;
    if (/(..+?)\1{2,}/.test(letters)) return true;
    if (/[bcdfghjklmnpqrstvwxz]{5,}/.test(letters)) return true;
    return KEYBOARD_RUNS.some((run) => letters.includes(run));
}

function clean(v) {
    return (v || '').replace(/\s+/g, ' ').trim();
}

function isBlockedValue(lower, blocked) {
    if (blocked.includes(lower.replace(/[^a-z0-9]/g, ''))) return true;
    const words = lower.split(/[^a-z0-9]+/).filter(Boolean);
    return words.length > 0 && words.every((w) => blocked.includes(w));
}

function nameRejectionReason(raw) {
    const n = clean(raw);
    if (!n) return MSG.NAME_REQUIRED;
    if (n.length < 2 || n.length > 80) return MSG.NAME_LENGTH;
    if (!/^[A-Za-z][A-Za-z .'-]*[A-Za-z.]$/.test(n) || /[.'-]{2,}/.test(n)) return MSG.NAME_FORMAT;

    const lower = n.toLowerCase();
    const letters = lower.replace(/[^a-z]/g, '');
    if (letters.length < 2 || !/[aeiouy]/.test(letters)) return MSG.NAME_INVALID;
    if (/([a-z])\1\1/.test(lower)) return MSG.NAME_INVALID;
    if (NAME_KEYBOARD_RUNS.some((run) => lower.includes(run))) return MSG.NAME_INVALID;
    if (isBlockedValue(lower, BLOCKED_NAME_WORDS)) return MSG.NAME_INVALID;
    if (lower.split(/[^a-z]+/).some((w) => looksRandom(w))) return MSG.NAME_INVALID;
    return '';
}

function businessTextRejectionReason(raw, maxLen, blocked, msgs) {
    const v = clean(raw);
    if (!v) return msgs.required;
    if (v.length < 2 || v.length > maxLen) return msgs.length;
    if (!/^[A-Za-z0-9][A-Za-z0-9 &.,()\/'-]*$/.test(v) || /[&.,()\/'-]{3,}/.test(v)) return msgs.format;

    const lower = v.toLowerCase();
    if (lower.replace(/[^a-z]/g, '').length < 2) return msgs.invalid;
    if (/(.)\1{3,}/.test(lower)) return msgs.invalid;
    if (isBlockedValue(lower, blocked)) return msgs.invalid;
    if (lower.split(/[^a-z0-9]+/).some((w) => looksRandom(w.replace(/[^a-z]/g, '')))) return msgs.invalid;
    return '';
}

function designationRejectionReason(raw) {
    return businessTextRejectionReason(raw, 60, BLOCKED_DESIGNATION_WORDS, {
        required: MSG.DESIGNATION_REQUIRED, length: MSG.DESIGNATION_LENGTH,
        format: MSG.DESIGNATION_FORMAT, invalid: MSG.DESIGNATION_INVALID
    });
}

function organisationRejectionReason(raw) {
    return businessTextRejectionReason(raw, 80, BLOCKED_ORG_WORDS, {
        required: MSG.ORG_REQUIRED, length: MSG.ORG_LENGTH,
        format: MSG.ORG_FORMAT, invalid: MSG.ORG_INVALID
    });
}

// ---------- Values handed in by the chat ----------
const FORM_FIELDS = ['pincode', 'mobileNumber', 'emailAddress', 'fullName', 'designation', 'organisationName'];
const FIELD_ALIASES = {
    pincode: ['pincode', 'pin', 'pinno', 'pincodeno', 'postalcode', 'postcode', 'zipcode', 'zip'],
    mobileNumber: ['mobilenumber', 'mobile', 'mobileno', 'phone', 'phonenumber', 'contactnumber', 'contactno'],
    emailAddress: ['emailaddress', 'email', 'emailid', 'mail'],
    fullName: ['fullname', 'name', 'customername', 'requestername'],
    designation: ['designation', 'jobtitle', 'role'],
    organisationName: ['organisationname', 'organizationname', 'organisation', 'organization', 'companyname', 'company']
};
const EMPTY_PLACEHOLDERS = ['null', 'undefined', 'none', 'n/a', '-'];

function debugLog(...args) {
    if (!DEBUG) return;
    // eslint-disable-next-line no-console
    console.info('[sfxBEF]', COMPONENT_VERSION, ...args);
}

function parseIncomingValue(val) {
    if (!val) return null;
    if (typeof val === 'string') {
        try {
            const parsed = JSON.parse(val);
            return parsed && typeof parsed === 'object' ? parsed : null;
        } catch (e) {
            return null;
        }
    }
    return typeof val === 'object' ? val : null;
}

function normaliseIncomingValue(raw) {
    let src = raw;
    if (src && src.enquiryForm) {
        src = parseIncomingValue(src.enquiryForm) || src;
    }
    const byKey = {};
    Object.keys(src || {}).forEach((key) => {
        byKey[key.toLowerCase().replace(/[^a-z]/g, '')] = src[key];
    });
    const out = {};
    Object.keys(FIELD_ALIASES).forEach((field) => {
        const alias = FIELD_ALIASES[field].find((a) => byKey[a] !== undefined && byKey[a] !== null);
        let value = alias ? String(byKey[alias]).trim() : '';
        if (EMPTY_PLACEHOLDERS.includes(value.toLowerCase()) || value.includes('{!')) value = '';
        out[field] = value;
    });
    return out;
}

const DUPLICATE_CHECK_DELAY_MS = 600;

// Footer app links
const IOS_APP_URL = 'https://apps.apple.com/in/app/safexpress-app/id6797861161';
const ANDROID_APP_URL = 'https://play.google.com/store/apps/details?id=com.safexpress.enterprise';

// =====================================================================
// COMPONENT
// =====================================================================
export default class SfxBusinessEnquiryForm extends LightningElement {
    @api configuration;

    // Lightning Type editor value - sent to the agent action when the customer clicks the chat Submit.
    // After the chat Submit the chat redraws this form and passes the submitted values back in here:
    // the form keeps them on screen so the customer can finish, and stays silent until they edit.
    // If those values belong to an enquiry registered a moment ago, the redrawn copy shows its
    // registration summary (see runDuplicateCheck).
    _value = {};
    @api
    get value() {
        return this._value;
    }
    set value(val) {
        debugLog('value received', val);
        const incoming = parseIncomingValue(val);
        if (!incoming) return;
        const fromForm = FORM_FIELDS.some((f) => Object.prototype.hasOwnProperty.call(incoming, f));
        const fields = normaliseIncomingValue(incoming);
        // Exactly the 7 fields of SafexpressBusinessEnquiryForm
        this._value = { ...fields, messagingSessionId: incoming.messagingSessionId || this.sessionId };

        if (this._userEdited || this.result || !fromForm) return;

        this._chatSubmitted = true; // the chat Submit has already been used for this form
        this._silent = true;        // never send these old values back to the chat until the customer edits
        this.restoreFromValue(fields);
    }

    logoUrl = SFX_LOGO;
    iosBadgeUrl = IOS_BADGE;
    androidBadgeUrl = ANDROID_BADGE;
    iosAppUrl = IOS_APP_URL;
    androidAppUrl = ANDROID_APP_URL;

    pincode = '';
    mobile = '';
    email = '';
    fullName = '';
    designation = '';
    organisationName = '';
    touched = { pincode: false, mobile: false, email: false, fullName: false, designation: false, organisationName: false };

    // Submission state
    isSubmitting = false;
    submitError = '';
    result = null; // { status, caseNumber, customerName, organisationName, pincode, city, state, fromChat }

    _userEdited = false;
    _silent = false;
    _chatSubmitted = false;
    _connected = false;
    _pendingLookups = false;

    // Pincode lookup: idle | checking | serviceable | not_serviceable
    // A valid-format pincode is always accepted ('serviceable'); the location card shows only when the
    // pincode is in Pincode__c. A pincode that is not listed, or a failed lookup, is accepted silently.
    pincodeState = 'idle';
    pincodeMessage = '';
    location = null;
    _pinSeq = 0;

    // Duplicate check: idle | checking | clear | duplicate | error
    dupState = 'idle';
    dupMessage = '';
    dupCaseNumber = '';
    _dupSeq = 0;
    _dupTimer;
    _dupPending = false;
    _dupCache = null;

    connectedCallback() {
        this._connected = true;
        debugLog('form opened');
        if (this._pendingLookups) {
            this.runRestoreLookups();
        }
    }

    disconnectedCallback() {
        this._connected = false;
        clearTimeout(this._dupTimer);
    }

    // ---------------- Keep the customer's entries after the chat Submit ----------------
    restoreFromValue(v) {
        const pin = this.sanitise('pincode', v.pincode || '');
        const mob = this.sanitise('mobile', v.mobileNumber || '');
        const em = (v.emailAddress || '').trim();
        const name = this.sanitise('fullName', v.fullName || '');
        const des = this.sanitise('designation', v.designation || '');
        const org = this.sanitise('organisationName', v.organisationName || '');

        if (!pin && !mob && !em && !name && !des && !org) return;
        if (
            pin === this.pincode && mob === this.mobile && em === this.email &&
            name === this.fullName && des === this.designation && org === this.organisationName
        ) {
            return;
        }

        this.pincode = pin;
        this.mobile = mob;
        this.email = em;
        this.fullName = name;
        this.designation = des;
        this.organisationName = org;
        this.touched = { pincode: true, mobile: true, email: true, fullName: true, designation: true, organisationName: true };

        this._pinSeq += 1;
        this.location = null;
        this.pincodeMessage = '';
        this.pincodeState = 'idle';
        this._dupCache = null;

        if (this._connected) {
            this.runRestoreLookups();
        } else {
            this._pendingLookups = true;
        }
    }

    runRestoreLookups() {
        this._pendingLookups = false;
        if (this.pincode.length === 6 && !pincodeRejectionReason(this.pincode)) {
            this.lookupPincode(this.pincode, this._pinSeq); // runs the duplicate check when it finishes
        } else {
            this.scheduleDuplicateCheck(0);
        }
    }

    // True only for the untouched copy the chat redraws after its Submit
    get isRedrawnCopy() {
        return this._chatSubmitted && this._silent && !this._userEdited;
    }

    // ---------------- Pincode getters ----------------
    get isPincodeValid() {
        return this.pincodeState === 'serviceable';
    }
    get isPincodeChecking() {
        return this.pincodeState === 'checking';
    }
    get hasLocation() {
        return this.isPincodeValid && !!this.location;
    }
    get locationCity() {
        return (this.location?.city || '').toUpperCase();
    }
    get locationSubtext() {
        const { city, district, state } = this.location || {};
        const showDistrict = district && (district || '').toLowerCase() !== (city || '').toLowerCase();
        return [showDistrict ? district : null, state].filter(Boolean).join(', ');
    }
    get pincodeFieldError() {
        const problem = pincodeRejectionReason(this.pincode);
        if (!problem) return '';
        return this.touched.pincode || this.pincode.length === 6 ? problem : '';
    }
    get pincodeServiceError() {
        return this.pincodeState === 'not_serviceable' ? this.pincodeMessage : '';
    }

    // ---------------- Mobile / email getters ----------------
    get mobileProblem() {
        return mobileRejectionReason(this.mobile);
    }
    get isMobileValid() {
        return !this.mobileProblem;
    }
    get mobileError() {
        if (!this.touched.mobile && this.mobile.length < 10) return '';
        return this.mobileProblem;
    }
    get normalisedEmail() {
        return (this.email || '').trim().toLowerCase();
    }
    get emailProblem() {
        return emailRejectionReason(this.email);
    }
    get isEmailValid() {
        return !this.emailProblem;
    }
    get emailError() {
        const problem = this.emailProblem;
        if (!problem) return '';
        if (EMAIL_INSTANT_MESSAGES.includes(problem)) return problem;
        return this.touched.email ? problem : '';
    }

    // ---------------- Step one / duplicate ----------------
    get isStepOneValid() {
        return this.isPincodeValid && this.isMobileValid && this.isEmailValid;
    }
    get duplicateKey() {
        return `${this.mobile}|${this.normalisedEmail}`;
    }
    get isDupChecking() {
        return this.dupState === 'checking';
    }
    get isDuplicate() {
        return this.dupState === 'duplicate';
    }
    get isDupError() {
        return this.dupState === 'error';
    }
    get isStepOneVerified() {
        return this.isStepOneValid && this.dupState === 'clear';
    }
    // "Click Submit below to continue." only makes sense before the chat Submit was used
    get showDupSubmitHint() {
        return this.isDuplicate && !this._chatSubmitted;
    }

    // ---------------- Details section ----------------
    get showDetails() {
        return !this.isDuplicate;
    }
    get isDetailsLocked() {
        return !this.isStepOneVerified;
    }
    get showLockNote() {
        return this.isDetailsLocked && !this.isDupChecking && !this.isDupError;
    }
    get nameProblem() {
        return nameRejectionReason(this.fullName);
    }
    get nameError() {
        return this.touched.fullName ? this.nameProblem : '';
    }
    get isNameOk() {
        return !this.nameProblem;
    }
    get designationProblem() {
        return designationRejectionReason(this.designation);
    }
    get designationError() {
        return this.touched.designation ? this.designationProblem : '';
    }
    get isDesignationOk() {
        return !this.designationProblem;
    }
    get organisationProblem() {
        return organisationRejectionReason(this.organisationName);
    }
    get organisationError() {
        return this.touched.organisationName ? this.organisationProblem : '';
    }
    get isOrganisationOk() {
        return !this.organisationProblem;
    }

    get isReady() {
        return this.isStepOneVerified && this.isNameOk && this.isDesignationOk && this.isOrganisationOk;
    }

    // ---------------- Progress ----------------
    get completedCount() {
        return [this.isPincodeValid, this.isMobileValid, this.isEmailValid, this.isNameOk, this.isDesignationOk, this.isOrganisationOk]
            .filter(Boolean).length;
    }
    get progressText() {
        return `${this.completedCount} of 6 completed`;
    }
    get progressStyle() {
        return `width: ${Math.round((this.completedCount / 6) * 100)}%;`;
    }

    // ---------------- Submit Request ----------------
    get showSubmitButton() {
        return !this.isDuplicate;
    }
    get isSubmitDisabled() {
        return this.isSubmitting || !this.isReady;
    }
    get submitLabel() {
        return this.isSubmitting ? 'Submitting…' : 'Submit Request';
    }

    async handleSubmitRequest() {
        this.submitError = '';
        this.touched = { pincode: true, mobile: true, email: true, fullName: true, designation: true, organisationName: true };
        if (!this.isReady || this.isSubmitting) return;

        this.isSubmitting = true;
        try {
            const res = await submitEnquiry({
                pincode: this.pincode,
                mobileNumber: this.mobile,
                emailAddress: this.normalisedEmail,
                fullName: clean(this.fullName),
                designation: clean(this.designation),
                organisationName: clean(this.organisationName),
                messagingSessionId: this.sessionId
            });
            debugLog('submitEnquiry result', res);

            if (res && (res.status === STATUS_CREATED || res.status === STATUS_DUPLICATE)) {
                this.result = { ...res, fromChat: false };
                this._silent = false;
                this.publishValue();
                this.notifyChatIfNeeded();
            } else {
                this.submitError = res?.message || MSG.SUBMIT_FAILED;
            }
        } catch (error) {
            console.error('Submit enquiry error: ', error);
            this.submitError = MSG.SUBMIT_FAILED;
        } finally {
            this.isSubmitting = false;
        }
    }

    // If the chat Submit was already used (the customer clicked it before completing the form),
    // post the reference number into the chat so the agent can confirm it.
    notifyChatIfNeeded() {
        if (!this._chatSubmitted || !this.result) return;
        const util = this.configuration?.util;
        if (!util || typeof util.sendTextMessage !== 'function') return;
        const text = this.result.status === STATUS_DUPLICATE
            ? `My business enquiry is already registered. Reference No. ${this.result.caseNumber}.`
            : `I have submitted the business enquiry form. Reference No. ${this.result.caseNumber}.`;
        try {
            util.sendTextMessage(text);
        } catch (error) {
            console.error('sendTextMessage error: ', error);
        }
    }

    // ---------------- Result view ----------------
    get hasResult() {
        return !!this.result;
    }
    get isCreatedResult() {
        return this.result?.status === STATUS_CREATED;
    }
    get resultNote() {
        if (this.result?.fromChat) return '✅ Your business enquiry is registered.';
        if (!this.isCreatedResult) {
            return this._chatSubmitted
                ? '⚠️ An enquiry is already registered with these details.'
                : '⚠️ An enquiry is already registered with these details. Please click Submit below to continue.';
        }
        return this._chatSubmitted
            ? '✅ Your business enquiry is logged. I will confirm it in the chat.'
            : '✅ Your business enquiry is logged. Please click Submit below to confirm.';
    }
    get resultNoteClass() {
        return this.isCreatedResult ? 'sfx-result-note' : 'sfx-result-note is-warning';
    }
    get resultIcon() {
        return this.isCreatedResult ? '✓' : '!';
    }
    get resultIconClass() {
        return this.isCreatedResult ? 'sfx-result-icon' : 'sfx-result-icon is-warning';
    }
    get resultHeadline() {
        const cn = this.result?.caseNumber || '';
        return this.isCreatedResult
            ? `Your business enquiry has been registered. Case #${cn} created.`
            : `We already have a business enquiry registered with these details. Case #${cn}.`;
    }
    get resultHeadlineClass() {
        return this.isCreatedResult ? 'sfx-result-headline' : 'sfx-result-headline is-warning';
    }
    get resultCaseNumber() {
        return this.result?.caseNumber || '';
    }
    get resultName() {
        return this.result?.customerName || clean(this.fullName) || '-';
    }
    get resultOrganisation() {
        return this.result?.organisationName || clean(this.organisationName) || '-';
    }
    get resultLocation() {
        const city = this.result?.city || this.location?.city || '';
        const state = this.result?.state || this.location?.state || '';
        const pin = this.result?.pincode || this.pincode || '';
        const place = [city, state].filter(Boolean).join(', ');
        return place ? `${place} - ${pin}` : pin || '-';
    }

    // ---------------- Styling ----------------
    stepClass(done, error, last) {
        let cls = 'sfx-step';
        if (done) cls += ' is-done';
        else if (error) cls += ' is-error';
        if (last) cls += ' is-last';
        return cls;
    }
    inputClass(done, error) {
        if (error) return 'sfx-input has-error';
        return done ? 'sfx-input is-valid' : 'sfx-input';
    }
    get pincodeStepClass() {
        return this.stepClass(this.isPincodeValid, !!(this.pincodeFieldError || this.pincodeServiceError), false);
    }
    get mobileStepClass() {
        return this.stepClass(this.isMobileValid, !!this.mobileError, false);
    }
    get emailStepClass() {
        return this.stepClass(this.isEmailValid, !!this.emailError, true);
    }
    get pincodeInputClass() {
        return this.inputClass(this.isPincodeValid, !!(this.pincodeFieldError || this.pincodeServiceError));
    }
    get mobileInputClass() {
        return this.inputClass(this.isMobileValid, !!this.mobileError);
    }
    get emailInputClass() {
        return this.inputClass(this.isEmailValid, !!this.emailError);
    }
    get nameInputClass() {
        return this.inputClass(this.isNameOk, !!this.nameError);
    }
    get designationInputClass() {
        return this.inputClass(this.isDesignationOk, !!this.designationError);
    }
    get organisationInputClass() {
        return this.inputClass(this.isOrganisationOk, !!this.organisationError);
    }

    get sessionId() {
        return this.configuration?.context?.messagingSessionId || '';
    }

    // ---------------- Handlers ----------------
    handleInput(event) {
        const field = event.target.dataset.field;
        const raw = event.target.value || '';
        const val = this.sanitise(field, raw);
        if (val !== raw) event.target.value = val;
        if (val === this[field]) return;

        this._userEdited = true;
        this._silent = false;
        this.submitError = '';
        this[field] = val;

        if (field === 'pincode') this.onPincodeChange(val);
        if (field === 'pincode' || field === 'mobile' || field === 'email') {
            this.scheduleDuplicateCheck(DUPLICATE_CHECK_DELAY_MS);
        }
        this.publishValue();
    }

    handleBlur(event) {
        const field = event.target.dataset.field;
        this.touched = { ...this.touched, [field]: true };
        if ((field === 'mobile' || field === 'email') && this._dupPending) {
            this.scheduleDuplicateCheck(0);
        }
    }

    handleRetryDuplicate() {
        this._dupCache = null;
        this.scheduleDuplicateCheck(0);
    }

    sanitise(field, raw) {
        switch (field) {
            case 'pincode':
                return raw.replace(/\D/g, '').slice(0, 6);
            case 'mobile':
                return toMobileDigits(raw);
            case 'email':
                return raw;
            case 'fullName':
                return raw.replace(/[^A-Za-z .'-]/g, '').replace(/\s{2,}/g, ' ').replace(/^\s+/, '').slice(0, 80);
            default:
                return raw.replace(/\s{2,}/g, ' ').replace(/^\s+/, '');
        }
    }

    // ---------------- Pincode lookup ----------------
    onPincodeChange(pin) {
        this._pinSeq += 1;
        this.location = null;
        this.pincodeMessage = '';
        this.pincodeState = 'idle';
        if (pin.length < 6) return;
        if (pincodeRejectionReason(pin)) {
            this.touched = { ...this.touched, pincode: true };
            return;
        }
        this.lookupPincode(pin, this._pinSeq);
    }

    async lookupPincode(pin, seq) {
        this.pincodeState = 'checking';
        try {
            const res = await checkPincode({ pincode: pin });
            if (seq !== this._pinSeq) return;
            if (res && res.isServiceable) {
                // Listed in Pincode__c: green tick + location card
                this.pincodeState = 'serviceable';
                this.location = { city: res.city, district: res.district, state: res.state };
            } else if (res && (res.isAccepted || !res.message)) {
                // Valid format but not listed: green tick only, accepted silently
                this.pincodeState = 'serviceable';
                this.location = null;
            } else {
                // Only a format problem reported by the server
                this.pincodeState = 'not_serviceable';
                this.pincodeMessage = res.message || MSG.PINCODE_FORMAT;
            }
        } catch (error) {
            if (seq !== this._pinSeq) return;
            // The lookup failed: the format is already valid, so accept silently (no card, no message)
            console.error('Pincode check error: ', error);
            this.pincodeState = 'serviceable';
            this.location = null;
        }
        this.scheduleDuplicateCheck(0);
        this.publishValue();
    }

    // ---------------- Duplicate check ----------------
    setDup(state, message = '', caseNumber = '') {
        this.dupState = state;
        this.dupMessage = message;
        this.dupCaseNumber = caseNumber;
    }

    scheduleDuplicateCheck(delay) {
        clearTimeout(this._dupTimer);
        this._dupPending = false;
        this._dupSeq += 1;

        if (!this.isStepOneValid) {
            this.setDup('idle');
            return;
        }
        const key = this.duplicateKey;
        if (this._dupCache && this._dupCache.key === key) {
            this.setDup(this._dupCache.state, this._dupCache.message, this._dupCache.caseNumber);
            return;
        }

        this.setDup('checking');
        const seq = this._dupSeq;
        this._dupPending = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._dupTimer = setTimeout(() => {
            this._dupPending = false;
            this.runDuplicateCheck(key, seq);
        }, delay);
    }

    async runDuplicateCheck(key, seq) {
        try {
            const res = await checkDuplicate({
                pincode: this.pincode,
                mobile: this.mobile,
                email: this.normalisedEmail,
                fullName: clean(this.fullName),
                designation: clean(this.designation),
                organisationName: clean(this.organisationName)
            });
            if (seq !== this._dupSeq) return;
            if (!res || res.isError) {
                this.setDup('error', res?.message || MSG.DUPLICATE_CHECK_FAILED);
            } else if (res.isDuplicate) {
                // Copy redrawn by the chat after its Submit (untouched): only when THIS form registered
                // the enquiry a moment ago (same details) show the registration summary. An enquiry found
                // by the duplicate check (details hidden, empty) keeps the "already registered" banner.
                if (this.isRedrawnCopy && !this.result && res.isJustRegistered) {
                    this.result = {
                        status: STATUS_CREATED,
                        caseNumber: res.caseNumber,
                        customerName: clean(this.fullName),
                        organisationName: clean(this.organisationName),
                        pincode: this.pincode,
                        fromChat: true
                    };
                    debugLog('redrawn copy: showing registration summary', this.result);
                }
                this.setDup('duplicate', res.message, res.caseNumber);
                this._dupCache = { key, state: 'duplicate', message: res.message, caseNumber: res.caseNumber };
            } else {
                this.setDup('clear');
                this._dupCache = { key, state: 'clear', message: '', caseNumber: '' };
            }
        } catch (error) {
            if (seq !== this._dupSeq) return;
            console.error('Duplicate check error: ', error);
            this.setDup('error', MSG.DUPLICATE_CHECK_FAILED);
        }
        this.publishValue();
    }

    // ---------------- Value for the chat Submit ----------------
    // Exactly the 7 fields of SafexpressBusinessEnquiryForm. The agent action finds the registration
    // by mobile + email. A form redrawn by the chat after its Submit stays silent until the customer edits it.
    publishValue() {
        if (this._silent) {
            debugLog('values shown only, nothing sent to the chat');
            return;
        }
        this._value = {
            pincode: this.pincode,
            mobileNumber: this.mobile,
            emailAddress: this.normalisedEmail,
            fullName: clean(this.fullName),
            designation: clean(this.designation),
            organisationName: clean(this.organisationName),
            messagingSessionId: this.sessionId
        };
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: { value: this._value },
                bubbles: true,
                composed: true
            })
        );
    }
}