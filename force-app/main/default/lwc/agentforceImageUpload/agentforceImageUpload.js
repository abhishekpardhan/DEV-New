import { LightningElement, api } from 'lwc';
import checkWaybill from '@salesforce/apex/SafexpressPostDeliveryStatusAction.checkWaybill';
import uploadProofFile from '@salesforce/apex/AgentforceImageUploadController.uploadProofFile';
import SFX_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';
import IOS_BADGE from '@salesforce/resourceUrl/IosStoreLogo';      
import ANDROID_BADGE from '@salesforce/resourceUrl/AppStoreLogo';  

const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'pdf'];
const MAX_FILE_BYTES = 2 * 1024 * 1024;
const COMPRESS_OVER_BYTES = 1024 * 1024; 
const MAX_IMAGE_DIMENSION = 1600;
const JPEG_QUALITY = 0.8;

const SAFEXPRESS_VARIANTS = ['safexpres', 'safeexpres', 'safexprs'];
const BLOCKED_EMAIL_NAMES = [
    'test', 'testing', 'tester', 'testuser', 'testmail', 'dummy', 'fake', 'sample', 'demo',
    'abc', 'abcd', 'abcde', 'xyz', 'asdf', 'qwerty', 'user', 'admin', 'example', 'temp',
    'none', 'null', 'na', 'nil', 'xxx', 'aaa', 'name', 'email', 'mail', 'noreply', 'noemail'
];
const BLOCKED_EMAIL_NAME_PREFIXES = ['dummy', 'fake', 'asdf', 'qwert', 'zxcv'];
const BLOCKED_DOMAIN_WORDS = [
    'test', 'testmail', 'testing', 'example', 'sample', 'dummy', 'fake', 'fakemail', 'abc', 'xyz',
    'temp', 'tempmail', 'domain', 'email', 'mailinator', 'yopmail', 'guerrillamail', 'trashmail',
    'throwaway', 'throwawaymail', 'getnada', 'sharklasers', 'dispostable', 'maildrop', 'mintemail',
    'mohmal', 'emailondeck', 'spamgourmet', 'discard', 'discardmail'
];
const DISPOSABLE_DOMAIN_PARTS = ['mailinator', 'yopmail', 'tempmail', 'guerrillamail', 'trashmail', 'fakemail', 'throwaway', 'disposable', '10minute'];
const KEYBOARD_RUNS = ['qwert', 'werty', 'asdfg', 'sdfgh', 'zxcvb', 'xcvbn', 'yuiop', 'hjkl', 'qazwsx'];

const MSG_EMAIL_REQUIRED = 'Email ID is required.';
const MSG_EMAIL_FORMAT = 'Please enter a valid email address. Use only letters, numbers and dots before @ (starting with a letter), e.g. name.surname@gmail.com.';
const MSG_EMAIL_DOMAIN_DIGITS = 'The email domain (after @) cannot contain numbers.';
const MSG_EMAIL_TOO_MANY_DIGITS = 'Email name can contain at most 4 numbers.';
const MSG_EMAIL_TEST = 'Test, dummy or temporary email addresses are not accepted. Please enter your real email address.';
const MSG_EMAIL_RANDOM = "This email address doesn't look valid. Please enter your real email address.";
const MSG_EMAIL_SAFEXPRESS = "Safexpress email addresses can't be used. Please enter your personal or company email address.";

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

    if ((local.match(/[0-9]/g) || []).length > 4) return MSG_EMAIL_TOO_MANY_DIGITS;
    if (/(.)\1{3,}/.test(local)) return MSG_EMAIL_RANDOM;

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
const BLOCKED_MOBILES = ['1234567890', '0123456789', '9876543210', '0987654321', '5555555555', '0000000000'];

const ISSUE_TYPES = [
    { value: 'MATERIAL_DAMAGED', label: '📦 Material Damaged', isStaff: false },
    { value: 'SHORTAGE', label: '➖ Shortage in the delivered material', isStaff: false },
    { value: 'NOT_RECEIVED', label: '❓ Expected material not received', isStaff: false },
    { value: 'SHOWN_DELIVERED', label: '🚚 Not received, but status shows Delivered', isStaff: false },
    { value: 'STAFF_BEHAVIOUR', label: '🙍 Bad behaviour of the delivery staff', isStaff: true }
];
const MIN_STAFF_DESCRIPTION = 20;
const MAX_DESCRIPTION = 2000;

const CHECK_IDLE = 'idle';         
const CHECK_RUNNING = 'checking';  
const CHECK_READY = 'ready';       
const CHECK_OPEN_CASE = 'openCase';
const CHECK_BLOCKED = 'blocked';   
const CHECK_DEBOUNCE_MS = 300;

