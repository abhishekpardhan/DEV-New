import { LightningElement, wire, api, track } from 'lwc';
import getList from '@salesforce/apex/CommonController.getList';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';

const ROWS_PER_PAGE = 10; // Set the number of rows per page

export default class DisplayRelationShipMapping extends NavigationMixin(LightningElement) {
    @api fields; // comma-separated field API names
    @api objectName;
    @api relationshipWithObj;
    @api recordId;
    @track columns = [];
    @track data = [];
    @track paginatedData = []; // Data for the current page
    @track objectLabel = '';
    @track objectPluralLabel = '';

    @track currentPage = 1; // Track the current page
    totalPages = 0;

    // Fetch object metadata to get field labels and object label
    @wire(getObjectInfo, { objectApiName: '$objectName' })
    objectInfoWire({ data, error }) {
        if (data) {
            this.objectLabel = data.label +'(Relationship)';
            this.objectPluralLabel = data.labelPlural;
            this.createColumns(data); // Pass the metadata to create columns
        } else if (error) {
            console.error('Error retrieving object info: ', error);
        }
    }

    // Fetch records using @wire and Apex method
    @wire(getList, {
        fields: '$fields',
        objAPIName: '$objectName',
        relationshipWithObj: '$relationshipWithObj',
        recordId: '$recordId'
    })
    getListDetails({ error, data }) {
        if (data) {
            this.data = data;
            this.totalPages = Math.ceil(this.data.length / ROWS_PER_PAGE);
            this.updatePaginatedData(); // Set initial page data
        } else if (error) {
            console.error('Error retrieving data: ', error);
        }
    }

    // Create columns using field API names and labels from object metadata
    createColumns(objectInfo) {
        if (objectInfo && this.fields) {
            const fieldList = this.fields.split(',').map(field => field.trim());
            this.columns = fieldList.map(fieldApiName => {
                const fieldLabel = objectInfo.fields[fieldApiName]?.label || fieldApiName;
                return { label: fieldLabel, fieldName: fieldApiName };
            });

        
        }
    }

    // Define the row actions
    getRowActions(row, doneCallback) {
        const actions = [
            {
                label: 'View',
                name: 'view',
            },
        ];
        doneCallback(actions);
    }

    // Handle row action for navigating to the record
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: this.objectName,
                    actionName: 'view'
                }
            });
        }
    }

    // Handle previous page button click
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updatePaginatedData();
        }
    }

    // Handle next page button click
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.updatePaginatedData();
        }
    }

    // Slice the data to show only the records for the current page
    updatePaginatedData() {
        const start = (this.currentPage - 1) * ROWS_PER_PAGE;
        const end = this.currentPage * ROWS_PER_PAGE;
        this.paginatedData = this.data.slice(start, end);
    }

    // Getters for disabling buttons when at the start or end of pagination
    get isPreviousButtonDisabled() {
        return this.currentPage === 1;
    }

    get isNextButtonDisabled() {
        return this.currentPage === this.totalPages;
    }
}