/*********************************************************************************************
**Author: Safexpress.com
**Description: test class written to cover the mentioned webservice.  
**JIRA Ticket: 
**Class:  PropelISFXUpsert 
**History: 
**Modified Date:                  
**Description: 
**Modified By:
*************************************************************************************************** */

@isTest
Public Class trg_billingInformation_Test
{
    Static testMethod void unit_PropelISFXUpsertAPI()
    {
        //Create MSA Account.         
        Account msaAccount = new Account();
        msaAccount.name = 'TEST PROSPECT ACCOUNT';
        msaAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        msaAccount.region__c = 'DELHI';
        msaAccount.Vertical__c = 'APPARELS';
        msaAccount.Sub__c = 'YARN';
        msaAccount.Propel_MSACode__c = 'MSA00000122';
        msaAccount.Propel_Key__c = '150';
        msaAccount.Contact_Person_Name__c = 'MALINI.KESAVAN';
        msaAccount.Phone = null;
        msaAccount.Mobile_No__c = '9750830555';
        msaAccount.Email__c = 'DESPATCH@QUICKDRY.IN';
        msaAccount.Type__c = 'CREDIT';
        msaAccount.Pan_No__c = 'AABCA6617M';
       // msaAccount.RecordTypeId = recordTypeId;
        
        insert msaAccount;
        // Insert the opportunity record. 
        Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
        objOpp1.Account__c = msaAccount.Id;
        objOpp1.Monthly_Potential_Air__c = 34 ;
        objOpp1.Monthly_Potential_Surface__c = 55;
        objOpp1.X3PL_Potential__c = 60;
        objOpp1.Customer_Type__c = 'NEW OPPORTUNITY';
        objOpp1.SFX_Code__c = 'SFX00000109';
        objOpp1.Gst_Exempted__c = true;
        objOpp1.PAN_No__c = 'AABCA6617M'; //SAC-1550
        insert objOpp1;
        System.assertNotEquals(objOpp1.Id, Null);

        // Insert the SFX record. 
        Account sfxAccount = new Account();
        sfxAccount.Name = 'SFX00000109';
        sfxAccount.SFX_Code__c = 'SFX00000109';
        sfxAccount.Propeli_Id__c = 5380;
        // Propel_MSACode__c = sfxJSON.Propel_MSACode,
        sfxAccount.Propel_key__c= '5380';
        sfxAccount.ParentId = msaAccount.Id;
        sfxAccount.RecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        sfxAccount.Contract_Sign_Date__c = System.Today();
        sfxAccount.Contract_Effective_Date__c = System.Today();
        sfxAccount.Contract_Expiry_date__c = System.Today().addDays(5);
        sfxAccount.Direct_Pickup__c = 'No';
        sfxAccount.Delivery_Hold__c = 'No';
        sfxAccount.Status__c = 'ACTIVE';
        sfxAccount.Business_Type__c = 'OUTBOUND';
        sfxAccount.Service_line__c = 'DISTRIBUTION';
        insert sfxAccount;
        
        // Insert Branch Master Details.
        Branch_Master__c objBranchMas = new Branch_Master__c();
        objBranchMas.Name = 'TEST BRANCH';
        objBranchMas.Region__c = 'DELHI';
        objBranchMas.PropelI_Branch_ID__c = 123456;
        insert objBranchMas;
        System.assertNotEquals(objBranchMas.Id, Null);

        // Insert Billing Information record. 
        Billing_Information__c upsert_BillRec = new Billing_Information__c();
        upsert_BillRec.Billing_Level__c = 'MSA';
        upsert_BillRec.MSA__c = 'MSA00000122';
        upsert_BillRec.SFX_no__c = 'SFX00000109';
        upsert_BillRec.Start_Date__c = System.Today();
        upsert_BillRec.Alias_name__c = 'testing';
        upsert_BillRec.Rate_Card_no__c = null;
        upsert_BillRec.Billing_Config_Id__c = 5467;
        upsert_BillRec.SFX__c =sfxAccount.id ;
        upsert_BillRec.Name = 'Billing Info:' + 'MSA00000122'+':'+ 'SFX00000109';
        upsert_BillRec.Composite_key__c = 'MSA00000122' + '::' + 'SFX00000109';
        upsert_BillRec.IsActive__c = true;
        insert upsert_BillRec;
        System.assertNotEquals(upsert_BillRec.id, null);
        
        // Update the billing level on billing information record. 
        upsert_BillRec.Billing_Level__c = 'SFX';
        update upsert_BillRec;

    }
}