import { LightningElement, wire, track, api } from 'lwc';
import searchLeads from '@salesforce/apex/LeadSearchController.searchLeads';
import createCampaignMembers from '@salesforce/apex/LeadSearchController.createCampaignMembers';

export default class LeadCampaignSearch extends LightningElement {
    @api recordId; // Campaign Id

    searchKey = '';
    @track leadResults = [];
    selectedLeads = new Set();
    remarksMap = {};
    @track showModal = true;

    openModal() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
    }

    handleSearch() {
        searchLeads({ searchTerm: this.searchKey,campaignId: this.recordId })
            .then(result => {
                this.leadResults = result;
            })
            .catch(error => {
                console.error(error);
            });
    }

    handleCheckboxChange(event) {
        const leadId = event.target.dataset.id;
        if (event.target.checked) {
            this.selectedLeads.add(leadId);
        } else {
            this.selectedLeads.delete(leadId);
        }
    }

    handleRemarksChange(event) {
        const leadId = event.target.dataset.id;
        this.remarksMap[leadId] = event.target.value;
    }

    handleSave() {
        const leadIds = Array.from(this.selectedLeads);
        createCampaignMembers({
            campaignId: this.recordId,
            leadIds: leadIds,
            remarksMap: this.remarksMap
        })
        .then(() => {
            alert('Leads successfully added to campaign!');
            this.leadResults = [];
            this.selectedLeads.clear();
            this.remarksMap = {};
        })
        .catch(error => {
            console.error(error);
            alert('Error: ' + error.body.message);
        });
    }
}