import { LightningElement, api } from 'lwc';
import lookupPincode from '@salesforce/apex/PincodeLookupService.lookupPincode';
import submitBooking from '@salesforce/apex/SafexpressBookingRequestService.submitBooking';
import findJustRegistered from '@salesforce/apex/SafexpressBookingRequestService.findJustRegistered';
import SFX_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';
import IOS_BADGE from '@salesforce/resourceUrl/IosStoreLogo';      // App Store badge
import ANDROID_BADGE from '@salesforce/resourceUrl/AppStoreLogo';  // Google Play badge
import {
    validateAddress, validateWeight, validatePackages, validateWeightPerPackage
} from 'c/bookingValidators';

const COMPONENT_VERSION = 'bk-v6-address-input';
const DEBUG = true; // set to false before go-live

const STATUS_CREATED = 'CREATED';

// =====================================================================
// COMMON VALIDATION (name, mobile, email, pincode) - identical to SafexpressBusinessEnquiryValidator.cls
// and to sfxBusinessEnquiryForm.js. Address / weight / packages come from c/bookingValidators.
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
    NAME_INVALID: 'Please enter your real full name.'

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

// ---------- Name ----------
const KEYBOARD_RUNS = ['qwert', 'werty', 'asdfg', 'sdfgh', 'zxcvb', 'xcvbn', 'yuiop', 'hjkl', 'qazwsx'];
const BLOCKED_NAME_WORDS = [
    'test', 'testing', 'tester', 'dummy', 'fake', 'sample', 'demo', 'name', 'fullname', 'myname',
    'xyz', 'abc', 'abcd', 'na', 'nil', 'none', 'null', 'user', 'customer', 'admin', 'unknown',
    'asdf', 'qwerty', 'anonymous', 'guest', 'nobody'
];
const NAME_KEYBOARD_RUNS = ['asdf', 'qwer', 'zxcv', 'hjkl', 'abcde'];

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

// ---------- Booking form ----------
// Exactly the 8 fields of the Lightning type bookingRequestForm (BookingRequestFormAction.BookingForm)
const FIELDS = ['name', 'mobileNumber', 'email', 'pickupPincode', 'pickupAddress', 'deliveryPincode', 'approxWeight', 'packageCount'];
const PIN_FIELDS = ['pickupPincode', 'deliveryPincode'];
const LOOKUP_DELAY_MS = 350;
const PINCODE_CHECK_FAILED = 'We could not check this pincode right now. Please try again.';
const SUBMIT_FAILED = 'We could not register your pickup request right now. Please try again in a few minutes.';
const EMPTY_PLACEHOLDERS = ['null', 'undefined', 'none', 'n/a', '-'];

const IOS_APP_URL = 'https://apps.apple.com/in/app/safexpress-app/id6797861161';
const ANDROID_APP_URL = 'https://play.google.com/store/apps/details?id=com.safexpress.enterprise';

function debugLog(...args) {
    if (!DEBUG) return;
    // eslint-disable-next-line no-console
    console.info('[sfxBKF]', COMPONENT_VERSION, ...args);
}

