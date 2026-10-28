/**
 * Apex class annotated as @isTest in order to contain the test data for test classes
 **/
@isTest
public class CommonDataTest{
    
    public Static String userId = userInfo.getUserId();
    public static Account getParentAccount() {
        Account objPro = new Account();
        objPro.name = 'TEST PROSPECT ACCOUNT';
        objPro.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        objPro.Type = 'Credit';
        objPro.region__c = 'DELHI';
        return objPro;
    }
    
   public static Opportunity__c getCustomOpportunity(Id accountId) {
    Opportunity__c customOpp = new Opportunity__c(
        Name = 'Test Custom Opportunity ' + System.now().getTime(), // 'Name' is almost always a required field
        // IMPORTANT: Add any other REQUIRED fields for your custom Opportunity__c object here.
        // You can find these by checking the fields on your custom Opportunity__c object in Setup -> Object Manager.
        // For example, if your custom Opportunity__c has a mandatory lookup to Account, it might look like this:
        Account__c = accountId, // Replace 'Account_Lookup_Field_On_Custom_Opp__c' with the actual API name
        // Example of another custom mandatory field:
        Stage__c = 'Active', // Replace with an actual stage value if your custom object has a stage
        Close_Date__c = Date.today().addMonths(2) // Replace with an actual date field if mandatory
    );
    return customOpp;
}
    
