// SAC-1390| Deepika (IBM ) | Create pofiling task by selecting multiple AT from list view.
public class CreateProfilingTask {
    
    public class FlowResponse {
        @InvocableVariable(label='Inserted Count')
        public Integer insertedCount;

        @InvocableVariable(label='Updated Count')
        public Integer updatedCount;

        @InvocableVariable(label='No Change Count')
        public Integer noChangeCount;
    }

    
    @InvocableMethod(callout=true label='Create Profiling Task')
    public static List<FlowResponse> customerProfilingTaskFromATList(List<List<Account_Team__c>> accTeam){
        System.debug('accTeam***'+accTeam.get(0));
        List<FlowResponse> responses = new List<FlowResponse>();

        Map<String, Integer> result = trg_AccountTeamHelper.onboardingTask(accTeam.get(0), true, 2);
        FlowResponse response = new FlowResponse();
        response.insertedCount = result.get('inserted');
        response.updatedCount = result.get('updated');
        response.noChangeCount = result.get('noChange');
        responses.add(response);
        return responses;
        
    }
}