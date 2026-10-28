@isTest
public class MergeContactQueueableTest {

    @testSetup
    public static void createData(){
        List<Contact> conList = new List<Contact>();
        Contact objCon1 = CommonDataTest.getContact();
        objCon1.mobilePhone = '0987654321';
        conList.add(objCon1);
        
        Contact objCon2 = CommonDataTest.getContact();
        objCon2.mobilePhone = '0987654321';
        conList.add(objCon2);
        
       	insert conList ;
    }
    
    @isTest
    public static void testContactmerge(){
        
        List<Contact> conList = [SELECT Id FROM Contact WHERE mobilePhone = '0987654321'];
        System.assertEquals(2, conList.size());
        
        List<String> mobilePhoneList = new List<String>{'0987654321'};
        List<String> emailList = new List<String>{'test@gmail.com'};
        MergeContactQueueable obj = new MergeContactQueueable(mobilePhoneList, emailList, false, null, null);
        Test.startTest();
        	System.enqueueJob(obj);
        Test.stopTest();
        // Asserts
        conList = [SELECT Id FROM Contact WHERE mobilePhone = '0987654321'];        
        System.assertEquals(1, conList.size());
    }
    
}