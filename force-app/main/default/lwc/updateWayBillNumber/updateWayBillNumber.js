import { LightningElement, api, wire } from 'lwc';

import getWayBillInfo from '@salesforce/apex/GetWayBillStatusAPI.getWayBillInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent' 
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import WAYBILL_FIELD from "@salesforce/schema/Case.WaybillNo__c";
import { NavigationMixin } from "lightning/navigation";

const fields = [WAYBILL_FIELD];

export default class UpdateWayBillNumber extends NavigationMixin(LightningElement) {

isSpinnerShow = false;
wayBillNumber;
@api objectApiName;
@api recordId; 
isUpdateDisabled = false;
errorMassage;

@wire(getRecord, { recordId: "$recordId", fields })
case;

connectedCallback(){
    this.isSpinnerShow = true;
    setTimeout(()=>{

        this.wayBillNumber = getFieldValue(this.case.data, WAYBILL_FIELD) ;
        console.log('this.wayBillNumber -->'+this.wayBillNumber );
        this.isSpinnerShow = false;
    },2000);
    
}

renderedCallback(){
        
}

get waybill() {
    return getFieldValue(this.case.data, WAYBILL_FIELD);
}

handleWayBillNumberChange(event){
    console.log('event.target.value-->'+event.target.value);
    this.wayBillNumber = event.target.value;
    this.errorMassage = undefined;
    let numbers = /^[0-9]+$/;
    if (event.detail.value.match(numbers)) {
        this.wayBillNumber = event.target.value;             
    } else {
        this.errorMassage = 'Please enter number only.'; 
                    
    }
}


handleUpdateWayBillNumber(event){
    console.log('this.wayBillNumber ::',this.wayBillNumber);
    let numbers = /^[0-9]+$/;
    if (this.wayBillNumber !== undefined && this.wayBillNumber.match(numbers)) {
        this.isSpinnerShow = true;
        getWayBillInfo({
            waybillNo: this.wayBillNumber, recordId : this.recordId, isUpdate:true
        }).then(result => {
            this.isSpinnerShow = false;
            console.log('search result ::',result);
            let apiResult = JSON.parse(result);
            console.log(apiResult);
            if('message' in apiResult){ 
                if(apiResult.message == null){
                    this.showToast('Updated','Waybill Updated','success');
                    console.log('updated...');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,                             
                            actionName: 'view'
                        }
                    });
                        
                }
                else {
                    this.errorMassage = 'Waybill ' +apiResult.message;
                } 
            }
            
        })
        .catch(error => {
            this.isSpinnerShow = false;
            console.log('error ====> ' + JSON.stringify(error));

        });          
    } else {
        this.errorMassage = 'Please enter number only.'; 
                
    }
    
}

showToast(title,message,variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    });
    this.dispatchEvent(event);
}

}