@isTest
public class UpdateContactEmailBatchTest {

    @isTest
    public static void testBatch(){
        List<Contact> conList = new List<Contact>();
        Contact objCon1 = CommonDataTest.getContact();
        objCon1.mobilePhone = '0987654321';
        conList.add(objCon1);
        
        Contact objCon2 = CommonDataTest.getContact();
        objCon2.mobilePhone = '0987654321';
        conList.add(objCon2);
        
        User us = CommonDataTest.getUserServiceCloudExecutive();
        insert us;
        System.runAs(us){
            insert conList ;
        }
        
        
        Test.startTest();
        	Database.executeBatch(new UpdateContactEmailBatch(), 100);
        Test.stopTest();
        
    }
}