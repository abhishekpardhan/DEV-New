global with sharing class SafexpressWaybillStatusAction {

    @InvocableMethod(
        label='Get Waybill Status V2' 
        description='Fetches shipment status for a waybill number and returns structured object for LWC rendering.'
    )
    global static List<SafexpressWaybillStatusResult> getWaybillStatus(List<SafexpressWaybillStatusRequest> requests) {
        List<SafexpressWaybillStatusResult> results = new List<SafexpressWaybillStatusResult>();
        
        for (SafexpressWaybillStatusRequest req : requests) {
            SafexpressWaybillStatusResult res = new SafexpressWaybillStatusResult();
            try {
                String waybillNum = extractWaybillNumber(req);
                if (String.isBlank(waybillNum)) {
                    res.waybillInfo = buildErrorResult(
                        'Waybill Number Required',
                        'Please provide a valid 12-digit waybill number to track your shipment.'
                    );
                } else {
                    res.waybillInfo = fetchAndFormat(waybillNum);
                }
            } catch (Exception ex) {
                res.waybillInfo = buildErrorResult(
                    'Service Error',
                    'We could not retrieve shipment details at this time. Please try again shortly.'
                );
            }
            results.add(res);
        }
        return results;
    }

    private static String extractWaybillNumber(SafexpressWaybillStatusRequest req) {
        if (req == null) return '';
        if (String.isNotBlank(req.waybillNumber)) return req.waybillNumber.trim();
        if (String.isNotBlank(req.customerConcern)) return req.customerConcern.trim();
        return '';
    }

    private static WaybillData fetchAndFormat(String waybillNum) {
        String rawJson;
        try {
            rawJson = GetWayBillStatusAPI.getWayBillInfo(waybillNum);
        } catch (Exception ex) {
            return buildErrorResult(
                'Tracking Service Unavailable',
                'The tracking service is temporarily unavailable. Please try again in a few minutes.'
            );
        }

        if (String.isBlank(rawJson)) {
            return buildNotFoundResult(waybillNum);
        }

        Map<String, Object> root;
        try {
            root = (Map<String, Object>) JSON.deserializeUntyped(rawJson);
        } catch (Exception ex) {
            return buildErrorResult(
                'Invalid Response',
                'We received an unexpected response from the tracking service.'
            );
        }

        if (root == null || root.isEmpty()) {
            return buildNotFoundResult(waybillNum);
        }

        Map<String, Object> data;
        if (root.containsKey('data') && root.get('data') instanceof Map<String, Object>) {
            data = (Map<String, Object>) root.get('data');
        } else {
            data = root;
        }

        if (data == null || data.isEmpty()) {
            return buildNotFoundResult(waybillNum);
        }

        WaybillData info = new WaybillData();
        info.success        = true;
        info.shipmentState  = 'SUCCESS';
        info.inputTypeUsed  = 'WAYBILL';
        info.deliveryCity   = getString(data, 'dlvryCity');
        info.caseNumber     = getString(data, 'caseNumber');
        info.bookingBranch  = getString(data, 'bookingBranch');
        info.consignorName  = getString(data, 'consignorName');
        info.consigneeName  = getString(data, 'consigneeName');
        info.actualDeliveryDate = getString(data, 'dlvryDate');
        info.expectedDeliveryDate = getString(data, 'expDlvryDate');

        Object trackObj = data.get('track');
        if (trackObj instanceof List<Object>) {
            List<Object> trackList = (List<Object>) trackObj;
            if (!trackList.isEmpty()) {
                Map<String, Object> latestEvent = (Map<String, Object>) trackList[0];
                info.currentStatus = getString(latestEvent, 'websiteMsg');
                info.lastEventDate = getString(latestEvent, 'eventDate');
            }
        }

        if ('CANCELLED'.equalsIgnoreCase(info.currentStatus)) {
            return buildErrorResult(
                'Shipment Cancelled',
                'Waybill ' + formatWaybill(waybillNum) + ' has been cancelled. Please contact your nearest Safexpress branch.'
            );
        }

        String emoji = getStatusEmoji(info.currentStatus);
        info.headerTitle = String.isNotBlank(info.currentStatus)
            ? emoji + ' ' + info.currentStatus
            : '📍 Waybill Status';
        info.headerColor = '#1E7A34';
        info.footerNote  = '🙏 Thank you for choosing Safexpress. 😊';

        return info;
    }

    private static WaybillData buildErrorResult(String title, String message) {
        WaybillData info = new WaybillData();
        info.success       = false;
        info.shipmentState = 'API_ERROR';
        info.headerTitle   = title;
        info.errorMessage  = message;
        info.headerColor   = '#C0392B';
        info.footerNote    = '🙏 Thank you for choosing Safexpress. 😊';
        return info;
    }

    private static WaybillData buildNotFoundResult(String lookupNum) {
        WaybillData info = new WaybillData();
        info.success       = false;
        info.shipmentState = 'NOT_FOUND';
        info.headerTitle   = 'No Record Found';
        info.errorMessage  = 'No shipment details found for waybill ' + formatWaybill(lookupNum) + '. Please verify the number.';
        info.headerColor   = '#E67E22';
        info.footerNote    = '🙏 Thank you for choosing Safexpress. 😊';
        return info;
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
}