export default class AgentforceImageUpload extends LightningElement {
    @api configuration;

    _value = {};
    @api
    get value() {
        return this._value;
    }
    set value(val) {
        if (val) {
            this._value = val;
            
            if (val.waybillNumber) this.waybill = val.waybillNumber.replace(/[^\d]/g, '');
            if (val.mobileNumber) this.mobile = val.mobileNumber;
            if (val.emailId) this.email = val.emailId;
            if (val.instructions) this.description = val.instructions;
            
            if (val.caseNumber) {
                this.result = val;
            }
            this.publishValue();
        }
    }

    connectedCallback() {
        this.publishValue(); 
    }

    logoUrl = SFX_LOGO;
    iosBadgeUrl = IOS_BADGE;
    androidBadgeUrl = ANDROID_BADGE;
    iosAppUrl = 'https://apps.apple.com/in/app/safexpress-app/id6797861161';
    androidAppUrl = 'https://play.google.com/store/apps/details?id=com.safexpress.enterprise';

    issueType = '';
    waybill = '';
    mobile = '';
    email = '';
    description = '';
    incidentDate = '';
    touched = { issueType: false, waybill: false, mobile: false, email: false, description: false, incidentDate: false };
    files = []; 

    isDragOver = false;
    isPreparingFiles = false;
    progressText = '';
    errorMessage = '';
    result = null;

    fileSeq = 0;

    checkState = CHECK_IDLE;
    checkResult = null;
    checkMessage = '';
    checkOutcome = '';
    checkedKey = '';
    checkSeq = 0;
    checkTimer;

    disconnectedCallback() {
        clearTimeout(this.checkTimer);
    }

    get issueOptions() {
        return ISSUE_TYPES.map((opt) => ({ ...opt, selected: opt.value === this.issueType }));
    }

    get isNoIssueSelected() { return !this.issueType; }
    get selectedIssue() { return ISSUE_TYPES.find((opt) => opt.value === this.issueType); }
    get isIssueValid() { return !!this.selectedIssue; }
    get isStaffIssue() { return !!this.selectedIssue && this.selectedIssue.isStaff; }

    get isDocsRequired() {
        if (this.isOpenCaseMode) return true; 
        return this.isIssueValid && !this.isStaffIssue;
    }

    get isDocsOptional() { return !this.isOpenCaseMode && this.isStaffIssue; }
    get isDescriptionRequired() { return this.isStaffIssue; }
    get isDescriptionOptional() { return !this.isStaffIssue; }

    get descriptionPlaceholder() {
        return this.isStaffIssue
            ? 'Please describe what happened, when, and the staff member involved (if known).'
            : 'Add any details that will help us (optional).';
    }

    get waybillDigits() { return (this.waybill || '').replace(/\s/g, ''); }
    get isWaybillValid() { return /^\d{12}$/.test(this.waybillDigits); }
    get isMobileValid() {
        const m = this.mobile || '';
        return /^\d{10}$/.test(m) && !/^(\d)\1{9}$/.test(m) && !BLOCKED_MOBILES.includes(m);
    }

    get emailProblem() { return emailRejectionReason(this.email); }
    get isEmailValid() { return !this.emailProblem; }
    get descriptionLength() { return (this.description || '').length; }
    get trimmedDescriptionLength() { return (this.description || '').trim().length; }

    get isDescriptionValid() {
        if (this.descriptionLength > MAX_DESCRIPTION) return false;
        if (this.isDescriptionRequired) return this.trimmedDescriptionLength >= MIN_STAFF_DESCRIPTION;
        return true;
    }

    get todayIso() {
        const d = new Date();
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const dd = String(d.getDate()).padStart(2, '0');
        return `${d.getFullYear()}-${mm}-${dd}`;
    }

    get isIncidentDateValid() {
        if (!this.isStaffIssue || !this.incidentDate) return true;
        return /^\d{4}-\d{2}-\d{2}$/.test(this.incidentDate) && this.incidentDate <= this.todayIso;
    }

