@isTest
public class AssignBranchPopulateTest {
	
@isTest
    public static void testBatch(){
        

        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
		
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Branch_Master__c bm = new Branch_Master__c();
        bm.Name = 'Test Branch1';
        insert bm;
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Billing_Branch__c = bm.Id;
        insert objSfx;
        
        PropelI_BDM_Mapping__c mapping = new PropelI_BDM_Mapping__c();
        mapping.Account__c = objSfx.Id;
        mapping.PropelI_BDM__c = us.Id; 
        mapping.CCD__c = true;
        mapping.Collection__c = true;
        mapping.PropelI_Composite_Key__c = us.Id+'::'+objSfx.Id;
        insert mapping;        
               
                       
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Relationship__c = true;
        accteam.PropelI_BDM_Mapping__c = mapping.Id;
        accteam.Account__c = objSfx.Id;
        accteam.Submission__c = true;
        accteam.Collection__c = true;
        accteam.BDMPropelI__c=us.Id;
        accteam.PropelI_Composite_Key__c = objSfx.Id;
        
        insert accteam;
         
        
        Test.startTest();
        Database.executeBatch( new AssignBranchPopulate());
        Test.stopTest();
        
    }    
    
    @isTest
    public static void testBatchWithId(){
        Set<String> acIdSet = new Set<String>();
        for(Integer i=0;i<10;i++){
            Account_Team__c acc_team = new Account_Team__c();
            acIdSet.add(acc_team.Id);
        }
        Test.startTest();
        Database.executeBatch( new AssignBranchPopulate(acIdSet));
        Test.stopTest();
    }
    
}