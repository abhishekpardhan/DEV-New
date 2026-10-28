/**
 * Description		:		Test class for CustomLoginController apex class
 **/
@isTest 
public class CustomLoginControllerTest{
    static testMethod void testMethod1() {  
    
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockClass());
        CustomLoginController objcustom = new CustomLoginController();
        objcustom.doLogin(); 
        
        
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockClass1());
        objcustom.doLogin(); 
     } 
}