/**
 * Booking / Pickup Request validation rules (client side).
 * MUST stay identical to BookingRequestValidator.cls.
 */

export const LIMITS = Object.freeze({
    NAME_MAX_LEN: 80,
    EMAIL_MAX_LEN: 80,
    ADDRESS_MIN_LEN: 10,
    ADDRESS_MAX_LEN: 255,
    // Weight has no business limit. Total_Weight__c is Number(16,2): up to 14 digits before the decimal point.
    PACKAGES_MAX: 10000000, // 1 crore
    MIN_KG_PER_PACKAGE: 0.05
});

export const MESSAGES = Object.freeze({
    NAME_REQUIRED: 'Kindly enter your full name.',
    NAME_INVALID: 'Kindly enter your valid full name.',
    NAME_TOO_LONG: 'Name can be at most 80 characters.',
    PHONE_REQUIRED: 'Kindly enter your 10-digit mobile number.',
    PHONE_INVALID: 'Kindly enter a valid 10-digit mobile number.',
    EMAIL_REQUIRED: 'Kindly enter your email address.',
    EMAIL_INVALID: 'Kindly enter a valid email address (like name@company.com).',
    EMAIL_BLOCKED: 'Kindly enter your own working email address.',
    PINCODE_REQUIRED: 'Kindly enter the 6-digit pincode.',
    PINCODE_INVALID: 'The pincode you have entered is not valid. Kindly enter a correct 6-digit pincode.',
    ADDRESS_REQUIRED: 'Kindly enter the pickup address.',
    ADDRESS_SHORT: 'Kindly enter the complete pickup address (house or plot, street, area).',
    ADDRESS_LONG: 'Pickup address can be at most 255 characters.',
    ADDRESS_INVALID: 'Kindly enter a valid pickup address.',
    WEIGHT_REQUIRED: 'Kindly enter the approximate weight in kg.',
    WEIGHT_INVALID: 'Kindly enter the weight in kg as a number, with up to 2 decimals (like 12.5).',
    WEIGHT_RANGE: 'Weight must be more than 0 kg.',
    PACKAGES_REQUIRED: 'Kindly enter the number of packages.',
    PACKAGES_INVALID: 'Kindly enter the number of packages as a whole number (like 3).',
    PACKAGES_RANGE: 'Number of packages must be between 1 and 1,00,00,000 (1 crore).',
    WEIGHT_PER_PACKAGE: 'The weight looks too low for this many packages. Kindly check both values.'
});

const NAME_PLACEHOLDERS = new Set([
    'test', 'testing', 'dummy', 'name', 'abc', 'xyz', 'na', 'demo', 'kuch bhi', 'naam',
    'user', 'customer', 'sample', 'none', 'null', 'unknown', 'asdf', 'qwerty', 'hello',
    'hi', 'mr', 'mrs', 'ms', 'sir', 'madam', 'no name', 'my name', 'full name'
]);
const NAME_PLACEHOLDER_WORDS = new Set(['test', 'testing', 'dummy', 'demo', 'sample', 'null', 'undefined', 'xyz', 'asdf', 'qwerty']);
const ADDRESS_PLACEHOLDERS = new Set([
    'test', 'testing', 'address', 'pickup address', 'my address', 'na', 'n/a', 'xyz', 'abc',
    'same', 'dummy', 'home', 'office', 'house', 'none', 'null', 'kuch bhi', 'pata', 'test address'
]);
const BLOCKED_EMAIL_DOMAINS = new Set([
    'example.com', 'example.in', 'test.com', 'test.in', 'abc.com', 'xyz.com', 'domain.com',
    'mailinator.com', 'yopmail.com', 'tempmail.com', '10minutemail.com', 'guerrillamail.com'
]);
const EMAIL_DOMAIN_TYPOS = Object.freeze({
    'gmial.com': 'gmail.com', 'gamil.com': 'gmail.com', 'gmai.com': 'gmail.com',
    'gmail.co': 'gmail.com', 'gmail.con': 'gmail.com', 'gmail.cm': 'gmail.com',
    'gmail.om': 'gmail.com', 'yahooo.com': 'yahoo.com', 'yaho.com': 'yahoo.com',
    'hotmial.com': 'hotmail.com', 'outlok.com': 'outlook.com'
});
const KEYBOARD_ROWS = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
const ALPHABET = 'abcdefghijklmnopqrstuvwxyz';

