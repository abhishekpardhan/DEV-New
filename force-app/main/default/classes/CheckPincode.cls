/**
 * @File Name          : CheckPincode.cls
 * @Description        : This class is a used to get the entered pincode is in service or not for pickup in the chat bot.
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 07-12-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        07-12-2021               Deepak                   Initial Version
**/
public without sharing class CheckPincode {

    public class PincodeInput {
        @InvocableVariable
        public String pincode;

        @InvocableVariable
        public String countString;
    }

    public class Output {
        @InvocableVariable public String pincode;
        @InvocableVariable public String city;
        @InvocableVariable public String district;
        @InvocableVariable public String state;
        @InvocableVariable public String countString;
    }
    @InvocableMethod(label='Check Pincode In Database')
    public static List<Output> checkPinCode(List<PincodeInput> pincodeInputs) {
        try {
            Integer countInteger = 1 ;
            String pincode;
            List<Output> outputStrings = new List<Output>();
            Output outputObj = new Output();
            for (PincodeInput pincodeInput : pincodeInputs) {
                if (pincodeInput.countString == null) {
                    countInteger = 1;
                } else {
                    countInteger = Integer.valueOf(pincodeInput.countString) + 1;
                }
                List<Pincode__c> pincodes = [SELECT Pincode__c,City__c,District__c,State__c FROM Pincode__c WHERE Pincode__c = :pincodeInput.pincode LIMIT 1];
                if (pincodes.size() > 0) {
                    outputObj.pincode = pincodes[0].Pincode__c;
                    outputObj.city = pincodes[0].City__c;
                    outputObj.district = pincodes[0].District__c;
                    outputObj.state = pincodes[0].State__c;
                }
                outputObj.countString = String.valueOf(countInteger);
                outputStrings.add(outputObj);
                break;
            }
            return outputStrings;
        }catch (Exception exp){
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CheckPincode at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CheckPincode', 'checkPinCode', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        return null;
    }
}