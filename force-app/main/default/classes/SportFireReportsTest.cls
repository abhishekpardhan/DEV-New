/**
 * Description		:		Test class for SportFireReports apex class
 * 
 * Coverage			:		85%
 **/
@isTest
public class SportFireReportsTest{

    static testMethod void test1(){
        User objUs = CommonDataTest.getUserBdm();
        insert objUs;
        System.runAs(objUs){
            SpotFire_Group__c objS = new SpotFire_Group__c();
            objS.Name = 'test name';
            objS.Group__c ='Group 1'; 
            objS.Report_Link__c = 'www.test.com';
            insert objS;
            SportFireReports.getReportLinks(); 
        }
                
    }
}