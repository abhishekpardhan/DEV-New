/**
* @File Name          : FussionSupplierDataAPITest.apxc
* @Description        : FussionSupplierDataAPITest is the test class for FussionSupplierDataAPI apex class
* @Author             : Shubham
* @Group              : Safexpress
* @Last Modified By   : Shubham
* @Last Modified On   : 05-01-2022
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        05-01-2022                Shubham                  Initial Version
**/
@IsTest
private class FussionSupplierDataAPITest {
    
    
    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('Authorization', '00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW');
            res.setHeader('x-api-key', 'NsgDiyaube5kURRzN5Ial85xr6NvkNbV59yXpC7v');
            //  htpReq.setHeader('Content-Type', contentType);
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"suppInfoList":[{"supplierId":300000014819217,"supplierName":"GOVIND SINGH-15773","supplierSite":"DLI10","supplierNumber":"55373","employeeCode":"15773","status":"A"},{"supplierId":300000014771249,"supplierName":"PANKAJ NAYAK-14467","supplierSite":"DLI10","supplierNumber":"55319","employeeCode":"14467","status":"A"},{"supplierId":300000014771208,"supplierName":"RAJ KUMAR SINGH-04253","supplierSite":"DLI10","supplierNumber":"55318","employeeCode":"04253","status":"A"}],"message":"SUCCESS","status":"SUCCESS","totalCount":7906}');
            return res;
        }
    }
    private class Mock1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
        //    System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('Authorization', '00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW');
            res.setHeader('x-api-key', 'NsgDiyaube5kURRzN5Ial85xr6NvkNbV59yXpC7v');
            //  htpReq.setHeader('Content-Type', contentType);
            res.setStatus('OK');
            res.setStatusCode(401);
            res.setBody('{"suppInfoList":[{"supplierId":300000014819217,"supplierName":"GOVIND SINGH-15773","supplierSite":"DLI10","supplierNumber":"55373","employeeCode":"15773","status":"A"},{"supplierId":300000014771249,"supplierName":"PANKAJ NAYAK-14467","supplierSite":"DLI10","supplierNumber":"55319","employeeCode":"14467","status":"A"},{"supplierId":300000014771208,"supplierName":"RAJ KUMAR SINGH-04253","supplierSite":"DLI10","supplierNumber":"55318","employeeCode":"04253","status":"A"}],"message":"SUCCESS","status":"SUCCESS","totalCount":7906}');
            return res;
        }
    }
    static testMethod void mockTest() {
        insert new Propeli_API__c( Name = 'Fusion Supplier API',
                                  Access_Key__c = 'W6fpB0krK02mbia4H7z6n7DGkJdTWtNu5NWRNY4w',
                                  Endpoint__c = 'https://qdtnufu29a.execute-api.ap-south-1.amazonaws.com/sfdc-sit-submission/supplier-report',
                                  Authorisation_Type__c = 'application/x-www-form-urlencoded' );
        //User testUser = CommonDataTest.getUserBdm();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock1());
        FussionSupplierDataAPI.getSupplerData();
        Test.stopTest();
    }
    static testMethod void mockTest1() {
        insert new Propeli_API__c( Name = 'Fusion Supplier API',
                                  Access_Key__c = 'W6fpB0krK02mbia4H7z6n7DGkJdTWtNu5NWRNY4w',
                                  Endpoint__c = 'https://qdtnufu29a.execute-api.ap-south-1.amazonaws.com/sfdc-sit-submission/supplier-report',
                                  Authorisation_Type__c = 'application/x-www-form-urlencoded' );
        //   User testUser = CommonDataTest.getUserBdm();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        FussionSupplierDataAPI.getSupplerData();
        Test.stopTest();
    }    
}