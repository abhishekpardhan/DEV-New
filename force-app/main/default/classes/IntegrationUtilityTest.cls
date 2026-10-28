/**
* @File Name          : IntegrationUtilityTest.cls
* @Description        : This Test class is for IntegrationUtility.cls
* @Author             : Deepika
* @Group              : IBM
* @Last Modified By   : Deepika
* @Last Modified On   : 17-05-2024
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        17-05-2024               Deepika                   Initial Version
**/

@isTest
public class IntegrationUtilityTest {
    
    @isTest
    static void createIntegrationTransactionTest(){
        
        //prepare data
        List<String> recordIdList = new List<String>();
        List <Account> listAccount = new List<Account>();
        listAccount.add(new Account(Name = 'test1')); 
        listAccount.add(new Account(Name = 'test2')); 
        listAccount.add(new Account(Name = 'test3')); 
        
        insert listAccount; 
        for(Account acc : listAccount){
            recordIdList.add(acc.Id);
        }

        //Prepare Create customer data
        IntegrationUtility.CreateIntegrationLog objIntegrationlog = new IntegrationUtility.CreateIntegrationLog();
        objIntegrationlog.recordIdList = recordIdList;
        objIntegrationlog.operationType = 'CreateOpportunityPropeli';
        objIntegrationlog.noOfretries = 1;
        objIntegrationlog.objectName = 'Account';
        objIntegrationlog.endPointURL = 'www.google.com';        
        
        //Preparing PropelICaseCreation data
        IntegrationUtility.CreateIntegrationLog objIntegrationlog1 = new IntegrationUtility.CreateIntegrationLog();
        objIntegrationlog1.recordIdList = recordIdList;
        objIntegrationlog1.operationType = 'PropelICaseCreation';
        objIntegrationlog1.noOfretries = 1;
        objIntegrationlog1.objectName = 'Account';
        objIntegrationlog1.endPointURL = 'www.google.com'; 
        
        //Preparing iConnectUpdateCase data
        IntegrationUtility.CreateIntegrationLog objIntegrationlog2 = new IntegrationUtility.CreateIntegrationLog();
        objIntegrationlog2.recordIdList = recordIdList;
        objIntegrationlog2.operationType = 'iConnectUpdateCase';
        objIntegrationlog2.noOfretries = 1;
        objIntegrationlog2.objectName = 'Account';
        objIntegrationlog2.endPointURL = 'www.google.com'; 

        Test.startTest();
        //for Create customer type
        IntegrationUtility.createIntegrationTransaction(objIntegrationlog);
        
        //for Create PropelICaseCreation type
        IntegrationUtility.createIntegrationTransaction(objIntegrationlog1);

        //for Create iConnectUpdateCase type
 		IntegrationUtility.createIntegrationTransaction(objIntegrationlog2);
        Test.stopTest();
        
        //Verify if the records are inserted
        Integer actualRecordsCount = [SELECT COUNT() FROM Integration_Transaction__c WHERE Object_Name__c = :'Account'];
        Assert.areEqual(recordIdList.size()*3, actualRecordsCount);
        
    }
    
    @isTest
    static void updateSuccessIntegrationTransactionTest(){
        //prepare data
        Account acc = new Account(Name = 'test1'); 
        
        Integration_Transaction__c reqDetail = new Integration_Transaction__c();
        reqDetail.Object_Name__c = 'Account';
        reqDetail.record_id__c = acc.Id; 
        reqDetail.Operation_Type__c = 'Create customer' ;
        reqDetail.No_of_Retries__c = 1;
        reqDetail.MSAPushEndpoint__c = 'www.google.com';
        insert reqDetail;
        
        IntegrationUtility.IntegrationLog objIntegration = new IntegrationUtility.IntegrationLog();
        objIntegration.recordId = String.valueOf(reqDetail.Id);
        objIntegration.eventName = '2222';
        objIntegration.response = 'Test Response';
        objIntegration.request = 'Test Request';
        objIntegration.errorMessage = null;
        objIntegration.statusCode = 200;
        
        //start Test
        Test.startTest();
        IntegrationUtility.updateIntegrationTransaction(objIntegration);
        Test.stopTest();
        
        //Verify if the records are updated on Integration_Transaction__c
        Integration_Transaction__c integrationObj = [SELECT Id,Status__c,Response__c,Request__c,Error_Message__c FROM Integration_Transaction__c WHERE id = :String.valueOf(reqDetail.Id)];
        Assert.areEqual(String.valueOf(reqDetail.Id), integrationObj.Id); 
        Assert.areEqual('Success', integrationObj.Status__c); 
        Assert.areEqual('Test Response', integrationObj.Response__c); 
        Assert.areEqual('Test Request', integrationObj.Request__c); 
    }
    
    @isTest
    static void updateFailIntegrationTransactionTest(){
        //prepare data
        Account acc = new Account(Name = 'test1'); 
        
        Integration_Transaction__c reqDetail = new Integration_Transaction__c();
        reqDetail.Object_Name__c = 'Account';
        reqDetail.record_id__c = acc.Id; 
        reqDetail.Operation_Type__c = 'Create customer' ;
        reqDetail.No_of_Retries__c = 1;
        reqDetail.MSAPushEndpoint__c = 'www.google.com';
        insert reqDetail;
        
        IntegrationUtility.IntegrationLog objIntegration = new IntegrationUtility.IntegrationLog();
        objIntegration.recordId = String.valueOf(reqDetail.Id);
        objIntegration.errorMessage = 'Error';
        objIntegration.statusCode = 400;
        
        //start Test
        Test.startTest();
        IntegrationUtility.updateIntegrationTransaction(objIntegration);
        Test.stopTest();
        
        //Verify if the records are updated on Integration_Transaction__c
        Integration_Transaction__c integrationObj = [SELECT Id,Status__c,Response__c,Request__c,Error_Message__c FROM Integration_Transaction__c WHERE id = :String.valueOf(reqDetail.Id)];
        Assert.areEqual(String.valueOf(reqDetail.Id), integrationObj.Id); 
        Assert.areEqual('Fail', integrationObj.Status__c); 
        Assert.areEqual('Error', integrationObj.Error_Message__c); 
    }
    
}