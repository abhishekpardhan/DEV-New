import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import CASE_OBJECT from '@salesforce/schema/Case';
import CANCEL_REASON_FIELD from "@salesforce/schema/Case.Cancel_Reason__c";
import updateCaseStatus from '@salesforce/apex/CancelPreBookingAPI.cancelCaseStatus';
import { getRecord } from 'lightning/uiRecordApi';
import CASE_NUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';


export default class CancelPreBooking extends LightningElement {
    @api recordId;
    caseRecordTypeId;
    showError=false;
    showSpinner = false;
    picklistValues = []
    caseNumber;

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_NUMBER_FIELD] })
    wiredCase({ error, data }) {
        if (data) {
            this.caseNumber = data.fields.CaseNumber.value;
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

   @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    results({ error, data }) {
        if (data) {
        this.caseRecordTypeId = data.defaultRecordTypeId;
        this.error = undefined;
        } else if (error) {
        this.error = error;
        this.caseRecordTypeId = undefined;
        }
    }

   
    @wire(getPicklistValues, { recordTypeId: "$caseRecordTypeId", fieldApiName: CANCEL_REASON_FIELD })
    getPicklistValuesForField({ error, data }) {
    if (error) {
        // TODO: Error handling
        console.error(error)
        } else if (data) {
        this.picklistValues = [...data.values]
        }
    }


    handleUpdateStatus() {
    if (this.selectedReason !=null){
        this.showSpinner = true;
        this.showError = false;
        updateCaseStatus({ recordId: this.recordId, caseId: this.caseNumber, selectedReason: this.selectedReason})
        .then(result => {
            this.showSpinner = false;
            let parsedResult = JSON.parse(result);
            if (parsedResult.type === 'SUCCESS') {
                this.closeModal();
                this.showToast('Success', JSON.parse(parsedResult.message).message, 'success');
            } else if (parsedResult.type === 'ERROR') {
                this.handleError(JSON.parse(parsedResult.message).errors.error[0].description);
            }
        })
        .catch(error => {
            this.handleError('Failed to update case status: ' + error);
        });
    }else{
        this.handleError(' Select Cancellation Reason');
    }
    }

    handleError(message){
        this.showSpinner = false;
        this.showError = true;
        this.caseError = message;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

   /* get reasonOptions() {
        if (this.caseObjectInfo.data) {
            const fieldInfo = this.caseObjectInfo.data.fields.Cancel_Reason__c;
            if (fieldInfo && fieldInfo.picklistValues) {
                return fieldInfo.picklistValues.map(picklistValue => ({
                    label: picklistValue.label,
                    value: picklistValue.value
                }));
            }
        }
        return [];
    }
*/
    handleReasonChange(event) {
        this.showError = false;
        this.selectedReason = event.detail.value;
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    disconnectedCallback(){
        eval("$A.get('e.force:refreshView').fire();");
    }
}