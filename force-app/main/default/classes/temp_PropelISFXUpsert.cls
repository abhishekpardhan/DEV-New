/*********************************************************************************************
**Author: Safexpress.com
**Description: this is API is exposed to Propel-I system to upsert the SFX, Offering, Service Line, Rate Card, Branches and Billing Information. 
**JIRA Ticket: 
**Test Class:  
**History: 
**Modified Date:                  
**Description: 
**Modified By:
*************************************************************************************************** */

global with sharing class temp_PropelISFXUpsert extends ExceptionHandling.wrap_ErrorsHandling {
    
    global String message;  //Request Successfully completed
    public cls_data data;
    public String status;   //SUCCESS
    
    //Wrapper class to send the response in JSON format
    public class JsonUpsertResult {
        List<Database.Error> Errors;  
        String SFXId;
        // String RCId;
        Boolean isCreated;
        Boolean isSuccess;
    }
    public class cls_data {
        public jsonWrapSFX[] responseData;
        public cls_referenceData referenceData;
    }
    public class cls_referenceData {
    }
    //Wrapper class to parse the JSON
    global class jsonWrapSFX {
        public String Propel_MSACode;
        public String Propel_Key;
        public String Account_Id;
        public string Msa_name;
        public String SFXCode;
        public Integer id;
        public Date Contract_Sign_date;
        public Date Contract_Start_date;
        public Date Contract_Expiry_date;
        public String Direct_Pickup;
        public String Delivery_Hold;
        public String Status;
        public String Business_Type;
        public String Service_line;
        public String Opportunity;
        public String CompSfxOffer;             
        public List<jsonWrapOffering> Offerings;
        public List<jsonWrapBilling> Billing_Info;
    }
    
    // Set the response body.
    Global class APIResponse extends cls_APIResponse
    {
        List<Database.Error> Errors;
        Global  String BillingInformationId; 
        Global String  MSA;
        Global String SFX;
        Global  Date SF_CreatedDate; 
        Global  Date SF_LastModifiedDate;        
    }
    
    // Wrapper class for service offering. 
    global class jsonWrapOffering {
        public String Service_Offering;
        public list<jsonWrapRATE> Rate_card;
    }
    // Wrapper class for rate card. 
    global class jsonWrapRATE {
        public string rate_card_name;
        public Integer id;
        public Date Sign_date;
        public Date Start_date;
        public Date End_date;
        public Integer Base_location;
        public string Status; 
        public String SFXCode;
        public list<jsonWrapBranch> assign_branch; 
    }
    // Wrapper class for assigned bracnhes. 
    global class jsonWrapBranch {
        
        Public Integer MDM_branch_id;
        public Integer assign_branch_id;
        public Integer Billing_Branch; 
        public Integer Billing_State_id;
        public Integer Submission_branch;
        public Integer Collection_branch;
        public String BILLING_STREET;
        public String BILLING_CITY;
        public String BILLING_COUNTRY;
        public String BILLING_ZIP_POSTAL_CODE;
        public String BILLING_STATE;
        public Integer Minimum_Billing;
        public String E_Bill_id;
        public String Comm_bill_email;
        public String GST;
        public String TAN;
        // public String PAN;
        public String Multiple_Emails;
        public String GB_Category;
        public Integer Monthly_Potential;
        public String Credit_Risk; 
        public Date Effective_date;
        public Date expiry_date;
        public String Booking_hold;
        public String Booking_Hold_Reason;
        public String delivery_hold;
        public String delivery_hold_reason;         
    }
    
    // Wrapper class for billing level.
    global class jsonWrapBilling {
        public String Billing_Level;
        Public String Billing_type;
        public String SFX_no;
        Public String Rate_card_no;
        public String MSA;
        public Date Start_date;
        public String alias_name;
        public Date End_date;
        Public Integer Billing_config_id;
        Public String Status;
        Public List<wrapBillinglineItems> billing_by;
        
    }
    
    // Wrapper class for billing line items. 
    Global class wrapBillinglineItems{
        
        Public String Billing_by_id;// Unique field, used to upsert the record. 
        Public Integer Assign_billing_branch_id;
        Public String State_id;
        Public Integer Billing_Branch;
        Public Integer Submission_branch;
        Public Integer Collection_branch;
        Public String Billing_address;
        Public Integer Minimum_Billing;
        Public String Comm_bill_email;
        Public Integer Monthly_Potential;
        Public Integer Credit_Risk; 
        Public String Status;
    }    
    //Post request to create SFX customer within SFDC
    global static void createCustomer(String rr) 
    {
        system.debug('Request Body rr:' +rr);
        
        PropelISFXUpsert.updateCustomer(rr);
        
    }
    // Wrapper to bind the service accounts. 
    Class wrap_ServicesAccount
    {
        String Service_Offering; 
        String SFXCode;
        String MSA;
        wrap_ServicesAccount(String Service_Offering, String MSA, String SFXCode){
            this.Service_Offering = Service_Offering; 
            this.SFXCode = SFXCode;
            this.MSA = MSA;
            
        } 
    }
    // Wrapper class to bind the rate cards. 
    Global Class wrap_RateCard
    {
        String rate_card_name;
        String Service_Offering; 
        Integer id;
        Date Sign_date;
        Date Start_date;
        Date End_date;
        Integer Base_location;
        String Status; 
        String SFXCode; 
        Global wrap_RateCard(String rate_card_name, String Service_Offering, Integer id, Date Sign_date, Date Start_date, Date End_date, Integer Base_location, String Status, String SFXCode)
        {
            
            this.rate_card_name = rate_card_name;
            this.Service_Offering = Service_Offering;
            this.id =id;
            this.Sign_date =  Sign_date;
            this.Start_date = Start_date;
            this.End_date = End_date;
            this.Base_location = Base_location;
            this.Status = Status;
            this.SFXCode =SFXCode;
        }
    }
    // warpper to bind the rate card branches. 
    Global Class wrap_Branches{
        
        Integer assign_branch_id;
        String MSA;
        String SFXCode;
        String Rate_Card; 
        String Service_Offering;
        Integer id;
        Integer MDM_branch_id;
        Date Effective_date;
        String Booking_hold;
        String delivery_hold;
        Date expiry_date;
        String Booking_Hold_Reason;
        String delivery_hold_reason;
        String Status;
        Global wrap_Branches(Integer id, Integer assign_branch_id, String MSA, String SFXCode, String Rate_Card, String Service_Offering, Integer MDM_branch_id, Date Effective_date, String Booking_hold, String delivery_hold,  Date expiry_date, String Booking_Hold_Reason, String delivery_hold_reason)
        {
            this.id = id;
            this.assign_branch_id = assign_branch_id;
            this.MSA = MSA;
            this.SFXCode = SFXCode;
            this.Rate_Card = Rate_Card;
            this.Service_Offering =Service_Offering;
            this.MDM_branch_id = MDM_branch_id; 
            this.Effective_date = Effective_date;
            this.Booking_hold = Booking_hold;
            this.delivery_hold = delivery_hold;
            this.expiry_date = expiry_date ;
            this.Booking_Hold_Reason = Booking_Hold_Reason;
            this.delivery_hold_reason = delivery_hold_reason;
            
        }
        
        
    }
    // Billing line item wrapper to upsert the records. 
    public class warp_BillinglineItems
    {
        String MSA;
        String SFX;
        String Billing_level;
        String RateCard;
        String Billing_by_id;// Unique field, used to upsert the record. 
        Integer Assign_billing_branch_id;
        String State_id;
        Integer Billing_Branch;
        Integer Submission_branch;
        Integer Collection_branch;
        String Billing_address;
        Integer Minimum_Billing;
        String Comm_bill_email;
        Integer Monthly_Potential;
        Integer Credit_Risk;
        String Status;
        public warp_BillinglineItems(String RateCard, String MSA, String SFX, String Billing_level, String Billing_by_id, Integer Assign_billing_branch_id, 
                              Integer Billing_Branch, Integer Submission_branch,Integer Collection_branch, String Billing_address, Integer Minimum_Billing,
                              String Comm_bill_email, Integer Monthly_Potential, Integer Credit_Risk )
            
        {
            this.RateCard  = RateCard;
            this.MSA = MSA;
            this.SFX = SFX;
            this.Billing_level = Billing_level;
            this.Billing_by_id = Billing_by_id;
            this.Assign_billing_branch_id = Assign_billing_branch_id;
            this.State_id = State_id;
            this.Billing_Branch = Billing_Branch;
            this.Submission_branch = Submission_branch;
            this.Collection_branch = Collection_branch;
            this.Billing_address = Billing_address;
            this.Minimum_Billing = Minimum_Billing;
            this.Comm_bill_email = Comm_bill_email;
            this.Monthly_Potential = Monthly_Potential;
            this.Credit_Risk = Credit_Risk;
        }
                 
        public warp_BillinglineItems(jsonWrapBilling eachBillingInfo, wrapBillinglineItems eachBillingLineItem){
            
            this.RateCard  = eachBillingInfo.Rate_card_no;
            this.MSA = eachBillingInfo.MSA;
            this.SFX = eachBillingInfo.SFX_no;
            this.Billing_level = eachBillingInfo.Billing_Level;
            this.Billing_by_id = eachBillingLineItem.Billing_by_id;
            this.Assign_billing_branch_id = eachBillingLineItem.Assign_billing_branch_id;
            this.State_id = eachBillingLineItem.State_id;
            this.Billing_Branch = eachBillingLineItem.Billing_Branch;
            this.Submission_branch = eachBillingLineItem.Submission_branch;
            this.Collection_branch = eachBillingLineItem.Collection_branch;
            this.Billing_address = eachBillingLineItem.Billing_address;
            this.Minimum_Billing = eachBillingLineItem.Minimum_Billing;
            this.Comm_bill_email = eachBillingLineItem.Comm_bill_email;
            this.Monthly_Potential = eachBillingLineItem.Monthly_Potential;
            this.Credit_Risk = eachBillingLineItem.Credit_Risk;
            this.Status = eachBillingLineItem.Status;
        }
        
    }
}