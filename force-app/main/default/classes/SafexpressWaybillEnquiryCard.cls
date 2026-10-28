/**
 * @File Name          : SafexpressWaybillEnquiryCard.cls
 * @Description        : Data wrapper class representing the LWC shipment card attributes.
 * @Author             : Rohit Deshmukh
 * @Last Modified By   : Rohit Deshmukh
 * @Last Modified On   : 14-Oct-2026
**/
global class SafexpressWaybillEnquiryCard {

    @InvocableVariable(label='Waybill Number Formatted')
    public String waybillNumberFormatted;

    @InvocableVariable(label='Last Event')
    public String lastEvent;

    @InvocableVariable(label='Current Status')
    public String currentStatus;

    @InvocableVariable(label='Delivery Location' description='Destination delivery city of the shipment.')
    public String deliveryLocation;

    @InvocableVariable(label='Delivered On' description='Date and time when the shipment was delivered.')
    public String deliveredOn;

    @InvocableVariable(label='Case Number')
    public String caseNumber;

    @InvocableVariable(label='Error Message')
    public String errorMessage;

    @InvocableVariable(label='Header Title')
    public String headerTitle;

    @InvocableVariable(label='Footer Note')
    public String footerNote;
}