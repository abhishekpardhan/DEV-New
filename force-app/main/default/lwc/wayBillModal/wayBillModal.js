import { LightningElement,api } from 'lwc';

export default class WayBillModal extends LightningElement {
    @api headerText = '';
    @api isTrackHistory = false;
    @api wayBillNumber;
    @api recordLimit = 10;
    @api trackData;
    closeModal(){
        const selectEvent = new CustomEvent('close');
        this.dispatchEvent(selectEvent);
    }
}