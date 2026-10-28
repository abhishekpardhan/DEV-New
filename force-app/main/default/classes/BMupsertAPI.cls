/**
* Description      :   Rest resource to make the third party able to insert the records of Branch Master within Salesforce
* Created Date    :  22-July-2020
* 
* Revision Logs    :   V_1.0 - Created
* 
**/
@RestResource(urlMapping='/BMCreate/*')
global with sharing class BMupsertAPI{
    private class JsonUpsertResult {
        List<Database.Error> Errors;
        String SFId;
        // Decimal Branch_ID;
        Boolean isCreated;
        Boolean isSuccess;
    }
    
    //Wrapper class
    global class dataWrap {  
        public List<branchListWrap> branchList;
    }
    global class branchListWrap {
        //attr3: Added on 24-Feb-2023 a flag with 0 or 1 value which shows the Branch Master synced from PropelI to Propel.
        public Integer attr3;
        public Integer id;
        public String address;
        public String bankAccNumOffline;
        public String bankAccNumOnline;
        public Integer operationalBranchId;
        public String bankAccNumGeneral;
        public String branchGstNum;
        public Integer scanFlag;
        public String branchCode;
        public String branchName;
        public String createdBy;
        public Date createdDate;
        public String cutoffTime;
        //public Time cutoffTime;
        public String descr;
        public Date effectiveDate;
        public String email;
        public Date expiryDate;
        public Integer lkpBranchRatingId;
        public String mobile;
        public Integer organisationId;
        public Integer branchTypeId;
        public String branchType; // Added by RC 
        public String reportingBranch; 
        public string stateName;
        public Integer reportingBranchId;
        public String phone;
        public Integer pincodeId;
        public Integer preBookingLagTimeFlag;
        public Integer status;
        public String updatedBy;
        public Date updatedDate;
        public List<branchFeatureWrap> branchFeature;
        public List<branchHierarchyListWrap> branchHierarchyList;
        public List<branchModeOfPaymentsWrap> branchModeOfPayments;
        public List<branchManagersWrap> branchManagers;
    }
    global class branchFeatureWrap {  
        public Integer id;
        public String branchFeature;
        public String createdBy;
        public Date createdDate;
        public Date effectiveDate;
        public Date expiryDate;
        public Integer status;
        public String updatedBy;
        public Date updatedDate;
        public Integer isSlabFlag;
        public Integer slabId;
        public Integer lkpBranchFeatureId;
    } 
    global class branchHierarchyListWrap {  
        
    } 
    global class branchModeOfPaymentsWrap {  
        public Integer id;
        public String modeOfPayment;
        public Integer status;
        public Integer focMnthWise;
        public Date effectiveDt;
        public Integer focWayblMaxCnt;
        public Date focValidUpto;
        public Integer lkpBranchMopId;
        public String createdBy;
        public Date createdDate;
        public Date effectiveDate;
        public Date expiryDate;
        public String updatedBy;
        public Date updatedDate;
    }
    global class branchManagersWrap {  
        public Integer id;
        public Integer status;
        public Integer lkpManagerTypeId;
        public String managerType;
        public Integer userId;
        public String createdBy;
        public Date createdDate;
        public Date effectiveDate;
        public Date expiryDate;
        public String updatedBy;
        public Date updatedDate;
    }  
    
    //Post method to create the Branch Master records from post request body
    @HttpPost
    global static void createBM(List<BMupsertAPI.dataWrap> data) {
        try{
            List<Branch_Master__c> lstBM = new list<Branch_Master__c>();
            Map<Branch_Master__c,Integer> mapOfNewBranch = new Map<Branch_Master__c,Integer>();
            List<Integer> lstOperationalId = new list<Integer>(); 
            for(BMupsertAPI.dataWrap eachDataWrap : data)
            {
                system.debug('Branchlist :' +eachDataWrap.BranchList);
                for(branchListWrap eachBM : eachDataWrap.BranchList){
                    Boolean isSyncedToPropel = eachBM.attr3 == 1 ? true : false;
                    Branch_Master__c newBranch = new Branch_Master__c(Name = eachBM.branchName,
                                                                      PropelI_Branch_ID__c = eachBM.id,
                                                                      Branch_Code__c = eachBM.branchCode,
                                                                      Effective_Date__c  = eachBM.effectiveDate,
                                                                      Expiry_Date__c = eachBM.expiryDate,
                                                                      Address1__c = eachBM.address,
                                                                      GST__c = eachBM.branchGstNum,
                                                                      Phone__c = eachBM.phone,
                                                                      State_Name__c = eachBM.stateName,
                                                                      Branch_Type__c = eachBM.branchType,
                                                                      Reporting_Branch__c = eachBM.reportingBranch,
                                                                      Email__c = eachBM.email,
                                                                      Is_Synced_to_Propel__c = isSyncedToPropel,
                                                                      Parent_Id__c= eachBM.operationalBranchId,
                                                                      is_PropelI_Branch__c = true
                                                                     );
                    lstBM.add(newBranch);
                    lstOperationalId.add(eachBM.operationalBranchId);
                    mapOfNewBranch.put(newBranch,eachBM.operationalBranchId);
                }
                
            }
            Map<String,String> valueOfBranches =new Map<String,String>{'TERRITORY'=>'AREA','AREA'=>'REGION'};
            String branchType = lstBM[0].Branch_Type__c ;
            String branchTypeValue = valueOfBranches.containsKey(branchType)?valueOfBranches.get(branchType):'TERRITORY';
            Map<Integer,Branch_Master__c> mapOfExistingBranch = new Map<Integer,Branch_Master__c>();
            List<Branch_Master__c> listOfBranch = new List<Branch_Master__c>();
            if(branchType != 'REGION') {
                listOfBranch = [SELECT Id,PropelI_Branch_ID__c,Branch_Type__c from Branch_Master__c where PropelI_Branch_ID__c IN :lstOperationalId];
            }
            
            if(!listOfBranch.isEmpty()){
                for(Branch_Master__c branch : listOfBranch) {
                    mapOfExistingBranch.put(Integer.valueOf(branch.PropelI_Branch_ID__c), branch);
                }

                for(Integer i=0; i<lstBM.size();i++){
                    System.debug('Count of lstBM'+i);
                    if(mapOfExistingBranch.get(mapOfNewBranch.get(lstBM[i])) == null){
						lstBM.remove(i);
                     }
                    else if(listOfBranch[0].Branch_Type__c == 'TERRITORY') {
                        lstBM[i].Territory__c = mapOfExistingBranch.get(mapOfNewBranch.get(lstBM[i])).Id;
                    }
                    else if(listOfBranch[0].Branch_Type__c == 'AREA') {
                        lstBM[i].Branch_Master_Area__c = mapOfExistingBranch.get(mapOfNewBranch.get(lstBM[i])).Id;
                    }
                    else {
                        lstBM[i].Branch_Master_Region__c = mapOfExistingBranch.get(mapOfNewBranch.get(lstBM[i])).Id;
                    }

                  }
               
                 System.debug('lstBM Rec'+lstBM.size());
                
            }
     	
            //if(!listOfBranch.isEmpty() || branchType == 'REGION') {
                Database.UpsertResult[] results = Database.upsert(lstBM, Branch_Master__c.PropelI_Branch_ID__c, false);
                system.debug('lstBM: ' +lstBM);
                system.debug('results: ' +results);
                List<JsonUpsertResult> lstJsonUpsertResult = new List<JsonUpsertResult>();
                for(Integer index = 0, size = results.size(); index < size; index++) {
                    JsonUpsertResult resultRow = new JsonUpsertResult();
                    resultRow.Errors =  results[index].getErrors();
                    resultRow.SFId = results[index].getId();
                    resultRow.isCreated = results[index].isCreated();
                    resultRow.isSuccess = results[index].isSuccess();
                    lstJsonUpsertResult.add(resultRow);
                }
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstJsonUpsertResult));
            //}
            if(Test.isRunningTest())
            {
                throw new dmlException();
            }
        }catch(Exception e){
            String name = 'BRANCH';
            String ClassName = 'BMupsertAPI';
            ExceptionHandling.Exception( name, ClassName, e);
        }
    }
}