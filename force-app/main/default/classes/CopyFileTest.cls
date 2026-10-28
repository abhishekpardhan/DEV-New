/**
 * Description		:		Test class for CopyFile apex class Used to copy file from one record to another
 * Created By       :       Shubham Girdhar
 * Created Date     :       12th Nov, 2019
 * Release          :       15th Nov, 2019
 * Last Modified on :       06/01/2020
 * Last Modified by :     Shubham Girdhar
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-505
 * Coverage			:		100%
 **/
@isTest
public class CopyFileTest {
    static testMethod void testMethod1() {
        Contact con = CommonDataTest.getContact();
        insert con;
        
        Lead__c ld = CommonDataTest.getLead();
        insert ld;
        
        ContentVersion contentVersion_1 = CommonDataTest.getContectVersion();
        insert contentVersion_1;
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :contentVersion_1.Id];
        
        ContentDocumentLink contentlink=CommonDataTest.getContentDocumentLink();
        
        contentlink.LinkedEntityId = con.Id; 
        contentlink.ContentDocumentId=testcontent.ContentDocumentId;
        insert contentlink;
        
        test.startTest();
        CopyFile.CopyFileFromRecord1to2(con.Id, ld.Id);
        test.stopTest();
    }
}