public with sharing class PropeliCancelledInvoiceWrappers {

    // Request Wrapper
    public class CancelledInvoiceRequest {
        public String fromDate;
        public String toDate;

        public CancelledInvoiceRequest() {}

        public CancelledInvoiceRequest(String fromDate, String toDate) {
            this.fromDate = fromDate;
            this.toDate = toDate;
        }
    }

    public class CancelledInvoiceItem {
        public String billId;
        public String billNumber;
        public String billType;
        public String status;
        public Decimal actualOutstandingAmount;
        public Decimal outstandingAmount;
        public String msaCode;
        public String sfRecordId;
        public String updatedDate;

    }

    public class CancelledInvoiceResponse {
        public String message;
        public String status;
        public List<CancelledInvoiceItem> data;
    }
}