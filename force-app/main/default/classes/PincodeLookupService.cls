/**
 * Looks up Pincode__c for the booking form (live) and the booking actions.
 * WITHOUT sharing on purpose: Pincode__c is public reference data and the chat form
 * runs as the site guest user. Only city, district and state are returned.
 * Status: SERVICEABLE | NOT_SERVICEABLE | INVALID_FORMAT | ERROR
 */
public without sharing class PincodeLookupService {

    public class PincodeResult {
        @AuraEnabled public String status;
        @AuraEnabled public String pincode;
        @AuraEnabled public String city;
        @AuraEnabled public String district;
        @AuraEnabled public String state;

        public String locationLabel() {
            List<String> parts = new List<String>();
            for (String p : new List<String>{ city, district, state }) {
                if (String.isNotBlank(p) && !parts.contains(p)) parts.add(p);
            }
            return String.join(parts, ', ');
        }
    }

    @AuraEnabled(cacheable=true)
    public static PincodeResult lookupPincode(String pincode) {
        return checkAll(new Set<String>{ pincode == null ? '' : pincode.replaceAll('\\s+', '') })
            .values()[0];
    }

    public static Map<String, PincodeResult> checkAll(Set<String> pincodes) {
        Map<String, PincodeResult> results = new Map<String, PincodeResult>();
        Set<String> wellFormed = new Set<String>();

        for (String pin : pincodes) {
            PincodeResult r = new PincodeResult();
            r.pincode = pin;
            if (BookingRequestValidator.validatePincodeFormat(pin).valid) {
                wellFormed.add(pin);
                r.status = 'NOT_SERVICEABLE';
            } else {
                r.status = 'INVALID_FORMAT';
            }
            results.put(pin, r);
        }
        if (wellFormed.isEmpty()) return results;

        try {
            for (Pincode__c rec : [
                SELECT Pincode__c, City__c, District__c, State__c
                FROM Pincode__c
                WHERE Pincode__c IN :wellFormed
            ]) {
                PincodeResult r = results.get(rec.Pincode__c);
                if (r == null || !isServiceable(rec)) continue;
                r.status = 'SERVICEABLE';
                r.city = rec.City__c;
                r.district = rec.District__c;
                r.state = rec.State__c;
            }
        } catch (Exception e) {
            for (String pin : wellFormed) results.get(pin).status = 'ERROR';
        }
        return results;
    }

    /** Align this with the rule inside AgentforcePincodeCheck. */
    @TestVisible
    private static Boolean isServiceable(Pincode__c rec) {
        return rec != null;
    }
}