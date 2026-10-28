/**
 * Description      :   Test class of BusinessDetailTrigger and BusinessDetailTriggerHelper
 * Release          :   21th Oct, 2024
 * JIRA Ticket		:	SAC-964	
 * Coverage			:
 * Revision Logs    :   V_1.0 - Created By - KR SANSI(IBM)
 * 
 **/
@isTest
public class BusinessDetailTriggerTest {

    @isTest
    public static void validateGSTWithStateTest(){
        Account acc = CommonDataTest.getMSAAccount();
        insert acc;
        Opportunity__c opp = CommonDataTest.getCustomOpportunity(acc.Id);
        opp.Stage__c ='Active';
        opp.GST_Number__c ='07ASDGH6789K1ZZ';
        opp.TAN_No__c = 'PDES03028F';
        opp.Gst_Exempted__c=true;
        opp.Pan_No__c = 'ASDGH6789K';
        opp.Monthly_Potential_Air__c =123;
        insert opp;

        Business_Detail__c bd = new Business_Detail__c(GST_No__c='07ASDGH6789K1ZZ', Billing_State__c='Delhi',Account__c = acc.Id,Opportunity__c = opp.ID, Potential_Business__c ='100000');
        insert bd;
        try{
        bd.Opportunity__c = null;
        update bd;
        }
        catch(Exception e){

           }
        
    }
    
}