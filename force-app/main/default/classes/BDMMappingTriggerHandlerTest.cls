/** 
* Description      :   Test class for PropelI_BDM_Mapping__c trigger.
* Last Changed     :   22,March,2024
* Author           :   Raghav, IBM
* Release          :   
* JIRA Ticket		:	https://safexpress.atlassian.net/browse/SAC-507
* Coverage			:
* Revision Logs    :   
**/
@isTest
private class BDMMappingTriggerHandlerTest {
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
        List<invoice__c> lstInv = new List<invoice__c>();
        //MSA <-> SFX-2 
        invoice__c inv1 = CommonDataTest.getInvoice();
        inv1.Bill_Branch__c = branch.Id;
        inv1.Sub_Branch_Master__c =  branch.Id;
        inv1.Collection_Branch__c = branch2.Id;
        inv1.Account__c = objMSa.Id;
        inv1.Billing_Level__c = 'MSA' ;
        inv1.MSA__c = objMSa.MSA__c;
        inv1.BDM_Email_IDs__c = 'test@gmail.com';
        inv1.Bill_Number__c = '1231';
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
        inv2.BDM_Email_IDs__c = 'test@gmail.com';
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
        inv3.BDM_Email_IDs__c = 'test@gmail.com';
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
        inv4.BDM_Email_IDs__c = 'test@gmail.com';
        inv4.Bill_Number__c = '1234';
        //insert inv4;
        lstInv.add(inv4);
        insert lstInv;
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
        /*PropelI_BDM_Mapping__c pbm4 = new PropelI_BDM_Mapping__c();
        pbm4.PropelI_BDM__c = bdm3.Id;
        pbm4.Account__c = objSfx2.Id;
        pbm4.Submission_Branch__c = branch.Id;
        pbm4.Collection_Branch__c =branch2.Id;
        pbm4.Billing_Branch__c = branch.Id;
        pbm4.PropelI_Branch_Id__c = '3298';
        pbm4.Collection__c = False;
        pbm4.Submission__c = True;
        pbm4.PropelI_Composite_Key__c = pbm3.PropelI_BDM__c + '::'+pbm3.PropelI_Branch_Id__c+':'+pbm3.Account__r.SFX__c+':'+pbm3.Account__r.MSA__c;
        
        lstPBM.add(pbm4);
        PropelI_BDM_Mapping__c pbm5 = new PropelI_BDM_Mapping__c();
        pbm5.PropelI_BDM__c = bdm3.Id;
        pbm5.Account__c = objSfx2.Id;
        pbm5.Submission_Branch__c = branch.Id;
        pbm5.Collection_Branch__c =branch2.Id;
        pbm5.Billing_Branch__c = branch.Id;
        pbm5.PropelI_Branch_Id__c = '3298';
        pbm5.Collection__c = False;
        pbm5.Submission__c = True;
        pbm5.PropelI_Composite_Key__c = pbm3.PropelI_BDM__c + '::'+pbm3.PropelI_Branch_Id__c+':'+pbm3.Account__r.SFX__c+':'+pbm3.Account__r.MSA__c;
        
        lstPBM.add(pbm5);
        PropelI_BDM_Mapping__c pbm6 = new PropelI_BDM_Mapping__c();
        pbm6.PropelI_BDM__c = bdm3.Id;
        pbm6.Account__c = objSfx2.Id;
        pbm6.Submission_Branch__c = branch.Id;
        pbm6.Collection_Branch__c =branch2.Id;
        pbm6.Billing_Branch__c = branch.Id;
        pbm6.PropelI_Branch_Id__c = '3298';
        pbm6.Collection__c = False;
        pbm6.Submission__c = True;
        pbm6.PropelI_Composite_Key__c = pbm3.PropelI_BDM__c + '::'+pbm3.PropelI_Branch_Id__c+':'+pbm3.Account__r.SFX__c+':'+pbm3.Account__r.MSA__c;
        
        lstPBM.add(pbm6);*/
        
