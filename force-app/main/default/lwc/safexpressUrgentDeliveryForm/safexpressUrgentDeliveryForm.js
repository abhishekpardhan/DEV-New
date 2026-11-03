import { LightningElement, api } from 'lwc';
import submitRequest from '@salesforce/apex/SafexpressUrgentDeliveryController.submitRequest';
import checkExistingCase from '@salesforce/apex/SafexpressUrgentDeliveryController.checkExistingCase';
import SFX_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';
// New static resource names for the footer
import IOS_BADGE from '@salesforce/resourceUrl/IosStoreLogo';
import ANDROID_BADGE from '@salesforce/resourceUrl/AppStoreLogo';

const SAFEXPRESS_VARIANTS = ['safexpres', 'safeexpres', 'safexprs'];
const BLOCKED_EMAIL_NAMES = ['test', 'testing', 'tester', 'testuser', 'testmail', 'dummy', 'fake', 'sample', 'demo', 'abc', 'abcd', 'abcde', 'xyz', 'asdf', 'qwerty', 'user', 'admin', 'example', 'temp', 'none', 'null', 'na', 'nil', 'xxx', 'aaa', 'name', 'email', 'mail', 'noreply', 'noemail'];
const BLOCKED_EMAIL_NAME_PREFIXES = ['dummy', 'fake', 'asdf', 'qwert', 'zxcv'];
const BLOCKED_DOMAIN_WORDS = ['test', 'testmail', 'testing', 'example', 'sample', 'dummy', 'fake', 'fakemail', 'abc', 'xyz', 'temp', 'tempmail', 'domain', 'email', 'mailinator', 'yopmail', 'guerrillamail', 'trashmail', 'throwaway', 'throwawaymail', 'getnada', 'sharklasers', 'dispostable', 'maildrop', 'mintemail', 'mohmal', 'emailondeck', 'spamgourmet', 'discard', 'discardmail'];
const DISPOSABLE_DOMAIN_PARTS = ['mailinator', 'yopmail', 'tempmail', 'guerrillamail', 'trashmail', 'fakemail', 'throwaway', 'disposable', '10minute'];
const KEYBOARD_RUNS = ['qwert', 'werty', 'asdfg', 'sdfgh', 'zxcvb', 'xcvbn', 'yuiop', 'hjkl', 'qazwsx'];

const INVALID_DOMAINS = ['gmai.com', 'gamil.com', 'yhoo.com', 'hotmai.com', 'outlok.com', 'yahmail.com'];
const PROFANITY = ['fuck', 'shit', 'bitch', 'asshole', 'dick', 'cunt', 'bastard', 'slut', 'whore', 'porn', 'scam', 'spam'];

const MSG_EMAIL_REQUIRED = 'Email ID is required.';
const MSG_EMAIL_FORMAT = 'Please enter a valid email address.';
const MSG_EMAIL_DOMAIN_DIGITS = 'The email domain cannot contain numbers.';
const MSG_EMAIL_TOO_MANY_DIGITS = 'Email name can contain at most 2 numbers.';
const MSG_EMAIL_TEST = 'Test or dummy emails are not accepted. Please enter your real email address.';
const MSG_EMAIL_RANDOM = "This email address doesn't look valid. Please enter a real email address.";
const MSG_EMAIL_SAFEXPRESS = "Safexpress emails can't be used. Please enter a personal or company email.";

function looksRandom(letters) {
    if (!letters) return false;
    if (/(.)\1{3,}/.test(letters)) return true;
    if (/(..+?)\1{2,}/.test(letters)) return true;
    if (/[bcdfghjklmnpqrstvwxz]{5,}/.test(letters)) return true;
    return KEYBOARD_RUNS.some((run) => letters.includes(run));
}

