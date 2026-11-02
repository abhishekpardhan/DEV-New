/**
 * @File Name          : ConstantUtility.cls
 * @Description        : This class will have all the constants defined to be used in various other classes
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Rudra Singh
 * @Last Modified On   : 22-12-2025
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        07-07-2021                Deepak                   Initial Version
* 2.0        22-12-2025                Rudra Singh              SAC-2154
**/


public class ConstantUtility {

    // HTTP VARIABLES
    public static final Integer CALLOUT_TIME_OUT_IN_MS = 60000;
    public static final String GET = 'GET';
    public static final String POST = 'POST';
    public static final String APPLICATION_JSON = 'application/json';
    public static final String INCOMPLETE_API_INFO_MESSAGE = 'API configuration is invalid. Please Contact Your System Administrator.';
    public static final String GETTING_ERROR_FROM_API = 'Getting Error from the API. Please Contact Your System Administrator.';
    public static final String SOME_WENT_WRONG_MESSAGE = 'Something went wrong. Please Contact Your System Administrator.';
    public static final String INVALID_REQUEST_BODY = 'Invalid Request body or required field(s) missing';
    public static final String INVALID_ACCESS_TOKEN_ERROR = 'Invalid Access token or error from API, Please Contact Your System Administrator.';

    //API NAME VARIABLES
    public static final String WAY_BILL_API_NAME = 'WayBill';
    public static final String SNSD_URL_API_NAME = 'SNSD URL';
    public static final String INVOICE_URL_API_NAME = 'INVOICE URL';
    public static final String OTRS_CREATE_TICKET_API_NAME = 'OTRS Create Ticket';
    public static final String OTRS_TICKET_DETAIL_API_NAME = 'OTRS Ticket Detail';
    public static final String OTRS_ARTICLE_UPDATE_API_NAME = 'OTRS Article Update';
    public static final String PROPEL_PRE_BOOKING_API_NAME = 'Propel_Pre_Booking_Create';
    public static final String PROTON_PRE_BOOKING_API_NAME = 'Proron_Pre_Booking_Create';
    public static final String PROTON_PRE_BOOKING_UPDATE_API_NAME = 'Proron_Pre_Booking_Update';
    public static final String PROPEL_PRE_BOOKING_API_TOKEN_NAME = 'API_Token'; 
    public static final String PROTON_PRE_BOOKING_API_TOKEN_NAME = 'Proton_API_Token';
    public static final String CHANGE_CASE_STATUS_TO_CANCEL_API = 'Cancel case status Ticket';


    public static final String CASE_TRIGGER_HANDLER = 'CaseTriggerHandler';
    public static final String OTRS_TICKET_NOT_FOUND = 'Ticket Number Not Found on Case.';
    public static final String NO_RECORD_FOUND = 'No record found.';
    public static final String CANCELLED_TASK_REMARKS = 'The invoice against this task has been Cancelled';


    public static final String COMPLETED = 'Completed';
    public static final String SUBMITTED = 'Submitted';
    public static final String ACTIVE = 'Active';
    public static final String COLLECTED = 'Collected';
    public static final String PARTLY_COLLECTED = 'Partly Collected';
    public static final String SUCCESS = 'SUCCESS';
    public static final String ERROR = 'ERROR';
    public static final String INVALID_CASE_ID = 'Invalid Case Id';
    public static final String OPEN = 'Open';
    public static final String CLOSED = 'Closed';
    public static final String CANCELLED = 'Cancelled';
    public static final String PINCODE_NOT_IN_SERVICE = 'Sorry, This Pincode is not in service.';
    public static final String CHANGE_REQUEST = 'Change Request';
    public static final String CASE_TYPE_POD = 'POD';
    public static final String CASE_TYPE_BOOKING_REQUEST = 'Booking Request';
    public static final String CASE_TYPE_SERVICE_ISSUE = 'Service Issue';
    public static final String CASE_TYPE_FEEDBACK = 'Feedback';
    public static final String CASE_TYPE_ESCALATION = 'Escalation';
    public static final String CASE_TYPE_FREIGHT_DISPUTE = 'Freight Dispute';
    public static final String CASE_TYPE_PICKUP_ISSUE = 'Pickup Issue';
    public static final String CASE_TYPE_B2B = 'Business Enquiry (B2B)';
    public static final String CASE_TYPE_BUSINESS_REQUEST = 'Booking Request';
    public static final String CASE_NATURE_COMPLAINT = 'Complaint';
    public static final String CASE_NATURE_ENQUIRY = 'Enquiry';
    public static final String CASE_NATURE_REQUEST = 'Request';
    public static final String SUB_TYPE_RETAIL = 'Retail';
    public static final String LEAD_SOURCE_SAFEXPERIENCE = 'Safexperience Centre';
    public static final String LEAD_STATUS_ACTIVE = 'Active';
    public static final String LEAD_TYPE_CREDIT_RETAIL = 'CREDIT+RETAIL';
    public static final String CONTACT_DEFAULT_LASTNAME = 'Unknown';
    public static final String ORIGIN_WHATS_APP = 'WhatsApp';
    public static final String CREDIT = 'Credit';
    public static final String CREDIT_NOTE = 'Credit Note';
    public static final String CREDIT_DEBIT_NOTE = 'Credit_Debit_Note';
    public static final String POD_CREDIT = 'POD Credit';
    public static final String POD_RETAIL = 'POD Retail';
    public static final String NEW_STATUS = 'New';
    public static final String CLAIM_ISSUES = 'Claim Issues';
    public static final String REQUIRED_FIELD_MISSING = 'Required fields missing';
    public static final String INCOMPLETE_BOOKING_INFORMATION = 'Required fields are missing to create booking request';
    public static final String WAYBILL_NUMBER_MISSING = 'Waybill Number is missing';
    public static final String BOOKING_CREATED = '900082';
    public static final String BOOKING_CANCEL = '900086';
    public static final String BOOKING_ASSIGNED = '900083';
    public static final String OTRS_STATUS_CLOSE = 'Closed';	


