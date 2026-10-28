/**
 * Description		:		Test class for PortfolioClass apex class
 * 
 * Coverage			:		91%
 **/
@isTest 
public class PortfolioClassTest{
    private static List<id> lstId = new List<id>();
    private static List<Id> lstAcc = new List<Id>();
    private static List<Account_Team__c> lstAccTeam = new List<Account_Team__c>();
    private static Map<String,List<Id>> mapAcc = new Map<String,List<Id>>();
    static testMethod void testMethod1() {
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
    
        User us = CommonDataTest.getUserBdm();
        insert us;
        User usName = [Select name from user where Id =: us.Id limit 1];
        System.debug('<< us >> '+usName.name);
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c=true ;
        insert accteam;
        lstAccTeam.add(accteam);
        lstAcc.add(objSfx.Id);
        mapAcc.put('rel' ,lstAcc);
        mapAcc.put('col' ,lstAcc);
        mapAcc.put('sub' ,lstAcc);
        mapAcc.put('n1' ,lstAcc);
        mapAcc.put('n2' ,lstAcc);
        mapAcc.put('n3' ,lstAcc);
        mapAcc.put('n4' ,lstAcc);
        mapAcc.put('crs' ,lstAcc);
        PortfolioClass.getAccounts(us.Id);
        PortfolioClass.getAll(us.Id);
        PortfolioClass.getallsearch(objSfx.Name , us.Id);
        PortfolioClass.CreateATeam(lstId , mapAcc ,us.Id);     
        PortfolioClass.removeATeam( lstAccTeam, us.Id);
        PortfolioClass.getUsers(us.Department);
        PortfolioClass.getDepartment();
    }
    static testMethod void testMethod2() {

        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
    
        User us = CommonDataTest.getUserBdm();
        insert us;
        User usName = [Select name from user where Id =: us.Id limit 1];
        System.debug('<< us >> '+usName.name);
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c=true ;
        insert accteam;
        lstAccTeam.add(accteam);
        lstAcc.add(objSfx.Id);
        mapAcc.put('col' ,lstAcc);
        mapAcc.put('sub' ,lstAcc);
        mapAcc.put('n1' ,lstAcc);
        mapAcc.put('n2' ,lstAcc);
        mapAcc.put('n3' ,lstAcc);
        mapAcc.put('n4' ,lstAcc);
        mapAcc.put('crs' ,lstAcc);
        PortfolioClass.CreateATeam(lstId , mapAcc ,us.Id);     
    }
    static testMethod void testMethod3() {
        
        //List<id> lstId = new List<id>();
        List<Id> lstAcc = new List<Id>();
        List<Account_Team__c> lstAccTeam = new List<Account_Team__c>();
        Map<String,List<Id>> mapAcc = new Map<String,List<Id>>();
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
    
        User us = CommonDataTest.getUserBdm();
        insert us;
        User usName = [Select name from user where Id =: us.Id limit 1];
        System.debug('<< us >> '+usName.name);
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c=true ;
        insert accteam;
        lstAccTeam.add(accteam);
        lstAcc.add(objSfx.Id);
        mapAcc.put('sub' ,lstAcc);
        mapAcc.put('n1' ,lstAcc);
        mapAcc.put('n2' ,lstAcc);
        mapAcc.put('n3' ,lstAcc);
        mapAcc.put('n4' ,lstAcc);
        mapAcc.put('crs' ,lstAcc);
        PortfolioClass.CreateATeam(lstId , mapAcc ,us.Id);     
    }
    static testMethod void testMethod4() {
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
    
        User us = CommonDataTest.getUserBdm();
        insert us;
        User usName = [Select name from user where Id =: us.Id limit 1];
        System.debug('<< us >> '+usName.name);
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c=true ;
        insert accteam;
        lstAccTeam.add(accteam);
        lstAcc.add(objSfx.Id);
        mapAcc.put('n1' ,lstAcc);
        mapAcc.put('n2' ,lstAcc);
        mapAcc.put('n3' ,lstAcc);
        mapAcc.put('n4' ,lstAcc);
        mapAcc.put('crs' ,lstAcc);
        PortfolioClass.CreateATeam(lstId , mapAcc ,us.Id);     
    }
    static testMethod void testMethod5() {
        
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
    
        User us = CommonDataTest.getUserBdm();
        insert us;
        User usName = [Select name from user where Id =: us.Id limit 1];
        System.debug('<< us >> '+usName.name);
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c=true ;
        insert accteam;
        lstAccTeam.add(accteam);
        lstAcc.add(objSfx.Id);
        mapAcc.put('n2' ,lstAcc);
        mapAcc.put('n3' ,lstAcc);
        mapAcc.put('n4' ,lstAcc);
        mapAcc.put('crs' ,lstAcc);
        PortfolioClass.CreateATeam(lstId , mapAcc ,us.Id);     
    }
    static testMethod void testMethod6() {
       
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
    
        User us = CommonDataTest.getUserBdm();
        insert us;
        User usName = [Select name from user where Id =: us.Id limit 1];
        System.debug('<< us >> '+usName.name);
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c=true ;
        insert accteam;
        lstAccTeam.add(accteam);
        lstAcc.add(objSfx.Id);
        mapAcc.put('n3' ,lstAcc);
        mapAcc.put('n4' ,lstAcc);
        mapAcc.put('crs' ,lstAcc);
        PortfolioClass.CreateATeam(lstId , mapAcc ,us.Id);     
    }
    static testMethod void testMethod7() {
       
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
    
        User us = CommonDataTest.getUserBdm();
        insert us;
        User usName = [Select name from user where Id =: us.Id limit 1];
        System.debug('<< us >> '+usName.name);
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c=true ;
        insert accteam;
        lstAccTeam.add(accteam);
        lstAcc.add(objSfx.Id);
        mapAcc.put('n4' ,lstAcc);
        mapAcc.put('crs' ,lstAcc);
        PortfolioClass.CreateATeam(lstId , mapAcc ,us.Id);     
    }
    static testMethod void testMethod8() {
        Account objPro = CommonDataTest.getParentAccount();
        insert objPro;
        
        Opportunity__c objOpp = CommonDataTest.getOpportunity();
        objOpp.Account__c = objPro.Id;
        insert objOpp;

        Account objSfx = CommonDataTest.getSfxAccount();
        objSfx.parentID = objPro.Id;
        objSfx.Opportunity__c = objOpp.Id;
        insert objSfx;
    
        User us = CommonDataTest.getUserBdm();
        insert us;
        User usName = [Select name from user where Id =: us.Id limit 1];
        System.debug('<< us >> '+usName.name);
        Account_Team__c accteam = CommonDataTest.getAccountTeam();
        accteam.Account__c = objSfx.Id;
        accteam.BDM__c=us.Id;
        accteam.Relationship__c=true ;
        insert accteam;
        lstAccTeam.add(accteam);
        lstAcc.add(objSfx.Id);
        mapAcc.put('crs' ,lstAcc);
        PortfolioClass.CreateATeam(lstId , mapAcc ,us.Id);     
    }
}