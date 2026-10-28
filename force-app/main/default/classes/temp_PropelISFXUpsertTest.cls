@isTest
public class temp_PropelISFXUpsertTest {
 
    
    @isTest
    static void unit_PropelISFXUpsertAPI(){
        String rate_card_name = '';
        String Service_Offering = '';
        Integer idValue = 12;
        Date Sign_date = Date.Today();
        Date Start_date = Date.Today();
        Date End_date = Date.Today();
        Integer Base_location;
        String Status = '';
        String SFXCode = '';
        temp_PropelISFXUpsert.wrap_RateCard testRC = new temp_PropelISFXUpsert.wrap_RateCard(
            rate_card_name,  Service_Offering, idValue, 
            Sign_date, Start_date, End_date, Base_location, Status, SFXCode);
        
        Integer assign_branch_id;
        String MSA='';
        String Rate_Card='';
        Integer MDM_branch_id=123;
        Date Effective_date=Date.Today();
        String Booking_hold='';
        String delivery_hold='';
        Date expiry_date=Date.Today();
        String Booking_Hold_Reason='';
        String delivery_hold_reason='';
        
        temp_PropelISFXUpsert.wrap_Branches obj = new temp_PropelISFXUpsert.wrap_Branches( 123, 456, 'String MSA', 'String SFXCode', 
                                            'String Rate_Card', 'String Service_Offering', 876, 
                                            Date.today(), 'String Booking_hold', 'String delivery_hold',  
                                            Date.today(), 'String Booking_Hold_Reason', 'String delivery_hold_reason');
        
        
        temp_PropelISFXUpsert.warp_BillinglineItems obj1 = new temp_PropelISFXUpsert.warp_BillinglineItems('String RateCard', 'String MSA', 'String SFX', 'String Billing_level', 'String Billing_by_id', 123, 
                              432, 675,987, 'String Billing_address', 876,
                              'String Comm_bill_email', 576, 77 );
          
        temp_PropelISFXUpsert.warp_BillinglineItems obj2 = new temp_PropelISFXUpsert.warp_BillinglineItems(new temp_PropelISFXUpsert.jsonWrapBilling(), new temp_PropelISFXUpsert.wrapBillinglineItems());
    }
    
}