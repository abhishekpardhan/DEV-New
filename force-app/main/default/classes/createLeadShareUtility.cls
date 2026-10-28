public class createLeadShareUtility {
	
    public static List<Lead__Share> createLeadShare(List<Id> areaUserIds, Id LeadId){
             List<Lead__Share> ledShareList = new List<Lead__Share>();
            for(Id usrId : areaUserIds){
                Lead__Share ledShare = new Lead__Share(ParentId=leadId,UserOrGroupId=usrId,AccessLevel='Read');
                ledShareList.add(ledShare);
            }
        	system.debug('ledShareList--->'+ledShareList);
            return ledShareList;
        }
    }