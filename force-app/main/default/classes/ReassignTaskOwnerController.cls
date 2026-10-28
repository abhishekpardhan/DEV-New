/**
* Class Name : ReassignTaskOwnerController.cls
* Description : Reassign task owner and update the task...
* Author : Manshi 
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 6, 2025 | Manshi  | Initial Version
**/

public class ReassignTaskOwnerController {
    
    //fetch user name from searchKey....
    @AuraEnabled(cacheable=true)
    public static List<User> findUsers(String searchKey) {
        String searchTerm = '%' + String.escapeSingleQuotes(searchKey) + '%';
        return [
            SELECT Id, Name
            FROM User
            WHERE IsActive = true AND Name LIKE :searchTerm];
    }
    
    // checked task is completed or not...
    @AuraEnabled
    public static String fetchCompletedTask(List<Id> taskIds) {
        try {
            if (taskIds == null || taskIds.isEmpty()) {
                return 'Task IDs is missing.';
            }
            // Fetch tasks records 
            List<Task> tasksToUpdate = [SELECT Id, Status FROM Task WHERE Id IN :taskIds AND Status = 'Completed'];
            if (!tasksToUpdate.isEmpty()) {
                return 'Completed tasks cannot be modified.';
            }
            else{
                return '';
            }
        }
        catch (Exception e) {
            throw new AuraHandledException('Error reassigning tasks: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String reassignTaskOwners(List<Id> taskIds, Id newOwnerId) {
        try {
            if (taskIds == null || taskIds.isEmpty() || newOwnerId == null) {
                return 'Task IDs or new owner is missing.';
            }
            // Fetch tasks records for updation...
            List<Task> tasksToUpdate = [SELECT Id, Status FROM Task WHERE Id IN :taskIds AND Status != 'Completed'];
            if (!tasksToUpdate.isEmpty()) {
                for (Task task : tasksToUpdate) {
                    task.OwnerId = newOwnerId;
                }
                update tasksToUpdate;
            }
            return 'Tasks reassigned successfully.';
        } catch (Exception e) {
             return 'Error reassigning tasks: ' + e.getMessage();
        }
    }
}