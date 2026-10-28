/**
    * @File Name          : QueryUtil.cls
    * @Description        : This class is Utility Class for general Query
    * @Author             : Deepak
    * @Group              : Techmatrix
    * @Last Modified By   : Deepak
    * @Last Modified On   : 08-07-2021
    * @Modification Log   :
    *==============================================================================
    * Ver         Date                     Author                 Modification
    *==============================================================================
    * 1.0         08-07-2021              Deepak                 Initial Version
 */

public without sharing class QueryUtil {

    /**
   @Author          : Deepak
   @Company         : TechMatrix Consulting
   @Description     : This Method  is used query and return the object List fields Based on query parameter
   @Date            : 07/07/2021
  */
    public static List<Safex_API__c> getSafexApiInfo(String apiName) {
        return [
                SELECT
                        Access_Key__c,Authorisation_Type__c,Customer_User_Login__c,Endpoint__c,Name,Password__c,
                        Username__c,Agent_User_Login__c
                FROM Safex_API__c
                WHERE Name = :apiName
                LIMIT 1
        ];
    }
    /**
      @Author          : Deepak
      @Company         : TechMatrix Consulting
      @Description     : This Method is used query and return the object List fields Based on query parameter
      @Date            : 07/07/2021
     */
    public static List<PropelI_API_PreBooking__c> getPropelApiInfo(String apiName) {
        return [
                SELECT
                        Id,Endpoint__c,grant_type__c,Password__c,scope__c,userid__c,Username__c,x_api_key__c
                FROM PropelI_API_PreBooking__c
                WHERE Name = :apiName
                LIMIT 1
        ];
    }

    /**
     @Author          : Deepak
     @Company         : TechMatrix Consulting
     @Description     : This Method  is used query and return the object List fields Based on query parameter
     @Date            : 07/07/2021
    */
    public static Case getCaseObject(String recordId) {
        return [
                SELECT Subject,Description,CaseNumber,ContactMobile,OTRS_Remarks__c,OTRS_Request_Status__c,OTRS_Ticket_No__c,
                        WaybillNo__c, Sub_Type__c,Origin,Consignee_Name__c,Transport_Mode__c,Product_Type__c,
                        Consignee_Address_Line_1__c,Consignee_Address_Line_2__c,Consignee_Address_Line_3__c,Consignee_Pincode__c,Consignee_Id__c,
                        Consignee_Email__c,Consignee_GSTIN_Number__c,Consignee_Phone__c,Consignee_PAN_Number__c,Consignee_TAN_Number__c,
                        Consignor_Name__c,SFX__r.MSA__c,PRC__r.MSA__c,SFX__c,PRC__c,SFX__r.Name,PRC__r.Name,
                        Consignor_Address_Line_1__c,Consignor_Address_Line_2__c,Consignor_Address_Line_3__c,Consignor_Pincode__c,Consignor_Id__c,
                        Consignor_Email__c,Consignor_GSTIN_Number__c,Consignor_Phone__c,Consignor_PAN_Number__c,Consignor_TAN_Number__c,
                        Booking_Channel__c,Origin_Branch__c,Business_Type__c,Commercial_Id__c,Customer_Reference_Number__c,Customer_Type__c,
                        Consignor_MSA_Cust_Id__c,PickUp_Date__c,PickUp_Time__c,Product_Category_Id__c,Rate_Card__c,Safexperience_Reference_Number__c,
                        Safexperience_Remarks__c,Service_Offering__c,SFX_PRC_Code__c,Source_Booking_Id__c,Total_Package_Count__c,Total_Weight__c,Origin_Branch_Code__c,
                        Main_Category__c,Sub_Category__c,Issue_Type__c,CreatedById,ContactPhone,ContactId,ContactEmail,LastModifiedDate,status,Consignor_City__c,
                        Consignee_City__c,Consignee_State__c,Consignor_State__c,No_of_Pcs__c,Mode_Of_Payment__c,Contact.Name,Origin_City__c,Destination_City__c
                FROM Case
                WHERE Id = :recordId
                LIMIT 1
        ][0];
    }
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This Method is used query this address information and return the object List based on pincode
    @Date            : 07/07/2021
   */
    public static List<Pincode__c> getAddress(String pincode) {
        return [
                SELECT Pincode__c,City__c,State__c,Country__c,Branch_Name__c,PO_Name__c,Branch_Id__c,District__c
                FROM Pincode__c
                WHERE Pincode__c = :pincode
                LIMIT 1
        ];
    }

}