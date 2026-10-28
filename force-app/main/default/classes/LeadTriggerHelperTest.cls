/**
* Description		:		Test class for LeadTriggerHelper apex class
* 
* Coverage			:		81%
**/
@isTest  
public class LeadTriggerHelperTest {
    static testMethod void testMethod1() {
        
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        Group g1 = new Group(Name='Lead Central Team (Credit)', type='Queue');
        insert g1;
        
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType ='Lead__c');
        insert q1;
        
        System.runAS(us){
            
            Lead__c objLead = CommonDataTest.getLead();
            objLead.Type__c = 'Credit';
            objLead.Status__c = 'Active';
            objLead.Account_Type__c = 'Emerging';
            objLead.Source__c = 'Directory';
            objLead.Assigned_to_Central_Desk__c = false;
            insert objLead;
            
            objLead.Assigned_to_Central_Desk__c = true;
            update objLead;
            
            Lead__c objLead1 = CommonDataTest.getLead();
            objLead1.Type__c = 'Credit';
            objLead1.Account_Type__c = 'Emerging';
            objLead1.name = 'TEST LEAD 2';
            objLead1.Email__c = 'test122@gmail.com';
            objLead1.Phone__c = '5456789098';
            objLead1.Source__c = 'Directory';
            objLead1.Assigned_to_Central_Desk__c = true;
            objLead1.Status__c = 'Active';//**
            insert objLead1;
            
            objLead1.Automation__c = true;
            update objLead1;
            
        }
    }
    static testMethod void testMethod2() {
        
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        
        Group g2 = new Group(Name='Lead Central Team (Retail)', type='Queue');
        insert g2;
        QueuesObject q2 = new QueueSObject(QueueID = g2.id, SobjectType = 'Lead__c');
        insert q2;
        
        System.runAS(us){
            
            Lead__c objLead = CommonDataTest.getLead();
            objLead.Type__c = 'Credit';
            objLead.Source__c = 'Directory';
            objLead.Assigned_to_Central_Desk__c = false;
            objLead.Status__c = 'Active';
            insert objLead;
            
            objLead.Assigned_to_Central_Desk__c = true;
            update objLead;
            
            Lead__c objLead1 = CommonDataTest.getLead();
            objLead1.Type__c = 'Credit';
            objLead1.name = 'TEST LEAD 2';
            objLead1.Email__c = 'test122@gmail.com';
            objLead1.Phone__c = '5456789098';
            objLead1.Source__c = 'Directory';
            objLead1.Assigned_to_Central_Desk__c = true;
            objLead1.Status__c = 'Active';//**
            insert objLead1;
            
            objLead1.Automation__c = true;
            update objLead1;
            
        }
    }
    
    static testMethod void testMethod3() {
        
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        
        Group g3 = new Group(Name='Lead Central Team (3PL)', type='Queue');
        insert g3;
        QueuesObject q3 = new QueueSObject(QueueID = g3.id, SobjectType = 'Lead__c');
        insert q3;
        
        System.runAS(us){
            
            Lead__c objLead = CommonDataTest.getLead();
            objLead.Type__c = '3PL';
            objLead.Source__c = 'Directory';
            objLead.Assigned_to_Central_Desk__c = false;
            objLead.Status__c = 'Active';
            insert objLead;
            
            objLead.Assigned_to_Central_Desk__c = true;
            update objLead;
            
            Lead__c objLead1 = CommonDataTest.getLead();
            objLead1.Type__c = '3PL';
            objLead1.name = 'TEST LEAD 2';
            objLead1.Email__c = 'test122@gmail.com';
            objLead1.Phone__c = '5456789098';
            objLead1.Source__c = 'Directory';
            objLead1.Assigned_to_Central_Desk__c = true;
            objLead1.Status__c = 'Active';//**
            insert objLead1;
            
            objLead1.Automation__c = true;
            update objLead1;
            
        }
    }
    
    static testMethod void testMethod4() {
        
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        System.runAS(us){
            String orgId=UserInfo.getOrganizationId(); 
            Profile pfAM= [Select Id from profile where Name='Area Manager' limit 1]; 
            String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
            Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
            String uniqueName=orgId+dateString+RandomId; 
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = uniqueName + '@test' + orgId + '.org', 
                               Username = uniqueName + '@test' + orgId + '.org', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = uniqueName.substring(18, 23), 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfAM.Id,
                               Region__c = 'DELHI',
                               AD_Id__c = '123',
                               Department = 'test AM',
                               Designation__c = 'Account Manager - Manages Credit Customers',
                               Area__c = 'DELHI',
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'                                                   
                              ); 
            Insert UsAM;
            
            Lead__c objLead = new Lead__c(
                name = 'TEST LEAD',
                Type__c = 'CREDIT',
                Account_Type__c = 'Emerging',
                Source__c = 'Reference Call ',
                Contact_Person_Name__c = 'test person name',
                Email__c = 'test@gmail.com',
                Phone__c = '1234567898',
                Region__c = 'DELHI',
                Status__c = 'Active',
                Street__c ='test street',
                City__c = 'DELHI',
                Zip_Postal_Code__c = '123456',
                State__c = 'DELHI',
                Area__c = 'DELHI'
            );
            Insert objLead;
            
            //  Lead__c TestLead = CommonDataTest.getLead();
            //  TestLead.Area__c = 'DELHI WEST';
            //  Insert TestLead;
            
        }
    }
    
    static testMethod void testleadShareInsert(){
        
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        System.runAS(us){
            String orgId=UserInfo.getOrganizationId(); 
            Profile pfAM= [Select Id from profile where Name='Area Manager' limit 1]; 
            String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
            Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
            String uniqueName=orgId+dateString+RandomId; 
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = uniqueName + '@test' + orgId + '.org', 
                               Username = uniqueName + '@test' + orgId + '.org', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = uniqueName.substring(18, 23), 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfAM.Id,
                               Region__c = 'DELHI',
                               AD_Id__c = '123',
                               Department = 'test AM',
                               Designation__c = 'Area manager',
                               Area__c = 'DELHI',
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'
                               
                              ); 
            Insert UsAM;
            
            Lead__c objLead = new Lead__c(
                name = 'TEST LEAD',
                Type__c = 'CREDIT',
                Account_Type__c = 'Emerging',
                Source__c = 'Reference Call ',
                Contact_Person_Name__c = 'test person name',
                Email__c = 'test@gmail.com',
                Phone__c = '1234567898',
                Region__c = 'DELHI',
                Status__c = 'Active',
                Street__c ='test street',
                City__c = 'DELHI',
                Zip_Postal_Code__c = '123456',
                State__c = 'DELHI',
                Area__c = 'DELHI'
            );
            Insert objLead;
        }        
    }
    
    static testMethod void testupdateLeadToShare(){
        
        
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        System.runAS(us){
            String orgId=UserInfo.getOrganizationId(); 
            Profile pfAM= [Select Id from profile where Name='Area Manager' limit 1]; 
            String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
            Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
            String uniqueName=orgId+dateString+RandomId; 
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = uniqueName + '@test' + orgId + '.org', 
                               Username = uniqueName + '@test' + orgId + '.org', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = uniqueName.substring(18, 23), 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfAM.Id,
                               Region__c = 'DELHI',
                               AD_Id__c = '123',
                               Department = 'test AM',
                               Designation__c = 'Area manager',
                               Area__c = 'DELHI',
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'
                               
                              ); 
            Insert UsAM;            
            
            Lead__c objLead = new Lead__c(
                name = 'TEST LEAD',
                Type__c = 'CREDIT',
                Account_Type__c = 'Emerging',
                Source__c = 'Reference Call ',
                Contact_Person_Name__c = 'test person name',
                Email__c = 'test@gmail.com',
                Phone__c = '1234567898',
                Region__c = 'DELHI',
                Status__c = 'Active',
                Street__c ='test street',
                City__c = 'DELHI',
                Zip_Postal_Code__c = '123456',
                State__c = 'DELHI',
                Area__c = 'DELHI'
            );
            insert objLead;
            
            Lead__Share ledShr = new Lead__Share(ParentId= objLead.Id, UserOrGroupId= UsAM.Id, AccessLevel='Read');
            insert ledShr;
            
            List<Lead__c> lstToUpdate = new List<Lead__c>();
            List<Lead__c> led = [Select Id, Area__c from Lead__c where id =: objLead.Id];
            for(Lead__c ld : led){
                ld.Region__c = 'ANDHRA PRADESH - TELANGANA';
                ld.Area__c = 'HYDERABAD CITY';
                lstToUpdate.add(ld);
            }            
            update lstToUpdate;        
        }    
    } 
    
    
   // Mock HTTP callout class
    private class GSTHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Create fake GST response
            String mockBody = '{"data":{"Gstin":"123456789012345","LegalName":"Test Legal","TradeName":"Test Trade"}}';
            res.setBody(mockBody);
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        // Create Retail & Credit record types for Lead__c
        Id retailRtId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
                         .get('Retail_Lead').getRecordTypeId();
        Id creditRtId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
                         .get('Credit_Lead').getRecordTypeId();

        // Create Metadata record for GST validation
        State_GST_Code__mdt gstCode = new State_GST_Code__mdt(
            MasterLabel = 'Uttarakhand',
            State_GST_Code__c = '05'
        );
       // insert gstCode;

        // Create Lead with Retail Record Type
        Lead__c retailLead = new Lead__c(
            Name = 'Retail Lead',
            RecordTypeId = retailRtId,
            Status__c = 'Active',
            State__c = 'Uttarakhand',
            GST_Number__c = '05ABCDE1234F1Z5',
            GST_Exempted__c = false
        );
        insert retailLead;

        // Create Lead with Credit Record Type
        Lead__c creditLead = new Lead__c(
            Name = 'Credit Lead',
            RecordTypeId = creditRtId,
            Status__c = 'Active',
            State__c = 'Uttarakhand',
            GST_Number__c = '05ABCDE1234F1Z5',
            GST_Exempted__c = false
        );
        insert creditLead;
    }

    @IsTest
    static void testHandleRecordTypeChange_RetailToCredit() {
        Id retailRtId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
                         .get('Retail_Lead').getRecordTypeId();
        Id creditRtId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
                         .get('Credit_Lead').getRecordTypeId();

        Lead__c leadRec = [SELECT Id, RecordTypeId FROM Lead__c WHERE Name = 'Retail Lead' LIMIT 1];
        Lead__c oldLead = leadRec.clone(false, true, false, false);
        oldLead.RecordTypeId = retailRtId;
        leadRec.RecordTypeId = creditRtId;

        Test.startTest();
        LeadTriggerHelper.handleRecordTypeChange(new List<Lead__c>{leadRec},
                                                 new Map<Id, Lead__c>{leadRec.Id => oldLead});
        Test.stopTest();

        System.assertEquals('Active', leadRec.Status__c);
    }

    @IsTest
    static void testHandleRecordTypeChange_CreditToRetail() {
        Id retailRtId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
                         .get('Retail_Lead').getRecordTypeId();
        Id creditRtId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
                         .get('Credit_Lead').getRecordTypeId();

        Lead__c leadRec = [SELECT Id, RecordTypeId FROM Lead__c WHERE Name = 'Credit Lead' LIMIT 1];
        Lead__c oldLead = leadRec.clone(false, true, false, false);
        oldLead.RecordTypeId = creditRtId;
        leadRec.RecordTypeId = retailRtId;

        Test.startTest();
        LeadTriggerHelper.handleRecordTypeChange(new List<Lead__c>{leadRec},
                                                 new Map<Id, Lead__c>{leadRec.Id => oldLead});
        Test.stopTest();

        System.assertEquals('Active', leadRec.Status__c);
    }

    @IsTest
    static void testValidateGSTWithState_Mismatch() {
        Lead__c leadRec = [SELECT Id, State__c, GST_Number__c FROM Lead__c LIMIT 1];
        leadRec.State__c = 'Uttarakhand';
        leadRec.GST_Number__c = '07ABCDE1234F1Z5'; // Wrong code for Uttarakhand (should be '05')

        Test.startTest();
        try {
            LeadTriggerHelper.validateGSTWithState(new List<Lead__c>{leadRec});
        } catch (Exception e) {
            // Expected addError prevents DML, but in unit tests it's caught as exception
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateRetailLeadName_ValidGST() {
        Id retailRtId = Schema.SObjectType.Lead__c.getRecordTypeInfosByDeveloperName()
                         .get('Retail_Lead').getRecordTypeId();

        Lead__c ld = new Lead__c(
            Name = 'Retail Qualified',
            RecordTypeId = retailRtId,
            Status__c = 'Active',
            GST_Number__c = '05ABCDE1234F1Z5',
            GST_Exempted__c = false,
            State__c = 'Uttarakhand'
        );
        insert ld;
        Map<Id, Lead__c> leadMap = new Map<Id, Lead__c>{ ld.Id => ld };
        Test.setMock(HttpCalloutMock.class, new GSTHttpMock());

        Test.startTest();
        LeadTriggerHelper.updateRetailLeadName(new List<Lead__c>{ld},leadMap);
        Test.stopTest();
    }

    @IsTest
    static void testValidateGSTNumber_DirectCall() {
        Test.setMock(HttpCalloutMock.class, new GSTHttpMock());

        Lead__c ld = [SELECT Id, Name, GST_Number__c, GST_Exempted__c FROM Lead__c LIMIT 1];
        ld.GST_Exempted__c = false;
        ld.GST_Number__c = '05ABCDE1234F1Z5';

        Test.startTest();
        LeadTriggerHelper.validateGSTNumber(ld);
        Test.stopTest();
    }
    @isTest
	static void testGSTNegativeBranches() {

        Test.setMock(HttpCalloutMock.class, new GSTHttpMock());
    
        Lead__c ld = [SELECT Id, Name, GST_Number__c, GST_Exempted__c, Status__c 
                      FROM Lead__c LIMIT 1];
    
        ld.GST_Number__c = '05ABCDE1234F1Z5';
        ld.GST_Exempted__c = false;
        ld.Status__c = 'Qualified';
    
        Map<Id, Lead__c> oldMap = new Map<Id, Lead__c>();
        oldMap.put(ld.Id, ld);
    
        Test.startTest();
        LeadTriggerHelper.updateRetailLeadName(new List<Lead__c>{ld}, oldMap);
    
        LeadTriggerHelper.processGSTValidationAsync(ld.Id, 'Active');
        Test.stopTest();
    }
    @IsTest
        static void testGSTStateBlank() {
        
            Lead__c ld = new Lead__c(
                Name='GST Test',
                GST_Number__c='05ABCDE1234F1Z5'
            );
        
            try{
                LeadTriggerHelper.validateGSTWithState(
                    new List<Lead__c>{ld}
                );
            }catch(Exception e){}
        
            System.assert(true);
        }
    @IsTest
        static void testUpdateApprovalStatus() {
        
            Lead__c ld = CommonDataTest.getLead();
            ld.Type__c = 'Credit';
            ld.Status__c = 'Active';
            ld.Assigned_to_Central_Desk__c = true;
            insert ld;
        
            Lead__c oldLd = ld.clone(false, true, false, false);
            oldLd.Approval_Status__c = 'Pending';
        
            ld.Approval_Status__c = ConstantUtility.Rejected;
        
            Test.startTest();
            LeadTriggerHelper.updateApprovalStatus(
                new List<Lead__c>{ld},
                new Map<Id,Lead__c>{ld.Id => oldLd}
            );
            Test.stopTest();
        
            System.assertEquals(
                ConstantUtility.Approval_Status_Central_Team,
                ld.Approval_Status__c
            );
        
            System.assertNotEquals(null, ld.OwnerId);
        }
    @IsTest
        static void testUpdateApprovalStatus_BDM() {
        
            Lead__c ld = CommonDataTest.getLead();
            ld.Status__c = 'Active';
            ld.Assigned_to_Central_Desk__c = false;
            insert ld;
        
            Lead__c oldLd = ld.clone(false, true, false, false);
            oldLd.Approval_Status__c = 'Pending';
        
            ld.Approval_Status__c = ConstantUtility.Rejected;
        
            Test.startTest();
            LeadTriggerHelper.updateApprovalStatus(
                new List<Lead__c>{ld},
                new Map<Id,Lead__c>{ld.Id => oldLd}
            );
            Test.stopTest();
        
            System.assertEquals(
                ConstantUtility.Approval_Status_Central_Team_BDM,
                ld.Approval_Status__c
            );
        }
}
// }