    get issueError() { return (!this.touched.issueType || this.isIssueValid) ? '' : 'Please select the issue you are facing.'; }
    get waybillError() {
        if (this.isWaybillValid && this.checkOutcome === 'INVALID_WAYBILL') return MSG_INVALID_WAYBILL;
        if (!this.touched.waybill || this.isWaybillValid) return '';
        return this.waybill ? MSG_INVALID_WAYBILL : 'Waybill number is required.';
    }
    get mobileError() { return (!this.touched.mobile || this.isMobileValid) ? '' : (this.mobile ? 'Please enter a genuine 10-digit mobile number.' : 'Mobile number is required.'); }
    get emailError() {
        const problem = this.emailProblem;
        if (!problem) return '';
        if (problem === MSG_EMAIL_SAFEXPRESS) return problem; 
        return this.touched.email ? problem : '';
    }
    get descriptionError() {
        if (!this.touched.description || this.isDescriptionValid) return '';
        if (this.descriptionLength > MAX_DESCRIPTION) return `Please keep it under ${MAX_DESCRIPTION} characters.`;
        return `Please describe what happened (at least ${MIN_STAFF_DESCRIPTION} characters).`;
    }
    get incidentDateError() { return this.isIncidentDateValid ? '' : 'Incident date cannot be in the future.'; }

    stepClass(isValid, hasError, isLast) {
        let cls = 'sfx-step';
        if (isValid) cls += ' is-done';
        else if (hasError) cls += ' is-error';
        if (isLast) cls += ' is-last';
        return cls;
    }

    get issueStepClass() { return this.stepClass(this.isIssueValid, !!this.issueError, true); }
    get waybillStepClass() { return this.stepClass(this.isWaybillValid && (this.isReadyMode || this.isOpenCaseMode), !!this.waybillError, false); }
    get mobileStepClass() { return this.stepClass(this.isMobileValid, !!this.mobileError, false); }
    get emailStepClass() { return this.stepClass(this.isEmailValid, !!this.emailError, true); }
    get descriptionStepClass() {
        const done = this.isDescriptionRequired ? this.isDescriptionValid : this.trimmedDescriptionLength > 0 && this.isDescriptionValid;
        return this.stepClass(done, !!this.descriptionError, false);
    }
    get incidentDateStepClass() { return this.stepClass(!!this.incidentDate && this.isIncidentDateValid, !!this.incidentDateError, false); }
    get filesStepClass() { return this.stepClass(this.hasFiles, false, true); }
    get dropZoneClass() {
        let cls = 'sfx-drop-zone';
        if (this.isDragOver) cls += ' is-dragover';
        if (this.hasFiles) cls += ' has-files';
        if (this.isDocsLocked) cls += ' is-disabled';
        return cls;
    }

    get requiredChecks() {
        const waybillOk = this.isWaybillValid && (this.isReadyMode || this.isOpenCaseMode);
        if (this.isOpenCaseMode) {
            return [this.isIssueValid, waybillOk, this.hasFiles];
        }
        const checks = [this.isIssueValid, waybillOk, this.isMobileValid, this.isEmailValid];
        if (this.isDocsRequired) checks.push(this.hasFiles);
        if (this.isDescriptionRequired) checks.push(this.isDescriptionValid);
        return checks;
    }

    get totalSteps() { return this.requiredChecks.length; }
    get completedCount() { return this.requiredChecks.filter(Boolean).length; }
    get progressStyle() { return `width: ${(this.completedCount / this.totalSteps) * 100}%;`; }
    get showForm() { return !this.result; }
    get hasFiles() { return this.files.length > 0; }
    get isBusy() { return this.isPreparingFiles; }

    get isSubmitDisabled() {
        if (this.isBusy || this.isChecking) return true;
        if (this.isOpenCaseMode) return !this.hasFiles;
        if (!this.isReadyMode) return true;
        return (this.completedCount < this.totalSteps || !this.isDescriptionValid || !this.isIncidentDateValid);
    }

    get isChecking() { return this.checkState === CHECK_RUNNING; }
    get isReadyMode() { return this.checkState === CHECK_READY; }
    get isOpenCaseMode() { return this.checkState === CHECK_OPEN_CASE; }
    get isBlocked() { return this.checkState === CHECK_BLOCKED; }
    get showCheckBanner() { return this.isBlocked && this.checkOutcome !== 'INVALID_WAYBILL' && !!this.checkMessage; }
    get checkBannerClass() { return this.checkOutcome === 'NOT_DELIVERED' ? 'sfx-banner sfx-banner-warn' : 'sfx-banner sfx-banner-error'; }
    get isDetailsLocked() { return this.isBusy || !this.isReadyMode; }
    get isDocsLocked() { return this.isBusy || !(this.isReadyMode || this.isOpenCaseMode); }
    get openCase() { return this.checkResult || {}; }
    get openCaseDocsHint() { return this.openCase.caseHasDocuments ? 'You can add more supporting documents to this complaint.' : 'Please upload supporting documents (images or PDF) for this complaint.'; }
    get showDetailsSections() { return !this.isOpenCaseMode; }
    get sessionId() { return this.configuration?.context?.messagingSessionId || ''; }
    get isExistingOutcome() { const o = this.result?.outcome; return o === 'EXISTING_WITH_PROOF' || o === 'EXISTING'; }
    get resultIcon() { return this.isExistingOutcome ? 'utility:info' : 'utility:success'; }
    get resultVariant() { return this.isExistingOutcome ? 'warning' : 'success'; }
    get hasFilesAttached() { return (this.result?.filesAttached || 0) > 0; }

