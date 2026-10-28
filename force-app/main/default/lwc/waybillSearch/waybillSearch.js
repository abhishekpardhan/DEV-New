import { LightningElement,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getWayBillInfo from '@salesforce/apex/GetWayBillStatusAPI.getWayBillInfo';

export default class WaybillSearch extends LightningElement {

    isSpinnerShow = false;
    WayBillStatus;
    errorMassage ; 
    trackData;
    waybillInfo = {};
    isSearchDisabled = false;
    showDetail = false;
    searchedWayBillNo;

    dodDaccAmt;

    handleWayBillChange(event) {
        this.errorMassage = undefined;
        let numbers = /^[0-9]+$/;
        if (event.detail.value.match(numbers)) {
            this.searchedWayBillNo = event.detail.value;
            this.isSearchDisabled = false;
        } else {
            this.errorMassage = 'Please enter number only.';
            this.isSearchDisabled = true;
        }
        //console.log(event.detail.value);
    }
    handleSearch() {
        console.log('searchedWayBillNo : ' + this.searchedWayBillNo);
        this.showDetail = false;
        this.errorMassage = undefined;
        if (!this.searchedWayBillNo) {
            this.errorMsg = 'Please enter Waybill number to search.';
        }else if (this.searchedWayBillNo.indexOf(",") != -1) {
            this.errorMsg = 'You have entered an invalid waybill number.';
        }else{
            
            this.isSpinnerShow = true;
            getWayBillInfo({
                waybillNo: this.searchedWayBillNo
            }).then(result => {
                this.isSpinnerShow = false;
                console.log('search result ::',result);
                try{
                if(result){
                    this.displayResult(JSON.parse(result));
                }}catch(e){
                    console.log(e.message);
                }
            })
            .catch(error => {
                this.isSpinnerShow = false;
                this.errorMassage = error.body.message;
                console.log('error ====> ' + JSON.stringify(error));
                this.showToast('Error',error.body.message,'error');
            });
        }
    }
    displayResult(result){
        if(result.data && !result.message){
            this.waybillInfo = result.data;
            if(this.waybillInfo.dodDacc && this.waybillInfo.dodDacc.dodDaccAmt){
                this.dodDaccAmt = this.waybillInfo.dodDacc.dodDaccAmt;
            }
            this.waybillInfo.freight = Math.ceil(this.waybillInfo.freight + this.waybillInfo.freightSt);  //Math.ceil(resultData.freight+ resultData.freightSt);
            this.trackData = result.data.track;
            this.showDetail = true;
            if(this.trackData){
                this.WayBillStatus = this.trackData[0].websiteMsg;
            }
        }else if(!result.data && result.message){
            this.errorMassage = result.message;
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