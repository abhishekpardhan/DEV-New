/**
* @File Name          : EinsteinChatBotController.cls
* @Description        : This class is a used to get the  wayBill Status for the chat bot.
* @Author             : Deepak
* @Group              : Techmatrix
* @Last Modified By   : Deepak
* @Last Modified On   : 27-10-2021
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        27-10-2021               Deepak                   Initial Version
**/
 
public without sharing class EinsteinChatBotController {
 
    @InvocableMethod(label='Get WayBill Status')
    public static List<String> getWayBillStatus(List<String> wayBills) {
        try {
            List<String> outputStrings = new List<String>();
            String result = GetWayBillStatusAPI.getWayBillInfo(wayBills[0]);
            WayBillResponseWrapper responseWrapper = (WayBillResponseWrapper) System.JSON.deserialize(result, WayBillResponseWrapper.class);
            System.debug('responseWrapper ' + responseWrapper);
            String outString ;
           /* if (responseWrapper.data.track == null || (responseWrapper.data.track).isEmpty()) {
                result = GetWayBillStatusAPI.getWayBillInfo(wayBills[0]);
                responseWrapper = (WayBillResponseWrapper) System.JSON.deserialize(result, WayBillResponseWrapper.class);
            }*/
            if (responseWrapper.data != null && !(responseWrapper.data.track).isEmpty()) {
                String city = responseWrapper.data.dlvryCity != null ? responseWrapper.data.dlvryCity : ' ';
                outString = responseWrapper.data.track[0].websiteMsg + ' on ' + responseWrapper.data.track[0].eventDate + ' to ' + city;
                System.debug(responseWrapper.data.edd);
                Date eddDate;
                if (responseWrapper.data.edd != null) {
                    eddDate = getEddDate(responseWrapper.data.edd);
                }
                if (responseWrapper != null && eddDate != null && eddDate < Date.today() && !responseWrapper.data.track[0].websiteMsg.containsIgnoreCase('Delivered')) {
                    outString = 'wayBillNotDeliverAsPerEDD';
                } else {
                    if (city != ' ') {
                        outString = 'Your waybill number:' + wayBills[0] + ' is ' + responseWrapper.data.track[0].websiteMsg + ' on ' + responseWrapper.data.track[0].eventDate + ' to ' + city;
                    } else {
                        outString = 'Your waybill number:' + wayBills[0] + ' is ' + responseWrapper.data.track[0].websiteMsg + ' on ' + responseWrapper.data.track[0].eventDate + ' ';
                    }
 
                }
            } else {
                outString = 'Waybill details not found';// + responseWrapper.message;
            }
            outputStrings.add(outString);
            return outputStrings;
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : EinsteinChatBotController at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('EinsteinChatBotController', 'getWayBillStatus', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
        return null;
    }
 
    public static Date getEddDate(String dateString) {
        String[] ArrayString = DateString.split('-');
        String StringMonth = null;
        Date parsedDate;
        integer index = 1;
        if (ArrayString.size() > 1) {
            if (ArrayString[index].containsIgnoreCase('Jan'))
                StringMonth = '01';
 
            if (ArrayString[index].containsIgnoreCase('Feb'))
                StringMonth = '02';
 
            if (ArrayString[index].containsIgnoreCase('Mar'))
                StringMonth = '03';
 
            if (ArrayString[index].containsIgnoreCase('Apr'))
                StringMonth = '04';
 
            if (ArrayString[index].containsIgnoreCase('May'))
                StringMonth = '05';
 
            if (ArrayString[index].containsIgnoreCase('Jun'))
                StringMonth = '06';
 
            if (ArrayString[index].containsIgnoreCase('Jul'))
                StringMonth = '07';
 
            if (ArrayString[index].containsIgnoreCase('Aug'))
                StringMonth = '08';
 
            if (ArrayString[index].containsIgnoreCase('Sep'))
                StringMonth = '09';
 
            if (ArrayString[index].containsIgnoreCase('Oct'))
                StringMonth = '10';
 
            if (ArrayString[index].containsIgnoreCase('Nov'))
                StringMonth = '11';
 
            if (ArrayString[index].containsIgnoreCase('Dec'))
                StringMonth = '12';
 
            parsedDate = Date.newInstance(Integer.valueOf(ArrayString[2]), Integer.valueOf(StringMonth), Integer.valueOf(ArrayString[0]));
            //parsedDate = Date.newInstance(ArrayString[0] + '/' + StringMonth + '/' + ArrayString[2];
        }
 
        return parsedDate;
    }
}