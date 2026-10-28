Id leadId = '00QC100000KJ1jJMAT';
Database.SaveResult result = Database.update(new Lead(Id = leadId,
    Assign_to_Central_Desk__c = true), false);
System.debug(LoggingLevel.ERROR, 'T15_UPDATE_SUCCESS=' + result.isSuccess());
