/**
* Description      :   Trigger on Case__c object to perform various tasks upon different DML Operations by calling helper class methods
* Release          :   17th july, 2019
* JIRA Ticket      :   https://safexpress.atlassian.net/browse/SD-357  
* Coverage         :
* Revision Logs    :   V_1.0 - Created
* 
**/
trigger trg_Case on Case__c ( before update, after insert,before insert, after update) {
    
    //Checking trigger switch values
    if(TriggerUtility.byPassTrigger) return ;
    if(System.Label.TestSwitch.equals('On')){
        //Getting various record type ids for case
        Id rtypeCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Corporate Credit Case').getRecordTypeId();
        Id rCreditCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Revenue Management Case').getRecordTypeId();
        Id rOperationCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Operation Issues').getRecordTypeId();
        Id rClaimCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Claim Issues').getRecordTypeId();
        Id rIdCT = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Customer Technology/IT request').getRecordTypeId();//Added by monika 20-02-2020
       
        //List<case__c> lstCase = new List<case__c>();
        List<case__c> lstCase11 = new List<case__c>();
        //Set<Id> lstAccountId = new Set<Id>();
        List<case__c> ReCase = new List<case__c>();//Added by Ashu
        List<case__c> lstCase1 = new List<case__c>();
        List<case__c> lstCase2 = new List<case__c>(); //Added by monika 21-11-2019
        List<case__c> lstCase3 = new List<case__c>();
        List<case__c> lstCase4 = new List<case__c>();
        List<case__c> pendingForAmCase = new List<case__c>();
        Set<Id> lstAccountId3 = new Set<Id>();
        /*  if(trigger.isbefore && trigger.isInsert){
for(case__c cs : trigger.new){
if(cs.recordtypeid == rtypeCase){
lstCase.add(cs);
lstAccountId.add(cs.Account__c);
}
}

//Calling the method to update the 'Assigned To' field on Case with 'Retail Head Corporate' user role
if(!lstCase.isEmpty()){
caseTriggerHelper.newCaseModification(lstCase,lstAccountId);
}
}*/
        
        if(trigger.isbefore && trigger.isInsert){
            List<Case__c> revenueCases = new List<Case__c> ();
            List<Case__c> claimCases = new List<Case__c> ();
            for(case__c cs : trigger.new){
                if(cs.RecordTypeId==rCreditCase){
                    revenueCases.add(cs);
                } else if(cs.RecordTypeId == rClaimCase) {
                    claimCases.add(cs);
                }
                if(cs.recordtypeid == rIdCT){
                    lstCase11.add(cs);
                    for(Case__c c : lstCase11){
                        if(c.Related_to__c == 'Lead'){
                            c.Account__c = System.Label.Lead_Account_ID;
                            if(c.Lead__c == null){
                                c.addError('Please enter valid lead');
                            }
                        }
                    }
                    
                }
                
                
                // Record Type : Customer Technology/IT request
                if (cs.recordtypeid == rIdCT && cs.Customer_Status__c ==null){
                    cs.Assigned_To__c = Label.Assign_for_Customer_Technology_IT_request;
                    cs.Customer_Status__c = 'Open';
                }
            }
            // Assign AssignTo Field value
            if(revenueCases.size()>0){
                caseTriggerHelper.caseAssignmentRule(revenueCases);
            }

            if(claimCases.size()>0){
                caseTriggerHelper.addClaimUnderstanding(claimCases);
            }
        }
        
        
        if(trigger.isAfter && trigger.isUpdate && CustomerCasePushAPI.firstRun ==true){
            CustomerCasePushAPI.firstRun = false;
            List<case__c> caseIds = new List<case__c>();
            
            for(case__c cs : trigger.new){
                if(cs.recordtypeid == rIdCT && cs.Customer_Approval_Status__c == 'Approved'&& cs.JIRA_Ticket__c == null){
                    CustomerCasePushAPI.caseFromSF(cs.Id);
                }
                if (cs.Approval_Status__c == 'Approved by AM' && 
                    Trigger.oldMap.get(cs.Id).Approval_Status__c != 'Approved by AM' && cs.recordTypeId== rtypeCase 
                    && (cs.case_typee__c == 'RFQ Support' || cs.case_typee__c=='Pricing')) {
                        caseIds.add(cs);
                    }
                
                /*if(cs.RecordTypeId == rtypeCase){
system.debug('enter-after');
lstCase3.add(cs);
lstAccountId3.add(cs.Account__c);
}
if(lstCase3.size()>0){
caseTriggerHelper.assignCorporateCreditCase(lstCase3,lstAccountId3);
}*/ 
            }
            
            if (!caseIds.isEmpty()) {
                caseTriggerHelper.notifyUsers(caseIds);
            }
        }
        
        if(trigger.isBefore && trigger.isUpdate){        
            caseTriggerHelper.rejectApprovalStatus(Trigger.new, Trigger.oldMap);//SAC-1689
            List<Case__c> allRevenueCases = new List<Case__c> ();
            List<Case__c> revenueCases = new List<Case__c> (); 
            List<Case__c> claimCasesForAssignment = new List<Case__c> (); 

            case__c oldcase= new case__c();
            for(case__c cs : trigger.new){
                oldcase=Trigger.oldMap.get(cs.Id);
                // Start SAC:2502- Sahil jain
                 system.debug('cs.Status__c');
                if(cs.Status__c!=oldcase.Status__c && (cs.Status__c=='Seek more details' ||cs.Status__c=='Rejected' ) && cs.CreatedById!=cs.Assigned_To__c && cs.recordTypeId == rClaimCase ){
                 
                    cs.Assigned_To__c=cs.CreatedById;
                    if(cs.Status__c=='Rejected'){
                        cs.Approval_Status__c='Rejected';
                    }
                }
                /*if(cs.Approval_Status__c != oldcase.Approval_Status__c && cs.Approval_Status__c?.contains('Rejected')){
                    if(cs.Status__c != 'Seek more details'){
                        cs.Status__c='Rejected';
                    }
                }*/
                //End SAC:2502 Sahil jain
                if(cs.recordtypeid == rCreditCase && cs.Approval_Status__c!=oldcase.Approval_Status__c ){            
                    allRevenueCases.add(cs);
                }
                if(cs.recordtypeid == rCreditCase && !(cs.Case_Type__c != null && (cs.Case_Type__c?.contains('Late Delivery') || cs.Case_Type__c?.contains('Weight difference')) && cs.Task_Amount__c >= 25000) && cs.Approval_Status__c!=oldcase.Approval_Status__c)
                {                
                    revenueCases.add(cs);
                    //if(cs.Approval_Status__c != trigger.oldMap.get(cs.Id).Approval_Status__c && cs.Approval_Status__c == 'Approved By AM'){
                    //lstCase.add(cs);
                    //if(!lstAccountId.contains(cs.Account__c)){
                    //    lstAccountId.add(cs.Account__c);
                    //}
                    //}
                }
              
        
                if(cs.CCD_Comments__c == '' || cs.CCD_Comments__c == null) {
                   // System.debug('cs.CCD_Comments__c == '+cs.CCD_Comments__c);
                }
                if (cs.Approval_Status__c == 'Approved By CCD' && cs.CCD_Comments__c == null && cs.Approval_Status__c != trigger.oldMap.get(cs.Id).Approval_Status__c) {
                    cs.addError('Please enter CCD Comments.');
                }
                if(cs.recordtypeid == rClaimCase && cs.Status__c == 'Provisional'){
                    lstCase1.add(cs);
                }
                
                if ((cs.Approval_Status__c == 'Approved By AM' || cs.Approval_Status__c =='Auto-approved') &&(
                            !(
                                cs.Case_Type__c != null &&
                                (cs.Case_Type__c.contains('Late Delivery') || cs.Case_Type__c.contains('Weight difference')) &&
                                cs.Task_Amount__c > 50000
                            )
                            ||
                            (
                                cs.Case_Type__c != null && cs.Case_Type__c.contains('Late Delivery') && cs.Case_Typee__c == 'Credit Rebate' &&
                                (cs.Task_Amount__c < 50000 || cs.Task_Amount__c == null || cs.Task_Amount__c == 0)
                            ) 
                            || 
                            (cs.Case_Typee__c == 'Paid Credit Note' || cs.Case_Typee__c == 'Topay Credit Note' || cs.Case_Typee__c == 'Paid Rebate Advise')
                        ) && cs.Assigned_To__c == trigger.oldMap.get(cs.Id).Assigned_To__c && (
                            cs.Approval_Status__c != trigger.oldMap.get(cs.Id).Approval_Status__c ||
                            cs.Case_Type__c != trigger.oldMap.get(cs.Id).Case_Type__c ||
                            cs.Case_Typee__c != trigger.oldMap.get(cs.Id).Case_Typee__c
                        )
                    ) {
                      //if(cs.Approval_Status__c != '' /*cs.recordtypeid == rtypeCase*/){
                      lstCase2.add(cs);//Changed by monika 21-11-2019
                      //lstAccountId.add(cs.Account__c);
                  }
                /*if(cs.RecordTypeId == rtypeCase){
system.debug('enter-before');
lstCase3.add(cs);
lstAccountId3.add(cs.Account__c);
}*/      
                
                if( (cs.Approval_Status__c == 'Approved by CCD' || cs.Approval_Status__c == 'Approved by Claim Dept') && cs.Approval_Status__c != trigger.oldMap.get(cs.Id).Approval_Status__c
                  ){
                      // SF2-104: Weight difference added - Credit Rebate LD/WD >= 50k after Claim Dept (Sachin) approval -> CCD Assigned Matrix (Vijay)
                      if(cs.Approval_Status__c == 'Approved by Claim Dept' && cs.Case_Typee__c == 'Credit Rebate' && cs.Case_Type__c != null && ((cs.Case_Type__c.contains('Shortage/Damage')) || (cs.Task_Amount__c >= 50000 && (cs.Case_Type__c.contains('Late Delivery') || cs.Case_Type__c.contains('Weight difference'))))) {
                            lstCase2.add(cs);
                      } else {
                          lstCase4.add(cs);//Changed by monika 21-11-2019
                      }
                          //do nothing
                      //if(cs.Approval_Status__c != '' /*cs.recordtypeid == rtypeCase*/){
                      //lstAccountId.add(cs.Account__c);
                  }
                if(cs.recordtypeid == rIdCT){
                    ReCase.add(cs);// Added by Ashu
                } 
                if(!ReCase.isEmpty()){//Changed by Ashu
                    caseTriggerHelper.updateRemarks(ReCase);
                }
                
                /*if(lstCase3.size()>0){
caseTriggerHelper.assignCorporateCreditCase(lstCase3,lstAccountId3);
}*/
                
                //SAC- 461, 462 || Deepika Thakur || IBM
                // Record Type : Claim Issues
                if(oldcase.Status__c =='Seek more details' && (cs.Status__c =='Active' || cs.Status__c=='Provisional')){
                        cs.Approval_Status__c = 'Not Submitted for Approval';
                    }
                 if (cs.recordtypeid == rClaimCase && cs.Total_Waybill_No__c != 0 && cs.Status__c !='Seek more details' &&  oldcase.Status__c !='Seek more details' && cs.Approval_Status__c=='Auto-approved' ){
                    
                    if(cs.Claim_Type__c == 'COF'){
                        cs.Assigned_To__c = Label.COF;
                    } else if(cs.Claim_Type__c == 'Cheque' || cs.Claim_Type__c == 'RTGS/ NEFT'){
                        claimCasesForAssignment.add(cs);
                    } else if(cs.Claim_Type__c == null){                 
                        cs.Assigned_To__c = Label.ClaimUserId;    // Convert Case Assigned to Field (Process Builder) By Tarun Sachdeva
                    }
                }
                // Record Type : Customer Technology/IT request
                else if (cs.recordtypeid == rIdCT && cs.Customer_Status__c ==null){
                    cs.Assigned_To__c = Label.Assign_for_Customer_Technology_IT_request;
                    cs.Customer_Status__c = 'Open';
                }
                List<String> businessTypes = new List<String>{'Branch Transfer','Code Extension','New SFX Code','New To-Pay Code','Sister-concern Code'};
                    if (cs.Approval_Status__c == 'Pending from AM' ||  cs.Approval_Status__c == 'Auto-approved' ){
                        for(String casType : businessTypes){
                            if(
                                (cs.Case_Type__c != null && cs.Case_Type__c.contains(casType))
                                || (cs.Case_Typee__c != null && cs.Case_Typee__c == 'Branch Transfer')
                            ){
                                pendingForAmCase.add(cs);
                                break;
                            }
                        }
                        
                    }
                
            }

            if(claimCasesForAssignment.size()>0){
                caseTriggerHelper.assignClaimCases(claimCasesForAssignment);
            }

            // verify Business detail exist for pending for AM cases
            if(pendingForAmCase.size() > 0){
                caseTriggerHelper.verifyBusinessDetail(pendingForAmCase);
            }
            // excluded from for loop, By - KR SANSI(IBM)
            if(!lstCase2.isEmpty()){//Changed by monika 21-11-2019
                caseTriggerHelper.newCaseModification(lstCase2);//Changed by monika 21-11-2019
            }
            if(!lstCase4.isEmpty()){//Changed by monika 21-11-2019
                caseTriggerHelper.caseAssignmentRule(lstCase4);//Changed by monika 21-11-2019
            }
            if (allRevenueCases.size()>0){
                System.debug('allRevenueCases'+allRevenueCases);
                caseTriggerHelper.AssignCaseToTheApprover(allRevenueCases, Trigger.oldMap);
            }
            // Assign AssignTo values
            if(revenueCases.size()>0){
                try{
                    caseTriggerHelper.caseAssignmentRule(revenueCases);
                } catch (Exception ex) {
                    System.debug('Error in caseAssignmentRule: ' + ex.getMessage());
                }
            }
            caseTriggerHelper.checkWaybill(Trigger.new,Trigger.oldMap);
        }
        
        //Method to update the 'Assigned To' field on Case with 'BDM' of respective Account's Account Team
        /*Monika if(!lstCase.isEmpty()){
caseTriggerHelper.updateAssignedTo(lstCase,lstAccountId);
}Monika*/
        
        //Calling the method to update the case status to active if it is claim case and status is provisional
        //Monika if(!lstCase1.isEmpty()){
        //Monika     caseTriggerHelper.changeStatusActive(lstCase1);
        //Monika }
        if(trigger.isAfter && trigger.isInsert){
            List<case__c> lstCases = new List<case__c>();
            for(case__c cs : trigger.new){
                if(cs.recordtypeid == rOperationCase && cs.Status__c == 'Active'){
                    lstCases.add(cs);
                }
            }
            
            //Calling the method to push the Operational case of Active status to third party system
            if(!lstCases.isEmpty()){
                CasePushApi.caseFromSF();
            }
        }
        
        
        //==========Added on 5/2/2019===========
        //Method to allow only certain field updation on Case__c object if Approval Status is approved.
      //  if(Trigger.isBefore && Trigger.isUpdate) { 
            //caseTriggerHelper.preventRecordEditing(Trigger.new, Trigger.oldMap);
        //}
        
    }
}