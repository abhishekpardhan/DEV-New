import {LightningElement,api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'
import PRE_BOOKING_PROPEL_I from '@salesforce/apex/PropelI_UtilClass.propelCreateTicket';
//import { CloseActionScreenEvent } from 'lightning/actions';

export default class SendToPropelIPreBooking extends LightningElement {
    @api recordId;
    cmpShow = true;
    connectedCallback (){
        this.createPreBooking();
    }
    createPreBooking() {
        console.log('createPreBooking  ---> '+this.recordId);
        PRE_BOOKING_PROPEL_I({
            recordId : this.recordId
            }).then(result => {
                console.log('createPreBooking result ::', result);
                try {
                    let parsedResult = JSON.parse(result);
                    console.log(parsedResult);
                    if (parsedResult.type === "SUCCESS") {
                        this.showToast('Success!', parsedResult.message, 'success');
                        this.cmpShow = false;
                        eval("$A.get('e.force:refreshView').fire();");

                    }else {
                        //this.closeModal();
                        this.showToast('Error From Propel Application!', parsedResult.message, 'error');
                        this.cmpShow = false;
                    }
                } catch (e) {
                    console.log(e.message);
                }
            })
            .catch(error => {
                this.closeModal();
                this.errorMassage = error.body.message;
                console.log('error ====> ' + JSON.stringify(error));
                this.showToast('Error', error.body.message, 'error');
                this.cmpShow = false;
            });
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}