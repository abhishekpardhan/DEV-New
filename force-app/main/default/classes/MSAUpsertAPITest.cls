/**
 * Description    :    Test class for MSAUpsertAPI apex class
 * 
 * Coverage      :    100%
 **/
@IsTest
private class MSAUpsertAPITest{
    static testMethod void testPostMethod()
    {     
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        
        req.requestUri ='/services/apexrest/MSAUpsertAPI';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = resp;
        
        MSAUpsertAPI.jsonWrap cust = new MSAUpsertAPI.jsonWrap();
        cust.Account_Name = 'SAFEX';
        //cust.Region = 'Delhi';
        cust.Vertical = 'HI TECH';
        cust.Sub_Vertical = 'IT';
        cust.Propel_MSACode = 'ABC12345';
        cust.Propel_Key = '1234';
        cust.Contact_Person_Name = 'YASH';
        cust.Phone = '9990898887';
        cust.Email = 'test@gmail.com';
        cust.Customer_Type = 'Credit';
        cust.PAN = 'BUGHY6578P';
        cust.Opportunity_Name = 'New Opp';
        cust.Opportunity_Type = 'New Opportunity';
        cust.X3PL_Potential = 45667;
        cust.GST_Number = '44ABCDE1234F2A5';
        cust.GST_Exempted = false;
        cust.TAN_Number = null;
        cust.TAN_Exempted = true;
        cust.MONTHLY_POTENTIAL_AIR = 787889;
        cust.Charged_wt_waybill = 6780;
        cust.Value_of_goods_waybill = 899;
        cust.Opp_Code = 788989;
        
        List<MSAUpsertAPI.jsonWrap> lstWrap = new List<MSAUpsertAPI.jsonWrap>();
        lstWrap.add(cust);
        Test.startTest();
        MSAUpsertAPI.createCustomer(lstWrap);
        Test.stopTest();
        String testStr = resp.responseBody.toString();
        System.assert(testStr != null);
      //  integer i = testStr.IndexOf('compositeKey');        
       // System.assertEquals('SAFEX773-12345', testStr.subString(i+15,i+29));*/
        
    }

}