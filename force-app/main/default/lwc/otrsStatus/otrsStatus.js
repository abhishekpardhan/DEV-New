import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFreshserviceTicketDetails from '@salesforce/apex/Freshservice_UtilClass.getFreshserviceTicketDetails';
import updateFreshserviceStatusOnCase from '@salesforce/apex/Freshservice_UtilClass.updateFreshserviceStatus';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class OtrsStatus extends LightningElement {
    @api recordId;

    headerText = 'Freshservice Information';
    isSpinnerShow = false;
    otrsTicketNumber = '';
    ticketDetail;
    articles = [];
    isOtrsInfoShow = false;
    articlesLabel = 'Related Articles';

    connectedCallback() {
        this.getFreshserviceTicketDetails();
    }

    disconnectedCallback() {
        eval("$A.get('e.force:refreshView').fire();");
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    getFreshserviceTicketDetails() {
        this.isSpinnerShow = true;

        getFreshserviceTicketDetails({
            recordId: this.recordId
        })
            .then(result => {
                this.isSpinnerShow = false;

                try {
                    let parsedResult = JSON.parse(result);
                    //console.log('getFreshserviceTicketDetails result => ', parsedResult);

                    if (parsedResult.type === 'SUCCESS') {
                        let data = JSON.parse(parsedResult.message);

                        if (data && data.message === 'success') {
                            this.ticketDetail = data.response.TicketDetail;
                            this.articles = this.ticketDetail.Articles ? this.ticketDetail.Articles : [];
                            this.articlesLabel = 'Related Articles (' + this.articles.length + ')';
                            this.otrsTicketNumber = this.ticketDetail.tnumber;

                            this.updateFreshserviceStatus(this.ticketDetail.state);
                            return;
                        }

                        this.showToast('Error', 'Freshservice response format is invalid.', 'error');
                        return;
                    }

                    if (parsedResult.message === 'Invalid Case Id') {
                        this.getFreshserviceTicketDetails();
                        return;
                    }

                    this.showToast('Error', parsedResult.message, 'error');
                } catch (e) {
                    console.log(e.message);
                    this.showToast('Error', e.message, 'error');
                }
            })
            .catch(error => {
                this.closeModal();
                this.isSpinnerShow = false;

                console.log('error ====> ' + JSON.stringify(error));

                this.showToast(
                    'Error',
                    error && error.body && error.body.message
                        ? error.body.message
                        : 'Freshservice status check failed.',
                    'error'
                );
            });
    }

    updateFreshserviceStatus(freshserviceStatus) {
        this.isSpinnerShow = true;

        updateFreshserviceStatusOnCase({
            freshserviceStatus: freshserviceStatus,
            recordId: this.recordId
        })
            .then(result => {
                this.isSpinnerShow = false;

                console.log('updateFreshserviceStatus result ::', result);

                try {
                    let parsedResult = JSON.parse(result);

                    if (parsedResult.type === 'SUCCESS') {
                        this.headerText =
                            'Freshservice Information for Ticket # ' +
                            this.otrsTicketNumber;

                        this.isOtrsInfoShow = true;

                        this.showToast(
                            'Success!',
                            'Freshservice Information Updated On Case',
                            'success'
                        );

                        return;
                    }

                    this.closeModal();
                    this.showToast('Error', parsedResult.message, 'error');
                } catch (e) {
                    console.log(e.message);
                    this.showToast('Error', e.message, 'error');
                }
            })
            .catch(error => {
                this.closeModal();
                this.isSpinnerShow = false;

                console.log('error ====> ' + JSON.stringify(error));

                this.showToast(
                    'Error',
                    error && error.body && error.body.message
                        ? error.body.message
                        : 'Freshservice status update failed.',
                    'error'
                );
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