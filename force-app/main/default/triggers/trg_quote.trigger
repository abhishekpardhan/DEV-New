/**
* Description      :   Trigger on Quote__c object to perform various tasks upon different DML Operations by calling helper class methods
* 
* 
* Revision Logs    :   V_1.0 - Created
* 
**/
trigger trg_quote on Quote__c (before insert ,after update,after insert,before update) {
    
    //Checking trigger switch value
    if(System.Label.TriggerSwitch.equals('On')){
        if(trigger.isbefore && trigger.isUpdate){
            List<Quote__c> lstQuote = new List<Quote__c>();
            List<Quote__c> lstQuoteToCheckOppCon = new List<Quote__c>();
            for(quote__c q : trigger.new){
                
                //Showing error in case file is not uploaded on quote and user is trying to submit the record for approval
                if(q.Approval_Status__c == 'Submitted for Approval' && (String.isBlank(trigger.oldmap.get(q.id).Approval_Status__c) || q.Approval_Status__c!=trigger.oldmap.get(q.id).Approval_Status__c) && q.Quote_Lint_Item_Records__c ==0 && q.File_Uploaded_By_BDM__c == false){
                    q.addError('Error : Please create the Quotation or upload the file!');
                }
                if(!String.isBlank(q.Enter_Remarks__c)){
                    lstQuote.add(q);
                }
                //SAC-919 || Deepika thakur ||IBM
                if((q.Approval_Status__c == 'Submitted for Approval'|| q.Approval_Status__c == 'Pending with Regional Retail Head' )
                   &&(String.isBlank(trigger.oldmap.get(q.id).Approval_Status__c) || q.Approval_Status__c!=trigger.oldmap.get(q.id).Approval_Status__c)){
                   lstQuoteToCheckOppCon.add(q);
               }
            }
            if(!lstQuote.isEmpty()){                
                quotetriggerHelper.updateQuoteRemarks(lstQuote);
            }
            //SAC-919 || Deepika thakur ||IBM
            if(!lstQuoteToCheckOppCon.isEmpty()){                
                quotetriggerHelper.checkoppoContact(lstQuoteToCheckOppCon);
            }
            quotetriggerHelper.updateAppStatus(trigger.new); // SAC-1363
        }
        if(trigger.isbefore && trigger.isInsert){
            
        }
        if(trigger.isInsert && trigger.isAfter){
            quotetriggerHelper.updateOpportunityDetails(trigger.new); //SAC-1457
            quotetriggerHelper.updateApprovals(trigger.new);
            system.debug('chk1trigger');
            quotetriggerHelper.newquoteinserted(trigger.new);
        }
        
        if(trigger.isInsert && trigger.isBefore){
            //Method to check if existing quote is active while creating new quote then give error.
            quotetriggerHelper.checkActiveQuotes(trigger.new);
            quotetriggerHelper.changeName(trigger.new);
            
            // added by Shubham Rastogi
            quotetriggerHelper.validateOpportunity(trigger.new);
            quotetriggerHelper.updateAppStatus(trigger.new); // SAC-1363
            
        }
        
        if(trigger.isAfter && trigger.isUpdate){
            List<Quote__c> lstQuoteRejected = new List<Quote__c>();
            List<Opportunity__c> opportunityList = new List<Opportunity__c>();
            for(quote__c q : trigger.new){
                
                if((q.Approval_Status__c == 'Rejected By RM' || q.Approval_Status__c == 'Rejected By Corporate Head Credit/Retail') && 
                   (q.Approval_Status__c != trigger.oldmap.get(q.id).Approval_Status__c)){
                       lstQuoteRejected.add(q);
                   }
                if(q.Status__c == 'Sent to Customer'){
                    Opportunity__c opp = new Opportunity__c(Id = q.Opportunity__c, Valid_for_Contract_Tagging__c = true);
                    opportunityList.add(opp);
                }
            }
            if(!lstQuoteRejected.isEmpty()){
                quotetriggerHelper.quoteRejected(lstQuoteRejected);
            }
            
            if(opportunityList.size() > 0){
                quotetriggerHelper.updateValidForContractTagging(opportunityList);
            }
        }
    }
}