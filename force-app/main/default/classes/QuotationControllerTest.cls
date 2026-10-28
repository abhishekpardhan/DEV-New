/**
 * Description		:		Test class for QuotationController apex class
 * 
 * Coverage			:		81%
 **/
@isTest
public class QuotationControllerTest 
{
    @testSetup
    static void setupTestData()
    {
        insert new Group_State_Master__c(Group__c= 'North One', State__c = 'Delhi; Haryana; Rajasthan; Uttar Pradesh');
        
        insert new list<Zone_Matrix__c> {new Zone_Matrix__c(Ex_Group__c ='North One', To_Group__c='North One', Zone__c='A' ),
                                new Zone_Matrix__c(Ex_Group__c ='North One', To_Group__c='North One', Zone__c='A' )};
                                
        insert new list<Price_Master__c> {new Price_Master__c(Air_Price__c = 1, Amount__c=2, Surface_Price__c=2, Type__c='Credit', Zone__c='A'), 
                                        new Price_Master__c(Air_Price__c = 1, Amount__c=2, Surface_Price__c=2, Type__c='Credit', Zone__c='A')}; 
                                        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;  
        
        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
        
        Opportunity__c objOpp1 = CommonDataTest.getOpportunity();
        objOpp1.Account__c = objPro.Id;
        objOpp1.Customer_Type__c= 'Renewal Opportunity';
        objOpp1.SFX_Code__c = '123';
        insert objOpp1;
        
        User us = CommonDataTest.getUserBdm();
        insert us;
        
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.National1__c = true;
        accteam.Collection__c = true;
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        insert accteam;
        
        Id rIdquoteNew = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId();

        Quote__c objQuo = CommonDataTest.getQuote();
        objQuo.Opportunity__c = objOpp1.Id;  
        objQuo.Enter_Remarks__c = null;
        objQuo.recordTypeId = rIdquoteNew;
        insert objQuo;                          
                                        
    }
    
    static testmethod void getZoneTest()
    {
        QuotationController.getZone('Delhi');
    }
    
    static testmethod void getCommandmentTest()
    {
        insert new list<Commandment_Master__c> { new Commandment_Master__c(Name = 'Fuel Surcharge', Air_Amount__c = 1, Surface_Amount__c=1, Type__c='Credit')};
        QuotationController.getCommandment();
    }   
    
    static testmethod void saveQLITest()
    {
        ID qtID = [select id from Quote__c limit 1].Id;
        
        QuotationController.wrapper wp = new QuotationController.wrapper();
        wp.Zone = 'A';
        wp.State='Delhi';
        wp.SurfacePrice=0;
        wp.AirPrice=0;
        wp.City='Delhi';
        wp.qtId=null;
        wp.Name='Tst Special Destinations';
        wp.Rate=1;
        wp.MinimumFrt=1;
        wp.check=true;
        wp.Exstate='Test';
        wp.YieldSurface=1;
        wp.YieldAir=1;
        
        list<QuotationController.wrapper> lst = new list<QuotationController.wrapper>{ wp };
        String lstVal = JSON.serialize(lst);
        
        QuotationController.wrapper wp1 = new QuotationController.wrapper();
        wp1 = wp;
        wp1.Name = 'Tst Zone Prices';
        lst = new list<QuotationController.wrapper>{ wp1 };
        String lstZoneState = JSON.serialize(lst);
        
        QuotationController.wrapper wp2 = new QuotationController.wrapper();
        wp2 = wp;
        wp2.Name = 'Tst Commandments';
        lst = new list<QuotationController.wrapper>{ wp2 };
        String lstCommandment = JSON.serialize(lst);
                                        
        QuotationController.wrapper wp3 = new QuotationController.wrapper();
        wp3 = wp;
        wp3.Name = 'Safextension';
        lst = new list<QuotationController.wrapper>{ wp3 };
        String lstSafextension = JSON.serialize(lst);
        
        Id qId = qtID;
        
        String exstate = 'Delhi';
        
        QuotationController.wrapper wp4 = new QuotationController.wrapper();
        wp4 = wp;
        wp4.Name = 'State Surcharge';
        lst = new list<QuotationController.wrapper>{ wp4 };
        String stateSurcharge = JSON.serialize(lst);
        
        QuotationController.checkQuote(qId);
        QuotationController.checkQuote2(qId);
        QuotationController.saveQLI(lstVal, lstZoneState, lstCommandment, qId, lstSafextension, exstate, stateSurcharge ,stateSurcharge );
        QuotationController.checkQuote(qId);
        QuotationController.checkQuote2(qId);
        QuotationController.getStates();
        QuotationController.getCity();
        
        QuotationController.getOpportunityDetail(qId);
        
        State_And_City_Combination__c sc = CommonDataTest.getStateANDCity();
        insert sc;
          QuotationController.getDependentPicklist();
        /*QuotationController.getDependentPicklist('lead__c', 'state__c', 'city__c');
        QuotationController.getDependentPicklist('lead1__c', 'state__c', 'city__c');
        QuotationController.getDependentPicklist('lead__c', 'state1__c', 'city__c');*/
        
        QuotationController.checkReadonly(qId);
        PicklistEntryWrapper obj = new PicklistEntryWrapper();
        obj.active = '';
        obj.defaultValue='';
        obj.value =''; 
    } 
}