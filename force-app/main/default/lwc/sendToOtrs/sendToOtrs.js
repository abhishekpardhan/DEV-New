import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import OTRSCreateTicket from '@salesforce/apex/OTRS_UtilClass.OTRSCreateTicket';
// import UpdateCase from '@salesforce/apex/OTRS_UtilClass.updateOTRSTicketOnCase';
import createFreshserviceTicket from '@salesforce/apex/Freshservice_UtilClass.createFreshserviceTicket';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SendToOtrs extends LightningElement {
    ticketNumber = '';
    otrsTicketNumber;
    @api recordId;

    connectedCallback() {
        if (!this.otrsTicketNumber) {
            // this.createTicketOTRS();
            this.createTicketFreshservice();
        } else {
            this.showToast('Information!', 'This Case is already sent to Freshservice System', 'info');
            this.closeModal();
        }
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    createTicketFreshservice() {
        console.log('createTicketFreshservice ---> ' + this.recordId);

        createFreshserviceTicket({
            recordId: this.recordId
        }).then(result => {
            try {
                console.log('createFreshserviceTicket result ::', result);

                let parsedResult = typeof result === 'string'
                    ? JSON.parse(result)
                    : result;

                this.closeModal();

                // if (parsedResult.type === 'SUCCESS') {
                //     this.showToast(
                //         'Success!',
                //         parsedResult.message
                //             ? parsedResult.message
                //             : 'Freshservice ticket creation initiated.',
                //         'success'
                //     );

                //     eval("$A.get('e.force:refreshView').fire();");
                // } else {
                //     this.showToast(
                //         'Error!',
                //         parsedResult.message
                //             ? parsedResult.message
                //             : 'Freshservice ticket creation failed.',
                //         'error'
                //     );
                // }
                if (parsedResult.type === 'SUCCESS') {
                    this.showToast(
                        'Success!',
                        parsedResult.message
                            ? parsedResult.message
                            : 'Freshservice ticket creation initiated.',
                        'success'
                    );

                    eval("$A.get('e.force:refreshView').fire();");
                } else if (parsedResult.type === 'ERROR') {
                    this.showToast(
                        'Error!',
                        parsedResult.message
                            ? parsedResult.message
                            : 'Freshservice ticket creation failed.',
                        'error'
                    );
                }
            } catch (e) {
                this.closeModal();
                console.log(e.message);
                this.showToast('Error!', e.message, 'error');
            }
        }).catch(error => {
            this.closeModal();
            console.log('error ====> ' + JSON.stringify(error));
            this.showToast(
                'Error',
                error.body && error.body.message
                    ? error.body.message
                    : 'Freshservice ticket creation failed',
                'error'
            );
        });
    }

    /*
    createTicketOTRS() {
        console.log('createTicketOTRS  ---> ' + this.recordId);
        OTRSCreateTicket({
            recordId: this.recordId
        }).then(result => {
            try {
                let parsedResult = JSON.parse(result);
                console.log(parsedResult);
                if (parsedResult.type === "SUCCESS") {
                    parsedResult = JSON.parse(parsedResult.message);
                    if (parsedResult && parsedResult.message === 'success') {
                        let otrsTicketNumber = parsedResult.response[0].TicketNumber;
                        console.log('otrsTicketNumber ' + otrsTicketNumber);
                        if (otrsTicketNumber) {
                            this.updateTicketOnCase(otrsTicketNumber);
                        } else {
                            this.closeModal();
                            this.showToast('Error!', 'Something went wrong!, Please try again', 'error');
                        }
                    }
                } else {
                    if (parsedResult.message === "Invalid Case Id") {
                        this.createTicketOTRS();
                        return;
                    }
                    this.closeModal();
                    this.showToast('Error!', parsedResult.message, 'error');
                }
            } catch (e) {
                console.log(e.message);
            }
        }).catch(error => {
            this.closeModal();
            this.errorMassage = error.body.message;
            console.log('error ====> ' + JSON.stringify(error));
            this.showToast('Error', error.body.message, 'error');
        });
    }

    updateTicketOnCase(otrsTicketNumber) {
        this.otrsTicketNumber = otrsTicketNumber;
        UpdateCase({
            otrsTicketNumber: otrsTicketNumber,
            recordId: this.recordId
        }).then(result => {
            console.log('updateTicketOnCase result ::', result);
            try {
                this.closeModal();
                result = JSON.parse(result);
                if (result.type === 'SUCCESS') {
                    this.showToast('Success!', 'Case Updated with OTRS System. OTRS Ticket Number is ' + otrsTicketNumber, 'success');
                    eval("$A.get('e.force:refreshView').fire();");
                    return;
                } else {
                    this.showToast('Error!', result.message, 'error');
                }
            } catch (e) {
                console.log(e.message);
            }
        }).catch(error => {
            this.closeModal();
            this.errorMassage = error.body.message;
            console.log('error ====> ' + JSON.stringify(error));
            this.showToast('Error', error.body.message, 'error');
        });
    }
    */

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}