        insert lstPBM;
        
        
    }
    @isTest static void insertBDM(){
        Map<Id, invoice__c> mapInvo = new Map<Id, Invoice__c>( [SELECT 
                                                                Id, Bill_Branch__c,Billing_Level__c,MSA__c, Collection_Branch__c,Sub_Branch_Master__c, Account__c, Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,SFX_Code__c
                                                                FROM Invoice__c ]);
        
        List<invoice__Share> lstInvShare = [SELECT id , parentId , userOrGroupId from invoice__share where parentId IN:mapInvo.KeySet()];
        Map<id , Set<id>> invParentIdToUserIdMap = new Map<id , Set<id>>();
        
        for(invoice__share invShr :lstInvShare){
            if(!invParentIdToUserIdMap.containsKey(invShr.parentId)){
                invParentIdToUserIdMap.put(invShr.parentId , new Set<Id>());
            }
            invParentIdToUserIdMap.get(invShr.parentId).add(invShr.userOrGroupId);
            
        }
        
        for (invoice__c inv : mapInvo.values()){
            if(inv.SFX_Code__c == 'SFX0000001'){
                Assert.areEqual('Akshay',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.areEqual('Akshay',inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c));
                
            }
            else if(inv.SFX_Code__c =='SFX0000002' && inv.billing_level__c == 'SFX'){
                Assert.areEqual('Alok',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.areEqual('Rahul',inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c));
                
            }
            
            else if(inv.SFX_Code__c =='SFX0000003'){
                Assert.areEqual('Akshay',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isNull(inv.Collection_PropelI_BDM_Mapping__c);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
            }
            
            else if(inv.Billing_Level__c == 'MSA' && inv.MSA__c =='MSA00000001'){
                
                Assert.areEqual('Alok',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.areEqual('Rahul',inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c));
                
            }
            
        }
    }
    @isTest static void updateBDM(){
        Map<Id,PropelI_BDM_Mapping__c> pbmMap = new Map<Id,PropelI_BDM_Mapping__c>([SELECT 
                                                                                    Id, Submission_Branch__c, Collection_Branch__c, Collection__c, Submission__c
                                                                                    FROM PropelI_BDM_Mapping__c ]);
        Map<Id,Invoice__c> mapInvo = new Map<Id,Invoice__c>([SELECT
                                                             Id, Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__c,SFX_Code__c
                                                             FROM Invoice__c]);
        List<invoice__Share> lstInvShare = [SELECT id , parentId , userOrGroupId from invoice__share where parentId IN:mapInvo.KeySet()];
        Map<id , Set<id>> invParentIdToUserIdMap = new Map<id , Set<id>>();
        
        for(invoice__share invShr :lstInvShare){
            if(!invParentIdToUserIdMap.containsKey(invShr.parentId)){
                invParentIdToUserIdMap.put(invShr.parentId , new Set<Id>());
            }
            invParentIdToUserIdMap.get(invShr.parentId).add(invShr.userOrGroupId);
            
        }
        for(PropelI_BDM_Mapping__c pbm :pbmMap.values()){
            if(pbm.Collection__c && pbm.Submission__c){
                 User bdm3 = CommonDataTest.getUserBdm();
        bdm3.firstname ='Rahul';
                pbm.Collection__c = False;
                pbm.PropelI_BDM__c=bdm3.id;
            }
            
        }
        
        try{
            update pbmMap.values();
        }
        catch(Exception e){
            System.debug('BDMMappingTriggerHandlerTest.updateBDM is failing with '+e.getMessage());
            ExceptionHandling.Exception('updateBDM' , 'BDMMappingTriggerHandlerTest', e );
        }
        
        for (invoice__c inv : mapInvo.values()){
            if(inv.SFX_Code__c == 'SFX0000001'){
                Assert.areEqual('Akshay',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isNull(inv.Collection_PropelI_BDM_Mapping__c);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                
                
            }
            
        }
        
        
    }
    @isTest static void deleteBDM(){
        List<PropelI_BDM_Mapping__c> pbmList = [SELECT Id, Submission_Branch__c, Collection_Branch__c, Collection__c, Submission__c
                                                FROM PropelI_BDM_Mapping__c ];
        Map<Id,Invoice__c> mapInvo = new Map<Id,Invoice__c>([SELECT
                                                             Id, Billing_Level__c,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__c,SFX_Code__c,MSA__c
                                                             FROM Invoice__c]);
        
        List<invoice__Share> lstInvShare = [SELECT id , parentId , userOrGroupId from invoice__share where parentId IN:mapInvo.KeySet()];
        
        Map<id , Set<id>> invParentIdToUserIdMap = new Map<id , Set<id>>();
        
        for(invoice__share invShr :lstInvShare){
            if(!invParentIdToUserIdMap.containsKey(invShr.parentId)){
                invParentIdToUserIdMap.put(invShr.parentId , new Set<Id>());
            }
            invParentIdToUserIdMap.get(invShr.parentId).add(invShr.userOrGroupId);
            
        }
        try{
            for( PropelI_BDM_Mapping__c pbm : pbmList){
                if(pbm.Submission__c && pbm.Collection__c){
                    delete pbm;
                }
                
                
            }
            
            
        }
        catch(Exception e){
            System.debug('BDMMappingTriggerHandlerTest.deleteBDM is failing with '+e.getMessage());
            ExceptionHandling.Exception('deleteBDM' , 'BDMMappingTriggerHandlerTest', e );
            
        }
        
        for (invoice__c inv : mapInvo.values()){
            if(inv.SFX_Code__c == 'SFX0000001'){
                Assert.isNull(inv.Submission_propelI_BDM_Mapping__c);
                Assert.isNull(inv.Collection_PropelI_BDM_Mapping__c);
                Assert.isNull(invParentIdToUserIdMap.get(inv.id).size());
                Assert.isNull(invParentIdToUserIdMap.get(inv.id).size());
                
            }
        }
        
    }
    
    /*@isTest static void BDMInvoiceTest(){
Opportunity__c objOpp = CommonDataTest.getOpportunity();
insert objOpp;

Account objPro = CommonDataTest.getMSAAccount();
insert objPro;

Account accnt = CommonDataTest.getSfxAccount();
accnt.parentID = objPro.Id;
accnt.Opportunity__c = objOpp.id;
insert accnt;

Branch_Master__c branch = CommonDataTest.getBranchMaster();
insert branch;
Branch_Master__c branch2 = CommonDataTest.getBranchMaster();
branch2.Region__c = 'MUMBAI';
insert branch2;
Invoice__c inv = CommonDataTest.getInvoice();
inv.Account__c=accnt.id;
inv.Billing_Level__c ='SFX';
inv.Sub_Branch_Master__c=branch.Id;
inv.Collection_Branch__c =branch.id;
inv.Bill_Branch__c = branch.id;
insert inv;
Invoice__c inv2 = CommonDataTest.getInvoice();
inv2.Account__c=accnt.id;
inv2.Billing_Level__c ='SFX';
inv2.Sub_Branch_Master__c=branch.Id;
inv2.Collection_Branch__c =branch2.id;
inv2.Bill_Branch__c = branch.id;
insert inv2;
Invoice__c inv3 = CommonDataTest.getInvoice();
inv3.Account__c=accnt.id;
inv3.Billing_Level__c ='SFX';
inv3.Sub_Branch_Master__c=branch.Id;
inv3.Collection_Branch__c =branch.id;
inv3.Bill_Branch__c = branch2.id;
insert inv3;
User bdm = CommonDataTest.getUserBdm();
insert bdm;
PropelI_BDM_Mapping__c pbdm = new PropelI_BDM_Mapping__c();
pbdm.Account__c=accnt.id;
pbdm.Submission_Branch__c = branch.id;
pbdm.Collection_Branch__c = branch.id;
pbdm.Billing_Branch__c = branch2.id;
pbdm.PropelI_BDM__c =bdm.id;
pbdm.Collection__c =True;
pbdm.PropelI_Composite_Key__c='005C5000000IgmsIAC::RC25549-DELHI NORTH-356:@69635:SFX00011898:QRMQRM';
insert pbdm;

PropelI_BDM_Mapping__c pbdm1 = new PropelI_BDM_Mapping__c();
pbdm1.Account__c=accnt.id;
pbdm1.Submission_Branch__c = branch.id;
pbdm1.Collection_Branch__c = branch.id;
pbdm.Billing_Branch__c = branch.id;
pbdm1.PropelI_BDM__c =bdm.id;
pbdm1.Submission__c = True;
pbdm1.PropelI_Composite_Key__c ='005D5000000IgmsIAC::RC25549-DELHI NORTH-356:@69635:SFX00011898:QRMQRM';
insert pbdm1;
pbdm1.Collection_Branch__c = branch2.id;
update pbdm1;
delete pbdm;

}*/
    
}