import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAddressInfo from '@salesforce/apex/AddressController.getAddress';



export default class PincodeInfo extends LightningElement {

    // Input variables from flow Screen
    @api pincodeLabel = 'Pincode';
    @api addressLabel = 'Address';
    @api showAddressWithBranch ;
    @api showAddressWithPOName ;
    @api isCompleteAddressShow ;

    // Output Variables to Flow Screen 
    @api completeAddress;
    @api pincode;
    @api branch;
    @api poName;
    @api city;
    @api state;
    @api country;

    @api inputPinCode;
    @api completeAddressForDisplay; 
    
    // Other Variables 
    errorMassage;
    isSpinnerShow ;

    connectedCallback(){
        if(this.inputPinCode && this.completeAddressForDisplay){
            this.completeAddress = this.completeAddressForDisplay;
            this.inputPinCode = this.inputPinCode;
        }
    }

    handlePincodeChange(event){
        this.errorMassage = undefined;
        let numbers = /^[0-9]+$/;
        if (event.detail.value.match(numbers)) {
            this.pincode = event.detail.value;
        } else {
            this.errorMassage = 'Please enter number only.';
        }    
        if(!this.errorMassage && this.pincode && this.pincode.length === 6){
            this.getAddress();
        }
    }
    getAddress(){
        this.isSpinnerShow = true;
        getAddressInfo({
            pincode: this.pincode
        }).then(result => {
            this.isSpinnerShow = false;
            console.log('result getAddressInfo ::',result); 
            try{
            if(result){
                this.setResult(JSON.parse(result));
            }}catch(e){
                console.log(e.message);
            }
        })
        .catch(error => {
            this.isSpinnerShow = false;
            console.log('error ====> ' + JSON.stringify(error));
            this.showToast('Error',error.body.message,'error');
        });
    }
    setResult(result){
        console.log(result);
        if (result && result.type === 'SUCCESS') {
            let data = JSON.parse(result.message);
            console.log(data);
            let address = '';
            address += data.State__c ? data.State__c + ', ' : ''; 
            address += data.City__c ? data.City__c + ', ' : ''; 
            address += data.District__c ? data.District__c + ', ' : ''; 
            address += data.Branch_Name__c && this.showAddressWithBranch ? data.Branch_Name__c + ', ' : '';
            address += data.PO_Name__c && this.showAddressWithPOName ? data.PO_Name__c + ', ' : ''; 
            address += data.Pincode__c ? data.Pincode__c + ', ' : '';  
            address += data.Country__c ? data.Country__c : '';

            this.completeAddress = address; 
            this.completeAddressForDisplay = address;
            this.inputPinCode = data.Pincode__c;

            this.pincode = data.Pincode__c;
            this.branch = data.Branch_Name__c ? data.Branch_Name__c : '';
            this.poName = data.PO_Name__c ? data.PO_Name__c : '';
            this.city = data.City__c ? data.City__c : ''; 
            this.state = data.State__c ? data.State__c : '';
            this.country = data.Country__c ? data.Country__c : '';
            this.showToast('Success','Complete Address loaded Successfully.','success');

        }else{
            this.errorMassage = result.message;
            this.showToast('Error',result.message,'error');
        }
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