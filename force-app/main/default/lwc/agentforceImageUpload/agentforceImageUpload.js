import { LightningElement, api } from 'lwc';
import precheckEscalation from '@salesforce/apex/SafexpressPostDeliveryStatusAction.precheckEscalation';
import submitEscalation from '@salesforce/apex/SafexpressPostDeliveryStatusAction.submitEscalation';
import uploadProofFile from '@salesforce/apex/AgentforceImageUploadController.uploadProofFile';
import SFX_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';
import IOS_BADGE from '@salesforce/resourceUrl/IOSAppLogo';
import ANDROID_BADGE from '@salesforce/resourceUrl/AndroidAppLogo';

const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'pdf'];

// Apex sync heap is 6 MB and base64 adds ~33%, so keep each file (after compression) under 2 MB
const MAX_FILE_BYTES = 2 * 1024 * 1024;
const COMPRESS_OVER_BYTES = 1024 * 1024; // compress photos bigger than 1 MB
const MAX_IMAGE_DIMENSION = 1600;
const JPEG_QUALITY = 0.8;

// ---------- Email rules (same as Apex emailRejectionReason in SafexpressPostDeliveryStatusAction) ----------
// Any email containing Safexpress in any spelling / case / position is blocked
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

// A word looks random: aaaa, titititi, 5+ consonants in a row, keyboard runs
function looksRandom(letters) {
    if (!letters) return false;
    if (/(.)\1{3,}/.test(letters)) return true;
    if (/(..+?)\1{2,}/.test(letters)) return true;
    if (/[bcdfghjklmnpqrstvwxz]{5,}/.test(letters)) return true;
    return KEYBOARD_RUNS.some((run) => letters.includes(run));
}

// Returns the message to show, or '' when the email is acceptable
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

// Issue types - keys must match ISSUE_TYPES in SafexpressPostDeliveryStatusAction
const ISSUE_TYPES = [
    { value: 'MATERIAL_DAMAGED', label: '📦 Material Damaged', isStaff: false },
    { value: 'SHORTAGE', label: '➖ Shortage in the delivered material', isStaff: false },
    { value: 'NOT_RECEIVED', label: '❓ Expected material not received', isStaff: false },
    { value: 'SHOWN_DELIVERED', label: '🚚 Not received, but status shows Delivered', isStaff: false },
    { value: 'STAFF_BEHAVIOUR', label: '🙍 Bad behaviour of the delivery staff', isStaff: true }
];
const MIN_STAFF_DESCRIPTION = 20;
const MAX_DESCRIPTION = 2000;

const IOS_APP_URL = 'https://apps.apple.com/in/app/safexpress-app/id6797861161';
const ANDROID_APP_URL = 'https://play.google.com/store/apps/details?id=com.safexpress.enterprise';

export default class AgentforceImageUpload extends LightningElement {
    @api configuration;

    // Lightning Type editor value (SafexpressDamageEscalationForm) - sent to the agent action
    _value = {};
    @api
    get value() {
        return this._value;
    }
    set value(val) {
        if (val) {
            this._value = val;
        }
    }

    logoUrl = SFX_LOGO;
    iosBadgeUrl = IOS_BADGE;
    androidBadgeUrl = ANDROID_BADGE;
    iosAppUrl = IOS_APP_URL;
    androidAppUrl = ANDROID_APP_URL;

    issueType = '';
    waybill = '';
    mobile = '';
    email = '';
    description = '';
    incidentDate = '';
    touched = { issueType: false, waybill: false, mobile: false, email: false, description: false, incidentDate: false };
    files = []; // { id, name, size, sizeLabel, emoji, base64Data, documentId }

    isDragOver = false;
    isPreparingFiles = false;
    isSubmitting = false;
    progressText = '';
    errorMessage = '';
    result = null;

    fileSeq = 0;

    // ---------------- Issue type ----------------

    get issueOptions() {
        return ISSUE_TYPES.map((opt) => ({ ...opt, selected: opt.value === this.issueType }));
    }

    get isNoIssueSelected() {
        return !this.issueType;
    }

    get selectedIssue() {
        return ISSUE_TYPES.find((opt) => opt.value === this.issueType);
    }

    get isIssueValid() {
        return !!this.selectedIssue;
    }

    get isStaffIssue() {
        return !!this.selectedIssue && this.selectedIssue.isStaff;
    }

    // Documents: required for material issues, optional for staff behaviour
    get isDocsRequired() {
        return this.isIssueValid && !this.isStaffIssue;
    }

    get isDocsOptional() {
        return this.isStaffIssue;
    }