    public static final String BUSINESS_TYPE_CREDIT_INBOUND = 'Credit-Inbound';
    public static final String BUSINESS_TYPE_CREDIT_OUTBOUND = 'Credit-Outbound';
    public static final String BUSINESS_TYPE_RETAIL_NON_PRC = 'RETAIL-NON PRC';
    public static final String BUSINESS_TYPE_RETAIL_WITH_PRC = 'Retail-WITH PRC';
    public static final String  HOLD_TASK_SUBJECT_PREFIX = 'Code Blocked || ';
    public static final String HOLD_ROLE_RC  = 'RC';
    public static final String HOLD_ROLE_NAM = 'NAM';
    public static final String BUSINESS_TYPE_RETAIL_INBOUND_WITH_PRC = 'Retail-Inbound With PRC';


    public static final String DUPLICATE_CASE_FOUND = 'We have found an open case with parameters you have send and case number mentioned in the response';
    public static final String CASE_CREATED_SUCCESS = 'Case Created Successfully';
    public static final String CASE_UPDATED_SUCCESS = 'Case Updated Successfully';
    public static final String UPDATE_FAILED = 'Update Failed';


    public static final String SUB_TYPE_PILFERRED = 'Pilferred';
    public static final String SUB_TYPE_SHORT_PART_SHIPMENT = 'Short / Part Shipment';
    public static final String SUB_TYPE_WRONG_DELIVERY = 'Wrong Delivery';
    public static final String SUB_TYPE_DELIVERY_NOT_DONE = 'Delivery Not Done';
    public static final String SUB_TYPE_INTERCHANGE = 'Interchange';
    public static final String SUB_TYPE_DELAY_IN_DELIVERY = 'Delay In Delivery';
    public static final String SUB_TYPE_DAMAGE = 'Damage';
    public static final String SUB_TYPE_ADDRESS_CHANGE = 'Address Change';
    public static final String SUB_TYPE_SHIPMENT_ON_HOLD = 'Shipment On Hold';
    public static final String SUB_TYPE_DOD_DACC_CANCELLATION = 'DOD_DOC Cancellation';
    public static final String SUB_TYPE_SHIPMENT_RE_BOOKING = 'Shipment Re-Booking';
    
    
    //Lead Constants
    public static final String LEAD_DROP_APPROVAL_PROCESS_NAME = 'Lead_Drop_Approval';
    public static final String PERMISSION_ERROR = 'You don\'t have permission to revive leads.';
    public static final String INELIGIBLE_ERROR = 'Only an approved Dropped lead or a Dropped by Central Desk lead can be revived.';
    public static final String SUCCESS_MESSAGE = 'Lead revived.';
    public static final String NOT_FOUND_ERROR = 'Lead not found or you do not have access to it.';
    public static final String INVALID_ID_ERROR = 'A valid Lead Id is required.';
    public static final String LEAD_REVIVE = 'Lead_Revive';
    public static final String REVIVE_LEAD = 'Revive Lead';
    public static final String LEAD_DUPLICATE_EXEMPTION = 'Lead_Duplicate_Exemption';
    public static final String DUPLICATE_PAN_ERROR_MESSAGE_PREFIX ='A Lead or Account already exists with the same PAN ' + '(derived from GST number): ';
    public static final String PROSPECT_CUSTOMER_RT = 'Prospect_Customer';
    public static final String SFX_CUSTOMER_RT = 'SFX_Customer';
    


