/**
* Description		:		Test class for invoiceTriggerHelper apex class
* Author            :       Himanshi Dang
* Coverage			:		94%
**/
@isTest 
private class invoiceTriggerHelperTest{
     private static Id userId;
    
    @testSetup static void  invSetup(){
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
       // objSfx2.MSA__c = 'MSA00000001';
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
        pbm3.Submission__c = True;
        pbm3.PropelI_Composite_Key__c = pbm3.PropelI_BDM__c + '::'+pbm3.PropelI_Branch_Id__c+':'+pbm3.Account__r.SFX__c+':'+pbm3.Account__r.MSA__c;
        //insert pbm3;
        lstPBM.add(pbm3);
        
      	PropelI_BDM_Mapping__c pbm4 = new PropelI_BDM_Mapping__c();
        pbm4.PropelI_BDM__c = bdm3.Id;
        pbm4.Account__c = objSfx2.Id;
       // pbm4.Submission_Branch__c = branch.Id;
       // pbm4.Collection_Branch__c =branch2.Id;
       // pbm4.Billing_Branch__c = branch.Id;
       // pbm4.PropelI_Branch_Id__c = '3298';
        pbm4.Local_NAM__c = True;
        pbm4.PropelI_Composite_Key__c = pbm4.PropelI_BDM__c + '::'+pbm4.PropelI_Branch_Id__c+':'+pbm4.Account__r.SFX__c+':'+pbm4.Account__r.MSA__c+':'+'0';
        lstPBM.add(pbm4);
        
        PropelI_BDM_Mapping__c pbm5 = new PropelI_BDM_Mapping__c();
        pbm5.PropelI_BDM__c = bdm3.Id;
        pbm5.Account__c = objSfx2.Id;
        pbm5.QRM__c = True;
        pbm5.PropelI_Composite_Key__c = pbm5.PropelI_BDM__c + '::'+pbm5.PropelI_Branch_Id__c+':'+pbm5.Account__r.SFX__c+':'+pbm5.Account__r.MSA__c+':'+'1';
        lstPBM.add(pbm5);
        
        PropelI_BDM_Mapping__c pbm6 = new PropelI_BDM_Mapping__c();
        pbm6.PropelI_BDM__c = bdm3.Id;
        pbm6.Account__c = objSfx2.Id;
        pbm6.CRS__c = True;
        pbm6.PropelI_Composite_Key__c = pbm6.PropelI_BDM__c + '::'+pbm6.PropelI_Branch_Id__c+':'+pbm6.Account__r.SFX__c+':'+pbm6.Account__r.MSA__c+':'+'2';
        lstPBM.add(pbm6);
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
        inv1.Remarks__c = 'test';
        inv1.Status_LID__c = 292;
        inv1.BDM_Email_IDs__c = 'test@test.com';
        //insert inv1;
        lstInv.add(inv1);
        
        //SFX1
        invoice__c inv2 = CommonDataTest.getInvoice();
        inv2.Bill_Branch__c = branch.Id;
        inv2.Sub_Branch_Master__c =  branch.Id;
        inv2.Collection_Branch__c = branch.Id;
        inv2.CRS_Propeli_BDM_Mapping__c = pbm6.Id;
        inv2.Account__c = objSfx.Id;
        inv2.Billing_Level__c = 'SFX' ;
        inv2.SFX_Code__c = objSfx.SFX__c ;
        inv2.Bill_Number__c = '1232';
        inv2.Out_Total_Amount__c=0;
		inv2.Remarks__c = 'test';
        inv2.Status_LID__c = 292;
        inv2.BDM_Email_IDs__c = 'test@test.com';
        //insert inv2;
        lstInv.add(inv2);
        
        //SFX2
        invoice__c inv3 = CommonDataTest.getInvoice();
        inv3.Bill_Branch__c = branch.Id;
        inv3.Sub_Branch_Master__c =  branch.Id;
        inv3.Collection_Branch__c = branch2.Id;
        inv3.QRM_Propeli_BDM_Mapping__c = pbm5.Id;
        inv3.Collection_PropelI_BDM_Mapping__c = pbm5.Id;
        inv3.Account__c = objSfx2.Id;
        inv3.Billing_Level__c = 'SFX' ;
        inv3.SFX_Code__c = objSfx2.SFX__c ;
        inv3.Bill_Number__c = '1233';
        inv3.Out_Total_Amount__c=12;
        inv3.Remarks__c = 'test';
        inv3.Status_LID__c = 292;
        inv3.BDM_Email_IDs__c = 'test@test.com';
        
        //insert inv3;
        lstInv.add(inv3);
        
        //SFX3
        invoice__c inv4 = CommonDataTest.getInvoice();
        inv4.Bill_Branch__c = branch.Id;
        inv4.Sub_Branch_Master__c =  branch.Id;
        inv4.Collection_Branch__c = branch.Id;
        inv4.NAM_Propeli_BDM_Mapping__c = pbm4.Id;
        inv4.Account__c = objSfx3.Id;
        inv4.Billing_Level__c = 'SFX' ;
        inv4.SFX_Code__c = objSfx3.SFX__c ;
        inv4.Bill_Number__c = '1234';
        inv4.e_Bill__c = 'YES';
        inv4.Remarks__c = 'test';
        inv4.Status_LID__c = 292;
        inv4.BDM_Email_IDs__c = 'test@test.com';
        inv4.Out_Total_Amount__c=0.0;
        //insert inv4;
        lstInv.add(inv4);
        insert lstInv;
        
        List<Invoice__c> invoices = new List<Invoice__c>();
        for(Integer i=0; i<2; i++) {
            invoices.add(new Invoice__c(
                Name = 'Test Invoice ' + i,
                Status_LID__c = 292,
                Out_Total_Amount__c = i == 0 ? 100 : 0,
                Charged_Freight_Amount__c = 1000.00,
                Charged_ST_Amount__c = 180.00,
                Charged_Total_Amount__c = 1180.00,
                Remarks__c = 'test',
                BDM_Email_IDs__c = 'test@test.com'
            ));
        }
        insert invoices;
        
        // Create payments related to invoices
        List<Payment__c> payments = new List<Payment__c>();
        for(Invoice__c inv : [SELECT Id FROM Invoice__c]) {
            payments.add(new Payment__c(
                Invoice__c = inv.Id,
               	Received_Freight_Amount__c=737934.69,
                Received_Freight_TDS_Amount__c = 13048,
                Bill_ID__c=1221212,
                Bill_Number__c='2121212',
                Created_Date__c = System.now().date(),
                Received_OCT_Amount__c=0,
                Cheque_Dishonor_Remarks__c = 'Cheque bounced'
            ));
        }
        insert payments;
        Id colTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
         List<Task> tasks = new List<Task>();
        for (Invoice__c inv : invoices) {
            tasks.add(new Task(
                RecordTypeId=colTaskRecordId,
                WhatId = inv.Id,
                Subject = 'Test Task for Invoice',
                Status = 'Open',
                Priority = 'Normal',
                Remarks__c = 'test',
                Outstanding_Amount__c = inv.Out_Total_Amount__c,
                File_Uploaded_By_BDM__c = false
            ));
        }
        insert tasks;
    }
    private static Account createAccountHierarchy() {
        Account parentAccount = new Account(Name = 'Parent Account');
        insert parentAccount;
        Id sfxRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Account childAccount = new Account(Name = 'Child Account', RecordTypeId=sfxRecId,ParentId = parentAccount.Id);
        insert childAccount;

        return childAccount;
    }
	
