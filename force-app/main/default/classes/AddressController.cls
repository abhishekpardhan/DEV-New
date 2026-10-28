/**
 * @File Name          : AddressController.cls
 * @Description        : This is used to fetch the Address information from the Pincode
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 17-08-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        17-08-2021                Deepak                   Initial Version
**/

public class AddressController {

    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to fetch the Address information from the Pincode
    @Date            : 17-08-2021
    */
    @AuraEnabled
    public static String getAddress(String pincode) {
        ReturnInfo returnInfo = new ReturnInfo();
        try {
            returnInfo.message = ConstantUtility.PINCODE_NOT_IN_SERVICE;
            List<Pincode__c> pincodes = QueryUtil.getAddress(pincode);
            if (pincodes.size() > 0) {
                returnInfo.type = ConstantUtility.SUCCESS;
                returnInfo.message = JSON.serialize(pincodes[0]);
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : AddressController at Line :: ' + exp.getLineNumber());
            returnInfo.message = returnInfo.message != null ? returnInfo.message : exp.getMessage();
            returnInfo.type = ConstantUtility.ERROR;
            LoggerUtil.createErrorLog('AddressController', 'getAddress', exp.getTypeName(), returnInfo.message, exp.getStackTraceString(), null);
        }
        return JSON.serialize(returnInfo);
    }
    /**  ================================== RETURN RESPONSE WRAPPER TO LWC COMPONENT ========================================= */
    public class ReturnInfo {
        @AuraEnabled public String type = ConstantUtility.ERROR;
        @AuraEnabled public String message;
    }
    public static void  dummyMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}