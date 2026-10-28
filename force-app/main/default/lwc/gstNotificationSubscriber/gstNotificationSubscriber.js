import { LightningElement,api } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
export default class GstNotificationSubscriber extends LightningElement {

    @api recordId; // Automatically populated when placed on a record page
    subscription = {};
    channelName = '/event/GST_Validation_Event__e';

    connectedCallback() {
        console.log('this.recordid-->'+this.recordId);
        this.registerErrorListener();
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleSubscribe() {
           console.log('this.recordid-->'+this.recordId);
           const messageCallback = (response) => {
            const eventData = response.data.payload;
            console.log('eventData-->'+JSON.stringify(eventData));
            console.log('eventData-->'+eventData.LeadId__c);
            // Only show toast if the event is for this specific record
            if (eventData.LeadId__c == this.recordId && eventData.ErrorMessage__c) {
                   console.log('this.recordid-->'+this.recordId);
                this.showToast(
                    '', 
                    eventData.ErrorMessage__c, 
                    'error'
                );
                setTimeout(() => {
                    this.refreshPage();
                }, 4000);
            }
           /* if(eventData.LeadId__c == this.recordId && eventData.ErrorMessage__c == 'The GST number is duplicate'){
                this.showToast(
                    '', 
                    eventData.ErrorMessage__c+ ' Please verify and update the GST number', 
                    'error'
                );
            }*/
             else if(eventData.LeadId__c == this.recordId && eventData.SuccessMessage__c == 'Valid GST'){
                 console.log('this.recordid-->'+this.recordId);
                    console.log('refresh');
                setTimeout(() => {
                        this.refreshPage();
                    }, 4000);

                this.showToast(
                    'Lead name and customer name is different', 
                     'Lead Name :' + eventData.LeadName__c + ' and Customer Name :' + eventData.GstResponseMsg__c, 
                    'success'
                );
            }
        };

        // Subscribe to the platform event
        subscribe(this.channelName, -1, messageCallback)
            .then(response => {
                this.subscription = response;
                console.log('Successfully subscribed to channel: ', this.channelName);
            })
            .catch(error => {
                console.error('Error subscribing to channel: ', error);
            });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
            console.log('Unsubscribed from channel: ', response);
        });
    }

    registerErrorListener() {
        onError(error => {
            console.error('Received error from server: ', JSON.stringify(error));
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

     refreshPage() {
       window.location.reload();
    }

}