    // Description: required for staff behaviour, optional otherwise
    get isDescriptionRequired() {
        return this.isStaffIssue;
    }

    get isDescriptionOptional() {
        return !this.isStaffIssue;
    }

    get descriptionPlaceholder() {
        return this.isStaffIssue
            ? 'Please describe what happened, when, and the staff member involved (if known).'
            : 'Add any details that will help us (optional).';
    }

    // ---------------- Field validation (live) ----------------

    get waybillDigits() {
        return (this.waybill || '').replace(/\s/g, '');
    }

    get isWaybillValid() {
        return /^\d{12}$/.test(this.waybillDigits);
    }

    get isMobileValid() {
        const m = this.mobile || '';
        return /^\d{10}$/.test(m) && !/^(\d)\1{9}$/.test(m) && !BLOCKED_MOBILES.includes(m);
    }

    get emailProblem() {
        return emailRejectionReason(this.email);
    }

    get isEmailValid() {
        return !this.emailProblem;
    }

    get descriptionLength() {
        return (this.description || '').length;
    }

    get trimmedDescriptionLength() {
        return (this.description || '').trim().length;
    }

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

    get issueError() {
        if (!this.touched.issueType || this.isIssueValid) return '';
        return 'Please select the issue you are facing.';
    }

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
        if (problem === MSG_EMAIL_SAFEXPRESS) return problem; // show immediately while typing
        return this.touched.email ? problem : '';
    }

    get descriptionError() {
        if (!this.touched.description || this.isDescriptionValid) return '';
        if (this.descriptionLength > MAX_DESCRIPTION) return `Please keep it under ${MAX_DESCRIPTION} characters.`;
        return `Please describe what happened (at least ${MIN_STAFF_DESCRIPTION} characters).`;
    }

    get incidentDateError() {
        if (this.isIncidentDateValid) return '';
        return 'Incident date cannot be in the future.';
    }

    // ---------------- Step styling (left pointers) ----------------

    stepClass(isValid, hasError, isLast) {
        let cls = 'sfx-step';
        if (isValid) cls += ' is-done';
        else if (hasError) cls += ' is-error';
        if (isLast) cls += ' is-last';
        return cls;
    }

    get issueStepClass() {
        return this.stepClass(this.isIssueValid, !!this.issueError, true);
    }

    get waybillStepClass() {
        return this.stepClass(this.isWaybillValid, !!this.waybillError, false);
    }

    get mobileStepClass() {
        return this.stepClass(this.isMobileValid, !!this.mobileError, false);
    }

    get emailStepClass() {
        return this.stepClass(this.isEmailValid, !!this.emailError, true);
    }

    get descriptionStepClass() {
        const done = this.isDescriptionRequired
            ? this.isDescriptionValid
            : this.trimmedDescriptionLength > 0 && this.isDescriptionValid;
        return this.stepClass(done, !!this.descriptionError, false);
    }

    get incidentDateStepClass() {
        const done = !!this.incidentDate && this.isIncidentDateValid;
        return this.stepClass(done, !!this.incidentDateError, false);
    }

    get filesStepClass() {
        return this.stepClass(this.hasFiles, false, true);
    }

    get dropZoneClass() {
        let cls = 'sfx-drop-zone';
        if (this.isDragOver) cls += ' is-dragover';
        if (this.hasFiles) cls += ' has-files';
        if (this.isBusy) cls += ' is-disabled';
        return cls;
    }

    // ---------------- Progress ----------------

    get requiredChecks() {
        const checks = [this.isIssueValid, this.isWaybillValid, this.isMobileValid, this.isEmailValid];
        if (this.isDocsRequired) checks.push(this.hasFiles);
        if (this.isDescriptionRequired) checks.push(this.isDescriptionValid);
        return checks;
    }

    get totalSteps() {
        return this.requiredChecks.length;
    }

    get completedCount() {
        return this.requiredChecks.filter(Boolean).length;
    }

    get progressStyle() {
        return `width: ${(this.completedCount / this.totalSteps) * 100}%;`;
    }

    // ---------------- General getters ----------------

    get showForm() {
        return !this.result;
    }

    get hasFiles() {
        return this.files.length > 0;
    }

    get isBusy() {
        return this.isSubmitting || this.isPreparingFiles;
    }

    get isSubmitDisabled() {
        return (
            this.isBusy ||
            this.completedCount < this.totalSteps ||
            !this.isDescriptionValid ||
            !this.isIncidentDateValid
        );
    }

    get sessionId() {
        return this.configuration?.context?.messagingSessionId || '';
    }

    get isExistingOutcome() {
        const o = this.result?.outcome;
        return o === 'EXISTING_WITH_PROOF' || o === 'EXISTING';
    }

    get resultIcon() {
        return this.isExistingOutcome ? 'utility:info' : 'utility:success';
    }

    get resultVariant() {
        return this.isExistingOutcome ? 'warning' : 'success';
    }

    get hasFilesAttached() {
        return (this.result?.filesAttached || 0) > 0;
    }

    get confirmNote() {
        return this.isExistingOutcome
            ? '✅ Your existing case details are shown. Please click Submit below to confirm.'
            : '✅ Your complaint is registered. Please click Submit below to confirm.';
    }

    // ---------------- Input handlers ----------------

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

        this[field] = val; // trimmed server-side

        if (field === 'issueType') {
            this.touched = { ...this.touched, issueType: true };
            if (!this.isStaffIssue) {
                this.incidentDate = '';
            }
        }
        this.errorMessage = '';
    }

    handleBlur(event) {
        const field = event.target.dataset.field;
        this.touched = { ...this.touched, [field]: true };
    }

    // ---------------- File handlers ----------------

    handleDragOver(event) {
        event.preventDefault();
        if (!this.isBusy) this.isDragOver = true;
    }

    handleDragLeave(event) {
        event.preventDefault();
        this.isDragOver = false;
    }

    handleDrop(event) {
        event.preventDefault();
        this.isDragOver = false;
        if (this.isBusy) return;
        const dropped = event.dataTransfer && event.dataTransfer.files;
        this.processFiles(Array.from(dropped || []));
    }

    handleFileChange(event) {
        const picked = Array.from(event.target.files || []);
        event.target.value = ''; // allow picking the same file again after removing it
        this.processFiles(picked);
    }

    async processFiles(picked) {
        if (!picked.length) return;

        this.errorMessage = '';
        this.isPreparingFiles = true;
        this.progressText = 'Preparing files...';

        const rejected = [];
        const prepared = [];

        try {
            for (const file of picked) {
                const ext = (file.name.split('.').pop() || '').toLowerCase();
                if (!ALLOWED_EXTENSIONS.includes(ext)) {
                    rejected.push(`${file.name} (only PNG, JPEG or PDF allowed)`);
                    continue;
                }

                let blob = file;
                let name = file.name;

                if (ext !== 'pdf' && file.size > COMPRESS_OVER_BYTES) {
                    // eslint-disable-next-line no-await-in-loop
                    const compressed = await this.compressImage(file);
                    if (compressed !== file) {
                        blob = compressed;
                        name = name.replace(/\.[^.]+$/, '') + '.jpg';
                    }
                }

                if (blob.size > MAX_FILE_BYTES) {
                    rejected.push(`${file.name} (larger than 2 MB)`);
                    continue;
                }

                if (this.isDuplicate(name, blob.size, prepared)) continue;

                // eslint-disable-next-line no-await-in-loop
                const base64Data = await this.readAsBase64(blob);
                this.fileSeq += 1;
                prepared.push({
                    id: `file-${this.fileSeq}`,
                    name,
                    size: blob.size,
                    sizeLabel: this.formatSize(blob.size),
                    emoji: ext === 'pdf' ? '📄' : '🖼️',
                    base64Data,
                    documentId: null
                });
            }

            this.files = [...this.files, ...prepared];

            if (rejected.length) {
                this.errorMessage = `Some files were not added: ${rejected.join(', ')}.`;
            }
        } catch (error) {
            console.error('File preparation error: ', error);
            this.errorMessage = 'Could not read the selected file(s). Please try again.';
        } finally {
            this.isPreparingFiles = false;
            this.progressText = '';
        }
    }

    handleRemoveFile(event) {
        const id = event.currentTarget.dataset.id;
        this.files = this.files.filter((f) => f.id !== id);
    }

    // ---------------- Submit ----------------

    get formParams() {
        return {
            waybillNumber: this.waybill,
            mobileNumber: this.mobile,
            emailId: this.email,
            issueType: this.issueType,
            description: this.description,
            incidentDate: this.isStaffIssue ? this.incidentDate : ''
        };
    }

    async handleSubmit() {
        this.errorMessage = '';
        if (!this.validateInputs()) return;

        this.isSubmitting = true;
        try {
            // 1. Validate + de-duplication check before uploading anything
            this.progressText = 'Checking your waybill...';
            const pre = await precheckEscalation(this.formParams);

            if (pre.isError) {
                this.errorMessage = pre.message;
                return;
            }
            if (pre.proofRequired && !this.hasFiles) {
                this.errorMessage = 'Please upload at least one image or PDF of the issue.';
                return;
            }

            // 2. Upload documents (one file per call) only when the case needs them
            const documentIds = [];
            if (pre.uploadFiles) {
                for (let i = 0; i < this.files.length; i++) {
                    const file = this.files[i];
                    this.progressText = `Uploading document ${i + 1} of ${this.files.length}...`;

                    if (!file.documentId) {
                        // eslint-disable-next-line no-await-in-loop
                        file.documentId = await uploadProofFile({
                            fileName: file.name,
                            base64Data: file.base64Data,
                            messagingSessionId: this.sessionId
                        });
                    }
                    documentIds.push(file.documentId);
                }
            }

            // 3. Create case OR update the existing case
            this.progressText = 'Registering your complaint...';
            const res = await submitEscalation({
                ...this.formParams,
                contentDocumentIds: documentIds,
                messagingSessionId: this.sessionId
            });

            if (res.isError) {
                this.errorMessage = res.message;
                return;
            }

            this.showResult(res);
        } catch (error) {
            console.error('Escalation submit error: ', error);
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isSubmitting = false;
            this.progressText = '';
        }
    }

    validateInputs() {
        this.touched = {
            issueType: true,
            waybill: true,
            mobile: true,
            email: true,
            description: true,
            incidentDate: true
        };

        if (
            !this.isIssueValid ||
            !this.isWaybillValid ||
            !this.isMobileValid ||
            !this.isEmailValid ||
            !this.isDescriptionValid ||
            !this.isIncidentDateValid
        ) {
            this.errorMessage = 'Please correct the highlighted fields.';
            return false;
        }
        if (this.isDocsRequired && !this.hasFiles) {
            this.errorMessage = 'Please upload at least one image or PDF of the issue.';
            return false;
        }
        return true;
    }

    showResult(res) {
        this.result = res;
        this.files = []; // release base64 data from memory
        this.publishValue(res);
        this.notifyAgent(res);
    }

    // Hands the result to the agent action input (Lightning Type editor contract)
    publishValue(res) {
        this._value = {
            waybillNumber: res.waybillFormatted || '',
            caseNumber: res.caseNumber || '',
            outcome: res.outcome || '',
            caseStatus: res.caseStatus || '',
            filesAttached: res.filesAttached || 0,
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

    notifyAgent(res) {
        const text = res?.agentMessage;
        if (!text || !this.configuration?.util?.sendTextMessage) return;
        try {
            this.configuration.util.sendTextMessage(text);
        } catch (error) {
            console.error('sendTextMessage error: ', error);
        }
    }

    // ---------------- File helpers ----------------

    isDuplicate(name, size, prepared) {
        return [...this.files, ...prepared].some((f) => f.name === name && f.size === size);
    }

    readAsBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(String(reader.result).split(',')[1]);
            reader.onerror = (error) => reject(error);
            reader.readAsDataURL(blob);
        });
    }

    // Resize + re-encode as JPEG. Falls back to the original file if anything fails.
    compressImage(file) {
        return new Promise((resolve) => {
            let url;
            try {
                url = URL.createObjectURL(file);
            } catch (e) {
                resolve(file);
                return;
            }

            const done = (output) => {
                URL.revokeObjectURL(url);
                resolve(output);
            };

            const img = new Image();
            img.onload = () => {
                try {
                    const scale = Math.min(1, MAX_IMAGE_DIMENSION / Math.max(img.width, img.height));
                    const width = Math.round(img.width * scale);
                    const height = Math.round(img.height * scale);

                    const canvas = document.createElement('canvas');
                    canvas.width = width;
                    canvas.height = height;
                    const ctx = canvas.getContext('2d');
                    ctx.fillStyle = '#ffffff'; // PNG transparency -> white
                    ctx.fillRect(0, 0, width, height);
                    ctx.drawImage(img, 0, 0, width, height);

                    canvas.toBlob(
                        (blob) => done(blob && blob.size < file.size ? blob : file),
                        'image/jpeg',
                        JPEG_QUALITY
                    );
                } catch (e) {
                    done(file);
                }
            };
            img.onerror = () => done(file);
            img.src = url;
        });
    }

    formatSize(bytes) {
        return bytes < 1024 * 1024
            ? `${Math.max(1, Math.round(bytes / 1024))} KB`
            : `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }

    reduceError(error) {
        return (
            error?.body?.message ||
            error?.message ||
            'Something went wrong. Please try again.'
        );
    }
}