    public static final String SUB_TYPE_Retail_PRC = 'Retail- PRC';
    public static final String SUB_TYPE_Retail_Non_PRC = 'Retail-Non-PRC';
    public static final String SUB_TYPE_Retail_C2H = 'Retail- C2H';
    public static final String SUB_TYPE_Retail_E2M = 'Retail- E2M';
    public static final String SUB_TYPE_Retail_Sanik_Express = 'Retail- Sanik Express';
    public static final String SUB_TYPE_Credit_Outbound = 'Credit- Outbound';
    public static final String SUB_TYPE_Reverse_Inbound_Credit = 'Reverse Inbound- Credit';
    public static final String SUB_TYPE_Reverse_Inbound_Retail_Non_PRC = 'Reverse Inbound- Retail-Non-PRC';
    public static final String SUB_TYPE_Reverse_Inbound_Retail_PRC = 'Reverse Inbound- Retail-PRC';



    public static final String MAIN_CATEGORY_CUSTOMER_ESCALATION = 'CustomerEscalation';
    
    public static final String MAIN_CATEGORY_CUSTOMER_ESCALATION_POST_DELIVERY = 'PostDeliveryEscalation';
     public static final String PROSPECT_CUSTOMER_RECORD_TYPE_DEVELOPERNAME= 'MSA';
     public static final String SFX_RECORD_TYPE_DEVELOPERNAME= 'SFX';

    public static final String SUB_CATEGORY_SPECIAL_DELIVERY_REQUEST = 'SpecialDeliveryRequest';
    public static final String SUB_CATEGORY_DELIVERY_PROCESS_REQUEST = 'DeliveryProcessRequest';
    public static final String SUB_CATEGORY_WAYBILL_ESCALATION = 'WaybillEscalation';

    public static final String ISSUE_TYPE_ADDRESS_CHANGE = 'AddressChange';
    public static final String ISSUE_TYPE_DOD_CANCELLATION = 'DODCancellation';
    public static final String ISSUE_TYPE_RE_BOOKING = 'Rebooking';
    public static final String ISSUE_TYPE_AT_GATEWAY = 'AtGateway';
    public static final String ISSUE_TYPE_OPEN_DELIVERY = 'OpenDelivery';
    public static final String ISSUE_TYPE_WRONG_DELIVERY = 'WrongDelivery';
    public static final String ISSUE_TYPE_IN_TRANSIT = 'InTransit';
    //SAC-1363 -Start
    public static final String Profile_Regional_Manager = 'Regional Manager';
    public static final String Rejected = 'Rejected';
    public static final String Dropped = 'Dropped';
    public static final String Pending_For_Approval = 'Pending for Approval';
    public static final String Dropped_By_Central_Desk ='Dropped by Central desk';
    public static final String Approved = 'Approved';
    Public Static Id CREDIT_LEAD_RECORDTYPE_ID =  Lead__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Credit_Lead').getRecordTypeId();
    Public Static Id RETAIL_LEAD_RECORDTYPE_ID =  Lead__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Retail_Lead').getRecordTypeId();
    public static final String Lead_Type_Retail ='Retail';
    public static final String Lead_Type_3PL ='3PL';
    public static final String CREDIT_RETAIL ='CREDIT+RETAIL';
    public static final String FTL ='FTL';
    public static final String Lead_Type_Trans_3PL ='Transportation+3PL';
    public static final String Approval_Status_Central_Team ='Reassign to Central Team';
    public static final String Approval_Status_Central_Team_BDM ='Reassign to BDM';
    public static final String Lead_Queue_Credit ='Lead_Central_Team_Credit';
    public static final String Lead_Queue_Retail ='Lead_Central_Team_Retail';
    public static final String Lead_Queue_3PL ='Lead_Central_Team_3PL';
    public static final String Closed_Won ='Closed Won';
    public static final String Closed_Lost ='Closed Lost';
    public static final String Submit_Approval_Status ='Submitted for Approval';
    public static final String RM_Approval_Status ='Pending from RM';
    public static final String Corporate_Approval_Status ='Pending from Corporate Head Credit/Retail';
    public static final String Regional_Approval_Status ='Pending with Regional Retail Head';
    //SAC-1363 -End
     