    get confirmNote() {
        if (this.result?.outcome === 'PROOF_ADDED') return '✅ Your documents have been added to your complaint. Please click Submit below to confirm.';
        return this.isExistingOutcome ? '✅ Your existing case details are shown. Please click Submit below to confirm.' : '✅ Your complaint is registered. Please click Submit below to confirm.';
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        let val = event.target.value || '';
        if (field === 'mobile') val = val.replace(/\D/g, '').slice(0, 10);
        else if (field === 'waybill') val = val.replace(/[^\d ]/g, '');

        this[field] = val; 
        if (field === 'issueType') {
            this.touched = { ...this.touched, issueType: true };
            if (!this.isStaffIssue) this.incidentDate = '';
        }
        this.errorMessage = '';
        if (field === 'issueType' || field === 'waybill') this.scheduleWaybillCheck();
        this.publishValue();
    }

    get checkKey() { return `${this.issueType}|${this.waybillDigits}`; }

    resetWaybillCheck() {
        clearTimeout(this.checkTimer);
        this.checkSeq += 1; 
        this.checkState = CHECK_IDLE;
        this.checkResult = null;
        this.checkMessage = '';
        this.checkOutcome = '';
        this.checkedKey = '';
        this.publishValue();
    }

    scheduleWaybillCheck() {
        if (!this.isIssueValid || !this.isWaybillValid) { this.resetWaybillCheck(); return; }
        if (this.checkKey === this.checkedKey && this.checkState !== CHECK_IDLE && this.checkOutcome !== 'API_ERROR') return; 
        clearTimeout(this.checkTimer);
        this.checkState = CHECK_RUNNING;
        this.checkMessage = '';
        this.checkOutcome = '';
        const key = this.checkKey;
        this.publishValue();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.checkTimer = setTimeout(() => this.runWaybillCheck(key), CHECK_DEBOUNCE_MS);
    }

    async runWaybillCheck(key) {
        this.checkSeq += 1;
        const seq = this.checkSeq;
        try {
            const res = await checkWaybill({ waybillNumber: this.waybill, issueType: this.issueType });
            if (seq !== this.checkSeq || key !== this.checkKey) return; 
            this.checkedKey = key;
            this.applyCheckResult(res);
        } catch (error) {
            if (seq !== this.checkSeq) return;
            console.error('Waybill check error: ', error);
            this.checkedKey = key;
            this.checkState = CHECK_BLOCKED;
            this.checkOutcome = 'API_ERROR';
            this.checkMessage = MSG_CHECK_FAILED;
        } finally {
            this.publishValue();
        }
    }

    applyCheckResult(res) {
        this.checkResult = res;
        this.checkOutcome = res?.outcome || '';
        this.checkMessage = res?.message || '';
        if (this.checkOutcome === 'READY') this.checkState = CHECK_READY;
        else if (this.checkOutcome === 'OPEN_CASE') this.checkState = CHECK_OPEN_CASE;
        else { this.checkState = CHECK_BLOCKED; if (!this.checkMessage) this.checkMessage = MSG_CHECK_FAILED; }
        this.publishValue();
    }

    handleBlur(event) {
        const field = event.target.dataset.field;
        this.touched = { ...this.touched, [field]: true };
        this.publishValue();
    }

    handleDragOver(event) { event.preventDefault(); if (!this.isBusy) this.isDragOver = true; }
    handleDragLeave(event) { event.preventDefault(); this.isDragOver = false; }
    handleDrop(event) { event.preventDefault(); this.isDragOver = false; if (!this.isBusy) this.processFiles(Array.from(event.dataTransfer?.files || [])); }
    handleFileChange(event) { const picked = Array.from(event.target.files || []); event.target.value = ''; this.processFiles(picked); }