    public static Account getSfxAccount() {
        Account objSfx = new Account();
        objSfx.name = 'TEST SFX ACCOUNT 1';
        objSfx.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        objSfx.region__c = 'DELHI';
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(60);
        return objSfx;
    }
    public static Account getSfxAccount1() {
        Account objSfx = new Account();
        objSfx.name = 'TEST SFX ACCOUNT 1';
        objSfx.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        objSfx.region__c = 'DELHI';
        objSfx.Contract_Expiry_Date__c = System.Today().addDays(60);
        return objSfx;
    }
    public static Account getPrcAccount() {
        Id rPRCid =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
        Account objSfx1 = new Account();
        objSfx1.name = 'TEST PRC';
        objSfx1.recordTypeId = rPRCid;
        return objSfx1;
    }
    public static Account_Team__c getAccountTeam() {
        Account_Team__c accteam = new Account_Team__c();
        return accteam;
    }
    public static User getUserAM() {
        String orgId=UserInfo.getOrganizationId(); 
        String strRand =String.valueOf(Integer.valueOf(Math.random()*10000));
        System.debug('strRand----->'+strRand);
        Profile pfAM= [Select Id from profile where Name='Area Manager' limit 1]; 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 
        User usAM=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfAM.Id,
                         Region__c = 'CORPORATE OFFICE',
                         AD_Id__c = strRand+'Test2',
                         Department = 'test AM',
                         Designation__c = 'Account Manager - Manages Credit Customers',
                         Area__c = 'CORPORATE OFFICE',
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                         
                        ); 
        
        
        return usAM;
    }
    public static User getUserRetailBDM() {
        String orgId=UserInfo.getOrganizationId(); 
        String strRand =String.valueOf(Integer.valueOf(Math.random()*10000));
        Profile pfAM= [Select Id from profile where Name='Retail BDM' limit 1]; 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 
        User usAM=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfAM.Id,
                         Region__c = 'CORPORATE OFFICE',
                         AD_Id__c = strRand+'Test2',
                         Department = 'test AM',
                         Designation__c = 'Account Manager - Manages Credit Customers',
                         Area__c = 'CORPORATE OFFICE',
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                         
                        ); 
        
        
        return usAM;
    }
    public static User getUserBdm() {
        String orgId=UserInfo.getOrganizationId();    
        String strRand =String.valueOf(Integer.valueOf(Math.random()*10000));
        System.debug('strRand----->'+strRand);
        Profile pfAM= [Select Id from profile where Name='BDM' limit 1]; 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 
        User usAM=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfAM.Id,
                         Region__c = 'CORPORATE OFFICE',
                         AD_Id__c = strRand+'Test1',
                         Department = 'Test bdm',
                         Designation__c = 'Account Manager - Manages Credit Customers',
                         Area__c = 'CORPORATE OFFICE',
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                         
                        ); 
        
        
        return usAM;
    }
     public static User getUserRegionalRetailManager() {
        String orgId=UserInfo.getOrganizationId(); 
        String strRand =String.valueOf(Integer.valueOf(Math.random()*10000));
        Profile pfAM= [Select Id from profile where Name='Regional Retail Manager' limit 1]; 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 
        User usAM=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfAM.Id,
                         Region__c = 'CORPORATE OFFICE',
                         AD_Id__c = strRand+'Test2',
                         Department = 'test AM',
                         Designation__c = 'Account Manager - Manages Credit Customers',
                         Area__c = 'CORPORATE OFFICE',
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                         
                        ); 
        
        
        return usAM;
    }
    public static User getUserServiceCloudExecutive() {
        String orgId=UserInfo.getOrganizationId();    
        String strRand = String.valueOf(Integer.valueOf(Math.random()*10000));
        System.debug('strRand----->'+strRand);
        Profile pfAM = [Select Id from profile where Name='Service Cloud - Executive' limit 1]; 
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 
        User usAM=new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pfAM.Id,
                         Region__c = 'CORPORATE OFFICE',
                         AD_Id__c = strRand+'Test1',
                         Department = 'Test bdm',
                         Designation__c = 'Head-Retail Service Centre',
                         Area__c = 'CORPORATE OFFICE',
                         Journey_Type__c = 'Car',
                         Sportfire_Group__c = 'Group 1',
                         Type__c = 'Credit'
                         
                        ); 
        
        
        return usAM;
    }
    
    public static Branch_Master__c getBranchMaster() {
        Branch_Master__c objBranchMas = new Branch_Master__c();
        objBranchMas.Name = 'TEST BRANCH';
        objBranchMas.Region__c = 'DELHI';
        return objBranchMas;
    }
    public static Contact getContact() {
         Contact objCon = new Contact();
         objCon.FirstName  = 'TEST';
         objCon.LastName = 'pwc';
         objCon.Email = 'test@gmail.com';
        objCon.MobilePhone = '5456789234';  // MobilePhone (not Phone)
        objCon.Phone = '5456789234';
       objCon.Designation__c = 'Manager';  // Must NOT be 'Others' or 'Not Specified'
       objCon.Department__c = 'Finance';   // Must NOT be 'Others'
       objCon.Contact_State__c = 'Delhi';
       objCon.Responsible_for__c = 'Collection';
       objCon.MailingStreet = 'test street';
      objCon.MailingPostalCode = '123456';
       objCon.MailingState = 'Delhi';
       objCon.MailingCity = 'Test contact';
       objCon.MailingCountry = 'In';
      objCon.Address_Type__c = 'Corporate Office';
      return objCon;
      }
    
    public static Invoice__c getInvoice() {//Billing_Line_Item__c bli
        Invoice__c objInv = new Invoice__c();
        objInv.Propel_ID__c = 12345;
        objInv.Submission_Date__c = Date.Today().addDays(3);
        objInv.Charged_Freight_Amount__c = 12;
        objInv.Charged_ST_Amount__c = 34;
        objInv.Charged_Total_Amount__c = 56;
        objInv.Status_LID__c = 292;
        objInv.Bill_Type_Flag__c = 'AB';
        objInv.Customer_Contract_Code__c = 'test pwc'; 
        objInv.Bill_Number__c = '6789';
        objInv.Bill_Due_Date__c = Date.Today().addDays(2);
        objInv.Out_Oct_Amount__c = 5 ;
        objInv.Out_Total_Amount__c = 8;
        //objInv.Billing_Line_Item__c = bli.Id;
        return objInv;
    }
    public static Task getSubmisionTask(){
        Id RecordTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();
        Task objTask = new Task();
        objTask.Subject = 'Test pwc';
        objTask.OwnerId = userId;
        objTask.Type__c = 'BILL SUBMISSION';
        objTask.Priority = 'Normal';
        objTask.status = 'Open';
        objTask.RecordTypeId = RecordTypeId;
        objTask.Mobile_Number__c = '1234567890';
        objTask.Description = 'Test Dec';
        return objTask;
    }
     public static Task getCollectionTask(){
        Id RecordTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Collection').getRecordTypeId();
        Task objTask = new Task();
        objTask.Subject = 'Test pwc';
        objTask.OwnerId = userId;
        objTask.Type__c = 'BILL COLLECTION';
        objTask.Priority = 'Normal';
        objTask.status = 'Open';
        objTask.RecordTypeId = RecordTypeId;
        objTask.Mobile_Number__c = '1234567890';
        objTask.Description = 'Test Dec';
        return objTask;
    }
    public static Task getGeneralTask(){
        Id RecordTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('General').getRecordTypeId();
        Task objTask = new Task();
        objTask.Subject = 'Test pwc';
        objTask.OwnerId = userId;
        objTask.Priority = 'Normal';
        objTask.status = 'Open';
        objTask.RecordTypeId = RecordTypeId;
        objTask.Mobile_Number__c = '1234567890';
        objTask.Description = 'Test Dec';
        return objTask;
    }
    public static Lead__c getLead() {
        Lead__c objLead = new Lead__c();
        objLead.name = 'TEST LEAD';
        objLead.Source__c = 'Reference Call ';
        objLead.Contact_Person_Name__c = 'test person name';
        objLead.Email__c = 'test@gmail.com';
        objLead.Phone__c = '1234567898';
        objLead.Region__c = 'DELHI';    
        objLead.Status__c = 'Active';
        objLead.Street__c ='test street';
        objLead.City__c = 'DELHI';
        objLead.Zip_Postal_Code__c = '123456';
        objLead.State__c = 'DELHI';
        return objLead;
    }
    public static Opportunity__c getOpportunity() {
        Opportunity__c objOpp = new Opportunity__c();
        objOpp.Name = 'TEST OPP';
        objOpp.Type__c = 'Credit';
        objOpp.X3PL_Potential__c = 23;
        return objOpp;
        }
           
    public static Payment__c getPayment() {
        return null;
    }
    public static Quote__c getQuote() {
        Quote__c objQuo = new Quote__c();
        objQuo.name = 'TEST QUOTE';
        objQuo.Time_Frame__c = '24 Hours'; 
        objQuo.Enter_Remarks__c = 'Test Remarks';
        return objQuo;
    }
    public static Case__c getCase(String recordTypw) {
       Id rtypeCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Corporate Credit Case').getRecordTypeId();
        Id rCreditCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Revenue Management Case').getRecordTypeId();
        Id rOperationCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Operation Issues').getRecordTypeId();

        Case__c objCase = new Case__c();
        objCase.Remarks__c = 'TEST remarks testetstetgdjfsdkhsdbjkdfjdsfdsfk';
        objCase.Requested_By__c = 'Customer Requested';
        objCase.Waybill_Numbers__c = '1234567890';
        if(recordTypw == 'Corporate Credit Case'){
            objCase.recordTypeId = rtypeCase;
        }else 
        if(recordTypw == 'Revenue Management Case'){
            objCase.recordTypeId = rCreditCase;
        }else if(recordTypw == 'Operation Issues'){
            objCase.recordTypeId = rOperationCase;
        }
        return objCase;
    }
    public static Debit_Credit_Note__c getDebitCreditNote(){
        Debit_Credit_Note__c objDebit = new Debit_Credit_Note__c();
        objDebit.Remarks__c= 'test debit';
        return objDebit;
    }
    public static ContentVersion getContectVersion(){
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
            );
        return contentVersion_1;
    }
    public static ContentDocumentLink getContentDocumentLink(){
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.ShareType= 'V';
        contentlink.Visibility = 'AllUsers'; 
        return contentlink;
    }
    public static Campaign__c getCampaign(){
        Campaign__c objCam=new Campaign__c();
        objCam.Name = 'Test campaign';
        objCam.Actual_Amount__c = 12; 
        objCam.Address__c = 'test address';
        objCam.Budgeted_Amount__c = 40;
        objCam.City__c = 'DELHI';
        objCam.End_Date__c = System.TODAY() +2 ;
        objCam.Pin_Code__c = '123456';
        objCam.Region__c = 'DELHI';
        objCam.Start_Date__c = System.TODAY() ;
        objCam.State__c = 'DELHI';
        objCam.Status__c = 'Active';
        objCam.Valid_Upto_for_Lead_Generation__c = System.TODAY() +2 ;
        return objCam;
    }
    public static Event__c getEvent(){
        Contact contact = CommonDataTest.getContact();
        contact.LastName = 'Test_' + System.currentTimeMillis();
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.allowSave = true;
        Database.insert(contact, dmlOptions);
        Event__c objEve = new Event__c();
        objEve.Start__c = System.now()+1;
        objEve.End__c = System.now()+1;
        objEve.CheckIn_Date__c = System.now()+1;
        objEve.CheckIn_Location__c = '24.4089,77.3178';
        objEve.CheckOut_Date__c = System.now()+1 ; 
        objEve.CheckOut_Location__c = '28.63,77.25';
        objEve.Is_Claim__c = false;
        objEve.Contact__c = contact.Id;
        return objEve;
    }
    public static Journey__c  getJourney(){
        Journey__c objJ = new Journey__c();
        objJ.Journey_Date__c    = System.TODAY()+1;
        objJ.CheckIn_Date__c = SYstem.now() +1;
        objJ.CheckIn_Location__c = '28.4595,77.0266';
        objJ.CheckOut_Date__c = SYstem.now() +1;
        objJ.CheckOut_Location__c = '28.4595,77.0266';
        objJ.Mode_of_transport__c = 'Public';
        return objJ;
    }
    public static Event_Lead__c  getEventLead(){
        Event_Lead__c objEL = new Event_Lead__c();
        objEL.Name    = 'Test event';
        objEL.Mobile_Phone__c = '1234567898';
        objEL.Pin_Code__c = '123453';
        objEL.Region__c = 'DELHI';
        objEL.Contact_Person_Name__c = 'Test contact';
        objEL.Salutation__c = 'Mrs.';
        objEL.City__c = 'DELHI';
        objEL.Address__c = 'test';
        objEL.State__c = 'DELHI';
        return objEL;
    }
    public static Quote_Line_Item__c  getQuoteLineItem(){
        Quote_Line_Item__c objQuo = new Quote_Line_Item__c();
        objQuo.NAme = 'test';
        objQuo.Zone__c = 'A';
        objQuo.State__c= 'Delhi';
        objQuo.Surface_Price__c = 12;
        objQuo.Air_Price__c = 12;
        objQuo.City__c = 'Delhi';
        objQuo.Rate__c = 12;
        objQuo.Minimum_Freight__c = 12;
        objQuo.check__c = true;
        objQuo.Version__c = null;
        return objQuo;
    }
    
    public  static State_And_City_Combination__c getStateANDCity() {
        State_And_City_Combination__c sC = new State_And_City_Combination__c();
        sc.State__c = 'Kerala';
        sc.City__c = 'Tirupati';
        return sc;
    }
    // Insert MSA Account. 
    Public Static Account getMSAAccount()
    {
        // Record Type Id's. 
        Id msaRecrdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();
        Account newMSA = new Account();
        newMSA.Name ='Unit Testing';
        newMSA.Region__c = 'Delhi';
        newMSA.Vertical__c = 'APPARELS';
        newMSA.Sub__c = 'FABRIC';
        String strRand =String.valueOf(Integer.valueOf(Math.random()*1000000000));
        System.debug('strRand----->'+strRand);
        newMSA.Propel_MSACode__c = 'MSA'+ strRand;
        newMSA.Propel_Key__c = strRand;
        newMSA.Contact_Person_Name__c = 'Unit Testing';
        newMSA.Phone = '8237872489';
        newMSA.Mobile_No__c = '8237872489';
        newMSA.Email__c = 'shreyangedam@safepxr.com';
        newMSA.Type__c = 'Credit';
       // newMSA.Pan_No__c = 'ABCDE1234F';
        newMSA.Pan_No__c = 'ASDGH6789K'; //SAC-1363
        newMSA.RecordTypeId=  msaRecrdTypeId;
        return newMSA;
    }
    // Insert SFX Account
    Public Static Account getNewSFXAccount()
    {
        Id sfxRecrdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
        Account newSFX = new Account();
        String strRand =String.valueOf(Integer.valueOf(Math.random()*1000000000));
        System.debug('strRand----->'+strRand);
        newSFX.Name = 'SFX'+ strRand;
        newSFX.SFX_Code__c = 'SFX'+ strRand;
        newSFX.RecordTypeID  = sfxRecrdTypeId;
        newSFX.Contract_Sign_Date__c =Date.today();
        newSFX.Contract_Effective_Date__c  =Date.today().addDays(5);
        newSFX.Contract_Expiry_date__c = Date.today().addDays(10);
        newSFX.Propel_key__c= strRand;
        newSFX.Direct_Pickup__c  = 'NO';
        newSFX.Delivery_Hold__c ='NO';
        newSFX.Status__c = 'ACTIVE';
        newSFX.Business_Type__c  = 'Outbound';
        newSFX.Service_line__c  = 'Distribution';
        newSFX.Billing_Level__c = 'MSA';
        return newSFX;
    }
    // Insert service account. 
    Public Static Account getServiceAccount()
    {
        Id serviceRecrdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Offering').getRecordTypeId();
        Account servcAcc = new Account();
        servcAcc.Name = 'AIR';
        servcAcc.Service_Offering__c = 'AIR';
        servcAcc.RecordTypeID = serviceRecrdTypeId;

        return servcAcc;
    }
    // Insert Rate Card Account.
    Public Static Account getRateCardAccount()
    {
        Id ratecardRecrdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        Account newRateCard = new Account();
        String strRand =String.valueOf(Integer.valueOf(Math.random()*10000));
        newRateCard.Name = 'RC'+strRand;
        newRateCard.rate_card_id__c = Integer.valueOf(Math.random()*10000);
        newRateCard.Rate_card_start_date__c = Date.today();
        newRateCard.Rate_card_end_date__c = Date.today().addDays(8);
        newRateCard.Status__c = 'ACTIVE';
        newRateCard.RecordTypeID  = ratecardRecrdTypeId;
        return newRateCard;
    }
    // Insert Branch Account. 
    Public Static Account getBarnchAccount()
    {
        Id branchRecrdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assign Branch').getRecordTypeId();
        Account newBranchAcc1 = new Account();
        newBranchAcc1.AssignBranch_ID__c = 'DLS11';
        newBranchAcc1.Effective_Date__c = System.today();
        newBranchAcc1.Booking_hold__c= '0';
        newBranchAcc1.Booking_Hold_Reason__c = 'unit testing';
        newBranchAcc1.Delivery_Hold__c= '0';
        newBranchAcc1.Delivery_Hold_Reason__c= 'unit testing';
        newBranchAcc1.Expiry_Date__c = System.today().addDays(10);
        newBranchAcc1.RecordTypeID = branchRecrdTypeId;
        return newBranchAcc1;
    }
   //SAC-1477 -Tarun Sachdeva | IBM
  
   public static Billing_Information__c getBInf() {
        Billing_Information__c objBInf = new Billing_Information__c();
        objBInf.Billing_Level__c = 'MSA';
        //objBInf.MSA__c = msaNumber;
        //objBInf.SFX_no__c = sfxNumber;
        //objBInf.SFX__c = sfxAccount.id;
        objBInf.Start_Date__c = System.today();
        objBInf.Alias_name__c = 'JSON MARK 1';
        //objBInf.Rate_Card_no__c = rcName;
        //objBInf.Name = 'Billing Info:' + msaNumber+':'+ sfxNumber;
        objBInf.Name = 'Billing Info:';
        return objBInf;
    }
   public static Billing_Line_Item__c getBLI() {
        Billing_Line_Item__c objBLI = new Billing_Line_Item__c();
        objBLI.Composite_Key__c = '9010100';
        return objBLI;
    }

}