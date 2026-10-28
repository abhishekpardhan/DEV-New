@isTest
public class test_invoiceShareBatch {
    
       static testMethod void testMethod1() {
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        List<Branch_Master__c> lstBM = new List<Branch_Master__c>();
        
        Branch_Master__c branch = CommonDataTest.getBranchMaster();
        //insert branch;// Delhi
        lstBM.add(branch);
        
        Branch_Master__c branch2 = CommonDataTest.getBranchMaster();
        branch2.Region__c = 'MUMBAI';
        //insert branch2;
        lstBM.add(branch2);
        
        Branch_Master__c branch3 = CommonDataTest.getBranchMaster();
        branch3.Region__c = 'DELHI-11';
        //insert branch3;
        lstBM.add(branch3);
        insert lstBM;
           
        Account objMSa = CommonDataTest.getMSAAccount();
        objMSa.Propel_MSACode__c = 'MSA00000001';
        objMSa.SFX_Code__c = 'SFX0000002';
        insert objMSa;
        
        
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objMSa.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Level__c = 'SFX';
        objSfx.Description = 'TEST INV SFX1';
        objSfx.SFX_Code__c = 'SFX0000001';
        insert objSfx;
        
        
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.Submission__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
           
        PropelI_BDM_Mapping__c pbm3 = new PropelI_BDM_Mapping__c();
        pbm3.PropelI_BDM__c = us.Id;
        pbm3.Account__c = objSfx.Id;
        pbm3.Submission_Branch__c = branch.Id;
        pbm3.Collection_Branch__c =branch2.Id;
        pbm3.Billing_Branch__c = branch.Id;
        pbm3.PropelI_Branch_Id__c = '3298';
        pbm3.Collection__c = False;
        pbm3.Submission__c = True;
        pbm3.PropelI_Composite_Key__c = pbm3.PropelI_BDM__c + '::'+pbm3.PropelI_Branch_Id__c+':'+pbm3.Account__r.SFX__c+':'+pbm3.Account__r.MSA__c;
        insert pbm3;
        
           
        invoice__c inv1 = CommonDataTest.getInvoice();
        inv1.Bill_Branch__c = branch.Id;
        inv1.Sub_Branch_Master__c =  branch.Id;
        inv1.Collection_Branch__c = branch2.Id;
        inv1.Account__c = objMSa.Id;
        inv1.Billing_Level__c = 'MSA' ;
        inv1.MSA__c = objMSa.MSA__c;
        inv1.Bill_Number__c = '1231';
		insert inv1;
                   
        Test.StartTest();
        InvoiceSharebatch invoiceShar = new InvoiceSharebatch();
           invoiceShar.query = 'Select Id, Collection_PropelI_BDM_Mapping__c, Submission_propelI_BDM_Mapping__c, MSA__c, Bill_Branch__c, Sub_Branch_Master__c, Collection_Branch__c, QRM_Propeli_BDM_Mapping__c, CRS_Propeli_BDM_Mapping__c, Account__c, Billing_Level__c , NAM_Propeli_BDM_Mapping__c FROM Invoice__c';
        database.executebatch(invoiceShar);
        Test.stopTest();  

}
}