Id t16Id = '00QC100000KJRsDMAX';
Id t17Id = '00QC100000KJRsEMAX';

Database.SaveResult t16 = Database.update(new Lead(Id = t16Id,
    Assign_to_Central_Desk__c = true), false);
System.debug(LoggingLevel.ERROR, 'T16_UPDATE_SUCCESS=' + t16.isSuccess());

Boolean t17Blocked = false;
String t17Message;
try {
    update new Lead(Id = t17Id, Assign_to_Central_Desk__c = false);
} catch (DmlException ex) {
    t17Blocked = true;
    t17Message = ex.getDmlMessage(0);
}
System.debug(LoggingLevel.ERROR, 'T17_BLOCKED=' + t17Blocked);
System.debug(LoggingLevel.ERROR, 'T17_MESSAGE=' + t17Message);
