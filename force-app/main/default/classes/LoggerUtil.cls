/**
    * @File Name          : LoggerUtil.cls
    * @Description        : This class is used to create the Logger records for error and API
    * @Author             : Deepak Kumar
    * @Group              : Techmatrix
    * @Last Modified By   : Deepak
    * @Last Modified On   : 07-07-2021
    * @Modification Log   :
    *==============================================================================
    * Ver         Date                     Author                 Modification
    *==============================================================================
    * 1.0         07-07-2021              Deepak         Initial Version
    * 1.1         30-07-2021              Deepak         Added createAPILog Method
 */

public without sharing class LoggerUtil {

    /**
     @Author          : Deepak
     @Company         : TechMatrix Consulting
     @Description     : This method is used to create Error Logger Records
     @Date            : 07/07/2021
    */
    public static String createErrorLog(
        String className,
        String methodName,
        String expType,
        String expMessage,
        String stackTraceString,
        String otherInfo
    ) {
        Error_Log__c errorLog = buildErrorLog(
            className,
            methodName,
            expType,
            expMessage,
            stackTraceString,
            otherInfo
        );

        insert errorLog;
        return errorLog.Id;
    }

    // Build Error Logger record.
    public static Error_Log__c buildErrorLog(
        String className,
        String methodName,
        String expType,
        String expMessage,
        String stackTraceString,
        String otherInfo
    ) {
        return new Error_Log__c(
            Class_Name__c = className,
            Method_Name__c = methodName,
            Exception_Type__c = expType,
            Exception_Message__c = expMessage,
            Stack_Trace_String__c = stackTraceString,
            Component_Name_Other_Information__c = otherInfo
        );
    }

    // Insert Error Logs bulk.
    public static void createErrorLogs(List<Error_Log__c> errorLogs) {
        if (errorLogs == null || errorLogs.isEmpty()) {
            return;
        }

        Database.insert(errorLogs, false);
    }

    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to create API Logger Records
    @Date            : 30/07/2021
   */
    public static String createAPILog(
        String apiName,
        String endPoint,
        String requestBody,
        String responseBody,
        Integer responseCode
    ) {
        API_Logger__c apiLogger = new API_Logger__c();

        populateAPIRequest(
            apiLogger,
            apiName,
            endPoint,
            requestBody
        );

        populateAPIResponse(
            apiLogger,
            responseBody,
            responseCode
        );

        // if (!System.isBatch()) {
        insert apiLogger;
        // }

        return null;
    }

    // Deepika Thakur || IBM
    public static Id createOrUpdateAPILog(
        API_Logger__c apiLogger,
        Boolean isInitial,
        String apiName,
        String endPoint,
        String requestBody,
        String responseBody,
        Integer responseCode
    ) {
        if (isInitial == true) {
            populateAPIRequest(
                apiLogger,
                apiName,
                endPoint,
                requestBody
            );

            insert apiLogger;
        } else {
            populateAPIResponse(
                apiLogger,
                responseBody,
                responseCode
            );

            update apiLogger;
        }

        return apiLogger.Id;
       // System.debug('API Logger ID: ' + apiLogger.Id);
    }

    // Deepika Thakur || IBM
    public static API_Logger__c createAPILog(
        String apiName,
        String endPoint,
        String requestBody,
        String responseBody,
        Integer responseCode,
        Boolean bulkInsertion
    ) {
        API_Logger__c apiLogger = new API_Logger__c();

        populateAPIRequest(
            apiLogger,
            apiName,
            endPoint,
            requestBody
        );

        populateAPIResponse(
            apiLogger,
            responseBody,
            responseCode
        );

        // if (!System.isBatch()) {
        // insert apiLogger;
        // }

        return apiLogger;
    }

    // Populate API request fields.
    private static void populateAPIRequest(
        API_Logger__c apiLogger,
        String apiName,
        String endPoint,
        String requestBody
    ) {
        apiLogger.API_Name__c = apiName;
        apiLogger.Endpoint__c = endPoint;
        apiLogger.Request_Body__c = requestBody;
        populateRequestHash(apiLogger, requestBody);
    }

    // Populate API response fields.
    private static void populateAPIResponse(
        API_Logger__c apiLogger,
        String responseBody,
        Integer responseCode
    ) {
        apiLogger.Response_Body__c =
            responseBody != null && responseBody.length() >= 131000
                ? 'Response too long'
                : responseBody;

        apiLogger.Response_Status_Code__c = String.valueOf(responseCode);
    }

    // Create Freshservice request hash.
    public static String createFreshserviceRequestHash(String requestBody) {
        return createSha256Hash(requestBody);
    }

    // Populate request hash.
    private static void populateRequestHash(
        API_Logger__c apiLogger,
        String requestBody
    ) {
        if (
            apiLogger == null ||
            String.isBlank(requestBody) ||
            String.isNotBlank(apiLogger.Request_Hash__c)
        ) {
            return;
        }

        Integer jsonStartIndex = requestBody.indexOf('Ticket');

        if (jsonStartIndex != -1) {
            /*
             * Existing OTRS behaviour.
             * OTRS payload contains "Ticket", so old hash method remains same.
             */
            apiLogger.Request_Hash__c =
                HttpUtility.createHashMap(
                    requestBody.substring(jsonStartIndex)
                );
        } else {
            /*
             * Freshservice / non-OTRS behaviour.
             * Do NOT use HttpUtility.createHashMap here.
             * Freshservice body has custom_fields and direct SHA-256 is safer.
             */
            apiLogger.Request_Hash__c =
                createSha256Hash(requestBody);
        }
    }

    // Create SHA-256 request hash.
    private static String createSha256Hash(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        return EncodingUtil.convertToHex(
            Crypto.generateDigest(
                'SHA-256',
                Blob.valueOf(value)
            )
        );
    }
}