function emailRejectionReason(rawEmail) {
    const e = (rawEmail || '').trim().toLowerCase();
    if (!e) return MSG_EMAIL_REQUIRED;
    const compact = e.replace(/[^a-z0-9]/g, '');
    if (SAFEXPRESS_VARIANTS.some((v) => compact.includes(v))) return MSG_EMAIL_SAFEXPRESS;

    const parts = e.split('@');
    if (parts.length !== 2) return MSG_EMAIL_FORMAT;
    const [local, domain] = parts;

    if (!/^[a-z][a-z0-9.]{1,38}[a-z0-9]$/.test(local) || local.includes('..')) return MSG_EMAIL_FORMAT;
    if (/[0-9]/.test(domain)) return MSG_EMAIL_DOMAIN_DIGITS;
    if (!/^[a-z]+(-[a-z]+)*(\.[a-z]+(-[a-z]+)*)*\.[a-z]{2,6}$/.test(domain)) return MSG_EMAIL_FORMAT;

    if (INVALID_DOMAINS.includes(domain)) return 'Please check the email domain for typos.';
    if (PROFANITY.some((word) => local.includes(word))) return 'Please provide a valid and appropriate email address.';

    if ((local.match(/[0-9]/g) || []).length > 2) return MSG_EMAIL_TOO_MANY_DIGITS;
    
    if (/(.)\1{2,}/.test(local)) return MSG_EMAIL_RANDOM;
    if (/(.{2,})\1{2,}/.test(local)) return MSG_EMAIL_RANDOM;

    const letters = local.replace(/[^a-z]/g, '');
    if (letters.length < 3) return MSG_EMAIL_RANDOM;

    if (BLOCKED_EMAIL_NAMES.includes(letters)) return MSG_EMAIL_TEST;
    if (BLOCKED_EMAIL_NAME_PREFIXES.some((p) => letters.startsWith(p))) return MSG_EMAIL_TEST;

    const nameLabels = domain.split('.').slice(0, -1);
    if (nameLabels.some((label) => BLOCKED_DOMAIN_WORDS.includes(label.replace(/-/g, '')))) return MSG_EMAIL_TEST;
    if (DISPOSABLE_DOMAIN_PARTS.some((p) => domain.includes(p))) return MSG_EMAIL_TEST;

    if (local.split('.').some((seg) => looksRandom(seg.replace(/[^a-z]/g, '')))) return MSG_EMAIL_RANDOM;
    if (letters.length >= 5 && !/[aeiouy]/.test(letters)) return MSG_EMAIL_RANDOM;

    if (nameLabels.some((label) => label.split('-').some((piece) => looksRandom(piece)))) return MSG_EMAIL_RANDOM;
    return '';
}

const MAX_INSTRUCTIONS = 2000;

export default class SafexpressUrgentDeliveryForm extends LightningElement {
    @api configuration;

    _value = {};
    _statusChecked = false;
    _waybillInitialized = false;

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        if (!val) return;
        this._value = val;
        
        if (val.shipmentStatus && !this._statusChecked) {
            this._statusChecked = true;
            const status = val.shipmentStatus.toUpperCase();
            
            if (!status.includes('TRANSIT') && !status.includes('ARRIVED')) {
                this.result = {
                    outcome: 'NOT_ELIGIBLE',
                    message: `Urgent delivery cannot be raised because the current shipment status is ${val.shipmentStatus}.`
                };
                this.publishValue(this.result);
                return;
            }
        }
        
