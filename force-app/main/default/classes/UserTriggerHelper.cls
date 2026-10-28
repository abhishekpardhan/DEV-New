public with sharing class UserTriggerHelper {
    private static Boolean isEnqueued = false;

    public static void processUsers(
        List<User> newList,
        Map<Id, User> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {

        try {

            List<User> usersToBackup = new List<User>();
            Map<Id, User> oldRecordsMap = new Map<Id, User>();

            for (User newUser : newList) {

                if (!areRequiredFieldsPresent(newUser)) {
                    continue;
                }

                if (isInsert) {
                    usersToBackup.add(newUser);
                }
                else if (isUpdate) {
                    User oldUser = oldMap.get(newUser.Id);

                    if (hasRelevantChanges(newUser, oldUser)) {
                        usersToBackup.add(newUser);
                        oldRecordsMap.put(newUser.Id, oldUser);
                    }
                }
            }

            if (!usersToBackup.isEmpty() && !isEnqueued) {
                isEnqueued = true;
                System.enqueueJob(new UserBackupQueueable(usersToBackup, oldRecordsMap.size() > 0 ? oldRecordsMap : null));
            
            }
        } catch (Exception e) {
            System.debug('Error in processUsers: ' + e.getMessage());
            ExceptionHandling.Exception('processUsers' , 'UserTriggerHelper', e );
        }
    }

    public static Boolean areRequiredFieldsPresent(User u) {
        return u.AD_Id__c != null &&
           u.Email != null &&
           u.IsActive != null &&
           u.Region__c != null;
    }

    public static Boolean hasRelevantChanges(User newU, User oldU) {
        if (oldU == null) return true;
        return (newU.AD_Id__c != oldU.AD_Id__c) ||
            (newU.Department != oldU.Department) ||
            (newU.Email != oldU.Email) ||
            (newU.IsActive != oldU.IsActive) ||
            (newU.ManagerId != oldU.ManagerId) ||
            (newU.MobilePhone != oldU.MobilePhone) ||
            (newU.Region__c != oldU.Region__c) ||
            (newU.Type__c != oldU.Type__c) ||
            (newU.UserRoleId != oldU.UserRoleId);
    }
       
}