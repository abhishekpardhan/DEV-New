public inherited sharing class LeadEnrichmentService {

    public static void toUpperCase(List<Lead> leads, Map<Id, Lead> oldMap) {
        for (Lead row : leads) {
            Lead previous = (oldMap == null) ? null : oldMap.get(row.Id);

            if (previous == null || row.FirstName != previous.FirstName) {
                row.FirstName = upper(row.FirstName);
            }
            if (previous == null || row.LastName != previous.LastName) {
                row.LastName = upper(row.LastName);
            }
        }
    }

    private static String upper(String value) {
        return String.isBlank(value) ? value : value.toUpperCase();
    }

}