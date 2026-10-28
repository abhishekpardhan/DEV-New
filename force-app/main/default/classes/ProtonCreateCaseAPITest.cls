@istest
public class ProtonCreateCaseAPITest {
 @testSetup
    static void setupTestData() {

    }
    static testMethod void createCaseTest() {
        
        Test.startTest();
        String myJSON = '{"caseNumber":"null","caseNature":"Request","caseType":"Booking Request","subType":"Retail- PRC","requesterName":"Air force school","requesterAddress":"--","requesterPhone":"9381003021","pickDateTime":"2022-01-31 13:10:55.0","numOfPices":"1","fromLocn":"BANGALORE-11","toLocn":"PUNE","fromPincode":"560006","toPincode":"410501","emailId":"dhananjay.khangal@safexpress.com","pickType":"--","weight":"100","chatDetails":"general","source":"API","remarks":"general","waybillnumber":null,"consigneeName":"--","mode":"SURFACE","product":"","contains":"","mop":"TO-PAY"}';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/ProtonCreateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        ProtonCreateCaseAPI.createCase();
        ProtonCreateCaseAPI.ResponseWrapper res = new ProtonCreateCaseAPI.ResponseWrapper();
        Test.stopTest();
    }
    static testMethod void createCaseTest1() {
        contact con = CommonDataTest.getContact();
        case testCase = new case(Status = 'New',
                                ContactId = con.id);
        Test.startTest();
        String myJSON = '{"caseNumber":"null","caseNature":"Request","caseType":"Booking Request","subType":"Retail- PRC","requesterName":"Air force school","requesterAddress":"--","requesterPhone":"9381003021","pickDateTime":"2022-01-31 13:10:55.0","numOfPices":"1","fromLocn":"BANGALORE-11","toLocn":"PUNE","fromPincode":"560006","toPincode":"410501","emailId":"dhananjay.khangal@safexpress.com","pickType":"--","weight":"100","chatDetails":"general","source":"API","remarks":"general","waybillnumber":null,"consigneeName":"--","mode":"SURFACE","product":"","contains":"","mop":"TO-PAY"}';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/ProtonCreateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        ProtonCreateCaseAPI.createCase();
        ProtonCreateCaseAPI.ResponseWrapper res = new ProtonCreateCaseAPI.ResponseWrapper();
        Test.stopTest();
    }
    /*static testMethod void createCaseTest2() {
        contact con = CommonDataTest.getContact();
        case testCase = new case(Status = 'New',
                                ContactId = con.id);
        Test.startTest();
        String myJSON = '{"caseNumber":null,"caseNature":"Request","caseType":"Booking Request","subType":"Retail- PRC","requesterName":"testing test3","requesterAddress":"AFORESEVECOM LTD NEW NO 233 OLD NO 227 PLOT NO 16A DODDANEKUNDI IND AREA 2 ND PHASE MAHADEVPURA, , , KARNATAKA,560048, INDIA - EMAIL ID : testing22@gmail.com","requesterPhone":"7892962604","pickDateTime":"2022-12-10 16:30:38.0","numOfPices":"3","fromLocn":"BANGALORE-11","toLocn":"DIMAPUR","fromPincode":"560006","toPincode":"410501","emailId":"testing1333@gmail.com","pickType":"--","weight":"0","chatDetails":"Externally cancelled","source":"WEB SITE","remarks":"Externally cancelled","waybillnumber":null,"consigneeName":"ACER INDIA PVT LTD","mode":"SURFACE","product":"","contains":"","mop":"","reqNo":"REQ20221104000683","status":"New"}';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/ProtonCreateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        ProtonCreateCaseAPI.createCase();
        ProtonCreateCaseAPI.ResponseWrapper res = new ProtonCreateCaseAPI.ResponseWrapper();
        Test.stopTest();
    }
    static testMethod void createCaseTest3() {
        contact con = CommonDataTest.getContact();
        case testCase = new case(Status = 'New',
                                ContactId = con.id);
        Test.startTest();
        String myJSON = '{"caseNumber":null,"caseNature":"Request","caseType":"Booking Request","subType":"Retail- PRC","requesterName":"LEX Chatbot User","requesterAddress":"Dr Revathy R Vineeth, H28/404, Panch Ganga CHSL, Near bus depot, Pratiksha Nagar, Sion East, Mumbai. 400022","requesterPhone":"9497361555","pickDateTime":"2022-12-10 10:00:00.0","numOfPices":"2","fromLocn":"--","toLocn":"--","fromPincode":"688539","toPincode":"400022","emailId":"testing333@gmail.com","pickType":"--","weight":"0","chatDetails":"Pickup-pin=688539; Delivery-pin=400022; Full Pickup Address=Ramachandra Panicker, Surya house, Maruthorvattom P O, Cherthala, Alappuzha. 688539; Full Delivery Address=Dr Revathy R Vineeth, H28/404, Panch Ganga CHSL, Near bus depot, Pratiksha Nagar, Sion East, Mumbai. 400022; Own boxes= 2; Pickup Date=2022-11-05; Pickup Time=10:00; ","source":"CHAT","remarks":"Pickup-pin=688539; Delivery-pin=400022; Full Pickup Address=Ramachandra Panicker, Surya house, Maruthorvattom P O, Cherthala, Alappuzha. 688539; Full Delivery Address=Dr Revathy R Vineeth, H28/404, Panch Ganga CHSL, Near bus depot, Pratiksha Nagar, Sion East, Mumbai. 400022; Own boxes= 2; Pickup Date=2022-11-05; Pickup Time=10:00; ","waybillnumber":"","consigneeName":null,"mode":"SURFACE","product":"","contains":"","mop":"","reqNo":"REQ20221102000341","status":"New"}';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://test.salesforce.com/services/apexrest/ProtonCreateSupportCase';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(myJSON);
        RestContext.request = request;
        ProtonCreateCaseAPI.createCase();
        ProtonCreateCaseAPI.ResponseWrapper res = new ProtonCreateCaseAPI.ResponseWrapper();
        Test.stopTest();
    }*/
}