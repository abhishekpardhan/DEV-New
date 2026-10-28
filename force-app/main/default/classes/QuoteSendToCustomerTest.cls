/**
 * Description		:		Test class for QuoteSendToCustomer apex class
 * Release			:		July 17, 2019
 * JIRA Ticket		:		https://safexpress.atlassian.net/browse/SD-394
 * Coverage			:		82%
 **/
@isTest 
public class QuoteSendToCustomerTest{
    static testMethod void testMethod1() {
            
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.email__c = 'Test@123gmail.com';
        insert objOpp;
               
        Quote__c objQuo = CommonDataTest.getQuote();
        objQuo.Opportunity__c = objOpp.Id; 
        insert objQuo;
                      
        ContentVersion contentVersion_1 = new ContentVersion(
        Title = 'Penguins',
        PathOnClient = 'Penguins.pdf',
        VersionData = Blob.valueOf('Test Content'),
        IsMajorVersion = true
        );
        insert contentVersion_1;
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=objQuo.id;
        contentlink.ShareType= 'V';
        contentlink.LinkedEntityId = objQuo.Id; 
        contentlink.ContentDocumentId=testcontent.ContentDocumentId;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        Contact objCon = CommonDataTest.getContact();
        objCon.Opportunity_Name__c= objOpp.id;
        insert objCon;
        
        Opportunity__c IntOpp = new Opportunity__c();
        IntOpp.Name = 'INTEGRATION OPPORTUNITY';
        IntOpp.Type__c = 'Credit';
        IntOpp.X3PL_Potential__c = 22;
        Insert IntOpp;
        
               
        Contact objCon1 = new Contact();
        objCon1.FirstName  = 'adarsh';
        objCon1.LastName = 'ranjan';
        objCon1.Email = 'araj@gmail.com';
        objCon1.MailingCity = 'raj contact';
        objCon1.MailingCountry = 'In';
        objCon1.MailingState = 'Delhi';
        objCon1.MailingStreet = 'test1 street';
        objCon1.Phone = '5478789294';
        objCon1.MailingPostalCode = '993456'; 
        objCon1.Opportunity_Name__c= IntOpp.Id;

        insert objCon1;//Monika
        List<Opportunity_Contact__c> opclist = new List<Opportunity_Contact__c>();
        Opportunity_Contact__c oppcon = new Opportunity_Contact__c();
        oppcon.Opportunity__c = objOpp.id;
        oppcon.Contact__c = objCon1.id;
        oppcon.Proposal_Send__c = true;
        insert oppcon;
        opclist.add(oppcon);
        System.assertNotEquals(oppcon.Id, null);
            
            
        List<QuoteSendToCustomer.QuoteSendToCustomerWrapper> lstCustomerWrapper = new List<QuoteSendToCustomer.QuoteSendToCustomerWrapper>();
        QuoteSendToCustomer.QuoteSendToCustomerWrapper objwrap = new QuoteSendToCustomer.QuoteSendToCustomerWrapper(objCon);
        QuoteSendToCustomer.QuoteSendToCustomerWrapper objwrap1 = new QuoteSendToCustomer.QuoteSendToCustomerWrapper(objCon1);
        lstCustomerWrapper.add(objwrap);
        lstCustomerWrapper.add(objwrap1);
        String wp = json.serialize(lstCustomerWrapper);
        System.debug('<< contentlink >> ' +contentlink);
        QuoteSendToCustomer.sendEmail(objQuo.Id ,wp);
        QuoteSendToCustomer.checkQuoteStatus(objQuo.Id);
        QuoteSendToCustomer.getContacts(objQuo.Id);        

    }
}