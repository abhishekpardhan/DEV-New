/**
 * @File Name          : PropelI_PreBookingWrapper.cls
 * @Description        : This class is the wrapper class for the create preBooking for Propel-i
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 20-09-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        20-09-2021                Deepak                   Initial Version
**/

public class PropelI_PreBookingWrapper {
    public String bookingChannel;    //Web
    public String branchCode;    //GYA01
    public String businessType;    //CREDIT-INBOUND
    public Integer commercialId;    //90194
    public cls_consignee consignee;
    public cls_consignor consignor;
    public String customerReferenceNumber;    //900
    public String customerType;    //CREDIT
    public String msaCode;    //900738
    public String pickupDate;    //2021-11-24
    public String pickupTime;    //14:00:00
    public String productCategoryName;    //143
    //public String productCategoryID;    //143
    public String rateCard;    //RC900865
    public Integer safexperienceReferenceNumber;    //111
    public String safexperienceRemarks;    //TEST 071921
    public String serviceOffering;    //SURFACE
    public String sfxPrcCode;    //SFX90000035
    public String source;    //SAFEXPRESS
    public Integer totalPackageCount;    //20
    public Integer totalWeight;    //200
    public class cls_consignee {
        public cls_addrBook addrBook;
        public String email;    //
        public String gstinNum;    //
        public Integer id;    //915974
        public String mob;    //9818360064
        public String name;    //PRIYA_CONSIGNEE
        public String panNum;    //
       // public String phone;    //
        public String tanNum;    //
    }
    public class cls_addrBook {
        public String addr1;    //SECTOR-20
        public String addr2;    //
        public String addr3;    //
        public Integer pincode;    //122001
    }
    public class cls_consignor {
        public cls_addrBook addrBook;
        public String email;    //
        public String gstinNum;    //
        public Integer id;    //915972
        public String mob;    //9818360064
        public String name;    //PRIYA_CONSIGNOR
        public String panNum;    //
       // public String phone;    //
        public String tanNum;    //
    }


}