trigger AgentWorkTrigger on AgentWork (after insert, after update) {
    // Set the Presence Status to 'Busy' for users associated with Messaging Sessions
    Set<Id> userIdsToUpdate = new Set<Id>();
    Set<Id> userIdsToUpdate1 = new Set<Id>();
    Set<Id> mSId = new Set<Id>();
    integer i =0;
    integer i1 =0;
    integer i2 =0;
    integer i3 =0;
    integer i4 =0;
    integer i5 =0;
    integer i6 =0;
    integer i7 =0;
    integer i8 =0;
    integer i9 =0;
    integer i11 =0;
    integer i12 =0;
    integer i13 =0;
    integer i14 =0;
    integer i15 =0;
    integer i16 =0;
    integer i17 =0;
    integer i18 =0;
    integer i19 =0;
    integer i28 =0;
    integer i38 =0;
    integer i48 =0;
    integer i58 =0;
    integer i68 =0;
    integer i71 =0;
    integer i72 =0;
    integer i73 =0;
    integer i74 =0;
    integer i75 =0;
    integer i76 =0;
    integer i77 =0;
    integer i78 =0;
    integer i79 =0;
    integer i80 =0;
    integer i81 =0;
    integer i82 =0;
    integer i83 =0;
    integer i84 =0;
    integer i85 =0;
    integer i86 =0;
    integer i87 =0;
    integer i88 =0;
    integer i89 =0;
    
    
    
    
    // Loop through MessagingSession records to get associated users
    if(trigger.isAfter && trigger.isupdate){
        for (AgentWork work : Trigger.new) {
            if(work.status != trigger.oldMap.get(work.Id).status && (work.status == 'Opened' || work.status == 'Closed')) {
                if (work.USERID	 != null) {
                    userIdsToUpdate.add(work.USERID);
                } 
                if(work.WorkItemId != null){
                    mSId.add(work.WorkItemId);
                }
            }
        }
        
        if (!userIdsToUpdate.isEmpty()) {
            List<UserServicePresence> usp= [SELECT Id,AtCapacityDuration,ConfiguredCapacity,ConfiguredInterruptCapacity,AverageCapacity FROM UserServicePresence WHERE IsCurrentState = true AND UserId IN:userIdsToUpdate];
            //System.debug('Total Capacity ->' + usp.AtCapacityDuration);
            //System.debug('Total Capacity ->' + usp.AverageCapacity);
            if(usp.size()>0) {
                Integer avgCapcity = Integer.valueOf(usp[0].ConfiguredCapacity);
                List<MessagingSession> mSlst = [select id,AgentCapacity__c, CreatedDate from MessagingSession where Id=:mSId];
                Integer count = [SELECT Count()
                                 FROM AgentWork
                                 WHERE status = 'Opened' AND USERID IN:userIdsToUpdate]; 
                System.debug('Consumed Capacity ->'+ count);
                if(avgCapcity == count) {
                    
                    usp[0].ServicePresenceStatusId = '0N5C5000000001FKAQ'; // Set the status to 'Busy'
                    //messagingsessionfield mark as busy
                    mSlst[0].AgentCapacity__c = 'Busy';
                    //presence.ServicePresenceStatusId = '0N5C5000000001KKAQ';    
                }
                else {
                    usp[0].ServicePresenceStatusId = '0N5C5000000001KKAQ';
                }
                update usp[0];
                update mSlst[0];
            }
        }
        
    }
    
}