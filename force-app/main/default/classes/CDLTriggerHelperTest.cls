/**
 * Description		:		Test class for ContentDocumentLink trigger
 * Created By       :       
 * Created Date     :       
 * Release          :       July,2020
 * Last Modified on :       Monika Rawat
 * Last Modified Date:      09/07/2020
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-497,https://safexpress.atlassian.net/browse/SD-629
 * Coverage			:		76%
 **/
@isTest 
public class CDLTriggerHelperTest{
    static testMethod void testMethod1() {
        UserRole obj=new UserRole(Name= 'Central Quotation Team Credit'); 
        insert obj;
        
        Profile p = [Select id from profile where name = 'System Administrator' limit 1];
        User us = CommonDataTest.getUserBdm();
        us.UserRoleId = obj.Id;
        us.profileId = p.id;
        insert us;
        
        System.runAs(us){
            Opportunity__c objOpp = CommonDataTest.getOpportunity();
            insert objOpp;
            
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

            Account objSfx = CommonDataTest.getSfxAccount();
            objSfx.parentID = objPro.Id;
            objSfx.Opportunity__c = objOpp.Id;
            insert objSfx;
            
            Invoice__c objInv = CommonDataTest.getInvoice();
            objInv.Account__c = objSfx.Id;
            objInv.Composite_Key__c = objSfx.id;
            insert objInv;
            
            Account_Team__c accteam = CommonDataTest.getAccountTeam();
            accteam.National4__c = true;
            accteam.Collection__c = true;
            accteam.Account__c = objSfx.Id;
            accteam.BDM__c=us.Id;
            insert accteam;
                            
            Task objTask = CommonDataTest.getSubmisionTask();
            objTask.WhatId = objInv.id;
            insert objTask;
            
            Quote__c objQuo = CommonDataTest.getQuote();
            objQuo.Opportunity__c = objOpp.Id;
            objQuo.Status__c = 'Active';
            objQuo.Approval_Status__c = 'Approved By CCD'; 
            insert objQuo;
            Test.startTest();
            ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
            insert contentVersion_1;
            
            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
            contentlink.LinkedEntityId=objQuo.id;
            contentlink.LinkedEntityId = objQuo.Id; 
            contentlink.ContentDocumentId=testcontent.ContentDocumentId;
            insert contentlink;
            
            
            ContentVersion contentVersion2 = CommonDataTest.getContectVersion();
            insert contentVersion2;
            
            ContentVersion testContent1 = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink2=CommonDataTest.getContentDocumentLink();
            contentlink2.LinkedEntityId=objTask.id;
            contentlink2.LinkedEntityId = objTask.Id; 
            contentlink2.ContentDocumentId=testcontent1.ContentDocumentId;
            insert contentlink2;

             Contact con = CommonDataTest.getContact();
        insert con;
            ContentVersion contentVersion_2 = CommonDataTest.getContectVersion();
        insert contentVersion_2;
       Test.stopTest();
        ContentVersion testContent_1 = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
        
        ContentDocumentLink contentlink_1=CommonDataTest.getContentDocumentLink();
        
        contentlink_1.LinkedEntityId = con.Id; 
        contentlink_1.ContentDocumentId=testcontent.ContentDocumentId;
        insert contentlink_1;
            list<Id> conId = new List<Id>();
            conId.add(con.Id);
                CDLTriggerHelper.ContactFileCopyToLead(conId);
        }
    }
   
