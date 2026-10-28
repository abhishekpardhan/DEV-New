@isTest
Private class PropelITokenTest
{
    static testMethod void unitTestPropelITokenTest()
    {
        Test.startTest();
        String str_pltIntegrationProfileId = System.label.Platform_Integration_Profile_ID;
        PropelIToken.addToken('SHHSGGSGGS155HSHHSHHSH222SHHSGGSGGS155HSHHSHHSH222SHHSGGSGGS155HSHHSHHSH222SHHSGGSGGS155HSHHSHHSH222', '0052y000000SXgbAAG');
        String Token2 = PropelIToken.GetToken('0052y000000SXgbAAG');
        Test.stopTest();
    }
}