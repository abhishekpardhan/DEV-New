/**
* Description      :   Helper class for Case__c Object Trigger to perform multiple operations like Restricting the user to update only certain fields if case is approved etc.
* Release          :   17th july, 2019, 15 Nov, 2019
* JIRA Ticket      :   https://safexpress.atlassian.net/browse/SD-357, SD-490
* Coverage         :   90%
* Revision Logs    :   V_1.0 - Created
**/
public class caseTriggerHelper {
    public static Boolean skipAssignmentUpdate = false;
    public static Boolean skipEventPublishing = false;
    //Method to update the Assign to Field on the Case Object
    public static void newCaseModification(List<case__c> lstCase){
        //map<Id,Id> mapAccountIdBDM = new map<Id,Id>();
        //map<Id,Id> mapSFXAccIdBDM = new map<Id,Id>();
        System.debug('newCaseModification');
        try{
            /*Id rIdSFX = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
            Id rIdPRC = Schema.SObjectType.Account.getRecordTypeInfosByName().get('PRC Customer').getRecordTypeId();
            //Id rIdSFXPropeli = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
            
            for(account acc : [select id,name,(select id,bdm__c,national1__c from Account_Teams__r where national1__c = true limit 1) from account where
                               Id IN: lstAccountId and recordtypeid =: rIdSFX]){
                                   if(acc.Account_Teams__r.size() > 0){
                                       mapAccountIdBDM.put(acc.Id,acc.Account_Teams__r[0].bdm__c);
                                   }
                               }
            
            Id RetailHeadCorpRoleId = [select id,name from userrole where name='Retail Head Corporate' limit 1].Id;
            User retailUser = [select id,name from user where userroleId =:RetailHeadCorpRoleId limit 1];
            for(account acc : [select id,name from account where Id IN: lstAccountId and recordtypeid =: rIdPRC]){
                if(retailUser != null){
                    mapAccountIdBDM.put(acc.Id,retailUser.Id);
                }
            }     */       
 			List<CCD_assigned_Matrix__mdt> ccdList = [SELECT Id, Case_Type__c, Sub_Type__c, FederationIdentifier__c FROM CCD_assigned_Matrix__mdt ORDER By Type_Order__c ASC, Sub_Type__c ASC];
            Set<String> federationIdSet = new Set<String>();
            for(CCD_assigned_Matrix__mdt ccd : ccdList){
                federationIdSet.add(ccd.FederationIdentifier__c);
            }
            // // System.debug('federationIdSet-->'+federationIdSet);
            Map<String, String> fedIdToUserIdMap = getFederationUserMap(federationIdSet);
            // // System.debug('fedIdToUserIdMap-->'+fedIdToUserIdMap);
            for(Case__c cs : lstCase){
                if(cs.Approval_Status__c == 'Approved by AM' || cs.Approval_Status__c == 'Approved by Claim Dept' || cs.Approval_Status__c=='Auto-approved'){
                    String assignedTo = getCCDUserId(cs, ccdList, fedIdToUserIdMap);
                    // // System.debug('assignedTo-->'+assignedTo);
                    if(assignedTo != null){
                        cs.Assigned_To__c = assignedTo;
                    }
                }
            }
            
        }catch(Exception e){
            System.debug('Exception:'+e.getMessage());
        }
    }

    public static void  addClaimUnderstanding(List<case__c> lstcase){
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        for(Case__c cs : lstcase){
            if(cs.Account__c != null){
                accountIds.add(cs.Account__c);
            }
        }
        for(Account acc : [Select Id, RecordType.DeveloperName, Contract__r.Claim_Understanding__c FROM Account WHERE Id IN : accountIds]){
            accountMap.put(acc.Id, acc);
        }
        for(Case__c cs : lstcase){
            if(accountMap.containsKey(cs.Account__c)){
                Account acc = accountMap.get(cs.Account__c);
                if(acc.RecordType.DeveloperName == 'Actual_SFX') {
                    cs.Claim_Understanding__c = acc.Contract__r.Claim_Understanding__c;
                } else {
                    cs.Claim_Understanding__c = 'NA';
                }
            }
        }
    }

