/**
 * Description      :   Test class for API to get sales data from propel-i to salesforce regularly
 * Release          :   17th may, 2021
 * Created by       :   Shubham Girdhar
 * Revision Logs    :   V_1.0 - Created
 **/
@isTest
private class SalesDataGetAPITest {
     static testMethod void testgetMethod()
    {
        Test.setMock(HttpCalloutMock.class, new mockResponceSalesDataAPI());
        Test.startTest();
        SalesDataGetAPI.GetSalesData();
        Test.stopTest();

}

}