/**
    @Description        : This class will used to Feting the Pincode Information And Update in Pincode Object
    * @Author             : Deepak
    * @Group              : Techmatrix
    * @Last Modified By   : Deepak
    * @Last Modified On   : 23/09/2021
    * @Modification Log   :
    *==============================================================================
    * Ver         Date                     Author                    Modification
    *==============================================================================
    * 1.0        23/09/2021                Deepak                   Initial Version
**/

global class PincodeInfoBatch implements Database.Batchable<Integer>, Database.AllowsCallouts {

    global static PinCode_API__c pinCodeApi = PinCode_API__c.getOrgDefaults();

    global Iterable<Integer> start(Database.BatchableContext bc) {
        List<Integer> stateIds = new List<Integer>();
        if (pinCodeApi.Max_StateId__c != null) {
            for (Integer i = 1; i <= Integer.valueOf(pinCodeApi.Max_StateId__c); i++) {
                stateIds.add(i);
            }
        }
        return stateIds;
    }
    global void execute(Database.BatchableContext bc, List<Integer> stateCode) {
        try {
            if (stateCode.size() == 1) {
                String response = getAddressInfo(String.valueOf(stateCode[0]));
                updatePinCodeCodes(response);
            }
        } catch (Exception exp) {
            System.debug('Exception Message :: ' + exp.getMessage() + ' AT ' + exp.getStackTraceString());
            LoggerUtil.createErrorLog('PincodeInfoBatch', 'execute', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    global void finish(Database.BatchableContext bc) {

    }


    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to create the request and and send to the api and return the response
    @Date            : 23/09/2021
    */
    public static String getAddressInfo(String stateId) {
        String endPoint = pinCodeApi.Endpoint__c + stateId;
        Blob headerValue = Blob.valueOf(pinCodeApi.Username__c + ':' + pinCodeApi.Password__c);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        HttpRequest request = HttpUtility.getHttpRequest(endPoint, ConstantUtility.GET, 'Authorization', authorizationHeader, null, ConstantUtility.APPLICATION_JSON, null);
        HttpResponse response = HttpUtility.makeCallout(request, null);
        return response.getBody();
    }
    /**
     @Author          : Deepak
     @Company         : TechMatrix Consulting
     @Description     : This method is used to parse the api response
     @Date            : 23/09/2021
     */
    public static void updatePinCodeCodes(String responseString) {
        if (responseString != null) {
            System.debug('responseString '+responseString);
            responseWrapper responseWrapper = (responseWrapper) System.JSON.deserialize(responseString, responseWrapper.class);
            if (responseWrapper != null) {
                if (responseWrapper.data.size() > 0) {
                    List<Pincode__c> pincodes = new List<Pincode__c>();
                    for (cls_data data : responseWrapper.data) {
                        pincodes.add(getMappedPincode(data));
                    }
                    if (pincodes.size() > 0) {
                        upsert pincodes Pincode__c;
                    }
                }
            }
        }
    }
    /**
     @Author          : Deepak
     @Company         : TechMatrix Consulting
     @Description     : This method is used to Mapping the API response to the Pincode object
     @Date            : 23/09/2021
     */
    public static Pincode__c getMappedPincode(cls_data data) {
        Pincode__c pincode = new Pincode__c();
        pincode.Branch_Id__c = String.valueOf(data.brId);
        pincode.Branch_Type__c = data.brType;
        pincode.Branch_Cd__c = data.brCd;
        pincode.Branch_Name__c = data.brName;
        pincode.Branch_Full_Name__c = data.brFullName;
        pincode.Address__c = data.address;
        pincode.State__c = data.state;
        pincode.District__c = data.district;
        pincode.City__c = data.city;
        pincode.Pincode__c = data.zipCode;
        return pincode;
    }


    /** Wrapper class for the Response handling */
    public class responseWrapper {
        public String status;    //Ok
        public cls_data[] data;
        public String responseId;    //823a4de8-1c93-43d9-8fe3-044c3a5a46c0
    }
    public class cls_data {
        public Integer brId;    //1353009
        public String brType;    //RBA
        public String brCd;    //KNP106
        public String brName;    //KANPUR-106
        public String brFullName;    //KANPUR-106(KNP106)
        public String address;    //SAFEXPRESS CENTRE D-16, SITE III PANKI INDUSTRIAL AREA,
        public String state;    //ANDAMAN & NICOBAR
        public String district;    //KANPUR
        public String city;
        public String zipCode;    //208022
    }

}