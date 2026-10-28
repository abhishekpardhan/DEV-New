public with sharing class AgentforceAgentChatWaybillStatusAction {

    @InvocableMethod(
        label='Get Waybill Status' 
        description='Fetches shipment status for a waybill number and returns structured object for LWC rendering.'
    )
    public static List<Output> getWaybillStatus(List<Input> inputs) {
        List<Output> results = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            try {
                String waybillNum = (inp.customerConcern != null) ? inp.customerConcern.trim() : '';
                if (String.isBlank(waybillNum)) {
                    out = buildErrorResult(
                        'Waybill number is required.',
                        'Please provide a valid waybill number to track your shipment.'
                    );
                } else {
                    out = fetchAndFormat(waybillNum);
                }
            } catch (Exception ex) {
                out = buildErrorResult(
                    'An unexpected error occurred.',
                    'We could not retrieve shipment details at this time. Please try again shortly.'
                );
            }
            results.add(out);
        }
        return results;
    }

    public class Input {
        @InvocableVariable(
            label='Waybill Number' 
            description='12-digit Safexpress waybill number or input entered by user' 
            required=true
        )
        public String customerConcern;
    }

    public class Output {
        @InvocableVariable(label='State')
        public String state;

        @InvocableVariable(label='Header Color')
        public String headerColor;

        @InvocableVariable(label='Header Title')
        public String headerTitle;

        @InvocableVariable(label='Footer Note')
        public String footerNote;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Rows')
        public List<RowItem> rows;
    }

    public class RowItem {
        @InvocableVariable(label='Label')
        public String label;

        @InvocableVariable(label='Value')
        public String value;

        public RowItem() {}

        public RowItem(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    private static Output fetchAndFormat(String waybillNum) {
        String inputLabel = '🚚 Waybill No.';
        String rawJson;
        try {
            rawJson = GetWayBillStatusAPI.getWayBillInfo(waybillNum);
        } catch (Exception ex) {
            return buildErrorResult(
                'Unable to reach tracking service.',
                'The tracking service is temporarily unavailable. Please try again in a few minutes.'
            );
        }

        if (String.isBlank(rawJson)) {
            return buildNotFoundResult(inputLabel, waybillNum);
        }

        Map<String, Object> root;
        try {
            root = (Map<String, Object>) JSON.deserializeUntyped(rawJson);
        } catch (Exception ex) {
            return buildErrorResult(
                'Invalid response from tracking service.',
                'We received an unexpected response. Please try again.'
            );
        }

        if (root == null || root.isEmpty()) {
            return buildNotFoundResult(inputLabel, waybillNum);
        }

        ShipmentResult res = parseShipmentData(root, waybillNum);

        if (res == null) {
            return buildNotFoundResult(inputLabel, waybillNum);
        }

        if ('CANCELLED'.equalsIgnoreCase(res.currentStatus)) {
            return buildErrorResult(
                'Shipment Cancelled',
                'Waybill ' + formatWaybill(waybillNum) + ' has been cancelled. Please contact your nearest Safexpress branch for assistance.'
            );
        }

        return buildFormattedResult(res, inputLabel, waybillNum);
    }

    private static ShipmentResult parseShipmentData(Map<String, Object> root, String waybillNum) {
        Map<String, Object> data;
        if (root.containsKey('data') && root.get('data') instanceof Map<String, Object>) {
            data = (Map<String, Object>) root.get('data');
        } else {
            data = root;
        }

        if (data == null || data.isEmpty()) return null;

        ShipmentResult res = new ShipmentResult();
        res.waybillNumber = waybillNum;
        res.deliveryCity  = getString(data, 'dlvryCity');
        res.caseNumber    = getString(data, 'caseNumber');

        Object trackObj = data.get('track');
        if (trackObj instanceof List<Object>) {
            List<Object> trackList = (List<Object>) trackObj;
            if (!trackList.isEmpty()) {
                Map<String, Object> latestEvent = (Map<String, Object>) trackList[0];
                res.currentStatus = getString(latestEvent, 'websiteMsg');
                res.lastEventDate = getString(latestEvent, 'eventDate');
            }
        }

        res.actualDeliveryDate = getString(data, 'dlvryDate');
        return res;
    }

    private static String getStatusEmoji(String status) {
        if (String.isBlank(status)) return '📍';
        String s = status.toLowerCase();
        if (s.contains('out for delivery'))  return '🚚';
        if (s.contains('in transit'))        return '🚛';
        if (s.contains('delivered'))         return '✅';
        if (s.contains('booked'))            return '📦';
        if (s.contains('pending'))           return '⏳';
        return '📍';
    }

    private static Output buildFormattedResult(ShipmentResult res, String inputLabel, String lookupNum) {
        Output out = new Output();
        out.rows = new List<RowItem>();
        out.rows.add(new RowItem(inputLabel, formatWaybill(lookupNum)));
        if (String.isNotBlank(res.lastEventDate))      out.rows.add(new RowItem('🕐 Last Event',         res.lastEventDate));
        if (String.isNotBlank(res.currentStatus))      out.rows.add(new RowItem('📍 Current Status',    res.currentStatus));
        if (String.isNotBlank(res.deliveryCity))       out.rows.add(new RowItem('🏙 Delivery Location', res.deliveryCity));
        if (String.isNotBlank(res.actualDeliveryDate)) out.rows.add(new RowItem('✅ Delivered On',             res.actualDeliveryDate));
        if (String.isNotBlank(res.caseNumber))         out.rows.add(new RowItem('🎫 Case Number',        res.caseNumber));

        String emoji = getStatusEmoji(res.currentStatus);
        out.headerTitle = String.isNotBlank(res.currentStatus)
            ? emoji + ' ' + res.currentStatus
            : '📍 Waybill Status';

        out.state       = 'SUCCESS';
        out.headerColor = '#1E7A34';
        out.footerNote  = '🙏 Thank you for choosing Safexpress. 😊';
        return out;
    }

    private static Output buildErrorResult(String title, String message) {
        Output out = new Output();
        out.state        = 'API_ERROR';
        out.headerColor  = '#C0392B';
        out.headerTitle  = title;
        out.errorMessage = message;
        out.footerNote   = '🙏 Thank you for choosing Safexpress. 😊';
        return out;
    }

    private static Output buildNotFoundResult(String inputLabel, String lookupNum) {
        Output out = new Output();
        out.state        = 'NOT_FOUND';
        out.headerColor  = '#E67E22';
        out.headerTitle  = 'No Record Found';
        out.errorMessage = 'No shipment details found for waybill ' + formatWaybill(lookupNum) + '. Please verify the number and try again.';
        out.footerNote   = '🙏 Thank you for choosing Safexpress. 😊';
        return out;
    }

    private static String getString(Map<String, Object> m, String key) {
        Object val = m.get(key);
        if (val == null) return null;
        String s = String.valueOf(val).trim();
        return String.isBlank(s) ? null : s;
    }

    private static String formatWaybill(String num) {
        if (num == null) return '';
        String digits = num.replaceAll('[^0-9]', '');
        if (digits.length() != 12) return num;
        return digits.substring(0, 4) + ' ' + digits.substring(4, 8) + ' ' + digits.substring(8, 12);
    }

    private class ShipmentResult {
        String waybillNumber;
        String currentStatus;
        String lastEventDate;
        String deliveryCity;
        String actualDeliveryDate;
        String caseNumber;
    }
}