    static testMethod void testMethod2() {
        UserRole obj=new UserRole(Name= 'Central Quotation Team Credit'); 
        insert obj;
        
        Profile p = [Select id from profile where name = 'System Administrator' limit 1];
        User us = CommonDataTest.getUserBdm();
        us.UserRoleId = obj.Id;
        us.profileId = p.id;
        insert us;
        
        System.runAs(us){
            Opportunity__c objOpp = CommonDataTest.getOpportunity();
            insert objOpp;
            
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

            Account objSfx = CommonDataTest.getSfxAccount();
            objSfx.parentID = objPro.Id;
            objSfx.Opportunity__c = objOpp.Id;
            insert objSfx;
            
            Invoice__c objInv = CommonDataTest.getInvoice();
            objInv.Account__c = objSfx.Id;
             objInv.Composite_Key__c = objSfx.id;
            insert objInv;
            
            Account_Team__c accteam = CommonDataTest.getAccountTeam();
            accteam.National4__c = true;
            accteam.Collection__c = true;
            accteam.Account__c = objSfx.Id;
            accteam.BDM__c=us.Id;
            insert accteam;
                            
            Task objTask = CommonDataTest.getSubmisionTask();
            objTask.WhatId = objInv.id;
            insert objTask;
            
            Quote__c objQuo = CommonDataTest.getQuote();
            objQuo.Opportunity__c = objOpp.Id;
            objQuo.Status__c = 'Active';
            objQuo.Approval_Status__c = 'Submitted for Approval'; 
            insert objQuo;
            Test.startTest();
            ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
            insert contentVersion_1;
            
            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
            contentlink.LinkedEntityId=objQuo.id;
            contentlink.LinkedEntityId = objQuo.Id; 
            contentlink.ContentDocumentId=testcontent.ContentDocumentId;
            insert contentlink;
            
            ContentVersion contentVersion2 = CommonDataTest.getContectVersion();
            insert contentVersion2;
            
            ContentVersion testContent1 = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink2=CommonDataTest.getContentDocumentLink();
            contentlink2.LinkedEntityId=objTask.id;
            contentlink2.LinkedEntityId = objTask.Id; 
            contentlink2.ContentDocumentId=testcontent1.ContentDocumentId;
            insert contentlink2;
            
             Contact con = CommonDataTest.getContact();
        insert con;
            ContentVersion contentVersion_2 = CommonDataTest.getContectVersion();
        insert contentVersion_2;
        
        ContentVersion testContent_1 = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
        
        ContentDocumentLink contentlink_1=CommonDataTest.getContentDocumentLink();
        
        contentlink_1.LinkedEntityId = con.Id; 
        contentlink_1.ContentDocumentId=testcontent.ContentDocumentId;
        insert contentlink_1;
            list<Id> conId = new List<Id>();
            conId.add(con.Id);
                CDLTriggerHelper.ContactFileCopyToLead(conId);
            delete contentlink_1;
            delete contentlink;
            Test.stopTest();
        }
    }
     static testMethod void testMethod3() {
        UserRole obj=new UserRole(Name= 'Central Quotation Team Credit'); 
        insert obj;
        
        Profile p = [Select id from profile where name = 'System Administrator' limit 1];
        User us = CommonDataTest.getUserBdm();
        us.UserRoleId = obj.Id;
        us.profileId = p.id;
        insert us;
        
        System.runAs(us){
          
            
Opportunity__c objOpp = CommonDataTest.getOpportunity();
            insert objOpp;
            
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

            Account objSfx = CommonDataTest.getSfxAccount();
            objSfx.parentID = objPro.Id;
            objSfx.Opportunity__c = objOpp.Id;
            insert objSfx;
            
           
              Id rIdClaimIssues = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Claim Issues').getRecordTypeId();
              Case__c objCase = CommonDataTest.getCase('Claim Issues');
                objCase.Account__c  = objSfx.Id;
                objCase.Assigned_To__c = us.Id;
                objCase.Remarks__c = 'asdfghjklpoiuytrewqsddfghhjkkkkkk';
                objCase.Status__c='Active';
                ObjCase.Requested_By__c ='Self Initiated';
                objCase.Waybill_Numbers__c = '1234567890';  
                objCase.RecordTypeId = rIdClaimIssues;
                insert objCase;
            Test.startTest();
            ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
            
            insert contentVersion_1;
            
            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
            contentlink.LinkedEntityId=objCase.id;
             
            contentlink.ContentDocumentId=testcontent.ContentDocumentId;
            insert contentlink;
            Test.stopTest();
        }
    }
     static testMethod void testMethod4() {
        UserRole obj=new UserRole(Name= 'Central Quotation Team Credit'); 
        insert obj;
        
        Profile p = [Select id from profile where name = 'System Administrator' limit 1];
        User us = CommonDataTest.getUserBdm();
        us.UserRoleId = obj.Id;
        us.profileId = p.id;
        insert us;
        
        System.runAs(us){
          
            

           
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

           
            
           
             
             
            Test.startTest();
             Id openContract = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
              Contract__c objcontract = New Contract__c();
                objcontract.Account__c  = objPro.Id;
                objcontract.RecordTypeId = openContract;
               
                insert objcontract;
            
            	
            ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
            
            insert contentVersion_1;
            
            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
            
            ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
            contentlink.LinkedEntityId=objcontract.id;

            contentlink.ContentDocumentId=testcontent.ContentDocumentId;
            insert contentlink;

            Test.stopTest();
        }
    }

