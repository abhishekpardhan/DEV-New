public With Sharing class CommonController {

    @AuraEnabled(cacheable=true)
    public static List<SObject> getList(String fields, String objAPIName, String relationshipWithObj, Id recordId) {
        // Filter fields based on user permissions
        fields = getAccessibleFields(fields, objAPIName);
        if (fields == null) {
            throw new AuraHandledException('No accessible fields available for this user');
        }

        // Construct the dynamic query
        String queryDetails = 'SELECT Id,' + fields + ' FROM ' + objAPIName + ' WHERE ' + relationshipWithObj + ' = :recordId';
        System.debug('Query String: ' + queryDetails);

        try {
            // Execute the dynamic query
            List<SObject> results = Database.query(queryDetails);
            System.debug('Query Results: ' + results.size() + ' records found');
            return results;
        } catch (Exception e) {
            System.debug('Error executing query: ' + e.getMessage());
            throw new AuraHandledException('Error in querying records: ' + e.getMessage());
        }
    }

    // Helper method to retrieve only accessible fields
    private static String getAccessibleFields(String fields, String objAPIName) {
        List<String> accessibleFields = new List<String>();
        for (String field : fields.split(',')) {
            field = field.trim();
            // Check if the field exists on the object and if it's accessible
            if (Schema.getGlobalDescribe().get(objAPIName).getDescribe().fields.getMap().containsKey(field)) {
                // Use isAccessible to verify user has access
                if (Schema.getGlobalDescribe().get(objAPIName).getDescribe().fields.getMap().get(field).getDescribe().isAccessible()) {
                    accessibleFields.add(field);
                } else {
                    System.debug('Field not accessible: ' + field);
                }
            }
        }
        return accessibleFields.isEmpty() ? null : String.join(accessibleFields, ',');
    }
}