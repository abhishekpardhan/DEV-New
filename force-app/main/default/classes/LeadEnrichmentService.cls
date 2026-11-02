/**
* @File Name          : LeadEnrichmentService.cls
* @Description        : Normalizes Lead names to uppercase before records are saved
* @Author             : Abhishek
* @Group              : GT
* @Last Modified By   : Abhishek
* @Last Modified On   : 28/10/2026
*==============================================================================
* Ver         Date              Author              Modification
*==============================================================================
* 1.0         28/10/2026        Abhishek            Class created
**/
public inherited sharing class LeadEnrichmentService {

    // Uppercase new or changed Lead names before saving.
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