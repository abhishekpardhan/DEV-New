/**
* @File Name          : LoggerUtilTest.cls
* @Description        : LoggerUtilTest is the test class for LoggerUtil apex class
* @Author             : Deepak
* @Group              : Techmatrix
* @Last Modified By   : Deepak
* @Last Modified On   : 01-11-2021
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        01-11-2021                Deepak                   Initial Version
**/

@IsTest
private class LoggerUtilTest {
    static testMethod void createErrorLogTest() {
        Test.startTest();
        LoggerUtil.createErrorLog('Test','TEST','test','test','test','test');
        Test.stopTest();
    }
    static testMethod void createAPILogTest() {
        Test.startTest();
        LoggerUtil.createAPILog('Test','TEST','test','test',200);
        Test.stopTest();
    }
    static testMethod void createandUpdateAPILogTest() {
        API_Logger__c log = new API_Logger__c(
            API_Name__c = 'InitialAPI',
            Endpoint__c = 'https://endpoint.com',
            Request_Body__c = '{"Ticket":"INIT"}'
        );
        insert log;  
        API_Logger__c clonedLog = log.clone(false, true, false, false);
        Test.startTest();
        LoggerUtil.createOrUpdateAPILog(clonedLog, true, 'Test', 'TEST', 'test', 'test', 200);
        Test.stopTest();
    }
    
    static testMethod void createandUpdateAPILogTest2() {
        API_Logger__c log = new API_Logger__c(
            API_Name__c = 'InitialAPI',
            Endpoint__c = 'https://endpoint.com',
            Request_Body__c = '{"Ticket":"INIT"}'
        );
        insert log;
        Test.startTest();
        LoggerUtil.createOrUpdateAPILog(log, false, 'Test', 'TEST', 'test', 'test', 200);
        Test.stopTest();
    }
    
    static testMethod void createAPILogTest2() {
        API_Logger__c log = new API_Logger__c(
            API_Name__c = 'InitialAPII',
            Endpoint__c = 'https://endpoint.com',
            Request_Body__c = '{"Ticket":"INIT"}'
        );
        insert log;
        Test.startTest();
        LoggerUtil.createAPILog('test','test', 'Test', 'TEST',200,true);
        Test.stopTest();
    }
        static testMethod void createAPILogTest3() {
            API_Logger__c log = new API_Logger__c(
                API_Name__c = 'InitialAPII',
                Endpoint__c = 'https://endpoint.com',
                Request_Body__c = '{"Ticket":"INIT"}'
            );
            insert log;
            Test.startTest();
            LoggerUtil.createAPILog('test','test', 'Test', 'TEST',200,false);
            Test.stopTest();
        }
        static testMethod void requestHashTest(){
        API_Logger__c freshserviceLog = LoggerUtil.createAPILog(
            'Freshservice','test','{"waybill_number":"123"}',null,200,true
        );
    
        API_Logger__c otrsLog = LoggerUtil.createAPILog(
            'OTRS','test','{"Ticket":{"Title":"Test"}}',null,200,true
        );
    
        API_Logger__c blankLog = LoggerUtil.createAPILog(
            'Freshservice','test',null,null,200,true
        );
    
        String expectedHash = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256',Blob.valueOf('{"waybill_number":"123"}'))
        );
    
        System.assertEquals(expectedHash,freshserviceLog.Request_Hash__c);
        System.assertNotEquals(null,otrsLog.Request_Hash__c);
        System.assertEquals(null,blankLog.Request_Hash__c);
    }
    static testMethod void longResponseTest(){
    API_Logger__c log = LoggerUtil.createAPILog(
        'Freshservice',
        'test',
        '{"waybill_number":"123"}',
        ''.leftPad(131000,'X'),
        500,
        true
    );

    System.assertEquals('Response too long',log.Response_Body__c);
    System.assertEquals('500',log.Response_Status_Code__c);
}
}