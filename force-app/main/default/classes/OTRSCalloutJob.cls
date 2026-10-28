public class OTRSCalloutJob implements Queueable, Database.AllowsCallouts {

    private final String apiName;
    //private final HttpRequest req;
    private final String endpoint;
    private final Blob requestBodyBlob;
    private final String contentLength;
    private final String contentType;
    private final Id loggerId;
    private final String caseId;

    public OTRSCalloutJob(Id loggerId ,String apiName, String endpoint , Blob requestBodyBlob, String contentLength, String contentType, String caseId) {
        this.apiName = apiName;
        this.endpoint = endpoint;
        this.requestBodyBlob = requestBodyBlob;
        this.contentType = contentType;
        this.contentLength = contentLength;
        this.loggerId = loggerId;
        this.caseId = caseId;
       // this.req = req;
    }

    public void execute(QueueableContext context) {
          // ReturnInfo returnInfo = new ReturnInfo();
        try {
            // Step 1: Create Request
            HttpRequest httpRequest = HttpUtility.getHttpRequest(endpoint, ConstantUtility.POST, 'Accept', ConstantUtility.APPLICATION_JSON, null, ConstantUtility.APPLICATION_JSON, requestBodyBlob);
            httpRequest.setHeader('Content-Length', contentLength);
            httpRequest.setHeader('Content-Type', contentType);   
            
            // Step 2: Re-query existing logger
            List<API_Logger__c> loggers = [SELECT Id,Request_Hash__c FROM API_Logger__c WHERE Id =:loggerId And CreatedDate = TODAY];
              
            // Step 3: Make Callout
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);
            System.debug('httpResponse-->'+httpResponse);
            // Step 4: Log Response (Update)
            if (!loggers.isEmpty() && loggers[0].Request_Hash__c != null) {
                LoggerUtil.createOrUpdateAPILog(loggers[0], false, null, null, null, httpResponse.getBody(), httpResponse.getStatusCode());
            }
            
            // Step 5: Publish Platform Event with ticket number (NEW)
            String ticketNumber = ''; // Extract ticket number from httpResponse if available
            try {
                Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
                if (parsedResponse.containsKey('response')) {
                    List<Object> responseList = (List<Object>) parsedResponse.get('response');
                    if (!responseList.isEmpty()) {
                        Map<String, Object> ticketData = (Map<String, Object>) responseList[0];
                        ticketNumber = String.valueOf(ticketData.get('TicketNumber'));
                    }
                }
            } catch (Exception e) {
                LoggerUtil.createErrorLog(
                'OTRSCalloutJob', 'execute', e.getTypeName(),
                e.getMessage(), e.getStackTraceString(), null
            );
            }
            //update case ticketnumber
            System.debug('ticketNumber-->'+ticketNumber);
            Case caseToUpdate = [Select Id,OTRS_Ticket_No__c from Case Where Id =:caseId];
            caseToUpdate.OTRS_Ticket_No__c = ticketNumber;
            update caseToUpdate;
            System.debug('caseToUpdate--->'+caseToUpdate);
            
          /*  OTRS_Response__e event = new OTRS_Response__e(
                RecordId__c = caseId, // Or original caseId if available in job context
                Status__c = 'Completed',
                TicketNumber__c = ticketNumber
            );
            EventBus.publish(event);*/

            
            
        } catch (Exception e) {
            LoggerUtil.createErrorLog(
                'OTRSCalloutJob', 'execute', e.getTypeName(),
                e.getMessage(), e.getStackTraceString(), null
            );
        }
    }
}