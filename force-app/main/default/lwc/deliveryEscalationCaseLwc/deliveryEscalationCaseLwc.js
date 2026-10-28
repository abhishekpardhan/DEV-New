import { LightningElement, api } from 'lwc';
import BRAND_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';
import TRUCK_IMG  from '@salesforce/resourceUrl/SafexpressTruck';
import ROAD_IMG   from '@salesforce/resourceUrl/SafexpressRoad';

export default class SafexpressWaybillEnquiryLWCCard extends LightningElement {
    @api value;

    logoUrl = BRAND_LOGO;
    truckUrl = TRUCK_IMG;
    roadUrl  = ROAD_IMG;

    get cardData() {
        let raw = this.value;
        if (typeof raw === 'string') {
            try {
                raw = JSON.parse(raw);
            } catch (e) {
                raw = null;
            }
        }
        return raw && typeof raw === 'object' ? raw : null;
    }

    // Determine state flags
    get isError() {
        const d = this.cardData;
        return Boolean(d && d.errorMessage && !d.waybillNumberFormatted && !d.caseNumber);
    }

    get isFreshCase() {
        const d = this.cardData;
        // Triggered if JSON has isFreshCase set to true OR has a caseNumber with plain text escalation context
        return Boolean(d && (d.isFreshCase === true || (d.caseNumber && !d.lastEvent && !d.currentStatus)));
    }

    get isStandardData() {
        const d = this.cardData;
        if (!d) return true; // Default preview state
        return !this.isError && !this.isFreshCase;
    }

    get headerTitle() {
        const d = this.cardData;
        if (d && d.headerTitle) return d.headerTitle;
        if (this.isFreshCase) return '🚨 Escalation Case Created';
        return '🚚 Waybill Status';
    }

    get successMessage() {
        const d = this.cardData;
        return d && d.successMessage ? d.successMessage : 'Your escalation case has been successfully logged and routed to the Complaints queue.';
    }

    get waybillNumberFormatted() {
        const d = this.cardData;
        return d ? (d.waybillNumberFormatted || d.waybillNumber) : null;
    }

    get lastEvent() {
        return this.cardData ? this.cardData.lastEvent : null;
    }

    get currentStatus() {
        return this.cardData ? this.cardData.currentStatus : null;
    }

    get deliveryLocation() {
        return this.cardData ? this.cardData.deliveryLocation : null;
    }

    get deliveredOn() {
        return this.cardData ? this.cardData.deliveredOn : null;
    }

    get caseNumber() {
        return this.cardData ? this.cardData.caseNumber : null;
    }

    get hasCaseNumber() {
        return Boolean(this.caseNumber);
    }

    get hasDeliveredOn() {
        return Boolean(this.deliveredOn);
    }

    get hasDeliveryLocation() {
        return Boolean(this.deliveryLocation);
    }

    get errorMessage() {
        return this.cardData ? this.cardData.errorMessage : null;
    }

    get footerNote() {
        const d = this.cardData;
        return d && d.footerNote ? d.footerNote : '🙏 Thank you for choosing Safexpress. 😊';
    }
}