/**
* @File Name          : LeadAssignmentService.cls
* @Description        : Resolves Lead pincodes and assigns eligible Leads to an Area Manager or Central Desk
* @Author             : Abhishek
* @Group              : GT
* @Last Modified By   : Abhishek
* @Last Modified On   : 28/10/2026
*==============================================================================
* Ver         Date              Author              Modification
*==============================================================================
* 1.0         28/10/2026        Abhishek            Class Created
**/
public inherited sharing class LeadAssignmentService {
    // The Queueable sets this flag while updating Leads so before-update
    // assignment does not run again in the same transaction.
    public static Boolean isJobUpdate = false;
    private static Id cachedCentralDeskQueueId;
    private static Map<Id, Id> pendingOwnerChanges = new Map<Id, Id>();

    /**
     * Checks Assign_to_Central_Desk__c automatically for Website Leads and
     * Leads linked to a Case, then processes only checked Leads.
     * A local pincode match fills Area__c and Region__c, completes the lookup,
     * and assigns an owner. An unresolved pincode is marked Pending for an
     * after-insert lookup. Unchecked Leads retain their owner, area, and region,
     * and have no lookup status set by this service.
     * @param newLeads Leads being inserted.
     */
    public static void onBeforeInsert(List<Lead> newLeads) {
        try {
            Set<String> pincodes = new Set<String>();
            for (Lead row : newLeads) {
                // Website and Case Leads enter the assignment flow automatically.
                if (row.LeadSource == 'Website' || row.Case__c != null) {
                    row.Assign_to_Central_Desk__c = true;
                }
                // An unchecked Lead does not enter the pincode assignment flow;
                // clear any submitted lookup status on this new record.
                if (row.Assign_to_Central_Desk__c != true) {
                    continue;
                }
                // Only nonblank postal codes are included in the local lookup.
                if (String.isNotBlank(row.PostalCode)) pincodes.add(row.PostalCode.trim());
            }
            // Resolve pincodes against local reference data.
            Map<String, AreaRegion> local = resolveLocal(pincodes);
            List<Lead> assignable = new List<Lead>();

            for (Lead row : newLeads) {
                // Only checked Leads can receive lookup or assignment fields.
                if (row.Assign_to_Central_Desk__c != true) continue;
                AreaRegion resolved = String.isNotBlank(row.PostalCode)
                    ? local.get(row.PostalCode.trim()) : null;
                // No local mapping: leave Area__c and Region__c unchanged and
                // mark the Lead Pending for the after-insert lookup.
                if (resolved == null) {
                    row.Pincode_Lookup_Status__c = 'Pending';
                } else {
                    // A local mapping completes the lookup with its area and region.
                    row.Area__c   = resolved.area;
                    row.Region__c = resolved.region;
                    row.Pincode_Lookup_Status__c = 'Completed';
                    assignable.add(row);
                }
            }
            // Assignment sets OwnerId, the assignment flag, date, and evaluated
            // flag on each Lead in the eligible list.
            List<Id> originalOwners = new List<Id>();
            for (Lead row : assignable) originalOwners.add(row.OwnerId);
            assignAreaManager(assignable);
            // The event subscriber transfers ownership after this insert commits.
            if (Trigger.isExecuting && Trigger.isBefore) {
                for (Integer i = 0; i < assignable.size(); i++) {
                    assignable[i].OwnerId = originalOwners[i];
                }
            }

        } catch (ConfigurationException ce) {
            throw ce;
        } catch (Exception e) {
            logError('onBeforeInsert', e);
        }
    }

    /**
     * Creates Draft lookup transactions for checked new Leads with a Pending
     * lookup and nonblank PostalCode. Each transaction starts with zero retries
     * and a request containing the trimmed pincode. Groups failed inserts by
     * error message and logs the affected Lead IDs.
     * @param newLeads Leads that were inserted.
     */
    public static void onAfterInsert(List<Lead> newLeads) {
        List<Lead> assignable = new List<Lead>();
        Map<Id, Id> originalOwners = new Map<Id, Id>();
        for (Lead row : newLeads) {
            if (row.Assignment_Evaluated__c == true &&
                row.Pincode_Lookup_Status__c == 'Completed') {
                assignable.add(row.clone(true, false, false, false));
                originalOwners.put(row.Id, row.OwnerId);
            }
        }
        assignAreaManager(assignable);
        Map<Id, Id> ownerChanges = new Map<Id, Id>();
        for (Lead row : assignable) {
            if (row.OwnerId != originalOwners.get(row.Id)) ownerChanges.put(row.Id, row.OwnerId);
        }
        publishOwnerChanges(ownerChanges);
        createLookupTransactions(newLeads, 'onAfterInsert');
    }

    public static void onAfterUpdate(List<Lead> newLeads) {
        Map<Id, Id> ownerChanges = new Map<Id, Id>();
        for (Lead row : newLeads) {
            if (pendingOwnerChanges.containsKey(row.Id)) {
                ownerChanges.put(row.Id, pendingOwnerChanges.remove(row.Id));
            }
        }
        publishOwnerChanges(ownerChanges);
    }

    private static void publishOwnerChanges(Map<Id, Id> ownerChanges) {
        if (ownerChanges.isEmpty()) return;
        List<Update_Event__e> events = new List<Update_Event__e>();
        for (Id leadId : ownerChanges.keySet()) {
            events.add(new Update_Event__e(
                ObjectName__c = 'Lead',
                ObjectId__c = String.valueOf(leadId),
                FieldName__c = 'OwnerId',
                Field_Value__c = String.valueOf(ownerChanges.get(leadId))
            ));
        }
        List<Database.SaveResult> results = EventBus.publishWithAccessLevel(
            events, AccessLevel.SYSTEM_MODE);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                throw new ConfigurationException('Lead ownership event could not be published: '
                    + result.getErrors()[0].getMessage());
            }
        }
    }

    // Used after insert and on the first assignment request during an update.
    private static void createLookupTransactions(List<Lead> leads, String methodName) {
        try {
            Map<String, List<String>> exceptionMap = new Map<String, List<String>>();
            List<Integration_Transaction__c> txns = new List<Integration_Transaction__c>();
            for (Lead row : leads) {
                // Only checked, Pending Leads with a postal code create requests.
                if (row.Assign_to_Central_Desk__c == true &&
                    row.Pincode_Lookup_Status__c == 'Pending' &&
                    String.isNotBlank(row.PostalCode)) {
                    txns.add(new Integration_Transaction__c(
                        Object_Name__c    = 'Lead',
                        Record_Id__c      = String.valueOf(row.Id),
                        Operation_Type__c = System.Label.OperationType_PropelI_PincodeLookup,
                        Status__c         = 'Draft',
                        No_of_Retries__c  = 0,
                        MSAPushEndpoint__c = 'callout:Propeli_Pincode_API/safeutil-sfdc/api/v1/sfi/fetchAreaByPincode',
                        Request__c        = JSON.serialize(new Map<String, String>{
                            'pincode' => row.PostalCode.trim() })
                    ));
                }
            }

            // Insert all eligible transactions in system mode. One failed row
            // does not prevent other transactions from being created.
            if (!txns.isEmpty()) {
                Database.SaveResult[] results = Database.insert(
                    txns,
                    false,
                    AccessLevel.SYSTEM_MODE
                );

                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err : results[i].getErrors()) {
                            String errorMsg = err.getMessage();
                            if (!exceptionMap.containsKey(errorMsg)) {
                                exceptionMap.put(
                                    errorMsg,
                                    new List<String>()
                                );
                            }
                            exceptionMap.get(errorMsg).add(
                                txns[i].Record_Id__c
                            );
                        }
                    }
                }
            }

            if (!exceptionMap.isEmpty()) {
                System.debug('exceptionMap >> ' + exceptionMap);
                List<ExceptionHandler__c> expList = new List<ExceptionHandler__c>();
                for (String errorMsg : exceptionMap.keySet()) {
                    ExceptionHandler__c exc = new ExceptionHandler__c();
                    exc.Name = methodName;
                    exc.Class_Name__c = 'LeadAssignmentService';
                    exc.Error_Message__c =
                        errorMsg + ':-' +
                        String.join(
                            exceptionMap.get(errorMsg),
                            ','
                        );
                    expList.add(exc);
                }

                if (!expList.isEmpty()) {
                    ExceptionHandling.Exceptions(expList);
                }
            }

        } catch (Exception e) {
            logError(methodName, e);
        }
    }

    private static void logError(String methodName, Exception e) {
        try {
            String msg = e.getTypeName() + ': ' + e.getMessage()
                + ' | Line ' + e.getLineNumber() + ' | ' + e.getStackTraceString();
            // Identify the class and method in the exception log.
            ExceptionHandling.Exception('LeadAssignmentService', methodName, msg.abbreviate(32000));
        } catch (Exception logEx) {
            System.debug(LoggingLevel.ERROR, 'ExceptionHandling failed: ' + logEx.getMessage());
        }
    }

    /**
     * On a first false-to-true assignment request, resolves the current
     * pincode locally or creates a Draft transaction for an API lookup.
     * Later requests go directly to Central Desk. Other updates and Queueable
     * writebacks do not start pincode lookup or assignment here.
     * @param newLeads Updated Lead values.
     * @param oldMap Lead values before the update, keyed by Id.
     */
    public static void onBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        // Queueable writebacks have already determined the assignment outcome.
        if (isJobUpdate) return;
        try {
            Set<String> pincodes = new Set<String>();
            List<Lead> firstRequests = new List<Lead>();
            List<Lead> assignable = new List<Lead>();
            List<Lead> pending = new List<Lead>();
            for (Lead row : newLeads) {
                Lead old = oldMap.get(row.Id);
                // Only a false-to-true transition requests a new assignment.
                if (old.Assign_to_Central_Desk__c == false &&
                    row.Assign_to_Central_Desk__c == true) {
                    // A previously evaluated Lead goes straight to Central Desk;
                    // it does not repeat the pincode or Area Manager lookup.
                    if (old.Assignment_Evaluated__c == true) {
                        Id targetOwner = centralDeskQueueId();
                        if (Trigger.isExecuting && Trigger.isBefore) {
                            if (row.OwnerId != targetOwner) pendingOwnerChanges.put(row.Id, targetOwner);
                        } else {
                            row.OwnerId = targetOwner;
                        }
                    } else {
                        // First request: collect current pincodes for one local lookup.
                        firstRequests.add(row);
                        if (String.isNotBlank(row.PostalCode)) pincodes.add(row.PostalCode.trim());
                    }
                }
            }
            Map<String, AreaRegion> local = resolveLocal(pincodes);
            for (Lead row : firstRequests) {
                AreaRegion resolved = String.isNotBlank(row.PostalCode)
                    ? local.get(row.PostalCode.trim()) : null;
                // No local match: keep the current owner while the API lookup
                // is pending, and create a transaction below when the pin is nonblank.
                if (resolved == null) {
                    row.Pincode_Lookup_Status__c = 'Pending';
                    pending.add(row);
                } else {
                    // A local match completes the lookup and qualifies the Lead
                    // for the existing Area Manager or Central Desk owner rule.
                    row.Area__c = resolved.area;
                    row.Region__c = resolved.region;
                    row.Pincode_Lookup_Status__c = 'Completed';
                    assignable.add(row);
                }
            }
            List<Id> originalOwners = new List<Id>();
            for (Lead row : assignable) originalOwners.add(row.OwnerId);
            assignAreaManager(assignable);
            if (Trigger.isExecuting && Trigger.isBefore) {
                for (Integer i = 0; i < assignable.size(); i++) {
                    Lead row = assignable[i];
                    if (row.OwnerId != originalOwners[i]) {
                        pendingOwnerChanges.put(row.Id, row.OwnerId);
                    }
                    row.OwnerId = originalOwners[i];
                }
            }
            // The same Draft transaction path handles unresolved first requests
            // from both insert and update.
            createLookupTransactions(pending, 'onBeforeUpdate');

        } catch (ConfigurationException ce) {
            throw ce;
        } catch (Exception e) {
            logError('onBeforeUpdate', e);
        }
    }

    /**
     * Assigns each supplied Lead to its sole active Area Manager for the area,
     * or to the Central Desk queue when there is no unique match. Sets
     * Assignment_Date__c and Assignment_Evaluated__c in either case.
     * @param leads Leads to assign; null or empty input is left unchanged.
     */
    public static void assignAreaManager(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) return;

        Set<String> areas = new Set<String>();
        for (Lead row : leads) {
            if (String.isNotBlank(row.Area__c)) areas.add(row.Area__c.trim());
        }

        Map<String, List<Id>> managers = new ReferenceData().areaManagers(areas);
        Datetime assignedAt = System.now();

        for (Lead row : leads) {
            List<Id> matches = managers.get(normalizeKey(row.Area__c));
            // Exactly one match: set that manager as owner and clear the
            // Central Desk assignment flag.
            if (matches != null && matches.size() == 1) {
                row.OwnerId = matches[0];
                row.Assign_to_Central_Desk__c = false;
            } else {
                // Zero or multiple matches: use the Central Desk queue and
                // leave the Lead marked for Central Desk assignment.
                row.OwnerId = centralDeskQueueId();
                row.Assign_to_Central_Desk__c = true;
            }
            // Both assignment outcomes record the evaluation time and result.
            row.Assignment_Date__c = assignedAt;
            row.Assignment_Evaluated__c = true;
        }
    }

    public class ConfigurationException extends Exception {}

    public class AreaRegion {
        public String area;
        public String region;
        public AreaRegion(String area, String region) {
            this.area = area;
            this.region = region;
        }
    }

    @TestVisible
    private static String normalizeKey(String value) {
        return String.isBlank(value) ? null : value.trim().toUpperCase();
    }

    @TestVisible
    private static Map<String, AreaRegion> resolveLocal(Set<String> pincodes) {
        Set<String> normalized = new Set<String>();
        if (pincodes != null) {
            for (String pincode : pincodes) {
                if (String.isNotBlank(pincode)) normalized.add(pincode.trim());
            }
        }
        return new ReferenceData().resolve(normalized);
    }

    public static Id centralDeskQueueId() {
        // Query the queue only on the first request in this transaction.
        if (cachedCentralDeskQueueId == null) {
            cachedCentralDeskQueueId = new ReferenceData().queueId();
        }
        return cachedCentralDeskQueueId;
    }

    // Reads queue, manager, pincode, and branch reference data independently
    // of Lead record sharing. Each query explicitly uses its stated mode.
    private without sharing class ReferenceData {

        // Returns active Area Manager IDs grouped by normalized area. The
        // caller uses the number of matches to choose an owner.
        public Map<String, List<Id>> areaManagers(Set<String> areas) {
            Map<String, List<Id>> result = new Map<String, List<Id>>();
            // No requested areas means no manager query or matches.
            if (areas.isEmpty()) return result;

            for (User manager : [
                SELECT Id, Area__c FROM User
                WHERE IsActive = true
                  AND Designation__c = 'Area Manager'
                  AND Area__c IN :areas
                WITH SYSTEM_MODE
            ]) {
                String key = LeadAssignmentService.normalizeKey(manager.Area__c);
                // A blank manager area cannot provide a usable match.
                if (key == null) continue;
                // Keep all matching managers so multiple matches are detectable.
                if (!result.containsKey(key)) result.put(key, new List<Id>());
                result.get(key).add(manager.Id);
            }
            return result;
        }

        // Resolves pincodes through Pincode and PropelI Branch Master records.
        // Returns only mappings whose selected branch has a nonblank area.
        public Map<String, AreaRegion> resolve(Set<String> pincodes) {
            Map<String, AreaRegion> result = new Map<String, AreaRegion>();
            // No pincodes means no reference-data queries or results.
            if (pincodes.isEmpty()) return result;

            Map<String, String> branchesByPincode = new Map<String, String>();
            Set<String> branchCodes = new Set<String>();
            for (Pincode__c row : [
                SELECT Pincode__c, Branch_Cd__c
                FROM Pincode__c
                WHERE Pincode__c IN :pincodes
                WITH SYSTEM_MODE
                ORDER BY CreatedDate ASC
            ]) {
                // Query order makes the oldest Pincode record the selected
                // mapping when duplicate records are returned.
                if (!branchesByPincode.containsKey(row.Pincode__c)) {
                    branchesByPincode.put(row.Pincode__c, row.Branch_Cd__c);
                    // Only a populated branch code can be queried next.
                    if (String.isNotBlank(row.Branch_Cd__c)) branchCodes.add(row.Branch_Cd__c);
                }
            }
            // No usable branch code means no area or region can be resolved.
            if (branchCodes.isEmpty()) return result;

            Map<String, AreaRegion> areasByBranch = new Map<String, AreaRegion>();
            for (Branch_Master__c row : [
                SELECT Branch_Code__c, Area__c, Region__c
                FROM Branch_Master__c
                WHERE Branch_Code__c IN :branchCodes
                  AND is_PropelI_Branch__c = true
                WITH SYSTEM_MODE
                ORDER BY Branch_Code__c, CreatedDate ASC
            ]) {
                // Keep the oldest PropelI Branch Master record for each code.
                if (!areasByBranch.containsKey(row.Branch_Code__c)) {
                    areasByBranch.put(row.Branch_Code__c, new AreaRegion(row.Area__c, row.Region__c));
                }
            }
            for (String pincode : branchesByPincode.keySet()) {
                AreaRegion resolved = areasByBranch.get(branchesByPincode.get(pincode));
                // A missing branch or blank area leaves the pincode unresolved.
                if (resolved != null && String.isNotBlank(resolved.area)) {
                    result.put(pincode, resolved);
                }
            }
            return result;
        }

        // Returns the Central_Desk queue Id used as the fallback Lead owner.
        // Missing configuration raises ConfigurationException.
        public Id queueId() {
            List<Group> queues = [
                SELECT Id FROM Group
                WHERE Type = 'Queue' AND DeveloperName = 'Central_Desk'
                LIMIT 1
            ];
            // Assignment cannot fall back when the Central Desk queue is absent.
            if (queues.isEmpty()) {
                throw new ConfigurationException(
                    'Required Lead queue Central_Desk is missing. Configure the Central Desk queue.');
            }
            return queues[0].Id;
        }
    }
}