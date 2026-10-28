/**
 * @File Name          : AgentforcePincodeCheck.cls
 * @Description        : Agentforce action used by the Business Enquiry topic. Validates the
 *                       pincode format (exactly 6 digits, numeric only) and checks whether the
 *                       pincode is serviceable using the Pincode__c object. Returns the city,
 *                       district and state for serviceable pincodes, plus a Location Card
 *                       that is shown to the customer as a map card in the chat.
 * @Author             :
 * @Group              :
 * @Last Modified On   : 09-10-2026
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0        29-09-2026                                          Initial Version
 * 1.1        09-10-2026                                          Added Location Card output for map card
 **/
public without sharing class AgentforcePincodeCheck {

    public static final String STATUS_SERVICEABLE     = 'SERVICEABLE';
    public static final String STATUS_NOT_SERVICEABLE = 'NOT_SERVICEABLE';
    public static final String STATUS_INVALID_FORMAT  = 'INVALID_FORMAT';
    public static final String STATUS_ERROR           = 'ERROR';

    public class PincodeInput {
        @InvocableVariable(
            label='Pincode'
            description='The pincode shared by the customer, exactly as entered.'
            required=true)
        public String pincode;
    }

    public class Output {
        @InvocableVariable(
            label='Pincode Status'
            description='Result of the pincode check. SERVICEABLE = valid 6-digit pincode where service is available. INVALID_FORMAT = not exactly 6 digits or contains non-numeric characters. NOT_SERVICEABLE = valid format but service is not available. ERROR = the check could not be completed.')
        public String pincodeStatus;

        @InvocableVariable(
            label='City'
            description='City of the pincode. Populated only when Pincode Status is SERVICEABLE.')
        public String city;

        @InvocableVariable(
            label='District'
            description='District of the pincode. Populated only when Pincode Status is SERVICEABLE.')
        public String district;

        @InvocableVariable(
            label='State'
            description='State of the pincode. Populated only when Pincode Status is SERVICEABLE.')
        public String state;

        @InvocableVariable(
            label='Location Card'
            description='Location details shown to the customer as a map card. Populated only when Pincode Status is SERVICEABLE.')
        public AgentforcePincodeLocationCard locationCard;
    }

    @InvocableMethod(
        label='Check Pincode Serviceability'
        description='Checks whether the pincode shared by the customer is a valid 6-digit numeric pincode and whether service is available in it. Returns the pincode status and, for serviceable pincodes, the city, district and state.')
    public static List<Output> checkPinCode(List<PincodeInput> pincodeInputs) {
        List<Output> outputs = new List<Output>();
        try {
            // Collect the valid-format pincodes so that only one SOQL query is run
            Set<String> validPincodes = new Set<String>();
            for (PincodeInput pincodeInput : pincodeInputs) {
                String pincode = cleanPincode(pincodeInput.pincode);
                if (isValidFormat(pincode)) {
                    validPincodes.add(pincode);
                }
            }

            Map<String, Pincode__c> pincodeMap = new Map<String, Pincode__c>();
            if (!validPincodes.isEmpty()) {
                for (Pincode__c pincodeRecord : [SELECT Pincode__c, City__c, District__c, State__c
                                                 FROM Pincode__c
                                                 WHERE Pincode__c IN :validPincodes]) {
                    pincodeMap.put(pincodeRecord.Pincode__c, pincodeRecord);
                }
            }

            // One output per input, in the same order (required for invocable methods)
            for (PincodeInput pincodeInput : pincodeInputs) {
                String pincode = cleanPincode(pincodeInput.pincode);
                Output outputObj = new Output();
                if (!isValidFormat(pincode)) {
                    outputObj.pincodeStatus = STATUS_INVALID_FORMAT;
                } else if (pincodeMap.containsKey(pincode)) {
                    Pincode__c pincodeRecord = pincodeMap.get(pincode);
                    outputObj.pincodeStatus = STATUS_SERVICEABLE;
                    outputObj.city = pincodeRecord.City__c;
                    outputObj.district = pincodeRecord.District__c;
                    outputObj.state = pincodeRecord.State__c;

                    // Data for the map card shown to the customer
                    AgentforcePincodeLocationCard card = new AgentforcePincodeLocationCard();
                    card.city     = pincodeRecord.City__c;
                    card.district = pincodeRecord.District__c;
                    card.state    = pincodeRecord.State__c;
                    card.pincode  = pincode;
                    outputObj.locationCard = card;
                } else {
                    outputObj.pincodeStatus = STATUS_NOT_SERVICEABLE;
                }
                outputs.add(outputObj);
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : AgentforcePincodeCheck at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('AgentforcePincodeCheck', 'checkPinCode', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
            outputs.clear();
            for (Integer i = 0; i < pincodeInputs.size(); i++) {
                Output errorOutput = new Output();
                errorOutput.pincodeStatus = STATUS_ERROR;
                outputs.add(errorOutput);
            }
        }
        return outputs;
    }

    private static String cleanPincode(String pincode) {
        return pincode == null ? null : pincode.trim();
    }

    private static Boolean isValidFormat(String pincode) {
        return String.isNotBlank(pincode) && Pattern.matches('^[0-9]{6}$', pincode);
    }
}