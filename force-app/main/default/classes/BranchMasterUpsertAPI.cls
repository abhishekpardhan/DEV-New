/**
 * Description      :   Rest resource to make the third able to insert the records of Branch Master within Salesforce
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
@RestResource(urlMapping='/BranchMasterUpsert/*')
global with sharing class BranchMasterUpsertAPI {
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        Decimal Branch_ID;
        Boolean isCreated;
        Boolean isSuccess;
    }
    
    //Wrapper class
    global class jsonWrap {
        public String Branch_Name;
        public Integer Branch_ID;
        public String Branch_Code;
        public String Branch_Type;
        public Date Effective_Date;
        public Date Expiry_Date;
        public String Address1;
        public String Address2;
        public String Address3;
        public String Address4;
        public String State;
        public String District;
        public String City;
        public String Country;
        public String ZIP_Code;
        public Integer Zone_Id;
        public String Zone;
        public Integer Area_Id;
        public String Area;
        public Integer Region_Id;
        public String Region;
    }
    
    //Post method to create the Branch Master records from post request body
    @HttpPost
    global static void createBranch(List<BranchMasterUpsertAPI.jsonWrap> brnchRecords) {
            Branch_Master__c[] branches = new Branch_Master__c[]{};
            for(BranchMasterUpsertAPI.jsonWrap i : brnchRecords) {
                branches.add(new Branch_Master__c(Name = i.Branch_Name, 
                                     Branch_ID__c  = i.Branch_ID,
                                     Branch_Code__c = i.Branch_Code,
                                     Branch_Type__c = i.Branch_Type,
                                     Effective_Date__c  = i.Effective_Date,
                                     Expiry_Date__c = i.Expiry_Date,
                                     Address1__c = i.Address1,
                                     Address2__c = i.Address2,
                                     Address3__c = i.Address3,
                                     Address4__c = i.Address4,
                                     State__c = i.State,
                                     District__c = i.District,
                                     City__c = i.City,
                                     Country__c = i.Country,
                                     ZIP_Code__c = i.ZIP_Code,
                                     Zone_Id__c = i.Zone_Id,
                                     Zone__c = i.Zone,
                                     Area_Id__c = i.Area_Id,
                                     Area__c = i.Area,
                                     Region_Id__c = i.Region_Id,
                                     Region__c = i.Region));
                                     
            }
        Database.UpsertResult[] results = Database.upsert(branches, Branch_Master__c.Branch_ID__c, false);
 
        List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
        for(Integer index = 0, size = results.size(); index < size; index++) {
            JsonUpsertResult resultRow = new JsonUpsertResult();
            resultRow.Errors =  results[index].getErrors();
            resultRow.SFId = results[index].getId();
            resultRow.Branch_ID = branches[index].Branch_ID__c;
            resultRow.isCreated = results[index].isCreated();
            resultRow.isSuccess = results[index].isSuccess();
            lstJsonUpsertResult.add(resultRow);
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
    }
}