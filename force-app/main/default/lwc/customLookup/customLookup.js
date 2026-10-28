import lookUp from '@salesforce/apex/customLookUpController.search';
import { api, LightningElement, track, wire } from 'lwc';


export default class customLookUp extends LightningElement {

    @api objName;
    @api displayText;

    @api fieldName;
    @api iconName;
    @api filter = '';
    @api searchPlaceholder='Search';
    @track records;
    @track isValueSelected;
    @track blurTimeout;
    searchTerm;
    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';
    @wire(lookUp, {searchTerm : '$searchTerm',fieldName : '$fieldName', myObject : '$objName', filter : '$filter'})
    wiredRecords({ error, data }) {
        console.log('data ',data);
        if (data) {
            this.error = undefined;
            this.records = data;
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }
    handleClick() {
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }
    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }
    onSelect(event) {
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;
        let selectedRecord = this.records.find(obj => obj.Id === selectedId)

        const valueSelectedEvent = new CustomEvent('lookupselected', {detail:  selectedRecord });
        this.dispatchEvent(valueSelectedEvent);
       
        this.isValueSelected = true;
        this.selectedName = selectedName;
        
        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    handleRemovePill() {
        this.isValueSelected = false;
    }

    onChange(event) {
        this.searchTerm = event.target.value;
    }

}