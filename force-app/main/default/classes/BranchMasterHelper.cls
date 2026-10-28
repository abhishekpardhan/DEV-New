public class BranchMasterHelper {
    // method to mark ARMBranch checkbox true in acount 
    public static void markArmAccounts(Set<id> BranchId){
        List<Account> accList = [Select id, name, Booking_Branch__c,ARM_Branch__c from Account where Booking_Branch__c IN: BranchID];
        System.debug('LLLLLLLLLLLLLLLL'+accList);
        List<Account> updatedList = new List<Account>();
        if(accList.size() > 0){
            for(Account acc : accList){
                acc.ARM_Branch__c = true;
                updatedList.add(acc);
            }
            update updatedList;
        }
    }
    // method to mark ARMBranch checkbox False in acount
    public static void removeArmAccounts(Set<id> BranchIdList){
     List<Account> accList = [Select id, name, Booking_Branch__c,ARM_Branch__c from Account where Booking_Branch__c IN: BranchIdList];
        System.debug('AAAAAAAAAAAAAAAAAA'+accList);
        List<Account> updatedList = new List<Account>();
        if(accList.size() > 0){
            for(Account acc : accList){
                acc.ARM_Branch__c = false;
                updatedList.add(acc);
            }
            update updatedList;
        }
    }
}