/**
 * @description Handler for Debit/Credit Note triggers.
 *              Creates Submission Tasks for new Debit_Credit_Note__c records that reference an invoice.
 *              Bulkified, respects sharing and FLS using USER_MODE for queries and DML.
 */
public with sharing class DebitCreditNoteHandler {

    public static void createSubmissionTask(List<Id> debitCreditNoteIds) {
        Set<Id> invoiceIds = new Set<Id>();
        Map<Id, Debit_Credit_Note__c> invoiceIdToDcn = new Map<Id, Debit_Credit_Note__c>();
        List<Debit_Credit_Note__c> dcnList = [
            SELECT Id, Invoice_Name__c, Bill_Number__c,Created_Date__c, CreatedDate, Note_Number__c,
                   Invoice_Name__r.Submission_propelI_BDM_Mapping__c,
                   Invoice_Name__r.Collection_PropelI_BDM_Mapping__c,
                   Invoice_Name__r.NAM_Propeli_BDM_Mapping__c
            FROM Debit_Credit_Note__c
            WHERE Id IN :debitCreditNoteIds AND Note_Type__c = 'Debit Note Created'
            WITH USER_MODE
        ];
        for (Debit_Credit_Note__c dcn : dcnList) {
            if (dcn.Invoice_Name__c != null && (dcn.Invoice_Name__r.Submission_propelI_BDM_Mapping__c != null || dcn.Invoice_Name__r.NAM_Propeli_BDM_Mapping__c != null)) {
                invoiceIds.add(dcn.Invoice_Name__c);
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            Map<Id, Invoice__c> invoiceMap = New Map<Id, Invoice__c>([ 
                SELECT Id, MSA_Name__c, Out_Total_Amount__c, Account__r.Parent.Name, Billing_Level__c, Green_Book__c,Account__r.Name,
                       Submission_propelI_BDM_Mapping__c, Submission_propelI_BDM_Mapping__r.PropelI_BDM__c, Bill_Branch__c, Total_Outstanding_Amount__c,
                       Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,
                       Charged_Freight_Amount__c, Charged_ST_Amount__c,
                       NAM_Propeli_BDM_Mapping__c, NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c, Bill_Number__c, CreatedDate,
                       QRM_Propeli_BDM_Mapping__c, QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c, Account__r.Customer_Category__c, Customer_Contract_Code__c,
                       CRS_Propeli_BDM_Mapping__c, CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c, SFX_Code__c, SFX__r.Customer_Category__c
                FROM Invoice__c
                WHERE Id IN :invoiceIds
            ]);

            Map<Id, String> invToUserMap = invoiceTriggerHelper.invToUserid('Sub', invoiceMap.values());
            Id subTaskRecordId;
            Schema.RecordTypeInfo rti = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Submission');
            if (rti != null) {
                subTaskRecordId = rti.getRecordTypeId();
            }

            List<Task> submissionTasks = new List<Task>();

            for (Debit_Credit_Note__c dcn : dcnList) {
                if (dcn.Invoice_Name__c == null || !invoiceMap.containsKey(dcn.Invoice_Name__c)) {
                    continue;
                }
                Invoice__c invRec = invoiceMap.get(dcn.Invoice_Name__c);
                Task task = new Task();
                String noteNumber = dcn.Note_Number__c;
                if (String.isBlank(noteNumber)) {
                    noteNumber = invRec.Bill_Number__c;
                }
                task.Subject = 'Debit Note Submission Task - ' + (noteNumber == null ? '' : noteNumber);
                task.RecordTypeId = subTaskRecordId;
                task.WhatId = dcn.Id;
                task.Invoice_date__c = dcn.Created_Date__c;
                task.SFX_Code__c = invRec.Customer_Contract_Code__c;
                task.Customer_Category__c = (invRec.Account__r != null) ? invRec.Account__r.Customer_Category__c : null;
                task.Billing_Branch__c = invRec.Bill_Branch__c;
                task.Billing_Level__c = invRec.Billing_Level__c;
                task.Account_Name__c = invRec.MSA_Name__c;

                task.Priority = 'High';
                task.Status = 'Open';

                Id ownerId = invToUserMap != null ? (Id)invToUserMap.get(invRec.Id) : null;
                task.OwnerId = ownerId;
                task.Automation__c = true;
                task.Green_Book__c = invRec.Green_Book__c;
                task.ActivityDate = Date.newInstance(dcn.CreatedDate.year(), dcn.CreatedDate.month(), dcn.CreatedDate.day()).addDays(7);
                submissionTasks.add(task);
                
            }

            if (!submissionTasks.isEmpty()) {
                Database.insert(submissionTasks, false);
            }

        } catch (Exception e) {
            Database.rollback(sp);
            ExceptionHandling.Exception('createSubmissionTask', 'DebitCreditNoteHandler', e);
        }
    }

    public static void updateCaseCreditNote(List<Debit_Credit_Note__c> creditNotes, Boolean isBefore) {
        Map<String, Debit_Credit_Note__c> caseNumberToNote = new Map<String, Debit_Credit_Note__c>();
        Map<String, Case__c> caseToCreditNoteMap = new Map<String, Case__c>();
        Set<Id> assignedToIds = new Set<Id>();
        Map<Id, Boolean> userProfilecheck = new Map<Id, Boolean>();

        try {
            for (Debit_Credit_Note__c note : creditNotes) {
                String caseNumber = getCaseNumberFromRemarks(note.Remarks__c);
                if (caseNumber != null) {
                    caseNumberToNote.put(caseNumber, note);
                } else if (isBefore) {
                    note.Case_Status__c = 'Case Not Found or Wrong Format';
                }
            }

            if (!caseNumberToNote.isEmpty()) {

                List<Case__c> cases = [
                    SELECT Id, Assigned_To__c, Credit_Debit_note_number__c, Name,
                        RecordType.DeveloperName, Case_Typee__c, Status__c
                    FROM Case__c 
                    WHERE Name IN :caseNumberToNote.keySet()
                ];

                for (Case__c c : cases) {
                    if (c.Assigned_To__c != null) {
                        assignedToIds.add(c.Assigned_To__c);
                    }
                }

                if (!assignedToIds.isEmpty()) {
                    Id rmProfileId = ConstantUtility.getProfileIdByName('Revenue Management');

                    for (User u : [SELECT Id, ProfileId FROM User WHERE Id IN :assignedToIds]) {
                        userProfilecheck.put(u.Id, u.ProfileId == rmProfileId);
                    }
                }

                List<Case__c> casesToUpdate = new List<Case__c>();

                for (Case__c c : cases) {

                    Boolean isValidRecordType = c.RecordType.DeveloperName == 'Credit_Debit_Note';
                    Boolean isValidCaseType   = c.Case_Typee__c == ConstantUtility.CREDIT_NOTE;

                    Boolean isRMUser = userProfilecheck.containsKey(c.Assigned_To__c) &&
                                    userProfilecheck.get(c.Assigned_To__c);

                    if (!isBefore) {
                        if (isValidRecordType &&
                            isValidCaseType &&
                            c.Status__c != ConstantUtility.CASE_STATUS_REJECTED &&
                            isRMUser) {

                            c.Credit_Debit_note_number__c = caseNumberToNote.get(c.Name).Note_Number__c;
                            c.Status__c = 'Completed';
                            casesToUpdate.add(c);
                        }
                    } else {
                        caseToCreditNoteMap.put(c.Name, c);
                    }
                }

                if (!isBefore && !casesToUpdate.isEmpty()) {
                    update casesToUpdate;
                }
            }

            if (isBefore) {

                for (Debit_Credit_Note__c note : creditNotes) {

                    String caseNumber = getCaseNumberFromRemarks(note.Remarks__c);
                    if (caseNumber == null) continue;

                    if (!caseToCreditNoteMap.containsKey(caseNumber)) {
                        note.Case_Status__c = 'Case Not Found with Case Number: ' + caseNumber;
                    } else {

                        Case__c c = caseToCreditNoteMap.get(caseNumber);

                        Boolean isValidRecordType = c.RecordType.DeveloperName == 'Credit_Debit_Note';
                        Boolean isValidCaseType   = c.Case_Typee__c == ConstantUtility.CREDIT_NOTE;

                        Boolean isRMUser = userProfilecheck.containsKey(c.Assigned_To__c) &&
                                        userProfilecheck.get(c.Assigned_To__c);

                        if (c.Status__c == ConstantUtility.CASE_STATUS_REJECTED) {
                            note.Case_Status__c = 'Credit note case is Rejected: ' + caseNumber;
                        }
                        else if (!isRMUser) {
                            note.Case_Status__c = 'Case is not approved yet';
                        }
                        else if (!isValidRecordType || !isValidCaseType) {
                            note.Case_Status__c = 'Case found but RecordType/CaseType is incorrect: ' + caseNumber;
                        }
                        else {
                            note.Case_Status__c = 'Case Found - ' + c.Name;
                        }
                    }
                }
            }

        } catch (Exception e) {
            ExceptionHandling.Exception('updateCaseCreditNote', 'DebitCreditNoteHandler', e);
        }
    }

    public static String getCaseNumberFromRemarks(String remarks) {

        if (String.isNotBlank(remarks) && remarks.contains(';')) {
            String raw = remarks.split(';')[0].trim();

            String cleaned = raw.replaceAll('\\s+', '');
            return cleaned;
        }

        return null;
    }
}