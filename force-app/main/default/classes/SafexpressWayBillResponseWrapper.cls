/**
 * @File Name          : SafexpressWayBillResponseWrapper.cls
 * @Description        : Wrapper class for Safexpress post-delivery waybill tracking API response
 * @Author             : Rohit Deshmukh
**/
public class SafexpressWayBillResponseWrapper {
    public String status;
    public Data data;
    public String message;
    public String responseId;

    public class Data {
        public String waybillNo;
        public String mop;
        public String pickupDate;
        public String shipDate;
        public String bookingBranch;
        public String mode;
        public String dodDaccType;
        public Integer pinode;
        public String dlvryCity;
        public String dlvryGty;
        public String sfxPrcCode;
        public String sfxPrcName;
        public String consignor;
        public String cnorGstn;
        public String cnorAddress;
        public String cnorMobNo;
        public String cnorEmailId;
        public String consignee;
        public String cneeGstn;
        public String cneeAddress;
        public String cneeMob;
        public String cneeEmailId;
        public Double freight;
        public Double freightSt;
        public String edd;
        public String dlvryDate;
        public String dlvryType;
        public DodDacc dodDacc;
        public List<Track> track;
    }

    public class DodDacc {
        public String payType;
        public String insmtType;
        public String insmNo;
        public Integer dodDaccAmt;
        public String inFavOf;
        public String pbleAt;
        public String pdcDate;
        public String bankType;
        public String bankName;
    }

    public class Track {
        public String eventDate;
        public String qty;
        public String eventDescr;
        public String websiteMsg;
    }
}