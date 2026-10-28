@isTest
public class OpportunityStatusBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create MSA account. 
        Account msaAccount = CommonDataTest.getMSAAccount();
        String msaNumber = msaAccount.Propel_MSACode__c;
        insert msaAccount;
        System.assertNotEquals(msaAccount.Id, Null);
        
        List<Opportunity__c> listoppo = new List<Opportunity__c>();
        // Opportunities that should be set to 'Open'
        Opportunity__c objOpp1 = new Opportunity__c(Name = 'Opportunity 1', Stage__c = 'Active', 
                                                    Account__c = msaAccount.Id,
                                                    Monthly_Potential_Air__c = 34 ,
                                                    Monthly_Potential_Surface__c = 55,
                                                    X3PL_Potential__c = 60,
                                                    Customer_Type__c = 'New Opportunity',
                                                    Region__c = 'DELHI',
                                                    SFX_Code__c = '12345',
                                                    Gst_Exempted__c = true,
                                                    PAN_No__c = 'ASDGH6789K',
                                                    TAN_No__c = 'QWER12345T');
       
        
        
        // Opportunities that should be set to 'Closed'
     
        Opportunity__c objOpp6 =new Opportunity__c(Name = 'Opportunity 7', Stage__c = 'Archive', 
                                                   Account__c = msaAccount.Id,
                                                   Monthly_Potential_Air__c = 34 ,
                                                   Monthly_Potential_Surface__c = 55,
                                                   X3PL_Potential__c = 60,
                                                   Customer_Type__c = 'New Opportunity',
                                                   Region__c = 'DELHI',
                                                   SFX_Code__c = '12345',
                                                   Gst_Exempted__c = true,
                                                   PAN_No__c = 'ASDGH6789K',
                                                   TAN_No__c = 'QWER12345T');
        
       
        
        listoppo.add(objOpp1);
        listoppo.add(objOpp6);

        insert listoppo;
    }
    
    @isTest
    static void testOpportunityStatusBatch() {
        // Initialize the batch instance
        OpportunityStatusBatch batch = new OpportunityStatusBatch();
        
        // Run the batch with a single batch size for simplicity in testing
        Test.startTest();
        Database.executeBatch(batch, 100);  // Setting batch size to 2 for testing purposes
        Test.stopTest();
                
          }
    
}