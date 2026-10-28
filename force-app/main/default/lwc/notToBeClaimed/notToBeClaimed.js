import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateStatus from '@salesforce/apex/JourneyStatusController.updateStatus';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class NotToBeClaimed extends LightningElement {
    @api recordId;

    // Refresh the view when the component is disconnected
    disconnectedCallback() {
        eval("$A.get('e.force:refreshView').fire();");
    }

    handleYesClick() {
        updateStatus({ journeyId: this.recordId })
            .then((result) => {
                if (result.status === 'success') {
                    this.showToast('Success', result.message, 'success');
                    this.dispatchEvent(new FlowNavigationFinishEvent());// Close alert after success
                } else if(result.message.includes('You must take action on previous journeys before proceeding with this one')){
                    this.showToast('Error', 'You must take action on previous journeys before proceeding with this one.', 'error');
                }else{
                    this.showToast('Error', result.message, 'error');
                }
            })
            .catch((error) => {
                const errorMessage = error.body ? error.body.message : 'Something went wrong. Please try again.';
                this.showToast('Error', errorMessage, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleNoClick() {
        this.dispatchEvent(new FlowNavigationFinishEvent());
    }
}