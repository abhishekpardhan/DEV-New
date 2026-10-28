import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createFreshserviceReply from '@salesforce/apex/Freshservice_UtilClass.createFreshserviceReply';

export default class OtrsNewArticle extends LightningElement {
    @api otrsTicketNumber;
    @api recordId;

    subject = 'Comment from service cloud';
    body = '';
    isSpinnerShow = false;

    handleSubjectChange(event) {
        // this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }

    handleSave() {
        let isInputValid = this.validateInput();

        if (isInputValid) {
            this.isSpinnerShow = true;

            createFreshserviceReply({
                ticketNumber: this.otrsTicketNumber,
                recordId: this.recordId,
                body: this.body
            })
                .then(result => {
                    this.isSpinnerShow = false;

                    try {
                        let parsedResult = JSON.parse(result);
                        console.log('createFreshserviceReply result => ', parsedResult);

                        if (parsedResult.type === 'SUCCESS') {
                            let data = JSON.parse(parsedResult.message);

                            if (data && data.message === 'success') {
                                this.showToast(
                                    'Success',
                                    'Comment added successfully',
                                    'success'
                                );

                                if (
                                    data.response &&
                                    data.response.Article
                                ) {
                                    this.updateArticleList(data.response.Article);
                                } else {
                                    this.updateArticleList(this.buildLocalArticle(data.response.ArticleID));
                                }

                                return;
                            }

                            this.showToast(
                                'Error',
                                'Freshservice reply response format is invalid.',
                                'error'
                            );

                            return;
                        }

                        this.showToast('Error', parsedResult.message, 'error');
                    } catch (e) {
                        console.log(e.message);
                        this.showToast('Error', e.message, 'error');
                    }
                })
                .catch(error => {
                    this.isSpinnerShow = false;

                    console.log('error ====> ' + JSON.stringify(error));

                    this.showToast(
                        'Error',
                        error && error.body && error.body.message
                            ? error.body.message
                            : 'Freshservice comment creation failed.',
                        'error'
                    );
                });
        }
    }

    validateInput() {
        let bodyInput = [...this.template.querySelectorAll('lightning-textarea')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        return !bodyInput || !this.body ? false : true;
    }

    handleCancel() {
        const selectEvent = new CustomEvent('cancel');
        this.dispatchEvent(selectEvent);
    }

    updateArticleList(articleObj) {
        const selectEvent = new CustomEvent('update', {
            detail: articleObj
        });

        this.dispatchEvent(selectEvent);
    }

    buildLocalArticle(articleId) {
        let articleObj = {};

        articleObj.ArticleId = articleId;
        articleObj.From = 'Salesforce';
        articleObj.To = '';
        articleObj.Subject = this.subject;
        articleObj.Body = this.body;
        articleObj.updateTime =
            new Date().toISOString().split('T')[0] +
            ' ' +
            new Date().toLocaleTimeString();

        articleObj.Attachment = [];

        return articleObj;
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