import {LightningElement,api} from 'lwc';
import FREIGHT_CALCULATOR_URL from '@salesforce/label/c.Freight_Calculator_Url';
export default class FreightCalculator extends LightningElement {

    iframeHeight = '800px';
    iframeWidth = '100%';
    @api recordId;
    connectedCallback() {
        //console.log('--- Record Id --- '+this.recordId);
        if (this.recordId) {
            this.iframeHeight = 350;
            // console.log('i m in if condition '+this.iframeHeight+' - '+this.iframeWidth);
        }
    }
    get fulUrl() {
        return FREIGHT_CALCULATOR_URL;
    }
}