import { LightningElement, api } from 'lwc';
import BRAND_LOGO from '@salesforce/resourceUrl/Safexpress_Logo';

// "DELHI CENTRAL" -> "Delhi Central"; short codes like "(DL)" stay in capitals
function toTitleCase(text) {
    if (!text) {
        return text;
    }
    return String(text)
        .split(' ')
        .map((word) => {
            const letters = word.replace(/[^A-Za-z]/g, '');
            if (letters.length <= 2) {
                return word;
            }
            return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        })
        .join(' ');
}

export default class PincodeLocationCard extends LightningElement {
    // Filled by Agentforce with the Location Card data from AgentforcePincodeCheck
    @api value;

    logoUrl = BRAND_LOGO;

    // Reads the card data safely, whether it arrives as an object or as JSON text
    get data() {
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

    get hasLocation() {
        const d = this.data;
        return Boolean(d && (d.city || d.district || d.state));
    }

    get city() {
        return this.data ? toTitleCase(this.data.city) : null;
    }

    get district() {
        return this.data ? toTitleCase(this.data.district) : null;
    }

    get state() {
        return this.data ? toTitleCase(this.data.state) : null;
    }

    get pincode() {
        return this.data ? this.data.pincode : null;
    }
}