import { api, LightningElement } from "lwc";

export default class AgentforceChatShipmentCard extends LightningElement {
    @api
    get readOnly() {
        return this._readOnly;
    }

    set readOnly(value) {
        this._readOnly = value;
    }
    _readOnly = false;
    _value;

    @api
    get value() {
        return this._value;
    }

    set value(value) {
        this._value = value;
        this.processValue();
    }

    shipmentData = [];

    connectedCallback() {
        if (this.value) {
            this.processValue();
        }
    }

    processValue() {
        if (!this._value) {
            this.shipmentData = [];
            return;
        }

        // Extracts the nested waybillInfo object safely
        const info = this._value?.waybillInfo || (Array.isArray(this._value) ? this._value[0]?.waybillInfo : this._value);

        if (info) {
            this.shipmentData = [{
                ...info,
                headerStyle: `background-color: ${info.headerColor || '#1E7A34'}; color: #ffffff; padding: 0.5rem; border-radius: 4px;`
            }];
        } else {
            this.shipmentData = [];
        }
    }

    handleInputChange(event) {
        event.stopPropagation();
        const { name, value } = event.target;
        this[name] = value;

        this.dispatchEvent(
            new CustomEvent("valuechange", {
                detail: {
                    value: this.value
                }
            })
        );
    }
}