const NAME_CONSONANT_PAIRS = new Set((
    'bh ch dh gh jh kh ph sh th wh rh zh ' +
    'br cr dr fr gr kr pr tr vr sr mr hr wr nr ' +
    'bl cl fl gl kl pl sl ' +
    'rb rc rd rf rg rj rk rl rm rn rp rs rt rv rw rz rq rh ' +
    'lb lc ld lf lg lj lk ll lm ln lp lq ls lt lv lz lh lw ' +
    'nb nc nd ng nj nk nm nn np ns nt nv nz nh nl nr nq ' +
    'mb mp mm mn ml md mt mh ms mj mk mv mr ' +
    'sc sd sf sk sl sm sn sp sq ss st sv sw sr sj sg sb ' +
    'tm tn tt tw tl tk ts tv tr th ' +
    'dm dd dw dv dg dl dn dr dh ' +
    'kk kl kr ks kt kw kn km kh ' +
    'gd gn gg gm gw gv gr gl gh ' +
    'jj jn jd jt jv jm jr jb jp jk jh ' +
    'pp pr pl pt pn ps ph ' +
    'bb bd bj bn bs br bl bh ' +
    'vn vs vj vt vd vk vl vr vv ' +
    'hm hn hl hr hs hb hd hj hk hp ht hv hw hz hf hg hq hy ' +
    'ff fz fr fl ft fs fk ' +
    'zm zr zh zl zb zd zn zw zz ' +
    'qb qr ql qs qd qt ' +
    'ck cl cr ct cc ch ' +
    'wn wl wr wd wt ' +
    'xm xs xt'
).split(/\s+/));
const UNUSUAL_VOWEL_PAIRS = new Set(['iu', 'ue', 'eu', 'uo', 'oe']);

const ok = (value) => ({ valid: true, value, error: '' });
const fail = (error) => ({ valid: false, value: '', error });
const asText = (raw) => (raw === null || raw === undefined ? '' : String(raw));
const squash = (raw) => asText(raw).replace(/\s+/g, ' ').trim();
const isConsonant = (ch) => 'bcdfghjklmnpqrstvwxz'.includes(ch);
const isVowel = (ch) => 'aeiou'.includes(ch);

function containsRun(text, source, length) {
    const reversed = source.split('').reverse().join('');
    for (const line of [source, reversed]) {
        for (let i = 0; i + length <= line.length; i++) {
            if (text.includes(line.substring(i, i + length))) return true;
        }
    }
    return false;
}

function isWholeRun(text, source) {
    if (text.length < 3) return false;
    const reversed = source.split('').reverse().join('');
    return source.includes(text) || reversed.includes(text);
}

function gibberishScore(word) {
    let score = 0;
    for (let i = 0; i + 1 < word.length; i++) {
        const a = word[i];
        const b = word[i + 1];
        const pair = a + b;
        if (isConsonant(a) && isConsonant(b) && a !== b && !NAME_CONSONANT_PAIRS.has(pair)) {
            score++;
        } else if (isVowel(a) && isVowel(b) && UNUSUAL_VOWEL_PAIRS.has(pair)) {
            score++;
        }
    }
    return score;
}

