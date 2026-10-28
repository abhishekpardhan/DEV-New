import {
    LightningElement,
    api
} from 'lwc';

export default class WayTrack extends LightningElement {
    trackColumns = [{
            label: 'Event Date',
            fieldName: 'eventDate',
            type: 'text'
        },
        {
            label: 'Website Message',
            fieldName: 'websiteMsg',
            type: 'text'
        },
        {
            label: 'Quantity',
            fieldName: 'qty',
            type: 'text',
            initialWidth: 100,
        },
        {
            label: 'Event Description',
            fieldName: 'eventDescr',
            type: 'text'
        }
    ];
    @api trackData;
}