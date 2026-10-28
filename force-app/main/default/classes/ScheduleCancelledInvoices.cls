public with sharing class ScheduleCancelledInvoices implements Schedulable {
    public void execute(SchedulableContext sc) {
        Date today = Date.today();
        Date fromDateValue = today.addDays(-Integer.valueOf(Label.Propeli_From_Date));
        Date toDateValue   = today.addDays(-Integer.valueOf(Label.Propeli_To_Date));
        String fromDateFormatted = String.valueOf(fromDateValue.day()).leftPad(2, '0') + '-' + 
                                String.valueOf(fromDateValue.month()).leftPad(2, '0') + '-' + 
                                fromDateValue.year();
        String toDateFormatted = String.valueOf(toDateValue.day()).leftPad(2, '0') + '-' + 
                                String.valueOf(toDateValue.month()).leftPad(2, '0') + '-' + 
                                toDateValue.year();

        PropeliCancelledInvoiceService.getCancelledInvoices(fromDateFormatted, toDateFormatted);
    }
}