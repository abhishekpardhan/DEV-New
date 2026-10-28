public with sharing class WaybillExcelUploadController {

    @AuraEnabled
    public static List<String> getExistingWaybillNumbers(Id caseId) {
        List<Waybill_Details__c> waybills = [
            SELECT Name 
            FROM Waybill_Details__c 
            WHERE Case__c = :caseId
        ];
        List<String> names = new List<String>();
        for (Waybill_Details__c w : waybills) {
            names.add(w.Name);
        }
        return names;
    }

    @AuraEnabled
    public static void saveWaybills(Id caseId, List<Waybill_Details__c> rows) {
        if (rows == null || rows.isEmpty()) return;
        for (Waybill_Details__c w : rows) {
            w.Case__c = caseId;
            w.Name = w.Name != null ? String.ValueOf(w.Name).trim() : null;
            w.Amount__c = w.Amount__c != null ? Double.valueOf(w.Amount__c) : null;
            w.Reason__c = w.Reason__c != null ? String.ValueOf(w.Reason__c).trim().replace(',', ';') : null;
            w.Remarks__c = w.Remarks__c != null ? String.ValueOf(w.Remarks__c).trim() : null;
        }
        try {
            insert rows;
        } catch(DmlException e) {
            throw new AuraHandledException('Error inserting Waybills: ' + e.getMessage());
        }
    }
}