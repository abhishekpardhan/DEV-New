//**************** Test class of cls_trgUserhandler ************//
@isTest 
public class cls_trgUserHandlertest{
    
    
    static testMethod void testleadShareInsert(){
        
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        System.runAS(us){
            
            List<Lead__c> ldLst = new List<Lead__c>();
            Lead__c objLead = new Lead__c(
                name = 'TEST LEAD',
                Type__c = 'CREDIT',
                Account_Type__c = 'Emerging',
                Source__c = 'Reference Call ',
                Contact_Person_Name__c = 'test person name',
                Email__c = 'test@gmail.com',
                Phone__c = '1234567898',
                Region__c = 'DELHI',
                Status__c = 'Qualified',
                Street__c ='test street',
                City__c = 'DELHI',
                Zip_Postal_Code__c = '123456',
                State__c = 'DELHI',
                Area__c = 'DELHI'
            );
            ldLst.add(objLead);
            Insert ldLst;
            
            List<user> usLst = new List<user>();
            List<profile> pfList = new List<profile>();
            pfList = [Select Id from profile where Name = 'Area Manager'];                                                   
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = 'test12@test12.com', 
                               Username = 'testabc12@testabc12.com', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = 'test', 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfList[0].Id,
                               Region__c = 'DELHI',
                               AD_Id__c = '123',
                               Department = 'test AM',
                               Designation__c = 'Area manager',
                               Area__c = 'DELHI', 
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'
                              ); 
            usLst.add(UsAM);
            
            Test.startTest();
            	Insert usLst;
            Test.stopTest();
            
            // Asserts 
            
            List<Lead__share> actualLeadShares = [SELECT Id, ParentId, UserOrGroupId FROM Lead__share where ParentId =: ldLst[0].Id AND UserOrGroupId =: usLst[0].Id];
             
            System.assert(actualLeadShares.size() > 0);
            
        }         
    }
    
    static testMethod void deleteLeadShare(){
        
        	String userId = userInfo.getUserId();
        	USer us = [Select Id from User where Id =: userId limit 1];
        System.runAS(us){
            List<Lead__c> ldLst = new List<Lead__c>();
                Lead__c objLead = new Lead__c(
                name = 'TEST LEAD',
                Type__c = 'CREDIT',
                Account_Type__c = 'Emerging',
                Source__c = 'Reference Call ',
                Contact_Person_Name__c = 'test person name',
                Email__c = 'test@gmail.com',
                Phone__c = '1234567898',
                Region__c = 'DELHI',
                Status__c = 'Qualified',
                Street__c ='test street',
                City__c = 'DELHI',
                Zip_Postal_Code__c = '123456',
                State__c = 'DELHI',
                Area__c = 'DELHI'
            );
            
            ldLst.add(objLead);
            
            Lead__c objLead2 = new Lead__c(
                name = 'TEST LEAD',
                Type__c = 'CREDIT',
                Account_Type__c = 'Emerging',
                Source__c = 'Reference Call ',
                Contact_Person_Name__c = 'test person name',
                Email__c = 'test@gmail.com',
                Phone__c = '1234567898',
                Region__c = 'DELHI',
                Status__c = 'Qualified',
                Street__c ='test street',
                City__c = 'DELHI',
                Zip_Postal_Code__c = '123456',
                State__c = 'DELHI',
                Area__c = 'DELHI CENTRAL'
            );
            ldLst.add(objLead2);
            insert ldLst;
            
            List<user> usLst = new List<user>();
            List<profile> pfList = new List<profile>();
            pfList = [Select Id from profile where Name = 'Area Manager'];                                                   
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = 'test1@test1.com', 
                               Username = 'testabc1@testabc1.com', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = 'test', 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfList[0].Id,
                               Region__c = 'DELHI',
                               AD_Id__c = '123',
                               Department = 'test AM',
                               Designation__c = 'Area manager',
                               Area__c = 'DELHI', 
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'
                              ); 
            usLst.add(UsAM);
            insert usLst;
            
            Test.startTest();
        	usLst[0].Area__c = 'DELHI CENTRAL';
        	update usLst;
        	Test.stopTest();
            
			List<Lead__share> actualLeadShares = [SELECT Id, ParentId, UserOrGroupId FROM Lead__share where ParentId =: objLead2.Id AND UserOrGroupId =: usLst[0].Id];
        	System.assert(actualLeadShares.size() > 0);                        
        }
			        	                    
        }    
    
    // Added By Adarsh - SAC-166
    static testMethod void testOppShareInsert(){
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        System.runAS(us){
            List<Opportunity__c> oppLst = new List<Opportunity__c>();
            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP';
            objOpp.Type__c = 'Retail';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            Insert objOpp;
            oppLst.add(objOpp);
            
            
            List<user> usLst = new List<user>();
            List<profile> pfList = new List<profile>();
            pfList = [Select Id from profile where Name = 'Area Manager'];                                                   
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = 'test2@test2.com', 
                               Username = 'testabc2@testabc2.com', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = 'test', 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfList[0].Id,
                               Region__c = 'DELHI',
                               AD_Id__c = '123',
                               Department = 'test AM',
                               Designation__c = 'Area manager',
                               Area__c = 'DELHI', 
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'
                              ); 
            usLst.add(UsAM);
            Test.startTest();
            	Insert usLst;
            Test.stopTest();
            
            // Asserts 
            List<opportunity__share> actualOppShares = [SELECT Id, ParentId, UserOrGroupId,AccessLevel FROM opportunity__share where ParentId =: oppLst[0].Id AND UserOrGroupId =: usLst[0].Id];
            System.assert(actualOppShares.size() > 0);
        }         
    }
    static testMethod void testOppDelShareInsert(){
        
        String userId = userInfo.getUserId();
        USer us = [Select Id from User where Id =: userId limit 1];
        System.runAS(us){
            List<Opportunity__c> oppLst = new List<Opportunity__c>();
            Opportunity__c objOpp = new Opportunity__c();
            objOpp.Name = 'TEST OPP';
            objOpp.Type__c = 'Retail';
            objOpp.X3PL_Potential__c = 23;
            objOpp.Area__c = 'DELHI';
            objOpp.Region__c = 'DELHI';
            Insert objOpp;
            oppLst.add(objOpp);
            
            
            List<user> usLst = new List<user>();
            List<profile> pfList = new List<profile>();
            pfList = [Select Id from profile where Name = 'Area Manager'];                                                   
            User usAM=new User(firstname = 'ABC', 
                               lastName = 'XYZ', 
                               email = 'test3@test3.com', 
                               Username = 'testabc3@testabc3.com', 
                               EmailEncodingKey = 'ISO-8859-1', 
                               Alias = 'test', 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               LocaleSidKey = 'en_US', 
                               LanguageLocaleKey = 'en_US', 
                               ProfileId = pfList[0].Id,
                               Region__c = 'DELHI',
                               AD_Id__c = '123',
                               Department = 'test AM',
                               Designation__c = 'Area manager',
                               Area__c = 'DELHI', 
                               Journey_Type__c = 'Car',
                               Sportfire_Group__c = 'Group 1',
                               Type__c = 'Credit'
                              ); 
            usLst.add(UsAM);
            Insert usLst;
            Test.startTest();
            usLst[0].Area__c = 'DELHI CENTRAL';
            update usLst;
            Test.stopTest();
            
            // Asserts 
            List<opportunity__share> actualOppShares = [SELECT Id, ParentId, UserOrGroupId,AccessLevel FROM opportunity__share where ParentId =: oppLst[0].Id AND UserOrGroupId =: usLst[0].Id];
           // System.assertNotEquals(actualOppShares[0].id, Null);
            System.assert(actualOppShares.size() == 0);
        }
    }
    //changes end - SAC-166
}