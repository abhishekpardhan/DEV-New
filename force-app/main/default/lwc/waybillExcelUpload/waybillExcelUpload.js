import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import sheetjs from '@salesforce/resourceUrl/sheetjs';
import { getRecord } from 'lightning/uiRecordApi';
import { getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Case__c.Name';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import REASON_FIELD from "@salesforce/schema/Waybill_Details__c.Reason__c";
import getExistingWaybillNumbers from '@salesforce/apex/WaybillExcelUploadController.getExistingWaybillNumbers';
import saveWaybills from '@salesforce/apex/WaybillExcelUploadController.saveWaybills';
export default class WaybillExcelUpload extends LightningElement {
    @api recordId;
    allowedReasons;

    @track nonDuplicateData = [];
    @track duplicateData = [];
    @track filteredDuplicateData = [];
    @track showModal = false;
    @track isLoading = false;

    existingWaybills = new Set();
    sheetLoaded = false;
    sheetLoadStarted = false;
    loadingInFlight = false;
    sheetRetryScheduled = false;
    error;

    templateRows = [
        { Name: '123456789012', Amount__c: 1500, Reason__c: 'Incorrect Billing', Remarks__c: 'Sample remark' },
        { Name: '123456789013', Amount__c: 2000, Reason__c: 'Late Delivery Deduction', Remarks__c: 'Sample remark' }
    ];

    modalColumns = [
        { label: 'Waybill Number', fieldName: 'Name' },
        { label: 'Amount', fieldName: 'Amount__c', type: 'number' },
        { label: 'Reason', fieldName: 'Reason__c' },
        { label: 'Remarks', fieldName: 'Remarks__c' },
        { label: 'Error', fieldName: 'error' , cellAttributes: { class: { fieldName: 'errorClass' } } }
    ];

    
    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD] })
    caseRecord;

    get caseName() {
        return getFieldValue(this.caseRecord.data, NAME_FIELD) || '';
    }

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: REASON_FIELD })
    picklistResults({ error, data }) {
        if (data) {
            this.allowedReasons = data.values.map(item => item.value);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.allowedReasons = undefined;
        }
    }

    get dynamicHelptextContent() {
        if (!this.allowedReasons || !this.allowedReasons.length) {
            return 'Reason picklist: loading… Multi-select values separated by commas.';
        }
        return `Reason picklist: Reason__c (${this.allowedReasons.join(', ')}). Multi-select values separated by commas.`;
    }

    connectedCallback() {
        if (!this.sheetLoadStarted) {
            this.sheetLoadStarted = true;
            this.tryLoadSheetJs();
        }
    }

    handleUpload(event) {
        if (!this.sheetLoaded) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Not Ready',
                message: 'Excel File is not loaded yet. Please wait a moment and try again.',
                variant: 'warning'
            }));
            return;
        }

        const file = event.target.files[0];
        if (!file) return;

        this.fetchExistingData();
        const reader = new FileReader();
        reader.onload = () => {
            try {
                const workbook = XLSX.read(reader.result, { type: 'binary' });
                const sheet = workbook.Sheets[workbook.SheetNames[0]];
                const rows = XLSX.utils.sheet_to_json(sheet, { defval: '' });
                const requiredHeaders = ['Name', 'Amount__c', 'Reason__c', 'Remarks__c'];
                const fileHeaders = rows.length ? Object.keys(rows[0]) : [];
                const isValidHeader =
                    fileHeaders.length === requiredHeaders.length &&
                    requiredHeaders.every(h => fileHeaders.includes(h));

                if (!isValidHeader) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Invalid Excel Format',
                        message: 'Invalid or missing headers. Required headers are: Name, Amount__c, Reason__c, Remarks__c.',
                        variant: 'error'
                    }));
                    return;
                }

                if (rows.length > 1000) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Row Limit Exceeded',
                        message: 'The uploaded file exceeds the maximum limit of 1000 rows. Please reduce the number of rows and try again.',
                        variant: 'error'
                    }));
                    return;
                }

                const seenWaybills = new Set();
                const preparedRows = rows.map((r, i) => this.prepareRow(r, i, seenWaybills));
                this.nonDuplicateData = preparedRows.filter(r => !r.isDuplicate);
                this.duplicateData = preparedRows.filter(r => r.isDuplicate);
                this.filteredDuplicateData = [...this.duplicateData];
                this.showModal = true;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'File Uploaded Successfully',
                    variant: 'success'
                }));
            } catch (e) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'File Upload Error',
                    message: 'Excel file error.',
                    variant: 'error'
                }));
                console.error(e);
            }
        };
        reader.onerror = () => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Read Error',
                message: 'Could not read the selected file.',
                variant: 'error'
            }));
        };
        reader.readAsBinaryString(file);
    }

    tryLoadSheetJs() {
        if (this.sheetLoaded) return;
        if (this.loadingInFlight) return;
        this.loadingInFlight = true;
        loadScript(this, sheetjs)
            .then(() => {
                this.sheetLoaded = true;
            })
            .catch(() => {
                if (!this.sheetRetryScheduled) {
                    this.sheetRetryScheduled = true;
                    setTimeout(() => {
                        loadScript(this, sheetjs)
                            .then(() => {
                                this.sheetLoaded = true;
                            })
                            .finally(() => {
                                this.loadingInFlight = false;
                            });
                    }, 500);
                    return;
                }
            })
            .finally(() => {
                // If we didn't schedule a retry, clear the in-flight flag here
                if (!this.sheetRetryScheduled) {
                    this.loadingInFlight = false;
                }
            });
    }

    prepareRow(row, idx, seenWaybills) {
        let error = '';
        let isDuplicate = false;
        if (this.existingWaybills.has(String(row.Name))) {
            error = 'Duplicate waybill';
            isDuplicate = true;
        } else if (seenWaybills.has(String(row.Name))) {
            error = 'Duplicate waybill in uploaded file';
        } else if (!row.Name) {
            error = 'Waybill is required';
        } else if (!/^\d{12}$/.test(row.Name)) {
            error = 'Waybill must be 12 digits';
        } else if (!row.Amount__c || row.Amount__c <= 0 || !/^\d+(\.\d{1,2})?$/.test(row.Amount__c)) {
            error = 'Amount is required/must be valid';
        } else if (!this.isValidReason(row.Reason__c)) {
            error = 'Reason is required and must be a valid option';
        }

        seenWaybills.add(String(row.Name));

        return {
            rowId: idx,
            Name: row.Name,
            Amount__c: row.Amount__c,
            waybillError: error === 'Waybill is required' || error === 'Waybill must be 12 digits' || error === 'Duplicate waybill in uploaded file',
            amountError: error === 'Amount is required/must be valid',
            reasonError: error === 'Reason is required and must be a valid option',
            Reason__c: [...new Set(
                            (row.Reason__c || '')
                                .split(',')
                                .map(v => v.trim())
                                .filter(v => v)
                        )].join(', '),
            Remarks__c: row.Remarks__c,
            error,
            isDuplicate,
            errorClass: error ? 'slds-text-color_error' : ''
        };
    }

    handleInsert() {
        const rowsToInsert = [...this.nonDuplicateData];
        if(rowsToInsert.filter(r => r.waybillError || r.amountError || r.reasonError).length > 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Insert Failed',
                message: `Some records contain validation issues. Please review and correct:
                • Waybill issues: ${rowsToInsert.filter(r => r.waybillError).length}
                • Amount issues: ${rowsToInsert.filter(r => r.amountError).length}
                • Reason issues: ${rowsToInsert.filter(r => r.reasonError).length}`,    
                variant: 'error'
            }));
            return;
        }
        // Show overlay spinner across the window during insert
        this.isLoading = true;
        saveWaybills({ caseId: this.recordId, rows: rowsToInsert })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Waybills inserted successfully.',
                    variant: 'success'
                }));
                this.resetModal();
                // Refresh existing data to reflect new inserts
                this.fetchExistingData();
            })
            .catch(err => {
                const message = err && err.body && err.body.message ? err.body.message : 'Unknown error while saving waybills.';
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Save Failed',
                    message,
                    variant: 'error'
                }));
            })
            .finally(() => { this.isLoading = false; });
    }

    handleCancel() {
        this.resetModal();
    }

    handleDownloadTemplate() {
        try {
            const wsData = [
                ['Name', 'Amount__c', 'Reason__c', 'Remarks__c'],
                ...this.templateRows.map(r => [r.Name, r.Amount__c, r.Reason__c, r.Remarks__c])
            ];
            const worksheet = XLSX.utils.aoa_to_sheet(wsData);
            const workbook = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(workbook, worksheet, 'Template');

            const wbout = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
            const blob = new Blob([wbout], { type: 'application/octet-stream' });
            const url = URL.createObjectURL(blob);

            const link = document.createElement('a');
            link.href = url;
            link.download = 'Waybill_Upload_Template.xlsx';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);

            this.dispatchEvent(new ShowToastEvent({
                title: 'Template Downloaded',
                message: 'Excel template downloaded successfully.',
                variant: 'success'
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Download Failed',
                message: 'Could not generate the Excel template.',
                variant: 'error'
            }));
            console.error(e);
        }
    }

    isValidReason(reasonValue) {
        if (!reasonValue) return false;
        const allowed = this.allowedReasons.map(r => r.toLowerCase());
        const selectedValues = reasonValue
            .split(',')               // split by comma from Excel
            .map(v => v.trim().toLowerCase())
            .filter(v => v);          // remove empty values

        return selectedValues.every(val => allowed.includes(val));
    }


    handleCopyTemplate() {
        try {
            const headers = ['Name', 'Amount__c', 'Reason__c', 'Remarks__c'];
            const rows = this.templateRows.map(r => [r.Name, r.Amount__c, r.Reason__c, r.Remarks__c]);
            const tsv = [headers.join('\t'), ...rows.map(r => r.join('\t'))].join('\n');
            const ta = document.createElement('textarea');
            ta.value = tsv;
            ta.style.position = 'fixed';
            ta.style.left = '-9999px';
            document.body.appendChild(ta);
            ta.select();
            try {
                document.execCommand('copy');
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Copied',
                    message: 'Template copied to clipboard. Paste into Excel/Sheets.',
                    variant: 'success'
                }));
            } catch (err) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Copy Failed',
                    message: 'Could not copy template. Please download the Excel instead.',
                    variant: 'warning'
                }));
            } finally {
                document.body.removeChild(ta);
            }
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Copy Failed',
                    message: 'Could not copy the template to clipboard.',
                variant: 'error'
            }));
                console.error(e);
        }
    }

    resetModal() {
        this.showModal = false;
        this.nonDuplicateData = [];
        this.duplicateData = [];
        this.filteredDuplicateData = [];
    }

    fetchExistingData() {
        this.isLoading = true;
        getExistingWaybillNumbers({ caseId: this.recordId })
            .then(result => {
                this.existingWaybills = new Set(result);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Load Failed',
                    message: 'Could not load existing waybills. Error: ' + (error && error.body && error.body.message ? error.body.message : 'Unknown error'),
                    variant: 'error'
                }));
                console.error(error);
            })
            .finally(() => { this.isLoading = false; });
    }

    // Getters for conditional rendering
    get hasNonDuplicateData() {
        return this.nonDuplicateData && this.nonDuplicateData.length > 0;
    }

    get noDataToInsert() {
        return !this.nonDuplicateData || this.nonDuplicateData.length === 0;
    }

    get hasDuplicateData() {
        return this.filteredDuplicateData && this.filteredDuplicateData.length > 0;
    }

    getTableStyle(data) {
        if (!data?.length) return '';
        return `height:${(Math.min(data.length, 10) * 40) + 40}px;`;
    }

    get datatableStyleNonDuplicate() {
        return this.getTableStyle(this.nonDuplicateData);
    }

    get datatableStyleDuplicate() {
        return this.getTableStyle(this.filteredDuplicateData);
    }

}