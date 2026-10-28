/**
* Description      :   Helper class for OpportunityTeamsTrigger
*                      Contains business logic to validate default opportunity team users
* 
* Created By       :   Anand Raju
* Created Date     :   May 14, 2026
* 
* Revision Logs    :   V_1.0 - Created - Validation logic for default users
*                      V_1.1 - Added profile bypass for System Administrator, Read Only, and Corporate salesforce team
* 
**/
public class OpportunityTeamsTriggerHelper {
    
    // Static variable to cache default user IDs (prevents repeated SOQL queries)
    private static Set<Id> cachedDefaultUserIds;
    
    // Static variable to cache bypass profiles
    private static Set<String> bypassProfiles;
    
    /**
     * @description Validates that records do not contain default users
     *              Adds error to records attempting to update/delete default users
     *              Bypasses validation for specific profiles
     * @param teams List of Opportunity_Teams__c records to validate
     * @param oldTeams Map of old Opportunity_Teams__c records
     */
    public static void validateDefaultUsers(List<Opportunity_Teams__c> teams, Map<Id,Opportunity_Teams__c> oldTeams) {
        try {
            // Check if current user's profile should bypass validation
            if(shouldBypassValidation()) {
                return;
            }
            
            // Get the set of default user IDs (cached)
            Set<Id> defaultUserIds = getDefaultUserIds();
            
            // If no default users configured, skip validation
            if(defaultUserIds == null || defaultUserIds.isEmpty()) {
                return;
            }
            
            // Check each record
            for(Opportunity_Teams__c team : teams) {
                Opportunity_Teams__c oldUser;
                if(oldTeams != null) {
                    oldUser = oldTeams.get(team.Id);
                }
                
                // Check if current or old user is a default user
                if((team.User__c != null && defaultUserIds.contains(team.User__c)) || 
                   (oldUser != null && defaultUserIds.contains(oldUser.User__c))) {
                    team.addError('This user is a default opportunity team member and cannot be updated or deleted.');
                }
            }
        } catch(Exception e) {
            System.debug('Error in validateDefaultUsers: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
            throw e;
        }
    }
    
    /**
   * @description Populates AD ID on Opportunity Team record from User
  * @param teams List of Opportunity_Teams__c records
 */
   public static void populateADId(List<Opportunity_Teams__c> teams) {

    Set<Id> userIds = new Set<Id>();

    // Collect User Ids
    for(Opportunity_Teams__c team : teams) {
        if(team.User__c != null) {
            userIds.add(team.User__c);
        }
    }

    // Fetch Users
    Map<Id, User> userMap = new Map<Id, User>(
        [
            SELECT Id, AD_Id__c
            FROM User
            WHERE Id IN :userIds
        ]
    );

    // Populate AD ID field
    for(Opportunity_Teams__c team : teams) {

        if(
            team.User__c != null &&
            userMap.containsKey(team.User__c)
        ) {
            team.AD_ID__c = userMap.get(team.User__c).AD_Id__c;
        }
    }
}
    /**
     * @description Checks if the current user's profile should bypass validation
     * @return Boolean True if user should bypass validation, false otherwise
     */
    private static Boolean shouldBypassValidation() {
        try {
            // Get bypass profiles (cached)
            if(bypassProfiles == null) {
                bypassProfiles = new Set<String>{
                    'System Administrator',
                    'Read Only',
                    'Corporate salesforce team'
                };
            }
            
            // Get current user's profile name
            String currentUserProfile = [
                SELECT Profile.Name 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ].Profile.Name;
            
            // Check if current profile is in bypass list
            return bypassProfiles.contains(currentUserProfile) && !test.isRunningTest();
            
        } catch(Exception e) {
            System.debug('Error in shouldBypassValidation: ' + e.getMessage());
            // If there's an error, don't bypass (safer approach)
            return false;
        }
    }

    /**
     * @description Retrieves and caches the set of default user IDs based on AD_Id__c values
     *              from the Default_Opportunity_Team_Users custom label
     * @return Set<Id> Set of User IDs that are considered default users
     */
    public static Set<Id> getDefaultUserIds() {
        // Return cached value if already queried
        if(cachedDefaultUserIds != null) {
            return cachedDefaultUserIds;
        }
        
        try {
            // Initialize the set
            cachedDefaultUserIds = new Set<Id>();
            
            // Read the custom label
            String labelValue = System.Label.Default_Opportunity_Team_Users;
            
            // If label is empty, return empty set
            if(String.isBlank(labelValue)) {
                return cachedDefaultUserIds;
            }
            
            // Parse comma-separated AD_Id__c values
            List<String> adIds = labelValue.split(',');
            
            // Trim whitespace from each value
            List<String> trimmedAdIds = new List<String>();
            for(String adId : adIds) {
                if(String.isNotBlank(adId)) {
                    trimmedAdIds.add(adId.trim());
                }
            }
            
            // Query users with matching AD_Id__c values
            if(!trimmedAdIds.isEmpty()) {
                List<User> defaultUsers = [
                    SELECT Id 
                    FROM User 
                    WHERE AD_Id__c IN :trimmedAdIds
                ];
                
                // Add user IDs to the cached set
                for(User usr : defaultUsers) {
                    cachedDefaultUserIds.add(usr.Id);
                }
            }
            
            return cachedDefaultUserIds;
            
        } catch(Exception e) {
            System.debug('Error in getDefaultUserIds: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
            // Return empty set on error to prevent blocking all operations
            cachedDefaultUserIds = new Set<Id>();
            return cachedDefaultUserIds;
        }
    }
    
    /**
     * @description Clears the cached default user IDs (useful for testing)
     */
    @TestVisible
    private static void clearCache() {
        cachedDefaultUserIds = null;
        bypassProfiles = null;
    }
}