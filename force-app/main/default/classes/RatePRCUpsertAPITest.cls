@IsTest
public class RatePRCUpsertAPITest {
static testMethod void testPostMethod()
    {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/PRCCreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        Account Parent = CommonDataTest.getParentAccount();
        Opportunity__c Oppo = CommonDataTest.getOpportunity();
        
        RatePRCUpsertAPI.jsonWrapBranch Branch = new RatePRCUpsertAPI.jsonWrapBranch();
        Branch.branch_id = 12345;
      //  Branch.Billing_Branch = 123456; 
    //    Branch.Billing_State_id = 1234567;
    //    Branch.Submission_branch = 1234567;
    //    Branch.Collection_branch = 126456;
    //    Branch.BILLING_STREET = 'Test Address';
    //    Branch.BILLING_CITY = 'Test City';
    //    Branch.BILLING_COUNTRY = 'Test Country';
      //  Branch.BILLING_ZIP_POSTAL_CODE = '136027';
    //    Branch.BILLING_STATE = 'Test State';
    //    Branch.Minimum_Billing = 200;
     //   Branch.E_Bill_id = 'Test@gmail.com';
//        Branch.Comm_bill_email = 'Test1@gmail.com';
        Branch.gst_num = 'ABCD1111BDW';
        Branch.tan_num = 'AXSCD1234CD';
       // public String PAN;
    //    Branch.Multiple_Emails = 'TRUE';
   //     Branch.GB_Category = 'TEST';
    //    Branch.Monthly_Potential = 900;
//        Branch.Credit_Risk = 'NUN'; 
     //   Branch.effective_date = '12/10/2020';
     //   Branch.expiry_date = '12/10/2021';
        Branch.Booking_hold = 'Nun';
       Branch.Booking_Hold_Reason = 'No Reason';
        Branch.delivery_hold = 'Test Hold';
        Branch.delivery_hold_reason = 'Test Reason';
        
         List<RatePRCUpsertAPI.jsonWrapBranch> BranchList = new List<RatePRCUpsertAPI.jsonWrapBranch>(); 
        BranchList.add(Branch);
        
        RatePRCUpsertAPI.jsonWrapRateEntity RateCard = new RatePRCUpsertAPI.jsonWrapRateEntity();
        RateCard.entity_name = 'RC-0003';
        RateCard.id = 1234;
        RateCard.Sign_date = date.today();
        RateCard.Start_date = date.today();
        RateCard.End_date = date.today();
        RateCard.Base_location = 90675;
        RateCard.Status = 'Active' ; 
    //   RateCard.SFXCode = 'ABCD123';
      RateCard.assign_branch = BranchList ; 
        
        List<RatePRCUpsertAPI.jsonWrapRateEntity> RateList = new List<RatePRCUpsertAPI.jsonWrapRateEntity>();
        RateList.add(RateCard);
        
        RatePRCUpsertAPI.jsonWrapOffering Service = new RatePRCUpsertAPI.jsonWrapOffering();
        Service.Service_Offering = 'SURFACE';
        Service.prc_ratecard_entity = RateList;
        
        List<RatePRCUpsertAPI.jsonWrapOffering> ServiceList = new List<RatePRCUpsertAPI.jsonWrapOffering>();  
         ServiceList.add(Service); 
        
        RatePRCUpsertAPI.jsonWrapPRC sfx = new RatePRCUpsertAPI.jsonWrapPRC(); 
        sfx.Propel_MSACode = 'ABCD1234';
       sfx.Propel_Key =  'ASFC123';
        sfx.Msa_name = 'Test Data';
        sfx.Account_Id = Parent.id;
       sfx.prcCode = 'ASCD1234';
        sfx.id = 098764;
        sfx.Contract_Sign_date = date.today();
        sfx.Contract_Start_date = date.today();
        sfx.Contract_Expiry_date = date.today();
  //      sfx.Direct_Pickup = 'False';
        sfx.Delivery_Hold = 'False';
       sfx.Rate_card_applicable = 'Active';
    sfx.Business_Type = 'Credit'; 
     sfx.Service_line = 'Surface';
        sfx.Opportunity = Oppo.id;
  //      sfx.CompSfxOffer = 'Test';             
       sfx.Offerings = ServiceList;
   //    sfx.Billing_Info = BillList;

         String myJSON = JSON.serialize(sfx);
     system.debug('@@@@@@@@@@@@'+ myJSON);
           req.requestBody = Blob.valueof(myJSON);

        RatePRCUpsertAPI.createCustomer();
    }
}