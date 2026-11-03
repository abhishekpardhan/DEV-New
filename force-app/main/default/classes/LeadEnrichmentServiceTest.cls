@IsTest
private class LeadEnrichmentServiceTest {
    
    @IsTest
    static void uppercasesNamesForNewLeadsInBulk() {
        List<Lead> leads = new List<Lead>();
        
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(
                FirstName = 'first' + i,
                LastName = 'last' + i,
                Company = 'Test Company ' + i,
                MobilePhone = '98765432' + String.valueOf(10 + i),
                Email = 'testlead' + i + '@example.com',
                Street = 'Test Street ' + i,
                City = 'Gurugram',
                State = 'Haryana',
                PostalCode = '12200' + i,
                 Vertical__c= 'ALLIANCE PARTNER MANAGEMENT',Sub_Vertical__c='COURIER',Account_Type__c= 'Emerging',
                    Area__c = 'NOIDA', Region__c = 'UTTAR PRADESH'
                
            ));
        }
        
        insert leads;
        LeadEnrichmentService.toUpperCase(leads, null);
        
        for (Integer i = 0; i < leads.size(); i++) {
            System.assertEquals('FIRST' + i, leads[i].FirstName, 'First name at index ' + i);
            System.assertEquals('LAST' + i, leads[i].LastName, 'Last name at index ' + i);
        }
    }
    
    @IsTest
    static void preservesNullAndBlankNames() {
        Lead nullNames = new Lead(FirstName = null, LastName = null);
        Lead blankNames = new Lead(FirstName = '   ', LastName = '   ');
        
        LeadEnrichmentService.toUpperCase(new List<Lead>{nullNames, blankNames}, null);
        
        System.assertEquals(null, nullNames.FirstName);
        System.assertEquals(null, nullNames.LastName);
        System.assertEquals('   ', blankNames.FirstName);
        System.assertEquals('   ', blankNames.LastName);
    }
    
    @IsTest
    static void uppercasesOnlyChangedNamesOnUpdate() {
        String leadPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();
        Id firstId = Id.valueOf(leadPrefix + '000000000001');
        Id secondId = Id.valueOf(leadPrefix + '000000000002');
        Id thirdId = Id.valueOf(leadPrefix + '000000000003');
        
        Lead first = new Lead(Id = firstId, FirstName = 'newFirst', LastName = 'unchangedLast');
        Lead second = new Lead(Id = secondId, FirstName = 'unchangedFirst', LastName = 'newLast');
        Lead third = new Lead(Id = thirdId, FirstName = 'sameFirst', LastName = 'sameLast');
        Map<Id, Lead> oldMap = new Map<Id, Lead>{
            firstId => new Lead(Id = firstId, FirstName = 'oldFirst', LastName = 'unchangedLast'),
                secondId => new Lead(Id = secondId, FirstName = 'unchangedFirst', LastName = 'oldLast'),
                thirdId => new Lead(Id = thirdId, FirstName = 'sameFirst', LastName = 'sameLast')
                };
                    
                    LeadEnrichmentService.toUpperCase(new List<Lead>{first, second, third}, oldMap);
        
        System.assertEquals('NEWFIRST', first.FirstName);
        System.assertEquals('unchangedLast', first.LastName);
        System.assertEquals('unchangedFirst', second.FirstName);
        System.assertEquals('NEWLAST', second.LastName);
        System.assertEquals('sameFirst', third.FirstName);
        System.assertEquals('sameLast', third.LastName);
    }
}