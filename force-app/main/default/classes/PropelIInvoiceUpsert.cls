/**
* Description     :    Rest resource to recieve the incoming flow of invoice records from propel-I and create corresponsing invoice records in Salesforce with compositekey as MSA/SFX/ Rate card. 
* Created By       :       
* Created Date     :       
* Release          :      24th November, 2020
* Last Modified on : 
* Test Class:      
* Jira Ticket      :      https://safexpress.atlassian.net/browse/SD-403
**/
@RestResource(urlMapping='/PropelIInvoiceUpsert/*')
global with sharing class PropelIInvoiceUpsert  {
    
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        Decimal propelId;
        Boolean isCreated;
        Boolean isSuccess;
    }
    Global class APIResponse extends cls_APIResponse
    {
        Global  String SF_InvoiceId;
        Global String MSA_Number;
        Global String Bill_Number;
        Global String SF_CreditNoteId; 
        Global  Datetime SF_CreatedDate; 
        Global  Datetime SF_LastModifiedDate;        
    }
    
    //Wrapper class
    global class jsonWrap 
    {
        public String Bill_Number;
        public Integer Propel_ID;
        public String Description;
        public Integer Customer_Contract_ID;
        public String Customer_Contract_Code;
        public Integer Bill_Branch_ID;
        public Integer Collection_Branch_ID;
        public Integer Sub_Branch_Master_ID;
        public Decimal Charged_Freight_Amount;
        public Decimal Charged_ST_Amount;
        public Decimal Charged_Total_Amount;
        public Decimal Out_Oct_Amount;
        public Decimal Out_Total_Amount;
        public Integer Status_LID;
        public String Bill_Type_Flag;
        public Date Bill_From_Date;
        public Date Bill_To_Date;
        public Date Bill_Due_Date;
        public Date Bill_Date;
        public Date Submission_Date;
        Public String MSA_Number;
        Public String Rate_Card_Number ;
        Public String MSA_Id;
        Public String Rate_Card_Id;
        Public String Billing_Level ;
        Public String Parent_Bill_Number;
        Public String Attribute2;
        Public String Attribute3;
        Public String Attribute4;
        public string SFX_Number; 
        public Date Bill_Creation_Date; 
        public Date Bill_Last_Update_Date; 
        public String e_Bill;
        public String Submitted_to_Email_IDs;
        public String BDM_Email_IDs;
    }
    
    //POST Request method to upsert the invoices within SFDC
    @HttpPost
    global static void createInvoice(List<PropelIInvoiceUpsert.jsonWrap> lstInvRecords) 
    {
        
        // Create an object to return the API response. 
        List<APIResponse> lst_APIResponses = new List<APIResponse>();
        // List of Invoice records to insert/update. 
        List<Invoice__c> lst_InvoiceToUpsert = new List<Invoice__c>();
        System.debug('invRecords------------->'+lstInvRecords);
        if(lstInvRecords != null && lstInvRecords.size() > 0)
        {
            
            // Iterate the JSON to pull the sent ids. 
            // Set to hold the Billing, Collection and Submission branch code. 
            Set<Integer> set_PropelIBranchIds = new Set<Integer>();
            // Map of branch master code and their respective SFDC id's. 
            Map<Decimal, Id> map_PropelIBranchIds = new Map<Decimal, String>();
            // Set of MSA Codes. 
            Set<String> set_MSAIds = new Set<String>();
            // Set of rate card ids. 
            Set<String> set_RateCardIds = new Set<String>();
            // Set of SFX Ids. 
            Set<String> set_SFXIds = new Set<String>();
            // Map of MSA, SFX and Rate Card id's and their respective SFDC id's. 
            Map<String, Id> map_AccountIds = new Map<String, Id>();
            // Set of Parent Invoice Number.
            Set<String> set_ParentInvoiceNumbers = new Set<String>();
            // Map of Parent invoice number of their respective SFDC Id's. 
            Map<String, Id> map_ParentInvoiceIds =new Map<String, Id>();
            
            
            for(PropelIInvoiceUpsert.jsonWrap eachInvoice : lstInvRecords)
            {
                if(String.isNotBlank(String.valueOf(eachInvoice.Bill_Branch_ID)))
                    set_PropelIBranchIds.add(eachInvoice.Bill_Branch_ID);
                
                if(String.isNotBlank(String.valueOf(eachInvoice.Collection_Branch_ID)))
                    set_PropelIBranchIds.add(eachInvoice.Collection_Branch_ID);
                
                if(String.isNotBlank(String.valueOf(eachInvoice.Sub_Branch_Master_ID)))
                    set_PropelIBranchIds.add(eachInvoice.Sub_Branch_Master_ID);
                
                if(String.isNotBlank(eachInvoice.Parent_Bill_Number))  
                    set_ParentInvoiceNumbers.add(eachInvoice.Parent_Bill_Number);  
                
                if(String.isNotBlank(eachInvoice.MSA_Number))
                    set_MSAIds.add(eachInvoice.MSA_Number);
                
                if(String.isNotBlank(eachInvoice.Customer_Contract_Code))
                    set_SFXIds.add(eachInvoice.Customer_Contract_Code);
                
                if(String.isNotBlank(eachInvoice.Rate_Card_Number))
                    set_RateCardIds.add(eachInvoice.Rate_Card_Number);
                
            }
            System.debug('set_PropelIBranchIds---------------->'+set_PropelIBranchIds);
            System.debug('set_ParentInvoiceNumbers------------->'+set_ParentInvoiceNumbers);
            System.debug('set_MSAIds------------->'+set_MSAIds);
            System.debug('set_SFXIds--------------->'+set_SFXIds);
            System.debug('set_RateCardIds------------------->'+set_RateCardIds);
            // Prepare the map of Branch Master and their respective SFDC Id's. 
            if(set_PropelIBranchIds != null && set_PropelIBranchIds.size() > 0)
            {
                List<Branch_Master__c> lst_BillingBrnch = [SELECT id, PropelI_Branch_ID__c from Branch_Master__c where PropelI_Branch_ID__c IN :  set_PropelIBranchIds limit 9999];
                System.debug('lst_BillingBrnch----->'+lst_BillingBrnch);
                if(lst_BillingBrnch != null && lst_BillingBrnch.size() > 0)
                {
                    for(Branch_Master__c eachBranchMaster : lst_BillingBrnch)
                    {
                        map_PropelIBranchIds.put(eachBranchMaster.PropelI_Branch_ID__c, eachBranchMaster.Id);
                    }
                }
            }
            System.debug('map_PropelIBranchIds----------------->'+map_PropelIBranchIds);
            // Prepare the map of MSA, SFX and rate card with their respective SFDC Id's. 
            if(! set_MSAIds.isEmpty() || ! set_SFXIds.isEmpty() || !set_RateCardIds.isEmpty())
            {
                List<Account> lst_Accounts = [Select id,Propel_MSACode__c,SFX_Code__c, name   from Account where Propel_MSACode__c IN : set_MSAIds OR SFX_Code__c IN : set_SFXIds OR ( name IN : set_RateCardIds AND parent.parent.RecordType.DeveloperName != 'PRC_Customer') limit 9999];
                if(! lst_Accounts.isEmpty()){
                    System.debug('lst_Accounts----------------->'+lst_Accounts);
                    for(Account eachAccount : lst_Accounts)
                    {
                        if(! set_MSAIds.isEmpty() && set_MSAIds.contains(eachAccount.Propel_MSACode__c))
                            map_AccountIds.put(eachAccount.Propel_MSACode__c, eachAccount.Id);
                        if(! set_SFXIds.isEmpty() && set_SFXIds.contains(eachAccount.SFX_Code__c))  
                            map_AccountIds.put(eachAccount.SFX_Code__c, eachAccount.Id);  
                        
                        if(!set_RateCardIds.isEmpty() && set_RateCardIds.contains(eachAccount.name))
                            map_AccountIds.put(eachAccount.name, eachAccount.Id );
                        
                    }
                }
            }
            
            System.debug('map_AccountIds----------------->'+map_AccountIds);
            
            if(! set_ParentInvoiceNumbers.isEmpty())
            {
                List<Invoice__c> lstInvoice = [Select id, Name, Parent_Invoice__c from Invoice__c where Name IN : set_ParentInvoiceNumbers limit 9999]; 
                if(! lstInvoice.isEmpty())
                {
                    for(Invoice__c eachInvoice : lstInvoice)
                    {
                        map_ParentInvoiceIds.put(eachInvoice.Name, eachInvoice.Id);
                    }
                }
            }
            System.debug('map_ParentInvoiceIds-------------->'+map_ParentInvoiceIds);
            
            // Iterate the invoice wrapper class. 
            for(PropelIInvoiceUpsert.jsonWrap eachInvoice : lstInvRecords)
            {
                // Each API request response. 
                APIResponse cls_APIResponse = new APIResponse();
                if(String.isNotBlank(String.valueOf(eachInvoice.Bill_Branch_ID)))
                {
                    // Billing Branch should not be blank.
                    if(! map_PropelIBranchIds.isEmpty() && map_PropelIBranchIds.keySet().contains(eachInvoice.Bill_Branch_ID)){
                        // Billing branch exists into SFDC.
                        if(String.isNotBlank(String.valueOf(eachInvoice.Collection_Branch_ID)))
                        {
                            if(! map_PropelIBranchIds.isEmpty() &&  map_PropelIBranchIds.keySet().contains(eachInvoice.Collection_Branch_ID))
                            {   
                                // collection branch exists. 
                                if(String.isNotBlank(String.valueOf(eachInvoice.Sub_Branch_Master_ID)))
                                {
                                    if(! map_PropelIBranchIds.isEmpty() &&  map_PropelIBranchIds.keySet().contains(eachInvoice.Sub_Branch_Master_ID))
                                    {
                                        if(String.isNotBlank(eachInvoice.Description) && eachInvoice.Description.containsIgnoreCase('DEBIT_NOTE'))
                                        {
                                            //When Debit note is opened for the invoice. 
                                            if(String.isNotBlank(eachInvoice.Parent_Bill_Number))
                                            {
                                                if(! map_ParentInvoiceIds.isEmpty() && map_ParentInvoiceIds.keySet().contains(eachInvoice.Parent_Bill_Number)){
                                                    // Insert debit note against of an invoice
                                                    //Invoke insertInvoiceOrDebitNote method. 
                                                    String Parent_Bill_Number = map_ParentInvoiceIds.get(eachInvoice.Parent_Bill_Number) ;
                                                    String AccountId ;
                                                    if( map_AccountIds.containsKey(eachInvoice.MSA_Number) && eachInvoice.Billing_Level.equalsIgnoreCase('MSA')){
                                                        AccountId = map_AccountIds.get(eachInvoice.MSA_Number);
                                                    } else if( map_AccountIds.containsKey(eachInvoice.Customer_Contract_Code) && eachInvoice.Billing_Level.equalsIgnoreCase('SFX')){
                                                        AccountId = map_AccountIds.get(eachInvoice.Customer_Contract_Code);
                                                    } else if( map_AccountIds.containsKey(eachInvoice.Rate_Card_Number) && eachInvoice.Billing_Level.equalsIgnoreCase('Rate Card')){
                                                        AccountId = map_AccountIds.get(eachInvoice.Rate_Card_Number);
                                                    }
                                                     
                                                        
                                                    lst_InvoiceToUpsert.add(PropelIInvoiceUpsert.createInvoiceOrDebitNote(eachInvoice, map_PropelIBranchIds, Parent_Bill_Number, AccountId));
                                                    /*lst_InvoiceToUpsert.add(PropelIInvoiceUpsert.insertInvoiceOrDebitNote(eachInvoice.MSA_Number, 
                                                                                                                          eachInvoice.Customer_Contract_Code, 
                                                                                                                          eachInvoice.Rate_Card_Number ,
                                                                                                                          eachInvoice.Bill_Number,
                                                                                                                          eachInvoice.Propel_ID,
                                                                                                                          eachInvoice.Description,
                                                                                                                          eachInvoice.Customer_Contract_ID, 
                                                                                                                          eachInvoice.Customer_Contract_Code,
                                                                                                                          eachInvoice.Charged_Freight_Amount, 
                                                                                                                          eachInvoice.Charged_ST_Amount, 
                                                                                                                          eachInvoice.Charged_Total_Amount, 
                                                                                                                          eachInvoice.Out_Oct_Amount, 
                                                                                                                          eachInvoice.Out_Total_Amount, 
                                                                                                                          eachInvoice.Status_LID, 
                                                                                                                          eachInvoice.Bill_Type_Flag,
                                                                                                                          eachInvoice.Bill_From_Date, 
                                                                                                                          eachInvoice.Bill_To_Date, 
                                                                                                                          eachInvoice.Bill_Due_Date, 
                                                                                                                          eachInvoice.Bill_Date, 
                                                                                                                          null, 
                                                                                                                          map_PropelIBranchIds.get(eachInvoice.Bill_Branch_ID), 
                                                                                                                          map_PropelIBranchIds.get(eachInvoice.Collection_Branch_ID),  
                                                                                                                          map_PropelIBranchIds.get(eachInvoice.Sub_Branch_Master_ID), 
                                                                                                                          map_ParentInvoiceIds.get(eachInvoice.Parent_Bill_Number), 
                                                                                                                          eachInvoice.Submission_Date, 
                                                                                                                          eachInvoice.Billing_Level
                                                                                                                         ));*/
                                                    
                                                }else{
                                                    //609: Parent invoice doesn't exist. Please insert a valid invoice number. 
                                                    cls_APIResponse.SF_CreditNoteId = null; 
                                                    cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                    cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                    cls_APIResponse.StatusCode = '609';
                                                    cls_APIResponse.StatusMessage = 'Parent Invoice number does not exist in SFDC, please insert an existing invoice number.'; 
                                                    lst_APIResponses.add(cls_APIResponse);
                                                    
                                                }
                                            }else{
                                                cls_APIResponse.SF_CreditNoteId = null; 
                                                cls_APIResponse.StatusCode = '617';
                                                cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                cls_APIResponse.StatusMessage = 'Parent Bill Number can not blank, please insert the parent bill number.'; 
                                                lst_APIResponses.add(cls_APIResponse);
                                            }
                                            
                                        }else // when invoice is sent.
                                        {
                                            if(String.isNotBlank(eachInvoice.Bill_Number))
                                            {
                                                if(String.isNotBlank(eachInvoice.Billing_Level))
                                                {
                                                    if(String.isNotBlank(eachInvoice.MSA_Number) || ! eachInvoice.Billing_Level.equalsIgnoreCase('MSA'))
                                                    {
                                                        
                                                        if(eachInvoice.Billing_Level.equalsIgnoreCase('MSA'))
                                                        {
                                                            if(! map_AccountIds.isEmpty() &&  map_AccountIds.keySet().contains(eachInvoice.MSA_Number))
                                                            {
                                                                //Invoke insertInvoiceOrDebitNote method. 
                                                                String AccountId = map_AccountIds.get(eachInvoice.MSA_Number);
                                                                lst_InvoiceToUpsert.add(createInvoiceOrDebitNote(eachInvoice, map_PropelIBranchIds, null, AccountId)) ;
                                                                /*lst_InvoiceToUpsert.add(PropelIInvoiceUpsert.insertInvoiceOrDebitNote(eachInvoice.MSA_Number, eachInvoice.Customer_Contract_Code, 
                                                                                                                                      eachInvoice.Rate_Card_Number ,eachInvoice.Bill_Number,
                                                                                                                                      eachInvoice.Propel_ID,eachInvoice.Description,
                                                                                                                                      eachInvoice.Customer_Contract_ID, eachInvoice.Customer_Contract_Code,
                                                                                                                                      eachInvoice.Charged_Freight_Amount, eachInvoice.Charged_ST_Amount,
                                                                                                                                      eachInvoice.Charged_Total_Amount, eachInvoice.Out_Oct_Amount, 
                                                                                                                                      eachInvoice.Out_Total_Amount, eachInvoice.Status_LID, eachInvoice.Bill_Type_Flag,
                                                                                                                                      eachInvoice.Bill_From_Date, eachInvoice.Bill_To_Date, eachInvoice.Bill_Due_Date, 
                                                                                                                                      eachInvoice.Bill_Date, 
                                                                                                                                      map_AccountIds.get(eachInvoice.MSA_Number), 
                                                                                                                                      map_PropelIBranchIds.get(eachInvoice.Bill_Branch_ID), 
                                                                                                                                      map_PropelIBranchIds.get(eachInvoice.Collection_Branch_ID),  
                                                                                                                                      map_PropelIBranchIds.get(eachInvoice.Sub_Branch_Master_ID), 
                                                                                                                                      null, 
                                                                                                                                      eachInvoice.Submission_Date, 
                                                                                                                                      eachInvoice.Billing_Level
                                                                                                                                     ));*/   
                                                            }else{
                                                                
                                                                //610: MSA Code does not exist in SFDC. 
                                                                cls_APIResponse.SF_InvoiceId = null; 
                                                                cls_APIResponse.SF_CreditNoteId = null; 
                                                                cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                                cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                                cls_APIResponse.StatusCode = '602';
                                                                cls_APIResponse.StatusMessage = 'MSA Number does not exist in SFDC, please insert an existing MSA number.'; 
                                                                lst_APIResponses.add(cls_APIResponse);
                                                            }
                                                            
                                                        }else if(eachInvoice.Billing_Level.equalsIgnoreCase('SFX'))
                                                        {
                                                            if(String.isNotBlank(eachInvoice.Customer_Contract_Code ))
                                                            {  
                                                                // Call insert invoice method. 
                                                                if(! map_AccountIds.isEmpty() &&  map_AccountIds.keySet().contains(eachInvoice.Customer_Contract_Code)){
                                                                    
                                                                    //Invoke insertInvoiceOrDebitNote method. 
                                                                    String AccountId = map_AccountIds.get(eachInvoice.Customer_Contract_Code);
                                                                    lst_InvoiceToUpsert.add(createInvoiceOrDebitNote(eachInvoice, map_PropelIBranchIds, null, AccountId)) ;
                                                                    /*lst_InvoiceToUpsert.add(PropelIInvoiceUpsert.insertInvoiceOrDebitNote(
                                                                            eachInvoice.MSA_Number, eachInvoice.Customer_Contract_Code, eachInvoice.Rate_Card_Number ,eachInvoice.Bill_Number,eachInvoice.Propel_ID,eachInvoice.Description,eachInvoice.Customer_Contract_ID, eachInvoice.Customer_Contract_Code,
                                                                            eachInvoice.Charged_Freight_Amount, eachInvoice.Charged_ST_Amount, eachInvoice.Charged_Total_Amount, eachInvoice.Out_Oct_Amount, eachInvoice.Out_Total_Amount, eachInvoice.Status_LID, eachInvoice.Bill_Type_Flag,
                                                                            eachInvoice.Bill_From_Date, eachInvoice.Bill_To_Date, 
                                                                            eachInvoice.Bill_Due_Date, 
                                                                            eachInvoice.Bill_Date,
                                                                            map_AccountIds.get(eachInvoice.Customer_Contract_Code), 
                                                                            map_PropelIBranchIds.get(eachInvoice.Bill_Branch_ID),
                                                                            map_PropelIBranchIds.get(eachInvoice.Collection_Branch_ID),  
                                                                            map_PropelIBranchIds.get(eachInvoice.Sub_Branch_Master_ID), 
                                                                            null, 
                                                                            eachInvoice.Submission_Date, 
                                                                            eachInvoice.Billing_Level));*/
                                                                    
                                                                }else{
                                                                    // 604: SFX does not exist, please insert a valid SFX number.
                                                                    cls_APIResponse.SF_InvoiceId = null; 
                                                                    cls_APIResponse.SF_CreditNoteId = null; 
                                                                    cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                                    cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                                    cls_APIResponse.StatusCode = '604';
                                                                    cls_APIResponse.StatusMessage = 'SFX Number does not exist in SFDC, please insert an existing SFX number.'; 
                                                                    lst_APIResponses.add(cls_APIResponse); 
                                                                }
                                                            }else{
                                                                // 603: SFX Number can not be blank, please insert an existing SFX number.
                                                                cls_APIResponse.SF_InvoiceId = null; 
                                                                cls_APIResponse.SF_CreditNoteId = null; 
                                                                cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                                cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                                cls_APIResponse.StatusCode = '603';
                                                                cls_APIResponse.StatusMessage = 'SFX Number can not be blank, please insert an existing SFX number.'; 
                                                                lst_APIResponses.add(cls_APIResponse); 
                                                            }
                                                            
                                                        }else if(eachInvoice.Billing_Level.equalsIgnoreCase('Rate Card'))
                                                        {
                                                            if(String.isNotBlank(eachInvoice.Rate_Card_Number)){
                                                                
                                                                if(! map_AccountIds.isEmpty()  && map_AccountIds.keySet().contains(eachInvoice.Rate_Card_Number))
                                                                {
                                                                    //Invoke insertInvoiceOrDebitNote method. 
                                                                    String AccountId = map_AccountIds.get(eachInvoice.Rate_Card_Number);
                                                                    lst_InvoiceToUpsert.add(createInvoiceOrDebitNote( eachInvoice, map_PropelIBranchIds,  null, AccountId)) ;
                                                                    /*lst_InvoiceToUpsert.add(PropelIInvoiceUpsert.insertInvoiceOrDebitNote(eachInvoice.MSA_Number, eachInvoice.Customer_Contract_Code, eachInvoice.Rate_Card_Number ,eachInvoice.Bill_Number,eachInvoice.Propel_ID,eachInvoice.Description,eachInvoice.Customer_Contract_ID, eachInvoice.Customer_Contract_Code,
                                                                                                                                          eachInvoice.Charged_Freight_Amount, eachInvoice.Charged_ST_Amount, eachInvoice.Charged_Total_Amount, eachInvoice.Out_Oct_Amount, eachInvoice.Out_Total_Amount, eachInvoice.Status_LID, eachInvoice.Bill_Type_Flag,
                                                                                                                                          eachInvoice.Bill_From_Date, eachInvoice.Bill_To_Date, eachInvoice.Bill_Due_Date, eachInvoice.Bill_Date, 
                                                                                                                                          map_AccountIds.get(eachInvoice.Rate_Card_Number), 
                                                                                                                                          map_PropelIBranchIds.get(eachInvoice.Bill_Branch_ID), 
                                                                                                                                          map_PropelIBranchIds.get(eachInvoice.Collection_Branch_ID),  
                                                                                                                                          map_PropelIBranchIds.get(eachInvoice.Sub_Branch_Master_ID), 
                                                                                                                                          null, 
                                                                                                                                          eachInvoice.Submission_Date, 
                                                                                                                                          eachInvoice.Billing_Level));*/
                                                                }else{
                                                                    
                                                                    //607: Rate Card does not exist. 
                                                                    cls_APIResponse.SF_InvoiceId = null; 
                                                                    cls_APIResponse.SF_CreditNoteId = null; 
                                                                    cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                                    cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                                    cls_APIResponse.StatusCode = '606';
                                                                    cls_APIResponse.StatusMessage = 'Rate Card number does not exist in SFDC, please insert an existing rate card number.'; 
                                                                    lst_APIResponses.add(cls_APIResponse); 
                                                                }
                                                            }else{
                                                                //607: Rate Card does not exist. 
                                                                cls_APIResponse.SF_InvoiceId = null; 
                                                                cls_APIResponse.SF_CreditNoteId = null; 
                                                                cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                                cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                                cls_APIResponse.StatusCode = '605';
                                                                cls_APIResponse.StatusMessage = 'Rate Card number can not be blank, please insert an existing rate card number.'; 
                                                                lst_APIResponses.add(cls_APIResponse); 
                                                            }   
                                                        }    
                                                        
                                                    }else{
                                                        //601: MSA can not be blank. 
                                                        cls_APIResponse.SF_InvoiceId = null; 
                                                        cls_APIResponse.SF_CreditNoteId = null; 
                                                        cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                        cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                        cls_APIResponse.StatusCode = '601';
                                                        cls_APIResponse.StatusMessage = 'MSA number can not be blank, please insert a MSA number.';
                                                        lst_APIResponses.add(cls_APIResponse);
                                                    }
                                                    
                                                }else{
                                                    //608: Billing level can be blank if invoice is sent.
                                                    cls_APIResponse.SF_InvoiceId = null; 
                                                    cls_APIResponse.SF_CreditNoteId = null; 
                                                    cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                    cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                    cls_APIResponse.StatusCode = '608';
                                                    cls_APIResponse.StatusMessage = 'Billing level can not be blank, please insert the billing level.';
                                                    lst_APIResponses.add(cls_APIResponse);
                                                }
                                                
                                            }else{
                                                
                                                //600: Bill_number can not be blank. 
                                                cls_APIResponse.SF_InvoiceId = null; 
                                                cls_APIResponse.SF_CreditNoteId = null; 
                                                cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                                cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                                cls_APIResponse.StatusCode = '600';
                                                cls_APIResponse.StatusMessage = 'Bill number can not be blank, please insert a bill number.';
                                                lst_APIResponses.add(cls_APIResponse);
                                            }
                                        }
                                    }else{
                                        
                                        //613: Submission Branch does not exist, please insert a valid submission branch 
                                        cls_APIResponse.SF_InvoiceId = null; 
                                        cls_APIResponse.SF_CreditNoteId = null; 
                                        cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                        cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                        cls_APIResponse.StatusCode = '616';
                                        cls_APIResponse.StatusMessage = 'Submission Branch does not exist, please insert a valid submission branch.'; 
                                        lst_APIResponses.add(cls_APIResponse);
                                        
                                    }
                                }else{
                                    //613: Submission Branch does not exist, please insert a valid submission branch 
                                    cls_APIResponse.SF_InvoiceId = null; 
                                    cls_APIResponse.SF_CreditNoteId = null; 
                                    cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                    cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                    cls_APIResponse.StatusCode = '615';
                                    cls_APIResponse.StatusMessage = 'Submission Branch can not be blank, please insert a valid submission branch.'; 
                                    lst_APIResponses.add(cls_APIResponse);
                                }
                            }else{
                                
                                //612: Collection Branch does not exist, please insert a valid collection branch. 
                                cls_APIResponse.SF_InvoiceId = null; 
                                cls_APIResponse.SF_CreditNoteId = null; 
                                cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                                cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                                cls_APIResponse.StatusCode = '614';
                                cls_APIResponse.StatusMessage = 'Collection Branch does not exist, please insert a valid collection branch.'; 
                                lst_APIResponses.add(cls_APIResponse);
                                
                            }
                        }else{
                            //612: Collection Branch does can not be blank, please insert a collection branch code. 
                            cls_APIResponse.SF_InvoiceId = null; 
                            cls_APIResponse.SF_CreditNoteId = null;
                            cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                            cls_APIResponse.MSA_Number = eachInvoice.MSA_Number;  
                            cls_APIResponse.StatusCode = '613';
                            cls_APIResponse.StatusMessage = 'Collection Branch can not be blank, please insert a valid collection branch.'; 
                            lst_APIResponses.add(cls_APIResponse);
                            
                        }
                    }else{
                        // Billing Branch does not exists. 
                        //611: Billing Branch does not exist, please insert a valid billing branch code. 
                        cls_APIResponse.SF_InvoiceId = null; 
                        cls_APIResponse.SF_CreditNoteId = null; 
                        cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                        cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                        cls_APIResponse.StatusCode = '612';
                        cls_APIResponse.StatusMessage = 'Billing Branch does not exist, please insert a valid billing branch code.'; 
                        lst_APIResponses.add(cls_APIResponse);
                    }
                    
                }else{
                    //611: Billing Branch does not exist, please insert a valid billing branch code. 
                    cls_APIResponse.SF_InvoiceId = null; 
                    cls_APIResponse.SF_CreditNoteId = null; 
                    cls_APIResponse.Bill_Number = eachInvoice.Bill_Number;
                    cls_APIResponse.MSA_Number = eachInvoice.MSA_Number; 
                    cls_APIResponse.StatusCode = '611';
                    cls_APIResponse.StatusMessage = 'Billing Branch can not be blank, please insert a valid billing branch code.'; 
                    lst_APIResponses.add(cls_APIResponse);
                    
                }
            }
            System.debug('lst_InvoiceToUpsert------->'+lst_InvoiceToUpsert);
            if(!lst_InvoiceToUpsert.isEmpty())
            {
                try{
                    // upsert the Invoice records.   
                    Database.UpsertResult[] results = Database.upsert(lst_InvoiceToUpsert, Invoice__c.Fields.Composite_Key__c, false);
                    List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
                    for(Integer index = 0, size = results.size(); index < size; index++) {
                        // Each API request response. 
                        APIResponse cls_APIResponse = new APIResponse();
                        List<Database.Error> Errors = results[index].getErrors();
                        if(Errors != null && Errors.size() > 0)
                        {
                            for(Database.Error eachError : Errors)
                            {
                                cls_APIResponse.StatusCode = '618';
                                cls_APIResponse.StatusMessage = eachError.getMessage();
                                cls_APIResponse.MSA_Number =String.valueOf(lst_InvoiceToUpsert[index].MSA__c);
                                cls_APIResponse.Bill_Number = lst_InvoiceToUpsert[index].Bill_Number__c;
                                cls_APIResponse.isCreated = results[index].isCreated();
                                cls_APIResponse.isSuccess = results[index].isSuccess();
                                cls_APIResponse.SF_CreatedDate = lst_InvoiceToUpsert[index].CreatedDate;
                                cls_APIResponse.SF_LastModifiedDate = lst_InvoiceToUpsert[index].LastModifiedDate;
                                lst_APIResponses.add(cls_APIResponse);
                            }
                            
                        }else{
                            
                            cls_APIResponse.StatusCode = '200';
                            cls_APIResponse.SF_InvoiceId = results[index].getId();
                            cls_APIResponse.MSA_Number =String.valueOf(lst_InvoiceToUpsert[index].MSA__c);
                            cls_APIResponse.Bill_Number = lst_InvoiceToUpsert[index].Bill_Number__c;
                            cls_APIResponse.isCreated = results[index].isCreated();
                            if(cls_APIResponse.isCreated)
                                cls_APIResponse.StatusMessage = 'The invoice record has been created into the SFDC successfully.';
                            else
                                cls_APIResponse.StatusMessage = 'The invoice record has been updated into the SFDC successfully.';     
                            cls_APIResponse.isSuccess = results[index].isSuccess();
                            cls_APIResponse.SF_CreatedDate = lst_InvoiceToUpsert[index].CreatedDate;
                            cls_APIResponse.SF_LastModifiedDate = lst_InvoiceToUpsert[index].LastModifiedDate;
                            lst_APIResponses.add(cls_APIResponse);
                        }
                        
                    }
                    
                }Catch(Exception objExcep)
                {
                    System.debug('There is an internal error, please reach out to SFDC Admin team:'+objExcep.getTypeName()+'::'+objExcep.getMessage()+':'+objExcep.getStackTraceString());
                    // Create an entry in exception handling table. 
                    ExceptionHandling.Exception( 'Invoice', 'PropelIInvoiceUpsert', objExcep);  
                }
            }
        }
        
        // Return the API response. 
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lst_APIResponses));
    }
    
    public static Invoice__c createInvoiceOrDebitNote(PropelIInvoiceUpsert.jsonWrap eachInvoice, Map<Decimal, String> map_PropelIBranchIds, String Parent_Bill_Number, String accountId){
        
        Invoice__c newInvoice = new Invoice__c();
        newInvoice.Propel_ID__c = eachInvoice.Propel_ID;
        newInvoice.Name =  eachInvoice.Bill_Number;
        newInvoice.Bill_Number__c = eachInvoice.Bill_Number;
        newInvoice.Description__c = eachInvoice.Description;
        newInvoice.Customer_Contract_ID__c = eachInvoice.Customer_Contract_ID;
        newInvoice.Customer_Contract_Code__c = eachInvoice.Customer_Contract_Code;
        newInvoice.Charged_Freight_Amount__c = eachInvoice.Charged_Freight_Amount;
        newInvoice.Charged_ST_Amount__c = eachInvoice.Charged_ST_Amount;
        newInvoice.Charged_Total_Amount__c = eachInvoice.Charged_Total_Amount;
        newInvoice.Out_Oct_Amount__c = eachInvoice.Out_Oct_Amount;
        newInvoice.Out_Total_Amount__c = eachInvoice.Out_Total_Amount;
        newInvoice.Status_LID__c = eachInvoice.Status_LID;                                    
        newInvoice.Bill_Type_Flag__c = eachInvoice.Bill_Type_Flag;
        newInvoice.Bill_From_Date__c = eachInvoice.Bill_From_Date;
        newInvoice.Bill_To_Date__c = eachInvoice.Bill_To_Date;
        newInvoice.Bill_Due_Date__c = eachInvoice.Bill_Due_Date;
        newInvoice.Bill_Date__c = eachInvoice.Bill_Date;
        newInvoice.MSA__c = eachInvoice.MSA_Number;
        newInvoice.SFX_Code__c = eachInvoice.SFX_Number;
        newInvoice.Rate_Card_Number__c = eachInvoice.Rate_Card_Number;
        newInvoice.Submission_Date__c = eachInvoice.Submission_Date;
        newInvoice.Billing_Level__c = eachInvoice.Billing_Level;
        newInvoice.Is_PropelI__c = true;        
        newInvoice.Bill_Creation_Date__c = eachInvoice.Bill_Creation_Date;
        newInvoice.Bill_Last_Update_Date__c = eachInvoice.Bill_Last_Update_Date;
        newInvoice.e_Bill__c = String.isBlank(eachInvoice.e_Bill) ? 'No' : eachInvoice.e_Bill;
        newInvoice.Remarks__c = eachInvoice.Submitted_to_Email_IDs;
        newInvoice.BDM_Email_IDs__c = eachInvoice.BDM_Email_IDs;
        
        
        // Map Parent invoice number on opened debit note. 
        if(String.isNotBlank(Parent_Bill_Number))
            newInvoice.Parent_Invoice__c = Parent_Bill_Number;
        // Associate Invoice with the account MSA, SFX and Rate Card. 
        if(String.isNotBlank(accountId))
            newInvoice.Account__c = accountId;
        // Assign the billing branch.
        newInvoice.Bill_Branch__c = map_PropelIBranchIds.get(eachInvoice.Bill_Branch_ID);
        // Assign the collection branch.
        newInvoice.Collection_Branch__c = map_PropelIBranchIds.get(eachInvoice.Collection_Branch_ID);
        //Assign the submission branch. 
        newInvoice.Sub_Branch_Master__c = map_PropelIBranchIds.get(eachInvoice.Sub_Branch_Master_ID);
        
        // Add the composite key. 
        newInvoice.Composite_Key__c  = eachInvoice.MSA_Number + ':'+ eachInvoice.Bill_Number;
                 
        return newInvoice;
        
    }
    
    // Method to insert the invoice or debit note. 
    /*Global static Invoice__c insertInvoiceOrDebitNote(String MSA_Number,
                                                      String SFX_Number, 
                                                      String Rate_Card_Number, 
                                                      String Bill_Number,
                                                      Integer Propel_ID, 
                                                      String Description,
                                                      Integer Customer_Contract_ID, 
                                                      String Customer_Contract_Code,
                                                      Decimal Charged_Freight_Amount, 
                                                      Decimal Charged_ST_Amount, 
                                                      Decimal Charged_Total_Amount, 
                                                      Decimal Out_Oct_Amount, 
                                                      Decimal Out_Total_Amount, 
                                                      Integer Status_LID, 
                                                      String Bill_Type_Flag,
                                                      Date Bill_From_Date, 
                                                      Date Bill_To_Date, 
                                                      Date Bill_Due_Date,
                                                      Date Bill_Date, 
                                                      Id accountId, 
                                                      Id Bill_Branch_ID, 
                                                      Id Collection_Branch_ID, 
                                                      Id Sub_Branch_Master_ID, 
                                                      Id Parent_InvoiceNumber, 
                                                      Date Submission_Date, 
                                                      String Billing_Level) 
    {
        Invoice__c newInvoice = new Invoice__c();
        newInvoice.Propel_ID__c = Propel_ID;
        newInvoice.Name =  Bill_Number;
        newInvoice.Bill_Number__c = Bill_Number;
        newInvoice.Description__c = Description;
        newInvoice.Customer_Contract_ID__c = Customer_Contract_ID;
        newInvoice.Customer_Contract_Code__c = Customer_Contract_Code;
        newInvoice.Charged_Freight_Amount__c = Charged_Freight_Amount;
        newInvoice.Charged_ST_Amount__c = Charged_ST_Amount;
        newInvoice.Charged_Total_Amount__c = Charged_Total_Amount;
        newInvoice.Out_Oct_Amount__c = Out_Oct_Amount;
        newInvoice.Out_Total_Amount__c = Out_Total_Amount;
        newInvoice.Status_LID__c = Status_LID;                                    
        newInvoice.Bill_Type_Flag__c = Bill_Type_Flag;
        newInvoice.Bill_From_Date__c = Bill_From_Date;
        newInvoice.Bill_To_Date__c = Bill_To_Date;
        newInvoice.Bill_Due_Date__c = Bill_Due_Date;
        newInvoice.Bill_Date__c = Bill_Date;
        newInvoice.MSA__c = MSA_Number;
        newInvoice.SFX_Code__c = SFX_Number;
        newInvoice.Rate_Card_Number__c = Rate_Card_Number;
        newInvoice.Submission_Date__c = Submission_Date;
        newInvoice.Billing_Level__c = Billing_Level;
        newInvoice.Is_PropelI__c = true;
        
        // Map Parent invoice number on opened debit note. 
        if(String.isNotBlank(Parent_InvoiceNumber))
            newInvoice.Parent_Invoice__c = Parent_InvoiceNumber;
        // Associate Invoice with the account MSA, SFX and Rate Card. 
        if(String.isNotBlank(accountId))
            newInvoice.Account__c = accountId;
        // Assign the billing branch.
        newInvoice.Bill_Branch__c = Bill_Branch_ID;
        // Assign the collection branch.
        newInvoice.Collection_Branch__c = Collection_Branch_ID;
        //Assign the submission branch. 
        newInvoice.Sub_Branch_Master__c = Sub_Branch_Master_ID;
        
        // Add the composite key. 
        newInvoice.Composite_Key__c  = MSA_Number + ':'+Bill_Number;
        return newInvoice;
    }*/
	// end of insertInvoiceOrDebitNote()
    
}