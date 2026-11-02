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
    public static Boolean isJobUpdate = false;
    private static Id cachedCentralDeskQueueId;

    // Prepare new Leads before they are saved. Set Central Desk eligibility for
    // Website/Case Leads, resolve known pincodes locally, and mark unknown ones
    // Pending so they can be looked up after insert.
    public static void onBeforeInsert(List<Lead> newLeads) {
        try {
            Set<String> pincodes = new Set<String>();
            for (Lead row : newLeads) {
                if (row.LeadSource == 'Website' || row.Case__c != null) {
                    row.Assign_to_Central_Desk__c = true;
                }
                row.Assignment_Evaluated__c = false;
                if (String.isNotBlank(row.PostalCode)) pincodes.add(row.PostalCode.trim());
            }

            Map<String, AreaRegion> local = resolveLocal(pincodes);
            List<Lead> assignable = new List<Lead>();

            for (Lead row : newLeads) {
                AreaRegion resolved = local.get(row.PostalCode.trim());
                if (resolved == null) {
                    row.Pincode_Lookup_Status__c = 'Pending';
                } else {
                    row.Area__c   = resolved.area;
                    row.Region__c = resolved.region;
                    row.Pincode_Lookup_Status__c = 'Completed';
                    if (row.Assign_to_Central_Desk__c == true) assignable.add(row);
                }
            }

            assignAreaManager(assignable);

        } catch (ConfigurationException ce) {
            throw ce;
        } catch (Exception e) {
            logError('onBeforeInsert', e);
        }
    }

    // Start the external lookup for newly saved Leads whose pincode was not
    // found locally. Create Draft integration transactions; their trigger
    // handles the later API processing.
    public static void onAfterInsert(List<Lead> newLeads) {
        try {
            List<Integration_Transaction__c> txns = new List<Integration_Transaction__c>();
            for (Lead row : newLeads) {
                if (row.Pincode_Lookup_Status__c == 'Pending' && String.isNotBlank(row.PostalCode)) {
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
            if (!txns.isEmpty()) insert txns; // IntegrationTransactionHandler takes over
        } catch (Exception e) {
            logError('onAfterInsert', e);
        }
    }

    // Record unexpected service errors with the method name and stack trace.
    // If the logging utility fails, write its failure to the debug log.
    private static void logError(String methodName, Exception e) {
        try {
            String msg = e.getTypeName() + ': ' + e.getMessage()
                + ' | Line ' + e.getLineNumber() + ' | ' + e.getStackTraceString();
            // Same order as your example: class name, then method name
            ExceptionHandling.Exception('LeadAssignmentService', methodName, msg.abbreviate(32000));
        } catch (Exception logEx) {
            System.debug(LoggingLevel.ERROR, 'ExceptionHandling failed: ' + logEx.getMessage());
        }
    }

    // Handle Leads newly marked for Central Desk during an update. Skip job
    // updates and pending lookups; send previously evaluated Leads to the
    // queue and evaluate the others for an Area Manager.
    public static void onBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        if (isJobUpdate) return;
        try {
            List<Lead> assignable = new List<Lead>();
            for (Lead row : newLeads) {
                Lead previous = oldMap.get(row.Id);
                if (previous == null
                    || previous.Assign_to_Central_Desk__c == true
                    || row.Assign_to_Central_Desk__c != true
                    || row.Pincode_Lookup_Status__c == 'Pending') continue;

                if (row.Assignment_Evaluated__c == true) {
                    row.OwnerId = centralDeskQueueId();
                } else {
                    assignable.add(row);
                }
            }
            assignAreaManager(assignable);

        } catch (ConfigurationException ce) {
            throw ce;
        } catch (Exception e) {
            logError('onBeforeUpdate', e);
        }
    }

    // Choose an owner for Leads ready for assignment. Give a Lead to its Area
    // Manager only when exactly one active manager matches the area; otherwise
    // keep it with Central Desk and mark the assignment as evaluated.
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
            if (matches != null && matches.size() == 1) {
                row.OwnerId = matches[0];
                row.Assign_to_Central_Desk__c = false;
                row.Assignment_Date__c = assignedAt;
            } else {
                row.OwnerId = centralDeskQueueId();
                row.Assign_to_Central_Desk__c = true;
            }
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

    // Check available pincode and branch records before using the external API.
    // Trim nonblank pincodes and return their locally resolved area and region
    // so callers can complete lookup and assignment in the same transaction.
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

    // Get the Central Desk queue used when no unique manager can own a Lead.
    // Cache its Id for repeated assignments in the same transaction.
    public static Id centralDeskQueueId() {
        if (cachedCentralDeskQueueId == null) {
            cachedCentralDeskQueueId = new ReferenceData().queueId();
        }
        return cachedCentralDeskQueueId;
    }

    // Read queue, manager, pincode, and branch reference data for assignment.
    // These lookups must work independently of Lead record sharing.
    private without sharing class ReferenceData {

        // Find active Area Managers for the requested areas. Group their Ids
        // by normalized area so assignment can detect a single match or fall
        // back to Central Desk when multiple managers match.
        public Map<String, List<Id>> areaManagers(Set<String> areas) {
            Map<String, List<Id>> result = new Map<String, List<Id>>();
            if (areas.isEmpty()) return result;

            for (User manager : [
                SELECT Id, Area__c FROM User
                WHERE IsActive = true
                  AND Designation__c = 'Area Manager'
                  AND Area__c IN :areas
                WITH SYSTEM_MODE
            ]) {
                String key = LeadAssignmentService.normalizeKey(manager.Area__c); // Change 4
                if (key == null) continue;
                if (!result.containsKey(key)) result.put(key, new List<Id>());
                result.get(key).add(manager.Id);
            }
            return result;
        }

        // Resolve requested pincodes using local Pincode and PropelI Branch
        // Master records. Use the oldest mapping for duplicates and return
        // only pincodes whose branch provides a nonblank area.
        public Map<String, AreaRegion> resolve(Set<String> pincodes) {
            Map<String, AreaRegion> result = new Map<String, AreaRegion>();
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
                if (!branchesByPincode.containsKey(row.Pincode__c)) {
                    branchesByPincode.put(row.Pincode__c, row.Branch_Cd__c);
                    if (String.isNotBlank(row.Branch_Cd__c)) branchCodes.add(row.Branch_Cd__c);
                }
            }
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
                if (!areasByBranch.containsKey(row.Branch_Code__c)) {
                    areasByBranch.put(row.Branch_Code__c, new AreaRegion(row.Area__c, row.Region__c));
                }
            }
            for (String pincode : branchesByPincode.keySet()) {
                AreaRegion resolved = areasByBranch.get(branchesByPincode.get(pincode));
                if (resolved != null && String.isNotBlank(resolved.area)) {
                    result.put(pincode, resolved);
                }
            }
            return result;
        }

        // Find the queue used as the fallback Lead owner. Fail with a clear
        // configuration error when Central_Desk is missing instead of assigning
        // a Lead to an unknown owner.
        public Id queueId() {
            List<Group> queues = [
                SELECT Id FROM Group
                WHERE Type = 'Queue' AND DeveloperName = 'Central_Desk'
                LIMIT 1
            ];
            if (queues.isEmpty()) {
                throw new ConfigurationException(
                    'Required Lead queue Central_Desk is missing. Configure the Central Desk queue.');
            }
            return queues[0].Id;
        }
    }
}