Id t18LeadId = '00QC100000KJRsDMAX';
Id territoryManagerId = '005C5000000JwHQIA0';
Database.SaveResult t18 = Database.update(new Lead(Id = t18LeadId,
    OwnerId = territoryManagerId), false);
System.debug(LoggingLevel.ERROR, 'T18_UPDATE_SUCCESS=' + t18.isSuccess());

String casePrefix = Case__c.SObjectType.getDescribe().getKeyPrefix();
Lead caseLead = new Lead(LastName = 'T20-IN-MEMORY', Company = 'Stream A Scenario Test',
    Status = 'Active', PostalCode = '990101', Assign_to_Central_Desk__c = false,
    Assignment_Evaluated__c = false, Case__c = Id.valueOf(casePrefix + '000000000001'));
LeadAssignmentService.onBeforeInsert(new List<Lead>{caseLead});
System.debug(LoggingLevel.ERROR, 'T20_CASE_AUTO_CHECKBOX=' + caseLead.Assign_to_Central_Desk__c);
System.debug(LoggingLevel.ERROR, 'T20_CASE_STATUS=' + caseLead.Pincode_Lookup_Status__c);
System.debug(LoggingLevel.ERROR, 'T20_CASE_EVALUATED=' + caseLead.Assignment_Evaluated__c);
System.debug(LoggingLevel.ERROR, 'T20_CASE_OWNER=' + caseLead.OwnerId);
