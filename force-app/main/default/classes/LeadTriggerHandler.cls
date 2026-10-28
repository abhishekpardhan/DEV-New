public class LeadTriggerHandler extends TriggerHandler {
    private List<Lead> newLeads;
    private Map<Id, Lead> oldLeadsMap;
    public static Boolean flag = true;
    public LeadTriggerHandler() {
        this.newLeads = (List<Lead>) Trigger.new;
        this.oldLeadsMap = (Map<Id, Lead>) Trigger.oldMap;
    }

    protected override void beforeInsert() {
        LeadEnrichmentService.toUpperCase(newLeads, null);
        // LeadGstService.derivePan(newLeads, null);
        LeadAssignmentService.onBeforeInsert(newLeads);
        LeadDuplicateService.checkPan(newLeads, null);
    }

    protected override void afterInsert() {
        LeadEnrichmentService.toUpperCase(newLeads, null);
        LeadAssignmentService.onAfterInsert(newLeads);
        // LeadGstService.enqueueVerification(newLeads, null);
    }

    protected override void beforeUpdate() {
        LeadEnrichmentService.toUpperCase(newLeads,oldLeadsMap);
        // LeadGstService.derivePan(newLeads,oldLeadsMap);
        LeadAssignmentService.onBeforeUpdate(newLeads, oldLeadsMap);
        // LeadGstService.checkStateVsRegion(
        //     newLeads,oldLeadsMap
        // );
        LeadDuplicateService.checkPan(newLeads,oldLeadsMap);
    }

    protected override void afterUpdate() {
        // LeadGstService.enqueueVerification(newLeads,oldLeadsMap);
         LeadDropApprovalService.submitDropApprovals(newLeads,oldLeadsMap);
    }
}