export function validateName(raw) {
    const value = squash(raw);
    if (!value) return fail(MESSAGES.NAME_REQUIRED);
    if (value.length > LIMITS.NAME_MAX_LEN) return fail(MESSAGES.NAME_TOO_LONG);
    if (!/^[\p{L}\p{M}][\p{L}\p{M} .'-]*$/u.test(value)) return fail(MESSAGES.NAME_INVALID);
    if (/[.'-]{2,}/.test(value)) return fail(MESSAGES.NAME_INVALID);

    const lower = value.toLowerCase();
    const letters = lower.replace(/[^\p{L}\p{M}]/gu, '');
    if (letters.length < 2) return fail(MESSAGES.NAME_INVALID);
    if (/(\p{L})\1\1/u.test(lower)) return fail(MESSAGES.NAME_INVALID);

    const plain = lower.replace(/[.']/g, '').replace(/\s+/g, ' ').trim();
    if (NAME_PLACEHOLDERS.has(plain)) return fail(MESSAGES.NAME_INVALID);
    const words = lower.split(/[\s.'-]+/).filter(Boolean);
    if (words.some((w) => NAME_PLACEHOLDER_WORDS.has(w))) return fail(MESSAGES.NAME_INVALID);

    if (/^[a-z]+$/.test(letters)) {
        if (!/[aeiouy]/.test(letters)) return fail(MESSAGES.NAME_INVALID);
        if (words.some((w) => w.length >= 4 && !/[aeiouy]/.test(w))) return fail(MESSAGES.NAME_INVALID);
        if (/[bcdfghjklmnpqrstvwxz]{5,}/.test(letters)) return fail(MESSAGES.NAME_INVALID);
        if (/[aeiou]{4,}/.test(letters)) return fail(MESSAGES.NAME_INVALID);
        if (words.some((w) => /([a-z]{2,3})\1\1/.test(w))) return fail(MESSAGES.NAME_INVALID);
        if (words.some((w) => /([bcdfghjkpqtvwxz])[bcdfghjklmnpqrstvwxz]\1/.test(w))) {
            return fail(MESSAGES.NAME_INVALID);
        }
        if (isWholeRun(letters, ALPHABET) || KEYBOARD_ROWS.some((row) => isWholeRun(letters, row))) {
            return fail(MESSAGES.NAME_INVALID);
        }
        if (words.some((w) => containsRun(w, ALPHABET, 4))) return fail(MESSAGES.NAME_INVALID);
        if (words.some((w) => KEYBOARD_ROWS.some((row) => containsRun(w, row, 5)))) return fail(MESSAGES.NAME_INVALID);
        if (words.reduce((sum, w) => sum + gibberishScore(w), 0) >= 3) return fail(MESSAGES.NAME_INVALID);
        if (words.some((w) => w.length >= 6 && gibberishScore(w) >= 2)) return fail(MESSAGES.NAME_INVALID);
    }
    return ok(value);
}

export function validatePhone(raw) {
    let digits = asText(raw).trim();
    if (!digits) return fail(MESSAGES.PHONE_REQUIRED);
    digits = digits.replace(/[\s\-()]/g, '');
    if (digits.startsWith('+91')) digits = digits.substring(3);
    else if (digits.startsWith('+')) return fail(MESSAGES.PHONE_INVALID);
    else if (digits.length === 12 && digits.startsWith('91')) digits = digits.substring(2);
    if (digits.length === 11 && digits.startsWith('0')) digits = digits.substring(1);

    if (!/^[6-9]\d{9}$/.test(digits)) return fail(MESSAGES.PHONE_INVALID);
    if (/(\d)\1{4}/.test(digits)) return fail(MESSAGES.PHONE_INVALID);
    const counts = {};
    for (const d of digits) counts[d] = (counts[d] || 0) + 1;
    if (Object.values(counts).some((c) => c >= 6)) return fail(MESSAGES.PHONE_INVALID);
    if (Object.keys(counts).length <= 2) return fail(MESSAGES.PHONE_INVALID);

    let up = 1;
    let down = 1;
    for (let i = 1; i < digits.length; i++) {
        const prev = Number(digits[i - 1]);
        const cur = Number(digits[i]);
        up = cur === (prev + 1) % 10 ? up + 1 : 1;
        down = cur === (prev + 9) % 10 ? down + 1 : 1;
        if (up >= 5 || down >= 5) return fail(MESSAGES.PHONE_INVALID);
    }
    return ok(digits);
}

export function validateEmail(raw) {
    const email = asText(raw).replace(/\s+/g, '').replace(/\.+$/, '').toLowerCase();
    if (!email) return fail(MESSAGES.EMAIL_REQUIRED);
    if (email.length > LIMITS.EMAIL_MAX_LEN) return fail(MESSAGES.EMAIL_INVALID);
    const parts = email.split('@');
    if (parts.length !== 2 || !parts[0]) return fail(MESSAGES.EMAIL_INVALID);
    const [local, domain] = parts;
    if (email.includes('..')) return fail(MESSAGES.EMAIL_INVALID);
    if (!/^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*$/.test(local)) {
        return fail(MESSAGES.EMAIL_INVALID);
    }
    if (!/^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$/.test(domain)) return fail(MESSAGES.EMAIL_INVALID);
    if (BLOCKED_EMAIL_DOMAINS.has(domain)) return fail(MESSAGES.EMAIL_BLOCKED);
    if (EMAIL_DOMAIN_TYPOS[domain]) {
        return fail(`Kindly check the email address. Did you mean ${local}@${EMAIL_DOMAIN_TYPOS[domain]}?`);
    }
    return ok(email);
}

export function validatePincodeFormat(raw) {
    const pin = asText(raw).replace(/\s+/g, '');
    if (!pin) return fail(MESSAGES.PINCODE_REQUIRED);
    if (!/^[1-9]\d{5}$/.test(pin)) return fail(MESSAGES.PINCODE_INVALID);
    return ok(pin);
}

export function validateAddress(raw) {
    const address = squash(raw);
    if (!address) return fail(MESSAGES.ADDRESS_REQUIRED);
    if (address.length > LIMITS.ADDRESS_MAX_LEN) return fail(MESSAGES.ADDRESS_LONG);
    const lower = address.toLowerCase();
    if (ADDRESS_PLACEHOLDERS.has(lower.replace(/[.,]/g, '').trim())) return fail(MESSAGES.ADDRESS_INVALID);
    if (address.length < LIMITS.ADDRESS_MIN_LEN) return fail(MESSAGES.ADDRESS_SHORT);
    if (!/^[\p{L}\p{M}\d\s,./#()&'":;-]+$/u.test(address)) return fail(MESSAGES.ADDRESS_INVALID);
    if (/https?:|www\.|@/.test(lower)) return fail(MESSAGES.ADDRESS_INVALID);
    if (/(.)\1{3,}/u.test(lower)) return fail(MESSAGES.ADDRESS_INVALID);
    if (/[,./#()&'":;-]{3,}/.test(address)) return fail(MESSAGES.ADDRESS_INVALID);
    const letters = lower.replace(/[^\p{L}\p{M}]/gu, '');
    if (letters.length < 4) return fail(MESSAGES.ADDRESS_INVALID);
    if (address.split(/[\s,]+/).filter(Boolean).length < 2) return fail(MESSAGES.ADDRESS_SHORT);
    if (/^[a-z]+$/.test(letters)) {
        if (!/[aeiou]/.test(letters)) return fail(MESSAGES.ADDRESS_INVALID);
        if (KEYBOARD_ROWS.some((row) => containsRun(letters, row, 5))) return fail(MESSAGES.ADDRESS_INVALID);
        if (/([a-z]{2,3})\1\1/.test(letters)) return fail(MESSAGES.ADDRESS_INVALID);
    }
    return ok(address);
}

export function validateWeight(raw) {
    const text = asText(raw).trim();
    if (!text) return fail(MESSAGES.WEIGHT_REQUIRED);
    // Up to 14 digits before the decimal point (field limit of Total_Weight__c) and up to 2 decimals.
    if (!/^(0|[1-9]\d{0,13})(\.\d{1,2})?$/.test(text)) return fail(MESSAGES.WEIGHT_INVALID);
    if (!(Number(text) > 0)) return fail(MESSAGES.WEIGHT_RANGE);
    return ok(text);
}

export function validatePackages(raw) {
    const text = asText(raw).trim();
    if (!text) return fail(MESSAGES.PACKAGES_REQUIRED);
    if (!/^[1-9]\d*$/.test(text)) return fail(MESSAGES.PACKAGES_INVALID);
    if (text.length > 8 || Number(text) > LIMITS.PACKAGES_MAX) return fail(MESSAGES.PACKAGES_RANGE);
    return ok(text);
}

export function validateWeightPerPackage(weight, packages) {
    if (Number(weight) / Number(packages) < LIMITS.MIN_KG_PER_PACKAGE) {
        return fail(MESSAGES.WEIGHT_PER_PACKAGE);
    }
    return ok(weight);
}