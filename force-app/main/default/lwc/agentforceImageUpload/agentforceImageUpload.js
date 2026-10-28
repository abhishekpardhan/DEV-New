import { LightningElement, api } from 'lwc';
import precheckEscalation from '@salesforce/apex/SafexpressPostDeliveryStatusAction.precheckEscalation';
import submitEscalation from '@salesforce/apex/SafexpressPostDeliveryStatusAction.submitEscalation';
import uploadProofFile from '@salesforce/apex/AgentforceImageUploadController.uploadProofFile';
import SFX_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';

const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'pdf'];

// Apex sync heap is 6 MB and base64 adds ~33%, so keep each file (after compression) under 2 MB
const MAX_FILE_BYTES = 2 * 1024 * 1024;
const COMPRESS_OVER_BYTES = 1024 * 1024; // compress photos bigger than 1 MB
const MAX_IMAGE_DIMENSION = 1600;
const JPEG_QUALITY = 0.8;

const FORM_TITLE = 'Report Damaged Goods';

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

    waybill = '';
    mobile = '';
    email = '';
    files = []; // { id, name, size, sizeLabel, icon, base64Data, documentId }

    isPreparingFiles = false;
    isSubmitting = false;
    progressText = '';
    errorMessage = '';
    result = null;

    fileSeq = 0;

    // ---------------- Getters ----------------

    get showForm() {
        return !this.result;
    }

    get headerTitle() {
        return this.result?.headerTitle || FORM_TITLE;
    }

    get hasFiles() {
        return this.files.length > 0;
    }

    get isBusy() {
        return this.isSubmitting || this.isPreparingFiles;
    }

    get isSubmitDisabled() {
        return this.isBusy || !this.waybill || !this.mobile || !this.email || !this.hasFiles;
    }

    get sessionId() {
        return this.configuration?.context?.messagingSessionId || '';
    }

    get resultIcon() {
        return this.result?.outcome === 'EXISTING_WITH_PROOF' ? 'utility:info' : 'utility:success';
    }

    get resultVariant() {
        return this.result?.outcome === 'EXISTING_WITH_PROOF' ? 'warning' : 'success';
    }

    get hasFilesAttached() {
        return (this.result?.filesAttached || 0) > 0;
    }

    // ---------------- Input handlers ----------------

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.detail.value || ''; // trimmed server-side; trimming here blocks typing spaces
        this.errorMessage = '';
    }

    async handleFileChange(event) {
        const picked = Array.from(event.target.files || []);
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

                const base64Data = await this.readAsBase64(blob);
                this.fileSeq += 1;
                prepared.push({
                    id: `file-${this.fileSeq}`,
                    name,
                    size: blob.size,
                    sizeLabel: this.formatSize(blob.size),
                    icon: ext === 'pdf' ? 'doctype:pdf' : 'doctype:image',
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

    async handleSubmit() {
        this.errorMessage = '';
        if (!this.validateInputs()) return;

        this.isSubmitting = true;
        try {
            // 1. Validate + de-duplication check before uploading anything
            this.progressText = 'Checking your waybill...';
            const pre = await precheckEscalation({
                waybillNumber: this.waybill,
                mobileNumber: this.mobile,
                emailId: this.email
            });

            if (pre.isError) {
                this.errorMessage = pre.message;
                return;
            }

            // Open complaint already has proof -> show it, ignore the new files
            if (!pre.proofRequired) {
                this.showResult(pre);
                return;
            }

            // 2. Upload proof, one file per call
            const documentIds = [];
            for (let i = 0; i < this.files.length; i++) {
                const file = this.files[i];
                this.progressText = `Uploading proof ${i + 1} of ${this.files.length}...`;

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

            // 3. Create case OR add proof to the existing case
            this.progressText = 'Registering your complaint...';
            const res = await submitEscalation({
                waybillNumber: this.waybill,
                mobileNumber: this.mobile,
                emailId: this.email,
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
        const inputs = [...this.template.querySelectorAll('lightning-input[data-field]')];
        const allValid = inputs.reduce((valid, input) => input.reportValidity() && valid, true);

        if (!allValid) {
            this.errorMessage = 'Please correct the highlighted fields.';
            return false;
        }
        if (!this.hasFiles) {
            this.errorMessage = 'Please upload at least one photo or PDF of the damaged goods.';
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