    async processFiles(picked) {
        if (!picked.length) return;
        this.errorMessage = '';
        this.isPreparingFiles = true;
        this.progressText = 'Uploading documents...';
        this.publishValue();

        const rejected = [];
        const prepared = [];

        try {
            for (const file of picked) {
                const ext = (file.name.split('.').pop() || '').toLowerCase();
                if (!ALLOWED_EXTENSIONS.includes(ext)) { rejected.push(`${file.name} (only PNG, JPEG or PDF allowed)`); continue; }
                let blob = file;
                let name = file.name;
                if (ext !== 'pdf' && file.size > COMPRESS_OVER_BYTES) {
                    // eslint-disable-next-line no-await-in-loop
                    const compressed = await this.compressImage(file);
                    if (compressed !== file) { blob = compressed; name = name.replace(/\.[^.]+$/, '') + '.jpg'; }
                }
                if (blob.size > MAX_FILE_BYTES) { rejected.push(`${file.name} (larger than 2 MB)`); continue; }
                if (this.isDuplicate(name, blob.size, prepared)) continue;

                // eslint-disable-next-line no-await-in-loop
                const base64Data = await this.readAsBase64(blob);

                // eslint-disable-next-line no-await-in-loop
                const docId = await uploadProofFile({
                    fileName: name,
                    base64Data: base64Data,
                    messagingSessionId: this.sessionId
                });

                this.fileSeq += 1;
                prepared.push({
                    id: `file-${this.fileSeq}`, name, size: blob.size,
                    sizeLabel: this.formatSize(blob.size), emoji: ext === 'pdf' ? '📄' : '🖼️',
                    documentId: docId 
                });
            }
            this.files = [...this.files, ...prepared];
            if (rejected.length) this.errorMessage = `Some files were not added: ${rejected.join(', ')}.`;
        } catch (error) {
            console.error('File preparation error: ', error);
            this.errorMessage = 'Could not upload the selected file(s). Please try again.';
        } finally {
            this.isPreparingFiles = false;
            this.progressText = '';
            this.publishValue();
        }
    }

    handleRemoveFile(event) {
        const id = event.currentTarget.dataset.id;
        this.files = this.files.filter((f) => f.id !== id);
        this.publishValue();
    }

    // ---------------- Publish to Agentforce ----------------

    publishValue() {
        const isValid = this.result ? true : !this.isSubmitDisabled;
        
        // REVERTED: Sends a proper Array to match the List<String> in Apex
        const docIds = this.files.map(f => f.documentId).filter(id => !!id);

        this._value = {
            waybillNumber: this.result?.waybillFormatted || this.waybill,
            mobileNumber: this.mobile,
            emailId: this.email,
            instructions: this.description,
            issueType: this.issueType || (this.selectedIssue ? this.selectedIssue.value : ''),
            incidentDate: this.incidentDate,
            contentDocumentIds: docIds, // Real Array goes out
            checkOutcome: this.checkOutcome,
            messagingSessionId: this.sessionId,
            caseNumber: this.result?.caseNumber || '',
            outcome: this.result?.outcome || ''
        };
        
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: { value: this._value, validity: isValid },
                bubbles: true, composed: true
            })
        );
    }

    // ---------------- File helpers ----------------

    isDuplicate(name, size, prepared) { return [...this.files, ...prepared].some((f) => f.name === name && f.size === size); }
    readAsBase64(blob) { return new Promise((resolve, reject) => { const reader = new FileReader(); reader.onload = () => resolve(String(reader.result).split(',')[1]); reader.onerror = (error) => reject(error); reader.readAsDataURL(blob); }); }
    compressImage(file) {
        return new Promise((resolve) => {
            let url;
            try { url = URL.createObjectURL(file); } catch (e) { resolve(file); return; }
            const done = (output) => { URL.revokeObjectURL(url); resolve(output); };
            const img = new Image();
            img.onload = () => {
                try {
                    const scale = Math.min(1, MAX_IMAGE_DIMENSION / Math.max(img.width, img.height));
                    const width = Math.round(img.width * scale); const height = Math.round(img.height * scale);
                    const canvas = document.createElement('canvas'); canvas.width = width; canvas.height = height;
                    const ctx = canvas.getContext('2d'); ctx.fillStyle = '#ffffff'; ctx.fillRect(0, 0, width, height); ctx.drawImage(img, 0, 0, width, height);
                    canvas.toBlob((blob) => done(blob && blob.size < file.size ? blob : file), 'image/jpeg', JPEG_QUALITY);
                } catch (e) { done(file); }
            };
            img.onerror = () => done(file);
            img.src = url;
        });
    }
    formatSize(bytes) { return bytes < 1024 * 1024 ? `${Math.max(1, Math.round(bytes / 1024))} KB` : `${(bytes / (1024 * 1024)).toFixed(1)} MB`; }
}