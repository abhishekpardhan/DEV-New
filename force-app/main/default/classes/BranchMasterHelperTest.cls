@istest
public class BranchMasterHelperTest {
    static testmethod void validate()
    {
        Branch_Master__c br=new Branch_Master__c();
        br.Branch_ID__c = 12345;
        br.name='Test1';
        br.Branch_Type__c='ARM';
        insert br;
           
             
        account ac=new account();
        ac.name='Test';
        ac.Composite_Key__c ='SAFEX324-12345';
        ac.Vertical__c='AUTOMOTIVE';
        ac.Region__c='Delhi';
        ac.Booking_Branch__c=br.id;
        insert ac;
        update br;
           
        Branch_Master__c br1=new Branch_Master__c();
        br1.Branch_ID__c = 12346;
        br1.name='Test2';
        br1.Branch_Type__c='test';
        insert br1;
        
        account ac1=new account();
        ac1.name='Test2';
        ac1.Composite_Key__c ='SAFEX321-12346';
        ac1.Vertical__c='AUTOMOTIVE';
        ac1.Region__c='Delhi';
        ac1.Booking_Branch__c=br1.id;
        
       insert ac1;
        update br1;
        
    }}