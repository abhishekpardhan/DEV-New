/*********************************************************************************************
**Author: Safexpress.com
**Description: this is API is exposed to Propel-I system to upsert the MSA. 
**JIRA Ticket: 
**Test Class:  
**History: 
**Modified Date:                  
**Description: 
**Modified By:
*************************************************************************************************** */
public with sharing class cls_PullMSAOnDemand extends ExceptionHandling.wrap_ErrorsHandling
{
    //Wrapper class to send the response in JSON format
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String accountId;
        String oppId;
        Boolean isCreated;
        Boolean isSuccess;
    }

    public String message;	//Request Successfully completed
	public cls_data data;
	public String status;	//SUCCESS

    class cls_data {
		public MSARecord responseData;
	}

    public class MSARecord
    {
		public String Account_Name;
		public String Vertical;
		public String Sub_Vertical;
		public String Propel_MSACode;
		public String Propel_Key;
		public String Contact_Person_Name;
		public String Phone;
		public String Mobile;                           //(Not available)
		public String Email;
		public String Customer_Type;
		public String PAN;
		public String Opportunity_Name;
		public String Opportunity_Type;
		public Decimal X3PL_Potential;
		public String GST_Number;                       //(Not Available)
		public Boolean GST_Exempted;
		public String TAN_Number;                       //(Not Available)
		public Boolean TAN_Exempted;
		public String MONTHLY_POTENTIAL_AIR;
		public String MONTHLY_POTENTIAL_SURFACE;
		public Decimal Charged_wt_waybill;               //(Not Available)
		public Integer Value_of_goods_waybill;
		public String Opp_Code;
		public String BILLING_STREET;                     //(Not Available)
		public String BILLING_CITY;                     //(Not Available)
		public String BILLING_COUNTRY;                  //(Not Available)
		public String BILLING_ZIP_POSTAL_CODE;
		public String BILLING_STATE;                    //(Not Available)
		public String INSURANCE;
		public String TYPE_OF_PACKAGING;                //(Not Available)
		public String WEBSITE;                          //(Not Available)
		//public Date CREATED_DATE;
        public Date CLOSE_DATE;                         //(Not Available)
		public String CORPORATE_OFFICE_LOCATION;
        //public Decimal x3PLPotential;
		//public String Account_Id;
		//public String Opportunity;
	}

    public static void upsertMSA(String msaInfo)
    {
        cls_PullMSAOnDemand objPullMSA = (cls_PullMSAOnDemand) System.JSON.deserialize(msaInfo, cls_PullMSAOnDemand.class);
        //System.debug('---- objPullMSA: ' + objPullMSA);

        if(objPullMSA != null)
        {
            //System.debug('---- objPullMSA.data: ' + objPullMSA.data);
            //System.debug('---- objPullMSA.data.responseData: ' + objPullMSA.data.responseData);
            //System.debug('---- objPullMSA.status: ' + objPullMSA.status);

            if(objPullMSA.data != null && objPullMSA.data.responseData != null && objPullMSA.status == 'SUCCESS')
            {
                //System.debug('---- objPullMSA.data.responseData.Opp_Code: ' + objPullMSA.data.responseData.Opp_Code);
                upsertMSARecord(objPullMSA.data.responseData);
            }
            else {
                System.debug('---- API returned something wrong: ' + objPullMSA.message);
                ExceptionHandling.createAPILog('cls_PullMSAOnDemand', '', objPullMSA.message, msaInfo, null);
            }
        }
    }

    static void upsertMSARecord(cls_PullMSAOnDemand.MSARecord objMSARecord)
    {
        System.debug('objMSARecord-------------->'+objMSARecord);
        try{
            Decimal oppCode = objMSARecord.Opp_Code != null && objMSARecord.Opp_Code != '' ? Decimal.valueof(objMSARecord.Opp_Code) : null;
            Opportunity__c[] opplist = new Opportunity__c[]{};
            //for(cls_PullMSAOnDemand.MSARecord eachMSARecord : objMSARecord)
            //{
                Account newAccount = new Account(Name = objMSARecord.Account_Name, 
                                                 Region__c = 'Delhi',
                                                 Vertical__c = objMSARecord.Vertical,
                                                 Sub__c = objMSARecord.Sub_Vertical,
                                                 Propel_MSACode__c = objMSARecord.Propel_MSACode,
                                                 Propel_Key__c = objMSARecord.Propel_Key,
                                                 Contact_Person_Name__c = objMSARecord.Contact_Person_Name,
                                                 Phone = objMSARecord.Phone,
                                                 Mobile_No__c = objMSARecord.Mobile,
                                                 Email__c = objMSARecord.Email,
                                                 Type__c = objMSARecord.Customer_Type,
                                                 Pan_No__c = objMSARecord.PAN);
                Database.UpsertResult resultsacc = Database.upsert(newAccount, Account.Fields.Propel_MSACode__c, false);
                //System.debug('resultsacc----->' + resultsacc);
                //System.debug('newAccount Id------->' + newAccount.id);

                //Database.SaveResult resultsacc = Database.Insert(newAccount, false);
                integer namelen = objMSARecord.Opportunity_Name.length();
                //System.debug('--- length: ' +namelen);
                String namecut = (String) objMSARecord.Opportunity_Name.abbreviate(80);
                System.debug('--- namecut: ' + namecut);

                Opportunity__c Opp = new Opportunity__c (Name = namecut, Name__c = objMSARecord.Opportunity_Name, Customer_Type__c = objMSARecord.Opportunity_Type,
                        GST_Number__c = objMSARecord.GST_Number, Type__c = objMSARecord.Customer_Type, Gst_Exempted__c = objMSARecord.GST_Exempted,
                        TAN_No__c = objMSARecord.TAN_Number, TAN_Exempted__c = objMSARecord.TAN_Exempted, Billing_Street__c = objMSARecord.BILLING_STREET,
                        Billing_City__c = 'Others', Other_City__c = objMSARecord.BILLING_CITY, Billing_Country__c = objMSARecord.BILLING_COUNTRY,
                        Billing_Zip_Postal_Code__c = objMSARecord.BILLING_ZIP_POSTAL_CODE, Billing_State__c = objMSARecord.BILLING_STATE, 
                        Close_Date__c = objMSARecord.CLOSE_DATE, Insurance__c = objMSARecord.INSURANCE, Monthly_Potential_Air__c = 1, Monthly_Potential_Surface__c = 1,
                        X3PL_Potential__c = 1, Avg_wt_of_consignment_Kg__c = objMSARecord.Charged_wt_waybill, Value_of_Goods_Kg__c = objMSARecord.Value_of_goods_waybill,
                        Type_of_Packaging__c = objMSARecord.TYPE_OF_PACKAGING, Website__c = objMSARecord.WEBSITE,
                        Corporate_Office_Location__c = objMSARecord.CORPORATE_OFFICE_LOCATION, Account__c = newAccount.ID, Opp_Code__c = oppCode);
                opplist.add(Opp);
            //}
            System.debug('opplist-------->'+opplist);
            //the below field is inrtoduced break the recursive cycle to call MSA Push API. 
            cls_RecursiveHandler.bol_FlagToStopMSAPushAPI = true;
            
            Database.UpsertResult[] results = Database.upsert(opplist,Opportunity__c.Fields.Opp_Code__c, false);
            System.debug('results------->'+results);
            //Database.SaveResult[] results = Database.Insert(opplist, false);

            List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
            for(Integer index = 0, size = results.size(); index < size; index++)
            {
                JsonUpsertResult resultRow = new JsonUpsertResult();
                resultRow.oppId = results[index].getId();
                resultRow.accountId = opplist[index].Account__c;
                //resultRow.isCreated = results[index].isCreated();
                resultRow.isSuccess = results[index].isSuccess();
                resultRow.Errors =  results[index].getErrors();
                lstJsonUpsertResult.add(resultRow);
                System.debug('lstJsonUpsertResult------>'+lstJsonUpsertResult);
            }
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
        }
        catch(Exception e)
        {
            String name = 'MSA';
            String ClassName = 'cls_PullMSAOnDemand';
            System.debug('Exception------>' + e);
            //ExceptionHandling.Exception(name, ClassName, e);
        }
    }
}