public without sharing class SafexpressChequeController {

    public Case__c  caseRecord     { get; private set; }
    public String   waybillNumbers { get; private set; }
    public String   amountInWords  { get; private set; }
    public String   closedDate     { get; private set; }
    public Boolean  isPOCMode      { get; private set; }
    public String   imageUrl       {get; private set;}
    public String   accountNumber {get; private set;}
    public String   chequeCofNo {get; private set;}
    public String   displayAmount {get; private set;}


    public SafexpressChequeController() {
          Document doc = [SELECT Id, Name FROM Document WHERE Name = 'SafexpressBlankCheque' LIMIT 1 ];
         imageUrl = URL.getOrgDomainUrl().toExternalForm() +'/servlet/servlet.ImageServer?id=' + doc.Id +'&oid=' + UserInfo.getOrganizationId();

        system.debug('imageUrl-->'+imageUrl);
        isPOCMode = (ApexPages.currentPage().getParameters().get('poc') == 'true');
        String caseId = ApexPages.currentPage().getParameters().get('id');
       // String caseId = 'a02C4000009Q1eWIAS';
        if (String.isBlank(caseId)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Missing Case ID - use ?id=<CaseId>'));
            return;
        }
        loadCaseData(caseId);
    }

    public static boolean isRTGSOrNEFT() {
        return true;
    }
    
   
    
public Boolean getIsCOF() {
    if(caseRecord == null) {
        return false;
    }
    return caseRecord.Claim_Type__c == 'COF';
}

public Boolean getIsRTGSOrNEFT() {
    if(caseRecord == null) {
        return true;
    }
    return caseRecord.Claim_Type__c != 'COF';
}

    // Called as {!displayName} by VF page
    public String getDisplayName() {
        if (caseRecord == null) return '(Unknown)';
        if (String.isNotBlank(caseRecord.Account_Holder_Name__c)) {
            return caseRecord.Account_Holder_Name__c;
        }
        if (caseRecord.Account__r != null && String.isNotBlank(caseRecord.Account__r.Name)) {
            return caseRecord.Account__r.Name;
        }
        return '(Unknown)';
    }
    // Called as {!accountNumber} by VF page
    public String getAccountNumber() {
        return caseRecord != null
            ? caseRecord?.Account_Number__c
            : '';
    }

    public String getBankBranchName() {
        return caseRecord != null ? caseRecord.Bank_Branch_Name__c : '';
    }

    // Called as {!srNo} by VF page
    public String getSrNo() {
        return (caseRecord != null) ? 'SFX-' + caseRecord.Name : '';
    }

    // Called as {!showWaybills} by VF page
    public Boolean getShowWaybills() {
        String p = ApexPages.currentPage().getParameters().get('showWaybills');
        return (p == null || p == 'true');
    }

    // Called as {!waybillCSV} by VF page
    public String getWaybillCSV() {
        String p = ApexPages.currentPage().getParameters().get('waybillCSV');
        return String.isNotBlank(p) ? p : waybillNumbers;
    }
    
    private void loadCaseData(String caseId) {
        try {
            caseRecord = [
                SELECT  Id, Name, LastModifiedDate,
                        Account_Holder_Name__c,
                        Task_Amount__c,
                        Claim_Approved_Amount__c,
                        Claim_Settlement_Date__c,
                        Account_Number__c,
                        Bank_Branch_Name__c,
                        IFSC_Code__c,
                        Claim_Type__c,
                        Cheque_COF_No__c,
                        Account__r.Name,
                        Contact__r.Email,
                        (SELECT Name, Amount__c
                         FROM   Waybill_Details__r
                         ORDER BY CreatedDate ASC)
                FROM    Case__c
                WHERE   Id = :caseId
                LIMIT   1
            ];

            // Settlement date: URL param > field > today
            String paramDate = ApexPages.currentPage().getParameters().get('settlementDate');
            closedDate = paramDate;
            chequeCofNo = ApexPages.currentPage().getParameters().get('chequeCOFNo');
            amountInWords = ApexPages.currentPage().getParameters().get('amountInWords');
            displayAmount = ApexPages.currentPage().getParameters().get('displayAmount');

            // Waybill numbers comma-joined
           List<String> wbNums = new List<String>();

            if (caseRecord.Waybill_Details__r != null) {
                Integer count = 0;

                for (Waybill_Details__c wb : caseRecord.Waybill_Details__r) {
                    if (count >= 5) {
                        break;
                    }

                    if (String.isNotBlank(wb.Name)) {
                        wbNums.add(wb.Name);
                        count++;
                    }
                }
            }
            waybillNumbers = wbNums.isEmpty() ? '-' : String.join(wbNums, ', ');
            accountNumber = caseRecord.Account_Number__c;

        } catch (QueryException e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Query error: ' + e.getMessage()));
        }
    }

    public static String formatIndianCurrencyLong(Long n) {
        if (n == null) return '0';

        String s = String.valueOf(Math.abs(n));
        String sign = (n < 0) ? '-' : '';

        if (s.length() <= 3) {
            return sign + s;
        }

        String result = s.substring(s.length() - 3);
        s = s.substring(0, s.length() - 3);

        while (s.length() > 2) {
            result = s.substring(s.length() - 2) + ',' + result;
            s = s.substring(0, s.length() - 2);
        }

        if (s.length() > 0) {
            result = s + ',' + result;
        }

        return sign + result;
    }

    // Formats Decimal as Indian currency
    public static String formatIndianCurrency(Decimal amt) {
        if (amt == null) {
            return '0';
        }

        Boolean isNegative = (amt < 0);

        amt = amt.abs().setScale(2, RoundingMode.HALF_UP);

        Long rupees = amt.longValue();

        Integer paise = ((amt - Decimal.valueOf(rupees)) * 100)
            .setScale(0, RoundingMode.HALF_UP)
            .intValue();

        String result = (isNegative ? '-' : '') + formatIndianCurrencyLong(rupees);

        // Show decimal only if paise is not zero
        if (paise > 0) {
            if (paise < 10) {
                result += '.0' + String.valueOf(paise);
            } else {
                result += '.' + String.valueOf(paise);
            }
        }

        return result;
    }

    public static String convertToIndianWords(Long n) {
    if (n == 0) return 'Zero';
    String[] ones = new String[]{
        '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven',
        'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen',
        'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    };
    String[] tens = new String[]{
        '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
        'Sixty', 'Seventy', 'Eighty', 'Ninety'
    };
    String r = '';
    if (n >= 10000000) { r += convertToIndianWords(n / 10000000) + ' Crore ';    n = Math.mod(n, 10000000); }
    if (n >= 100000)   { r += convertToIndianWords(n / 100000)   + ' Lakh ';     n = Math.mod(n, 100000);   }
    if (n >= 1000)     { r += convertToIndianWords(n / 1000)     + ' Thousand '; n = Math.mod(n, 1000);     }
    if (n >= 100)      { r += ones[(Integer)(n / 100)] + ' Hundred ';             n = Math.mod(n, 100);      }
    if (n >= 20)       { r += tens[(Integer)(n / 10)] + ' ';                      n = Math.mod(n, 10);       }
    if (n > 0)         { r += ones[(Integer)n] + ' '; }
    return r.trim();
}

// New wrapper that handles Rupees + Paise
public static String convertAmountToIndianWords(Decimal amt) {
    if (amt == null || amt <= 0) return 'Zero';

    // Ensure exactly 2 decimal places to avoid rounding surprises
    amt = amt.setScale(2, System.RoundingMode.HALF_UP);

    Long rupees = amt.longValue(); // truncates the decimal part
    // Get paise as integer 0-99
    Integer paise = ((amt - rupees) * 100).setScale(0, System.RoundingMode.HALF_UP).intValue();

    String rupeesWords = (rupees > 0) ? convertToIndianWords(rupees) : '';
    String paiseWords  = (paise > 0) ? convertToIndianWords((Long)paise) : '';

    String result = '';
    if (rupeesWords != '') {
        result += rupeesWords + ' Rupees';
    }
    if (paiseWords != '') {
        result += (result != '' ? ' and ' : '') + paiseWords + ' Paise';
    }
    if (result == '') {
        result = 'Zero Rupees';
    }
    return result + ' Only';
}
}