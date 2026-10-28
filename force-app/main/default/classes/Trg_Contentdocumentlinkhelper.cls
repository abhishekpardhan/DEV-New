public class Trg_Contentdocumentlinkhelper {

    public static void validateFileUpload(List<ContentDocumentLink> cdlList) {
        if (cdlList == null || cdlList.isEmpty()) return;

        Set<Id> contractIds = collectContractIds(cdlList);
        if (contractIds.isEmpty()) return;

        Boolean              hasCMTReadWrite       = FeatureManagement.checkPermission('Contract_Management_Team_Read_Write');
        Map<Id, Contract__c> contractMap           = queryContracts(contractIds);
        Set<Id>              contractsWithBlockOpp = queryContractsWithBlockingOpp(contractIds);

        Set<Id> closedContractIds       = getClosedContractIds(contractMap);
        Set<Id> contractsWithSFXAccount = (hasCMTReadWrite && !closedContractIds.isEmpty())
            ? queryContractsWithSFXAccount(closedContractIds)
            : new Set<Id>();

        for (ContentDocumentLink cdl : cdlList) {
            if (cdl.LinkedEntityId == null) continue;

            Contract__c con = contractMap.get(cdl.LinkedEntityId);
            if (con == null) continue;

            if (isUploadBlocked(con, contractsWithBlockOpp, hasCMTReadWrite, contractsWithSFXAccount)) {
                cdl.addError(buildErrorMessage(con, hasCMTReadWrite, contractsWithSFXAccount));
            }
        }
    }

    // ─── Private ─────────────────────────────────────────────────────────────

    private static Set<Id> collectContractIds(List<ContentDocumentLink> cdlList) {
        Set<Id> ids = new Set<Id>();
        for (ContentDocumentLink cdl : cdlList) {
            if (cdl.LinkedEntityId != null &&
                cdl.LinkedEntityId.getSObjectType() == Contract__c.SObjectType) {
                ids.add(cdl.LinkedEntityId);
            }
        }
        return ids;
    }

    private static Map<Id, Contract__c> queryContracts(Set<Id> contractIds) {
        return new Map<Id, Contract__c>([
            SELECT Id, RecordType.DeveloperName
            FROM Contract__c
            WHERE Id IN :contractIds
        ]);
    }

    private static Set<Id> getClosedContractIds(Map<Id, Contract__c> contractMap) {
        Set<Id> closedIds = new Set<Id>();
        for (Contract__c con : contractMap.values()) {
            if (con.RecordType != null && con.RecordType.DeveloperName == 'Closed') {
                closedIds.add(con.Id);
            }
        }
        return closedIds;
    }

    private static Set<Id> queryContractsWithBlockingOpp(Set<Id> contractIds) {
        Set<Id> result = new Set<Id>();
        for (Opportunity__c opp : [
            SELECT Contract__c
            FROM Opportunity__c
            WHERE Contract__c IN :contractIds
              AND Stage__c IN ('Closed Won', 'Closed Lost')
        ]) {
            result.add(opp.Contract__c);
        }
        return result;
    }

    private static Set<Id> queryContractsWithSFXAccount(Set<Id> closedContractIds) {
        Set<Id> result = new Set<Id>();
        for (Account acc : [
            SELECT Contract__c
            FROM Account
            WHERE Contract__c IN :closedContractIds
              AND RecordType.DeveloperName = 'Actual_SFX'
        ]) {
            result.add(acc.Contract__c);
        }
        return result;
    }

    /**
     * Block rules:
     *   Closed RT — block all, except CMT Read/Write users when an Actual_SFX
     *               account is linked to the contract.
     *   Open RT   — block when any linked Opp is Closed Won or Closed Lost.
     */
    private static Boolean isUploadBlocked(
        Contract__c con,
        Set<Id>     contractsWithBlockOpp,
        Boolean     hasCMTReadWrite,
        Set<Id>     contractsWithSFXAccount
    ) {
        if (con.RecordType == null) return false;

        String rt = con.RecordType.DeveloperName;

        if (rt == 'Closed') {
            if (hasCMTReadWrite && contractsWithSFXAccount.contains(con.Id)) {
                return false;
            }
            return true;
        }

        if (rt == 'Open') {
            return contractsWithBlockOpp.contains(con.Id);
        }

        return false;
    }

    private static String buildErrorMessage(
        Contract__c con,
        Boolean     hasCMTReadWrite,
        Set<Id>     contractsWithSFXAccount
    ) {
        if (con.RecordType != null && con.RecordType.DeveloperName == 'Closed') {
            if (hasCMTReadWrite && !contractsWithSFXAccount.contains(con.Id)) {
                return 'Files cannot be uploaded. No SFX account is linked to this contract.';
            }
            return 'Files cannot be uploaded. This contract is closed.';
        }
        return 'Files cannot be uploaded. A linked Opportunity is Closed Won or Closed Lost.';
    }
}