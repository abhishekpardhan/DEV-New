import { LightningElement, api } from 'lwc';
import BRAND_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';
import TRUCK_IMG  from '@salesforce/resourceUrl/SafexpressTruck';
import ROAD_IMG   from '@salesforce/resourceUrl/SafexpressRoad';
// Updated to your new static resource names
import IOS_BADGE     from '@salesforce/resourceUrl/IosStoreLogo';
import ANDROID_BADGE from '@salesforce/resourceUrl/AppStoreLogo';

const IOS_APP_URL     = 'https://apps.apple.com/in/app/safexpress-app/id6797861161';
const ANDROID_APP_URL = 'https://play.google.com/store/apps/details?id=com.safexpress.enterprise';

export default class SafexpressWaybillEnquiryLWCCard extends LightningElement {
    @api value;

    logoUrl = BRAND_LOGO;
    truckUrl = TRUCK_IMG;
    roadUrl  = ROAD_IMG;

    // Footer app badges
    iosBadgeUrl     = IOS_BADGE;
    androidBadgeUrl = ANDROID_BADGE;
    iosAppUrl       = IOS_APP_URL;
    androidAppUrl   = ANDROID_APP_URL;

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

    get isError() {
        const d = this.cardData;
        return Boolean(d && d.errorMessage && !d.waybillNumberFormatted);
    }

    get hasData() {
        const d = this.cardData;
        if (!d) return true; 
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
}