    // ─── SAC: Contract file-upload gate (Trg_Contentdocumentlinkhelper) ──────

    private static User setupBdmUser() {
        UserRole obj = new UserRole(Name = 'Central Quotation Team Credit');
        insert obj;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User us = CommonDataTest.getUserBdm();
        us.UserRoleId = obj.Id;
        us.profileId = p.Id;
        insert us;
        return us;
    }

    private static Contract__c buildContract(Id accountId, String recordTypeDevName) {
        Schema.DescribeSObjectResult conDescribe = Contract__c.SObjectType.getDescribe();
        Id rtId = conDescribe.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        Contract__c con = new Contract__c();
        con.Account__c = accountId;
        con.RecordTypeId = rtId;
        return con;
    }

    private static ContentDocumentLink buildLink(Id linkedEntityId, Id contentDocumentId) {
        ContentDocumentLink link = CommonDataTest.getContentDocumentLink();
        link.LinkedEntityId = linkedEntityId;
        link.ContentDocumentId = contentDocumentId;
        return link;
    }

    // Second upload to an Open RT contract with no blocking Opportunity must succeed (the original bug)
    static testMethod void testMethod5_OpenRT_SecondFileUpload_NoBlockingOpp_Allowed() {
        User us = setupBdmUser();
        System.runAs(us) {
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

            Contract__c objContract = buildContract(objPro.Id, 'Open');
            insert objContract;

            Test.startTest();
            ContentVersion cv1 = CommonDataTest.getContectVersion();
            insert cv1;
            ContentVersion contentCv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];
            insert buildLink(objContract.Id, contentCv1.ContentDocumentId);

            ContentVersion cv2 = CommonDataTest.getContectVersion();
            cv2.PathOnClient = 'Penguins2.pdf';
            insert cv2;
            ContentVersion contentCv2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
            insert buildLink(objContract.Id, contentCv2.ContentDocumentId); // previously blocked — must now succeed
            Test.stopTest();

            List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :objContract.Id];
            System.assertEquals(2, links.size(), 'Both files should link to an Open RT contract with no blocking Opportunity');
        }
    }

    // Builds a fully-qualified Open RT contract matching the field set proven
    // in OpportunityTriggerHandlerTest.integrationUserOppTest1 to clear every
    // Contract-tagging validation rule on Opportunity__c.
    private static Contract__c buildTaggableContract(Id accountId, Id signedByUserId, Id signedByContactId) {
        Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        Date today = System.today();
        Contract__c c = new Contract__c();
        c.Account__c = accountId;
        c.Contract_Start_Date_MOU_Date__c = today;
        c.Is_valid__c = true;
        c.Credit_Term__c = 'GB';
        c.Contract_End_Date__c = today.toStartOfMonth().addMonths(1).addDays(-1);
        c.Bill_Cycle__c = 'Fortnightly';
        c.Service_Requirements__c = 'service';
        c.Claim_Understanding__c = 'Owners Risk';
        c.Description__c = 'description';
        c.Contract_Copy_enclosed__c = 'Yes';
        c.MOU_enclosed__c = 'Yes';
        c.Bill_Submission__c = 'Local';
        c.Bill_Collection__c = 'Local';
        c.Customer_Signed_by_Customer__c = signedByContactId;
        c.Customer_Signed_date__c = today;
        c.Contract_Signed_by_Safexpress__c = signedByUserId;
        c.Safexpress_signed_date__c = today;
        c.Freight_MIS_required__c = 'Yes';
        c.POD_Link_Required__c = 'Yes';
        c.RecordTypeId = openRecordTypeId;
        return c;
    }

    // Open RT contract with a linked Closed Won Opportunity must block upload
    static testMethod void testMethod6_OpenRT_ClosedWonOpp_Blocked() {
        User us = setupBdmUser();
        System.runAs(us) {
            Account msaAccount = CommonDataTest.getMSAAccount();
            insert msaAccount;

            Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon;

            Contract__c objContract = buildTaggableContract(msaAccount.Id, us.Id, objCon.Id);
            insert objContract;

            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP CLOSED WON';
            objOpp.Type__c = 'Credit+Retail';
            objOpp.GST_Number__c = '09ASDGH6789K1ZZ';
            objOpp.TAN_No__c = 'PDES03028F';
            objOpp.Stage__c = 'Active';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            objOpp.Account__c = msaAccount.Id;
            objOpp.Contract__c = objContract.Id;
            objOpp.Valid_for_Contract_Tagging__c = true;
            insert objOpp;
            objOpp.Stage__c = 'Closed Won';
            update objOpp;

            Test.startTest();
            ContentVersion cv1 = CommonDataTest.getContectVersion();
            insert cv1;
            ContentVersion contentCv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];

            Boolean errorThrown = false;
            try {
                insert buildLink(objContract.Id, contentCv1.ContentDocumentId);
            } catch (DmlException e) {
                errorThrown = true;
                System.assert(e.getMessage().contains('Closed Won'), 'Unexpected error message: ' + e.getMessage());
            }
            Test.stopTest();
            System.assert(errorThrown, 'Upload must be blocked when a linked Opportunity is Closed Won');
        }
    }

    // Open RT contract with a linked Closed Lost Opportunity must block upload
    static testMethod void testMethod7_OpenRT_ClosedLostOpp_Blocked() {
        User us = setupBdmUser();
        System.runAs(us) {
            Account msaAccount = CommonDataTest.getMSAAccount();
            insert msaAccount;

            Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon;

            Contract__c objContract = buildTaggableContract(msaAccount.Id, us.Id, objCon.Id);
            insert objContract;

            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP CLOSED LOST';
            objOpp.Type__c = 'Credit+Retail';
            objOpp.GST_Number__c = '09ASDGH6789K1ZZ';
            objOpp.TAN_No__c = 'PDES03028F';
            objOpp.Stage__c = 'Active';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            objOpp.Account__c = msaAccount.Id;
            objOpp.Contract__c = objContract.Id;
            objOpp.Valid_for_Contract_Tagging__c = true;
            insert objOpp;
            objOpp.Stage__c = 'Closed Lost';
            objOpp.Lost_Reason__c = 'Customer Not Interested';
            update objOpp;

            Test.startTest();
            ContentVersion cv1 = CommonDataTest.getContectVersion();
            insert cv1;
            ContentVersion contentCv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];

            Boolean errorThrown = false;
            try {
                insert buildLink(objContract.Id, contentCv1.ContentDocumentId);
            } catch (DmlException e) {
                errorThrown = true;
                System.assert(e.getMessage().contains('Closed Won'), 'Unexpected error message: ' + e.getMessage());
            }
            Test.stopTest();
            System.assert(errorThrown, 'Upload must be blocked when a linked Opportunity is Closed Lost');
        }
    }

    // Open RT contract with an Active-stage Opportunity must allow unlimited uploads
    static testMethod void testMethod8_OpenRT_ActiveOpp_MultipleFiles_Allowed() {
        User us = setupBdmUser();
        System.runAs(us) {
            Account msaAccount = CommonDataTest.getMSAAccount();
            insert msaAccount;

            Contact objCon = CommonDataTest.getContact();
            objCon.LeadSource = 'Directory';
            objCon.Contact_State__c = 'Delhi';
            insert objCon;

            Contract__c objContract = buildTaggableContract(msaAccount.Id, us.Id, objCon.Id);
            insert objContract;

            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP ACTIVE';
            objOpp.Type__c = 'Credit+Retail';
            objOpp.GST_Number__c = '09ASDGH6789K1ZZ';
            objOpp.TAN_No__c = 'PDES03028F';
            objOpp.Stage__c = 'Active';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            objOpp.Account__c = msaAccount.Id;
            objOpp.Contract__c = objContract.Id;
            objOpp.Valid_for_Contract_Tagging__c = true;
            insert objOpp;

            Test.startTest();
            ContentVersion cv1 = CommonDataTest.getContectVersion();
            insert cv1;
            ContentVersion contentCv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];
            insert buildLink(objContract.Id, contentCv1.ContentDocumentId);

            ContentVersion cv2 = CommonDataTest.getContectVersion();
            cv2.PathOnClient = 'Penguins2.pdf';
            insert cv2;
            ContentVersion contentCv2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
            insert buildLink(objContract.Id, contentCv2.ContentDocumentId);
            Test.stopTest();

            List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :objContract.Id];
            System.assertEquals(2, links.size(), 'Active-stage Opportunity must not block uploads');
        }
    }

    // Closed RT contract with no CMT permission must block upload
    static testMethod void testMethod9_ClosedRT_NoPermission_Blocked() {
        User us = setupBdmUser();
        System.runAs(us) {
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

            Contract__c objContract = buildContract(objPro.Id, 'Closed');
            insert objContract;

            Test.startTest();
            ContentVersion cv1 = CommonDataTest.getContectVersion();
            insert cv1;
            ContentVersion contentCv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];

            Boolean errorThrown = false;
            try {
                insert buildLink(objContract.Id, contentCv1.ContentDocumentId);
            } catch (DmlException e) {
                errorThrown = true;
                System.assert(e.getMessage().contains('closed'), 'Unexpected error message: ' + e.getMessage());
            }
            Test.stopTest();
            System.assert(errorThrown, 'Upload must be blocked on a Closed RT contract without CMT permission');
        }
    }

    // Closed RT contract + CMT Read/Write + linked Actual_SFX account must allow upload
    static testMethod void testMethod10_ClosedRT_WithCMTPermission_AndSFXAccount_Allowed() {
        User us = setupBdmUser();

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Contract_Management_Team_Read_Write' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = us.Id, PermissionSetId = ps.Id);

        System.runAs(us) {
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

            Contract__c objContract = buildContract(objPro.Id, 'Closed');
            insert objContract;

            Id actualSfxRT = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Actual_SFX').getRecordTypeId();
            Account objSfx = new Account();
            objSfx.Name = 'TEST ACTUAL SFX';
            objSfx.RecordTypeId = actualSfxRT;
            objSfx.Region__c = 'DELHI';
            objSfx.Contract__c = objContract.Id;
            insert objSfx;

            Test.startTest();
            ContentVersion cv1 = CommonDataTest.getContectVersion();
            insert cv1;
            ContentVersion contentCv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];
            insert buildLink(objContract.Id, contentCv1.ContentDocumentId); // must succeed
            Test.stopTest();

            List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :objContract.Id];
            System.assertEquals(1, links.size(), 'CMT Read/Write user must upload to a Closed contract with a linked Actual_SFX account');
        }
    }

    // Closed RT contract + CMT Read/Write but no linked Actual_SFX account must still block upload
    static testMethod void testMethod11_ClosedRT_WithCMTPermission_NoSFXAccount_Blocked() {
        User us = setupBdmUser();

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Contract_Management_Team_Read_Write' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = us.Id, PermissionSetId = ps.Id);

        System.runAs(us) {
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

            Contract__c objContract = buildContract(objPro.Id, 'Closed');
            insert objContract;

            Test.startTest();
            ContentVersion cv1 = CommonDataTest.getContectVersion();
            insert cv1;
            ContentVersion contentCv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];

            Boolean errorThrown = false;
            try {
                insert buildLink(objContract.Id, contentCv1.ContentDocumentId);
            } catch (DmlException e) {
                errorThrown = true;
                System.assert(e.getMessage().contains('No SFX account'), 'Unexpected error message: ' + e.getMessage());
            }
            Test.stopTest();
            System.assert(errorThrown, 'CMT Read/Write must not bypass the block when no Actual_SFX account is linked');
        }
    }

    // Bulk safety: 5 Open RT contracts uploaded in a single DML batch, no governor limit issues
    static testMethod void testMethod12_BulkOpenRTContracts_NoBlockingOpp_Allowed() {
        User us = setupBdmUser();
        System.runAs(us) {
            Account objPro = CommonDataTest.getParentAccount();
            insert objPro;

            List<Contract__c> contracts = new List<Contract__c>();
            for (Integer i = 0; i < 5; i++) {
                contracts.add(buildContract(objPro.Id, 'Open'));
            }
            insert contracts;

            List<ContentVersion> versions = new List<ContentVersion>();
            for (Integer i = 0; i < 5; i++) {
                ContentVersion cv = CommonDataTest.getContectVersion();
                cv.PathOnClient = 'Bulk' + i + '.pdf';
                versions.add(cv);
            }

            Test.startTest();
            insert versions;
            Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>(
                [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versions]
            );

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Integer i = 0; i < 5; i++) {
                links.add(buildLink(contracts[i].Id, cvMap.get(versions[i].Id).ContentDocumentId));
            }
            insert links;
            Test.stopTest();

            Set<Id> contractIds = new Map<Id, Contract__c>(contracts).keySet();
            System.assertEquals(5, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId IN :contractIds]);
        }
    }
}