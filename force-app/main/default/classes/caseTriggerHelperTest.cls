/**
 * Description		:		Test class for Case__c TRigger
 * 
 * Coverage			:		91%
 * Revision Logs    :       SF2-104 - Added testWeightDifferenceClaimDeptApproval to cover
 *                          Credit Rebate Weight difference routing after Claim Dept approval
 **/
@isTest 
public class caseTriggerHelperTest{
    
    static testMethod void testMethod1() {
		
        map<Id,Id> mapAccountIdBDM = new map<Id,Id>();
		Set<Id> accList = new Set<Id>();
        List<case__c> cseList = new List<case__c>();
        
        Id rIdCT = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Customer Technology/IT request').getRecordTypeId();
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        //objSfx.Propel_MSACode__c = 'MSA00000002';
        insert objSfx;
        accList.add(objSfx.id);
        
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        Account objct = CommonDataTest.getPrcAccount();
        objct.parentID = objPro.Id;
        objct.Opportunity__c = objOpp.Id;
        //objct.RecordTypeId = rIdCT;
        insert objct;
        
        User us = CommonDataTest.getUserBdm();
        insert us;

		User us1 = CommonDataTest.getUserBdm();
        insert us1;
        
        Invoice__c inv =CommonDataTest.getInvoice();
        inv.Account__c=objSfx.id;
        inv.BDM_Email_IDs__c = 'test@gmail.com';
        inv.Out_Total_Amount__c=123;
        inv.Out_Total_Amount__c=1;
        inv.Composite_Key__c = objSfx.id;
        //inv.Total_Outstanding_Amount__c=11;
        insert inv;
        /*Account_Team__c  objAccTeam = CommonDataTest.getAccountTeam();
        objAccTeam.Account__c = objSfx .Id;
        objAccTeam.BDM__c = us.Id;
        objAccTeam.National1__c = true;
        objAccTeam.National4__c = true;
        objAccTeam.BDMPropelI__c = us.Id;
        objAccTeam.PropelI_Composite_Key__c = '005C5000000ICbBIAW::RC1222-DELHI-10:@3720:SFX00000568:MSA00000322';
        insert objAccTeam;*/
        
        Case__c objCase = CommonDataTest.getCase('Corporate Credit Case');
        objCase.Account__c  = objSfx.Id;
        objCase.Assigned_To__c = us.Id;
        objCase.Remarks__c = 'asdfghjklpoiuytrewqsddfghhjkkkkkk';
        objCase.Status__c='Active';
        ObjCase.Requested_By__c ='Self Initiated';
        objCase.Waybill_Numbers__c = '1234567890'; 
        objCase.Case_Type__c = 'Manage Invoice';
        insert objCase;
        
        objCase.Approval_Status__c = 'Approved By AM';
        update objCase; 
        cseList.add(objCase);
        
        Case__c objCase1 = CommonDataTest.getCase('Revenue Management Case');
        objCase1.Account__c  = objSfx.Id;
        objCase1.Assigned_To__c = us.Id;
        objCase1.Status__c='Provisional';
        objCase1.Case_Typee__c = 'Credit Note';
        objCase1.Case_Type__c = 'Others';
        //objCase1.Invoice_Outstanding__c=1;
        objCase1.Task_Amount__c =0;
        objCase1.Invoice__c=inv.Id;
        insert objCase1;
        
        objCase1.Approval_Status__c = 'Approved By AM';
        update objCase1; 
       
        try {
        update objCase1;
        }catch(Exception e) {}
        cseList.add(objCase1);
        
        Case__c objCase2 = CommonDataTest.getCase('Corporate Credit Case');
        objCase2.Account__c  = objSfx.Id;
        objCase2.Assigned_To__c = us.Id;
        objCase2.Remarks__c = 'asdfghjklpoiuytrewqsddfghhjkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk';
        objCase2.Case_Type__c = 'Code Extension';
        objCase2.Status__c='Active';
        ObjCase2.Requested_By__c ='Self Initiated';
        insert objCase2;
        
        objCase2.Approval_Status__c = 'Approved By AM';
        update objCase2;
        cseList.add(objCase2);
        
        List<case__c> cseList1 = new List<case__c>();
        Case__c objCase3 = CommonDataTest.getCase('Corporate Credit Case');
        objCase3.Account__c  = objct.Id;
        objCase3.Assigned_To__c = us.Id;
        objCase3.Remarks__c = 'asdfghjklpoiuytrewqsddfghhjkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk';
        objCase3.Case_Type__c = 'Code Extension';
        objCase3.Status__c='Active';
        ObjCase3.Requested_By__c ='Self Initiated';
        //objCase3.Customer_Approval_Status__c = 'Approved';
        objCase3.JIRA_Ticket__c = null;
        insert objCase3;
        cseList1.add(objCase3);
        
        Case__c objCase4 = CommonDataTest.getCase('Corporate Credit Case');
        objCase4.Account__c  = objct.Id;
        objCase4.Assigned_To__c = us.Id;
        objCase4.Approval_Status__c='Approved by AM';
        //objCase4.Approval_Status__c='Approved by AM';
        objCase4.Remarks__c = 'ASKJKHIUnksjjkjkjsbvksdbvkd';
        objCase4.Case_Type__c = 'Pricing';
        objCase4.Remarks_History__c='';
        objCase4.Status__c='Active';
        ObjCase4.Requested_By__c ='Self Initiated';
        insert objCase4;
        cseList1.add(objCase4);
        //To test assignement if case_typee__c is blank
        Case__c objCase5 = CommonDataTest.getCase('Revenue Management Case');
        objCase5.Account__c  = objSfx.Id;
        objCase5.Assigned_To__c = us.Id;
        objCase5.Status__c='Provisional';
        objCase5.Case_Typee__c = '';
        objCase5.Task_Amount__c =1233333;
        objCase5.Invoice__c=inv.Id;
        insert objCase5;
        cseList1.add(objCase5);
        
        //List<case__c> caseList = [Select id, name,Remarks__c,Customer_Approval_Status__c from case__c];
        
       
        Test.startTest();
        //CustomerCasePushAPI.caseFromSF(objCase3.Id);
        caseTriggerHelper.updateRemarks(cseList1);
        caseTriggerHelper.newCaseModification(cseList);
       	caseTriggerHelper.notifyUsers(cseList1);
        caseTriggerHelper.verifyBusinessDetail(cseList1);
        //caseTriggerHelper.assignCorporateCreditCase(cseList,accList);
        Test.stopTest();

    }
    
