import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//Get WayBill Info
import getWayBillInfo from '@salesforce/apex/GetWayBillStatusAPI.getWayBillInfo';

export default class WayBillSearchForFlow extends LightningElement {

    //api variable for output
    @api wayBillNumber;
    @api WaybillStatus;
    @api edd;
    @api fromBranch;
    @api toBranch;
    @api pickUpDate;
    @api modeOfPayment; 
    @api modeOfDispatch;
    @api freight;
    @api consignorName;
    @api ConsigneeName;
    @api dod_Dacc; 
    @api trackData;
    @api subType;

    @api recordLimit;


    //api variable for Input
    @api isOutputFieldsDisabled;
    @api caseType;


    //track variable for component only
    searchedWayBillNo;
    isSpinnerShow = false;
    errorMassage ; 
    isSearchDisabled = false;
    isCaseHistoryShow = false;
    isTrackShow = false;


    // ======= PickList options functions ==============//
    //Mode of Payment Values
    get optionsModeOfPayment() {
        return [
            { label: 'Paid', value: 'Paid' },
            { label: 'To Pay', value: 'To Pay' }
        ];
    }
    //Mode Of Dispatch Values
    get optionsModeOfDispatch() {
        return [
            { label: 'By Road', value: 'By Road' },
            { label: 'By Air', value: 'By Air' },
            { label: 'Other', value: 'Other' }
        ];
    }
     //Mode Of dod_DACC Values
    get optionsDodDacc() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }
    
    // ======= functions for API Callout==============//
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
        console.log(event.detail.value);
    }

    //handle Search
    handleSearch() {
        this.setValuesToBlank();
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
                    this.setResult(JSON.parse(result));
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
    setResult(result){
        this.setValuesToBlank();
        this.setValues(result);
    }
    setValuesToBlank(){
        this.wayBillNumber = '';
        this.WaybillStatus = '';
        this.edd = undefined
        this.fromBranch = '';
        this.toBranch = '';
        this.pickUpDate = undefined
        this.modeOfPayment = '';
        this.modeOfDispatch = '';
        this.freight = '';
        this.consignorName = '';
        this.ConsigneeName = '';
        this.dod_Dacc = '';
        this.trackData = undefined;
    }
    setValues(result){
        if(result.data && !result.message){
            let resultData = result.data;
            this.wayBillNumber = resultData.waybillNo;
            this.edd = this.parseDate(resultData.edd);
            this.fromBranch = resultData.bookingBranch;
            this.toBranch = resultData.dlvryCity;
            this.pickUpDate = this.parseDate(resultData.pickupDate);
            this.modeOfPayment = resultData.mop;
            this.modeOfDispatch = resultData.mode;
            this.freight = Math.ceil(resultData.freight+ resultData.freightSt);
            this.consignorName = resultData.consignor;
            this.ConsigneeName = resultData.consignee;
            if(resultData.dodDacc){
                this.dod_Dacc = resultData.dodDacc.dodDaccAmt;
            }
            this.trackData = resultData.track;
            // WayBill Status Binding from track
            if(resultData.track){
                this.WaybillStatus = resultData.track[0].websiteMsg;
            }           
        }else if(!result.data && result.message){
            this.errorMassage = result.message;
        }
    }
    parseDate(inputDate){
        let parsedDate = undefined;
        console.log(inputDate);
        var monthNumber = (monthName) => { 
            let monthValue ;
            if(monthName == 'Jan'){
                monthValue = 1;
            }else if(monthName == 'Feb'){
                monthValue = 2;
            }else if(monthName == 'Mar'){
                monthValue = 3;
            }else if(monthName == 'Apr'){
                monthValue = 4;
            }else if(monthName == 'May'){
                monthValue = 5;
            }else if(monthName == 'Jun'){
                monthValue = 6;
            }else if(monthName == 'Jul'){
                monthValue = 7;
            }else if(monthName == 'Aug'){
                monthValue = 8;
            }else if(monthName == 'Sep'){
                monthValue = 9;
            }else if(monthName == 'Oct'){
                monthValue = 10;
            }else if(monthName == 'Nov'){
                monthValue = 11;
            }else if(monthName == 'Dec'){
                monthValue = 12;
            }
            return monthValue;
        };
        if(inputDate){
            let dateValue = inputDate.split('-')[0];
            let monthValue =  monthNumber(inputDate.split('-')[1]);
            let yearValue = inputDate.split('-')[2];
            parsedDate = yearValue +'-'+ monthValue +'-'+ dateValue;
        }
        return parsedDate;

    }
    showToast(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // ======= functions for fields Change is not is not disabled ==============//
    handleWaybillStatusChange(event) {
        this.WaybillStatus = event.detail.value;
    } 
    handleEDDChange(event) {
        this.edd = event.detail.value;
    }
    handleFromBranchChange(event) {
        this.fromBranch = event.detail.value;
    }
    handleToBranchChange(event) {
        this.toBranch = event.detail.value;
    }
    handlePickUpDateChange(event) {
        this.pickUpDate = event.detail.value;
    }
    handleModeOfPaymentChange(event) {
        this.modeOfPayment = event.detail.value;
    } 
    handleModeOfDispatchChange(event) {
        this.modeOfDispatch = event.detail.value;
    } 
    handleConsigneeNameChange(event) {
        this.ConsigneeName = event.detail.value;
    } 
    handleConsignorNameChange(event) {
        this.consignorName = event.detail.value;
    } 
    handleDodDaccChange(event) {
        this.dod_Dacc = event.detail.value;
    }
    handleCaseHistoryShow(){
        this.isCaseHistoryShow = true;
    }
    handleClickTrack(){
        this.isTrackShow = true;
    }
    handleWayBillModalClose() {
        this.isCaseHistoryShow = false;
        this.isTrackShow = false;
    }
}