        if (val.waybillNumber && !this._waybillInitialized) {
            this.waybill = val.waybillNumber.replace(/[^\d]/g, '');
            this.touched.waybill = true;
            this._waybillInitialized = true;
            
            if (this.isWaybillValid) {
                this.runInitialDeduplicationCheck();
            }
        }
    }

    logoUrl = SFX_LOGO;
    iosBadgeUrl = IOS_BADGE;
    androidBadgeUrl = ANDROID_BADGE;
    iosAppUrl = 'https://apps.apple.com/in/app/safexpress-app/id6797861161';
    androidAppUrl = 'https://play.google.com/store/apps/details?id=com.safexpress.enterprise';

    waybill = '';
    mobile = '';
    email = '';
    instructions = '';
    touched = { waybill: false, mobile: false, email: false, instructions: false };

    lastCheckedWaybill = ''; 
    isCheckingDuplicate = false;
    isSubmitting = false;
    progressText = '';
    errorMessage = '';
    result = null;

    get waybillDigits() { return (this.waybill || '').replace(/\s/g, ''); }
    get isWaybillValid() { return /^\d{12}$/.test(this.waybillDigits); }
    get isMobileValid() {
        const m = this.mobile || '';
        return /^[6-9]\d{9}$/.test(m) && !/^(\d)\1{9}$/.test(m);
    }
    get emailProblem() { return emailRejectionReason(this.email); }
    get isEmailValid() { return !this.emailProblem; }
    get instructionsLength() { return (this.instructions || '').length; }
    get isInstructionsValid() { return this.instructionsLength <= MAX_INSTRUCTIONS; }

    get waybillError() {
        if (!this.touched.waybill || this.isWaybillValid) return '';
        return this.waybill ? 'Waybill number must be exactly 12 digits.' : 'Waybill number is required.';
    }
    get mobileError() {
        if (!this.touched.mobile || this.isMobileValid) return '';
        return this.mobile ? 'Please enter a genuine 10-digit mobile number.' : 'Mobile number is required.';
    }
    get emailError() {
        const problem = this.emailProblem;
        if (!problem) return '';
        if (problem === MSG_EMAIL_SAFEXPRESS) return problem;
        return this.touched.email ? problem : '';
    }
    get instructionsError() {
        if (!this.touched.instructions || this.isInstructionsValid) return '';
        return `Please keep it under ${MAX_INSTRUCTIONS} characters.`;
    }

    stepClass(isValid, hasError, isLast) {
        let cls = 'sfx-step';
        if (isValid) cls += ' is-done';
        else if (hasError) cls += ' is-error';
        if (isLast) cls += ' is-last';
        return cls;
    }
    get waybillStepClass() { return this.stepClass(this.isWaybillValid, !!this.waybillError, false); }
    get mobileStepClass() { return this.stepClass(this.isMobileValid, !!this.mobileError, false); }
    get emailStepClass() { return this.stepClass(this.isEmailValid, !!this.emailError, false); }
    get instructionsStepClass() { return this.stepClass(true, !!this.instructionsError, true); }

    get isWaybillDisabled() { return this.isBusy || this._waybillInitialized; }
    get showForm() { return !this.result; }
    get isBusy() { return this.isSubmitting || this.isCheckingDuplicate; }
    get requiredChecks() { return [this.isWaybillValid, this.isMobileValid, this.isEmailValid]; }
    get totalSteps() { return this.requiredChecks.length; }
    get completedCount() { return this.requiredChecks.filter(Boolean).length; }
    get progressStyle() { return `width: ${(this.completedCount / this.totalSteps) * 100}%;`; }
    get isSubmitDisabled() { return this.isBusy || this.completedCount < this.totalSteps || !this.isInstructionsValid; }

    get isExistingOutcome() { return this.result?.outcome === 'EXISTING'; }
    get resultIcon() { 
        if (this.result?.outcome === 'NOT_ELIGIBLE') return 'utility:error';
        return this.isExistingOutcome ? 'utility:info' : 'utility:success'; 
    }
    get resultVariant() { 
        if (this.result?.outcome === 'NOT_ELIGIBLE') return 'error';
        return this.isExistingOutcome ? 'warning' : 'success'; 
    }
    get confirmNote() {
        if (this.result?.outcome === 'NOT_ELIGIBLE') return '⛔ Request Blocked';
        return this.isExistingOutcome
            ? '✅ A case is already open. Please click Submit below to confirm.'
            : '✅ Your urgent request is logged. Please click Submit below to confirm.';
    }

    async runInitialDeduplicationCheck() {
        this.lastCheckedWaybill = this.waybill;
        this.isCheckingDuplicate = true;
        this.progressText = 'Checking case status...';
        
        try {
            const res = await checkExistingCase({ waybillNumber: this.waybill });
            
            if (res && res.outcome === 'EXISTING') {
                this.result = res;
                this.publishValue(res);
            }
        } catch (error) {
            console.error('Initial deduplication check failed: ', error);
        } finally {
            this.isCheckingDuplicate = false;
            this.progressText = '';
        }
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        let val = event.target.value || '';

        if (field === 'mobile') {
            val = val.replace(/\D/g, '').slice(0, 10);
            event.target.value = val;
        } else if (field === 'waybill') {
            val = val.replace(/[^\d ]/g, '');
            event.target.value = val;
        }

        this[field] = val;
        this.errorMessage = '';

        // Instantly trigger deduplication check on the 12th keystroke
        if (field === 'waybill' && this.isWaybillValid && this.waybill !== this.lastCheckedWaybill) {
            this.runInitialDeduplicationCheck();
        }
    }

    handleBlur(event) {
        const field = event.target.dataset.field;
        this.touched = { ...this.touched, [field]: true };
        
        if (field === 'waybill' && this.isWaybillValid && this.waybill !== this.lastCheckedWaybill) {
            this.runInitialDeduplicationCheck();
        }
    }

    async handleSubmit() {
        this.errorMessage = '';
        this.touched = { waybill: true, mobile: true, email: true, instructions: true };

        if (!this.isWaybillValid || !this.isMobileValid || !this.isEmailValid || !this.isInstructionsValid) {
            this.errorMessage = 'Please correct the highlighted fields.';
            return;
        }

        this.isSubmitting = true;
        this.progressText = 'Processing your request...';

        try {
            const res = await submitRequest({
                waybillNumber: this.waybill,
                mobileNumber: this.mobile,
                emailId: this.email,
                instructions: this.instructions,
                shipmentStatus: this._value?.shipmentStatus || ''
            });

            if (res.isError) {
                this.errorMessage = res.message;
                return;
            }

            this.result = res;
            this.publishValue(res);

        } catch (error) {
            console.error('Urgent Delivery submit error: ', error);
            this.errorMessage = error?.body?.message || error?.message || 'Something went wrong. Please try again.';
        } finally {
            this.isSubmitting = false;
            this.progressText = '';
        }
    }

    publishValue(res) {
        this._value = {
            waybillNumber: this.waybill,
            mobileNumber: this.mobile,
            emailId: this.email,
            instructions: this.instructions,
            shipmentStatus: this._value?.shipmentStatus || '',
            caseNumber: res.caseNumber || '',
            outcome: res.outcome || '',
            message: res.message || ''
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