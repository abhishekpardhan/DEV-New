import { LightningElement , api } from 'lwc';
import LightningModal from 'lightning/modal';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import fetchITRecord from '@salesforce/apex/RefreshBookingRequest.fetchITRecord';

export default class ItQueueableCall extends LightningElement{
    @api recordId;
  handleUpdateClick() {
        fetchITRecord({ caseId: this.recordId })
            .then(result => {
                console.log('IT record fetched successfully:', result);
                //return closeModal();
                this.dispatchEvent(new CloseActionScreenEvent());

            })
            .catch(error => {
                console.error('Error fetching IT record:', error);
                this.showToast("Error", "Maximum retry attempts reached", "error");
                this.dispatchEvent(new CloseActionScreenEvent());

            });
    } 
   
    showToast(titleval, msg, varianttype) {
        const event = new ShowToastEvent({
            title: titleval,
            message: msg,
            variant: varianttype,
            mode: "dismissable"
        });
        this.dispatchEvent(event);
        //alert(msg);
    }   
    }