function parseIncoming(val) {
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

function text(v) {
    const s = v === null || v === undefined ? '' : String(v).trim();
    return EMPTY_PLACEHOLDERS.includes(s.toLowerCase()) || s.includes('{!') ? '' : s;
}

// =====================================================================
// COMPONENT
// =====================================================================
export default class BookingRequestForm extends LightningElement {
    @api configuration;
    @api readOnly = false; // kept for compatibility; the form manages its own state

    // Lightning Type editor value - sent to the agent action when the customer clicks the chat Submit.
    // After the chat Submit the chat redraws this form and passes the submitted values back in here:
    // the copy keeps them on screen, stays silent until the customer edits, and shows the registration
    // summary when these exact details were registered a moment ago.
    _value = {};
    @api
    get value() {
        return this._value;
    }
    set value(val) {
        debugLog('value received', val);
        let incoming = parseIncoming(val);
        if (!incoming) return;
        if (incoming.booking_form || incoming.bookingForm) {
            incoming = parseIncoming(incoming.booking_form || incoming.bookingForm) || incoming;
        }
        const fromForm = FIELDS.some((f) => Object.prototype.hasOwnProperty.call(incoming, f));
        const fields = {};
        FIELDS.forEach((f) => {
            fields[f] = text(incoming[f]);
        });
        this._value = fields; // exactly the 8 fields

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

    form = {
        name: '', mobileNumber: '', email: '', pickupPincode: '', pickupAddress: '',
        deliveryPincode: '', approxWeight: '', packageCount: ''
    };
    touched = {};

    // Pincode lookups: idle | checking | serviceable | not_serviceable | error
    pins = { pickupPincode: { state: 'idle' }, deliveryPincode: { state: 'idle' } };
    _pinSeq = { pickupPincode: 0, deliveryPincode: 0 };
    _pinTimers = {};

    isSubmitting = false;
    submitError = '';
    result = null; // { status, caseNumber, customerName, pickup..., delivery..., approxWeight, packageCount, fromChat }

    _userEdited = false;
    _silent = false;
    _chatSubmitted = false;
    _connected = false;
    _pendingRestore = false;
    _justRegisteredChecked = false;

    connectedCallback() {
        this._connected = true;
        debugLog('form opened');
        if (this._pendingRestore) this.runRestoreLookups();
    }

    disconnectedCallback() {
        this._connected = false;
        Object.values(this._pinTimers).forEach((t) => clearTimeout(t));
    }

    // ---------------- Keep the customer's entries after the chat Submit ----------------
    restoreFromValue(v) {
        const next = {};
        FIELDS.forEach((f) => {
            next[f] = this.sanitise(f, v[f] || '');
        });
        if (FIELDS.every((f) => !next[f])) return;
        if (FIELDS.every((f) => next[f] === this.form[f])) return;

        this.form = next;
        const touched = {};
        FIELDS.forEach((f) => {
            touched[f] = true;
        });
        this.touched = touched;
        this._justRegisteredChecked = false;

        if (this._connected) {
            this.runRestoreLookups();
        } else {
            this._pendingRestore = true;
        }
    }

    runRestoreLookups() {
        this._pendingRestore = false;
        PIN_FIELDS.forEach((f) => this.schedulePinLookup(f, 0));
    }

    // True only for the untouched copy the chat redraws after its Submit
    get isRedrawnCopy() {
        return this._chatSubmitted && this._silent && !this._userEdited;
    }

    // The redrawn copy shows the registration summary when these exact details were registered a moment ago
    async checkJustRegistered() {
        if (!this.isRedrawnCopy || this.result || this._justRegisteredChecked || !this.isReady) return;
        this._justRegisteredChecked = true;
        try {
            const res = await findJustRegistered({
                mobileNumber: this.mobile,
                email: this.normalisedEmail,
                pickupPincode: this.form.pickupPincode,
                deliveryPincode: this.form.deliveryPincode,
                approxWeight: this.form.approxWeight.trim(),
                packageCount: this.form.packageCount.trim()
            });
            if (res && res.found && this.isRedrawnCopy && !this.result) {
                this.result = {
                    status: STATUS_CREATED,
                    caseNumber: res.caseNumber,
                    customerName: clean(this.form.name),
                    pickupPincode: this.form.pickupPincode,
                    deliveryPincode: this.form.deliveryPincode,
                    approxWeight: this.form.approxWeight.trim(),
                    packageCount: this.form.packageCount.trim(),
                    fromChat: true
                };
                debugLog('redrawn copy: showing registration summary', this.result);
            }
        } catch (error) {
            console.error('findJustRegistered error: ', error);
        }
    }

    // ---------------- Field checks ----------------
    get mobile() {
        return this.form.mobileNumber;
    }
    get normalisedEmail() {
        return (this.form.email || '').trim().toLowerCase();
    }

    // The message for a field, or '' when it is fine (pincode service problems included)
    problemFor(field) {
        const v = this.form[field];
        switch (field) {
            case 'name':
                return nameRejectionReason(v);
            case 'mobileNumber':
                return mobileRejectionReason(v);
            case 'email':
                return emailRejectionReason(v);
            case 'pickupPincode':
            case 'deliveryPincode': {
                const fmt = pincodeRejectionReason(v);
                if (fmt) return fmt;
                const state = this.pins[field].state;
                if (state === 'not_serviceable') return MSG.PINCODE_NOT_SERVICEABLE;
                if (state === 'error') return PINCODE_CHECK_FAILED;
                return '';
            }
            case 'pickupAddress':
                return validateAddress(v).error || '';
            case 'approxWeight': {
                const w = validateWeight(v);
                if (!w.valid) return w.error;
                const p = validatePackages(this.form.packageCount);
                if (p.valid) {
                    const per = validateWeightPerPackage(w.value, p.value);
                    if (!per.valid) return per.error;
                }
                return '';
            }
            case 'packageCount':
                return validatePackages(v).error || '';
            default:
                return '';
        }
    }

    isFieldOk(field) {
        if (this.problemFor(field)) return false;
        return PIN_FIELDS.includes(field) ? this.pins[field].state === 'serviceable' : true;
    }

    errorFor(field) {
        const problem = this.problemFor(field);
        if (!problem) return '';
        if (PIN_FIELDS.includes(field)) {
            const state = this.pins[field].state;
            if (state === 'not_serviceable' || state === 'error') return problem; // show at once
            return this.touched[field] || this.form[field].length === 6 ? problem : '';
        }
        if (field === 'mobileNumber' && !this.touched[field] && this.form[field].length < 10) return '';
        if (field === 'email' && EMAIL_INSTANT_MESSAGES.includes(problem)) return problem;
        return this.touched[field] ? problem : '';
    }

    get isReady() {
        return FIELDS.every((f) => this.isFieldOk(f));
    }

    // ---------------- View: errors, ticks, classes ----------------
    get nameError() { return this.errorFor('name'); }
    get mobileError() { return this.errorFor('mobileNumber'); }
    get emailError() { return this.errorFor('email'); }
    get pickupPincodeError() { return this.errorFor('pickupPincode'); }
    get pickupAddressError() { return this.errorFor('pickupAddress'); }
    get deliveryPincodeError() { return this.errorFor('deliveryPincode'); }
    get weightError() { return this.errorFor('approxWeight'); }
    get packagesError() { return this.errorFor('packageCount'); }

    get isNameOk() { return this.isFieldOk('name'); }
    get isMobileOk() { return this.isFieldOk('mobileNumber'); }
    get isEmailOk() { return this.isFieldOk('email'); }
    get isPickupPincodeOk() { return this.isFieldOk('pickupPincode'); }
    get isPickupAddressOk() { return this.isFieldOk('pickupAddress'); }
    get isDeliveryPincodeOk() { return this.isFieldOk('deliveryPincode'); }
    get isWeightOk() { return this.isFieldOk('approxWeight'); }
    get isPackagesOk() { return this.isFieldOk('packageCount'); }

    inputClass(field) {
        if (this.errorFor(field)) return 'sfx-input has-error';
        return this.isFieldOk(field) ? 'sfx-input is-valid' : 'sfx-input';
    }
    get nameInputClass() { return this.inputClass('name'); }
    get mobileInputClass() { return this.inputClass('mobileNumber'); }
    get emailInputClass() { return this.inputClass('email'); }
    get pickupPincodeInputClass() { return this.inputClass('pickupPincode'); }
    get pickupAddressInputClass() { return this.inputClass('pickupAddress'); }
    get deliveryPincodeInputClass() { return this.inputClass('deliveryPincode'); }
    get weightInputClass() { return this.inputClass('approxWeight'); }
    get packagesInputClass() { return this.inputClass('packageCount'); }

    stepClass(field, last) {
        let cls = 'sfx-step';
        if (this.isFieldOk(field)) cls += ' is-done';
        else if (this.errorFor(field)) cls += ' is-error';
        if (last) cls += ' is-last';
        return cls;
    }
    get pickupPincodeStepClass() { return this.stepClass('pickupPincode', false); }
    get pickupAddressStepClass() { return this.stepClass('pickupAddress', false); }
    get deliveryPincodeStepClass() { return this.stepClass('deliveryPincode', true); }

    pinView(field) {
        const pin = this.pins[field];
        const showDistrict = pin.district && pin.district.toLowerCase() !== (pin.city || '').toLowerCase();
        return {
            checking: pin.state === 'checking',
            found: pin.state === 'serviceable',
            city: (pin.city || pin.district || '').toUpperCase(),
            area: [showDistrict ? pin.district : null, pin.state === 'serviceable' ? pin.stateName : null]
                .filter(Boolean).join(', ')
        };
    }
    get pickupPin() { return this.pinView('pickupPincode'); }
    get deliveryPin() { return this.pinView('deliveryPincode'); }

    // ---------------- Progress ----------------
    get completedCount() {
        return FIELDS.filter((f) => this.isFieldOk(f)).length;
    }
    get progressText() {
        return `${this.completedCount} of ${FIELDS.length} completed`;
    }
    get progressStyle() {
        return `width: ${Math.round((this.completedCount / FIELDS.length) * 100)}%;`;
    }

    // ---------------- Submit Request ----------------
    get isSubmitDisabled() {
        return this.isSubmitting || !this.isReady;
    }
    get submitLabel() {
        return this.isSubmitting ? 'Submitting…' : 'Submit Request';
    }

    async handleSubmitRequest() {
        this.submitError = '';
        const touched = {};
        FIELDS.forEach((f) => {
            touched[f] = true;
        });
        this.touched = touched;
        if (!this.isReady || this.isSubmitting) return;

        this.isSubmitting = true;
        try {
            const res = await submitBooking({
                name: clean(this.form.name),
                mobileNumber: this.mobile,
                email: this.normalisedEmail,
                pickupPincode: this.form.pickupPincode,
                deliveryPincode: this.form.deliveryPincode,
                pickupAddress: clean(this.form.pickupAddress),
                approxWeight: this.form.approxWeight.trim(),
                packageCount: this.form.packageCount.trim(),
                messagingSessionId: this.sessionId
            });
            debugLog('submitBooking result', res);

            if (res && res.status === STATUS_CREATED) {
                this.result = { ...res, fromChat: false };
                this._silent = false;
                this.publishValue();
                this.notifyChatIfNeeded();
            } else {
                this.submitError = (res && res.message) || SUBMIT_FAILED;
            }
        } catch (error) {
            console.error('Submit booking error: ', error);
            this.submitError = SUBMIT_FAILED;
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
        try {
            util.sendTextMessage(`I have submitted the pickup request form. Reference No. ${this.result.caseNumber}.`);
        } catch (error) {
            console.error('sendTextMessage error: ', error);
        }
    }

    // ---------------- Result view ----------------
    get hasResult() {
        return !!this.result;
    }
    get resultNote() {
        if (this.result?.fromChat) return '✅ Your pickup request is registered.';
        return this._chatSubmitted
            ? '✅ Your pickup request is logged. I will confirm it in the chat.'
            : '✅ Your pickup request is logged. Please click Submit below to confirm.';
    }
    get resultHeadline() {
        return `Your pickup request has been registered. Case #${this.result?.caseNumber || ''} created.`;
    }
    get resultCaseNumber() {
        return this.result?.caseNumber || '';
    }
    get resultName() {
        return this.result?.customerName || clean(this.form.name) || '-';
    }
    placeLabel(location, pin, field) {
        const fromPin = this.pins[field];
        const place = location || [fromPin.city, fromPin.stateName].filter(Boolean).join(', ');
        return place ? `${place} - ${pin}` : pin || '-';
    }
    get resultPickup() {
        return this.placeLabel(this.result?.pickupLocation, this.result?.pickupPincode || this.form.pickupPincode, 'pickupPincode');
    }
    get resultDelivery() {
        return this.placeLabel(this.result?.deliveryLocation, this.result?.deliveryPincode || this.form.deliveryPincode, 'deliveryPincode');
    }
    get resultWeight() {
        const w = this.result?.approxWeight || this.form.approxWeight;
        return w ? `${w} kg` : '-';
    }
    get resultPackages() {
        return this.result?.packageCount || this.form.packageCount || '-';
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
        if (val === this.form[field]) return;

        this._userEdited = true;
        this._silent = false;
        this.submitError = '';
        this.form = { ...this.form, [field]: val };

        if (PIN_FIELDS.includes(field)) {
            this._pinSeq[field] += 1;
            this.pins = { ...this.pins, [field]: { state: 'idle' } };
            this.schedulePinLookup(field, LOOKUP_DELAY_MS);
        }
        this.publishValue();
    }

    handleBlur(event) {
        const field = event.target.dataset.field;
        this.touched = { ...this.touched, [field]: true };
    }

    sanitise(field, raw) {
        const s = raw === null || raw === undefined ? '' : String(raw);
        switch (field) {
            case 'pickupPincode':
            case 'deliveryPincode':
                return s.replace(/\D/g, '').slice(0, 6);
            case 'mobileNumber':
                return toMobileDigits(s);
            case 'email':
                return s;
            case 'name':
                return s.replace(/[^A-Za-z .'-]/g, '').replace(/\s{2,}/g, ' ').replace(/^\s+/, '').slice(0, 80);
            case 'approxWeight':
                return s.replace(/[^\d.]/g, '').replace(/(\..*)\./g, '$1').slice(0, 17);
            case 'packageCount':
                return s.replace(/\D/g, '').slice(0, 8);
            case 'pickupAddress':
                return s.replace(/\s{2,}/g, ' ').replace(/^\s+/, '').slice(0, 255);
            default:
                return s;
        }
    }

    // ---------------- Pincode lookups ----------------
    schedulePinLookup(field, delay) {
        clearTimeout(this._pinTimers[field]);
        const pin = this.form[field];
        if (pin.length !== 6 || pincodeRejectionReason(pin)) return;
        const seq = this._pinSeq[field];
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._pinTimers[field] = setTimeout(() => this.lookupPin(field, pin, seq), delay);
    }

    async lookupPin(field, pin, seq) {
        this.pins = { ...this.pins, [field]: { state: 'checking' } };
        let next;
        try {
            const res = await lookupPincode({ pincode: pin });
            if (res && res.status === 'SERVICEABLE') {
                next = { state: 'serviceable', city: res.city, district: res.district, stateName: res.state };
            } else if (res && res.status === 'NOT_SERVICEABLE') {
                next = { state: 'not_serviceable' };
            } else {
                next = { state: 'error' };
            }
        } catch (error) {
            console.error('Pincode check error: ', error);
            next = { state: 'error' };
        }
        if (seq !== this._pinSeq[field] || this.form[field] !== pin) return; // customer changed it meanwhile
        this.pins = { ...this.pins, [field]: next };
        this.touched = { ...this.touched, [field]: true };
        this.publishValue();
        this.checkJustRegistered();
    }

    // ---------------- Value for the chat Submit ----------------
    // Exactly the 8 fields of BookingRequestFormAction.BookingForm. The agent action finds the registration
    // by these details. A copy redrawn by the chat after its Submit stays silent until the customer edits it.
    publishValue() {
        if (this._silent) {
            debugLog('values shown only, nothing sent to the chat');
            return;
        }
        this._value = {
            name: clean(this.form.name),
            mobileNumber: this.mobile,
            email: this.normalisedEmail,
            pickupPincode: this.form.pickupPincode,
            deliveryPincode: this.form.deliveryPincode,
            pickupAddress: clean(this.form.pickupAddress),
            approxWeight: this.form.approxWeight.trim(),
            packageCount: this.form.packageCount.trim()
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