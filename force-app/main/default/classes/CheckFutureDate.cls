/**
 * @File Name          : CheckFutureDate.cls
 * @Description        : This class is a used to get the Date entered for pickup in the chat bot.
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 29-11-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        29-11-2021               Deepak                   Initial Version
**/

public without sharing class CheckFutureDate {

    public class DateInput {
        @InvocableVariable
        public String dateString;
        @InvocableVariable
        public String countString;
    }
    public class Output {
        @InvocableVariable
        public String dateValid;
        @InvocableVariable
        public String countString;
    }
    @InvocableMethod(label='Check Future Date')
    public static List<Output> checkDate(List<DateInput> dateInputs) {
        try {
            Integer countInteger ;
            Date dateValue;
            String tempDate;
            List<Output> outputStrings = new List<Output>();
            for (DateInput dateObj : dateInputs) {
                if (dateObj.countString == null) {
                    countInteger = 1;
                } else {
                    countInteger = Integer.valueOf(dateObj.countString) + 1;
                }
                /// Date
                Integer dd = Integer.valueOf(dateObj.dateString.split('/')[0]);
                Integer mon = Integer.valueOf(dateObj.dateString.split('/')[1]);
                Integer year = Integer.valueOf(dateObj.dateString.split('/')[2]);
                dateValue = Date.newInstance(year, mon, dd);
                tempDate = dateObj.dateString;
                break;
            }
            Output output = new Output();
            if (dateValue >= Date.today()) {
                output.dateValid = tempDate;
            } else {
                output.dateValid = null;
            }
            output.countString = String.valueOf(countInteger);
            outputStrings.add(output);

            return outputStrings;
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CheckFutureDate at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CheckFutureDate', 'checkDate', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        return null;
    }
}