    public static void assignClaimCases(List<Case__c> lstCase){

        Map<Id,Case__c> caseMap = new Map<Id, Case__c>([SELECT Id, Assigned_To__c, Account__r.RecordType.DeveloperName FROM Case__c WHERE Id IN : lstCase]);
        for(Case__c cs : lstCase){
            if(caseMap.containsKey(cs.Id)){
                Case__c caseRecord = caseMap.get(cs.Id);
                if(caseRecord.Account__r.RecordType.DeveloperName == 'Actual_SFX') {
                    cs.Assigned_To__c = Label.CREDIT_RTGS_NEFT;
                } else {
                    cs.Assigned_To__c = Label.RETAIL_RTGS_NEFT;
                }
            }
        }

    }
    
    
    public static String getCCDUserId(Case__c cas, List<CCD_assigned_Matrix__mdt> ccdList, Map<String, String> fedIdToUserIdMap){
        String response;
        // // System.debug('ccdList-->'+ccdList);
        for(CCD_assigned_Matrix__mdt ccd: ccdList){
             
            if(ccd.Case_Type__c == cas.Case_Typee__c && cas.Case_Type__c != null && cas.Case_Type__c.contains(ccd.Sub_Type__c)){
                String fedId = ccd.FederationIdentifier__c;
                if(fedIdToUserIdMap.containsKey(ccd.FederationIdentifier__c)){
                    response = fedIdToUserIdMap.get(ccd.FederationIdentifier__c);
                    break;
                }                
            }
        }
        return response;
    }
    
    public static void updateRemarks(List<Case__c> ReCase){
        try{
            Id currentUser = UserInfo.getUserId();
            datetime dt = system.now();
            datetime dt2 = dt.addHours(5);
            datetime dt3 = dt2.addMinutes(30);
            Map<Id,User> mapUserIdName = new Map<Id,User>([select Id,name from user]);
            List<Case__c> lstCase = new List<Case__c>();
            for(Case__c cs : ReCase){
                if(cs.Customer_Remarks__c != null) {
                    if(String.isBlank(cs.Remarks_History__c)){
                        cs.Remarks_History__c = mapUserIdName.get(currentUser).Name +' '+ dt3 + ':' +cs.Customer_Remarks__c;  //cs.LastModifiedDate
                    }   
                    else{
                        cs.Remarks_History__c += '\r\n' + mapUserIdName.get(currentUser).Name +' '+ dt3 + ':' +cs.Customer_Remarks__c;
                    }
                    Integer len = cs.Customer_Remarks__c.length();
                    if(len <25){
                        cs.AddError('Please enter atleast 25 characters');
                    }
                    cs.Customer_Remarks__c = '';
                    lstCase.add(cs);
                }
            }
            Update lstCase;
        }catch(Exception e){
          System.debug('Exception:'+e.getMessage());
        }
    }
    
