public class SendCaseNotificationQueueable implements Queueable {
    
    public Map<String, String> caseIdToManager;
    public String dynamicNotificationTypeId;
    public SendCaseNotificationQueueable(Map<String, String> caseIdToManager, String dynamicNotificationTypeId){
        
        this.caseIdToManager = caseIdToManager;
        this.dynamicNotificationTypeId = dynamicNotificationTypeId;
    }
    public void execute(QueueableContext qc){
        String caseId;
        String managerId;
        for(String casId : this.caseIdToManager.keySet()){
            caseId = casId;
			managerId = this.caseIdToManager.get(casId);   
            break;
        }
        
        Set<String> recipientSet = new Set<String>{managerId};
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Case Approved by AM');
        notification.setBody('A case has been approved by the Account Manager.');
        notification.setNotificationTypeId(this.dynamicNotificationTypeId);
        notification.setSenderId(UserInfo.getUserId());
        notification.setTargetId(caseId); 
        notification.send(recipientSet);
        
        String removeId = this.caseIdToManager.remove(caseId);
        if(this.caseIdToManager.size() > 0){
            SendCaseNotificationQueueable obj = new SendCaseNotificationQueueable(this.caseIdToManager, this.dynamicNotificationTypeId);
            System.enqueueJob(obj);
        }
        
    }
    
}