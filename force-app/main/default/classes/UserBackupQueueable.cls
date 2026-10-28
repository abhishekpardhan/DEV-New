public class UserBackupQueueable implements Queueable {

    private List<User> newUsers;
    private Map<Id, User> oldUserMap;

    public UserBackupQueueable(List<User> newUsers, Map<Id, User> oldUserMap) {
        this.newUsers = newUsers;
        this.oldUserMap = oldUserMap;
    }

    public void execute(QueueableContext context) {
        try {

            Map<String, User> validUsersID = new Map<String, User>();

            for (User u : newUsers) {
                if (UserTriggerHelper.areRequiredFieldsPresent(u) &&
                    (oldUserMap == null || UserTriggerHelper.hasRelevantChanges(u, oldUserMap.get(u.Id)))) {
                    validUsersID.put(u.Id, u);
                }
            }

            if (validUsersID.isEmpty()) return;

            Map<String, User_Backup__c> backupByName = new Map<String, User_Backup__c>();
            for (User_Backup__c ub : [
                SELECT Id, UserId__c
                FROM User_Backup__c
                WHERE UserId__c IN :validUsersID.keySet()
            ]) {
                backupByName.put(ub.UserId__c, ub);
            }

            List<User_Backup__c> toUpsert = new List<User_Backup__c>();

            for (String adId : validUsersID.keySet()) {
                User u = validUsersID.get(adId);

                User_Backup__c backup = backupByName.containsKey(adId)
                    ? backupByName.get(adId)
                    : new User_Backup__c(UserId__c = adId);

                mapUserToBackup(u, backup);
                toUpsert.add(backup);
            }

            if (!toUpsert.isEmpty()) {
                Database.upsert(toUpsert, User_Backup__c.UserId__c, false);
            }
        } catch (Exception e) {
            System.debug('Error in UserBackupQueueable: ' + e.getMessage());
            ExceptionHandling.Exception('execute' , 'UserBackupQueueable', e );
        }
    }

    private static void mapUserToBackup(User u, User_Backup__c b) {
        b.AD_Id__c       = u.AD_Id__c;
        b.Name           = (u.FirstName != null ? u.FirstName + ' ' : '') + u.LastName;
        b.Department__c  = u.Department;
        b.Email__c       = u.Email;
        b.IsActive__c    = u.IsActive;
        b.ManagerId__c   = u.ManagerId;
        b.Type__c   = u.Type__c;
        b.Phone__c       = u.MobilePhone;
        b.Region__c      = u.Region__c;
        b.UserRoleId__c  = u.UserRoleId;
    }

}