    //This method will update 'Assigned To'  to   'National4' when status is 'Approved by am' by Renu
    /*Commented by Monika on 14-11-2019 public static void updateAssignedTo(List<case__c> lstCase,Set<Id> lstAccountId){
map<Id,Id> mapAccountIdBDM = new map<Id,Id>();
try{      
for(account acc : [select id,name,(select id,bdm__c,National4__c from Account_Teams__r where National4__c = true limit 1) from account where Id IN: lstAccountId]){
if(acc.Account_Teams__r.size() > 0){
mapAccountIdBDM.put(acc.Id,acc.Account_Teams__r[0].bdm__c);
}
}
for(case__c cs : lstCase){
cs.Assigned_To__c = mapAccountIdBDM.get(cs.Account__c);
}

}catch(Exception e){
// // System.debug('Exception:'+e.getMessage());
}
}Monika*/
    //this method is to update the status active if waybil details record is created.
    /*Monika public static void changeStatusActive(List<case__c> lstCase){
Map<Id,Id> mapWaybilToCase  = new Map<Id,Id>();
for(Waybill_Details__c objway : [select id,Case__c from Waybill_Details__c where Case__c IN : lstCase]){
mapWaybilToCase.put(objway.case__c ,objway.id);
}
if(mapWaybilToCase.size() > 0){
for(case__c objCase : lstCase){
if(mapWaybilToCase.get(objCase.id) != null){
objCase.Status__c = 'Active';
}
}
}
}Monika*/
    
    
    //=============Added on 5/2/2019
    //Description   :   Method to make the user able to edit only certain fields if record is approved for Revenue Management Cases
  /* public static void preventRecordEditing(List<Case__c> newCases, Map<Id,Case__c> mapOldCases) {
        
       
        Schema.DescribeSObjectResult r = Case__c.sObjectType.getDescribe();
        Set <String> apiNames =  new Set<String>();
        for(string apiName : r.fields.getMap().keySet()){
            apiNames.add(apiName);
        }
        
       
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Case__c.getRecordTypeInfosById();
        
       
        for(Case__c cse :  newCases) {
            
           
            if(cse.Approval_Status__c != Null && !(cse.Case_Type__c != null && (cse.Case_Type__c?.contains('Late Delivery') || cse.Case_Type__c?.contains('Weight difference')) && cse.Task_Amount__c > 50000) && (cse.Approval_Status__c == 'Approved By AM' || cse.Approval_Status__c == 'Approved by Claim Dept') &&  mapOldCases != Null && mapOldCases.containsKey(cse.Id)) { //Monika
                
               
                if(cse.RecordTypeId != Null && rtMapById.containsKey(cse.RecordTypeId) && (rtMapById.get(cse.RecordTypeId).getDeveloperName() == 'Credit_Debit_Note')) {
                    
                    String revenueCasesId = rtMapById.get(cse.RecordTypeId).getDeveloperName() == 'Credit_Debit_Note' ? String.valueOf(cse.RecordTypeId) : '';
                    for(String fieldAPIName : apiNames) {
                        
                        
                        if(fieldAPIName == 'Approval_Status__c' ||fieldAPIName == 'Assigned_To__c' || fieldAPIName == 'Status__c' || fieldAPIName == 'Assigned_To__c' || fieldAPIName == 'Remarks__c' || fieldAPIName == 'lastreferenceddate' || fieldAPIName == 'lastvieweddate' || fieldAPIName =='lastactivitydate'
                           || fieldAPIName == 'lastmodifiedbyid' || fieldAPIName == 'lastmodifieddate' || fieldAPIName == 'isdeleted'||(String.isNotBlank(revenueCasesId) && fieldAPIName == 'Credit_Debit_note_number__c')) {
                               // // System.debug('In if LIne no 171--->'+fieldAPIName);
                               continue; 
                           }
                            
                          
                        else {
                            
                            
                            if(mapOldCases.get(cse.Id).get(fieldAPIName) != cse.get(fieldAPIName)&&cse.SkipValidationWhileReAssigning__c) {
                                cse.addError('Can only update Status, Remarks and Credit/Debit note number if Case is Approved');
                            }
                        }
                    }
                } 
            }
        }
    }*/
    /* public static void assignCorporateCreditCase(List<case__c> lstCase,Set<Id> lstAccountId){
// // System.debug('lstCase'+lstCase);
// // System.debug('lstAccountId'+lstAccountId);
map<Id,Id> mapSFXAccIdBDM = new map<Id,Id>();
List<Case__c> caseList = new List<Case__c>();
Id rIdSFXPropeli = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX').getRecordTypeId();
/*for(account acc : [select id,name,(select id,BDMPropelI__c,MSA__c,national1__c from Account_Teams__r where national1__c = true limit 1) from account where
Id IN: lstAccountId and recordtypeid =: rIdSFXPropeli]){ 
// // System.debug('acc'+acc+acc.Account_Teams__r[0].MSA__c);
/*if(acc.Account_Teams__r[0].MSA__c != null){
String msaAcc = acc.Account_Teams__r[0].MSA__c;
for(account accs : [select id,name,(select id,bdm__c,MSA__c,BDMPropelI__c,national1__c from Account_Teams__r) from account where Id =: msaAcc]){
// // System.debug('accs'+accs);
mapSFXAccIdBDM.put(acc.Id,accs.Account_Teams__r[0].BDMPropelI__c);
}
}*/
    /*if(!acc.Account_Teams__r.isEmpty()){
mapSFXAccIdBDM.put(acc.Id,acc.Account_Teams__r[0].BDMPropelI__c); //0052y000001FZ38AAG
}
}*/
    /*for(case__c cs : lstCase){
// // System.debug('cs'+cs);
if(cs.Approval_Status__c == 'Approved by AM'){ //&& cs.Case_Type__c == 'Corporate Credit Case'
// // System.debug('###########'+system.label.bdmpropeli);
case__c cse = new case__c();
cse.Id = cs.Id;
cse.Assigned_To__c = system.label.bdmpropeli; 
// // System.debug('cse'+cse);
caseList.add(cse);
}
}
if(caseList.size()>0){
update caseList;
}
}*/
    
    
    public static void caseAssignmentRule(List<Case__c> caseList){
        List<Case__c> caseListToAssignWithApprover = new List<Case__c>(); 
        String profileId = UserInfo.getProfileId();
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Id =: profileId];
        String profileName = profileList[0].Name;
        List<Case_Assigned_Matrix__mdt> camList = Case_Assigned_Matrix__mdt.getAll().values(); 
        // System.debug('camList-->'+camList);
        cmdMatrixWrapper matrixObj = getCaseTypeRecords(camList);   
        //  System.debug('matrixObj-->'+matrixObj);
        Map<String, List<Case_Assigned_Matrix__mdt>> caseRecordTypeMap = matrixObj?.caseTypeList;
        //  System.debug('caseRecordTypeMap-->'+caseRecordTypeMap);
        Set<String> federationIdSet = matrixObj?.federationIdSet;
        //  System.debug('federationIdSet-->'+federationIdSet);
        Map<String, String> fedIdUserMap = new Map<String, String>();
        if(federationIdSet.size()>0){
            fedIdUserMap=getFederationUserMap(federationIdSet);
        }
        
