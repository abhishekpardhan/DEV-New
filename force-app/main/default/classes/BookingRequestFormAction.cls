/**
 * Agent action "Submit_Booking_Form".
 * Re-validates the form on the server and returns cleaned values. No DML.
 * formStatus: VALID | INVALID | ERROR
 */
public with sharing class BookingRequestFormAction {

    /** Data shape of the form. Referenced by lightningTypes/bookingRequestForm/schema.json. */
    public class BookingForm {
        @InvocableVariable(label='Name' description='Full name of the customer')
        public String name;
        @InvocableVariable(label='Mobile Number' description='10-digit mobile number')
        public String mobileNumber;
        @InvocableVariable(label='Email' description='Email address')
        public String email;
        @InvocableVariable(label='Pickup Pincode' description='6-digit pincode of the pickup location')
        public String pickupPincode;
        @InvocableVariable(label='Delivery Pincode' description='6-digit pincode of the delivery location')
        public String deliveryPincode;
        @InvocableVariable(label='Pickup Address' description='Full pickup address')
        public String pickupAddress;
        @InvocableVariable(label='Approx Weight (kg)' description='Approximate total weight in kg')
        public String approxWeight;
        @InvocableVariable(label='Number of Packages' description='Total number of packages')
        public String packageCount;
    }

    public class Request {
        @InvocableVariable(label='Booking Form' required=true)
        public BookingForm booking_form;
    }

    public class Response {
        @InvocableVariable(label='Form Status') public String formStatus;
        @InvocableVariable(label='Invalid Fields') public String invalidFields;
        @InvocableVariable(label='Error Message') public String errorMessage;
        @InvocableVariable(label='Name') public String name;
        @InvocableVariable(label='Mobile Number') public String mobileNumber;
        @InvocableVariable(label='Email') public String email;
        @InvocableVariable(label='Pickup Pincode') public String pickupPincode;
        @InvocableVariable(label='Delivery Pincode') public String deliveryPincode;
        @InvocableVariable(label='Pickup Address') public String pickupAddress;
        @InvocableVariable(label='Approx Weight (kg)') public String approxWeight;
        @InvocableVariable(label='Number of Packages') public String packageCount;
        @InvocableVariable(label='Pickup Location') public String pickupLocation;
        @InvocableVariable(label='Delivery Location') public String deliveryLocation;
    }

    @InvocableMethod(
        label='Submit Booking Form'
        description='Validates the booking or pickup request form and returns the cleaned details. Does not create a case.'
    )
    public static List<Response> submit(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Set<String> pins = new Set<String>();
        for (Request req : requests) {
            BookingForm f = req.booking_form == null ? new BookingForm() : req.booking_form;
            pins.add(clean(f.pickupPincode));
            pins.add(clean(f.deliveryPincode));
        }
        Map<String, PincodeLookupService.PincodeResult> pinResults = PincodeLookupService.checkAll(pins);
        for (Request req : requests) {
            responses.add(validateOne(req.booking_form == null ? new BookingForm() : req.booking_form, pinResults));
        }
        return responses;
    }

    private static Response validateOne(BookingForm f, Map<String, PincodeLookupService.PincodeResult> pinResults) {
        Response res = new Response();
        List<String> codes = new List<String>();
        List<String> messages = new List<String>();

        res.name = keep(BookingRequestValidator.validateName(f.name), 'NAME', 'Name', codes, messages);
        res.mobileNumber = keep(BookingRequestValidator.validatePhone(f.mobileNumber), 'MOBILE_NUMBER', 'Mobile number', codes, messages);
        res.email = keep(BookingRequestValidator.validateEmail(f.email), 'EMAIL', 'Email', codes, messages);
        res.pickupAddress = keep(BookingRequestValidator.validateAddress(f.pickupAddress), 'PICKUP_ADDRESS', 'Pickup address', codes, messages);
        res.approxWeight = keep(BookingRequestValidator.validateWeight(f.approxWeight), 'APPROX_WEIGHT', 'Approx weight', codes, messages);
        res.packageCount = keep(BookingRequestValidator.validatePackages(f.packageCount), 'PACKAGE_COUNT', 'Number of packages', codes, messages);

        if (String.isNotBlank(res.approxWeight) && String.isNotBlank(res.packageCount)) {
            BookingRequestValidator.FieldResult perPackage =
                BookingRequestValidator.validateWeightPerPackage(res.approxWeight, res.packageCount);
            if (!perPackage.valid) {
                res.approxWeight = '';
                codes.add('APPROX_WEIGHT');
                messages.add('Approx weight: ' + perPackage.error);
            }
        }

        PincodeLookupService.PincodeResult pickup = pinResults.get(clean(f.pickupPincode));
        PincodeLookupService.PincodeResult delivery = pinResults.get(clean(f.deliveryPincode));
        Boolean pickupCheckFailed = applyPincode(pickup, 'PICKUP_PINCODE', 'Pickup pincode', codes, messages);
        Boolean deliveryCheckFailed = applyPincode(delivery, 'DELIVERY_PINCODE', 'Delivery pincode', codes, messages);
        Boolean checkFailed = pickupCheckFailed || deliveryCheckFailed;

        if (pickup != null && pickup.status == 'SERVICEABLE') {
            res.pickupPincode = pickup.pincode;
            res.pickupLocation = pickup.locationLabel();
        }
        if (delivery != null && delivery.status == 'SERVICEABLE') {
            res.deliveryPincode = delivery.pincode;
            res.deliveryLocation = delivery.locationLabel();
        }

        res.invalidFields = String.join(codes, ',');
        res.errorMessage = String.join(messages, '\n');
        res.formStatus = checkFailed ? 'ERROR' : (codes.isEmpty() ? 'VALID' : 'INVALID');
        return res;
    }

    private static Boolean applyPincode(
        PincodeLookupService.PincodeResult r, String code, String label, List<String> codes, List<String> messages
    ) {
        if (r == null || r.status == 'INVALID_FORMAT') {
            BookingRequestValidator.FieldResult fmt =
                BookingRequestValidator.validatePincodeFormat(r == null ? '' : r.pincode);
            codes.add(code);
            messages.add(label + ': ' + fmt.error);
        } else if (r.status == 'NOT_SERVICEABLE') {
            codes.add(code);
            messages.add(label + ': Sorry, we do not provide service in this pincode.');
        } else if (r.status == 'ERROR') {
            codes.add(code);
            messages.add(label + ': Sorry, I am unable to verify the pincode right now. Kindly try again after some time.');
            return true;
        }
        return false;
    }

    private static String keep(
        BookingRequestValidator.FieldResult r, String code, String label, List<String> codes, List<String> messages
    ) {
        if (r.valid) return r.value;
        codes.add(code);
        messages.add(label + ': ' + r.error);
        return '';
    }

    private static String clean(String pin) {
        return pin == null ? '' : pin.replaceAll('\\s+', '');
    }
}