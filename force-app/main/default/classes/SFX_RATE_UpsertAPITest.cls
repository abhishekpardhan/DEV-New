/**
 * Description    :    Test class for SFX_RATE_UpsertAPITest apex class
 * 
 * Coverage      :    100%
 **/
@IsTest
public class SFX_RATE_UpsertAPITest {
static testMethod void testPostMethod()
    {     
        

        /*ring SFXRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Actual SFX').getRecordTypeId();
        String RateRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate_card').getRecordTypeId();
        String OfferingRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        String AssignBranchRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId(); */
        // Insert the Parent account.
        Account Parent = CommonDataTest.getParentAccount();
        //rent.RecordTypeId = MSARecordTypeID;
        // Insert the opportunity record. 
        Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
        objOpp1.Account__c = Parent.Id;
        objOpp1.Monthly_Potential_Air__c = 34 ;
        objOpp1.Monthly_Potential_Surface__c = 55;
        objOpp1.X3PL_Potential__c = 60;
        objOpp1.Customer_Type__c = 'Renewal Opportunity';
        objOpp1.SFX_Code__c = 'SFX000006399';
        objOpp1.Gst_Exempted__c = true;
        objOpp1.PAN_No__c = 'ABCHB4353L';
        insert objOpp1;
        
        // Insert Branch Master Details.
        Branch_Master__c objBranchMas = new Branch_Master__c();
        objBranchMas.Name = 'TEST BRANCH';
        objBranchMas.Region__c = 'DELHI';
        objBranchMas.PropelI_Branch_ID__c = 123456;
        insert objBranchMas;
        
        
        SFX_RATE_UpsertAPI.jsonWrapBilling Bil = new SFX_RATE_UpsertAPI.jsonWrapBilling();
        Bil.Billing_Level ='MSA';
        Bil.Rate_card_no = 'ABC4321';
        Bil.SFX_no = 'SFX000006399';
        Bil.msa = 'MSA00000080';
        Bil.Start_date = Date.today();
        Bil.End_date = Date.today();
        Bil.alias_name = 'ABC';
        List<SFX_RATE_UpsertAPI.jsonWrapBilling> BillList = new List<SFX_RATE_UpsertAPI.jsonWrapBilling>();
        BillList.add(Bil);
        
        SFX_RATE_UpsertAPI.jsonWrapBranch Branch = new SFX_RATE_UpsertAPI.jsonWrapBranch();
        Branch.assign_branch_id = 123456;
        Branch.Billing_Branch = 123456; 
        Branch.Billing_State_id = 123456;
        Branch.Submission_branch = 123456;
        Branch.Collection_branch = 123456;
        Branch.BILLING_STREET = 'Test Address';
        Branch.BILLING_CITY = 'Test City';
        Branch.BILLING_COUNTRY = 'Test Country';
        Branch.BILLING_ZIP_POSTAL_CODE = '136027';
        Branch.BILLING_STATE = 'Test State';
        Branch.Minimum_Billing = 200;
        Branch.E_Bill_id = 'Test@gmail.com';
        Branch.Comm_bill_email = 'Test1@gmail.com';
        Branch.GST = '22CBCDE1234F2Z0';
        Branch.TAN = 'AXSCD1234CD';
       // public String PAN;
        Branch.Multiple_Emails = 'TRUE';
        Branch.GB_Category = 'TEST';
        Branch.Monthly_Potential = 900;
        Branch.Credit_Risk = 'NUN'; 
        Branch.Effective_date = SYSTEM.TODAY();
        Branch.expiry_date = SYSTEM.TODAY().ADDDAYS(30);
        Branch.Booking_hold = 'Nun';
       	Branch.Booking_Hold_Reason = 'No Reason';
        Branch.delivery_hold = 'Test Hold';
        Branch.delivery_hold_reason = 'Test Reason';  
        
        List<SFX_RATE_UpsertAPI.jsonWrapBranch> BranchList = new List<SFX_RATE_UpsertAPI.jsonWrapBranch>(); 
        BranchList.add(Branch);
        
        SFX_RATE_UpsertAPI.jsonWrapRATE RateCard = new SFX_RATE_UpsertAPI.jsonWrapRATE();
        RateCard.rate_card_name = 'RC-0003';
        RateCard.id = 1234;
        RateCard.Sign_date = date.today();
        RateCard.Start_date = date.today();
        RateCard.End_date = date.today();
        RateCard.Base_location = 90675;
        RateCard.Status = 'Active' ; 
       RateCard.SFXCode = 'SFX000006399';
      RateCard.assign_branch = BranchList ; 
        
        List<SFX_RATE_UpsertAPI.jsonWrapRATE> RateList = new List<SFX_RATE_UpsertAPI.jsonWrapRATE>();
        RateList.add(RateCard);
        
        
        SFX_RATE_UpsertAPI.jsonWrapOffering Service = new SFX_RATE_UpsertAPI.jsonWrapOffering();
        Service.Service_Offering = 'SURFACE';
        Service.Rate_card = RateList;
        
        List<SFX_RATE_UpsertAPI.jsonWrapOffering> ServiceList = new List<SFX_RATE_UpsertAPI.jsonWrapOffering>();  
         ServiceList.add(Service); 
        
        SFX_RATE_UpsertAPI.jsonWrapSFX sfx = new SFX_RATE_UpsertAPI.jsonWrapSFX(); 
       sfx.Propel_MSACode = 'MSA00000080';
       sfx.Propel_Key =  'ASFC123';
       sfx.Account_Id = Parent.id;
       sfx.SFXCode = 'SFX000006399';
       sfx.id = 09876;
       sfx.Contract_Sign_date = date.today();
       sfx.Contract_Start_date = date.today();
        sfx.Contract_Expiry_date = date.today();
        sfx.Direct_Pickup = 'False';
        sfx.Delivery_Hold = 'False';
       sfx.Status = 'Active';
        sfx.Business_Type = 'Credit'; 
         sfx.Service_line = 'Surface';
        sfx.Opportunity = objOpp1.id;
        sfx.CompSfxOffer = 'Test';             
       sfx.Offerings = ServiceList;
       sfx.Billing_Info = BillList;
        

     // RestContext.request = request;
    
        /* Test.startTest();
        SFX_RATE_UpsertAPI.createCustomer();
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        System.assert(testStr != null);
     */
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        req.requestUri ='/services/apexrest/InactiveSFX_RATECreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        String myJSON = JSON.serialize(sfx);
        req.requestBody = Blob.valueof(myJSON);
        SFX_RATE_UpsertAPI.createCustomer();
        Test.stopTest();
    }
}