    // Utility method to create Collection_PropelI_BDM_Mapping__c record
    private static PropelI_BDM_Mapping__c createCollectionMapping() {
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestBDmtest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Sportfire_Group__c='Group 1',
            Journey_Type__c='Bike',
            TimeZoneSidKey = 'Asia/Kolkata',
            Type__c = 'Retail',
            Region__c= 'RAJASTHAN',
            ProfileId = [SELECT Id FROM Profile WHERE Name='BDM' LIMIT 1].Id,
            IsActive= True,
            Username = 'testuser87216829817981798721' + '@example.com'
        );
        insert testUser;
        
         PropelI_BDM_Mapping__c mappings = new PropelI_BDM_Mapping__c(
            PropelI_BDM__c = testUser.Id,
            PropelI_Composite_Key__c = 'TestKey123'
        );
        insert mappings;
        
        PropelI_BDM_Mapping__c mapping = [Select Id ,PropelI_BDM__c,PropelI_Composite_Key__c from PropelI_BDM_Mapping__c  Limit 1];
       
        return mapping;
    }
    
     @IsTest
   static void testCreateCollectionTask() {
        List<User> bdmUser = [SELECT Id FROM User WHERE Profile.Name = 'BDM' AND IsActive = TRUE LIMIT 50];
        Set<Id> UserId = new Set<Id>();
        for(User us:bdmUser){
            UserId.add(us.Id);
        }
        List<Branch_Master__c> lstBM = new List<Branch_Master__c>();
        Account acc = createAccountHierarchy();
        PropelI_BDM_Mapping__c mapping = createCollectionMapping();
		Branch_Master__c branch = CommonDataTest.getBranchMaster();
        
        lstBM.add(branch);
        
        Branch_Master__c branch2 = CommonDataTest.getBranchMaster();
        branch2.Region__c = 'MUMBAI';
        
        lstBM.add(branch2);
        
        Branch_Master__c branch3 = CommonDataTest.getBranchMaster();
        branch3.Region__c = 'DELHI-11';
        //insert branch3;
        lstBM.add(branch3);
        insert lstBM;
        Invoice__c inv = new Invoice__c(    
       Bill_Branch__c = branch.Id,
        Sub_Branch_Master__c =  branch.Id,
        Collection_Branch__c = branch2.Id,
       Charged_Freight_Amount__c=100,
            Charged_ST_Amount__c=100, 
            Bill_Number__c = 'BN12345',
            Account__c = acc.Id,
            Collection_PropelI_BDM_Mapping__c = mapping.Id,
            SFX_Code__c = 'SFX001',
            Charged_Total_Amount__c = 1500,
            Billing_Level__c = 'Level 1',
            e_Bill__c = 'Yes',
            Out_Total_Amount__c = 500,
            Remarks__c = 'Test Remarks',
            BDM_Email_IDs__c = 'bdm@example.com'  
        );
        insert inv;

        // Query with relationships to pass to the method
        inv = [SELECT Id,MSA_Name__c, Bill_Number__c, Account__r.Parent.Name, 
               Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c, SFX_Code__c, Total_Outstanding_Amount__c, 
               Bill_Branch__c, Charged_Total_Amount__c, Billing_Level__c, e_Bill__c, Out_Total_Amount__c, 
               Green_Book__c, Remarks__c, BDM_Email_IDs__c, CreatedDate, Bill_Date__c
               FROM Invoice__c WHERE Id = :inv.Id];
		
        Test.startTest();
       Task tsk = InvoiceTriggerHelper.createCollectionTask(inv);
        //insert tsk;
        Test.stopTest();

       
    }

    @IsTest
    Static void testinvshare(){
        Invoice__c inv=[Select id from Invoice__c Limit 1];
        User bdmUser = [SELECT Id FROM User WHERE Profile.Name = 'BDM' AND IsActive = TRUE LIMIT 1];
        Map<Id,Id> invmap = new Map<Id,Id>();
        invmap.put(inv.Id,bdmUser.Id);
        Test.startTest();
		invoiceTriggerHelper.invShareRec(inv.Id,invmap);     
        Test.stopTest();
    }
     @IsTest
    Static void testinvshare1(){
        Invoice__c inv=[Select id from Invoice__c Limit 1];
        User bdmUser = [SELECT Id FROM User WHERE Profile.Name = 'BDM' AND IsActive = TRUE LIMIT 1];
        Map<Id,Id> invmap = new Map<Id,Id>();
        invmap.put(inv.Id,bdmUser.Id);
        Test.startTest();
		invoiceTriggerHelper.invShareRec(inv.Id,bdmUser.Id);     
        Test.stopTest();
    }

    @IsTest
    Static void invToUseridTest(){
        Invoice__c inv=[Select id,Submission_propelI_BDM_Mapping__c, Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__c, Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,
        NAM_Propeli_BDM_Mapping__c, NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,QRM_Propeli_BDM_Mapping__c, QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,CRS_Propeli_BDM_Mapping__c, CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c from Invoice__c where Submission_propelI_BDM_Mapping__c!=null AND  Collection_PropelI_BDM_Mapping__c !=null  AND NAM_Propeli_BDM_Mapping__c!=null  Limit 1];
        List<invoice__c> invList = new List<invoice__c>();
        invList.add(inv);
        Test.startTest();
		invoiceTriggerHelper.invToUserid('Sub', invList);     
		invoiceTriggerHelper.invToUserid('Col', invList);     
		invoiceTriggerHelper.invToUserid('NAM', invList);     
		invoiceTriggerHelper.invToUserid('QRM', invList);     
		invoiceTriggerHelper.invToUserid('CRS', invList);     
        Test.stopTest();
    }


    @IsTest
    static void testUpdateInvoiceOut() {
        // Get the invoices created in test setup
        List<Invoice__c> invoices = [SELECT Id, Out_Total_Amount__c FROM Invoice__c where Status_LID__c=292 and Out_Total_Amount__c=0 LIMIT 2];
        List<Id> invoiceIds = new List<Id>();
        for(Invoice__c inv : invoices) {
            invoiceIds.add(inv.Id);
        }
        
        // Old invoice map simulating trigger old map
        Map<Id, Invoice__c> oldMap = new Map<Id, Invoice__c>();
        for(Invoice__c inv : invoices) {
            // For old map, simulate change in outstanding amount for 1 invoice
            Invoice__c oldInv = inv.clone(false);
            oldInv.Out_Total_Amount__c = inv.Out_Total_Amount__c == 0 ? 100 : 0;
            oldInv.Status_LID__c = 292;
            oldMap.put(inv.Id, oldInv);
        }
        
        Test.startTest();
        // Call the method
        InvoiceTriggerHelper.updateInvoiceOut(invoices, invoiceIds, oldMap);
        Test.stopTest();        
        
    }
   
    static testMethod void afterInsertTest(){
        Map<Id, invoice__c> mapInvo = new Map<Id, Invoice__c>( [SELECT 
                                                                Id, Bill_Branch__c,Billing_Level__c,MSA__c, Collection_Branch__c,Sub_Branch_Master__c, Account__c, 
                                                                Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,
                                                                NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,QRM_Propeli_BDM_Mapping__r.PropelI_BDM__c,
                                                                SFX_Code__c ,CRS_Propeli_BDM_Mapping__r.PropelI_BDM__c
                                                                FROM Invoice__c  where Submission_propelI_BDM_Mapping__c !=null]);
        
        List<Task> lstTask = [SELECT id ,OwnerId, whatId from task where WhatId IN: mapInvo.KeySet() ];
        List<invoice__Share> lstInvShare = [SELECT id , parentId , userOrGroupId from invoice__share where parentId IN:mapInvo.KeySet()];
        Map<id , id > taskOwnerMap = new Map<id , id >();
        Map<id , Set<id>> invParentIdToUserIdMap = new Map<id , Set<id>>();
        invoice__c invoice;
        for(invoice__share invShr :lstInvShare){
            if(!invParentIdToUserIdMap.containsKey(invShr.parentId)){
                invParentIdToUserIdMap.put(invShr.parentId , new Set<Id>());
            }
            invParentIdToUserIdMap.get(invShr.parentId).add(invShr.userOrGroupId);
           
        }
        
        for(Task tsk : lstTask){
            taskOwnerMap.put(tsk.Whatid , tsk.OwnerId); 
            
        }
       List<invoice__c> invlst = [Select Id,Bill_Number__c,Out_Total_Amount__c,Account__r.Name,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Green_Book__c,CreatedDate from invoice__c where Submission_propelI_BDM_Mapping__c!=null  LIMIT 1];
        for (invoice__c inv : mapInvo.values()){
            invoice = inv;
            if(inv.SFX_Code__c == 'SFX0000001'){
                Assert.areEqual('Akshay',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.areEqual('Akshay',inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.areEqual(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,taskOwnerMap.get(inv.id));
                
                
            }
            else if(inv.SFX_Code__c =='SFX0000002' && inv.billing_level__c == 'SFX'){
                Assert.areEqual('Alok',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.areEqual('Rahul',inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.areEqual(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,taskOwnerMap.get(inv.id));
                
            }
            
            else if(inv.SFX_Code__c =='SFX0000003'){
                Assert.areEqual('Akshay',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isNull(inv.Collection_PropelI_BDM_Mapping__c);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.areEqual(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,taskOwnerMap.get(inv.id));
                
            }
            
            else if(inv.Billing_Level__c == 'MSA' && inv.MSA__c =='MSA00000001'){
                
                Assert.areEqual('Alok',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.areEqual('Rahul',inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.areEqual(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,taskOwnerMap.get(inv.id));
                
                
            }
            
        }
        InvoiceTriggerHelper.createInvShareRec(new Set<Id>{invoice.Id},'');
    }

    static testMethod void afterUpdateTest1(){
        
        Map<Id, invoice__c> mapInvo = new Map<Id, Invoice__c>( [SELECT 
                                                                Id,MSA_Name__c, Bill_Branch__c, Collection_Branch__c,Sub_Branch_Master__c, Account__c,Bill_Number__c, Total_Outstanding_Amount__c,
                                                                Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,SFX_Code__c,
                                                                Customer_Contract_Code__c, Bill_Date__c, Billing_Level__c, MSA__c, BDM_Email_IDs__c,Remarks__c, e_Bill__c
                                                                , NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,Out_Total_Amount__c, Green_Book__c
                                                                ,CreatedDate
                                                                FROM Invoice__c ]);

        Debit_Credit_Note__c dcn = new Debit_Credit_Note__c();
        dcn.Invoice_Name__c =  mapInvo.values()[0].Id;
        dcn.Bill_Number__c = 'DCN-TEST-001';
        dcn.Created_Date__c = System.today();
        insert dcn;

        Task task = CommonDataTest.getSubmisionTask();
        task.WhatId = dcn.Id;
        insert task;

        Test.startTest();
        try {
            invoiceTriggerHelper.updateDebitTask(mapInvo.keySet());
        } catch (Exception ex) {
            
        }
        Test.stopTest();
        

    }
    
    
    static testMethod void afterUpdateTest(){
        
        Map<Id, invoice__c> mapInvo = new Map<Id, Invoice__c>( [SELECT 
                                                                Id, MSA_Name__c,Bill_Branch__c, Collection_Branch__c,Sub_Branch_Master__c, Account__c,Bill_Number__c, Total_Outstanding_Amount__c,
                                                                Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,SFX_Code__c,
                                                                Customer_Contract_Code__c, Bill_Date__c, Billing_Level__c, MSA__c, BDM_Email_IDs__c,Remarks__c, e_Bill__c
                                                                , NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,Out_Total_Amount__c, Green_Book__c
                                                                ,CreatedDate
                                                                FROM Invoice__c ]);
        List<Task> taskNewList= new List<Task>();
       // Id subTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
          Contact con = CommonDataTest.getContact();
          insert con;
        for(invoice__c invoice : mapInvo.values()){
            Task task = new Task();
            task.Status = 'Completed';
            task.Ebill_Submission__c = true;
            task.WhatId = mapInvo.get(invoice.Id).Id;
            task.WhoId = con.Id; 
            taskNewList.add(task);
        }
        
        insert taskNewList;
        invoiceTriggerHelper.createSubmissionTask(mapInvo);

        Map<id , Branch_Master__c> branchMasterMap = new Map<id , Branch_Master__c>([Select id , Region__c from Branch_Master__c]);
        system.debug('invoice-->'+Json.serialize(mapInvo));
        
        for(invoice__c inv : mapInvo.values()){
            for(Branch_Master__c bm :branchMasterMap.values()){
                 //inv.Collection_Branch__c = bm.id;
                if( bm.Region__c == 'MUMBAI'){
                     Account objSfx = CommonDataTest.getSfxAccount();
                    inv.Collection_Branch__c = bm.id;
                    inv.Out_Oct_Amount__c =2;
                    inv.Out_Total_Amount__c=8;
                    inv.Account__c=objSfx.id;
                    system.debug('invoice22-->'+Json.serialize(inv));
                    
                }
                //if(inv.SFX_Code__c=='SFX0000002' && bm.Region__c == 'DELHI-11'){
                    inv.Collection_Branch__c = bm.id;
            } 
            
        }
        update mapInvo.values();
        
        List<Task> lstTask = [SELECT id ,OwnerId, RecordTypeId,whatId,Status from task where WhatId IN: mapInvo.KeySet() ];
        if(lstTask.size()> 0){
            for(invoice__c inv : mapInvo.values()){
               // invoiceTriggerHelper.createCollectionTask(lstTask, inv);
            }
        }
        List<invoice__c> invlst = [Select Id,MSA_Name__c,Bill_Number__c,Out_Total_Amount__c,Account__r.Name,Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Green_Book__c,CreatedDate from invoice__c LIMIT 1];
        if(!invlst.isEmpty()){
            for(invoice__c inv : invlst){
                invoiceTriggerHelper.createTask(inv);
            } 
        }
        List<invoice__Share> lstInvShare = [SELECT id , parentId , userOrGroupId from invoice__share where parentId IN:mapInvo.KeySet()];
        Map<id , id > taskOwnerMap = new Map<id , id >();
        Map<id , Set<id>> invParentIdToUserIdMap = new Map<id , Set<id>>();
        for(invoice__share invShr :lstInvShare){
            if(!invParentIdToUserIdMap.containsKey(invShr.parentId)){
                invParentIdToUserIdMap.put(invShr.parentId , new Set<Id>());
            }
            invParentIdToUserIdMap.get(invShr.parentId).add(invShr.userOrGroupId);
            
        }
        
        for(Task tsk : lstTask){
            tsk.Payment_Remaining__c = 'Partly Recoverable / Non Recoverable';
            taskOwnerMap.put(tsk.Whatid , tsk.OwnerId); 
            

        
        for (invoice__c inv : mapInvo.values()){
            if(inv.SFX_Code__c == 'SFX0000001'){
                Assert.areEqual('Alok',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.areEqual('Rahul',inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.areEqual(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,taskOwnerMap.get(inv.id));
                
                
            }
            else if(inv.SFX_Code__c =='SFX0000002' && inv.billing_level__c == 'SFX'){
                Assert.areEqual('Akshay',inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__r.firstname);
                Assert.isNull(inv.Collection_PropelI_BDM_Mapping__c);
                Assert.isTrue(invParentIdToUserIdMap.get(inv.id).contains(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c));
                Assert.areEqual(inv.Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,taskOwnerMap.get(inv.id));
                
            }
        }
        
        
    }
  }   
    
  
    static testMethod void autoclose(){
       
        Map<Id, invoice__c> mapInvo = new Map<Id, Invoice__c>( [SELECT 
                                                                Id, Bill_Branch__c, Collection_Branch__c,Sub_Branch_Master__c, Account__c,Bill_Number__c, Total_Outstanding_Amount__c,
                                                                Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,SFX_Code__c,
                                                                Customer_Contract_Code__c, Bill_Date__c, Billing_Level__c, MSA__c, BDM_Email_IDs__c,Remarks__c, e_Bill__c
                                                                , NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,Out_Total_Amount__c, Green_Book__c
                                                                ,CreatedDate
                                                                FROM Invoice__c where Submission_propelI_BDM_Mapping__c !=null  limit 1]);
         Id colTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        list<task> tasks = new list<task>(); 
         for (Id inv : mapInvo.keyset()) {
             Invoice__c invoices = mapInvo.get(inv);
            tasks.add(new Task(
                RecordTypeId=colTaskRecordId,
                WhatId = inv,
                Subject = 'Test Task for Invoice',
                Status = 'Open',
                Priority = 'Normal',
                Remarks__c = 'test',
                Outstanding_Amount__c = invoices.Out_Total_Amount__c,
                File_Uploaded_By_BDM__c = false
            ));
        }
        insert tasks;
       
         Test.startTest();
        try {
            invoiceTriggerHelper.autoClosedInvoice(mapInvo);
        } catch (Exception ex) {
            
        }
        Test.stopTest();
        
    }
     static testMethod void autoclose1(){
       
        Map<Id, invoice__c> mapInvo = new Map<Id, Invoice__c>( [SELECT 
                                                                Id, Bill_Branch__c, Collection_Branch__c,Sub_Branch_Master__c, Account__c,Bill_Number__c, Total_Outstanding_Amount__c,
                                                                Submission_propelI_BDM_Mapping__r.PropelI_BDM__c,Collection_PropelI_BDM_Mapping__r.PropelI_BDM__c,SFX_Code__c,
                                                                Customer_Contract_Code__c, Bill_Date__c, Billing_Level__c, MSA__c, BDM_Email_IDs__c,Remarks__c, e_Bill__c
                                                                , NAM_Propeli_BDM_Mapping__r.PropelI_BDM__c,Out_Total_Amount__c, Green_Book__c
                                                                ,CreatedDate
                                                                FROM Invoice__c where Collection_PropelI_BDM_Mapping__C !=null   limit 1]);
         Id colTaskRecordId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
         
        list<task> tasks = new list<task>(); 
         List<Invoice__c>  invupdate= new List<Invoice__c>();
         for (Id inv : mapInvo.keyset()) {
            	Invoice__c invoices = mapInvo.get(inv);
             	invoices.Submission_propelI_BDM_Mapping__c = null;
             	invupdate.add(invoices);
             
            	tasks.add(new Task(
                RecordTypeId=colTaskRecordId,
                WhatId = inv,
                Subject = 'Test Task for Invoice',
                Status = 'Open',
                Priority = 'Normal',
                Remarks__c = 'test',
                Outstanding_Amount__c = invoices.Out_Total_Amount__c,
                File_Uploaded_By_BDM__c = false
            ));
        }
         Update invupdate;
        insert tasks;
       
         Test.startTest();
        try {
            invoiceTriggerHelper.autoClosedInvoice(mapInvo);
        } catch (Exception ex) {
            
        }
        Test.stopTest();
        
    }
     
    

  
}