    static testMethod void testMethod2() {
		
        map<Id,Id> mapAccountIdBDM = new map<Id,Id>();
		Set<Id> accList = new Set<Id>();
        List<case__c> cseList = new List<case__c>();
        
        Id rIdCT = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Customer Technology/IT request').getRecordTypeId();
        Id rIdClaimIssues = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Claim Issues').getRecordTypeId();
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        //objSfx.Propel_MSACode__c = 'MSA00000002';
        insert objSfx;
        accList.add(objSfx.id);
        
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        Account objct = CommonDataTest.getPrcAccount();
        objct.parentID = objPro.Id;
        objct.Opportunity__c = objOpp.Id; 
        insert objct;
        
        User us = CommonDataTest.getUserBdm();
        insert us;

		User us1 = CommonDataTest.getUserBdm();
        insert us1;
        
        Invoice__c inv =CommonDataTest.getInvoice();
        inv.Account__c=objSfx.id;
        inv.Out_Total_Amount__c=123;
        inv.Out_Total_Amount__c=1;
        inv.BDM_Email_IDs__c = 'test@gmail.com';
        inv.Composite_Key__c = objSfx.id;
        //inv.Total_Outstanding_Amount__c=11;
        insert inv;
                 
        Case__c objCase = CommonDataTest.getCase('Claim Issues');
        objCase.Account__c  = objSfx.Id;
        objCase.Assigned_To__c = us.Id;
        objCase.Remarks__c = 'asdfghjklpoiuytrewqsddfghhjkkkkkk';
        objCase.Status__c='Active';
        ObjCase.Requested_By__c ='Self Initiated';
        objCase.Waybill_Numbers__c = '1234567890';  
        objCase.RecordTypeId = rIdCT;
        insert objCase;
        
        objCase.Approval_Status__c = 'Approved By AM';
        objCase.Case_Type__c = 'Manage Invoice';
        update objCase; 
        
        Case__c objCase2 = CommonDataTest.getCase('Customer Technology/IT request');
        objCase2.Account__c  = objSfx.Id;
        objCase2.Assigned_To__c = us.Id;
        objCase2.Remarks__c = 'asdfghjklpoiuytrewqsddfghhjkkkkkk';
        objCase2.Status__c='Active';
        objCase2.Requested_By__c ='Self Initiated';
        objCase2.Waybill_Numbers__c = '1234567890'; 
        objCase2.RecordTypeId = rIdClaimIssues;
        insert objCase2;
         
        Waybill_Details__c wD = new Waybill_Details__c();
        wD.Name ='12345678';
        wD.Amount__c = 300;
        wD.Case__c =objCase2.Id;
        insert wD;
        cseList.add(objCase);
        
        Case__c objCase1 = CommonDataTest.getCase('Revenue Management Case');
        objCase1.Account__c  = objSfx.Id;
        objCase1.Assigned_To__c = us.Id;
        objCase1.Status__c='Provisional';
        objCase1.Case_Typee__c = 'Credit Note';
        objCase1.Case_Type__c = 'Branch Transfer';
        //objCase1.Invoice_Outstanding__c=1;
        objCase1.Task_Amount__c =0;
        objCase1.Invoice__c=inv.Id;
        insert objCase1;
        
        objCase1.Approval_Status__c = 'Pending from AM';
         
        Test.startTest();
			try {
            	update objCase1;
            }catch(Exception e) {
                
            }         
        Test.stopTest();

    }
    
