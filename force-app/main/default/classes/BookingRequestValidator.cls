/**
 * Server-side validation for Booking / Pickup Requests.
 * MUST stay identical to the LWC module c/bookingValidators.
 */
public with sharing class BookingRequestValidator {

    public static final Integer NAME_MAX_LEN = 80;
    public static final Integer EMAIL_MAX_LEN = 80;
    public static final Integer ADDRESS_MIN_LEN = 10;
    public static final Integer ADDRESS_MAX_LEN = 255;
    public static final Decimal WEIGHT_MAX_KG = 50000;
    public static final Integer PACKAGES_MAX = 5000;
    public static final Decimal MIN_KG_PER_PACKAGE = 0.05;

    public class FieldResult {
        public Boolean valid;
        public String value;
        public String error;
        FieldResult(Boolean valid, String value, String error) {
            this.valid = valid;
            this.value = value;
            this.error = error;
        }
    }

    private static final Set<String> NAME_PLACEHOLDERS = new Set<String>{
        'test', 'testing', 'dummy', 'name', 'abc', 'xyz', 'na', 'demo', 'kuch bhi', 'naam',
        'user', 'customer', 'sample', 'none', 'null', 'unknown', 'asdf', 'qwerty', 'hello',
        'hi', 'mr', 'mrs', 'ms', 'sir', 'madam', 'no name', 'my name', 'full name'
    };
    private static final Set<String> NAME_PLACEHOLDER_WORDS = new Set<String>{
        'test', 'testing', 'dummy', 'demo', 'sample', 'null', 'undefined', 'xyz', 'asdf', 'qwerty'
    };
    private static final Set<String> ADDRESS_PLACEHOLDERS = new Set<String>{
        'test', 'testing', 'address', 'pickup address', 'my address', 'na', 'n/a', 'xyz', 'abc',
        'same', 'dummy', 'home', 'office', 'house', 'none', 'null', 'kuch bhi', 'pata', 'test address'
    };
    private static final Set<String> BLOCKED_EMAIL_DOMAINS = new Set<String>{
        'example.com', 'example.in', 'test.com', 'test.in', 'abc.com', 'xyz.com', 'domain.com',
        'mailinator.com', 'yopmail.com', 'tempmail.com', '10minutemail.com', 'guerrillamail.com'
    };
    private static final Map<String, String> EMAIL_DOMAIN_TYPOS = new Map<String, String>{
        'gmial.com' => 'gmail.com', 'gamil.com' => 'gmail.com', 'gmai.com' => 'gmail.com',
        'gmail.co' => 'gmail.com', 'gmail.con' => 'gmail.com', 'gmail.cm' => 'gmail.com',
        'gmail.om' => 'gmail.com', 'yahooo.com' => 'yahoo.com', 'yaho.com' => 'yahoo.com',
        'hotmial.com' => 'hotmail.com', 'outlok.com' => 'outlook.com'
    };
    private static final List<String> KEYBOARD_ROWS = new List<String>{ 'qwertyuiop', 'asdfghjkl', 'zxcvbnm' };
    private static final String ALPHABET = 'abcdefghijklmnopqrstuvwxyz';

    // Consonant pairs found in real Indian and English names. Keep in sync with JS.
    private static final Set<String> NAME_CONSONANT_PAIRS = new Set<String>((
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
    ).split('\\s+'));
    private static final Set<String> UNUSUAL_VOWEL_PAIRS = new Set<String>{ 'iu', 'ue', 'eu', 'uo', 'oe' };

    private static FieldResult ok(String value) { return new FieldResult(true, value, ''); }
    private static FieldResult fail(String error) { return new FieldResult(false, '', error); }

    private static String squash(String raw) {
        return raw == null ? '' : raw.replaceAll('\\s+', ' ').trim();
    }
    private static Boolean matches(String regex, String text) {
        return Pattern.matches(regex, text);
    }
    private static Boolean finds(String regex, String text) {
        return Pattern.compile(regex).matcher(text).find();
    }
    private static Boolean isConsonant(String ch) {
        return 'bcdfghjklmnpqrstvwxz'.contains(ch);
    }
    private static Boolean isVowel(String ch) {
        return 'aeiou'.contains(ch);
    }
    private static List<String> nonBlank(List<String> parts) {
        List<String> out = new List<String>();
        for (String p : parts) {
            if (String.isNotBlank(p)) out.add(p);
        }
        return out;
    }
    private static Boolean containsRun(String text, String source, Integer length) {
        for (String line : new List<String>{ source, source.reverse() }) {
            for (Integer i = 0; i + length <= line.length(); i++) {
                if (text.contains(line.substring(i, i + length))) return true;
            }
        }
        return false;
    }
    private static Boolean isWholeRun(String text, String source) {
        return text.length() >= 3 && (source.contains(text) || source.reverse().contains(text));
    }
    private static Integer gibberishScore(String word) {
        Integer score = 0;
        for (Integer i = 0; i + 1 < word.length(); i++) {
            String a = word.substring(i, i + 1);
            String b = word.substring(i + 1, i + 2);
            String pair = a + b;
            if (isConsonant(a) && isConsonant(b) && !a.equals(b) && !NAME_CONSONANT_PAIRS.contains(pair)) {
                score++;
            } else if (isVowel(a) && isVowel(b) && UNUSUAL_VOWEL_PAIRS.contains(pair)) {
                score++;
            }
        }
        return score;
    }

    // ---------------- NAME
    public static FieldResult validateName(String raw) {
        String value = squash(raw);
        if (String.isBlank(value)) return fail('Kindly enter your full name.');
        if (value.length() > NAME_MAX_LEN) return fail('Name can be at most 80 characters.');

        String invalid = 'Kindly enter your valid full name.';
        if (!matches('^[\\p{L}\\p{M}][\\p{L}\\p{M} .\'\\-]*$', value)) return fail(invalid);
        if (finds('[.\'\\-]{2,}', value)) return fail(invalid);

        String lower = value.toLowerCase();
        String letters = lower.replaceAll('[^\\p{L}\\p{M}]', '');
        if (letters.length() < 2) return fail(invalid);
        if (finds('(\\p{L})\\1\\1', lower)) return fail(invalid);

        String plain = lower.replaceAll('[.\']', '').replaceAll('\\s+', ' ').trim();
        if (NAME_PLACEHOLDERS.contains(plain)) return fail(invalid);
        List<String> words = nonBlank(lower.split('[\\s.\'\\-]+'));
        for (String w : words) {
            if (NAME_PLACEHOLDER_WORDS.contains(w)) return fail(invalid);
        }

        if (matches('^[a-z]+$', letters)) {
            if (!finds('[aeiouy]', letters)) return fail(invalid);
            if (finds('[bcdfghjklmnpqrstvwxz]{5,}', letters)) return fail(invalid);
            if (finds('[aeiou]{4,}', letters)) return fail(invalid);
            if (isWholeRun(letters, ALPHABET)) return fail(invalid);
            for (String row : KEYBOARD_ROWS) {
                if (isWholeRun(letters, row)) return fail(invalid);
            }
            Integer totalScore = 0;
            for (String w : words) {
                if (w.length() >= 4 && !finds('[aeiouy]', w)) return fail(invalid);
                if (finds('([a-z]{2,3})\\1\\1', w)) return fail(invalid);
                if (finds('([bcdfghjkpqtvwxz])[bcdfghjklmnpqrstvwxz]\\1', w)) return fail(invalid);
                if (containsRun(w, ALPHABET, 4)) return fail(invalid);
                for (String row : KEYBOARD_ROWS) {
                    if (containsRun(w, row, 5)) return fail(invalid);
                }
                Integer score = gibberishScore(w);
                if (w.length() >= 6 && score >= 2) return fail(invalid);
                totalScore += score;
            }
            if (totalScore >= 3) return fail(invalid);
        }
        return ok(value);
    }

    // ---------------- MOBILE
    public static FieldResult validatePhone(String raw) {
        String invalid = 'Kindly enter a valid 10-digit mobile number.';
        String digits = raw == null ? '' : raw.trim();
        if (String.isBlank(digits)) return fail('Kindly enter your 10-digit mobile number.');

        digits = digits.replaceAll('[\\s\\-()]', '');
        if (digits.startsWith('+91')) {
            digits = digits.substring(3);
        } else if (digits.startsWith('+')) {
            return fail(invalid);
        } else if (digits.length() == 12 && digits.startsWith('91')) {
            digits = digits.substring(2);
        }
        if (digits.length() == 11 && digits.startsWith('0')) digits = digits.substring(1);

        if (!matches('^[6-9]\\d{9}$', digits)) return fail(invalid);
        if (finds('(\\d)\\1{4}', digits)) return fail(invalid);

        Map<String, Integer> counts = new Map<String, Integer>();
        for (Integer i = 0; i < digits.length(); i++) {
            String d = digits.substring(i, i + 1);
            counts.put(d, (counts.containsKey(d) ? counts.get(d) : 0) + 1);
        }
        for (Integer c : counts.values()) {
            if (c >= 6) return fail(invalid);
        }
        if (counts.size() <= 2) return fail(invalid);

        Integer up = 1;
        Integer down = 1;
        for (Integer i = 1; i < digits.length(); i++) {
            Integer prev = Integer.valueOf(digits.substring(i - 1, i));
            Integer cur = Integer.valueOf(digits.substring(i, i + 1));
            up = cur == Math.mod(prev + 1, 10) ? up + 1 : 1;
            down = cur == Math.mod(prev + 9, 10) ? down + 1 : 1;
            if (up >= 5 || down >= 5) return fail(invalid);
        }
        return ok(digits);
    }

    // ---------------- EMAIL
    public static FieldResult validateEmail(String raw) {
        String invalid = 'Kindly enter a valid email address (like name@company.com).';
        String email = raw == null ? '' : raw.replaceAll('\\s+', '').replaceAll('\\.+$', '').toLowerCase();
        if (String.isBlank(email)) return fail('Kindly enter your email address.');
        if (email.length() > EMAIL_MAX_LEN) return fail(invalid);

        if (email.countMatches('@') != 1 || email.startsWith('@')) return fail(invalid);
        String local = email.substringBefore('@');
        String domain = email.substringAfter('@');

        if (email.contains('..')) return fail(invalid);
        if (!matches('^[a-z0-9!#$%&\'*+/=?^_`{|}~\\-]+(\\.[a-z0-9!#$%&\'*+/=?^_`{|}~\\-]+)*$', local)) return fail(invalid);
        if (!matches('^([a-z0-9]([a-z0-9\\-]*[a-z0-9])?\\.)+[a-z]{2,}$', domain)) return fail(invalid);

        if (BLOCKED_EMAIL_DOMAINS.contains(domain)) return fail('Kindly enter your own working email address.');
        if (EMAIL_DOMAIN_TYPOS.containsKey(domain)) {
            return fail('Kindly check the email address. Did you mean ' + local + '@' + EMAIL_DOMAIN_TYPOS.get(domain) + '?');
        }
        return ok(email);
    }

    // ---------------- PINCODE (format only)
    public static FieldResult validatePincodeFormat(String raw) {
        String pin = raw == null ? '' : raw.replaceAll('\\s+', '');
        if (String.isBlank(pin)) return fail('Kindly enter the 6-digit pincode.');
        if (!matches('^[1-9]\\d{5}$', pin)) {
            return fail('The pincode you have entered is not valid. Kindly enter a correct 6-digit pincode.');
        }
        return ok(pin);
    }

    // ---------------- PICKUP ADDRESS
    public static FieldResult validateAddress(String raw) {
        String invalid = 'Kindly enter a valid pickup address.';
        String tooShort = 'Kindly enter the complete pickup address (house or plot, street, area).';
        String address = squash(raw);
        if (String.isBlank(address)) return fail('Kindly enter the pickup address.');
        if (address.length() > ADDRESS_MAX_LEN) return fail('Pickup address can be at most 255 characters.');

        String lower = address.toLowerCase();
        if (ADDRESS_PLACEHOLDERS.contains(lower.replaceAll('[.,]', '').trim())) return fail(invalid);
        if (address.length() < ADDRESS_MIN_LEN) return fail(tooShort);

        if (!matches('^[\\p{L}\\p{M}\\d\\s,./#()&\'":;\\-]+$', address)) return fail(invalid);
        if (finds('https?:|www\\.|@', lower)) return fail(invalid);
        if (finds('(.)\\1{3,}', lower)) return fail(invalid);
        if (finds('[,./#()&\'":;\\-]{3,}', address)) return fail(invalid);

        String letters = lower.replaceAll('[^\\p{L}\\p{M}]', '');
        if (letters.length() < 4) return fail(invalid);
        if (nonBlank(address.split('[\\s,]+')).size() < 2) return fail(tooShort);

        if (matches('^[a-z]+$', letters)) {
            if (!finds('[aeiou]', letters)) return fail(invalid);
            for (String row : KEYBOARD_ROWS) {
                if (containsRun(letters, row, 5)) return fail(invalid);
            }
            if (finds('([a-z]{2,3})\\1\\1', letters)) return fail(invalid);
        }
        return ok(address);
    }

    // ---------------- WEIGHT AND PACKAGES
    public static FieldResult validateWeight(String raw) {
        String text = raw == null ? '' : raw.trim();
        if (String.isBlank(text)) return fail('Kindly enter the approximate weight in kg.');
        if (!matches('^(0|[1-9]\\d{0,6})(\\.\\d{1,2})?$', text)) {
            return fail('Kindly enter the weight in kg as a number, with up to 2 decimals (like 12.5).');
        }
        Decimal kg = Decimal.valueOf(text);
        if (kg <= 0 || kg > WEIGHT_MAX_KG) return fail('Weight must be more than 0 and at most 50,000 kg.');
        return ok(text);
    }

    public static FieldResult validatePackages(String raw) {
        String text = raw == null ? '' : raw.trim();
        if (String.isBlank(text)) return fail('Kindly enter the number of packages.');
        if (!matches('^[1-9]\\d{0,4}$', text)) {
            return fail('Kindly enter the number of packages as a whole number (like 3).');
        }
        if (Integer.valueOf(text) > PACKAGES_MAX) return fail('Number of packages must be between 1 and 5,000.');
        return ok(text);
    }

    public static FieldResult validateWeightPerPackage(String weight, String packages) {
        if (Decimal.valueOf(weight) / Integer.valueOf(packages) < MIN_KG_PER_PACKAGE) {
            return fail('The weight looks too low for this many packages. Kindly check both values.');
        }
        return ok(weight);
    }
}