        //  System.debug('fedIdUserMap-->'+fedIdUserMap);
        for(Case__c cas : caseList){
            //  System.debug('cas-->'+cas);
            if (fedIdUserMap.size()>0 && caseRecordTypeMap!= null && (cas.Approval_Status__c.contains('Approved') || cas.Approval_Status__c.contains('approved')) && !(( cas.RecordTypeId != null
          && Schema.SObjectType.Case__c.getRecordTypeInfosById().containsKey(cas.RecordTypeId)
          && Schema.SObjectType.Case__c.getRecordTypeInfosById().get(cas.RecordTypeId).getDeveloperName().equalsIgnoreCase('Credit_Debit_Note')
          && (
               String.valueOf(cas.Status__c).equalsIgnoreCase('Rejected')
            || String.valueOf(cas.Approval_Status__c).equalsIgnoreCase('Rejected')
            || String.valueOf(cas.Approval_Status__c).equalsIgnoreCase('Rejected by Claim Dept')
            || String.valueOf(cas.Approval_Status__c).equalsIgnoreCase('Rejected By AM')
          )
        )
        ||
        ( cas.RecordTypeId != null
          && Schema.SObjectType.Case__c.getRecordTypeInfosById().containsKey(cas.RecordTypeId)
          && Schema.SObjectType.Case__c.getRecordTypeInfosById().get(cas.RecordTypeId).getDeveloperName().equalsIgnoreCase('Corporate_Credit_Case')
          && (
               String.valueOf(cas.Status__c).equalsIgnoreCase('Rejected')
            || String.valueOf(cas.Approval_Status__c).equalsIgnoreCase('Rejected By AM')
          )
        )
        ||
        ( cas.RecordTypeId != null
          && Schema.SObjectType.Case__c.getRecordTypeInfosById().containsKey(cas.RecordTypeId)
          && Schema.SObjectType.Case__c.getRecordTypeInfosById().get(cas.RecordTypeId).getDeveloperName().equalsIgnoreCase('Customer_Portal_Access_new')
          && (
               String.valueOf(cas.Status__c).equalsIgnoreCase('Rejected')
            || String.valueOf(cas.Approval_Status__c).equalsIgnoreCase('Rejected by CO')
            || String.valueOf(cas.Approval_Status__c).equalsIgnoreCase('Rejected by Claim Dept')
            || String.valueOf(cas.Approval_Status__c).equalsIgnoreCase('Rejected By AM')
          )
        ))){
                if(String.isNotBlank(assignCaseToAssigner(cas, caseRecordTypeMap, fedIdUserMap, profileName))){
                    cas.Assigned_To__c = assignCaseToAssigner(cas, caseRecordTypeMap, fedIdUserMap, profileName); 
                    // System.debug('cas.Assigned_To__c-->'+cas.Assigned_To__c);
                }
            }
            //START SAC-1319 || Deepika Thakur || IBM
            if(Trigger.isInsert && cas.Assigned_To__c == null){
                cas.Assigned_To__c= UserInfo.getUserId();
            }
            //END SAC-1319 || Deepika Thakur || IBM
        }
        
    }
    
    public static void AssignCaseToTheApprover(List<Case__c> newList, Map<Id, Case__c> oldMap){
         System.debug('hi iam here AssignCaseToTheApprover');
        Id rCreditCase = Schema.SObjectType.Case__c.getRecordTypeInfosByName().get('Revenue Management Case').getRecordTypeId();
        for (Case__c cs : newList) {
            try {
                Case__c oldCs = oldMap.get(cs.Id);
                if (cs.RecordTypeId == rCreditCase && 
                    cs.Approval_Status__c != oldCs.Approval_Status__c) {
                          System.debug('hi iam here ');
                       
                        
                        if (cs.Approval_Status__c.contains('Pending') ||  cs.Approval_Status__c =='Approved By AM') {
                            // System.debug('cs.Approval_Status__c.contains');
                            cs.SkipValidationWhileReAssigning__c = True;
                             Database.SaveResult publishResult = EventBus.publish( new Case_Assignment_Event__e(Case_Id__c = cs.Id));
                            
                            if (publishResult.isSuccess()) {
                                 System.debug('Details updated successfully!');
                            } else {
                                 System.debug('Error publishing event!');
                            }
                            
                        } else if (cs.Approval_Status__c.contains('Approved')) {
                            cs.SkipValidationWhileReAssigning__c = false;
                           
                        }
                    }
            } catch (Exception ex) {
                 System.debug('Error in AssignCaseToTheApprover: ' + ex.getMessage());
            }
        }
    }

    
    public static String assignCaseToAssigner(Case__c cas, Map<String, List<Case_Assigned_Matrix__mdt>> caseRecordTypeMap, Map<String, String> fedIdUserMap, String profileName){
        String response = '';
        
        for(String caseType: caseRecordTypeMap.keySet()){
            //  System.debug('caseType-->'+caseType);
            // cat credit Note
            List<Case_Assigned_Matrix__mdt> caseTypeRecod = caseRecordTypeMap.get(caseType);
            //  System.debug('caseTypeRecod-->'+caseTypeRecod);
            String federationId = checkConditions(cas, caseTypeRecod, profileName);
            //  System.debug('federationId-->'+federationId);
            if(String.isNotBlank(federationId)){
                response = fedIdUserMap.containsKey(federationId) ? fedIdUserMap.get(federationId):'';
                break;
            }
        }
        return response;
    }
    
    public static String checkConditions(Case__c cas, List<Case_Assigned_Matrix__mdt> camRecords, String profileName){
        String response = ''; 
        Boolean temp = true;
        String assigner = '';
        for(Case_Assigned_Matrix__mdt cam: camRecords){  
            //  System.debug('cam-->'+cam);
            String field = cam?.Field_Name__c;
            if(field == 'Approval_Status__c' && (cas.Case_Typee__c == 'Topay Credit Note' || cas.Case_Typee__c == 'Paid Credit Note')){
                field = 'Case_Typee__c';
            }
            String values = cam?.Values__c;
            String methodName = cam?.Method_Name__c;
            assigner = cam?.Federation_Id__c;
            
            if(field == 'Profile'){
                if(values != profileName){
                    temp = false;
                    break;
                }
            }else{ 
                String caseValue = field!=null?String.valueOf(cas.get(field)):null;                
                List<String> valuesList = values!=null?values.split(','):new List<String>();
                if(valuesList.contains('isBlank')){
                    valuesList.set(valuesList.indexOf('isBlank'),'');
                }
                // // System.debug('valuesList-->'+valuesList);
                // // System.debug('caseValue-->'+caseValue);
                // // System.debug('methodName-->'+methodName);
                // // System.debug('field-->'+field);
                if(String.isBlank(methodName) && !valuesList.contains(caseValue)){
                    temp = false;
                    break;
                }
                if(methodName == 'NOT' && valuesList.contains(caseValue)){
                    temp = false;
                    break;
                }
            }
            
        }  
        if(temp == true){
            response = assigner;
        }
        
        return response;
    }
    
    public static Map<String, String> getFederationUserMap(Set<String> federationIdSet){        
        Map<String, String> response = new Map<String, String>();  
        List<Case_Assigned_Matrix__mdt> camList = Case_Assigned_Matrix__mdt.getAll().values();
        List<User> userList = [SELECT Id, FederationIdentifier FROM User WHERE FederationIdentifier IN : federationIdSet];
        for(User usr: userList){
            response.put(usr.FederationIdentifier, usr.Id);
        }
        return response;
    }
    
    public static cmdMatrixWrapper getCaseTypeRecords(List<Case_Assigned_Matrix__mdt> camList){
        Map<String, List<Case_Assigned_Matrix__mdt>> caseMatix = new Map<String, List<Case_Assigned_Matrix__mdt>>();
        Set<String> federationIdSet = new Set<String>(); 
        for(Case_Assigned_Matrix__mdt cam: camList){
            federationIdSet.add(cam.Federation_Id__c);
            if(!caseMatix.containsKey(cam.Label)){
                caseMatix.put(cam.Label, new List<Case_Assigned_Matrix__mdt>());
            }  
            caseMatix.get(cam.Label).add(cam);
        }
        cmdMatrixWrapper response = new cmdMatrixWrapper(caseMatix, federationIdSet); 
        return response;
    }
    
    public class cmdMatrixWrapper{
        public Map<String, List<Case_Assigned_Matrix__mdt>> caseTypeList;
        public Set<String> federationIdSet;
        cmdMatrixWrapper(Map<String, List<Case_Assigned_Matrix__mdt>> caseTypeList, Set<String> federationIdSet){
            this.caseTypeList = caseTypeList;
            this.federationIdSet = federationIdSet;
        }
    }
    
    private static String notificationTypeId; 
    
    public static void notifyUsers(List<case__c> caseIds) {
        
        List<Messaging.CustomNotification> notifications = new List<Messaging.CustomNotification>();
        String dynamicNotificationTypeId = getCustomNotificationTypeId();
        
        Set<Id> bdmUserIds = new Set<Id>();
        for (Case__c c : caseIds) {
            Id bdmUserId = c.CreatedById; 
            bdmUserIds.add(bdmUserId);
           
        }
        
        
        List<User> userList = [SELECT Id, Profile.Name, ManagerId , Manager.Manager.id FROM User WHERE Id IN :bdmUserIds];
        Map<String, String> caseIdToManager = new Map<String, String>();
        for (Case__c c : caseIds) { 
            for(User usr : userList){
                if(usr.ManagerId != null && usr.Manager.ManagerId != null && c.CreatedById == usr.Id){
                    caseIdToManager.put(c.Id, usr.Manager.ManagerId);
                    break;
                }
            }
        }
        
       /* Map<Id, User> RMOfbdmUsers = new Map<Id, User>([SELECT Id, Profile.Name, ManagerId , Manager.Manager.id FROM User WHERE Id IN :bdmUserIds AND Profile.Name = 'BDM']);

        Map<String, String> caseIdToManager = new Map<String, String>();
        for (Case__c c : caseIds) { 
            if(RMOfbdmUsers.containsKey(c.CreatedById) && RMOfbdmUsers.get(c.CreatedById).ManagerId != null && RMOfbdmUsers.get(c.CreatedById).Manager.Manager.Id != null){
                caseIdToManager.put(c.Id, RMOfbdmUsers.get(c.CreatedById).Manager.Manager.id);
            }             
        }   */  
        
        
       /* List<User> RMOfbdmUsers = [SELECT Id, Profile.Name, ManagerId , Manager.Manager.id FROM User WHERE Id IN :bdmUserIds AND Profile.Name = 'BDM'];

        Map<String, String> caseIdToManager = new Map<String, String>();
        for (Case__c c : caseIds) { 
            for(User rm : RMOfbdmUsers){
                if(rm.ManagerId != null && rm.Manager.Manager.id!=null){
                    if (!caseIdToManager.containsKey(c.Id)) {
                        caseIdToManager.put(c.Id, rm.Manager.Manager.id);
                    }
                }
            }
        }  */   
        
        SendCaseNotificationQueueable obj = new SendCaseNotificationQueueable(caseIdToManager, dynamicNotificationTypeId);
        System.enqueueJob(obj);
         
    }    
    
    
    
    public static String getCustomNotificationTypeId() {
        if (notificationTypeId == null) { 
            List<CustomNotificationType> notificationTypes = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Notification_to_BDM' LIMIT 1];
            
            if (!notificationTypes.isEmpty()) {
                notificationTypeId = notificationTypes[0].Id;
                //  System.debug('notificationTypeId---->'+notificationTypeId);
            } 
        }
        return notificationTypeId;
    }
    
    public static void verifyBusinessDetail(List<Case__c> lstCase){
        Map<String, String> businessDetailCaseMap = new Map<String, String>();
        List<Business_Detail__c> bdList = [SELECT Id, Case__c FROM Business_Detail__c WHERE Case__c IN : lstCase];
        for(Business_Detail__c bd : bdList){
            businessDetailCaseMap.put(bd.Case__c, bd.Id);
        }
        for(Case__c cas : lstCase){
            if(!businessDetailCaseMap.containsKey(cas.Id)){
                cas.addError('Case must have at least one business detail');
            }
        }
    }
    // By - Tarun sachdeva | IBM
    public static void checkWaybill(List<Case__c> lstCase, Map<Id,Case__c> oldRec){
        // // System.debug('Entered in Before Update');
        Id currentUserId = UserInfo.getUserId();
        Set<Id> nwCseId = new Set<Id>();
        Map<Id,Integer> mapOfWayBill = new Map<Id,Integer>();
        Id rCreditCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Revenue Management Case').getRecordTypeId();
        Id rClaimCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Claim Issues').getRecordTypeId();
        
        
        User currentUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1];
        String profileName = currentUser.Profile.Name;
        // // System.debug('profileName');
        for(Case__c c :lstCase){
            nwCseId.add(c.Id);
        }
        
        List<AggregateResult> countOfWaybill = [Select count(id) totalWaybill ,case__r.Id caseId from Waybill_Details__c where case__r.Id IN :nwCseId group by case__r.Id ];
        // // System.debug('countOfWaybill--->'+countOfWaybill);
        for(AggregateResult ar :countOfWaybill){
            
            mapOfWayBill.put((Id)ar.get('caseId'),(Integer)ar.get('totalWaybill'));
        }
        // // System.debug('mapOfWayBill--->'+mapOfWayBill);
        for(Case__c newCse : lstCase){
            
            if(mapOfWayBill.containsKey(newCse.Id) || nwCseId.contains(newCse.Id)){
                // // System.debug('Entered in IF mapOfWayBill--->'+mapOfWayBill);
                if ((newCse.Status__c != oldRec.get(newCse.Id).Status__c) &&
                    (newCse.RecordTypeId == rCreditCase ||newCse.RecordTypeId == rClaimCase) &&
                    newCse.Status__c != 'Provisional' &&
                    // mapOfWayBill.get(newCse.Id) == 0 &&
                    !new Set<String>{'Regional Finance Head', 'Revenue Management', 'System Administrator'}.contains(profileName)
                   ){
                       if(!mapOfWayBill.containsKey(newCse.Id) && nwCseId.contains(newCse.Id)){
                           // // System.debug('Error Occured');
                           newCse.addError('Status should not be changed until the waybill details are added');
                       }
                   }
//
            }
        }
    }
    
    // By - Manshi Joshi | IBM (SAC-1689)
   public static void rejectApprovalStatus(List<Case__c> newList, Map<Id, Case__c> oldMap){
        try{
            Id revenueCaseRecordTypeId = Schema.SObjectType.Case__c.getRecordTypeInfosByDeveloperName().get('Credit_Debit_Note').getRecordTypeId();
            for (Case__c cs : newList) {
                Case__c oldCase = oldMap.get(cs.Id); 
                if (oldCase.Status__c != cs.Status__c && cs.Status__c == 'Rejected' && cs.RecordTypeId == revenueCaseRecordTypeId) {
                    cs.Approval_Status__c = 'Rejected';
                }
                else if(oldCase.Status__c != cs.Status__c && cs.Status__c == 'Active' && cs.RecordTypeId == revenueCaseRecordTypeId){
                    if(userInfo.getProfileId() == [SELECT Id FROM Profile WHERE Name = 'Regional Finance Head' LIMIT 1].Id){
                        cs.Approval_Status__c = 'Auto-approved';
                    }
                    else{
                        cs.Approval_Status__c = 'Not Submitted for Approval';
                    }
                }
            }
            
        }
        catch (Exception ex) {
             System.debug('Error in rejectApprovalStatus method: ' + ex.getMessage());
            
        }
    }    
    
}