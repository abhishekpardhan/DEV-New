/**
 * @File Name          : HttpFormBuilderTest.cls
 * @Description        : HttpFormBuilderTest is the test class for HttpFormBuilder apex class
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
private class HttpFormBuilderTest {
    @testSetup static void createTestData() {
        String endpoint = 'www.google.com';
        Safex_API__c safexApi = TestDataFactory.createSafexAPI(ConstantUtility.WAY_BILL_API_NAME, 'test', 'basic', null, null,endpoint, 'testUser', 'testPassword');
      //  insert safexApi;
    }
    static testMethod void propelCreateTicketTest() {
        Test.startTest();
        String json = '{"name:"test""}';
        String contentType = HttpFormBuilder.GetContentType();
        String form64 = HttpFormBuilder.append('test', json);
        blob formBlob = HttpFormBuilder.makeBlobWithFile('file',Blob.valueOf('test'),'test',null);
        blob formBlob2 = HttpFormBuilder.makeBlob('file');
        String tes = HttpFormBuilder.writeFileBody('file',Blob.valueOf('test'),'test1');
        Test.stopTest();
    }




}