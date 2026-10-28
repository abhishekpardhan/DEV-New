/*------------------------------------------------------------------------
* Author: Safexpress
* Description: test class to cover the "cls_AddTokenBillingSystem" class
* Coverage: 
* History:
* Modified By/Date: Comment:
* ----------------------------------------------------------------------*/ 
@isTest
public class cls_BillingSubmissionRequestTest {
    
    
    static testMethod void  validateBillingSubmissionAPI()
    {
        //get record type ids.
        Id msaIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Id sfxIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Id serviceIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        Id ratecardIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Id branchIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
        // Insert barnch master record.                
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        br.PropelI_Branch_ID__c = 12345;
        insert br;
        System.assertNotEquals(br.id, null);
        // Create custom setting. 
        PropelAPI_Token__c propToken = new PropelAPI_Token__c();
        propToken.String0__c = 'SFGGSGSFSVSVVSVSV';
        propToken.String1__c = 'SGGTWUUWYYWYYWYYWYWYYW';
        propToken.String2__c = 'SGSGHSHHHEHHEHE';
        propToken.String3__c = 'SGTEHETHEHHDHDHHD';
        propToken.String4__c ='KJHYSHGSTSRRSRSWEESTSTRERERTS';
        insert propToken;
        // Insert MSA Account
        Account newMSAAcc = new Account();
        newMSAAcc.Name = 'unit testing';
        newMSAAcc.Region__c = 'Delhi';
        newMSAAcc.Vertical__c = 'ENGINEERING';
        newMSAAcc.Sub__c ='BUILDING MATERIAL';
        newMSAAcc.Propel_MSACode__c = 'MSA999999245';
        newMSAAcc.RecordTypeID = msaIDs;
        newMSAAcc.Propel_Key__c = '89';
        newMSAAcc.Contact_Person_Name__c ='Akshay Testing' ;
        newMSAAcc.Phone = '011232324';
        newMSAAcc.Mobile_No__c ='9999161406';
        newMSAAcc.Email__c = 'akshay@gmail.com';
        newMSAAcc.Type__c = 'Credit';
        newMSAAcc.Pan_No__c = 'DDDPD4567G';
        insert newMSAAcc;
        System.assertNotEquals(newMSAAcc.id, null);
        
        Account newSFX = new Account();
        newSFX.Name = 'SFX999999057';
        newSFX.SFX_Code__c = 'SFX999999057';
        newSFX.Propeli_Id__c = Decimal.valueOf('6938');
        newSFX.Propel_key__c= '243453';
        newSFX.ParentId = newMSAAcc.Id;
        newSFX.RecordTypeID = sfxIDs;
        newSFX.Contract_Sign_Date__c = Date.today();
        newSFX.Contract_Effective_Date__c =  Date.today();
        newSFX.Contract_Expiry_date__c =  Date.today().addDays(10);
        newSFX.Direct_Pickup__c = 'NO';
        newSFX.Delivery_Hold__c = 'NO';
        newSFX.Status__c ='ACTIVE';
        newSFX.Business_Type__c ='OUTBOUND';
        newSFX.Service_line__c = 'DISTRIBUTION';
        insert newSFX;
        System.assertNotEquals(newSFX.id, null);
        // Add a service account. 
        Account newServiceAcc = new Account();
        newServiceAcc.Name = 'SURFACE';
        newServiceAcc.Service_Offering__c = 'SURFACE';
        newServiceAcc.ParentId =  newSFX.Id;
        newServiceAcc.Comp__c = 'newSFX' + '-' + 'SFX999999057';
        newServiceAcc.RecordTypeID = serviceIDs;
        insert newServiceAcc;
        System.assertNotEquals(newServiceAcc.Id, null);
        // Add a rate card.
        Account newRateCard = new Account();
        newRateCard.Name = 'RC687887';
        newRateCard.rate_card_id__c =6874;
        newRateCard.Rate_card_start_date__c = Date.today();
        newRateCard.Rate_card_end_date__c = Date.today().addDays(10);
        newRateCard.Status__c = 'ACTIVE';
        newRateCard.ParentId =  newServiceAcc.Id;
        newRateCard.RecordTypeID  = ratecardIDs;
        newRateCard.Composite_Key__c = '6874' + '-' + 'SURFACE' + '-' + 'SFX999999057';
        insert newRateCard;
        System.assertNotEquals(newRateCard.Id, null);
        
        // Add a branch type account. 
        Account newBranchAcc = new Account();
        newBranchAcc.Name = 'ASSIGN BRANCH:'+ 'RC687887'+ '-'+'SFX999999057';
        newBranchAcc.AssignBranch_ID__c = '12345' ;
        newBranchAcc.Effective_Date__c = Date.today();
        newBranchAcc.Booking_hold__c= '1';
        newBranchAcc.Booking_Hold_Reason__c = 'Reason 1';
        newBranchAcc.Delivery_Hold__c='1';
        newBranchAcc.Delivery_Hold_Reason__c= 'Reason 1';
        newBranchAcc.Expiry_Date__c = Date.today().addDays(10);
        newBranchAcc.RecordTypeID = branchIDs;
        newBranchAcc.ParentId = newRateCard.Id;
        newBranchAcc.CompBranch__c = '12345' + '-' +'6874' + '-' + 'SURFACE' + '-' + 'SFX999999057'; 
        insert newBranchAcc;
        System.assertNotEquals(newBranchAcc.Id, null);
        // Create contact
        Contact newCon = new Contact();
        newCon.FirstName = 'Unit';
        newCon.LastName = 'Testing';
        newCon.Email = 'unittest@gmail.com';
        newCon.Phone = '9999161406';
        insert newCon;
        System.assertNotEquals(newCon.Id, null);
        // Insert an invoice.
        Invoice__c inv = new Invoice__c();
        inv.Propel_ID__c=54321;
        inv.Name='210201000003';
        inv.Bill_Number__c='21020100003';    
        //inv.Description__c= 'Debit Note';
        inv.Customer_Contract_ID__c= 29374;
        inv.Customer_Contract_Code__c='SFX00000057';
        // inv.Customer_Contract_Code__c='SAFEX324';
        inv.Charged_Freight_Amount__c= 5600;
        inv.Charged_ST_Amount__c= 6778.50;
        inv.Charged_Total_Amount__c=674590.85;
        inv.Out_Oct_Amount__c=768.00;
        inv.Out_Total_Amount__c=7483900.00;
        inv.Status_LID__c=98765;
        //inv.Bill_Type_Flag__c='';
        inv.Bill_Branch__c =br.Id;
        inv.Collection_Branch__c = br.Id;
        inv.Sub_Branch_Master__c = br.Id;
        inv.Bill_From_Date__c=Date.today();
        inv.Bill_To_Date__c=Date.today();
        inv.Bill_Due_Date__c=Date.today();
        inv.Bill_Date__c=Date.today();
        inv.MSA__c='MSA999999245';
        inv.Description__c = 'ALLIED_CREDIT_BILL';
        inv.Is_Submission_Synced__c = false;
        //inv.SFX_Code__c='SFX00000057';
        //inv.Rate_Card_Number__c='RC6873';
        inv.Submission_Date__c=Date.today();
        inv.Billing_Level__c='MSA';
        //inv.Parent_Invoice__c='a041s000003FS2zAAG';
        inv.Account__c=newMSAAcc.id;
        inv.Composite_Key__c='MSA999999245:210201000003';
        inv.Submitted_To__c = newCon.Id;
        inv.Submission_Date__c  = Date.today();
        insert inv;
        System.assertNotEquals(inv.Id, null);
        Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
        // Create submission task.
        List<Task> tskList = new List<Task>();
        Task tsk = new task();
        tsk.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
        tsk.recordtypeid = rId;
        tsk.whatid = inv.id;
        tsk.Priority = 'High';
        tsk.status = 'Open';
        tsk.Is_PropelI__c = true;
        tsk.Submitted_Date__c = Date.today();
        // t.ownerid = mapAccId.get(inv.account__c);
        tsk.Automation__c = true;
        tsk.ActivityDate = date.newinstance(Date.today().year(), Date.today().month(), Date.today().day()).addDays(7);
        insert tsk;
        tskList.add(tsk);
        System.assertNotEquals(tsk, null);
        String json = 
                '[{"billId":893,"billNumber":"21020100003","status":"ERROR","message":""},{"billId":892,"billNumber":"211703000014","status":"ERROR","message":""}]';
        String auth = '00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW';
        String status = 'success';
        Integer statusCode = 200;
        // Create an invoice submission response.
        Invoice_Submission_Response__c eachResponse = new Invoice_Submission_Response__c();
        eachResponse.Bill_Id__c =123;
        eachResponse.Bill_Number__c = '210201000003';
        eachResponse.Message__c = 'record is successfully inserted.';
        eachResponse.Status__c = 'SUCCESS';
        eachResponse.Invoice__c = inv.Id;
        insert eachResponse;
        System.assertNotEquals(eachResponse.Id, null);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new mockTestClass(json,auth,status,statusCode));
        cls_BillingSubmissionRequest asy = new cls_BillingSubmissionRequest(tskList);
        //asy.settaskids(tsk.Id);
        asy.execute(null);
        Test.stopTest();
        
