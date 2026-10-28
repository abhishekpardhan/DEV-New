import { api, LightningElement } from 'lwc';
import getCasesWithWayBill from '@salesforce/apex/GetWayBillStatusAPI.getCases';
import { NavigationMixin } from 'lightning/navigation';



export default class RecentCasesByWayBill extends LightningElement {
    @api wayBillNumber;
    @api recordLimit = 10;
    isSpinnerShow = true;
    caseData = {};
    columns = [{
        label: 'Case Number',
        fieldName: 'CaseNumber',
        type: 'text'
    },
    {
        label: 'Subject',
        fieldName: 'Subject',
        type: 'text'
    },
    {
        label: 'Case Nature',
        fieldName: 'Case_Nature__c',
        type: 'text'
    },
    {
        label: 'Case Type',
        fieldName: 'Case_Type__c',
        type: 'text'
    },
    {
        label: 'Status',
        fieldName: 'Status',
        type: 'text'
    },
    ];


    connectedCallback(){ 
        this.getCases();
    }
    getCases() {
        this.isSpinnerShow = true;
        console.log('this.wayBillNumber '+this.wayBillNumber);
        getCasesWithWayBill({
            waybillNo: this.wayBillNumber,
            recordLimit : this.recordLimit
            }).then(result => {
                this.isSpinnerShow = false;
                console.log('getCasesWithWayBill result ::', result);
                try {
                    if(result !== undefined){
                        this.caseData = JSON.parse(result);
                    }
                } catch (e) {
                    console.log(e.message);
                }
            })
            .catch(error => {
                this.closeModal();
                this.isSpinnerShow = false;
                this.errorMassage = error.body.message;
                console.log('error ====> ' + JSON.stringify(error));
                this.showToast('Error', error.body.message, 'error');
            });
    }
}