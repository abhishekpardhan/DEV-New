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
    // Maximum number of transaction IDs placed in each enqueued job.
    public static final Integer BATCH_SIZE = 50;

    // The map keys identify integration transactions to process.
    @TestVisible private Map<String, String> txnToLead;

    /**
     * Stores a copy of the transaction-to-Lead map for this job.
     * @param txnToLead Transaction IDs keyed to their Lead IDs.
     */
    public PincodeLookupQueueable(Map<String, String> txnToLead) {
        this.txnToLead = txnToLead.clone();
    }

    // FOUND has one valid area and region; NOT_FOUND has no usable match;
    // ERROR means a token, callout, or response problem occurred.
    public enum LookupState { FOUND, NOT_FOUND, ERROR }
    // Carries the lookup classification and response details for one pincode.
    public class LookupResult {
        public LookupState state;
        public String area;
        public String region;
        public String response;
        public Integer statusCode;
        public String error;
    }
    // Carries either the OAuth access token or a token-request error.
    private class TokenResult { public String token; public String error; }

    /**
     * Enqueues transaction IDs in groups of at most BATCH_SIZE, using the
     * requested delay for each job. A final smaller group is also enqueued.
     * @param all Transaction IDs keyed to their Lead IDs.
     * @param delayMinutes Delay passed to System.enqueueJob.
     */
    public static void enqueueInChunks(Map<String, String> all, Integer delayMinutes) {
        Map<String, String> chunk = new Map<String, String>();
        for (String txnId : all.keySet()) {
            chunk.put(txnId, all.get(txnId));
            // A full group starts its own Queueable job.
            if (chunk.size() == BATCH_SIZE) {
                enqueueChunk(chunk, delayMinutes);
                chunk = new Map<String, String>();
            }
        }
        // Do not lose the final group when it has fewer than BATCH_SIZE IDs.
        if (!chunk.isEmpty()) enqueueChunk(chunk, delayMinutes);
    }

    // Enqueues one group if a Queueable slot is available. Otherwise, logs
    // the transaction IDs and leaves their records in their current state.
    private static void enqueueChunk(Map<String, String> chunk, Integer delayMinutes) {
        // The limit check prevents an enqueue attempt when no slot remains.
        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new PincodeLookupQueueable(chunk), delayMinutes);
        } else {
            // This branch logs the IDs; it does not change retry counts.
            logMessage('enqueueChunk', 'Queueable limit reached. Draft transactions: '
                + String.join(new List<String>(chunk.keySet()), ','));
        }
    }

    /**
     * Attaches a finalizer and processes the supplied transactions. If
     * processing throws, logs the exception and registers Draft transactions
     * for another attempt or final failure.
     * @param ctx Queueable execution context.
     */
    public void execute(QueueableContext ctx) {
        Set<Id> txnIds = new Set<Id>();
        for (String s : txnToLead.keySet()) txnIds.add((Id) s);

        // The finalizer handles an unhandled failure that stops this job.
        System.attachFinalizer(new PincodeFinalizer(txnIds));

        try {
            process(txnIds);
        // Record a caught processing error and update its Draft transactions.
        } catch (Exception e) {
            String msg = e.getTypeName() + ': ' + e.getMessage()
                + ' | Line ' + e.getLineNumber() + ' | ' + e.getStackTraceString();
            logMessage('execute', msg.abbreviate(32000));
            try {
                registerFailure(txnIds, msg);
            // Log a second error if failure registration also throws.
            } catch (Exception ex) {
                logMessage('registerFailure', ex.getMessage());
            }
        }
    }

    // Processes Draft transactions only for checked Leads still Pending.
    // Eligible transactions share one OAuth token and reuse results for the
    // same pincode. Unchecked or completed Leads receive no callout or update.
    private void process(Set<Id> txnIds) {
        Integer maxAttempts = Integer.valueOf(Label.Max_Retries);

        List<Integration_Transaction__c> txns = [
            SELECT Id, Record_Id__c, Request__c, No_of_Retries__c, Status__c
            FROM Integration_Transaction__c
            WHERE Id IN :txnIds AND Status__c = 'Draft'
            ORDER BY Id
        ];
        // No Draft transaction means there is no callout or DML to perform.
        if (txns.isEmpty()) return;

        // Check Pending status and the assignment checkbox before any callout,
        // without holding Lead row locks during the external request.
        Set<Id> leadIds = new Set<Id>();
        for (Integration_Transaction__c t : txns) leadIds.add((Id) t.Record_Id__c);
        Set<Id> eligibleLeadIds = new Set<Id>();
        for (Lead candidate : [
            SELECT Id
            FROM Lead
            WHERE Id IN :leadIds AND Pincode_Lookup_Status__c = 'Pending'
              AND Assign_to_Central_Desk__c = true
        ]) eligibleLeadIds.add(candidate.Id);

        Map<Id, String> pincodeByTxn = new Map<Id, String>();
        Map<String, LookupResult> results = new Map<String, LookupResult>();
        TokenResult token;
        // Reserve one available callout for the shared OAuth token request.
        Integer capacity = Math.max(0, Limits.getLimitCallouts() - Limits.getCallouts() - 1);

        for (Integration_Transaction__c t : txns) {
            // A Lead that is unchecked or no longer Pending needs no callout.
            if (!eligibleLeadIds.contains((Id) t.Record_Id__c)) continue;
            String pin = pincodeOf(t);
            pincodeByTxn.put(t.Id, pin);
            // A blank pincode needs no callout. Duplicate pincodes reuse the
            // first result in this job.
            if (String.isBlank(pin) || results.containsKey(pin)) continue;

            // Capacity overflow becomes an ERROR result; the retry decision
            // depends on the transaction's remaining attempts below.
            if (results.size() >= capacity) {
                results.put(pin, errorResult('Callout limit reached for this job.'));
                continue;
            }
            // Fetch the token only once, even when several pincodes are looked up.
            if (token == null) token = fetchToken();
            // A token error skips the pincode API and is handled as ERROR below.
            results.put(pin, token.error == null ? callPincodeApi(pin, token.token)
                                                 : errorResult(token.error));
        }

        // Recheck and lock Leads after callouts; an unchecked or completed Lead
        // is excluded from the result writeback even if it was eligible earlier.
        Map<Id, Lead> leads = new Map<Id, Lead>([
            SELECT Id, Assign_to_Central_Desk__c
            FROM Lead
            WHERE Id IN :eligibleLeadIds AND Pincode_Lookup_Status__c = 'Pending'
              AND Assign_to_Central_Desk__c = true
            FOR UPDATE
        ]);

        List<Lead> updates = new List<Lead>();
        List<Integration_Transaction__c> updateTxns = new List<Integration_Transaction__c>();
        List<Lead> assignable = new List<Lead>();
        Id queueId;

        for (Integration_Transaction__c t : txns) {
            Lead lead = leads.get((Id) t.Record_Id__c);
            // If the Lead is unchecked, absent, or no longer Pending, finish
            // its transaction with a skip message and make no Lead update.
            if (lead == null) {
                t.Status__c = 'Success';
                t.Error_Message__c = 'Lead no longer Pending; skipped.';
                continue;
            }

            String pin = pincodeByTxn.get(t.Id);
            LookupResult r;
            // A blank pincode becomes NOT_FOUND without making a callout.
            if (String.isBlank(pin)) {
                r = new LookupResult();
                r.state = LookupState.NOT_FOUND;
                r.error = 'Blank pincode; no callout made.';
            } else {
                r = results.get(pin);
            }
            t.Status_Code__c = r.statusCode;
            t.Response__c = fit(r.response, Integration_Transaction__c.Response__c);

            Lead change = new Lead(
                Id = lead.Id,
                Assign_to_Central_Desk__c = lead.Assign_to_Central_Desk__c
            );
            // Only a nonblank request pincode overwrites Lead.PostalCode.
            if (String.isNotBlank(pin)) change.PostalCode = pin;

            // ERROR: store the error and either retry the Draft transaction or
            // fail it after the allowed attempts are exhausted.
            if (r.state == LookupState.ERROR) {
                Integer nextRetry = (t.No_of_Retries__c == null ? 0 : Integer.valueOf(t.No_of_Retries__c)) + 1;
                t.Error_Message__c = fit(r.error, Integration_Transaction__c.Error_Message__c);
                // A retry increments No_of_Retries__c. The Lead stays Pending,
                // and the Draft transaction update schedules another attempt.
                if (nextRetry < maxAttempts) {
                    t.No_of_Retries__c = nextRetry; // stays Draft; handler afterUpdate re-enqueues
                    continue;
                }
                // Exhausted attempts fail the transaction and set the Lead's
                // lookup status to Failed. Owner changes only if its flag is true.
                t.Status__c = 'Fail'; // no further lookup attempt is scheduled
                if (queueId == null) queueId = LeadAssignmentService.centralDeskQueueId();
                applyCentralDesk(change, queueId, 'Failed');
            // FOUND: complete the Lead lookup and mark the transaction Success.
            } else if (r.state == LookupState.FOUND) {
                t.Status__c = 'Success';
                change.Area__c = r.area;
                change.Region__c = r.region;
                change.Pincode_Lookup_Status__c = 'Completed';
                // Only flagged Leads are assigned to an Area Manager or queue.
                if (lead.Assign_to_Central_Desk__c == true) assignable.add(change);
            // NOT_FOUND: mark the transaction Success and the Lead Not Found.
            // The owner moves to Central Desk only when its flag is true.
            } else { // NOT_FOUND
                t.Status__c = 'Success';
                if (queueId == null) queueId = LeadAssignmentService.centralDeskQueueId();
                applyCentralDesk(change, queueId, 'Not Found');
            }
            updates.add(change);
            // Keep the transaction at the same index as its Lead update result.
            updateTxns.add(t);
        }

        // Apply the unique-manager or Central Desk rule to flagged FOUND Leads.
        LeadAssignmentService.assignAreaManager(assignable);

        // Suppress the Lead trigger's assignment logic during this writeback.
        Map<String, Set<String>> exceptionMap = new Map<String, Set<String>>();
        Boolean previousJobUpdate = LeadAssignmentService.isJobUpdate;
        try {
            LeadAssignmentService.isJobUpdate = true;
            // Partial system-mode DML lets successful Leads save even if
            // another Lead fails validation or trigger processing.
            if (!updates.isEmpty()) {
                Database.SaveResult[] saves = Database.update(updates, false, AccessLevel.SYSTEM_MODE);
                for (Integer i = 0; i < saves.size(); i++) {
                    // A failed Lead update makes its paired transaction Fail.
                    if (!saves[i].isSuccess()) {
                        List<String> errs = new List<String>();
                        for (Database.Error err : saves[i].getErrors()) {
                            errs.add(err.getStatusCode() + ': ' + err.getMessage());
                        }
                        String msg = 'Lead writeback failed for ' + updates[i].Id + ': ' + String.join(errs, '; ');
                        updateTxns[i].Status__c = 'Fail';
                        updateTxns[i].Error_Message__c = fit(msg, Integration_Transaction__c.Error_Message__c);
                        collectErrors(exceptionMap, 'Lead update', updates[i].Id, saves[i].getErrors());
                    }
                }
            }
        // Always restore the prior guard value for later work in this transaction.
        } finally {
            LeadAssignmentService.isJobUpdate = previousJobUpdate;
        }

        // Save all transaction outcomes in system mode. Updating Draft retry
        // counts invokes the handler that schedules another lookup job.
        Database.SaveResult[] txnSaves = Database.update(txns, false, AccessLevel.SYSTEM_MODE);
        for (Integer i = 0; i < txnSaves.size(); i++) {
            // Keep every failed transaction update in the grouped error log.
            if (!txnSaves[i].isSuccess()) {
                collectErrors(exceptionMap, 'Integration_Transaction update', txns[i].Id,
                    txnSaves[i].getErrors());
            }
        }
        logGroupedErrors('process', exceptionMap);
    }

    /**
     * Records a job-level failure on Draft transactions. Transactions below
     * Max_Retries gain one retry; exhausted transactions become Fail. Still
     * Pending Leads that are still checked get lookup status Failed and are
     * assigned to the Central Desk queue when retries are exhausted.
     * @param txnIds Transaction IDs affected by the failure.
     * @param message Error message stored on the transactions.
     */
    public static void registerFailure(Set<Id> txnIds, String message) {
        Integer maxAttempts = Integer.valueOf(Label.Max_Retries);
        Map<String, Set<String>> exceptionMap = new Map<String, Set<String>>();
        List<Integration_Transaction__c> txns = [
            SELECT Id, Record_Id__c, No_of_Retries__c
            FROM Integration_Transaction__c
            WHERE Id IN :txnIds AND Status__c = 'Draft'
        ];
        Set<Id> exhausted = new Set<Id>();
        for (Integration_Transaction__c t : txns) {
            Integer nextRetry = (t.No_of_Retries__c == null ? 0 : Integer.valueOf(t.No_of_Retries__c)) + 1;
            t.Error_Message__c = fit(message, Integration_Transaction__c.Error_Message__c);
            // Remaining attempts keep the transaction Draft and increment retries.
            if (nextRetry < maxAttempts) {
                t.No_of_Retries__c = nextRetry;
            } else {
                // Exhausted attempts fail the transaction and identify its Lead.
                t.Status__c = 'Fail';
                exhausted.add((Id) t.Record_Id__c);
            }
        }
        // Only exhausted transactions for checked, Pending Leads can change
        // a Lead's lookup outcome or owner.
        if (!exhausted.isEmpty()) {
            List<Lead> stuck = [SELECT Id, Assign_to_Central_Desk__c FROM Lead
                                WHERE Id IN :exhausted AND Pincode_Lookup_Status__c = 'Pending'
                                  AND Assign_to_Central_Desk__c = true];
            // A Lead no longer Pending is left unchanged.
            if (!stuck.isEmpty()) {
                Id queueId = LeadAssignmentService.centralDeskQueueId();
                // Every selected Lead becomes Failed; only flagged Leads move
                // to Central Desk and become assignment evaluated.
                for (Lead l : stuck) applyCentralDesk(l, queueId, 'Failed');
                Boolean previous = LeadAssignmentService.isJobUpdate;
                try {
                    LeadAssignmentService.isJobUpdate = true;
                    Database.SaveResult[] leadSaves = Database.update(
                        stuck, false, AccessLevel.SYSTEM_MODE);
                    for (Integer i = 0; i < leadSaves.size(); i++) {
                        // Group every failed Lead writeback with its Lead ID.
                        if (!leadSaves[i].isSuccess()) {
                            collectErrors(exceptionMap, 'Lead retry update', stuck[i].Id,
                                leadSaves[i].getErrors());
                        }
                    }
                // Restore the assignment guard even if the update throws.
                } finally {
                    LeadAssignmentService.isJobUpdate = previous;
                }
            }
        }
        // Persist retry or failure state for every Draft transaction found.
        if (!txns.isEmpty()) {
            Database.SaveResult[] txnSaves = Database.update(txns, false, AccessLevel.SYSTEM_MODE);
            for (Integer i = 0; i < txnSaves.size(); i++) {
                // Group each failed transaction update with its transaction ID.
                if (!txnSaves[i].isSuccess()) {
                    collectErrors(exceptionMap, 'Integration_Transaction retry update',
                        txns[i].Id, txnSaves[i].getErrors());
                }
            }
        }
        logGroupedErrors('registerFailure', exceptionMap);
    }

    // Groups errors with the same operation, status code, and message, then
    // adds each affected record ID to that group's set.
    private static void collectErrors(Map<String, Set<String>> exceptionMap, String operation,
        Id recordId, List<Database.Error> errors) {
        for (Database.Error error : errors) {
            String key = operation + ': ' + error.getStatusCode() + ': ' + error.getMessage();
            // The first occurrence creates the group; later records reuse it.
            if (!exceptionMap.containsKey(key)) exceptionMap.put(key, new Set<String>());
            exceptionMap.get(key).add(String.valueOf(recordId));
        }
    }

    // Inserts one ExceptionHandler__c per grouped error in system mode, with
    // its affected record IDs when present. Failed log inserts go to debug.
    private static void logGroupedErrors(String methodName, Map<String, Set<String>> exceptionMap) {
        // No DML is needed when there are no errors to log.
        if (exceptionMap.isEmpty()) return;
        List<ExceptionHandler__c> logs = new List<ExceptionHandler__c>();
        for (String error : exceptionMap.keySet()) {
            String message = error;
            // A standalone exception has no record IDs; DML errors do.
            if (!exceptionMap.get(error).isEmpty()) {
                message += ' | Record IDs: '
                    + String.join(new List<String>(exceptionMap.get(error)), ',');
            }
            logs.add(new ExceptionHandler__c(
                Name = 'PincodeLookupQueueable',
                Class_Name__c = methodName,
                Error_Message__c = fit(message, ExceptionHandler__c.Error_Message__c)
            ));
        }
        Database.SaveResult[] logSaves = Database.insert(logs, false, AccessLevel.SYSTEM_MODE);
        for (Integer i = 0; i < logSaves.size(); i++) {
            // Do not recursively insert another log if an exception log fails.
            if (!logSaves[i].isSuccess()) {
                for (Database.Error error : logSaves[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Exception log insert failed: ' + error.getMessage());
                }
            }
        }
    }

    // Logs one standalone error without attaching record IDs.
    private static void logMessage(String methodName, String message) {
        Map<String, Set<String>> errors = new Map<String, Set<String>>{
            message => new Set<String>()
        };
        logGroupedErrors(methodName, errors);
    }

    // Sets the supplied lookup status for every Lead passed in. Only a Lead
    // already flagged for Central Desk receives the queue owner and an
    // evaluated assignment flag.
    private static void applyCentralDesk(Lead row, Id queueId, String status) {
        // Unflagged Leads keep their current owner and evaluated flag.
        row.Assignment_Evaluated__c = true;
        row.OwnerId = queueId;
        row.Pincode_Lookup_Status__c = status;
    }

    // Returns the trimmed pincode from the JSON request. Missing, invalid,
    // or unreadable requests return null and make no pincode API call.
    private static String pincodeOf(Integration_Transaction__c t) {
        try {
            Map<String, Object> req = (Map<String, Object>) JSON.deserializeUntyped(t.Request__c);
            String pin = (String) req.get('pincode');
            return pin == null ? null : pin.trim();
        } catch (Exception e) {
            return null;
        }
    }

    // Wraps a message as a lookup ERROR result.
    private static LookupResult errorResult(String message) {
        LookupResult r = new LookupResult();
        r.state = LookupState.ERROR;
        r.error = message;
        return r;
    }

    // Performs one standalone pincode lookup. A token failure returns ERROR
    // without calling the pincode endpoint.
    @TestVisible
    private static LookupResult callApi(String pincode) {
        TokenResult tr = fetchToken();
        // Only a successful token response allows the pincode API call.
        return tr.error == null ? callPincodeApi(pincode, tr.token) : errorResult(tr.error);
    }

    // Requests an OAuth token from the configured endpoint and returns either
    // its access_token or an error for a failed or invalid response.
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
            // Any HTTP status other than 200 prevents a pincode lookup.
            if (response.getStatusCode() != 200) {
                result.error = 'Token endpoint HTTP ' + response.getStatusCode();
            } else {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                result.token = body == null ? null : (String) body.get('access_token');
                // A 200 response without access_token is still a token error.
                if (String.isBlank(result.token)) result.error = 'Token response is missing access_token.';
            }
        // Transport or parsing exceptions become token errors.
        } catch (Exception ex) {
            result.error = 'Token request failed: ' + ex.getTypeName() + ': ' + ex.getMessage();
        }
        return result;
    }

    // Sends a pincode to PropelI and classifies the response. One valid row
    // with areaName and regionName returns FOUND; zero or multiple rows return
    // NOT_FOUND; HTTP, response-shape, and callout failures return ERROR.
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
            // A non-200 response is an ERROR, with its HTTP status retained.
            if (result.statusCode != 200) {
                result.state = LookupState.ERROR;
                result.error = 'HTTP ' + result.statusCode;
                return result;
            }
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(result.response);
            // The response must contain a SUCCESS status before reading data.
            if (payload == null || (String) payload.get('status') != 'SUCCESS') {
                result.state = LookupState.ERROR;
                result.error = 'Response status is not SUCCESS.';
                return result;
            }
            Map<String, Object> data = (Map<String, Object>) payload.get('data');
            // Missing data is a response error, while empty data is NOT_FOUND.
            if (data == null) throw new CalloutException('Missing data object.');
            // PropelI uses an empty data object when the pincode is not served.
            if (data.isEmpty()) { // empty data has no area or region match
                result.state = LookupState.NOT_FOUND;
                return result;
            }
            List<Object> rows = (List<Object>) data.get('responseData');
            // A missing responseData array is an error, not an empty result.
            if (rows == null) throw new CalloutException('Missing responseData array.');
            // A single response row is required to assign one area and region.
            if (rows.size() != 1) {
                result.state = LookupState.NOT_FOUND;
                return result;
            }
            Map<String, Object> area = (Map<String, Object>) rows[0];
            result.area = (String) area.get('areaName');
            // One row requires both a nonblank area and a nonblank region.
            if (String.isBlank(result.area)) throw new CalloutException('Missing areaName.');
            result.region = (String) area.get('regionName');
            if (String.isBlank(result.region)) throw new CalloutException('Missing regionName.');
            result.area = result.area.trim();
            result.region = result.region.trim();
            result.state = LookupState.FOUND;
        // Convert callout, casting, and shape exceptions to an ERROR result.
        } catch (Exception ex) {
            result.state = LookupState.ERROR;
            result.error = ex.getTypeName() + ': ' + ex.getMessage().replace(token, '[REDACTED]');
        }
        return result;
    }

    // Truncates a value to the target field's declared length; preserves null.
    private static String fit(String value, Schema.SObjectField field) {
        Integer maximum = field.getDescribe().getLength();
        return value == null || value.length() <= maximum ? value : value.substring(0, maximum);
    }

    // Handles an unhandled parent Queueable failure in a finalizer transaction
    // so affected Draft transactions can be registered for retry or failure.
    public without sharing class PincodeFinalizer implements Finalizer {
        private Set<Id> txnIds;

        /**
         * Stores the transaction IDs to handle if the parent job fails.
         * @param txnIds Transaction IDs from the parent Queueable.
         */
        public PincodeFinalizer(Set<Id> txnIds) {
            this.txnIds = txnIds;
        }

        /**
         * Logs an unhandled parent-job exception and registers its Draft
         * transactions for retry or failure. Other job outcomes do nothing.
         * @param ctx Parent Queueable finalizer context.
         */
        public void execute(FinalizerContext ctx) {
            // Only an unhandled parent exception needs finalizer recovery.
            if (ctx.getResult() != ParentJobResult.UNHANDLED_EXCEPTION) return;
            try {
                Exception ex = ctx.getException();
                String msg = (ex.getTypeName() + ': ' + ex.getMessage() + ' | ' + ex.getStackTraceString())
                    .abbreviate(32000);
                PincodeLookupQueueable.logMessage('execute', msg);
                PincodeLookupQueueable.registerFailure(txnIds, msg); // retries or fails Draft transactions
            // If finalizer handling itself fails, record the error in debug.
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'PincodeFinalizer failed: ' + e.getMessage());
            }
        }
    }
}