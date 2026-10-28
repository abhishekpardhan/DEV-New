@isTest
public class InvoiceShareListTest {

     @testSetup static void  bdmSetup(){
        Id sfxRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        List<Account> lstAcnt = new List<Account>();
        Account objMSa = CommonDataTest.getMSAAccount();
        objMSa.Propel_MSACode__c = 'MSA00000001';
        objMSa.SFX_Code__c = 'SFX0000002';
        insert objMSa;
        //lstAcnt.add(objMSa);
        
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objMSa.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Level__c = 'SFX';
        objSfx.Description = 'TEST INV SFX1';
        objSfx.SFX_Code__c = 'SFX0000001';
        //insert objSfx;
        lstAcnt.add(objSfx);
        
        
        Account objSfx2 = CommonDataTest.getSfxAccount();
        objSfx2.parentID = objMSa.Id;
        objSfx2.Opportunity__c = objOpp.Id;
        objSfx2.Billing_Level__c = 'MSA';
        objSfx2.Description = 'TEST INV SFX2';
        objSfx2.SFX_Code__c = 'SFX0000002';
        objSfx2.RecordTypeId= sfxRecId;
        //insert objSfx2;
        lstAcnt.add(objSfx2);
        
        Account objSfx3 = CommonDataTest.getSfxAccount();
        objSfx3.parentID = objMSa.Id;
        objSfx3.Opportunity__c = objOpp.Id;
        objSfx3.Billing_Level__c = 'SFX';
        objSfx3.Description = 'TEST INV SFX3';
        objSfx3.SFX_Code__c = 'SFX0000003';
        objSfx3.RecordTypeId= sfxRecId;
        //insert objSfx3;
        lstAcnt.add(objSfx3);
        insert lstAcnt;
        
        List<User> lstUser = new List<User>();
        
        User bdm = CommonDataTest.getUserBdm();
        bdm.firstname ='Akshay';
        //insert bdm;
        lstUser.add(bdm);
        
        User bdm2 = CommonDataTest.getUserBdm();
        bdm2.firstname ='Alok';
        //insert bdm2;
        lstUser.add(bdm2);
        
        User bdm3 = CommonDataTest.getUserBdm();
        bdm3.firstname ='Rahul';
        //insert bdm3;
        lstUser.add(bdm3);
        insert lstUser;
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
        
        
        List<PropelI_BDM_Mapping__c> lstPBM = new List<PropelI_BDM_Mapping__c>();
        
        PropelI_BDM_Mapping__c pbm1 = new PropelI_BDM_Mapping__c();
        pbm1.PropelI_BDM__c = bdm.Id;
        pbm1.Account__c = objSfx3.Id;
        pbm1.Submission_Branch__c = branch.Id;
        pbm1.Collection_Branch__c =branch.Id;
        pbm1.Billing_Branch__c = branch.Id;
        pbm1.PropelI_Branch_Id__c = '3298';
        pbm1.Collection__c = True;
        pbm1.Submission__c = True;
        pbm1.Local_NAM__c = True;
        pbm1.QRM__c = True;
        pbm1.CRS__c = True;
        pbm1.PropelI_Composite_Key__c = pbm1.PropelI_BDM__c + '::'+pbm1.PropelI_Branch_Id__c+':'+pbm1.Account__r.SFX__c+':'+pbm1.Account__r.MSA__c;
        //insert pbm1;
        lstPBM.add(pbm1);
        
        PropelI_BDM_Mapping__c pbm2 = new PropelI_BDM_Mapping__c();
        pbm2.PropelI_BDM__c = bdm2.Id;
        pbm2.Account__c = objSfx2.Id;
        pbm2.Submission_Branch__c = branch.Id;
        pbm2.Collection_Branch__c =branch2.Id;
        pbm2.Billing_Branch__c = branch.Id;
        pbm2.PropelI_Branch_Id__c = '3298';
        pbm2.Collection__c = True;
        pbm2.Submission__c = False;
        pbm2.Local_NAM__c = True;
        pbm2.QRM__c = True;
        pbm2.CRS__c = True;
        pbm2.PropelI_Composite_Key__c = pbm2.PropelI_BDM__c + '::'+pbm2.PropelI_Branch_Id__c+':'+pbm2.Account__r.SFX__c+':'+pbm2.Account__r.MSA__c;
        //insert pbm2;
        lstPBM.add(pbm2);
        
        PropelI_BDM_Mapping__c pbm3 = new PropelI_BDM_Mapping__c();
        pbm3.PropelI_BDM__c = bdm3.Id;
        pbm3.Account__c = objSfx2.Id;
        pbm3.Submission_Branch__c = branch.Id;
        pbm3.Collection_Branch__c =branch2.Id;
        pbm3.Billing_Branch__c = branch.Id;
        pbm3.PropelI_Branch_Id__c = '3298';
        pbm3.Collection__c = False;
        pbm3.Submission__c = False;
        pbm3.Local_NAM__c = True;
        pbm3.QRM__c = True;
        pbm3.CRS__c = True;
        pbm3.PropelI_Composite_Key__c = pbm3.PropelI_BDM__c + '::'+pbm3.PropelI_Branch_Id__c+':'+pbm3.Account__r.SFX__c+':'+pbm3.Account__r.MSA__c;
        
        lstPBM.add(pbm3);
        
        
        insert lstPBM;
        
         
         List<invoice__c> lstInv = new List<invoice__c>();
        //MSA <-> SFX-2 
        invoice__c inv1 = CommonDataTest.getInvoice();
        inv1.Bill_Branch__c = branch.Id;
        inv1.Sub_Branch_Master__c =  branch.Id;
        inv1.Collection_Branch__c = branch2.Id;
        inv1.Account__c = objMSa.Id;
        inv1.Billing_Level__c = 'MSA' ;
        inv1.MSA__c = objMSa.MSA__c;
        inv1.Bill_Number__c = '1231';
        inv1.Submission_propelI_BDM_Mapping__c = pbm1.Id; 
        inv1.Collection_PropelI_BDM_Mapping__c = pbm1.Id;
        inv1.NAM_Propeli_BDM_Mapping__c = pbm1.Id;
        inv1.QRM_Propeli_BDM_Mapping__c = pbm1.Id;
        inv1.CRS_Propeli_BDM_Mapping__c = pbm1.Id;
        //insert inv1;
        lstInv.add(inv1);
        
        //SFX1
        invoice__c inv2 = CommonDataTest.getInvoice();
        inv2.Bill_Branch__c = branch.Id;
        inv2.Sub_Branch_Master__c =  branch.Id;
        inv2.Collection_Branch__c = branch.Id;
        inv2.Account__c = objSfx.Id;
        inv2.Billing_Level__c = 'SFX' ;
        inv2.SFX_Code__c = objSfx.SFX__c ;
        inv2.Bill_Number__c = '1232';
        //insert inv2;
        lstInv.add(inv2);
        
        //SFX2
        invoice__c inv3 = CommonDataTest.getInvoice();
        inv3.Bill_Branch__c = branch.Id;
        inv3.Sub_Branch_Master__c =  branch.Id;
        inv3.Collection_Branch__c = branch2.Id;
        inv3.Account__c = objSfx2.Id;
        inv3.Billing_Level__c = 'SFX' ;
        inv3.SFX_Code__c = objSfx2.SFX__c ;
        inv3.Bill_Number__c = '1233';
        //insert inv3;
        lstInv.add(inv3);
        
        //SFX3
        invoice__c inv4 = CommonDataTest.getInvoice();
        inv4.Bill_Branch__c = branch.Id;
        inv4.Sub_Branch_Master__c =  branch.Id;
        inv4.Collection_Branch__c = branch3.Id;
        inv4.Account__c = objSfx3.Id;
        inv4.Billing_Level__c = 'SFX' ;
        inv4.SFX_Code__c = objSfx3.SFX__c ;
        inv4.Bill_Number__c = '1234';
        //insert inv4;
        lstInv.add(inv4);
        insert lstInv;
        
    }
    
    @isTest
    public static void invoiceShareTest(){
        Test.startTest();
        	InvoiceShareList batchObject = new InvoiceShareList();
            batchObject.query = 'SELECT Id, Submission_propelI_BDM_Mapping__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.Name,Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.Name ,NAM_Propeli_BDM_Mapping__c,NAM_Propeli_BDM_Mapping__r.PropelI_BDM__r.Name,QRM_Propeli_BDM_Mapping__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__r.Name,CRS_Propeli_BDM_Mapping__c,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__r.Name FROM invoice__c ' ;
        	batchObject.emailList = new List<String>{'test@test.com'};
            Database.executeBatch(batchObject);
        Test.stopTest();
    }
}