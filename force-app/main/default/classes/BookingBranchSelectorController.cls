public with sharing class BookingBranchSelectorController {

    public class BranchResponse {
        @AuraEnabled public List<Branch_Master__c> branches { get; set; }
        @AuraEnabled public Branch_Master__c existingBranch { get; set; }
    }

    // -------------------------------------------------------------------------
    // 1) Search Branches
    /// -------------------------------------------------------------------------
    
    @AuraEnabled
    public static BranchResponse searchBranches(String searchKey, Id ContactId) {
        BranchResponse response = new BranchResponse();
        try  {
            List<Branch_Master__c> result = new List<Branch_Master__c>();

            List<Contact> contactList = [
                SELECT Id, AccountId, Assigned_Branch_id__c, Assigned_Branch_Name__c
                FROM Contact
                WHERE Id =:ContactId
                LIMIT 1
            ];
            if (contactList.isEmpty()) {
                throw new AuraHandledException('No Contact found for given Id.');
            }
            Contact acr = contactList[0];
            String searchPattern = (String.isBlank(searchKey)) ? '%' : ('%' + searchKey.trim() + '%');
            List<Account> acctList = new List<Account>();
            acctList = [
                SELECT Id, Parent.Id,Billing_Branch__c,Billing_Branch__r.Id,Billing_Branch__r.Name   
                FROM Account
                WHERE (Parent.Parent.Parent.Parent.Id = :acr.AccountId
                    OR Parent.Parent.Parent.Id = :acr.AccountId)
                AND Billing_Branch__r.Name LIKE :searchPattern
            ];

            if(acctList.isEmpty()) {
                // get sfx
                List<Account> lstAccounts = [SELECT Id, Account_Recordtype_Name__c,RecordType.Name
                                            FROM Account 
                                            WHERE (Parent.Id =:acr.AccountId or Id =:acr.AccountId)
                                            AND RecordType.Name = 'SFX'];
                if(!lstAccounts.isEmpty()) {
                    //reate card
                    List<Account> lstRateCard = [SELECT Id FROM Account WHERE Parent.Parent.Id IN: lstAccounts 
                    AND RecordType.Name = 'Rate Card'];
                    if(!lstRateCard.isEmpty()){
                        //get booking branch
                        BookingBranch bb = new BookingBranch();
                        Set<Id> rateCardIds = new Map<Id, Account>(lstRateCard).keySet();
                        acctList = bb.getBookingBranch(new Set<Id>(), rateCardIds, searchPattern);
                        
                    } else {
                        // get branches from the
                        BookingBranch bb = new BookingBranch();
                        Set<Id> sfxIds = new Map<Id, Account>(lstAccounts).keySet();
                        acctList = bb.getBookingBranch(sfxIds, new Set<Id>(), searchPattern);

                    }
    
                }
            }
    
                
            Map<String, String> mapDuplicateCheck = new Map<String, String>();

            for (Account acct : acctList) {
                if (acct.Billing_Branch__r.Id != acr.Assigned_Branch_id__c && !mapDuplicateCheck.containsKey(acct.Billing_Branch__r.Id)) {
                    mapDuplicateCheck.put(acct.Billing_Branch__r.Id, acct.Billing_Branch__r.Name);
                    result.add(acct.Billing_Branch__r);
                }
            }

            response.branches = result;

            if (acr.Assigned_Branch_id__c != null) {
                response.existingBranch = new Branch_Master__c(
                    Id = acr.Assigned_Branch_id__c,
                    Name = acr.Assigned_Branch_Name__c
                );
            }
        } catch (Exception e) {
            LoggerUtil.createErrorLog('BookingBranchSelectorController', 'searchBranches', e.getTypeName(), e.getMessage(), e.getStackTraceString(), '');
            throw new AuraHandledException('Error searching branches: ' + e.getMessage());
        }

        return response;
    }

    public without sharing class BookingBranch {
 
        public List<Account> getBookingBranch(Set<Id> sfxIds, Set<Id> rateCardIds, String searchKey) {
            if(!sfxIds.isEmpty() && rateCardIds.isEmpty()) {
                return [
                    SELECT Id, Parent.Id, Billing_Branch__c, Billing_Branch__r.Id, Billing_Branch__r.Name 
                    FROM Account 
                    WHERE Parent.Parent.Parent.Id IN:sfxIds 
                    AND Billing_Branch__r.Name LIKE :searchKey
                ];
            } else {
                return [
                    SELECT Id, Parent.Id, Billing_Branch__c, Billing_Branch__r.Id, Billing_Branch__r.Name 
                    FROM Account 
                    WHERE Parent.Id IN: rateCardIds
                    AND Billing_Branch__r.Name LIKE :searchKey
                ];
            }
        }
    }
    // -------------------------------------------------------------------------
    // 2) Associate Branch to Contact (bulk-safe) - assigns the same branchId to all provided contacts
    // -------------------------------------------------------------------------
    @AuraEnabled
    public static void associateBranchToRelation(Id branchId, Id contactId, String branchName) {
        try {

            if (branchId == null || contactId == null) {
                throw new AuraHandledException('Branch Id and Contact Id(s) are required.');
            }

            // Load branch name (ensures we only use branches visible to the running user)

            List<Contact> cons = [
                SELECT Id, Assigned_Branch_id__c, Assigned_Branch_Name__c
                FROM Contact
                WHERE Id =:contactId
            ];

            if (cons.isEmpty()) return;

            for (Contact con : cons) {
                con.Assigned_Branch_id__c = branchId;
                con.Assigned_Branch_Name__c = branchName;
            }

            update cons;
        } catch (Exception e) {
            LoggerUtil.createErrorLog('BookingBranchSelectorController', 'associateBranchToRelation', e.getTypeName(), e.getMessage(), e.getStackTraceString(), '');
            throw new AuraHandledException('Error associating branch to contact: ' + e.getMessage());
        }
    }

    // -------------------------------------------------------------------------
    // 3) Remove Branch from Contact(s) (bulk-safe)
    // -------------------------------------------------------------------------
    @AuraEnabled
    public static void removeBranchFromRelation(Id contactId) {
        try {
            if (contactId == null) {
                throw new AuraHandledException('Contact Id(s) are required.');
            }

            List<Contact> cons = [
                SELECT Id, Assigned_Branch_id__c, Assigned_Branch_Name__c
                FROM Contact
                WHERE Id =:contactId
            ];

            if (cons.isEmpty()) return;

            for (Contact c : cons) {
                c.Assigned_Branch_id__c = null;
                c.Assigned_Branch_Name__c = null;
            }

            update cons;
        } catch (Exception e) {
            LoggerUtil.createErrorLog('BookingBranchSelectorController', 'removeBranchFromRelation', e.getTypeName(), e.getMessage(), e.getStackTraceString(), '');
            throw new AuraHandledException('Error removing branch from contact: ' + e.getMessage());
        }
    }
}