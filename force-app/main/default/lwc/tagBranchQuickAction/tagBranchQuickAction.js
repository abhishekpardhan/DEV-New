import { LightningElement, api, track } from 'lwc';
import searchBranches from '@salesforce/apex/BookingBranchSelectorController.searchBranches';
import associateBranchToRelation from '@salesforce/apex/BookingBranchSelectorController.associateBranchToRelation';
import removeBranchFromRelation from '@salesforce/apex/BookingBranchSelectorController.removeBranchFromRelation';

import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TagBranchQuickAction extends LightningElement {
    @api recordId; // Contact Id
    @track branches = [];
    @track selectedBranchId;
    @track selectedBranchName;
    @track searchKey = '';
    @track existingBranchName = ''; // already associated branch
    @track isBranchSelectedFromList = false; // <== new flag to track selection from list

    showError = false;
    showAssignedBranchBtn = false;

    connectedCallback() {
        const currentUrl = window.location.href;
        const params = new URLSearchParams(new URL(currentUrl).search);
        this.recordId = params.get("recordId");
        console.log('recordId', this.recordId);
        if (this.recordId) {
            this.loadBranches();
        }
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;

        // if (!this.searchKey) {
        //     this.resetSelection();
        //     return;
        // }

        searchBranches({ searchKey: this.searchKey, ContactId: this.recordId })
            .then(result => {
                console.log('result>>'+JSON.stringify(result));
                
                if (result.branches.length > 0) {
                    this.branches = result.branches;
                    this.showError = false;
                } else {
                    this.branches = [];
                    this.showError = true;
                    this.showAssignedBranchBtn = false;
                }
            })
            .catch(error => {
                this.branches = [];
                this.showError = true;
                this.showAssignedBranchBtn = false;
                console.error('Search error:', error);
            });
    }

    handleSearchFocus() {
        this.loadBranches();
    }

    loadBranches() {
        searchBranches({ ContactId: this.recordId })
            .then(result => {
                console.log('result68>>'+JSON.stringify(result));

                if (result && result.branches && result.branches.length > 0) {
                    this.branches = result.branches;
                    this.showError = false;
                } else {
                    this.branches = [];
                    this.showError = true;
                }

                if (result && result.existingBranch) {
                    this.existingBranchName = result.existingBranch.Name;
                    this.selectedBranchId = result.existingBranch.Id;
                   // this.searchKey = this.existingBranchName;
                    this.showAssignedBranchBtn = false;  // Show Associate Branch button
                    this.isBranchSelectedFromList = false; // No new selection yet
                } else {
                    this.existingBranchName = '';
                    this.showAssignedBranchBtn = false;
                    this.isBranchSelectedFromList = false;
                }
            })
            .catch(error => {
                this.showError = true;
                this.branches = [];
                this.existingBranchName = '';
                this.showAssignedBranchBtn = false;
                this.isBranchSelectedFromList = false;
            });
    }

    handleSelectBranch(event) {
        this.selectedBranchId = event.currentTarget.dataset.id;
        const selectedBranch = this.branches.find(branch => branch.Id === this.selectedBranchId);

        if (selectedBranch) {
            this.selectedBranchName = selectedBranch.Name;
            this.searchKey = this.selectedBranchName;
            this.showAssignedBranchBtn = true;
            this.isBranchSelectedFromList = true;  // <== mark branch selected from list
        } else {
            this.resetSelection();
        }

        this.branches = [];
    }

    resetSelection() {
        this.selectedBranchId = null;
        this.selectedBranchName = '';
        this.searchKey = '';
        this.showAssignedBranchBtn = false;
        this.isBranchSelectedFromList = false; // <== reset flag here
        this.branches = [];
    }

    handleAssociate() {
        if (!this.selectedBranchId) return;
        console.log('this.recordId>>'+this.recordId);
        console.log('this.selectedBranchId>>'+this.selectedBranchId);
        
        associateBranchToRelation({
            branchId: this.selectedBranchId,
            contactId: this.recordId,
            branchName: this.selectedBranchName
        })
            .then(() => {
                getRecordNotifyChange([{ recordId: this.recordId }]);

                this.showToast('Success', 'Branch associated successfully!', 'success');
                this.existingBranchName = this.selectedBranchName;
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('Error associating branch:', error);
                this.showToast('Error', error.body?.message || 'You don’t have permission to tag or reassign this branch. Please contact your administrator.', 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    handleRemoveTag() {
        removeBranchFromRelation({ contactId: this.recordId })
            .then(() => {
                getRecordNotifyChange([{ recordId: this.recordId }]);

                this.showToast('Success', 'Branch tag removed successfully!', 'success');
                this.existingBranchName = '';
                this.resetSelection();
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('Error removing branch:', error);
                this.showToast('Error', error.body?.message || 'Error removing tag.', 'error');
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}