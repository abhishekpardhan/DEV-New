@JsonAccess(serializable='always' deserializable='always')
global class SafexpressWaybillStatusResult {

    @InvocableVariable(label='Waybill Info' description='Structured shipment data object')
    global WaybillData waybillInfo;
}