public class UpdateOpportunityWithQuoteJob implements Queueable {
    private List<Id> quoteOppIds;
    private Map<Id, Id> quoteToOppMap;

    public UpdateOpportunityWithQuoteJob(Map<Id, Id> quoteToOppMap) {
        this.quoteToOppMap = quoteToOppMap;
        this.quoteOppIds = new List<Id>(quoteToOppMap.values());
    }

    public void execute(QueueableContext context) {
        TriggerUtility.byPassTrigger= true ;
        // Query Opportunities with related Quotes
        Map<Id, Opportunity__c> mapOpportunity = new Map<Id, Opportunity__c>([
            SELECT Id, Name, LatestQuote__c, 
                   (SELECT Id, Name FROM Quotes__r)
            FROM Opportunity__c
            WHERE Id IN :quoteOppIds
        ]);
        
        List<Opportunity__c> listOppToBeUpdated = new List<Opportunity__c>();
        
        // Iterate over the map and update the LatestQuote__c field
        for (Id quoteId : quoteToOppMap.keySet()) {
            Id oppId = quoteToOppMap.get(quoteId);
            if (mapOpportunity.containsKey(oppId)) {
                Opportunity__c opp = mapOpportunity.get(oppId);
                opp.LatestQuote__c = quoteId;
                listOppToBeUpdated.add(opp);
            }
        }

        // Perform DML update if there are records to update
        if (!listOppToBeUpdated.isEmpty()) {
            update listOppToBeUpdated;
        }
    }
}