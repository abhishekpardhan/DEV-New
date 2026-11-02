/**
* @File Name          : PincodeLookupQueueable.cls
* @Description        : Looks up Lead pincodes through PropelI and updates Lead assignment and integration transactions
* @Author             : Abhishek
* @Group              : GT
* @Last Modified By   : Abhishek
* @Last Modified On   : 28/10/2026
*==============================================================================
* Ver         Date              Author              Modification
*==============================================================================
* 1.0         28/10/2026        Abhishek            Added class and method Created
**/
public without sharing class PincodeLookupQueueable implements Queueable, Database.AllowsCallouts {
    private static final String TOKEN_ENDPOINT = 'callout:Propeli_Token_API/oauth2/token';
    private static final String ENDPOINT =
        'callout:Propeli_Pincode_API/safeutil-sfdc/api/v1/sfi/fetchAreaByPincode';
    public static final Integer BATCH_SIZE = 50;

    @TestVisible private Map<String, String> txnToLead;

    public PincodeLookupQueueable(Map<String, String> txnToLead) {
        this.txnToLead = txnToLead.clone();
    }

    public enum LookupState { FOUND, NOT_FOUND, ERROR }
    public class LookupResult {
        public LookupState state;
        public String area;
        public String region;
        public String response;
        public Integer statusCode;
        public String error;
    }
    private class TokenResult { public String token; public String error; }

    // Divide integration transactions into groups of up to BATCH_SIZE and enqueue a
    // separate lookup job for each group, using the requested delay.
    public static void enqueueInChunks(Map<String, String> all, Integer delayMinutes) {
        Map<String, String> chunk = new Map<String, String>();
        for (String txnId : all.keySet()) {
            chunk.put(txnId, all.get(txnId));
            if (chunk.size() == BATCH_SIZE) {
                enqueueChunk(chunk, delayMinutes);
                chunk = new Map<String, String>();
            }
        }
        if (!chunk.isEmpty()) enqueueChunk(chunk, delayMinutes);
    }

    // Enqueue one group when the transaction has a Queueable slot available.
    // Otherwise log its transaction IDs so the Draft records can be replayed.
    private static void enqueueChunk(Map<String, String> chunk, Integer delayMinutes) {
        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new PincodeLookupQueueable(chunk), delayMinutes);
        } else {
            // Records stay Draft; bump No_of_Retries__c on them to replay (same as other integrations)
            ExceptionHandling.Exception('PincodeLookupQueueable', 'enqueueChunk',
                'Queueable limit reached. Draft transactions: ' + String.join(new List<String>(chunk.keySet()), ','));
        }
    }

    // Attach a finalizer, then process the job's integration transactions.
    // Log unexpected errors and register the affected transactions for retry.
    public void execute(QueueableContext ctx) {
        Set<Id> txnIds = new Set<Id>();
        for (String s : txnToLead.keySet()) txnIds.add((Id) s);

        System.attachFinalizer(new PincodeFinalizer(txnIds));

        try {
            process(txnIds);
        } catch (Exception e) {
            String msg = e.getTypeName() + ': ' + e.getMessage()
                + ' | Line ' + e.getLineNumber() + ' | ' + e.getStackTraceString();
            ExceptionHandling.Exception('PincodeLookupQueueable', 'execute', msg.abbreviate(32000));
            try {
                registerFailure(txnIds, msg);
            } catch (Exception ex) {
                ExceptionHandling.Exception('PincodeLookupQueueable', 'registerFailure', ex.getMessage());
            }
        }
    }

    // Read Draft transactions and look up each distinct pincode, reusing one
    // OAuth token. Update only still-Pending Leads, then save the lookup result,
    // failure, or retry state on each integration transaction.
    private void process(Set<Id> txnIds) {
        Integer maxAttempts = Integer.valueOf(Label.Max_Retries);

        List<Integration_Transaction__c> txns = [
            SELECT Id, Record_Id__c, Request__c, No_of_Retries__c, Status__c
            FROM Integration_Transaction__c
            WHERE Id IN :txnIds AND Status__c = 'Draft'
            ORDER BY Id
        ];
        if (txns.isEmpty()) return;

        Map<Id, String> pincodeByTxn = new Map<Id, String>();
        Map<String, LookupResult> results = new Map<String, LookupResult>();
        TokenResult token;
        // Reserve one available callout for the shared OAuth token request.
        Integer capacity = Math.max(0, Limits.getLimitCallouts() - Limits.getCallouts() - 1);

        for (Integration_Transaction__c t : txns) {
            String pin = pincodeOf(t);
            pincodeByTxn.put(t.Id, pin);
            // Reuse the result when several transactions request the same pincode.
            if (String.isBlank(pin) || results.containsKey(pin)) continue;

            if (results.size() >= capacity) {
                results.put(pin, errorResult('Callout limit reached for this job.'));
                continue;
            }
            if (token == null) token = fetchToken();
            results.put(pin, token.error == null ? callPincodeApi(pin, token.token)
                                                 : errorResult(token.error));
        }

        // Lock and update only Leads that still need a lookup result.
        Set<Id> leadIds = new Set<Id>();
        for (Integration_Transaction__c t : txns) leadIds.add((Id) t.Record_Id__c);
        Map<Id, Lead> leads = new Map<Id, Lead>([
            SELECT Id, Assign_to_Central_Desk__c
            FROM Lead
            WHERE Id IN :leadIds AND Pincode_Lookup_Status__c = 'Pending'
            FOR UPDATE
        ]);

        List<Lead> updates = new List<Lead>();
        List<Integration_Transaction__c> updateTxns = new List<Integration_Transaction__c>();
        List<Lead> assignable = new List<Lead>();
        Id queueId;

        for (Integration_Transaction__c t : txns) {
            Lead lead = leads.get((Id) t.Record_Id__c);
            // A completed or removed Lead no longer needs this transaction.
            if (lead == null) {
                t.Status__c = 'Success';
                t.Error_Message__c = 'Lead no longer Pending; skipped.';
                continue;
            }

            String pin = pincodeByTxn.get(t.Id);
            LookupResult r;
            // A blank pincode is treated as not found without making a callout.
            if (String.isBlank(pin)) {
                r = new LookupResult();
                r.state = LookupState.NOT_FOUND;
                r.error = 'Blank pincode; no callout made.';
            } else {
                r = results.get(pin);
            }
            t.Status_Code__c = r.statusCode;
            t.Response__c = fit(r.response, Integration_Transaction__c.Response__c);

            Lead change = new Lead(Id = lead.Id);
            if (String.isNotBlank(pin)) change.PostalCode = pin;

            if (r.state == LookupState.ERROR) {
                Integer nextRetry = (t.No_of_Retries__c == null ? 0 : Integer.valueOf(t.No_of_Retries__c)) + 1;
                t.Error_Message__c = fit(r.error, Integration_Transaction__c.Error_Message__c);
                if (nextRetry < maxAttempts) {
                    t.No_of_Retries__c = nextRetry; // stays Draft; handler afterUpdate re-enqueues
                    continue;
                }
                t.Status__c = 'Fail'; // attempts used up
                if (queueId == null) queueId = LeadAssignmentService.centralDeskQueueId();
                applyCentralDesk(change, queueId, 'Failed');
            } else if (r.state == LookupState.FOUND) {
                t.Status__c = 'Success';
                change.Area__c = r.area;
                change.Region__c = r.region;
                change.Pincode_Lookup_Status__c = 'Completed';
                // Only Leads flagged for Central Desk need owner assignment here.
                if (lead.Assign_to_Central_Desk__c == true) assignable.add(change);
            } else { // NOT_FOUND
                t.Status__c = 'Success';
                if (queueId == null) queueId = LeadAssignmentService.centralDeskQueueId();
                applyCentralDesk(change, queueId, 'Not Found');
            }
            updates.add(change);
            // Keep the transaction at the same index as its Lead update result.
            updateTxns.add(t);
        }

        LeadAssignmentService.assignAreaManager(assignable);

        // Suppress normal Lead assignment while this job writes lookup results.
        List<ExceptionHandler__c> failures = new List<ExceptionHandler__c>();
        Boolean previousJobUpdate = LeadAssignmentService.isJobUpdate;
        try {
            LeadAssignmentService.isJobUpdate = true;
            if (!updates.isEmpty()) {
                Database.SaveResult[] saves = Database.update(updates, false);
                for (Integer i = 0; i < saves.size(); i++) {
                    if (!saves[i].isSuccess()) {
                        List<String> errs = new List<String>();
                        for (Database.Error err : saves[i].getErrors()) {
                            errs.add(err.getStatusCode() + ': ' + err.getMessage());
                        }
                        String msg = 'Lead writeback failed for ' + updates[i].Id + ': ' + String.join(errs, '; ');
                        updateTxns[i].Status__c = 'Fail';
                        updateTxns[i].Error_Message__c = fit(msg, Integration_Transaction__c.Error_Message__c);
                        failures.add(new ExceptionHandler__c(
                            Name = 'PincodeLookupQueueable', Class_Name__c = 'process', Error_Message__c = msg));
                    }
                }
            }
        } finally {
            LeadAssignmentService.isJobUpdate = previousJobUpdate;
        }

        // Updating Draft transactions fires the handler that schedules retries.
        Database.SaveResult[] txnSaves = Database.update(txns, false);
        for (Integer i = 0; i < txnSaves.size(); i++) {
            if (!txnSaves[i].isSuccess()) {
                failures.add(new ExceptionHandler__c(Name = 'PincodeLookupQueueable', Class_Name__c = 'process',
                    Error_Message__c = 'Integration_Transaction update failed: '
                        + txnSaves[i].getErrors()[0].getMessage()));
            }
        }
        ExceptionHandling.Exceptions(failures);
    }

    // Handle a failure that affected the whole job. Increment retry counts on
    // Draft transactions; when attempts are exhausted, mark them failed and
    // send any still-Pending Leads to Central Desk.
    public static void registerFailure(Set<Id> txnIds, String message) {
        Integer maxAttempts = Integer.valueOf(Label.Max_Retries);
        List<Integration_Transaction__c> txns = [
            SELECT Id, Record_Id__c, No_of_Retries__c
            FROM Integration_Transaction__c
            WHERE Id IN :txnIds AND Status__c = 'Draft'
        ];
        Set<Id> exhausted = new Set<Id>();
        for (Integration_Transaction__c t : txns) {
            Integer nextRetry = (t.No_of_Retries__c == null ? 0 : Integer.valueOf(t.No_of_Retries__c)) + 1;
            t.Error_Message__c = fit(message, Integration_Transaction__c.Error_Message__c);
            if (nextRetry < maxAttempts) {
                t.No_of_Retries__c = nextRetry;
            } else {
                t.Status__c = 'Fail';
                exhausted.add((Id) t.Record_Id__c);
            }
        }
        // Only Leads still Pending need fallback assignment after retries end.
        if (!exhausted.isEmpty()) {
            List<Lead> stuck = [SELECT Id FROM Lead
                                WHERE Id IN :exhausted AND Pincode_Lookup_Status__c = 'Pending'];
            if (!stuck.isEmpty()) {
                Id queueId = LeadAssignmentService.centralDeskQueueId();
                for (Lead l : stuck) applyCentralDesk(l, queueId, 'Failed');
                Boolean previous = LeadAssignmentService.isJobUpdate;
                try {
                    LeadAssignmentService.isJobUpdate = true;
                    Database.update(stuck, false);
                } finally {
                    LeadAssignmentService.isJobUpdate = previous;
                }
            }
        }
        if (!txns.isEmpty()) Database.update(txns, false);
    }

    // Mark an unresolved or failed Lead as evaluated and assign it to the
    // Central Desk queue with the supplied lookup status.
    private static void applyCentralDesk(Lead row, Id queueId, String status) {
        row.OwnerId = queueId;
        row.Assign_to_Central_Desk__c = true;
        row.Assignment_Evaluated__c = true;
        row.Pincode_Lookup_Status__c = status;
    }

    // Extract the pincode from the transaction's JSON request. Return null
    // when the request is invalid so the job can handle it without a callout.
    private static String pincodeOf(Integration_Transaction__c t) {
        try {
            Map<String, Object> req = (Map<String, Object>) JSON.deserializeUntyped(t.Request__c);
            String pin = (String) req.get('pincode');
            return pin == null ? null : pin.trim();
        } catch (Exception e) {
            return null;
        }
    }

    private static LookupResult errorResult(String message) {
        LookupResult r = new LookupResult();
        r.state = LookupState.ERROR;
        r.error = message;
        return r;
    }

    // Perform one standalone pincode lookup by fetching an OAuth token first.
    // Return a lookup error if token retrieval fails.
    @TestVisible
    private static LookupResult callApi(String pincode) {
        TokenResult tr = fetchToken();
        return tr.error == null ? callPincodeApi(pincode, tr.token) : errorResult(tr.error);
    }

    // Request an OAuth access token from the configured token endpoint.
    // Return the token or an error describing a failed or invalid response.
    private static TokenResult fetchToken() {
        TokenResult result = new TokenResult();
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(TOKEN_ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setTimeout(7000);
            request.setBody('grant_type=client_credentials&scope='
                + EncodingUtil.urlEncode('authtest/waybillapps', 'UTF-8'));
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() != 200) {
                result.error = 'Token endpoint HTTP ' + response.getStatusCode();
            } else {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                result.token = body == null ? null : (String) body.get('access_token');
                if (String.isBlank(result.token)) result.error = 'Token response is missing access_token.';
            }
        } catch (Exception ex) {
            result.error = 'Token request failed: ' + ex.getTypeName() + ': ' + ex.getMessage();
        }
        return result;
    }

    // Send the pincode and token to PropelI, then classify the response.
    // Return area and region for one valid match, NOT_FOUND for no match,
    // or ERROR for a callout or response failure.
    private static LookupResult callPincodeApi(String pincode, String token) {
        LookupResult result = new LookupResult();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', token); // raw token, no "Bearer "
        request.setTimeout(7000);
        request.setBody(JSON.serialize(new Map<String, String>{ 'pincode' => pincode }));
        try {
            HttpResponse response = new Http().send(request);
            result.statusCode = response.getStatusCode();
            // Remove the token before storing the response on a transaction.
            result.response = response.getBody() == null ? null : response.getBody().replace(token, '[REDACTED]');
            if (result.statusCode != 200) {
                result.state = LookupState.ERROR;
                result.error = 'HTTP ' + result.statusCode;
                return result;
            }
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(result.response);
            if (payload == null || (String) payload.get('status') != 'SUCCESS') {
                result.state = LookupState.ERROR;
                result.error = 'Response status is not SUCCESS.';
                return result;
            }
            Map<String, Object> data = (Map<String, Object>) payload.get('data');
            if (data == null) throw new CalloutException('Missing data object.');
            // PropelI uses an empty data object when the pincode is not served.
            if (data.isEmpty()) { // confirmed out-of-service shape: data = {}
                result.state = LookupState.NOT_FOUND;
                return result;
            }
            List<Object> rows = (List<Object>) data.get('responseData');
            if (rows == null) throw new CalloutException('Missing responseData array.');
            // A single response row is required to assign one area and region.
            if (rows.size() != 1) {
                result.state = LookupState.NOT_FOUND;
                return result;
            }
            Map<String, Object> area = (Map<String, Object>) rows[0];
            result.area = (String) area.get('areaName');
            if (String.isBlank(result.area)) throw new CalloutException('Missing areaName.');
            result.region = (String) area.get('regionName');
            if (String.isBlank(result.region)) throw new CalloutException('Missing regionName.');
            result.area = result.area.trim();
            result.region = result.region.trim();
            result.state = LookupState.FOUND;
        } catch (Exception ex) {
            result.state = LookupState.ERROR;
            result.error = ex.getTypeName() + ': ' + ex.getMessage().replace(token, '[REDACTED]');
        }
        return result;
    }

    private static String fit(String value, Schema.SObjectField field) {
        Integer maximum = field.getDescribe().getLength();
        return value == null || value.length() <= maximum ? value : value.substring(0, maximum);
    }

    // Handle failures that stop the Queueable before its normal error handling
    // can finish, so its transactions are still recorded for retry or failure.
    public without sharing class PincodeFinalizer implements Finalizer {
        private Set<Id> txnIds;

        public PincodeFinalizer(Set<Id> txnIds) {
            this.txnIds = txnIds;
        }

        // When the parent job ends with an unhandled exception, log the error
        // and update its Draft transactions through registerFailure.
        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() != ParentJobResult.UNHANDLED_EXCEPTION) return;
            try {
                Exception ex = ctx.getException();
                String msg = (ex.getTypeName() + ': ' + ex.getMessage() + ' | ' + ex.getStackTraceString())
                    .abbreviate(32000);
                ExceptionHandling.Exception('PincodeLookupQueueable', 'execute', msg);
                PincodeLookupQueueable.registerFailure(txnIds, msg); // bumps retries or fails the leads
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'PincodeFinalizer failed: ' + e.getMessage());
            }
        }
    }
}