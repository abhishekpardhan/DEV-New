import { LightningElement, api,track } from 'lwc';
import findUsers from '@salesforce/apex/ReassignTaskOwnerController.findUsers';
import reassignTaskOwners from '@salesforce/apex/ReassignTaskOwnerController.reassignTaskOwners';
import fetchCompletedTask from '@salesforce/apex/ReassignTaskOwnerController.fetchCompletedTask';
import Toast from 'lightning/toast';

export default class ReassignTaskOwner extends LightningElement {
    isLoading = false; // Spinner flag
    @api label = 'Select Owner';
    @api placeholder = 'Search People...';
    @api records =[];
    @track searchTerm = '';
    isCompleted ;
    @track isInitialized = false; 
    @track successMessage= 'Completed tasks cannot be modified.';
    @track selectedUserId = '';
    @track selectedUserName = '';
    @track taskUsers;
    @track showResults = false;
    @track noResults = false;
    @track selectedTaskId = [];
      
    connectedCallback() {
        //Get selected task Id's...
         if (this.records && this.records.length > 0) {
            this.selectedTaskId = this.records.map(task => task.Id);
        }
        if(this.selectedTaskId != null){
            fetchCompletedTask({ taskIds: this.selectedTaskId })
                .then(result => {
                    if(result == 'Completed tasks cannot be modified.'){
                        this.isCompleted = true;
                    }
                    else{
                         this.isCompleted = false;
                    }
                    this.isInitialized = true;
                })
                .catch(error => {
                    console.error('Error fetching task status:', error);
                    this.isInitialized = true;
                });
        } else {
            this.isInitialized = true; // No records, still set flag
        }
    }
    
    handleSave(event){
        const inputEl = this.template.querySelector('.user-input');
        if (!inputEl.checkValidity()) {
            inputEl.reportValidity(); // Show the custom error
            return; 
        }
        this.isLoading = true; // Show spinner
        if(this.selectedTaskId && this.selectedTaskId != '' && this.selectedUserId){
            reassignTaskOwners({ taskIds: this.selectedTaskId, newOwnerId: this.selectedUserId })
                .then(result => {
                    this.isLoading = false;
                    if(result != 'Tasks reassigned successfully.'){
                        this.showToast("warning", result, "warning");
                    }
                    else{
                        this.showToast("success", result, "success");
                    }
                    setTimeout(() => {
                        window.location.href = `${window.location.origin}/lightning/o/Task/list?filterName=__Recent`; //`${window.location.origin}/lightning/o/Task/list?filterName=__Recent;
                   }, 2000);
                })
                .catch(error => {
                    this.isLoading = false;
                    const errorMsg = error.body?.message || error.message || 'Unknown error';
                    this.showToast("Error", errorMsg, "error");
                });
        } else {
            this.isLoading = false;
            this.showToast("Error", "Please select at least one Task", "error");
        }

    }

    //search user on click of search button
    handleSearch(event) {
        const searchTerm = event.target.value;
        this.selectedUserName = searchTerm;
        if (searchTerm && searchTerm.trim().length > 0) {
            findUsers({ searchKey: searchTerm })
                .then(result => {
                    this.taskUsers = result;
                    this.noResults = result.length === 0;
                    this.showResults = true;
                })
                .catch(error => {
                    console.error('Error searching User: ', error);
                    this.taskUsers = undefined;
                    this.noResults = true;
                    this.showResults = true;
                });
        } else {
            this.taskUsers = undefined;
            this.noResults = false;
            this.showResults = false;
        }
    }

    // select user on click of user card...
    handleSelect(event) {
        const userId = event.currentTarget.dataset.userId;
        this.selectedUserName = userId;
        const selected = this.taskUsers.find(us => us.Name === userId);
       if (selected) {
           this.selectedUserId = selected.Id;
       }
        this.showResults = false;
        this.taskUsers = undefined;
   }
    
    //Show Owners dropdown list...
    showDropdown() {
        if (this.taskUsers && this.taskUsers.length > 0) {
            this.showResults = true;
        }
    }
    
    //clear input field when user clicks on clear button
    clearSelection() {
        this.selectedUserName = '';
        this.taskUsers = undefined;
        this.showResults = false;
        const input = this.template.querySelector('lightning-input');
        if (input) {
            input.focus();
        }
    }

    showToast(title, msg, type) {
        Toast.show(
          {
            label: title,
            message: msg,
            mode: "dismissible",
            variant: type,
            onclose: () => {}
          },
          this
        );
      }

}