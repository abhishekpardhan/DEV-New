@RestResource(urlMapping='/ccdBdmContactDetails/*')
global with sharing class CCDBDMContactDetails {
    
    @HttpPost
    global static UserListResponse doPost() {
        List<UserWrapper> userList = new List<UserWrapper>();
        RestRequest request = RestContext.request; //RestRequest for the Apex REST method
        String requestBody = request.requestBody != null ? request.requestBody.toString() : '';
        
        if (!String.isBlank(requestBody)) {
            RequestWrapper requestWrapper = (RequestWrapper) System.JSON.deserialize(requestBody, RequestWrapper.class);
            
            if (requestWrapper != null ) {
                
                if(requestWrapper.msa_code !=null  && requestWrapper.msa_code != ''  ){
                    if(requestWrapper.user_type.toLowerCase() != 'msa' && requestWrapper.user_type.toLowerCase() != 'rc' && requestWrapper.user_type.toLowerCase() != 'sfx'){
                        List<String> errorMessages = new List<String>();
                        errorMessages.add('User Type is not supported... Please try MSA, RC OR SFX !');
                        UserListResponse res = new UserListResponse(userList, '403', 'success', errorMessages);
                        return res;
                    }
                    
                    
                    List<Account> accList = new List<Account>();
                    
                    
                    if (requestWrapper.user_type.toLowerCase() == 'msa' || requestWrapper.user_type.toLowerCase() == 'rc' || requestWrapper.user_type.toLowerCase() == 'sfx') {
                       
                        accList = [SELECT Id,Parent.Id,Billing_Branch__c,Billing_Branch__r.Id, Billing_Branch__r.PropelI_Branch_ID__c FROM Account WHERE Parent.Parent.Parent.Parent.Propel_MSACode__c =:requestWrapper.msa_code /*OR Parent.Parent.Parent.SFX_Code__c IN:requestWrapper.sfx_code OR Parent.Name IN:requestWrapper.rc_name*/];
                       
                        if(accList.isEmpty()){
                            List<String> errorMessages = new List<String>();
                            errorMessages.add('No data available!');
                            UserListResponse res = new UserListResponse(userList, '200', 'success', errorMessages);
                            return res;
                        }
                        
                    }
                    
                    
                    
                    if(requestWrapper.user_type.toLowerCase() == 'sfx' && requestWrapper.sfx_code == null){
                        List<String> errorMessages = new List<String>();
                        errorMessages.add('For the User type SFX Please add sfx_code !');
                        UserListResponse res = new UserListResponse(userList, '200', 'success', errorMessages);
                        return res;
                    }
                    
                    if(requestWrapper.user_type.toLowerCase() == 'rc' && requestWrapper.rc_name == null){
                        List<String> errorMessages = new List<String>();
                        errorMessages.add('For the User type RC Please add rc_name !');
                        UserListResponse res = new UserListResponse(userList, '200', 'success', errorMessages);
                        return res;
                    }
                    
                    List<Branch_Master__c> lstBranches = new List<Branch_Master__c>();
                    Map<String,Id> setOfAccIdWithBookingBranch = new Map<String,Id>();
                    
                    if (requestWrapper.msa_code != null && requestWrapper.propel_i_branchid != null) {
                        lstBranches = [SELECT Id, PropelI_Branch_ID__c  FROM Branch_Master__c WHERE PropelI_Branch_ID__c IN:requestWrapper.propel_i_branchid];
                    } 
                    if (requestWrapper.propel_i_branchid != null) {
                        lstBranches = [SELECT Id, PropelI_Branch_ID__c  FROM Branch_Master__c WHERE PropelI_Branch_ID__c IN:requestWrapper.propel_i_branchid];
                    }
                    
                     if(requestWrapper.user_type.toLowerCase() == 'sfx') {
                        accList = [SELECT Id,Parent.Id,Billing_Branch__c,Billing_Branch__r.Id, Billing_Branch__r.PropelI_Branch_ID__c  FROM Account WHERE Parent.Parent.Parent.SFX_Code__c IN:requestWrapper.sfx_code];
                    }
                    else if(requestWrapper.user_type.toLowerCase() == 'rc' &&  requestWrapper.propel_i_branchid !=null ) {
                       
                        accList = [SELECT Id,Parent.Id,Parent.Name,Billing_Branch__c,Billing_Branch__r.Id ,Billing_Branch__r.PropelI_Branch_ID__c FROM Account WHERE Parent.Name IN:requestWrapper.rc_name and Billing_Branch__r.PropelI_Branch_ID__c IN :requestWrapper.propel_i_branchid ];
                    }
                    else if(requestWrapper.user_type.toLowerCase() == 'rc' ) {
                        
                        accList = [SELECT Id,Parent.Name,Parent.Id,Billing_Branch__c,Billing_Branch__r.Id ,Billing_Branch__r.PropelI_Branch_ID__c FROM Account WHERE Parent.Name IN:requestWrapper.rc_name];
                    }
                    
                    
                    Map<Id, Decimal> mapBrachIdWithPropalICode = new Map<Id, Decimal>();
                    
                    if(!lstBranches.isEmpty()){
                        for(Branch_Master__c branch : lstBranches) {
                            mapBrachIdWithPropalICode.put(branch.Id, branch.PropelI_Branch_ID__c);

                        }
                        
                    }
                    
                   
                    
                    for(Account acc : accList) {
                     
                        if(lstBranches.isEmpty() && !setOfAccIdWithBookingBranch.containsKey(String.valueOf(acc.Billing_Branch__r.PropelI_Branch_ID__c)) && requestWrapper.user_type.toLowerCase() != 'rc'){
                           
                            setOfAccIdWithBookingBranch.put(String.valueOf(String.valueOf(acc.Billing_Branch__r.PropelI_Branch_ID__c)),acc.Parent.Id); 
                        }
                        if(!lstBranches.isEmpty() && mapBrachIdWithPropalICode != null && mapBrachIdWithPropalICode.containsKey(acc.Billing_Branch__c) && !setOfAccIdWithBookingBranch.containsKey(String.valueOf(acc.Billing_Branch__r.PropelI_Branch_ID__c)) && requestWrapper.user_type.toLowerCase() != 'rc') {
                         
                            setOfAccIdWithBookingBranch.put(String.valueOf(acc.Billing_Branch__r.PropelI_Branch_ID__c),acc.Parent.Id);
                        }
                        
                        if(requestWrapper.user_type.toLowerCase() == 'rc'){
                            
                             String key = acc.Billing_Branch__r.PropelI_Branch_ID__c + acc.Parent.Name;
                            setOfAccIdWithBookingBranch.put(Key,acc.Parent.Id);
                        }
                        
                    }
                    List<Account_Team__c> accTeams = [SELECT Id,Name, BranchName__c,PropeliBranchId__c,National2__c,Relationship__c,BDMPropelI__r.name,BDMPropelI__r.email,BDMPropelI__r.mobilephone FROM Account_Team__c WHERE Account__r.Propel_MSACode__c =:requestWrapper.msa_code OR Account__c IN: setOfAccIdWithBookingBranch.values()];
                    
                    List<String> uniqueUserList = new List<String>();
                    for(Account_Team__c accTeam : accTeams) {
                        if(accTeam.National2__c == true && !uniqueUserList.contains(accTeam.BDMPropelI__r.name)) { 
                            uniqueUserList.add(accTeam.BDMPropelI__r.name);
                            userList.add(new UserWrapper(accTeam.BDMPropelI__r.name,accTeam.BDMPropelI__r.email,accTeam.BDMPropelI__r.mobilephone,accTeam.BranchName__c,'National Account Manager'));
                        }
                        if(accTeam.Relationship__c == true && requestWrapper.propel_i_branchid == null && !uniqueUserList.contains(accTeam.BDMPropelI__r.name)) {
                            uniqueUserList.add(accTeam.BDMPropelI__r.name);
                            userList.add(new UserWrapper(accTeam.BDMPropelI__r.name,accTeam.BDMPropelI__r.email,accTeam.BDMPropelI__r.mobilephone,accTeam.BranchName__c,'Local Account Manager'));
                        }
                        if(accTeam.Relationship__c == true && requestWrapper.propel_i_branchid != null && requestWrapper.propel_i_branchid.contains(accTeam.PropeliBranchId__c) && !uniqueUserList.contains(accTeam.BDMPropelI__r.name)) {  
                            uniqueUserList.add(accTeam.BDMPropelI__r.name);
                            userList.add(new UserWrapper(accTeam.BDMPropelI__r.name,accTeam.BDMPropelI__r.email,accTeam.BDMPropelI__r.mobilephone,accTeam.BranchName__c,'Local Account Manager'));
                        }

                    }
                }
                if(requestWrapper.user_type.toLowerCase() == 'msa' && requestWrapper.msa_code == null){
                        List<String> errorMessages = new List<String>();
                        errorMessages.add('For the User type MSA Please add msa_code !');
                        UserListResponse res = new UserListResponse(userList, '200', 'success', errorMessages);
                        return res;
                    }
                
            }
            else{
                 List<String> errorMessages = new List<String>();
                 errorMessages.add('Invalid or missing input parameters!');
                 UserListResponse res = new UserListResponse(userList, '200', 'success', errorMessages);
                 return res;
            }
        }
        
        List<String> errorMessages = new List<String>();
        if(userList.isEmpty()){
            errorMessages.add('No data available!');
            UserListResponse res = new UserListResponse(userList, '200', 'success', errorMessages);
            return res;
        }else{
            errorMessages.add('');
            UserListResponse res = new UserListResponse(userList, '200', 'success', errorMessages);
            return res;
        }
    }
    
    global class UserListResponse {
        public List<UserWrapper> users;
        public String responseCode { get; set; }
        public String responseMessage { get; set; }
        public List<String> errorMessages { get; set; }
        
        public UserListResponse(List<UserWrapper> users, String responseCode, String responseMessage, List<String> errorMessages) {
            this.users = users;
            this.responseCode = responseCode;
            this.responseMessage = responseMessage;
            this.errorMessages = errorMessages;
        }
        
    }
    
    global class UserWrapper {
        public String Name;
        public String Email;
        public String Phone;
        public String BranchName;
        public String Type;
        
        public UserWrapper(String Name, String Email, String Phone,String BranchName,String Type) {
            this.Name = Name;
            this.Email = Email;
            this.Phone = Phone;
            this.BranchName = BranchName;
            this.Type = Type;
        }
        
    }
    
    global class RequestWrapper {
        global String user_type;
        global String msa_code;
        global List<String> sfx_code;
        global List<String> rc_name;
        global List<Decimal> propel_i_branchid;
        
    }
}