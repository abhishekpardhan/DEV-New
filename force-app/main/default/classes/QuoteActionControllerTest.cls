/**
 * Description		:		Test class for QuoteActionController apex class
 * 
 * Coverage			:		88%
 **/
@isTest 
public class QuoteActionControllerTest{
    static testMethod void testMethod1() {
            
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Quote__c objQuo = CommonDataTest.getQuote();
        objQuo.Opportunity__c = objOpp.Id; 
        insert objQuo;
        
        Test.StartTest();
        	QuoteActionController.closequote(objQuo.Id , Date.today());
        	QuoteActionController.getDefferedReason();
        Test.StopTest();
    } 
    
    static testMethod void testMethod2() {
            
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        insert objOpp;
        
        Quote__c objQuo = CommonDataTest.getQuote();
        objQuo.Opportunity__c = objOpp.Id; 
        insert objQuo;
        Test.StartTest();
          	QuoteActionController.createnewquotee(objQuo.Id ,'Product Not acceptable','TEST QUOTE','TEST SUBREASON');
        Test.StopTest();
    }
}