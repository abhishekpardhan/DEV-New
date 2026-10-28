import { LightningElement, track, wire } from 'lwc';
import getPropelIBDMMapping from '@salesforce/apex/cls_propelIPortfolioBDMMapping.getPropelIBDMMapping';

export default class BdmReport extends LightningElement {
    @track data;

    connectedCallback() {
        getPropelIBDMMapping()
        .then(result => {
            console.log('--- 10 JSON.stringify(result): ' + JSON.stringify(result));
            this.data = result;
        })
        .catch(error => {

        });
    }

    handleSectionToggle(event){
        console.log(event.detail.openSections);
    }
}