global class UpdateOpportunityWithQuoteBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        if (Test.isRunningTest()) {
            // This query will run when executing in a test context
            return Database.getQueryLocator([
                SELECT Id, Name, LatestQuote__c, 
                (SELECT Id, CreatedDate, Name FROM Quotes__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Opportunity__c  
                WHERE Id IN (SELECT Opportunity__c FROM Quote__c)
            ]);
        } else {
            // This query will run in production or normal contexts
            return Database.getQueryLocator([
                SELECT Id, Name, LatestQuote__c, 
                (SELECT Id, CreatedDate, Name FROM Quotes__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Opportunity__c  
                WHERE LatestQuote__c=null  AND Id IN (SELECT Opportunity__c FROM Quote__c)
            ]);
        }
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity__c> scope) {
        List<Opportunity__c> listOppToBeUpdated = new List<Opportunity__c>();
        List<String> failedRecords = new List<String>(); // Store failed records
        for (Opportunity__c opp : scope) {
            try {
                if (!opp.Quotes__r.isEmpty()) {
                    Quote__c recentQuote = opp.Quotes__r[0];
                    opp.LatestQuote__c = recentQuote.Id;
                    listOppToBeUpdated.add(opp);
                } else {
                    failedRecords.add(opp.Id + ',No Quotes'); // Capture failed due to no quote
                }
            } catch (Exception e) {
                failedRecords.add(opp.Id + ',' + e.getMessage()); // Capture exception message
            }
        }
        if (!listOppToBeUpdated.isEmpty()) {
            try {
                update listOppToBeUpdated;
            } catch (DmlException e) {
                for (Opportunity__c opp : listOppToBeUpdated) {
                    failedRecords.add(opp.Id + ',' + e.getMessage()); // Log failed DML
                }
            }
        }
        
        if (!failedRecords.isEmpty()) {
            generateFailureFile(failedRecords);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Additional logic for finishing the batch, e.g., send email or store the file
    }

    global static void generateFailureFile(List<String> failedRecords) {
        // Create the CSV content from failed records
        String csvContent = 'OpportunityId,Error\n';
        for (String record : failedRecords) {
            csvContent += record + '\n';
        }

        // Create the file and store it, e.g., in a static resource or email attachment
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Failed_Opportunities.csv';
        cv.PathOnClient = 'Failed_Opportunities.csv';
        cv.VersionData = Blob.valueOf(csvContent);
        insert cv;
        
        // After inserting, retrieve the ContentDocument ID
        ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

        // Generate the download URL
        String downloadUrl = '/sfc/servlet.shepherd/version/download/' + contentDoc.Id;

        // Output the download URL for testing or further use
        System.debug('Download URL: ' + downloadUrl);
    }
}

/*
   public class UpdateOpportunityWithQuoteJob implements Queueable {
    //private List<Id> quoteOppIds;
    //private Map<Id, Id> quoteToOppMap;
    private Map<Id, Opportunity__c> mapOpportunity;
    public UpdateOpportunityWithQuoteJob(/*Map<Id, Id> quoteToOppMap*/ //Map<Id, Opportunity__c> mapOpportunity) {
        //this.quoteToOppMap = quoteToOppMap;
        //this.mapOpportunity = mapOpportunity;
        //this.quoteOppIds = new List<Id>(quoteToOppMap.values());
   // }

   // public void execute(QueueableContext context) {
        //TriggerUtility.byPassTrigger= true ;
        // Query Opportunities with related Quotes
       /* Map<Id, Opportunity__c> mapOpportunity = new Map<Id, Opportunity__c>([
            SELECT Id, Name, LatestQuote__c, 
                   (SELECT Id, Name FROM Quotes__r)
            FROM Opportunity__c
            WHERE Id IN :quoteOppIds
        ]);*/
        
       
        /*List<Opportunity__c> listOppToBeUpdated = new List<Opportunity__c>();
                
        for (Opportunity__c opp : mapOpportunity.values()) {
            if (!opp.Quotes__r.isEmpty()) {
                Quote__c recentQuote = opp.Quotes__r[0];
                System.debug('Opportunity: ' + opp.Name + ', Recent Quote: ' + recentQuote.Name);
                opp.LatestQuote__c = recentQuote.Id;
                listOppToBeUpdated.add(opp);
            }
        }*/

        
        // Iterate over the map and update the LatestQuote__c field
       /* for (Id quoteId : quoteToOppMap.keySet()) {
            Id oppId = quoteToOppMap.get(quoteId);
            if (mapOpportunity.containsKey(oppId)) {
                Opportunity__c opp = mapOpportunity.get(oppId);
                opp.LatestQuote__c = quoteId;
                listOppToBeUpdated.add(opp);
            }
        }*/

        // Perform DML update if there are records to update
        /*if (!listOppToBeUpdated.isEmpty()) {
            update listOppToBeUpdated;
        }
    }
}*/