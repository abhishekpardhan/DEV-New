@isTest
public class TestContentDocument {
    @isTest static void TestDeleteFile() {
        
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
        objOpp1.Account__c = msaAccount.Id;
        objOpp1.Monthly_Potential_Air__c = 34 ;
        objOpp1.Monthly_Potential_Surface__c = 55;
        objOpp1.X3PL_Potential__c = 60;
        objOpp1.Customer_Type__c = 'New Opportunity';
        objOpp1.Region__c = 'DELHI';
        objOpp1.SFX_Code__c = '12345';
        objOpp1.Gst_Exempted__c = true;
        objOpp1.PAN_No__c = 'ASDGH6789K';
        objOpp1.TAN_No__c = 'QWER12345T';
        objOpp1.LatestQuote__c = null;
        insert objOpp1;
        
        Id rIdquoteNew = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId();
        
        Quote__c objQuo = CommonDataTest.getQuote(); 
        objQuo.Enter_Remarks__c = null;
        objQuo.Opportunity__c = objOpp1.Id;
        objQuo.recordTypeId = rIdquoteNew;
        insert objQuo;
       ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id];
        Id contentDocumentId = insertedCV.ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = objQuo.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
 
        // Test INSERT
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentDocumentId];
        System.assertEquals(documents.size(), 1);
        
        
        
        // Test DELETE
        delete cdl;
        delete documents;
        documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 0);
    }
    
    @isTest static void TestDeleteFile1() {
        
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
        objOpp1.Account__c = msaAccount.Id;
        objOpp1.Monthly_Potential_Air__c = 34 ;
        objOpp1.Monthly_Potential_Surface__c = 55;
        objOpp1.X3PL_Potential__c = 60;
        objOpp1.Customer_Type__c = 'New Opportunity';
        objOpp1.Region__c = 'DELHI';
        objOpp1.SFX_Code__c = '12345';
        objOpp1.Gst_Exempted__c = true;
        objOpp1.PAN_No__c = 'ASDGH6789K';
        objOpp1.TAN_No__c = 'QWER12345T';
        objOpp1.LatestQuote__c = null;
        insert objOpp1;
        
        Id rIdquoteNew = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId();
        
        Quote__c objQuo = CommonDataTest.getQuote(); 
        objQuo.Enter_Remarks__c = null;
        objQuo.Opportunity__c = objOpp1.Id;
        objQuo.recordTypeId = rIdquoteNew;
        insert objQuo;
       ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id];
        Id contentDocumentId = insertedCV.ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = objQuo.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
 
        // Test INSERT
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentDocumentId];
        System.assertEquals(documents.size(), 1);
        
        
        
        // Test DELETE
        delete documents;
        documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 0);
    }
    
    @isTest static void TestDeleteFile2() {
        
        List<profile> pfList = new List<profile>();
        pfList = [Select Id from profile where Name = 'System Administrator']; 
        User us=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = 'test13@test13.com', 
                         Username = 'testabc13@testabc13.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'test', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfList[0].Id,
                         Region__c = 'DELHI',
                         AD_Id__c = '123',
                         Department = 'test AM',
                         Designation__c = 'Area manager',
                         Area__c = 'DELHI', 
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                        ); 
        Insert us;
        
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        Contact objCon = CommonDataTest.getContact();
        objCon.LeadSource = 'Directory';
        objCon.Contact_State__c = 'Delhi';
        insert objCon ;
        Id openRecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        
        Contract__c c = new Contract__c();
        c.Account__c = msaAccount.Id;
        c.Contract_Start_Date_MOU_Date__c = Date.today();
        //c.Is_valid__c = false;
        c.Credit_Term__c = 'GB';
        Date startDate = Date.today();
        c.Contract_Start_Date_MOU_Date__c = startDate;
        Date today = System.today();
        Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
        c.Contract_End_Date__c = lastDayOfMonth;
        c.Bill_Cycle__c = 'Fortnightly';
        c.Service_Requirements__c = 'service';
        c.Claim_Understanding__c = 'Owners Risk';
        c.Description__c = 'description';
        c.Contract_Copy_enclosed__c = 'Yes';
        c.MOU_enclosed__c = 'Yes';
        c.Bill_Submission__c = 'Local';
        c.Bill_Collection__c = 'Local';
        c.Customer_Signed_by_Customer__c = objCon.Id;
        c.Customer_Signed_date__c = Date.Today();
        c.Contract_Signed_by_Safexpress__c = us.Id;
        c.Safexpress_signed_date__c = Date.today();
        c.Freight_MIS_required__c = 'Yes';
        c.POD_Link_Required__c = 'Yes';
        c.RecordTypeId = openRecordTypeId;
        insert c;
       ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id];
        Id contentDocumentId = insertedCV.ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = c.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
 
        // Test INSERT
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentDocumentId];
        System.assertEquals(documents.size(), 1);
        
        
        
        // Test DELETE
        delete documents;
        documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 0);
    }
}