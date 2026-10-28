@IsTest
public class CreateComplainCaseAPITest {
	@TestSetup
    static void setup() {
        Contact contact = new Contact(
            LastName = 'Test',
            Email = 'TestEmail@gmail.com',
            MobilePhone = '1234567890'
        );
        insert contact;
    }
    
    @IsTest
    static void test_check_requiredData() {
        String requestBody = '{}';
        RestRequest request = new RestRequest();
        request.requestURI = '/CreateComplainCaseAPI/*';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        Test.startTest();
        CreateComplainCaseAPI.createCase();
        Test.stopTest();
    }
    
    @IsTest
    static void test_createNewCase() {
        String requestBody = '{"caseNature" : "Request", "caseType" : "POD", "subType" : "Address Change", "Description" : "Case is raised", "emailId" : "TestEmail@gmail.com", "Phone" : "1234567890", "Name" : "Test", "source" : "social media"}';
        RestRequest request = new RestRequest();
        request.requestURI = '/CreateComplainCaseAPI/*';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        Test.startTest();
        CreateComplainCaseAPI.createCase();
        Test.stopTest();
        
    }
}