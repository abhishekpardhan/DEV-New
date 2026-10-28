Id leadId = '00QC100000KJ1jJMAT';
Database.SaveResult result = Database.update(new Lead(Id = leadId, PostalCode = '990102'), false);
System.debug(LoggingLevel.ERROR, 'T14_UPDATE_SUCCESS=' + result.isSuccess());
