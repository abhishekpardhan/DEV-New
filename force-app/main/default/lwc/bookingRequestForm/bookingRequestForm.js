import { LightningElement, api } from 'lwc';
import lookupPincode from '@salesforce/apex/PincodeLookupService.lookupPincode';
import SAFEXPRESS_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';
import {
    validateName, validatePhone, validateEmail, validatePincodeFormat,
    validateAddress, validateWeight, validatePackages, validateWeightPerPackage
} from 'c/bookingValidators';

const VALIDATORS = {
    name: validateName,
    mobileNumber: validatePhone,
    email: validateEmail,
    pickupPincode: validatePincodeFormat,
    deliveryPincode: validatePincodeFormat,
    pickupAddress: validateAddress,
    approxWeight: validateWeight,
    packageCount: validatePackages
};
const FIELD_NAMES = Object.keys(VALIDATORS);
const PINCODE_FIELDS = ['pickupPincode', 'deliveryPincode'];
const LOOKUP_DELAY_MS = 350;
const NOT_SERVICEABLE = 'Sorry, we do not provide service in this pincode.';

export default class BookingRequestForm extends LightningElement {
    @api readOnly = false;
        logoUrl = SAFEXPRESS_LOGO;
    showLogo = true;

    handleLogoError() {
        this.showLogo = false;
    }

    form = {
        name: '', mobileNumber: '', email: '', pickupPincode: '',
        deliveryPincode: '', pickupAddress: '', approxWeight: '', packageCount: ''
    };
    errors = {};
    touched = {};
    pins = { pickupPincode: { state: 'idle' }, deliveryPincode: { state: 'idle' } };

    _value = {};
    _lookupTimers = {};
    _lookupSeq = { pickupPincode: 0, deliveryPincode: 0 };
    _rendered = false;

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val || {};
        let changed = false;
        FIELD_NAMES.forEach((f) => {
            const incoming = this._value[f];
            if (incoming !== undefined && incoming !== null && String(incoming) !== this.form[f]) {
                this.form = { ...this.form, [f]: String(incoming) };
                changed = true;
            }
        });
        if (changed) {
            const touched = { ...this.touched };
            FIELD_NAMES.forEach((f) => {
                if (this.form[f]) touched[f] = true;
            });
            this.touched = touched;
            this.runAllChecks();
            PINCODE_FIELDS.forEach((f) => this.scheduleLookup(f, 0));
        }
    }

    renderedCallback() {
        this._rendered = true;
        this.reportTouched();
    }

    disconnectedCallback() {
        Object.values(this._lookupTimers).forEach((t) => clearTimeout(t));
    }

    handleChange(event) {
        event.stopPropagation();
        const field = event.target.dataset.field;
        const raw = event.detail && event.detail.value !== undefined ? event.detail.value : event.target.value;
        this.form = { ...this.form, [field]: raw === null || raw === undefined ? '' : String(raw) };
        this.runAllChecks();
        if (PINCODE_FIELDS.includes(field)) {
            this.pins = { ...this.pins, [field]: { state: 'idle' } };
            this.scheduleLookup(field, LOOKUP_DELAY_MS);
        }
        this.emitValue();
    }

    handleBlur(event) {
        const field = event.target.dataset.field;
        this.touched = { ...this.touched, [field]: true };
        this.runAllChecks();
    }

    runAllChecks() {
        const errors = {};
        FIELD_NAMES.forEach((f) => {
            const result = VALIDATORS[f](this.form[f]);
            if (!result.valid) errors[f] = result.error;
        });
        if (!errors.approxWeight && !errors.packageCount) {
            const perPackage = validateWeightPerPackage(this.form.approxWeight.trim(), this.form.packageCount.trim());
            if (!perPackage.valid) errors.approxWeight = perPackage.error;
        }
        PINCODE_FIELDS.forEach((f) => {
            if (!errors[f] && this.pins[f].state === 'notServiceable') errors[f] = NOT_SERVICEABLE;
        });
        this.errors = errors;
        this.reportTouched();
    }

    reportTouched() {
        if (!this._rendered) return;
        this.template.querySelectorAll('[data-field]').forEach((input) => {
            const field = input.dataset.field;
            const message = this.touched[field] ? this.errors[field] || '' : '';
            input.setCustomValidity(message);
            if (this.touched[field]) input.reportValidity();
        });
    }

    scheduleLookup(field, delay) {
        clearTimeout(this._lookupTimers[field]);
        const format = validatePincodeFormat(this.form[field]);
        if (!format.valid) return;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._lookupTimers[field] = setTimeout(() => this.lookup(field, format.value), delay);
    }

    async lookup(field, pincode) {
        const seq = ++this._lookupSeq[field];
        this.pins = { ...this.pins, [field]: { state: 'checking' } };
        let next;
        try {
            const result = await lookupPincode({ pincode });
            if (result && result.status === 'SERVICEABLE') {
                const area = [result.district, result.state]
                    .filter((p, i, all) => p && all.indexOf(p) === i && p !== result.city);
                next = { state: 'ok', city: result.city || result.district || '', area: area.join(', ') };
            } else if (result && result.status === 'NOT_SERVICEABLE') {
                next = { state: 'notServiceable' };
                this.touched = { ...this.touched, [field]: true };
            } else {
                next = { state: 'unavailable' };
            }
        } catch (e) {
            next = { state: 'unavailable' };
        }
        if (seq !== this._lookupSeq[field] || validatePincodeFormat(this.form[field]).value !== pincode) {
            return;
        }
        this.pins = { ...this.pins, [field]: next };
        this.runAllChecks();
        this.emitValue();
    }

    emitValue() {
        const value = {};
        FIELD_NAMES.forEach((f) => {
            const result = VALIDATORS[f](this.form[f]);
            value[f] = result.valid ? result.value : String(this.form[f]).trim();
        });
        this._value = value;
        this.dispatchEvent(new CustomEvent('valuechange', { detail: { value } }));
    }

    get pickup() { return this.pinView('pickupPincode'); }
    get delivery() { return this.pinView('deliveryPincode'); }

    pinView(field) {
        const pin = this.pins[field];
        return {
            checking: pin.state === 'checking',
            ok: pin.state === 'ok',
            unavailable: pin.state === 'unavailable',
            city: pin.city,
            area: pin.area,
            stopClass: 'route-stop' + (pin.state === 'ok' ? ' route-stop_verified' : '')
        };
    }

    get pendingCount() { return Object.keys(this.errors).length; }
    get isComplete() { return this.pendingCount === 0; }
    get statusText() {
        if (this.isComplete) return 'All details look good. You can submit the form now.';
        const n = this.pendingCount;
        return n === 1 ? '1 detail still needs your attention.' : `${n} details still need your attention.`;
    }
    get statusClass() { return 'form-status' + (this.isComplete ? ' form-status_ready' : ''); }
    get showStatus() { return !this.readOnly && Object.keys(this.touched).length > 0; }
}