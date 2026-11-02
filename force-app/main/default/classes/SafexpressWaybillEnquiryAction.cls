/**
 * @File Name          : SafexpressWaybillEnquiryAction.cls
 * @Description        : Invocable action to fetch and normalize shipment tracking details for Safexpress waybills.
 * @Author             : Rohit Deshmukh
 * @Last Modified By   : Rohit Deshmukh
 * @Last Modified On   : 14-Oct-2026
**/
global with sharing class SafexpressWaybillEnquiryAction {

    global class Request {
        @InvocableVariable(label='Waybill Number' required=true)
        public String waybillNumber;
    }

    global class Output {
        @InvocableVariable(label='Waybill Status'
            description='SUCCESS, NOT_FOUND, API_ERROR, VALIDATION_ERROR')
        public String waybillStatus;

        @InvocableVariable(label='Current Status'
            description='Latest tracking status text from the API.')
        public String currentStatus;

        @InvocableVariable(label='Waybill Card'
            description='Full waybill status card shown to the customer.')
        public SafexpressWaybillEnquiryCard waybillCard;
    }

    @InvocableMethod(
        label       = 'Safexpress Waybill Status Intent'
        description = 'Fetches shipment tracking status for a waybill number and returns a card shown to the customer.'
        category    = 'Safexpress Agent Actions'
    )
    global static List<Output> getWaybillStatus(List<Request> requests) {
        List<Output> outputs = new List<Output>();
        for (Request req : requests) {
            Output out = new Output();
            try {
                if (String.isBlank(req.waybillNumber)) {
                    out.waybillStatus = 'VALIDATION_ERROR';
                    out.currentStatus = 'VALIDATION_ERROR';
                    SafexpressWaybillEnquiryCard card = new SafexpressWaybillEnquiryCard();
                    card.headerTitle  = 'Waybill Number Required';
                    card.errorMessage = 'Please provide a valid waybill number to track your shipment.';
                    card.footerNote   = '🙏 Thank you for choosing Safexpress. 😊';
                    out.waybillCard   = card;
                } else {
                    out = fetchAndBuild(req.waybillNumber.trim());
                }
            } catch (Exception ex) {
                LoggerUtil.createErrorLog('SafexpressWaybillEnquiryAction', 'getWaybillStatus',
                    ex.getTypeName(), ex.getMessage(), ex.getStackTraceString(), null);
                out.waybillStatus = 'API_ERROR';
                out.currentStatus = 'API_ERROR';
                SafexpressWaybillEnquiryCard card = new SafexpressWaybillEnquiryCard();
                card.headerTitle  = 'Service Error';
                card.errorMessage = 'We could not retrieve shipment details at this time. Please try again shortly.';
                card.footerNote   = '🙏 Thank you for choosing Safexpress. 😊';
                out.waybillCard   = card;
            }
            outputs.add(out);
        }
        return outputs;
    }

    private static String normalizeStatus(String raw) {
        if (String.isBlank(raw)) return null;
        String s = raw.toLowerCase();
        if (s.contains('out for delivery'))                         return 'Out for Delivery';
        if (s.contains('delivered') && !s.contains('undelivered')) return 'Delivered';
        if (s.contains('undelivered'))                             return 'Undelivered';
        if (s.contains('arrived at destination'))                  return 'Arrived at Destination';
        if (s.contains('arrived'))                                 return 'Arrived at Destination';
        if (s.contains('in transit'))                              return 'In Transit';
        if (s.contains('departed') || s.contains('transit'))      return 'In Transit';
        if (s.contains('booked') || s.contains('rps created'))    return 'Booked';
        if (s.contains('picked up') || s.contains('pickup'))      return 'Picked Up';
        if (s.contains('cancelled') || s.contains('canceled'))    return 'Cancelled';
        if (s.contains('pending'))                                 return 'Pending';
        if (s.contains('waybill arrived'))                         return 'Arrived at Destination';
        if (s.contains('waybill in transit') || s.contains('is departed') || s.contains('vehicle')) return 'In Transit';
        return raw;
    }

    private static Output fetchAndBuild(String waybillNum) {
        Output out = new Output();
        SafexpressWaybillEnquiryCard card = new SafexpressWaybillEnquiryCard();

        String rawJson;
        try {
            rawJson = GetWayBillStatusAPI.getWayBillInfo(waybillNum);
        } catch (Exception ex) {
            out.waybillStatus = 'API_ERROR';
            out.currentStatus = 'API_ERROR';
            card.headerTitle  = 'Tracking Service Unavailable';
            card.errorMessage = 'The tracking service is temporarily unavailable. Please try again in a few minutes.';
            card.footerNote   = '🙏 Thank you for choosing Safexpress. 😊';
            out.waybillCard   = card;
            return out;
        }

        if (String.isBlank(rawJson) || rawJson.contains('Not Found')) {
            out.waybillStatus = 'NOT_FOUND';
            out.currentStatus = 'NOT_FOUND';
            card.headerTitle  = 'No Record Found';
            card.errorMessage = 'No shipment details found for waybill ' + formatWaybill(waybillNum) + '. Please verify the number.';
            card.footerNote   = '🙏 Thank you for choosing Safexpress. 😊';
            out.waybillCard   = card;
            return out;
        }

        WayBillResponseWrapper wrapper;
        try {
            wrapper = (WayBillResponseWrapper) JSON.deserialize(rawJson, WayBillResponseWrapper.class);
        } catch (Exception ex) {
            out.waybillStatus = 'API_ERROR';
            out.currentStatus = 'API_ERROR';
            card.headerTitle  = 'Invalid Response';
            card.errorMessage = 'We received an unexpected response from the tracking service.';
            card.footerNote   = '🙏 Thank you for choosing Safexpress. 😊';
            out.waybillCard   = card;
            return out;
        }

        if (wrapper == null || wrapper.data == null) {
            out.waybillStatus = 'NOT_FOUND';
            out.currentStatus = 'NOT_FOUND';
            card.headerTitle  = 'No Record Found';
            card.errorMessage = 'No shipment details found for waybill ' + formatWaybill(waybillNum) + '. Please verify the number.';
            card.footerNote   = '🙏 Thank you for choosing Safexpress. 😊';
            out.waybillCard   = card;
            return out;
        }

        WayBillResponseWrapper.Data data = wrapper.data;

        String currentStatus    = null;
        String lastEvent        = null;
        String deliveredOn      = null;
        String deliveryLocation = data.dlvryCity;

        if (data.track != null && !data.track.isEmpty()) {
            WayBillResponseWrapper.Track latest = data.track[0];
            String cleanWebsite = normalizeStatus(latest.websiteMsg);
            String cleanEvent   = normalizeStatus(latest.eventDescr);
            currentStatus = String.isNotBlank(cleanWebsite) ? cleanWebsite : cleanEvent;
            lastEvent     = latest.eventDate;
        }

        Boolean isDelivered = String.isNotBlank(currentStatus)
                              && currentStatus.toLowerCase().contains('delivered')
                              && !currentStatus.toLowerCase().contains('undelivered');

        if (isDelivered) {
            deliveredOn = String.isNotBlank(data.dlvryDate) ? data.dlvryDate : lastEvent;
        }

        String emoji = getStatusEmoji(currentStatus);
        out.waybillStatus           = 'SUCCESS';
        out.currentStatus           = currentStatus;
        card.headerTitle            = String.isNotBlank(currentStatus) ? emoji + ' ' + currentStatus : '📍 Waybill Status';
        card.waybillNumberFormatted = formatWaybill(waybillNum);
        card.lastEvent              = lastEvent;
        card.currentStatus          = currentStatus;
        card.deliveryLocation       = deliveryLocation;
        card.deliveredOn            = deliveredOn;
        card.footerNote             = '🙏 Thank you for choosing Safexpress. 😊';
        out.waybillCard             = card;
        return out;
    }

    private static String getStatusEmoji(String status) {
        if (String.isBlank(status)) return '📍';
        String s = status.toLowerCase();
        if (s.contains('out for delivery'))         return '🚚';
        if (s.contains('in transit'))               return '🚛';
        if (s.contains('arrived at destination'))   return '🏬';
        if (s.contains('undelivered'))              return '⚠️';
        if (s.contains('delivered'))                return '✅';
        if (s.contains('booked') || s.contains('picked up')) return '📦';
        if (s.contains('pending'))                  return '⏳';
        if (s.contains('cancelled'))                return '❌';
        return '📍';
    }

    private static String formatWaybill(String num) {
        if (num == null) return '';
        String digits = num.replaceAll('[^0-9]', '');
        if (digits.length() == 12) {
            return digits.substring(0, 4) + ' ' + digits.substring(4, 8) + ' ' + digits.substring(8, 12);
        } else if (digits.length() == 8) {
            return digits.substring(0, 4) + ' ' + digits.substring(4, 8);
        } else if (digits.length() == 9) {
            return digits.substring(0, 3) + ' ' + digits.substring(3, 6) + ' ' + digits.substring(6, 9);
        }
        return num;
    }
}