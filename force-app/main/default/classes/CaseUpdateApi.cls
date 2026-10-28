/**
 * Description		:		Rest resource to update the Case__c records (Proton_Token_No__c) within salesforce from third party system 
 * Created By       :       Shubham Girdhar
 * Created Date     :       
 * Release          :       18th August, 2019
 * Last Modified on :       8th August, 2019
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
@RestResource(urlMapping='/CasesUpdate/*')
global with sharing class CaseUpdateApi{
    
    //Wrapper class
    private class JsonUpdateResult {
        List<Database.Error> Errors;
        String SFId;
        String Token_No;        
        Boolean isSuccess;
    }
    
    //Wrapper class to contain JSON tokens
    global class jsonWrap {
        public String Token_No;
        public String Proton_Remarks;
        public String Status;
        public Id Case_Id;
    }
    
    /**
     * POST method update the cases withing SFDC whenver third party hit the SFDC endpoint
     **/
    @HttpPost
    global static void updateOperationalCase(List<CaseUpdateApi.jsonWrap> caseRecords){        
     try{

    List<Case__c> lstCase = new List<Case__c>();
        map<Id,String> mapCaseIdTokenNo = new map<Id,String>();
        for(CaseUpdateApi.jsonWrap  cs : caseRecords){
            if(cs.Case_Id != null){
                case__c updateCase = new case__c(id = cs.Case_Id,
                                                 Proton_Remarks__c = cs.Proton_Remarks,
                                                 Status__c = cs.Status,
                                                 Proton_Token_No__c = cs.Token_No);
                lstCase.add(updateCase);
                mapCaseIdTokenNo.put(cs.Case_Id,cs.Token_No);
            }
        }
        Database.SaveResult[] results = Database.update(lstCase);        
        List<JsonUpdateResult> lstJsonUpdateResult = new List<JsonUpdateResult>();
        for(Integer index = 0, size = results.size(); index < size; index++) {
            JsonUpdateResult resultRow = new JsonUpdateResult();
            resultRow.Errors =  results[index].getErrors();
            resultRow.SFId = results[index].getId();                    
            resultRow.isSuccess = results[index].isSuccess();
            resultRow.Token_No = mapCaseIdTokenNo.get(results[index].getId());
            lstJsonUpdateResult.add(resultRow);
        }        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpdateResult));
    } catch(Exception e){ // Added by shubham Girdhar reffering jira ticket: SD-417
        String name = 'Case';
            String ClassName = 'CaseUpdateApi';
            ExceptionHandling.Exception( name, ClassName, e);            
    }
    }
}