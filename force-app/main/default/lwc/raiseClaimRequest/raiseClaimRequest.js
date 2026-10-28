import { LightningElement , api } from "lwc";
import CreateClaimRequest from '@salesforce/apex/CreateCustomCase.createCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class RaiseClaimRequest extends LightningElement {
	@api recordId;
	isSpinnerShow =  false;
   
    @api
    invoke() {
		console.log('headless quick action called');
        console.log(this.recordId);
        this.createClaim();
	}
    createClaim(){
            this.isSpinnerShow = true;
            CreateClaimRequest({
                recordId: this.recordId
            }).then(result => {
                this.isSpinnerShow = false;

                console.log('result createClaim ::',result);
                try{
                if(result ){
                    eval("$A.get('e.force:refreshView').fire();");
                    this.showToast('Success',result,'success');
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
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}