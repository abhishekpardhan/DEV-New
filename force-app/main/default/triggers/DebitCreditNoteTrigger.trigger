trigger DebitCreditNoteTrigger on Debit_Credit_Note__c (before insert, after insert) {

    if(System.Label.TriggerSwitch != 'On') return;

    if(Trigger.isInsert) {
        List<Id> debitNoteIds = new List<Id>();
        List<Debit_Credit_Note__c> creditNotes = new List<Debit_Credit_Note__c>();

        for(Debit_Credit_Note__c note : Trigger.new) {
            if(note.Note_Type__c == 'CREDIT_NOTE') {
                creditNotes.add(note);
            }
        }
        
        if(Trigger.isBefore) {
            if(!creditNotes.isEmpty()) {
                DebitCreditNoteHandler.updateCaseCreditNote(creditNotes, trigger.isBefore);
            }
        }

        if(Trigger.isAfter) {
            for(Debit_Credit_Note__c note : Trigger.new) {
                if(note.Note_Type__c == 'Debit Note Created') {
                    debitNoteIds.add(note.Id);
                } 
            }
            if(!debitNoteIds.isEmpty()) {
                DebitCreditNoteHandler.createSubmissionTask(debitNoteIds);
            }
            if(!creditNotes.isEmpty()) {
                DebitCreditNoteHandler.updateCaseCreditNote(creditNotes, trigger.isBefore);
            }
        }
    
    }
        
}