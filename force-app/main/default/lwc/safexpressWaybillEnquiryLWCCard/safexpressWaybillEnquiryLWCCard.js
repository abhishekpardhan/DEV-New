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

    // Error only when errorMessage is present AND no waybill
    get isError() {
        const d = this.cardData;
        return Boolean(d && d.errorMessage && !d.waybillNumberFormatted);
    }

    // Show data card when waybillNumberFormatted present OR when no data at all (preview)
    get hasData() {
        const d = this.cardData;
        if (!d) return true; // preview state — show data card template
        return Boolean(d.waybillNumberFormatted);
    }

    get headerTitle() {
        const d = this.cardData;
        return d && d.headerTitle ? d.headerTitle : '🚚 Waybill Status';
    }

    get waybillNumberFormatted() {
        return this.cardData ? this.cardData.waybillNumberFormatted : null;
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