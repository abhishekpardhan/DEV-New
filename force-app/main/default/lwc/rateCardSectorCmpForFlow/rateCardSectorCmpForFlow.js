import { api, LightningElement } from 'lwc';

export default class RateCardSectorCmpForFlow extends LightningElement {
    @api displayText;
    @api modeOfTransPort;
    @api prcId;
    @api sfxId;
    @api rateCardName;
    @api subType;

    handleAccountSelection(event){
        
        console.log(event.detail.Parent.Name);
        console.log(event.detail.Parent.Parent.Name);
        console.log(event.detail.Name);
        console.log(event.detail.Id);
        console.log(event.detail);

        this.rateCardName = event.detail.Name;
        this.displayText = event.detail.Rate_Card_Formula__c;
        this.modeOfTransPort = event.detail.Parent.Name.toLowerCase() === 'air' ?  'Air' : 'Surface';
        this.sfxId  = event.detail.Parent.Parent.Name.toLowerCase().startsWith('sfx') ? event.detail.Parent.Parent.Id : null;
        this.prcId  = event.detail.Parent.Parent.Name.toLowerCase().startsWith('prc') ? event.detail.Parent.Parent.Id : null;

    } 
    handleRemovePill() {
        this.displayText = undefined;
        this.rateCardName = undefined;
        this.displayText = undefined;
        this.modeOfTransPort = undefined;
        this.prcId  = undefined;
    }
}