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
Public Class PropelISFXUpsert_Test
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
        objOpp1.PAN_No__c = 'AABCA6617M';
        insert objOpp1;
        System.assertNotEquals(objOpp1.Id, Null);
        
        // Insert Branch Master Details.
        Branch_Master__c objBranchMas = new Branch_Master__c();
        objBranchMas.Name = 'TEST BRANCH';
        objBranchMas.Region__c = 'DELHI';
        objBranchMas.PropelI_Branch_ID__c = 123456;
        insert objBranchMas;
        System.assertNotEquals(objBranchMas.Id, Null);
        
        // Add the branch line items.
        PropelISFXUpsert.wrapBillinglineItems billingLineItem = new PropelISFXUpsert.wrapBillinglineItems();
        billingLineItem.Billing_by_id =  '5116';
        billingLineItem.Assign_billing_branch_id =  123456;
        billingLineItem.Billing_Branch = 123456;
        billingLineItem.Submission_branch = 123456;
        billingLineItem.Collection_branch =  123456;
        billingLineItem.Billing_address = 'ASDFGH , BHILWARA CITY , BHILWARA , RAJASTHAN 311001';
        billingLineItem.Minimum_Billing =  0;
        billingLineItem.Comm_bill_email =  'DF@GMAIL.COM';
        billingLineItem.Monthly_Potential =  0;
        billingLineItem.Credit_Risk =  0;
        List<PropelISFXUpsert.wrapBillinglineItems> lstBillingItems = new List<PropelISFXUpsert.wrapBillinglineItems>();
        lstBillingItems.add(billingLineItem);
       
        PropelISFXUpsert.jsonWrapBilling billing = new PropelISFXUpsert.jsonWrapBilling();
        billing.Billing_Level = 'MSA';
        billing.Billing_type = 'DESTINATION BRANCH WISE';
        billing.Sfx_no = 'SFX00000109';
        billing.msa = 'MSA00000122';
        billing.Start_date = System.Today();
        billing.alias_name =  'JSONTEST1';
        billing.Billing_config_id = 4786;
        billing.billing_by = lstBillingItems;
        
        List<PropelISFXUpsert.jsonWrapBilling> lstBillings = new List<PropelISFXUpsert.jsonWrapBilling>();
        lstBillings.add(billing);
        
        PropelISFXUpsert.jsonWrapBranch assignedBranch = new PropelISFXUpsert.jsonWrapBranch();
        assignedBranch.assign_branch_id = 5767;
        assignedBranch.MDM_branch_id = 16;
        assignedBranch.Effective_date = System.Today();
        assignedBranch.Booking_hold = '0';
        assignedBranch.delivery_hold = '0';
        
        List<PropelISFXUpsert.jsonWrapBranch> lstAssignedBranch =  new List<PropelISFXUpsert.jsonWrapBranch>();
        lstAssignedBranch.add(assignedBranch);
        
        PropelISFXUpsert.jsonWrapRATE rateCard = new PropelISFXUpsert.jsonWrapRATE();
        rateCard.rate_card_name = 'RC5811';
        rateCard.id = 5811;
        rateCard.start_date =  System.Today();
        rateCard.end_date = System.Today().AddDays(10);
        rateCard.base_location = 16;
        rateCard.status = 'ACTIVE';
        rateCard.assign_branch = lstAssignedBranch;
         
        List<PropelISFXUpsert.jsonWrapRATE> lstRateCards = new List<PropelISFXUpsert.jsonWrapRATE>();
        lstRateCards.add(rateCard);   
        
        PropelISFXUpsert.jsonWrapOffering serviceOffering = new  PropelISFXUpsert.jsonWrapOffering();      
        serviceOffering.Service_Offering = 'SURFACE';
        serviceOffering.Rate_card = lstRateCards;
		List<PropelISFXUpsert.jsonWrapOffering> lstServiceOffering = new List<PropelISFXUpsert.jsonWrapOffering>();
        lstServiceOffering.add(serviceOffering);
        
        PropelISFXUpsert.jsonWrapSFX newSFX = new PropelISFXUpsert.jsonWrapSFX();
        newSFX.Propel_MSACode = 'MSA00000122';
        newSFX.Propel_Key = '5380';
        newSFX.id = 6843;
        newSFX.Account_Id = msaAccount.Id;
        newSFX.SFXCode = 'SFX00000109';
        newSFX.Status = 'ACTIVE';
        newSFX.Contract_Sign_date = System.Today();
        newSFX.Contract_Start_date = System.Today();
        newSFX.Contract_Expiry_date = System.Today();
        newSFX.Direct_Pickup =  'NO';
        newSFX.Delivery_Hold = 'NO';
        newSFX.Business_Type = 'OUTBOUND';
        newSFX.Service_line = 'DISTRIBUTION';
        newSFX.Opportunity =  objOpp1.Id;
        newSFX.Offerings = lstServiceOffering;
        newSFX.Billing_Info =lstBillings;
        
       //Make the websercvice callout. 
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        req.requestUri ='/services/apexrest/SFX_RATECreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        String myJSON = JSON.serialize(newSFX);
        req.requestBody = Blob.valueof(myJSON);
        PropelISFXUpsert.createCustomer();
        Test.stopTest();
    }
}