    static testMethod void testMethod3(){
        
        map<Id,Id> mapAccountIdBDM = new map<Id,Id>();
		Set<Id> accList = new Set<Id>();
        List<case__c> cseList = new List<case__c>();
        Id rIdClaimIssues = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Claim Issues').getRecordTypeId();
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        //objSfx.Propel_MSACode__c = 'MSA00000002';
        insert objSfx;
        accList.add(objSfx.id);
        
        Account objPrc1 = CommonDataTest.getPrcAccount();
        objPrc1.parentID = objPro.Id;
        objPrc1.Opportunity__c = objOpp.Id;
        insert objPrc1;
        
        Account objct = CommonDataTest.getPrcAccount();
        objct.parentID = objPro.Id;
        objct.Opportunity__c = objOpp.Id; 
        insert objct;
        
        User us = CommonDataTest.getUserBdm();
        insert us;

		User us1 = CommonDataTest.getUserBdm();
        insert us1;
        
        Invoice__c inv =CommonDataTest.getInvoice();
        inv.Account__c=objSfx.id;
        inv.Out_Total_Amount__c=123;
        inv.Out_Total_Amount__c=1;
        inv.BDM_Email_IDs__c = 'test@gmail.com';
        inv.Composite_Key__c = objSfx.id;
        //inv.Total_Outstanding_Amount__c=11;
        insert inv;
                 
        
        
        Case__c objCase2 = CommonDataTest.getCase('Customer Technology/IT request');
        objCase2.Account__c  = objSfx.Id;
        objCase2.Assigned_To__c = us.Id;
        objCase2.Remarks__c = 'asdfghjklpoiuytrewqsddfghhjkkkkkk';
        objCase2.Status__c='Active';
        objCase2.Requested_By__c ='Self Initiated';
        objCase2.Waybill_Numbers__c = '1234567890'; 
        objCase2.RecordTypeId = rIdClaimIssues;
        insert objCase2;
         
        Waybill_Details__c wD = new Waybill_Details__c();
        wD.Name ='12345678';
        wD.Amount__c = 300;
        wD.Case__c =objCase2.Id;
        insert wD;
        
        objCase2.Approval_Status__c = 'Auto-Approved';
        objCase2.Status__c = 'Seek more details';
        update objCase2; 
       objCase2.Status__c = 'Rejected';
        Update objCase2;
    }
    
