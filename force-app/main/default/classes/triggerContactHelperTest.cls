/**
 * Description		:		Test class for Contact Trigger apex class
 * JIRA ticket      :		https://safexpress.atlassian.net/browse/SD-453
 * Last Modified By :       Shubham Girdhar
 * Last Modified Date:      06/01/2020
 * Coverage			:		81%
 **/
@isTest 
public class triggerContactHelperTest {
    
    public static void testdata() {
        
        Opportunity__c objOpp = new Opportunity__c();
        objOpp.Name = 'TEST OPP';
        objOpp.Type__c = 'Retail';
        objOpp.Opportunity_Status__c = null;
        objOpp.X3PL_Potential__c = 23;
        objOpp.GST_Number__c = '07AABCB2115P1ZR';
        insert objOpp;
        
        Branch_Master__c BMrec1 = CommonDataTest.getBranchMaster();
        BMrec1.Name = 'PANJIM-12';
        BMrec1.Branch_Code__c = 'PJI12';
        insert BMrec1;
        
        Account objPro = CommonDataTest.getParentAccount();
        objPro.Billing_Branch__c = BMrec1.Id;
        objPro.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        insert objPro;
        
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.SFX_Code__c = 'SFX123';
        objSfx.parentID = objPro.Id;
        objPro.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        objSfx.Opportunity__c = objOpp.Id;
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(60);
        insert objSfx;
        
        Contact objCon = new Contact();
        objCon.FirstName  = 'TEST';
        objCon.Contact_State__c = 'Delhi'; //MON
        objCon.LastName = 'pwc';
        objCon.Email = 'test@gmail.com';
        objCon.MailingCity = 'Test contact';
        objCon.MailingCountry = 'In';
        objCon.MailingState = 'Delhi';
        objCon.MailingStreet = 'test street';
        objCon.Phone = '5456789234';
        objCon.MailingPostalCode = '123456';
        objCon.Address_Type__c = 'Corporate Office';
        objCon.Responsible_for__c ='Collection';
        objCon.AccountId = objPro.Id;
        insert objCon;
        
        User us =  CommonDataTest.getUserBdm();
        insert us;
        
        Account_Team__c accteam = new Account_Team__c();
        accteam.National1__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.BDMPropelI__c = us.id;
        accteam.Relationship__c  = true;
        accteam.Collection__c = true;
        accteam.National2__c = false;
        accteam.National3__c = true;
        accteam.Submission__c = true;   
        accteam.PropelI_Composite_Key__c = objSfx.Id+'&&'+objSfx.Id;
        insert accteam;
        
        
    }
    
    static testMethod void validateHelloWorld() {
       Contact objCon = CommonDataTest.getContact();
       objCon.LeadSource = 'Directory';
       objCon.Contact_State__c = 'Delhi';
       insert objCon ;
        List<Contact> newContactList = new List<Contact>();
        newContactList.add(objCon);
        Map<Id, Contact> mapTest = new Map<Id, Contact>();
        mapTest.put(objCon.id,objCon);
        triggerContactHelper.removeAccountContactRelation(newContactList,mapTest);
        objCon.Is_Active__c = false;
        update objCon;
    }
    
    /*static testMethod void validateHelloWorld1() {
        testdata();
        List<Contact> newContactList = [Select Id,AccountId,OwnerId from Contact where FirstName = 'TEST' ];
        Test.startTest();
        triggerContactHelper.checkContactOwner(newContactList);
        Test.stopTest();
    }*/
   
}