    public static final String Account_RTname_Prospect ='Prospect Customer'; //SAC-1457
    public static final String Billing_Level_SFX ='SFX'; //SAC-1550
    public static final String Billing_Level_RC ='RATE Card'; //SAC-1550
    
    public static MAP<String, String> TIME_SLOT_MAP = new map<string, string>{
            '08:00 AM - 10:00 AM' => '10:00:00',
            '10:00 AM - 12:00 PM' => '12:00:00',
            '12:00 PM - 02:00 PM' => '14:00:00',
            '02:00 PM - 04:00 PM' => '16:00:00',
            '04:00 PM - 06:00 PM' => '18:00:00',
            '06:00 PM - 08 :00 PM' => '20:00:00'
    };
    public static MAP<String, String> SERIAL_TIME_SLOT_MAP = new map<string, string>{
            '1' => '08:00 AM - 10:00 AM',
            '2' => '10:00 AM - 12:00 PM',
            '3' => '12:00 PM - 02:00 PM',
            '4' => '02:00 PM - 04:00 PM',
            '5' => '04:00 PM - 06:00 PM',
            '6' => '06:00 PM - 08 :00 PM'
    };
        
    public static MAP<String, String> SERIAL_TIME_SLOT_MAP_NEW = new map<string, string>{
            'for 08:00 AM - 10:00 AM' =>'1' ,
            'for 10:00 AM - 12:00 PM' =>'2',
            'for 12:00 PM - 02:00 PM'=>'3' ,
            'for 02:00 PM - 04:00 PM'=>'4',
            'for 04:00 PM - 06:00 PM' =>'5',
            'for 06:00 PM - 08 :00 PM'=>'6'
    };
   Public Static Id BOOKING_REQUEST_SUPPORT_CASE_RECORDTYPE_ID =  case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking_Request').getRecordTypeId();
   Public Static Id ENQUIRY_SUPPORT_CASE_RECORDTYPE_ID =  case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Enquiry').getRecordTypeId();
   Public Static Id TASK_ONBOARDING_RECORDTYPE_ID =  TASK.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Closed_Task_Record_Type').getRecordTypeId();
   Public Static Id TASK_GENERAL_RECORDTYPE_ID =  TASK.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('General').getRecordTypeId();
   Public Static Id TASK_COLLECTION_RECORDTYPE_ID =  TASK.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Collection').getRecordTypeId();
   Public Static Id TASK_CUSTOMER_RELATIONSHIP_PROFILING_TASK_ID =  TASK.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Customer_Relationship_Profiling_Tasks').getRecordTypeId();
   public static Id CONTRACT_CLOSED_RECORDTYPE_ID = Contract__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Closed').getRecordTypeId();
   
   public static final Integer REMINDER_DAY_90 = 90;
   public static final Integer REMINDER_DAY_60 = 60;
   public static final Integer REMINDER_DAY_30 = 30;
   public static final String TASK_SUBJECT_60 = '60 Day Reminder';
   public static final String TASK_SUBJECT_30 = '30 Day Reminder';
   public static final String TASK_STATUS_OPEN = 'Open';
   public static final String EMAIL_TEMPLATE_DEV_NAME = 'Contract_Renewal_Template';
   public static final String ERROR_NO_BDM ='No BDM found for Account: ';
   public static final String ERROR_CONTEXT = 'ContractRenewalService';    
   public static final String CASE_STATUS_REJECTED = 'Rejected';
   public static final String CONTRACT_FROM_EMAIL = 'noreply@safexpress.com';
   
   public static final String CASE_TYPE_WAYBILL_ENQUIRY = 'Waybill Enquiry';
   public static final String CASE_SUB_TYPE_OTHERS = 'Others';
   public static final String CASE_ORIGIN_ENTERPRISE_APP = 'ENTERPRISE APP';

    public static Id getProfileIdByName(String profileName) {
        
           List<Profile> ProfileRecord = [SELECT Id, Name FROM Profile where Name =:profileName];
           return ProfileRecord[0].Id;
        
    }

    // This method checks if the given profileId belongs to System Administrator, Corporate Salesforce Team, or Read Only profile.
    public static Boolean isAdminCorporateSalesforceTeamOrReadOnly(Id profileId) {
        List<Profile> profiles = [SELECT Name FROM Profile WHERE Id =: profileId];
        if (!profiles.isEmpty()) {
            String profileName = profiles[0].Name;
            return (profileName == 'System Administrator' || profileName == 'Corporate salesforce team' || profileName == 'Read Only');
        }
        return false;
    }
  
}