        //cls_BillingSubmissionRequest.invResponse(json,eachResponse.Invoice__c);
        
         
    }   
    static testMethod void  validateBillingSubmissionAPI2()
    {
        //get record type ids.
        Id msaIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Id sfxIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Id serviceIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        Id ratecardIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Id branchIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
        // Insert barnch master record.                
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        br.PropelI_Branch_ID__c = 12345;
        insert br;
        System.assertNotEquals(br.id, null);
        // Create custom setting. 
        PropelAPI_Token__c propToken = new PropelAPI_Token__c();
        propToken.String0__c = 'SFGGSGSFSVSVVSVSV';
        propToken.String1__c = 'SGGTWUUWYYWYYWYYWYWYYW';
        propToken.String2__c = 'SGSGHSHHHEHHEHE';
        propToken.String3__c = 'SGTEHETHEHHDHDHHD';
        propToken.String4__c ='KJHYSHGSTSRRSRSWEESTSTRERERTS';
        insert propToken;
        // Insert MSA Account
        Account newMSAAcc = new Account();
        newMSAAcc.Name = 'unit testing';
        newMSAAcc.Region__c = 'Delhi';
        newMSAAcc.Vertical__c = 'ENGINEERING';
        newMSAAcc.Sub__c ='BUILDING MATERIAL';
        newMSAAcc.Propel_MSACode__c = 'MSA999999245';
        newMSAAcc.RecordTypeID = msaIDs;
        newMSAAcc.Propel_Key__c = '89';
        newMSAAcc.Contact_Person_Name__c ='Akshay Testing' ;
        newMSAAcc.Phone = '011232324';
        newMSAAcc.Mobile_No__c ='9999161406';
        newMSAAcc.Email__c = 'akshay@gmail.com';
        newMSAAcc.Type__c = 'Credit';
        newMSAAcc.Pan_No__c = 'DDDPD4567G';
        insert newMSAAcc;
        System.assertNotEquals(newMSAAcc.id, null);
        
        Account newSFX = new Account();
        newSFX.Name = 'SFX999999057';
        newSFX.SFX_Code__c = 'SFX999999057';
        newSFX.Propeli_Id__c = Decimal.valueOf('6938');
        newSFX.Propel_key__c= '243453';
        newSFX.ParentId = newMSAAcc.Id;
        newSFX.RecordTypeID = sfxIDs;
        newSFX.Contract_Sign_Date__c = Date.today();
        newSFX.Contract_Effective_Date__c =  Date.today();
        newSFX.Contract_Expiry_date__c =  Date.today().addDays(10);
        newSFX.Direct_Pickup__c = 'NO';
        newSFX.Delivery_Hold__c = 'NO';
        newSFX.Status__c ='ACTIVE';
        newSFX.Business_Type__c ='OUTBOUND';
        newSFX.Service_line__c = 'DISTRIBUTION';
        insert newSFX;
        System.assertNotEquals(newSFX.id, null);
        // Add a service account. 
        Account newServiceAcc = new Account();
        newServiceAcc.Name = 'SURFACE';
        newServiceAcc.Service_Offering__c = 'SURFACE';
        newServiceAcc.ParentId =  newSFX.Id;
        newServiceAcc.Comp__c = 'newSFX' + '-' + 'SFX999999057';
        newServiceAcc.RecordTypeID = serviceIDs;
        insert newServiceAcc;
        System.assertNotEquals(newServiceAcc.Id, null);
        // Add a rate card.
        Account newRateCard = new Account();
        newRateCard.Name = 'RC687887';
        newRateCard.rate_card_id__c =6874;
        newRateCard.Rate_card_start_date__c = Date.today();
        newRateCard.Rate_card_end_date__c = Date.today().addDays(10);
        newRateCard.Status__c = 'ACTIVE';
        newRateCard.ParentId =  newServiceAcc.Id;
        newRateCard.RecordTypeID  = ratecardIDs;
        newRateCard.Composite_Key__c = '6874' + '-' + 'SURFACE' + '-' + 'SFX999999057';
        insert newRateCard;
        System.assertNotEquals(newRateCard.Id, null);
        
        // Add a branch type account. 
        Account newBranchAcc = new Account();
        newBranchAcc.Name = 'ASSIGN BRANCH:'+ 'RC687887'+ '-'+'SFX999999057';
        newBranchAcc.AssignBranch_ID__c = '12345' ;
        newBranchAcc.Effective_Date__c = Date.today();
        newBranchAcc.Booking_hold__c= '1';
        newBranchAcc.Booking_Hold_Reason__c = 'Reason 1';
        newBranchAcc.Delivery_Hold__c='1';
        newBranchAcc.Delivery_Hold_Reason__c= 'Reason 1';
        newBranchAcc.Expiry_Date__c = Date.today().addDays(10);
        newBranchAcc.RecordTypeID = branchIDs;
        newBranchAcc.ParentId = newRateCard.Id;
        newBranchAcc.CompBranch__c = '12345' + '-' +'6874' + '-' + 'SURFACE' + '-' + 'SFX999999057'; 
        insert newBranchAcc;
        System.assertNotEquals(newBranchAcc.Id, null);
        // Create contact
        Contact newCon = new Contact();
        newCon.FirstName = 'Unit';
        newCon.LastName = 'Testing';
        newCon.Email = 'unittest@gmail.com';
        newCon.Phone = '9999161406';
        insert newCon;
        System.assertNotEquals(newCon.Id, null);
        // Insert an invoice.
        Invoice__c inv = new Invoice__c();
        inv.Propel_ID__c=54321;
        inv.Name='210201000003';
        inv.Bill_Number__c='21020100003';    
        //inv.Description__c= 'Debit Note';
        inv.Customer_Contract_ID__c= 29374;
        inv.Customer_Contract_Code__c='SFX00000057';
        // inv.Customer_Contract_Code__c='SAFEX324';
        inv.Charged_Freight_Amount__c= 5600;
        inv.Charged_ST_Amount__c= 6778.50;
        inv.Charged_Total_Amount__c=674590.85;
        inv.Out_Oct_Amount__c=768.00;
        inv.Out_Total_Amount__c=7483900.00;
        inv.Status_LID__c=98765;
        //inv.Bill_Type_Flag__c='';
        inv.Bill_Branch__c =br.Id;
        inv.Collection_Branch__c = br.Id;
        inv.Sub_Branch_Master__c = br.Id;
        inv.Bill_From_Date__c=Date.today();
        inv.Bill_To_Date__c=Date.today();
        inv.Bill_Due_Date__c=Date.today();
        inv.Bill_Date__c=Date.today();
        inv.MSA__c='MSA999999245';
        inv.Description__c = 'ALLIED_CREDIT_BILL';
        //inv.SFX_Code__c='SFX00000057';
        //inv.Rate_Card_Number__c='RC6873';
        inv.Submission_Date__c=Date.today();
        inv.Billing_Level__c='MSA';
        //inv.Parent_Invoice__c='a041s000003FS2zAAG';
        inv.Account__c=newMSAAcc.id;
        inv.Composite_Key__c='MSA999999245:210201000003';
        inv.Submitted_To__c = newCon.Id;
        inv.Submission_Date__c  = Date.today();
        insert inv;
        System.assertNotEquals(inv.Id, null);
        Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
        // Create submission task.
        List<Task> tskList = new List<Task>();
        Task tsk = new task();
        tsk.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
        tsk.recordtypeid = rId;
        tsk.whatid = inv.id;
        tsk.Priority = 'High';
        tsk.status = 'Open';
        tsk.Is_PropelI__c = true;
        tsk.Submitted_Date__c = Date.today();
        // t.ownerid = mapAccId.get(inv.account__c);
        tsk.Automation__c = true;
        tsk.ActivityDate = date.newinstance(Date.today().year(), Date.today().month(), Date.today().day()).addDays(7);
        insert tsk;
        tskList.add(tsk);
        System.assertNotEquals(tsk, null);
        String json = 
                '[{"billId":893,"billNumber":"211703000015","status":"ERROR","message":""},{"billId":892,"billNumber":"211703000014","status":"ERROR","message":""}]';
        String auth = '00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW';
        String status = 'success';
        Integer statusCode = 400;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new mockTestClass(json,auth,status,statusCode));
        //Test.setMock(HttpCalloutMock.class, new mockTestClass.MockHttpTokenResponse());
        cls_BillingSubmissionRequest asy1 = new cls_BillingSubmissionRequest(tskList);
        //asy1.settaskids(tsk.Id);
        asy1.execute(null);
        Test.stopTest();
        // Create an invoice submission response.
        Invoice_Submission_Response__c eachResponse = new Invoice_Submission_Response__c();
        eachResponse.Bill_Id__c =123;
        eachResponse.Bill_Number__c = '210201000003';
        eachResponse.Message__c = 'record is successfully inserted.';
        eachResponse.Status__c = 'SUCCESS';
        eachResponse.Invoice__c = inv.Id;
        insert eachResponse;
        System.assertNotEquals(eachResponse.Id, null);
       // cls_BillingSubmissionRequest.invResponse(eachResponse.Bill_Id__c,eachResponse.Bill_Number__c,eachResponse.Message__c,eachResponse.Status__c,eachResponse.Invoice__c);
        
        
        
    }
    static testMethod void  validateBillingSubmissionWMSAPI()
    {
        //get record type ids.
        Id msaIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Id sfxIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Id serviceIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        Id ratecardIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Id branchIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
        // Insert barnch master record.                
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        br.PropelI_Branch_ID__c = 12345;
        insert br;
        System.assertNotEquals(br.id, null);
        // Insert MSA Account
        Account newMSAAcc = new Account();
        newMSAAcc.Name = 'unit testing';
        newMSAAcc.Region__c = 'Delhi';
        newMSAAcc.Vertical__c = 'ENGINEERING';
        newMSAAcc.Sub__c ='BUILDING MATERIAL';
        newMSAAcc.Propel_MSACode__c = 'MSA999999245';
        newMSAAcc.RecordTypeID = msaIDs;
        newMSAAcc.Propel_Key__c = '89';
        newMSAAcc.Contact_Person_Name__c ='Akshay Testing' ;
        newMSAAcc.Phone = '011232324';
        newMSAAcc.Mobile_No__c ='9999161406';
        newMSAAcc.Email__c = 'akshay@gmail.com';
        newMSAAcc.Type__c = 'Credit';
        newMSAAcc.Pan_No__c = 'DDDPD4567G';
        insert newMSAAcc;
        System.assertNotEquals(newMSAAcc.id, null);
        
        Account newSFX = new Account();
        newSFX.Name = 'SFX999999057';
        newSFX.SFX_Code__c = 'SFX999999057';
        newSFX.Propeli_Id__c = Decimal.valueOf('6938');
        newSFX.Propel_key__c= '243453';
        newSFX.ParentId = newMSAAcc.Id;
        newSFX.RecordTypeID = sfxIDs;
        newSFX.Contract_Sign_Date__c = Date.today();
        newSFX.Contract_Effective_Date__c =  Date.today();
        newSFX.Contract_Expiry_date__c =  Date.today().addDays(10);
        newSFX.Direct_Pickup__c = 'NO';
        newSFX.Delivery_Hold__c = 'NO';
        newSFX.Status__c ='ACTIVE';
        newSFX.Business_Type__c ='OUTBOUND';
        newSFX.Service_line__c = 'DISTRIBUTION';
        insert newSFX;
        System.assertNotEquals(newSFX.id, null);
        // Add a service account. 
        Account newServiceAcc = new Account();
        newServiceAcc.Name = 'SURFACE';
        newServiceAcc.Service_Offering__c = 'SURFACE';
        newServiceAcc.ParentId =  newSFX.Id;
        newServiceAcc.Comp__c = 'newSFX' + '-' + 'SFX999999057';
        newServiceAcc.RecordTypeID = serviceIDs;
        insert newServiceAcc;
        System.assertNotEquals(newServiceAcc.Id, null);
        // Add a rate card.
        Account newRateCard = new Account();
        newRateCard.Name = 'RC687887';
        newRateCard.rate_card_id__c =6874;
        newRateCard.Rate_card_start_date__c = Date.today();
        newRateCard.Rate_card_end_date__c = Date.today().addDays(10);
        newRateCard.Status__c = 'ACTIVE';
        newRateCard.ParentId =  newServiceAcc.Id;
        newRateCard.RecordTypeID  = ratecardIDs;
        newRateCard.Composite_Key__c = '6874' + '-' + 'SURFACE' + '-' + 'SFX999999057';
        insert newRateCard;
        System.assertNotEquals(newRateCard.Id, null);
        
        // Add a branch type account. 
        Account newBranchAcc = new Account();
        newBranchAcc.Name = 'ASSIGN BRANCH:'+ 'RC687887'+ '-'+'SFX999999057';
        newBranchAcc.AssignBranch_ID__c = '12345' ;
        newBranchAcc.Effective_Date__c = Date.today();
        newBranchAcc.Booking_hold__c= '1';
        newBranchAcc.Booking_Hold_Reason__c = 'Reason 1';
        newBranchAcc.Delivery_Hold__c='1';
        newBranchAcc.Delivery_Hold_Reason__c= 'Reason 1';
        newBranchAcc.Expiry_Date__c = Date.today().addDays(10);
        newBranchAcc.RecordTypeID = branchIDs;
        newBranchAcc.ParentId = newRateCard.Id;
        newBranchAcc.CompBranch__c = '12345' + '-' +'6874' + '-' + 'SURFACE' + '-' + 'SFX999999057'; 
        insert newBranchAcc;
        System.assertNotEquals(newBranchAcc.Id, null);
        // Create contact
        Contact newCon = new Contact();
        newCon.FirstName = 'Unit';
        newCon.LastName = 'Testing';
        newCon.Email = 'unittest@gmail.com';
        newCon.Phone = '9999161406';
        insert newCon;
        System.assertNotEquals(newCon.Id, null);
        // Insert an invoice.
        Invoice__c inv = new Invoice__c();
        inv.Propel_ID__c=54321;
        inv.Name='210201000003';
        inv.Bill_Number__c='21020100003';    
        //inv.Description__c= 'Debit Note';
        inv.Customer_Contract_ID__c= 29374;
        inv.Customer_Contract_Code__c='SFX00000057';
        // inv.Customer_Contract_Code__c='SAFEX324';
        inv.Charged_Freight_Amount__c= 5600;
        inv.Charged_ST_Amount__c= 6778.50;
        inv.Charged_Total_Amount__c=674590.85;
        inv.Out_Oct_Amount__c=768.00;
        inv.Out_Total_Amount__c=7483900.00;
        inv.Status_LID__c=98765;
        //inv.Bill_Type_Flag__c='';
        inv.Bill_Branch__c =br.Id;
        inv.Collection_Branch__c = br.Id;
        inv.Sub_Branch_Master__c = br.Id;
        inv.Bill_From_Date__c=Date.today();
        inv.Bill_To_Date__c=Date.today();
        inv.Bill_Due_Date__c=Date.today();
        inv.Bill_Date__c=Date.today();
        inv.MSA__c='MSA999999245';
        inv.Description__c = 'WMS_BILL';
        //inv.SFX_Code__c='SFX00000057';
        //inv.Rate_Card_Number__c='RC6873';
        inv.Submission_Date__c=Date.today();
        inv.Billing_Level__c='MSA';
        //inv.Parent_Invoice__c='a041s000003FS2zAAG';
        inv.Account__c=newMSAAcc.id;
        inv.Composite_Key__c='MSA999999245:210201000003';
        inv.Submitted_To__c = newCon.Id;
        inv.Submission_Date__c  = Date.today();
        insert inv;
        System.assertNotEquals(inv.Id, null);
        Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
        // Create submission task.
        List<Task> tskList = new List<Task>();
        Task tsk = new task();
        tsk.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
        tsk.recordtypeid = rId;
        tsk.whatid = inv.id;
        tsk.Priority = 'High';
        tsk.status = 'Open';
        tsk.Is_PropelI__c = true;
        tsk.Submitted_Date__c = Date.today();
        // t.ownerid = mapAccId.get(inv.account__c);
        tsk.Automation__c = true;
        tsk.ActivityDate = date.newinstance(Date.today().year(), Date.today().month(), Date.today().day()).addDays(7);
        insert tsk;
        tskList.add(tsk);
        System.assertNotEquals(tsk, null);
        String json =
                '[{"billId":893,"billNumber":"211703000015","status":"ERROR","message":""},{"billId":892,"billNumber":"211703000014","status":"ERROR","message":""}]';
        String auth = '00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW';
        String status = 'success';
        Integer statusCode = 200;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new mockTestClass(json,auth,status,statusCode));
        cls_BillingSubmissionRequest asy = new cls_BillingSubmissionRequest(tskList);
        //asy.settaskids(tsk.Id);
        asy.execute(null);
        Test.stopTest();
        // Create an invoice submission response.
        Invoice_Submission_Response__c eachResponse = new Invoice_Submission_Response__c();
        eachResponse.Bill_Id__c =123;
        eachResponse.Bill_Number__c = '210201000003';
        eachResponse.Message__c = 'record is successfully inserted.';
        eachResponse.Status__c = 'SUCCESS';
        eachResponse.Invoice__c = inv.Id;
        insert eachResponse;
        System.assertNotEquals(eachResponse.Id, null);
        //cls_BillingSubmissionRequest.invResponse(eachResponse.Bill_Id__c,eachResponse.Bill_Number__c,eachResponse.Message__c,eachResponse.Status__c,eachResponse.Invoice__c);
        
    }
    static testMethod void  validateBillingSubmissionWMSAPI1()
    {
        //get record type ids.
        Id msaIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Id sfxIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Id serviceIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        Id ratecardIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Id branchIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
        // Insert barnch master record.                
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        br.PropelI_Branch_ID__c = 12345;
        insert br;
        System.assertNotEquals(br.id, null);
        // Insert MSA Account
        Account newMSAAcc = new Account();
        newMSAAcc.Name = 'unit testing';
        newMSAAcc.Region__c = 'Delhi';
        newMSAAcc.Vertical__c = 'ENGINEERING';
        newMSAAcc.Sub__c ='BUILDING MATERIAL';
        newMSAAcc.Propel_MSACode__c = 'MSA999999245';
        newMSAAcc.RecordTypeID = msaIDs;
        newMSAAcc.Propel_Key__c = '89';
        newMSAAcc.Contact_Person_Name__c ='Akshay Testing' ;
        newMSAAcc.Phone = '011232324';
        newMSAAcc.Mobile_No__c ='9999161406';
        newMSAAcc.Email__c = 'akshay@gmail.com';
        newMSAAcc.Type__c = 'Credit';
        newMSAAcc.Pan_No__c = 'DDDPD4567G';
        insert newMSAAcc;
        System.assertNotEquals(newMSAAcc.id, null);
        
        Account newSFX = new Account();
        newSFX.Name = 'SFX999999057';
        newSFX.SFX_Code__c = 'SFX999999057';
        newSFX.Propeli_Id__c = Decimal.valueOf('6938');
        newSFX.Propel_key__c= '243453';
        newSFX.ParentId = newMSAAcc.Id;
        newSFX.RecordTypeID = sfxIDs;
        newSFX.Contract_Sign_Date__c = Date.today();
        newSFX.Contract_Effective_Date__c =  Date.today();
        newSFX.Contract_Expiry_date__c =  Date.today().addDays(10);
        newSFX.Direct_Pickup__c = 'NO';
        newSFX.Delivery_Hold__c = 'NO';
        newSFX.Status__c ='ACTIVE';
        newSFX.Business_Type__c ='OUTBOUND';
        newSFX.Service_line__c = 'DISTRIBUTION';
        insert newSFX;
        System.assertNotEquals(newSFX.id, null);
        // Add a service account. 
        Account newServiceAcc = new Account();
        newServiceAcc.Name = 'SURFACE';
        newServiceAcc.Service_Offering__c = 'SURFACE';
        newServiceAcc.ParentId =  newSFX.Id;
        newServiceAcc.Comp__c = 'newSFX' + '-' + 'SFX999999057';
        newServiceAcc.RecordTypeID = serviceIDs;
        insert newServiceAcc;
        System.assertNotEquals(newServiceAcc.Id, null);
        // Add a rate card.
        Account newRateCard = new Account();
        newRateCard.Name = 'RC687887';
        newRateCard.rate_card_id__c =6874;
        newRateCard.Rate_card_start_date__c = Date.today();
        newRateCard.Rate_card_end_date__c = Date.today().addDays(10);
        newRateCard.Status__c = 'ACTIVE';
        newRateCard.ParentId =  newServiceAcc.Id;
        newRateCard.RecordTypeID  = ratecardIDs;
        newRateCard.Composite_Key__c = '6874' + '-' + 'SURFACE' + '-' + 'SFX999999057';
        insert newRateCard;
        System.assertNotEquals(newRateCard.Id, null);
        
        // Add a branch type account. 
        Account newBranchAcc = new Account();
        newBranchAcc.Name = 'ASSIGN BRANCH:'+ 'RC687887'+ '-'+'SFX999999057';
        newBranchAcc.AssignBranch_ID__c = '12345' ;
        newBranchAcc.Effective_Date__c = Date.today();
        newBranchAcc.Booking_hold__c= '1';
        newBranchAcc.Booking_Hold_Reason__c = 'Reason 1';
        newBranchAcc.Delivery_Hold__c='1';
        newBranchAcc.Delivery_Hold_Reason__c= 'Reason 1';
        newBranchAcc.Expiry_Date__c = Date.today().addDays(10);
        newBranchAcc.RecordTypeID = branchIDs;
        newBranchAcc.ParentId = newRateCard.Id;
        newBranchAcc.CompBranch__c = '12345' + '-' +'6874' + '-' + 'SURFACE' + '-' + 'SFX999999057'; 
        insert newBranchAcc;
        System.assertNotEquals(newBranchAcc.Id, null);
        // Create contact
        Contact newCon = new Contact();
        newCon.FirstName = 'Unit';
        newCon.LastName = 'Testing';
        newCon.Email = 'unittest@gmail.com';
        newCon.Phone = '9999161406';
        insert newCon;
        System.assertNotEquals(newCon.Id, null);
        // Insert an invoice.
        Invoice__c inv = new Invoice__c();
        inv.Propel_ID__c=54321;
        inv.Name='210201000003';
        inv.Bill_Number__c='21020100003';    
        //inv.Description__c= 'Debit Note';
        inv.Customer_Contract_ID__c= 29374;
        inv.Customer_Contract_Code__c='SFX00000057';
        // inv.Customer_Contract_Code__c='SAFEX324';
        inv.Charged_Freight_Amount__c= 5600;
        inv.Charged_ST_Amount__c= 6778.50;
        inv.Charged_Total_Amount__c=674590.85;
        inv.Out_Oct_Amount__c=768.00;
        inv.Out_Total_Amount__c=7483900.00;
        inv.Status_LID__c=98765;
        //inv.Bill_Type_Flag__c='';
        inv.Bill_Branch__c =br.Id;
        inv.Collection_Branch__c = br.Id;
        inv.Sub_Branch_Master__c = br.Id;
        inv.Bill_From_Date__c=Date.today();
        inv.Bill_To_Date__c=Date.today();
        inv.Bill_Due_Date__c=Date.today();
        inv.Bill_Date__c=Date.today();
        inv.MSA__c='MSA999999245';
        inv.Description__c = 'WMS_BILL';
        //inv.SFX_Code__c='SFX00000057';
        //inv.Rate_Card_Number__c='RC6873';
        inv.Submission_Date__c=Date.today();
        inv.Billing_Level__c='MSA';
        //inv.Parent_Invoice__c='a041s000003FS2zAAG';
        inv.Account__c=newMSAAcc.id;
        inv.Composite_Key__c='MSA999999245:210201000003';
        inv.Submitted_To__c = newCon.Id;
        inv.Submission_Date__c  = Date.today();
        insert inv;
        System.assertNotEquals(inv.Id, null);
        Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
        // Create submission task.
        List<Task> tskList = new List<Task>();
        Task tsk = new task();
        tsk.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
        tsk.recordtypeid = rId;
        tsk.whatid = inv.id;
        tsk.Priority = 'High';
        tsk.status = 'Open';
        tsk.Is_PropelI__c = true;
        tsk.Submitted_Date__c = Date.today();
        // t.ownerid = mapAccId.get(inv.account__c);
        tsk.Automation__c = true;
        tsk.ActivityDate = date.newinstance(Date.today().year(), Date.today().month(), Date.today().day()).addDays(7);
        insert tsk;
        tskList.add(tsk);
        System.assertNotEquals(tsk, null);
        String json =
                '[{"billId":893,"billNumber":"211703000015","status":"ERROR","message":""},{"billId":892,"billNumber":"211703000014","status":"ERROR","message":""}]';
        String auth = '00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW';
        String status = 'success';
        Integer statusCode = 400;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new mockTestClass(json,auth,status,statusCode));
        cls_BillingSubmissionRequest asy = new cls_BillingSubmissionRequest(tskList);
        //asy.settaskids(tsk.Id);
        asy.execute(null);
        Test.stopTest();
        // Create an invoice submission response.
        Invoice_Submission_Response__c eachResponse = new Invoice_Submission_Response__c();
        eachResponse.Bill_Id__c =123;
        eachResponse.Bill_Number__c = '210201000003';
        eachResponse.Message__c = 'record is successfully inserted.';
        eachResponse.Status__c = 'SUCCESS';
        eachResponse.Invoice__c = inv.Id;
        insert eachResponse;
        System.assertNotEquals(eachResponse.Id, null);
       // cls_BillingSubmissionRequest.invResponse(eachResponse.Bill_Id__c,eachResponse.Bill_Number__c,eachResponse.Message__c,eachResponse.Status__c,eachResponse.Invoice__c);
        
    }
    static testMethod void  validateBillingSubmissionCreditAPI()
    {
        //get record type ids.
        Id msaIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Id sfxIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Id serviceIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        Id ratecardIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Id branchIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
        // Insert barnch master record.                
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        br.PropelI_Branch_ID__c = 12345;
        insert br;
        System.assertNotEquals(br.id, null);
        // Insert MSA Account
        Account newMSAAcc = new Account();
        newMSAAcc.Name = 'unit testing';
        newMSAAcc.Region__c = 'Delhi';
        newMSAAcc.Vertical__c = 'ENGINEERING';
        newMSAAcc.Sub__c ='BUILDING MATERIAL';
        newMSAAcc.Propel_MSACode__c = 'MSA999999245';
        newMSAAcc.RecordTypeID = msaIDs;
        newMSAAcc.Propel_Key__c = '89';
        newMSAAcc.Contact_Person_Name__c ='Akshay Testing' ;
        newMSAAcc.Phone = '011232324';
        newMSAAcc.Mobile_No__c ='9999161406';
        newMSAAcc.Email__c = 'akshay@gmail.com';
        newMSAAcc.Type__c = 'Credit';
        newMSAAcc.Pan_No__c = 'DDDPD4567G';
        insert newMSAAcc;
        System.assertNotEquals(newMSAAcc.id, null);
        
        Account newSFX = new Account();
        newSFX.Name = 'SFX999999057';
        newSFX.SFX_Code__c = 'SFX999999057';
        newSFX.Propeli_Id__c = Decimal.valueOf('6938');
        newSFX.Propel_key__c= '243453';
        newSFX.ParentId = newMSAAcc.Id;
        newSFX.RecordTypeID = sfxIDs;
        newSFX.Contract_Sign_Date__c = Date.today();
        newSFX.Contract_Effective_Date__c =  Date.today();
        newSFX.Contract_Expiry_date__c =  Date.today().addDays(10);
        newSFX.Direct_Pickup__c = 'NO';
        newSFX.Delivery_Hold__c = 'NO';
        newSFX.Status__c ='ACTIVE';
        newSFX.Business_Type__c ='OUTBOUND';
        newSFX.Service_line__c = 'DISTRIBUTION';
        insert newSFX;
        System.assertNotEquals(newSFX.id, null);
        // Add a service account. 
        Account newServiceAcc = new Account();
        newServiceAcc.Name = 'SURFACE';
        newServiceAcc.Service_Offering__c = 'SURFACE';
        newServiceAcc.ParentId =  newSFX.Id;
        newServiceAcc.Comp__c = 'newSFX' + '-' + 'SFX999999057';
        newServiceAcc.RecordTypeID = serviceIDs;
        insert newServiceAcc;
        System.assertNotEquals(newServiceAcc.Id, null);
        // Add a rate card.
        Account newRateCard = new Account();
        newRateCard.Name = 'RC687887';
        newRateCard.rate_card_id__c =6874;
        newRateCard.Rate_card_start_date__c = Date.today();
        newRateCard.Rate_card_end_date__c = Date.today().addDays(10);
        newRateCard.Status__c = 'ACTIVE';
        newRateCard.ParentId =  newServiceAcc.Id;
        newRateCard.RecordTypeID  = ratecardIDs;
        newRateCard.Composite_Key__c = '6874' + '-' + 'SURFACE' + '-' + 'SFX999999057';
        insert newRateCard;
        System.assertNotEquals(newRateCard.Id, null);
        
        // Add a branch type account. 
        Account newBranchAcc = new Account();
        newBranchAcc.Name = 'ASSIGN BRANCH:'+ 'RC687887'+ '-'+'SFX999999057';
        newBranchAcc.AssignBranch_ID__c = '12345' ;
        newBranchAcc.Effective_Date__c = Date.today();
        newBranchAcc.Booking_hold__c= '1';
        newBranchAcc.Booking_Hold_Reason__c = 'Reason 1';
        newBranchAcc.Delivery_Hold__c='1';
        newBranchAcc.Delivery_Hold_Reason__c= 'Reason 1';
        newBranchAcc.Expiry_Date__c = Date.today().addDays(10);
        newBranchAcc.RecordTypeID = branchIDs;
        newBranchAcc.ParentId = newRateCard.Id;
        newBranchAcc.CompBranch__c = '12345' + '-' +'6874' + '-' + 'SURFACE' + '-' + 'SFX999999057'; 
        insert newBranchAcc;
        System.assertNotEquals(newBranchAcc.Id, null);
        // Create contact
        Contact newCon = new Contact();
        newCon.FirstName = 'Unit';
        newCon.LastName = 'Testing';
        newCon.Email = 'unittest@gmail.com';
        newCon.Phone = '9999161406';
        insert newCon;
        System.assertNotEquals(newCon.Id, null);
        // Insert an invoice.
        Invoice__c inv = new Invoice__c();
        inv.Propel_ID__c=54321;
        inv.Name='210201000003';
        inv.Bill_Number__c='21020100003';    
        //inv.Description__c= 'Debit Note';
        inv.Customer_Contract_ID__c= 29374;
        inv.Customer_Contract_Code__c='SFX00000057';
        // inv.Customer_Contract_Code__c='SAFEX324';
        inv.Charged_Freight_Amount__c= 5600;
        inv.Charged_ST_Amount__c= 6778.50;
        inv.Charged_Total_Amount__c=674590.85;
        inv.Out_Oct_Amount__c=768.00;
        inv.Out_Total_Amount__c=7483900.00;
        inv.Status_LID__c=98765;
        //inv.Bill_Type_Flag__c='';
        inv.Bill_Branch__c =br.Id;
        inv.Collection_Branch__c = br.Id;
        inv.Sub_Branch_Master__c = br.Id;
        inv.Bill_From_Date__c=Date.today();
        inv.Bill_To_Date__c=Date.today();
        inv.Bill_Due_Date__c=Date.today();
        inv.Bill_Date__c=Date.today();
        inv.MSA__c='MSA999999245';
        inv.Description__c = 'CREDIT_BILL';
        //inv.SFX_Code__c='SFX00000057';
        //inv.Rate_Card_Number__c='RC6873';
        inv.Submission_Date__c=Date.today();
        inv.Billing_Level__c='MSA';
        //inv.Parent_Invoice__c='a041s000003FS2zAAG';
        inv.Account__c=newMSAAcc.id;
        inv.Composite_Key__c='MSA999999245:210201000003';
        inv.Submitted_To__c = newCon.Id;
        inv.Submission_Date__c  = Date.today();
        insert inv;
        System.assertNotEquals(inv.Id, null);
        Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
        // Create submission task.
        List<Task> tskList = new List<Task>();
        Task tsk = new task();
        tsk.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
        tsk.recordtypeid = rId;
        tsk.whatid = inv.id;
        tsk.Priority = 'High';
        tsk.status = 'Open';
        tsk.Is_PropelI__c = true;
        tsk.Submitted_Date__c = Date.today();
        // t.ownerid = mapAccId.get(inv.account__c);
        tsk.Automation__c = true;
        tsk.ActivityDate = date.newinstance(Date.today().year(), Date.today().month(), Date.today().day()).addDays(7);
        insert tsk;
        tskList.add(tsk);
        System.assertNotEquals(tsk, null);
        String json =
                '[{"billId":893,"billNumber":"211703000015","status":"ERROR","message":""},{"billId":892,"billNumber":"211703000014","status":"ERROR","message":""}]';
        String auth = '00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW';
        String status = 'success';
        Integer statusCode = 200;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new mockTestClass(json,auth,status,statusCode));
        cls_BillingSubmissionRequest asy = new cls_BillingSubmissionRequest(tskList);
        //asy.settaskids(tsk.Id);
        asy.execute(null);
        Test.stopTest();
        // Create an invoice submission response.
        Invoice_Submission_Response__c eachResponse = new Invoice_Submission_Response__c();
        eachResponse.Bill_Id__c =123;
        eachResponse.Bill_Number__c = '210201000003';
        eachResponse.Message__c = 'record is successfully inserted.';
        eachResponse.Status__c = 'SUCCESS';
        eachResponse.Invoice__c = inv.Id;
        insert eachResponse;
        System.assertNotEquals(eachResponse.Id, null);
        //cls_BillingSubmissionRequest.invResponse(eachResponse.Bill_Id__c,eachResponse.Bill_Number__c,eachResponse.Message__c,eachResponse.Status__c,eachResponse.Invoice__c);
        
    } 
    static testMethod void  validateBillingSubmissionCreditAPI1()
    {
        //get record type ids.
        Id msaIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Id sfxIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Id serviceIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        Id ratecardIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Id branchIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
        // Insert barnch master record.                
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        br.PropelI_Branch_ID__c = 12345;
        insert br;
        System.assertNotEquals(br.id, null);
        // Insert MSA Account
        Account newMSAAcc = new Account();
        newMSAAcc.Name = 'unit testing';
        newMSAAcc.Region__c = 'Delhi';
        newMSAAcc.Vertical__c = 'ENGINEERING';
        newMSAAcc.Sub__c ='BUILDING MATERIAL';
        newMSAAcc.Propel_MSACode__c = 'MSA999999245';
        newMSAAcc.RecordTypeID = msaIDs;
        newMSAAcc.Propel_Key__c = '89';
        newMSAAcc.Contact_Person_Name__c ='Akshay Testing' ;
        newMSAAcc.Phone = '011232324';
        newMSAAcc.Mobile_No__c ='9999161406';
        newMSAAcc.Email__c = 'akshay@gmail.com';
        newMSAAcc.Type__c = 'Credit';
        newMSAAcc.Pan_No__c = 'DDDPD4567G';
        insert newMSAAcc;
        System.assertNotEquals(newMSAAcc.id, null);
        
        Account newSFX = new Account();
        newSFX.Name = 'SFX999999057';
        newSFX.SFX_Code__c = 'SFX999999057';
        newSFX.Propeli_Id__c = Decimal.valueOf('6938');
        newSFX.Propel_key__c= '243453';
        newSFX.ParentId = newMSAAcc.Id;
        newSFX.RecordTypeID = sfxIDs;
        newSFX.Contract_Sign_Date__c = Date.today();
        newSFX.Contract_Effective_Date__c =  Date.today();
        newSFX.Contract_Expiry_date__c =  Date.today().addDays(10);
        newSFX.Direct_Pickup__c = 'NO';
        newSFX.Delivery_Hold__c = 'NO';
        newSFX.Status__c ='ACTIVE';
        newSFX.Business_Type__c ='OUTBOUND';
        newSFX.Service_line__c = 'DISTRIBUTION';
        insert newSFX;
        System.assertNotEquals(newSFX.id, null);
        // Add a service account. 
        Account newServiceAcc = new Account();
        newServiceAcc.Name = 'SURFACE';
        newServiceAcc.Service_Offering__c = 'SURFACE';
        newServiceAcc.ParentId =  newSFX.Id;
        newServiceAcc.Comp__c = 'newSFX' + '-' + 'SFX999999057';
        newServiceAcc.RecordTypeID = serviceIDs;
        insert newServiceAcc;
        System.assertNotEquals(newServiceAcc.Id, null);
        // Add a rate card.
        Account newRateCard = new Account();
        newRateCard.Name = 'RC687887';
        newRateCard.rate_card_id__c =6874;
        newRateCard.Rate_card_start_date__c = Date.today();
        newRateCard.Rate_card_end_date__c = Date.today().addDays(10);
        newRateCard.Status__c = 'ACTIVE';
        newRateCard.ParentId =  newServiceAcc.Id;
        newRateCard.RecordTypeID  = ratecardIDs;
        newRateCard.Composite_Key__c = '6874' + '-' + 'SURFACE' + '-' + 'SFX999999057';
        insert newRateCard;
        System.assertNotEquals(newRateCard.Id, null);
        
        // Add a branch type account. 
        Account newBranchAcc = new Account();
        newBranchAcc.Name = 'ASSIGN BRANCH:'+ 'RC687887'+ '-'+'SFX999999057';
        newBranchAcc.AssignBranch_ID__c = '12345' ;
        newBranchAcc.Effective_Date__c = Date.today();
        newBranchAcc.Booking_hold__c= '1';
        newBranchAcc.Booking_Hold_Reason__c = 'Reason 1';
        newBranchAcc.Delivery_Hold__c='1';
        newBranchAcc.Delivery_Hold_Reason__c= 'Reason 1';
        newBranchAcc.Expiry_Date__c = Date.today().addDays(10);
        newBranchAcc.RecordTypeID = branchIDs;
        newBranchAcc.ParentId = newRateCard.Id;
        newBranchAcc.CompBranch__c = '12345' + '-' +'6874' + '-' + 'SURFACE' + '-' + 'SFX999999057'; 
        insert newBranchAcc;
        System.assertNotEquals(newBranchAcc.Id, null);
        // Create contact
        Contact newCon = new Contact();
        newCon.FirstName = 'Unit';
        newCon.LastName = 'Testing';
        newCon.Email = 'unittest@gmail.com';
        newCon.Phone = '9999161406';
        insert newCon;
        System.assertNotEquals(newCon.Id, null);
        // Insert an invoice.
        Invoice__c inv = new Invoice__c();
        inv.Propel_ID__c=54321;
        inv.Name='210201000003';
        inv.Bill_Number__c='21020100003';    
        //inv.Description__c= 'Debit Note';
        inv.Customer_Contract_ID__c= 29374;
        inv.Customer_Contract_Code__c='SFX00000057';
        // inv.Customer_Contract_Code__c='SAFEX324';
        inv.Charged_Freight_Amount__c= 5600;
        inv.Charged_ST_Amount__c= 6778.50;
        inv.Charged_Total_Amount__c=674590.85;
        inv.Out_Oct_Amount__c=768.00;
        inv.Out_Total_Amount__c=7483900.00;
        inv.Status_LID__c=98765;
        //inv.Bill_Type_Flag__c='';
        inv.Bill_Branch__c =br.Id;
        inv.Collection_Branch__c = br.Id;
        inv.Sub_Branch_Master__c = br.Id;
        inv.Bill_From_Date__c=Date.today();
        inv.Bill_To_Date__c=Date.today();
        inv.Bill_Due_Date__c=Date.today();
        inv.Bill_Date__c=Date.today();
        inv.MSA__c='MSA999999245';
        inv.Description__c = 'CREDIT_BILL';
        //inv.SFX_Code__c='SFX00000057';
        //inv.Rate_Card_Number__c='RC6873';
        inv.Submission_Date__c=Date.today();
        inv.Billing_Level__c='MSA';
        //inv.Parent_Invoice__c='a041s000003FS2zAAG';
        inv.Account__c=newMSAAcc.id;
        inv.Composite_Key__c='MSA999999245:210201000003';
        inv.Submitted_To__c = newCon.Id;
        inv.Submission_Date__c  = Date.today();
        insert inv;
        System.assertNotEquals(inv.Id, null);
        Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
        // Create submission task.
        List<Task> tskList = new List<Task>();
        Task tsk = new task();
        tsk.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
        tsk.recordtypeid = rId;
        tsk.whatid = inv.id;
        tsk.Priority = 'High';
        tsk.status = 'Open';
        tsk.Is_PropelI__c = true;
        tsk.Submitted_Date__c = Date.today();
        // t.ownerid = mapAccId.get(inv.account__c);
        tsk.Automation__c = true;
        tsk.ActivityDate = date.newinstance(Date.today().year(), Date.today().month(), Date.today().day()).addDays(7);
        insert tsk;
        tskList.add(tsk);
        System.assertNotEquals(tsk, null);
        String json =
                '[{"billId":893,"billNumber":"211703000015","status":"ERROR","message":""},{"billId":892,"billNumber":"211703000014","status":"ERROR","message":""}]';
        String auth = '00D0l000000DzLi!ARMAQLH93ywCMfP2_o8wEQVNZ3BokJBQoeJ1oQfQr3G8pgw5FwKPiyfTexgxRn7xOHO6JFU4EZSqraNsAqRP6TLxsLnSbRpW';
        String status = 'success';
        Integer statusCode = 400;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new mockTestClass(json,auth,status,statusCode));
        cls_BillingSubmissionRequest asyPrc = new cls_BillingSubmissionRequest(tskList);
        //asyPrc.settaskids(tsk.Id);
        asyPrc.execute(null);
        Test.stopTest();
        // Create an invoice submission response.
        Invoice_Submission_Response__c eachResponse = new Invoice_Submission_Response__c();
        eachResponse.Bill_Id__c =123;
        eachResponse.Bill_Number__c = '210201000003';
        eachResponse.Message__c = 'record is successfully inserted.';
        eachResponse.Status__c = 'SUCCESS';
        eachResponse.Invoice__c = inv.Id;
        insert eachResponse;
        System.assertNotEquals(eachResponse.Id, null);
        //cls_BillingSubmissionRequest.invResponse(eachResponse.Bill_Id__c,eachResponse.Bill_Number__c,eachResponse.Message__c,eachResponse.Status__c,eachResponse.Invoice__c);
        
    } 
}