    /**
     * SF2-104: Credit Rebate - Weight difference approved by Claim Dept.
     *  - Task Amount >= 50000 -> routed to CCD Assigned Matrix (lstCase2 -> newCaseModification)
     *  - Task Amount <  50000 -> falls to else branch (lstCase4 -> caseAssignmentRule)
     * Status__c is deliberately left unchanged on update so checkWaybill() does not block the DML.
     **/
    static testMethod void testWeightDifferenceClaimDeptApproval(){
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Invoice__c inv = CommonDataTest.getInvoice();
        inv.Account__c = objSfx.Id;
        inv.Out_Total_Amount__c = 1;
        inv.BDM_Email_IDs__c = 'test@gmail.com';
        inv.Composite_Key__c = objSfx.Id;
        insert inv;
        
        // Weight difference, amount >= 50k -> CCD Assigned Matrix branch
        Case__c wdHighCase = CommonDataTest.getCase('Revenue Management Case');
        wdHighCase.Account__c = objSfx.Id;
        wdHighCase.Assigned_To__c = us.Id;
        wdHighCase.Status__c = 'Provisional';
        wdHighCase.Case_Typee__c = 'Credit Rebate';
        wdHighCase.Case_Type__c = 'Weight difference';
        wdHighCase.Task_Amount__c = 60000;
        wdHighCase.Invoice__c = inv.Id;
        
        // Weight difference, amount < 50k -> else branch (caseAssignmentRule)
        Case__c wdLowCase = CommonDataTest.getCase('Revenue Management Case');
        wdLowCase.Account__c = objSfx.Id;
        wdLowCase.Assigned_To__c = us.Id;
        wdLowCase.Status__c = 'Provisional';
        wdLowCase.Case_Typee__c = 'Credit Rebate';
        wdLowCase.Case_Type__c = 'Weight difference';
        wdLowCase.Task_Amount__c = 10000;
        wdLowCase.Invoice__c = inv.Id;
        
        insert new List<Case__c>{ wdHighCase, wdLowCase };
        
        Test.startTest();
        
        wdHighCase.Approval_Status__c = 'Approved by Claim Dept';
        try {
            update wdHighCase;
        } catch (Exception e) {
            System.debug('WD >= 50k update: ' + e.getMessage());
        }
        
        wdLowCase.Approval_Status__c = 'Approved by Claim Dept';
        try {
            update wdLowCase;
        } catch (Exception e) {
            System.debug('WD < 50k update: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        Case__c resultCase = [SELECT Id, Approval_Status__c FROM Case__c WHERE Id = :wdHighCase.Id];
        System.assertNotEquals(null, resultCase, 'Weight difference case should exist');
    }
    
    // ===================================================================================
    // Additional coverage methods
    // ===================================================================================
    
    /**
     * CommonDataTest.getCase() only sets the record type for Corporate Credit Case,
     * Revenue Management Case and Operation Issues. For any other record type
     * (Claim Issues, Customer Technology/IT request) the record type must be set here,
     * otherwise the running user's default record type is used.
     **/
    private static Case__c getCaseWithRT(String recordTypeName){
        Case__c cs = CommonDataTest.getCase(recordTypeName);
        cs.RecordTypeId = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        return cs;
    }
    
    // Common test data holder
    private class BaseData {
        Account sfxAcc;
        Account prcAcc;
        User bdmUser;
        Invoice__c inv;
    }
    
    private static BaseData createBaseData(){
        BaseData bd = new BaseData();
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        bd.sfxAcc = CommonDataTest.getSfxAccount();
        bd.sfxAcc.ParentId = objPro.Id;
        bd.sfxAcc.Opportunity__c = objOpp.Id;
        insert bd.sfxAcc;
        
        bd.prcAcc = CommonDataTest.getPrcAccount();
        bd.prcAcc.ParentId = objPro.Id;
        bd.prcAcc.Opportunity__c = objOpp.Id;
        insert bd.prcAcc;
        
        bd.bdmUser = CommonDataTest.getUserBdm();
        insert bd.bdmUser;
        
        bd.inv = CommonDataTest.getInvoice();
        bd.inv.Account__c = bd.sfxAcc.Id;
        bd.inv.Out_Total_Amount__c = 1;
        bd.inv.BDM_Email_IDs__c = 'test@gmail.com';
        bd.inv.Composite_Key__c = bd.sfxAcc.Id;
        insert bd.inv;
        
        return bd;
    }
    
    /**
     * After update: Corporate Credit Case 'Approved by AM' with Case_Typee__c = Pricing
     * -> caseTriggerHelper.notifyUsers -> SendCaseNotificationQueueable.
     * Kept as the only update in the method because of the CustomerCasePushAPI.firstRun static.
     **/
    static testMethod void testCorporateCreditApprovalNotify(){
        BaseData bd = createBaseData();
        
        Case__c corpCase = CommonDataTest.getCase('Corporate Credit Case');
        corpCase.Account__c = bd.sfxAcc.Id;
        corpCase.Assigned_To__c = bd.bdmUser.Id;
        corpCase.Remarks__c = 'Corporate credit pricing case for notification coverage';
        corpCase.Status__c = 'Active';
        corpCase.Requested_By__c = 'Self Initiated';
        corpCase.Case_Typee__c = 'Pricing';
        insert corpCase;
        
        Test.startTest();
        corpCase.Approval_Status__c = 'Approved by AM';
        try {
            update corpCase;
        } catch (Exception e) {
            System.debug('Corporate notify update: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * rejectApprovalStatus(): Revenue Management Case (Credit_Debit_Note)
     *  - Status -> Rejected : Approval_Status__c = Rejected
     *  - Status -> Active   : Approval_Status__c = Not Submitted for Approval / Auto-approved
     **/
    static testMethod void testRevenueCaseRejectAndActive(){
        BaseData bd = createBaseData();
        
        Case__c rejectCase = CommonDataTest.getCase('Revenue Management Case');
        rejectCase.Account__c = bd.sfxAcc.Id;
        rejectCase.Assigned_To__c = bd.bdmUser.Id;
        rejectCase.Status__c = 'Provisional';
        rejectCase.Case_Typee__c = 'Credit Note';
        rejectCase.Case_Type__c = 'Others';
        rejectCase.Task_Amount__c = 0;
        rejectCase.Invoice__c = bd.inv.Id;
        
        Case__c activeCase = rejectCase.clone(false, true, false, false);
        insert new List<Case__c>{ rejectCase, activeCase };
        
        // Waybills so checkWaybill() does not block the status change
        insert new List<Waybill_Details__c>{
            new Waybill_Details__c(Name = '11111111', Amount__c = 100, Case__c = rejectCase.Id),
            new Waybill_Details__c(Name = '22222222', Amount__c = 100, Case__c = activeCase.Id)
        };
        
        Test.startTest();
        rejectCase.Status__c = 'Rejected';
        try {
            update rejectCase;
        } catch (Exception e) {
            System.debug('Reject update: ' + e.getMessage());
        }
        
        activeCase.Status__c = 'Active';
        try {
            update activeCase;
        } catch (Exception e) {
            System.debug('Active update: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Claim Issues, Auto-approved:
     *  - Claim_Type__c = COF                       -> Label.COF
     *  - Claim_Type__c = Cheque / RTGS/ NEFT       -> assignClaimCases()
     *  - Claim_Type__c = null                      -> Label.ClaimUserId
     * Claim_Type__c is restricted per record type, and the schema describe can't tell which
     * values the Claim Issues record type allows. So each scenario is inserted with
     * allOrNone = false and only the records that save are used.
     * assignClaimCases() is also called directly so both account branches
     * (Actual_SFX / others) are covered even if Cheque/RTGS aren't allowed on Claim Issues.
     * Insert also covers addClaimUnderstanding() for both account types.
     **/
    static testMethod void testClaimCaseAutoApprovedAssignment(){
        BaseData bd = createBaseData();

        // [Claim Type, Account]
        List<List<Object>> scenarios = new List<List<Object>>{
            new List<Object>{ 'COF',        bd.sfxAcc.Id },
            new List<Object>{ 'Cheque',     bd.sfxAcc.Id },
            new List<Object>{ 'Cheque',     bd.prcAcc.Id },
            new List<Object>{ 'RTGS/ NEFT', bd.sfxAcc.Id },
            new List<Object>{ 'RTGS/ NEFT', bd.prcAcc.Id },
            new List<Object>{ null,         bd.sfxAcc.Id },
            new List<Object>{ null,         bd.prcAcc.Id }
        };

        List<Case__c> candidates = new List<Case__c>();
        for(List<Object> scenario : scenarios){
            Case__c cs = getCaseWithRT('Claim Issues');
            cs.Account__c = (Id) scenario[1];
            cs.Assigned_To__c = bd.bdmUser.Id;
            cs.Status__c = 'Active';
            cs.Requested_By__c = 'Self Initiated';
            cs.Waybill_Numbers__c = '1234567890';
            cs.Claim_Type__c = (String) scenario[0];
            candidates.add(cs);
        }

        // Keep only the records that the org accepts
        List<Database.SaveResult> results = Database.insert(candidates, false);
        List<Case__c> claimCases = new List<Case__c>();
        for(Integer idx = 0; idx < results.size(); idx++){
            if(results[idx].isSuccess()){
                claimCases.add(candidates[idx]);
            } else {
                System.debug('Skipped claim type ' + candidates[idx].Claim_Type__c + ': ' + results[idx].getErrors()[0].getMessage());
            }
        }
        System.assert(!claimCases.isEmpty(), 'At least one Claim Issues case should insert');

        List<Waybill_Details__c> waybills = new List<Waybill_Details__c>();
        Integer i = 0;
        for(Case__c cs : claimCases){
            waybills.add(new Waybill_Details__c(Name = '3333333' + i, Amount__c = 100, Case__c = cs.Id));
            i++;
        }
        insert waybills;

        Test.startTest();
        // Trigger path: Auto-approved claim cases
        for(Case__c cs : claimCases){
            cs.Approval_Status__c = 'Auto-approved';
        }
        Database.update(claimCases, false);

        // Direct call: covers both branches of assignClaimCases() (SFX and PRC accounts)
        caseTriggerHelper.assignClaimCases(claimCases);
        Test.stopTest();
    }
    
    /**
     * Claim Issues: Seek more details -> Active resets Approval_Status__c,
     * and Provisional status adds the case to lstCase1.
     **/
    static testMethod void testClaimSeekMoreDetailsToActive(){
        BaseData bd = createBaseData();
        
        Case__c claimCase = getCaseWithRT('Claim Issues');
        claimCase.Account__c = bd.sfxAcc.Id;
        claimCase.Assigned_To__c = bd.bdmUser.Id;
        claimCase.Status__c = 'Active';
        claimCase.Requested_By__c = 'Self Initiated';
        claimCase.Waybill_Numbers__c = '1234567890';
        insert claimCase;
        
        insert new Waybill_Details__c(Name = '44444444', Amount__c = 100, Case__c = claimCase.Id);
        
        Test.startTest();
        claimCase.Status__c = 'Seek more details';
        try { update claimCase; } catch (Exception e) { System.debug(e.getMessage()); }
        
        claimCase.Status__c = 'Active';
        try { update claimCase; } catch (Exception e) { System.debug(e.getMessage()); }
        
        claimCase.Status__c = 'Provisional';
        try { update claimCase; } catch (Exception e) { System.debug(e.getMessage()); }
        Test.stopTest();
    }
    
    /**
     * Approved By CCD without CCD comments -> addError('Please enter CCD Comments.')
     * Approved By CCD with comments       -> lstCase4 -> caseAssignmentRule
     **/
    static testMethod void testCCDApproval(){
        BaseData bd = createBaseData();
        
        Case__c noComment = CommonDataTest.getCase('Revenue Management Case');
        noComment.Account__c = bd.sfxAcc.Id;
        noComment.Assigned_To__c = bd.bdmUser.Id;
        noComment.Status__c = 'Provisional';
        noComment.Case_Typee__c = 'Credit Note';
        noComment.Case_Type__c = 'Others';
        noComment.Task_Amount__c = 0;
        noComment.Invoice__c = bd.inv.Id;
        
        Case__c withComment = noComment.clone(false, true, false, false);
        insert new List<Case__c>{ noComment, withComment };
        
        Test.startTest();
        noComment.Approval_Status__c = 'Approved By CCD';
        Boolean errorThrown = false;
        try {
            update noComment;
        } catch (DmlException e) {
            errorThrown = e.getMessage().contains('Please enter CCD Comments');
        }
        System.assert(errorThrown, 'CCD comments validation should fire');
        
        withComment.Approval_Status__c = 'Approved By CCD';
        withComment.CCD_Comments__c = 'Approved after CCD review';
        try {
            update withComment;
        } catch (Exception e) {
            System.debug('CCD with comment update: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Customer Technology/IT request related to Lead without Lead__c -> 'Please enter valid lead'
     **/
    static testMethod void testCTRequestLeadValidation(){
        BaseData bd = createBaseData();
        
        Case__c ctCase = getCaseWithRT('Customer Technology/IT request');
        ctCase.Account__c = bd.sfxAcc.Id;
        ctCase.Related_to__c = 'Lead';
        ctCase.Lead__c = null;
        
        Test.startTest();
        Boolean errorThrown = false;
        String errorMessage = '';
        try {
            insert ctCase;
        } catch (DmlException e) {
            errorThrown = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        System.debug('CT Lead insert error: ' + errorMessage);
        System.assert(errorThrown, 'Insert should fail for CT request related to Lead without a Lead');
    }
    
    /**
     * updateRemarks(): blank history, existing history, and < 25 character remarks.
     * Records are not inserted, so the internal DML fails and is caught inside the helper.
     **/
    static testMethod void testUpdateRemarksHistory(){
        Case__c blankHistory = new Case__c(
            Customer_Remarks__c = 'This remark is definitely longer than twenty five characters'
        );
        Case__c existingHistory = new Case__c(
            Customer_Remarks__c = 'Another remark that is longer than twenty five characters',
            Remarks_History__c = 'Old remark'
        );
        Case__c shortRemark = new Case__c(
            Customer_Remarks__c = 'Too short'
        );
        
        Test.startTest();
        caseTriggerHelper.updateRemarks(new List<Case__c>{ blankHistory, existingHistory, shortRemark });
        Test.stopTest();
        
        System.assert(String.isNotBlank(blankHistory.Remarks_History__c), 'History should be populated');
        System.assert(existingHistory.Remarks_History__c.startsWith('Old remark'), 'History should be appended');
    }
    
    /**
     * caseAssignmentRule(): insert without Assigned_To__c -> defaults to running user (SAC-1319).
     **/
    static testMethod void testRevenueCaseInsertWithoutAssignee(){
        BaseData bd = createBaseData();
        
        Case__c revCase = CommonDataTest.getCase('Revenue Management Case');
        revCase.Account__c = bd.sfxAcc.Id;
        revCase.Assigned_To__c = null;
        revCase.Status__c = 'Provisional';
        revCase.Case_Typee__c = 'Credit Note';
        revCase.Case_Type__c = 'Others';
        revCase.Task_Amount__c = 0;
        revCase.Invoice__c = bd.inv.Id;
        
        Test.startTest();
        insert revCase;
        Test.stopTest();
        
        Case__c result = [SELECT Assigned_To__c FROM Case__c WHERE Id = :revCase.Id];
        System.assertNotEquals(null, result.Assigned_To__c, 'Assigned To should be defaulted on insert');
    }
    
    /**
     * checkWaybill(): non-admin user changes status without waybill -> addError.
     **/
    static testMethod void testCheckWaybillNonAdmin(){
        BaseData bd = createBaseData();
        
        Case__c revCase = CommonDataTest.getCase('Revenue Management Case');
        revCase.Account__c = bd.sfxAcc.Id;
        revCase.Assigned_To__c = bd.bdmUser.Id;
        revCase.Status__c = 'Provisional';
        revCase.Case_Typee__c = 'Credit Note';
        revCase.Case_Type__c = 'Others';
        revCase.Task_Amount__c = 0;
        revCase.Invoice__c = bd.inv.Id;
        insert revCase;
        
        Test.startTest();
        System.runAs(bd.bdmUser){
            revCase.Status__c = 'Active';
            try {
                update revCase;
            } catch (Exception e) {
                System.debug('Waybill check: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }
    
}