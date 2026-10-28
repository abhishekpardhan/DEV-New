public class AgentforceAgentDelayCaseResult {

    @InvocableVariable(label = 'Success')
    public Boolean success;

    @InvocableVariable(label = 'Case Number')
    public String caseNumber;

    @InvocableVariable(label = 'Case Id')
    public String caseId;

    @InvocableVariable(
        label       = 'Is Duplicate'
        description = 'True if an open Delay Case already exists for this waybill. Agent must inform customer of existing case number instead of creating a new one.'
    )
    public Boolean isDuplicate;

    @InvocableVariable(
        label       = 'Duplicate Message'
        description = 'Pre-built message for the agent to read out when a duplicate case is found.'
    )
    public String duplicateMessage;

    @InvocableVariable(
        label       = 'Case Priority Set'
        description = 'The priority that was set on the Case — High or Medium. Agent can use this to communicate urgency to the customer.'
    )
    public String casePrioritySet;

    @InvocableVariable(label = 'Contact Id')
    public String contactId;

    @InvocableVariable(label = 'Error Message')
    public String errorMessage;
}