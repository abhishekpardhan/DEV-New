@IsTest
public class PincodeApiMock implements HttpCalloutMock {
    // Change here if the Named Credential name changes
    public static final String TOKEN_ENDPOINT = 'callout:Propeli_Token_API/oauth2/token';
    public static final String API_ENDPOINT =
        'callout:Propeli_Pincode_API/safeutil-sfdc/api/v1/sfi/fetchAreaByPincode';

    private List<Integer> codes;
    private List<String> bodies;
    private Boolean throwCallout;

    // Optional per-pincode responses (take priority over the default list)
    private Map<String, Integer> codeByPincode = new Map<String, Integer>();
    private Map<String, String>  bodyByPincode = new Map<String, String>();

    public Integer calls = 0;       // pincode API calls only
    public Integer tokenCalls = 0;
    public Integer tokenStatusCode = 200;
    public String tokenBody = '{"access_token":"fictional-test-token","expires_in":3600}';
    public Boolean throwTokenCallout = false;

    // Problems found inside the mock. Test must call assertClean().
    public List<String> violations = new List<String>();

    public PincodeApiMock(Integer statusCode, String body) {
        this.codes = new List<Integer>{statusCode};
        this.bodies = new List<String>{body};
        this.throwCallout = false;
    }

    public PincodeApiMock(List<Integer> codes, List<String> bodies) {
        System.assert(codes != null && !codes.isEmpty());
        System.assertEquals(codes.size(), bodies.size());
        this.codes = codes.clone();
        this.bodies = bodies.clone();
        this.throwCallout = false;
    }

    public PincodeApiMock(Boolean throwCallout) {
        this.throwCallout = throwCallout;
        this.codes = new List<Integer>{500};
        this.bodies = new List<String>{'{}'};
    }

    // ---------- Ready-made responses (confirmed API shapes) ----------

    // One or more areas. Region has a trailing space on purpose, like the real API.
    public static PincodeApiMock success(Integer numberOfAreas) {
        return new PincodeApiMock(200, successBody(numberOfAreas, 'MUMBAI '));
    }

    // Area found but no regionName
    public static PincodeApiMock successWithoutRegion() {
        return new PincodeApiMock(200, successBody(1, null));
    }

    // Pincode not serviceable: SUCCESS with data = {}
    public static PincodeApiMock notServiceable() {
        return new PincodeApiMock(200, notServiceableBody());
    }

    public static String successBody(Integer numberOfAreas, String regionName) {
        List<Object> rows = new List<Object>();
        for (Integer i = 0; i < numberOfAreas; i++) {
            Map<String, Object> row = new Map<String, Object>{
                'areaId' => i, 'areaCd' => 'SAMPLE_' + i, 'areaName' => 'BHIWANDI',
                'regionId' => 1, 'regionCd' => 'MUM'};
            if (regionName != null) row.put('regionName', regionName);
            rows.add(row);
        }
        return JSON.serialize(new Map<String, Object>{
            'message' => 'Fetch active area by pincode',
            'status'  => 'SUCCESS',
            'data'    => new Map<String, Object>{'responseData' => rows}});
    }

    public static String notServiceableBody() {
        return '{"message":"Fetch active area by pincode","data":{},"status":"SUCCESS"}';
    }

    // Different answer for a specific pincode, e.g. for mixed batches (T-21)
    public PincodeApiMock forPincode(String pincode, Integer statusCode, String body) {
        codeByPincode.put(pincode, statusCode);
        bodyByPincode.put(pincode, body);
        return this;
    }

    // Call at the end of the test
    public void assertClean() {
        System.assertEquals(0, violations.size(),
            'Mock found unexpected request details: ' + String.join(violations, ' | '));
    }

    // ---------- HttpCalloutMock ----------
    public HttpResponse respond(HttpRequest request) {
        check('POST'.equals(request.getMethod()), 'Method must be POST');

        if (request.getEndpoint() == TOKEN_ENDPOINT) {
            check('application/x-www-form-urlencoded'.equals(request.getHeader('Content-Type')),
                'Token request Content-Type');
            check('grant_type=client_credentials&scope=authtest%2Fwaybillapps'.equals(request.getBody()),
                'Token request body');
            tokenCalls++;
            if (throwTokenCallout) throw new CalloutException('Simulated token timeout');
            HttpResponse tokenResponse = new HttpResponse();
            tokenResponse.setStatusCode(tokenStatusCode);
            tokenResponse.setBody(tokenBody);
            return tokenResponse;
        }

        check(API_ENDPOINT.equals(request.getEndpoint()), 'Unexpected endpoint: ' + request.getEndpoint());
        check('application/json'.equals(request.getHeader('Content-Type')), 'API Content-Type');
        // Raw token: must not start with "Bearer "
        check('fictional-test-token'.equals(request.getHeader('Authorization')),
            'Authorization must be the raw token, no Bearer prefix');

        String pincode;
        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
            check(payload.size() == 1, 'Body must contain only pincode');
            pincode = (String) payload.get('pincode');
            check(pincode != null, 'pincode must be a String');
        } catch (Exception e) {
            violations.add('Bad request body: ' + e.getMessage());
        }

        calls++;
        if (throwCallout) throw new CalloutException('Simulated pincode callout timeout');

        Integer code;
        String body;
        if (pincode != null && codeByPincode.containsKey(pincode)) {
            code = codeByPincode.get(pincode);
            body = bodyByPincode.get(pincode);
        } else {
            Integer index = Math.min(calls - 1, codes.size() - 1);
            code = codes[index];
            body = bodies[index];
        }

        HttpResponse response = new HttpResponse();
        response.setStatusCode(code);
        response.setHeader('Content-Type', 'application/json');
        response.setBody(body);
        return response;
    }

    private void check(Boolean condition, String message) {
        if (!condition) violations.add(message);
    }
}