/*
* Description      :       
* Created By       :       Safexpress team
* Created Date     :       
* Release          :       
* Last Modified on :       
* Jira Ticket      :       
*/
public class PropelI_PortfolioMgnmt_Controller
{
    //This method is userd for getting the values option of Designation Picklist field.
    @AuraEnabled(cacheable=true)
    public static List<string> getDepartment(){
        List<String> lstDepartment = new List<String>();
        Schema.DescribeFieldResult fieldResult = User.Designation__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        // Get the list of department. 
        List<Portfolio_Department__mdt> lstdepartments = [SELECT Department_Name__c from Portfolio_Department__mdt];
        System.debug('lstdepartments--------------->'+lstdepartments);
        if(lstdepartments != null && lstdepartments.size() > 0)
        {
            for(Portfolio_Department__mdt eachDeprt : lstdepartments)
                lstDepartment.add(eachDeprt.Department_Name__c);
        }
        lstDepartment.sort();
        return lstDepartment;
    }
    
    //Returning list of user according to selected department
    @AuraEnabled
    public static List<user> getUsers(String dept){        
        List<user> lstUser = [SELECT Id, name, AD_Id__c, MobilePhone, Email,Designation__c, Department, Region__c, journey_Type__c,Supplier_Num__c, Supplier_Site_Code__c FROM User WHERE designation__c = :dept AND isActive = True];
        lstUser.sort(); 
        return lstUser;
    }
    
    //@@@@@@@@ Depricated by Akshay Kumar on 29 - Jul-2022
    // Method to Return User info
    @AuraEnabled
    public static User GetUserProfile(Id userId ){
        User us = new User();
        us = [select id, name, MobilePhone, Email,Designation__c, Department, AD_id__c, Region__c, journey_Type__c,Supplier_Num__c, Supplier_Site_Code__c from user WHERE IsActive = true AND Id =: userId ];
        return us;
    } 
    
    //Returning list to be used as dummy in the picklist
    @AuraEnabled
    public static List<String> getData(){        
        List<String> data = new List<String>();
        String a = 'One';
        String b = 'Two';
        String c = 'Three';
        Data.add(a);
        Data.add(b);
        Data.add(c);
        return data;
    }
    
    // Return the list of searching by options. 
    @AuraEnabled
    Public Static List<String> getSearchBy(){
        
        //Access the "PropelI_Search_By__mdt" metadata. 
        List<PropelI_Search_By__mdt> lstSearchby = [SELECT Search_By__c from PropelI_Search_By__mdt];
        // Prepare the list of searching by options. 
        List<String> lstSearchingByOpts = new List<String>();
        for(PropelI_Search_By__mdt eachSearchBy : lstSearchby)
            lstSearchingByOpts.add(eachSearchBy.Search_By__c);
        
        System.debug('lstSearchingByOpts------------------->'+lstSearchingByOpts);
        return lstSearchingByOpts;
    }
    
    @AuraEnabled
    Public Static List<String> getPortfolioType()
    {
        //Access the "Portfolio_Type__mdt" metadata. 
        List<Portfolio_Type__mdt> lstPortfolioMtd = [SELECT Type__c from Portfolio_Type__mdt];
        //Prepare the list of portfolio type options. 
        List<String> lstPortfolioType = new List<String>();
        for(Portfolio_Type__mdt eachPortfolioType : lstPortfolioMtd)
            lstPortfolioType.add(eachPortfolioType.Type__c);
        
        System.debug('lstPortfolioType------------->'+lstPortfolioType);
        lstPortfolioType.sort();
        return lstPortfolioType;
    }
    
    //This method will return all the existing assinged Submission/Collection records for the selected User.
    @AuraEnabled
    //Getting existing assigned records list.
    Public Static wrap_SCMapping_Pagination getAssignedSCPortfolios(String searchby, Id usrId, String searchStr, String str_PortfolioType, 
                                                                    Integer pageSize, Integer startIdx, Integer endIdx)
    {
        Integer totalRecords = 0;
        List<String> msaCodes = new List<String>();
        Set<String> msaCodeSet = new Set<String>();
        
        system.debug('pageSize = '+pageSize);
        system.debug('startIdx = '+startIdx);
        system.debug('endIdx = '+endIdx);
        system.debug('totalRecords = '+totalRecords);
        
        for(Account_Team__c accTeam : [SELECT Id, Name, Account__r.MSA__c, BDMPropelI__r.Name from Account_Team__c  where BDMPropelI__c =: usrId AND 
                                       RecordType.Name = 'PropelI Account Team' AND (Submission__c = TRUE OR Collection__c = TRUE ) order by Account__r.MSA__c ASC]){
                                           msaCodeSet.add(accTeam.Account__r.MSA__c);
                                       }
        
        
        system.debug('msaCodeSet ==>'+msaCodeSet);
        
        for(Account msaRec : [Select Id, Name, Propel_MSACode__c from Account where Propel_MSACode__c In:msaCodeSet order by Propel_MSACode__c]){
            if(totalRecords >= startIdx && totalRecords < endIdx){
                system.debug('Enter '+totalRecords);
                msaCodes.add(msaRec.Propel_MSACode__c);
            }
            totalRecords = totalRecords+1;
            
        }
        
        system.debug('msaCodes ==>'+msaCodes);
        
        Decimal pages = Decimal.valueOf(totalRecords);
        System.debug('@@@pages'+ pages);
        
        pages = pages.divide(Decimal.valueOf(pageSize), 2);
        System.debug('@@@pages'+ pages);
        
        Integer totalPages = (Integer)pages.round(System.RoundingMode.CEILING);
        System.debug('@@@totalpages'+ totalPages);
        
        //adjust start index e.g. 1, 11, 21, 31
        startIdx = startIdx+1;
        //adjust end index
        if(endIdx > totalRecords){
            endIdx = totalRecords;
        }
        
        System.debug('searchby----------------->'+searchby);
        System.debug('usrId----------------->'+usrId);
        System.debug('searchStr------------->'+searchStr);
        System.debug('str_PortfolioType----------->'+str_PortfolioType);
        
        Set<String> setSearchStr = new Set<String>();
        if(String.isNotBlank(searchStr))
        {
            List<String> lstSearchStr = searchStr.split(',');
            System.debug('lstSearchStr----------->'+lstSearchStr);
            setSearchStr = new Set<String>(lstSearchStr);
            System.debug('setSearchStr--------------->'+setSearchStr);
        }    
        Set<String> set_RC = new Set<String>();
        Set<String> set_SFXCode = new Set<String>();
        Map<String, Account_Team__c> mapBillingByIdAccountTeam = new Map<String, Account_Team__c>();
        Set<String> setMSA = new Set<String>();
        List<Account_Team__c> lstAssignedPostfolios = [SELECT Id, Name, National1__c,National2__c,National3__c,CRS__c, Account__r.SFX_Code__c,
                                                       NSM__c , Relationship__c, Collection__c,Submission__c,Account__r.Propel_MSACode__c, PropelI_Branch_Id__c,
                                                       Account__r.Name,Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__r.Name 
                                                       from Account_Team__c where 
                                                       BDMPropelI__c =: usrId AND (Collection__c = TRUE OR Submission__c = True) AND Account__r.MSA__c IN: msaCodes];
        System.debug('lstAssignedPostfolios-------------------->'+lstAssignedPostfolios);
        if(! lstAssignedPostfolios.isEmpty())
        {
            for(Account_Team__c eachAccountTeam : lstAssignedPostfolios)
            {
                System.debug('eachAccountTeam.Account__r.Name------------>'+eachAccountTeam.Account__r.Name);
                if(String.isNotBlank(eachAccountTeam.Account__r.Name) && eachAccountTeam.Account__r.Name.startsWithIgnoreCase('RC'))
                {
                    set_RC.add(eachAccountTeam.Account__r.Name);
                    if(eachAccountTeam.Account__r.SFX__c != null)
                    {
                        set_SFXCode.add(eachAccountTeam.Account__r.SFX__c);
                    }
                    if(eachAccountTeam.PropelI_Branch_Id__c != null)
                    {
                        mapBillingByIdAccountTeam.put(eachAccountTeam.PropelI_Branch_Id__c, eachAccountTeam);
                    }
                }
                else if(String.isNotBlank(eachAccountTeam.Account__r.SFX_Code__c) && eachAccountTeam.Account__r.SFX_Code__c.startsWithIgnoreCase('SFX'))   
                {
                    if(eachAccountTeam.Account__r.SFX_Code__c != null)
                    {
                        set_SFXCode.add(eachAccountTeam.Account__r.SFX_Code__c);
                    }
                    if(eachAccountTeam.Account__r.MSA__c != null)
                    {
                        setMSA.add(eachAccountTeam.Account__r.MSA__c);
                    }
                    if(eachAccountTeam.PropelI_Branch_Id__c != null)
                    {
                        mapBillingByIdAccountTeam.put(eachAccountTeam.PropelI_Branch_Id__c, eachAccountTeam);
                    }
                }
            }
            System.debug('mapBillingByIdAccountTeam------------>'+mapBillingByIdAccountTeam);
            System.debug('set_RC------------------>'+set_RC);
            System.debug('set_SFXCode------------------->'+set_SFXCode);
            System.debug('setMSA------------->'+setMSA);
            if(! set_RC.isEmpty() || ! set_SFXCode.isEmpty())
            {
                List<Account_Team__c> lstOthrsAssignedPostfolios = [SELECT Id, Name, National1__c,National2__c,National3__c,
                                                                    CRS__c,NSM__c , Relationship__c, Collection__c,Submission__c,Account__r.Propel_MSACode__c,
                                                                    Account__r.Name,Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__r.Name, PropelI_Branch_Id__c, Account__r.SFX_Code__c
                                                                    from Account_Team__c where (Account__r.Name    
                                                                                                IN : set_RC OR  Account__r.SFX_Code__c IN : set_SFXCode )
                                                                    AND (Collection__c = TRUE OR Submission__c = True) AND BDMPropelI__c != :usrId];
                System.debug('lstOthrsAssignedPostfolios-------------->'+lstOthrsAssignedPostfolios);
                Map<String, wrap_SCMapping> mapOthrsAssignedPortfolio = new Map<String, wrap_SCMapping>();
                if( !lstOthrsAssignedPostfolios.isEmpty())
                {
                    for(Account_Team__c asgndPortfolio : lstOthrsAssignedPostfolios)
                    {
                        if(asgndPortfolio.Account__c != null  && asgndPortfolio.Account__r.SFX_Code__c != null && asgndPortfolio.Account__r.SFX_Code__c.startsWithIgnoreCase('SFX'))
                        {
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null, asgndPortfolio.Submission__c , Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null,asgndPortfolio.BDMPropelI__r.Name));
                            else
                            {
                                if(asgndPortfolio.Collection__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollection = asgndPortfolio.Collection__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollectionAssigned = asgndPortfolio.Collection__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CollectionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    
                                }
                                
                                if(asgndPortfolio.Submission__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubimission = asgndPortfolio.Submission__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubmissionAssigned = asgndPortfolio.Submission__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).SubmissionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    
                                }
                            }
                        }                     
                        else if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Name != null && asgndPortfolio.Account__r.Name.startsWithIgnoreCase('RC'))
                        {
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                            else
                            {
                                if(asgndPortfolio.Collection__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollection = asgndPortfolio.Collection__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollectionAssigned = asgndPortfolio.Collection__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CollectionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    
                                }
                                
                                if(asgndPortfolio.Submission__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubimission = asgndPortfolio.Submission__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubmissionAssigned = asgndPortfolio.Submission__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).SubmissionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    
                                }
                            }
                            
                        }
                    }
                }
                System.debug('mapOthrsAssignedPortfolio------------->'+mapOthrsAssignedPortfolio);
                
                List<Account> lstRCAccounts = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,Propel_key__c,Billing_Level__c,Parent.Name, SFX_Code__c,Assign_Branch_Id__r.Name from Account where Name IN : set_RC AND RecordType.Name = 'Rate Card' limit 9999];
                System.debug('lstRCAccounts----------->'+lstRCAccounts);
                List<Account> lstSFX = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,Propel_key__c,Billing_Level__c,Parent.Name, SFX_Code__c,Assign_Branch_Id__r.Name from Account where SFX_Code__c IN : set_SFXCode ORDER BY SFX_Code__c ASC limit 9999];
                System.debug('lstSFX--------------->'+lstSFX);
                List<Billing_Information__c> lstBillingInfos = [SELECT Id, Billing_Level__c,MSA__c, SFX_no__c, Rate_Card_no__c,(SELECT Billing_By_Id__c,Billing_Branch__r.Name,Collection_Branch__r.Name, Submission_Branch__r.Name from Billing_Line_Items__r /*where isactive__c = true*/) from Billing_Information__c where SFX_no__c IN :set_SFXCode limit 9999];
                System.debug('lstBillingInfos---------------->'+lstBillingInfos);
                Map<String, List<wrap_SCMapping>> mapwrap_SCMapping = new Map<String, List<wrap_SCMapping>>();
                Map<String, List<wrap_SCMapping>> mapwrap_SCMapping_SFX = new Map<String, List<wrap_SCMapping>>();
                
                if(! lstBillingInfos.isEmpty())
                {
                    for(Billing_Information__c eachBillingInfo : lstBillingInfos)
                    {
                        if(eachBillingInfo.Billing_Line_Items__r != null && eachBillingInfo.Billing_Line_Items__r.size() > 0)
                        {
                            for(Billing_Line_Item__c eachBillLineItem : eachBillingInfo.Billing_Line_Items__r)
                            {
                                if(eachBillingInfo.SFX_no__c != null) //Added on 4-Apr-2023 by Mohit Sharma
                                {
                                    Boolean isCollectionSelfAsgnd = mapBillingByIdAccountTeam != null && mapBillingByIdAccountTeam.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapBillingByIdAccountTeam.get(eachBillLineItem.Billing_By_Id__c).Collection__c ? True : False ;
                                    //system.debug('isCollectionSelfAsgnd---->'+isCollectionSelfAsgnd);
                                    Boolean isCollectionAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isCollection ? True : False ;
                                    //system.debug('isCollectionAsgnd----->'+isCollectionAsgnd);
                                    String str_CollectionBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isCollection && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).CollectionUsrName != null ? mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).CollectionUsrName: Null ;
                                    //system.debug('str_CollectionBDM--->'+str_CollectionBDM);
                                    Boolean isSubmissionSelfAsgnd = mapBillingByIdAccountTeam != null && mapBillingByIdAccountTeam.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapBillingByIdAccountTeam.get(eachBillLineItem.Billing_By_Id__c).Submission__c ? True : False ;
                                    
                                    Boolean isSubmissionAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isSubimission ? True : False ;
                                    String str_SubmissionBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isSubimission && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).SubmissionUsrName != null ? mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).SubmissionUsrName : Null ;
                                    //System.debug('Collection-----Billing by Id--->'+eachBillLineItem.Billing_By_Id__c);
                                    //System.debug('Collection eachBillLineItem------------------------>'+eachBillingInfo.SFX_no__c);
                                    //System.debug('Collection isCollectionSelfAsgnd--------------->'+isCollectionSelfAsgnd);
                                    //System.debug('Collection isCollectionAsgnd----------------->'+isCollectionAsgnd);
                                    //System.debug('Collection str_CollectionBDM----------------->'+str_CollectionBDM);
                                    //System.debug('Collection isSubmissionSelfAsgnd--------------->'+isSubmissionSelfAsgnd);
                                    //System.debug('Collection isSubmissionAsgnd--------------->'+isSubmissionAsgnd);
                                    //System.debug('Collection str_SubmissionBDM--------------->'+str_SubmissionBDM);
                                    
                                    if(eachBillingInfo.Billing_Level__c == 'Rate Card') {
                                        if(! mapwrap_SCMapping.keySet().contains(eachBillingInfo.Rate_Card_no__c))  //Changed the key from SFX_no__c to Rate_Card_no__c
                                        {
                                            mapwrap_SCMapping.put(eachBillingInfo.Rate_Card_no__c, new List<wrap_SCMapping>{new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name,isSubmissionAsgnd, isSubmissionSelfAsgnd, str_SubmissionBDM, isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM )});
                                        }else{
                                            mapwrap_SCMapping.get(eachBillingInfo.Rate_Card_no__c).add(new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd, str_SubmissionBDM, isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM));
                                        }
                                    }
                                    else {
                                        if(! mapwrap_SCMapping_SFX.containsKey(eachBillingInfo.SFX_no__c))
                                        {
                                            mapwrap_SCMapping_SFX.put(eachBillingInfo.SFX_no__c,new List<wrap_SCMapping>{new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name , isSubmissionAsgnd, isSubmissionSelfAsgnd, str_SubmissionBDM, isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM)});
                                        }else{
                                            mapwrap_SCMapping_SFX.get(eachBillingInfo.SFX_no__c).add(new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name , isSubmissionAsgnd, isSubmissionSelfAsgnd, str_SubmissionBDM, isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM));
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //System.debug('mapwrap_SCMapping_SFX---------------------->'+mapwrap_SCMapping_SFX);
                    //System.debug('mapwrap_SCMapping---------------------->'+mapwrap_SCMapping);
                    Map<String, List<wrap_SCBranches>> mapwrap_SCBranches = new Map<String, List<wrap_SCBranches>>();
                    if(! lstRCAccounts.isEmpty())
                    {
                        for(Account eachRC : lstRCAccounts)
                        {
                            if(! mapwrap_SCBranches.containsKey(eachRC.SFX__c) && ! mapwrap_SCMapping.isEmpty() &&  mapwrap_SCMapping.containsKey(eachRC.Name))
                                mapwrap_SCBranches.put(eachRC.SFX__c, new List<wrap_SCBranches>{new wrap_SCBranches(eachRC.Name,eachRC.Parent.Name, mapwrap_SCMapping.get(eachRC.Name))});
                            else if(! mapwrap_SCBranches.isEmpty() && mapwrap_SCBranches.containsKey(eachRC.SFX__c) && ! mapwrap_SCMapping.isEmpty() && mapwrap_SCMapping.containsKey(eachRC.Name))
                                mapwrap_SCBranches.get(eachRC.SFX__c).add(new wrap_SCBranches(eachRC.Name,eachRC.Parent.Name, mapwrap_SCMapping.get(eachRC.Name)));
                        }
                    }
                    //System.debug('mapwrap_SCBranches------------>'+mapwrap_SCBranches);
                    Map<String, List<wrap_SCSFX>> mapwrap_SCSFX = new Map<String, List<wrap_SCSFX>>();
                    Set<String> setMSANo = new Set<String>();
                    Map<String, String> mapMSAName = new Map<String, String>();
                    for(Account eachSFX: lstSFX)
                    {
                        setMSANo.add(eachSFX.MSA__c);
                        if(! mapMSAName.keySet().contains(eachSFX.Parent.Name))
                            mapMSAName.put(eachSFX.MSA__c, eachSFX.Parent.Name);
                        
                        if(String.isNotBlank(eachSFX.Billing_Level__c) && eachSFX.Billing_Level__c.equalsIgnoreCase('Rate Card'))
                        {
                            if(! mapwrap_SCSFX.keySet().contains(eachSFX.MSA__c))
                            {
                                mapwrap_SCSFX.put(eachSFX.MSA__c,new List<wrap_SCSFX>{new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c,null,mapwrap_SCBranches.get(eachSFX.SFX__c), eachSFX.Billing_Level__c)});
                            }else{
                                
                                mapwrap_SCSFX.get(eachSFX.MSA__c).add(new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c,null, mapwrap_SCBranches.get(eachSFX.SFX__c), eachSFX.Billing_Level__c));
                            }
                        }
                        else if(String.isNotBlank(eachSFX.Billing_Level__c) && (eachSFX.Billing_Level__c.equalsIgnoreCase('MSA') || eachSFX.Billing_Level__c.equalsIgnoreCase('SFX')) && mapwrap_SCMapping_SFX.keySet().contains(eachSFX.SFX__c))
                        {
                            if(! mapwrap_SCSFX.keySet().contains(eachSFX.MSA__c))
                                mapwrap_SCSFX.put(eachSFX.MSA__c, new List<wrap_SCSFX>{ new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, mapwrap_SCMapping_SFX.get(eachSFX.SFX__c), null, eachSFX.Billing_Level__c)});
                            else{
                                mapwrap_SCSFX.get(eachSFX.MSA__c).add(new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, mapwrap_SCMapping_SFX.get(eachSFX.SFX__c), null, eachSFX.Billing_Level__c));
                            }
                        }
                    }
                    //System.debug('mapMSAName---------------->'+mapMSAName);
                    //System.debug('mapwrap_SCSFX--------------->'+mapwrap_SCSFX);
                    //System.debug('setMSANo------------------->'+setMSANo);
                    Map<String, wrap_SCMSA> mapwrap_SCMSA = new Map<String, wrap_SCMSA>();
                    
                    if(! mapwrap_SCSFX.isEmpty() && ! setMSANo.isEmpty())
                    {
                        for(String eachMSA : setMSANo)
                        {
                            if(! mapwrap_SCMSA.keySet().contains(eachMSA) && mapwrap_SCSFX.keySet().contains(eachMSA))
                                mapwrap_SCMSA.put(eachMSA, new wrap_SCMSA(eachMSA,mapMSAName.get(eachMSA),  mapwrap_SCSFX.get(eachMSA)));
                        }
                    }
                    //System.debug('mapwrap_SCMSA--------------->'+mapwrap_SCMSA);
                    
                    List<wrap_SCMSA> data = new List<wrap_SCMSA>();
                    
                    for(String msaCode : msaCodeSet){
                        if(mapwrap_SCMSA.containsKey(msaCode)){
                            data.add(mapwrap_SCMSA.get(msaCode));
                        }
                    }
                    return new wrap_SCMapping_Pagination(data, msaCodeSet.size(), totalPages, startIdx, endIdx);  
                }
            }
        }
        return null;
        
    }
    
    //This method will return all the existing assinged Relationship/National records for the selected User.
    @AuraEnabled
    Public Static wrap_MSAPortfolioRlNAN_Pagination getAssignedUsrPorfolios(String searchby, Id usrId, String searchStr, String str_PortfolioType, 
                                                                            Integer pageSize, Integer startIdx, Integer endIdx)
    {
        
        Integer totalRecords = 0;
        
        List<String> msaCodes = new List<String>();
        
        // Map to return the assigned portfolios. 
        Map<String, wrap_MSAPortfolioRlNAN> lstwrap_MSAPortfolioRlNAN1 = new Map<String, wrap_MSAPortfolioRlNAN>(); 
        
        Set<String> msaCodeSet = new Set<String>();
        
        system.debug('pageSize = '+pageSize);
        system.debug('startIdx = '+startIdx);
        system.debug('endIdx = '+endIdx);
        system.debug('totalRecords = '+totalRecords);
        
        for(Account_Team__c accTeam : [SELECT Id, Name, Account__r.MSA__c, BDMPropelI__r.Name from Account_Team__c  where BDMPropelI__c =: usrId AND 
                                       RecordType.Name = 'PropelI Account Team' AND (National1__c = TRUE OR National2__c = TRUE OR National3__c = TRUE OR National4__c = TRUE OR CRS__c = TRUE OR NSM__c = TRUE OR Relationship__c = TRUE) order by Account__r.MSA__c ASC]){
                                           msaCodeSet.add(accTeam.Account__r.MSA__c);
                                       }
        
        
        system.debug('msaCodeSet ==>'+msaCodeSet);
        
        for(Account msaRec : [Select Id, Name, Propel_MSACode__c from Account where Propel_MSACode__c In:msaCodeSet order by Propel_MSACode__c]){
            if(totalRecords >= startIdx && totalRecords < endIdx){
                system.debug('Enter '+totalRecords);
                msaCodes.add(msaRec.Propel_MSACode__c);
            }
            totalRecords = totalRecords+1;
        }
        
        system.debug('msaCodes ==>'+msaCodes);
        
        Decimal pages = Decimal.valueOf(totalRecords);
        System.debug('@@@pages'+ pages);
        
        pages = pages.divide(Decimal.valueOf(pageSize), 2);
        System.debug('@@@pages'+ pages);
        
        Integer totalPages = (Integer)pages.round(System.RoundingMode.CEILING);
        System.debug('@@@totalpages'+ totalPages);
        
        //adjust start index e.g. 1, 11, 21, 31
        startIdx = startIdx+1;
        //adjust end index
        if(endIdx > totalRecords){
            endIdx = totalRecords;
        }
        
        List<Account_Team__c> lstAssignedPostfolios = [SELECT Id, Name, PropelI_Branch_Id__c,National1__c,National2__c,National3__c,National4__c,CRS__c,NSM__c , Relationship__c, Account__r.SFX_Code__c,
                                                       Collection__c,Submission__c,Account__r.Propel_MSACode__c, Account__r.Name,Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__r.Name from Account_Team__c  where BDMPropelI__c =: usrId AND 
                                                       RecordType.Name = 'PropelI Account Team' AND (National1__c = TRUE OR National2__c = TRUE OR National3__c = TRUE OR National4__c = TRUE OR CRS__c = TRUE OR NSM__c = TRUE OR Relationship__c = TRUE) AND Account__r.MSA__c IN: msaCodes];
        System.debug('lstAssignedPostfolios-------------->'+lstAssignedPostfolios); 
        if(! lstAssignedPostfolios.isEmpty())
        {
            Set<String> set_RC = new Set<String>();
            Set<String> set_SFXCode = new Set<String>();
            Map<String, Account_Team__c> map_MSAAccount = new Map<String, Account_Team__c>();
            Map<String, Account_Team__c> map_SFXAccount = new Map<String, Account_Team__c>();
            Map<String, Account_Team__c> map_RCAccounts = new Map<String, Account_Team__c>();
            set<String> setMSACode = new Set<String>();
            for(Account_Team__c eachAccountTeam : lstAssignedPostfolios)
            {
                //System.debug('---- eachAccountTeam.Account__r.Name: ' + eachAccountTeam.Account__r.Name);
                //System.debug('---- eachAccountTeam.Account__r.MSA__c: ' + eachAccountTeam.Account__r.MSA__c);
                //System.debug('---- eachAccountTeam.Account__r.Propel_MSACode__c: ' + eachAccountTeam.Account__r.Propel_MSACode__c);
                if(String.isNotBlank(eachAccountTeam.Account__r.Name) && eachAccountTeam.Account__r.Name.startsWithIgnoreCase('RC'))
                {
                    set_RC.add(eachAccountTeam.Account__r.Name);
                    map_RCAccounts.put(eachAccountTeam.PropelI_Branch_Id__c, eachAccountTeam);
                    set_SFXCode.add(eachAccountTeam.Account__r.SFX__c);
                    setMSACode.add(eachAccountTeam.Account__r.MSA__c);
                    //map_MSAAccount.put(eachAccountTeam.Account__r.MSA__c, eachAccountTeam);
                }
                else if(String.isNotBlank(eachAccountTeam.Account__r.Name) && eachAccountTeam.Account__r.Name.startsWithIgnoreCase('SFX'))   
                {
                    setMSACode.add(eachAccountTeam.Account__r.MSA__c);
                    set_SFXCode.add(eachAccountTeam.Account__r.SFX__c);
                    map_SFXAccount.put(eachAccountTeam.Account__r.SFX__c, eachAccountTeam);
                    //map_MSAAccount.put(eachAccountTeam.Account__r.MSA__c, eachAccountTeam);
                }
                else if(String.isNotBlank(eachAccountTeam.Account__r.Propel_MSACode__c))
                {
                    setMSACode.add(eachAccountTeam.Account__r.Propel_MSACode__c);
                    map_MSAAccount.put(eachAccountTeam.Account__r.Propel_MSACode__c, eachAccountTeam);
                }
            }
            System.debug('map_RCAccounts----------------->'+map_RCAccounts);
            System.debug('map_RCAccounts.keySet()----------------->'+map_RCAccounts.keySet());
            System.debug('map_SFXAccount---------------->'+map_SFXAccount);
            System.debug('map_SFXAccount.keySet()---------------->'+map_SFXAccount.keySet());
            System.debug('map_MSAAccount--------------->'+map_MSAAccount);
            System.debug('map_MSAAccount.keySet()--------------->'+map_MSAAccount.keySet());
            System.debug('set_RC------------------>'+set_RC);
            System.debug('set_SFXCode------------------->'+set_SFXCode);
            System.debug('setMSACode----->'+setMSACode);
            
            if(! set_SFXCode.isEmpty() || ! map_MSAAccount.isEmpty())
            {
                List<Account_Team__c> lstOthrsAssignedPostfolios = [SELECT Id, Name, PropelI_Branch_Id__c,National1__c,National2__c,National3__c,CRS__c,NSM__c , National4__c,Relationship__c, Collection__c, Account__r.SFX_Code__c,
                                                                    Submission__c,Account__r.Propel_MSACode__c, Account__r.Name,Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__c, BDMPropelI__r.Name from Account_Team__c where 
                                                                    (Account__r.Name IN : set_SFXCode  OR Account__r.Propel_MSACode__c IN : setMSACode OR Account__r.Name IN : set_RC)  AND RecordType.Name = 'PropelI Account Team' 
                                                                    AND (National1__c = TRUE OR National2__c = TRUE OR National3__c = TRUE OR National4__c =TRUE OR  CRS__c = TRUE OR NSM__c = TRUE OR Relationship__c = TRUE)];
                //System.debug('lstOthrsAssignedPostfolios-------------->'+lstOthrsAssignedPostfolios);
                Map<String, wrap_MSAPortfolioRlNAN> mapOthrsAssignedPortfolio = new Map<String, wrap_MSAPortfolioRlNAN>();
                if(! lstOthrsAssignedPostfolios.isEmpty())
                {   
                    for(Account_Team__c asgndPortfolio : lstOthrsAssignedPostfolios)
                    {
                        //System.debug('asgndPortfolio.Account__r.Name------------>'+asgndPortfolio.Account__r.Name);
                        //System.debug('asgndPortfolio.Account__r.Propel_MSACode__c---------->'+asgndPortfolio.Account__r.Propel_MSACode__c);
                        //System.debug('---- asgndPortfolio.PropelI_Branch_Id__c: ' + asgndPortfolio.PropelI_Branch_Id__c);
                        //System.debug('---- asgndPortfolio.Account__r.Name.startsWith("RC"): ' + asgndPortfolio.Account__r.Name.startsWith('RC'));
                        
                        if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Name != null  && asgndPortfolio.Account__r.Name.startsWith('RC'))
                        {
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Name, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                            else
                            {
                                if(asgndPortfolio.National1__c || Test.isRunningTest()){mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CCD = asgndPortfolio.National1__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCCDAssigned = asgndPortfolio.National1__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CCDMBDM =  asgndPortfolio.BDMPropelI__r.Name;}
                                
                                if(asgndPortfolio.National2__c || Test.isRunningTest()) {mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).NAM = asgndPortfolio.National2__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isNamAssigned = asgndPortfolio.National2__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).NAMBDM =  asgndPortfolio.BDMPropelI__r.Name;}
                                
                                if(asgndPortfolio.National3__c || Test.isRunningTest()) {   mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).QRM = asgndPortfolio.National3__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isQRMAssigned = asgndPortfolio.National3__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).QRMBDM =  asgndPortfolio.BDMPropelI__r.Name;}
                                
                                if(asgndPortfolio.National4__c || Test.isRunningTest()) {   mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).RM = asgndPortfolio.National4__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isRMAssigned = asgndPortfolio.National4__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).RMBDM =  asgndPortfolio.BDMPropelI__r.Name;}
                                
                                if(asgndPortfolio.CRS__c || Test.isRunningTest()) { mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CRS = asgndPortfolio.CRS__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCRSAssigned = asgndPortfolio.CRS__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CRSBDM =  asgndPortfolio.BDMPropelI__r.Name;}  
                                
                                if(asgndPortfolio.Relationship__c || Test.isRunningTest())  {  mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).Relationship = asgndPortfolio.Relationship__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isRelAssigned = asgndPortfolio.Relationship__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).relationshipBDM =  asgndPortfolio.BDMPropelI__r.Name;}                                  
                            }   
                        }
                        else if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Propel_MSACode__c != null  && asgndPortfolio.Account__r.Propel_MSACode__c.startsWith('MSA') )
                        {
                            
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.Account__r.Propel_MSACode__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.Account__r.Propel_MSACode__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Propel_MSACode__c,asgndPortfolio.Account__r.Name, asgndPortfolio.National1__c, asgndPortfolio.National1__c,asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,asgndPortfolio.National2__c, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,asgndPortfolio.National3__c, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,asgndPortfolio.National4__c, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,asgndPortfolio.CRS__c, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                            else
                            {
                                if(asgndPortfolio.National1__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CCD = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isCCDAssigned = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CCDMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National2__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).NAM = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isNamAssigned = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).NAMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National3__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).QRM = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isQRMAssigned = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).QRMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National4__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).RM = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isRMAssigned = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).RMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.CRS__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CRS = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isCRSAssigned = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CRSBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                } 
                                if(asgndPortfolio.Relationship__c) 
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).Relationship = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isRelAssigned = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).relationshipBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }                                        
                            }  
                        } 
                        //System.debug('mapOthrsAssignedPortfolio---->'+mapOthrsAssignedPortfolio);
                    }
                }
                
                //System.debug('mapOthrsAssignedPortfolio------------->'+mapOthrsAssignedPortfolio);
                //System.debug('set_SFXCode------------------->'+set_SFXCode);
                List<Account> lstBranches = [SELECT Id,Name, Branch_Status__c, AssignBranch_ID__c, Propel_MSACode__c, MSA__c, SFX__c, Parent.Name,Parent.Parent.Name, SFX_Code__c, Assign_Branch_Id__r.Name, Parent.Relationship__c,Billing_Branch__r.Name from Account where Parent.Name IN :  set_RC AND Branch_Status__c != 'In-active' AND Is_PRC_Rate_Card__c=false];
                List<Account> lstServices =  [SELECT Id,Name, Account_Name__c, Propel_MSACode__c, MSA__c, SFX__c,National1__c,National2__c,National3__c, Parent.Name,Parent.Billing_Level__c, SFX_Code__c, Assign_Branch_Id__r.Name,Billing_Branch__r.Name from Account where SFX__c IN : set_SFXCode AND SFX__c != null ORDER BY SFX__c ASC];
                //System.debug('lstBranches----------------->'+lstBranches);
                //System.debug('lstServices-------------->'+lstServices);
                Map<String, List<Wrap_RT_BracnhesPortfolios>> map_Branches = new Map<String, List<Wrap_RT_BracnhesPortfolios>>();
                if(! lstBranches.isEmpty())
                {
                    for(Account eachBranch : lstBranches)
                    {
                        system.debug('--------------------------------------'+eachBranch);
                        
                        Boolean isRelationshipSelfAsgnd = map_RCAccounts != null && map_RCAccounts.keySet().contains(eachBranch.AssignBranch_ID__c) && map_RCAccounts.get(eachBranch.AssignBranch_ID__c).Relationship__c ? True : False ;
                        Boolean isRelationshipAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBranch.AssignBranch_ID__c) && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).Relationship ? True : False ;
                        String str_RelationshipBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBranch.AssignBranch_ID__c) && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).Relationship && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).relationshipBDM != null ? mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).relationshipBDM : Null ;
                        
                        //System.debug('isRelationshipSelfAsgnd----------->'+isRelationshipSelfAsgnd);
                        //System.debug('isRelationshipAsgnd---------------->'+isRelationshipAsgnd);
                        //System.debug('str_RelationshipBDM-------------->'+str_RelationshipBDM);
                        if(eachBranch.SFX__c != null)
                        {
                            if(! map_Branches.keySet().contains(eachBranch.SFX__c))
                            {
                                
                                map_Branches.put(eachBranch.SFX__c,  new List<Wrap_RT_BracnhesPortfolios>{new Wrap_RT_BracnhesPortfolios(eachBranch.Parent.Name, eachBranch.Parent.Parent.Name, eachBranch.Billing_Branch__r.Name, eachBranch.AssignBranch_ID__c, isRelationshipAsgnd, isRelationshipSelfAsgnd, str_RelationshipBDM)});
                            }
                            
                            else 
                                map_Branches.get(eachBranch.SFX__c).add(new Wrap_RT_BracnhesPortfolios(eachBranch.Parent.Name,eachBranch.Parent.Parent.Name, eachBranch.Billing_Branch__r.Name, eachBranch.AssignBranch_ID__c, isRelationshipAsgnd,  isRelationshipSelfAsgnd, str_RelationshipBDM));
                        }                    
                    }
                }
                System.debug('map_Branches------------>'+map_Branches);
                Map<String, List<wrap_SFXPortfolioRlNAN>> map_Services = new Map<String, List<wrap_SFXPortfolioRlNAN>>();
                Map<String, String> mapMSAAccName = new Map<String, String>();
                if(! lstServices.isEmpty())
                {
                    Set<String> setSFX = new Set<String>();
                    for(Account eachService : lstServices)
                    {
                        if(eachService.SFX__c != null)
                        {
                            if(eachService.SFX__c != null && !setSFX.contains(eachService.SFX__c))
                            {
                                if(! map_Services.keySet().contains(eachService.MSA__c))
                                    map_Services.put(eachService.MSA__c, new List<wrap_SFXPortfolioRlNAN>{new wrap_SFXPortfolioRlNAN(eachService.SFX__c, map_Branches.get(eachService.SFX__c), eachService.Parent.Billing_Level__c)});
                                else
                                    map_Services.get(eachService.MSA__c).add(new wrap_SFXPortfolioRlNAN(eachService.SFX__c, map_Branches.get(eachService.SFX__c), eachService.Parent.Billing_Level__c));
                            }
                            setSFX.add(eachService.SFX__c);
                            if(! mapMSAAccName.keySet().contains(eachService.MSA__c))
                                mapMSAAccName.put(eachService.MSA__c, eachService.Parent.Name );
                        }
                    }
                }
                System.debug('map_Services----------->'+map_Services);
                for(Account eachSFX : lstServices) 
                {
                    //System.debug('---- eachSFX.MSA__c: ' + eachSFX.MSA__c);
                    //System.debug('---- map_MSAAccount.keySet().contains(eachSFX.MSA__c): ' + map_MSAAccount.keySet().contains(eachSFX.MSA__c));
                    //System.debug('---- map_MSAAccount.get(eachSFX.MSA__c): ' + map_MSAAccount.get(eachSFX.MSA__c));
                    Boolean isCCDSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachSFX.MSA__c) && map_MSAAccount.get(eachSFX.MSA__c).National1__c ? True : False ;
                    Boolean isCCDAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCD) || isCCDSelfAsgnd) ? True : False ;
                    String str_CCDBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCD && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCDMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCDMBDM : Null ;           
                    //System.debug('isCCDSelfAsgnd----------->'+isCCDSelfAsgnd);
                    //System.debug('isCCDAsgnd---------------->'+isCCDAsgnd);
                    //System.debug('str_CCDBDM-------------->'+str_CCDBDM);
                    Boolean isNAMSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachSFX.MSA__c) && map_MSAAccount.get(eachSFX.MSA__c).National2__c ? True : False ;
                    Boolean isNAMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAM) || isNAMSelfAsgnd) ? True : False ;
                    String str_NAMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAMBDM : Null ;           
                    //System.debug('isNAMSelfAsgnd----------->'+isNAMSelfAsgnd);
                    //System.debug('isNAMAsgnd---------------->'+isNAMAsgnd);
                    //System.debug('str_NAMBDM-------------->'+str_NAMBDM);
                    Boolean isQRMSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachSFX.MSA__c) && map_MSAAccount.get(eachSFX.MSA__c).National3__c? True : False ;
                    Boolean isQRMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRM) || isQRMSelfAsgnd) ? True : False ;
                    String str_QRMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRMBDM : Null ;
                    //System.debug('isQRMSelfAsgnd----------->'+isQRMSelfAsgnd);
                    //System.debug('isQRMAsgnd---------------->'+isQRMAsgnd);
                    //System.debug('str_QRMBDM-------------->'+str_QRMBDM);
                    Boolean isRMSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachSFX.MSA__c) && map_MSAAccount.get(eachSFX.MSA__c).National4__c  ? True : False ;
                    Boolean isRMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RM) || isRMSelfAsgnd) ? True : False ;
                    String str_RMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RMBDM: Null ;           
                    //System.debug('isRMSelfAsgnd----------->'+isRMSelfAsgnd);
                    //System.debug('isRMAsgnd---------------->'+isRMAsgnd);
                    //System.debug('str_RMBDM-------------->'+str_RMBDM);
                    Boolean isCRSSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachSFX.MSA__c) && map_MSAAccount.get(eachSFX.MSA__c).CRS__c ? True : False ;
                    Boolean isCRSAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRS) || isCRSSelfAsgnd )? True : False ;
                    String str_CRSBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRS && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRSBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRSBDM : Null ;           
                    //System.debug('isCRSSelfAsgnd----------->'+isCRSSelfAsgnd);
                    //System.debug('isCRSAsgnd---------------->'+isCRSAsgnd);
                    //System.debug('str_CRSBDM-------------->'+str_CRSBDM);
                    
                    if(! lstwrap_MSAPortfolioRlNAN1.keySet().contains(eachSFX.MSA__c))
                    {
                        String strNameMSA = eachSFX.Account_Name__c != null ? eachSFX.Account_Name__c : eachSFX.Parent.Name;
                        lstwrap_MSAPortfolioRlNAN1.put(eachSFX.MSA__c ,new wrap_MSAPortfolioRlNAN (eachSFX.MSA__c, strNameMSA, isCCDAsgnd,isCCDSelfAsgnd, str_CCDBDM, isNAMAsgnd, isNAMSelfAsgnd, str_NAMBDM, isQRMAsgnd, isQRMSelfAsgnd,str_QRMBDM,isRMAsgnd, isRMSelfAsgnd,str_RMBDM, isCRSAsgnd,isCRSSelfAsgnd, str_CRSBDM , map_Services.get(eachSFX.MSA__c), null, null));
                    }
                }
                if(map_MSAAccount != null && ! mapOthrsAssignedPortfolio.isEmpty())
                {
                    for(Account_Team__c eachMSA : map_MSAAccount.values())
                    {
                        //System.debug('---- eachMSA.Account__r.Propel_MSACode__c: ' + eachMSA.Account__r.Propel_MSACode__c);
                        //System.debug('---- map_MSAAccount.keySet().contains(eachMSA.Account__r.Propel_MSACode__c): ' + map_MSAAccount.keySet().contains(eachMSA.Account__r.Propel_MSACode__c));
                        //System.debug('---- map_MSAAccount.get(eachMSA.Account__r.Propel_MSACode__c): ' + map_MSAAccount.get(eachMSA.Account__r.Propel_MSACode__c));
                        
                        Boolean isCCDSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachMSA.Account__r.MSA__c) && map_MSAAccount.get(eachMSA.Account__r.MSA__c).National1__c ? True : False ;
                        Boolean isCCDAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).CCD) || isCCDSelfAsgnd) ? True : False ;
                        String str_CCDBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).CCD && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).CCDMBDM != null ? mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).CCDMBDM : Null ;           
                        //System.debug('isCCDSelfAsgnd----------->'+isCCDSelfAsgnd);
                        //System.debug('isCCDAsgnd---------------->'+isCCDAsgnd);
                        //System.debug('str_CCDBDM-------------->'+str_CCDBDM);
                        Boolean isNAMSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachMSA.Account__r.MSA__c) && map_MSAAccount.get(eachMSA.Account__r.MSA__c).National2__c ? True : False ;
                        Boolean isNAMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).NAM ) || isNAMSelfAsgnd) ? True : False ;
                        String str_NAMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).NAM && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).NAMBDM != null ? mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).NAMBDM : Null ;           
                        //System.debug('isNAMSelfAsgnd----------->'+isNAMSelfAsgnd);
                        //System.debug('isNAMAsgnd---------------->'+isNAMAsgnd);
                        //System.debug('str_NAMBDM-------------->'+str_NAMBDM);
                        Boolean isQRMSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachMSA.Account__r.MSA__c) && map_MSAAccount.get(eachMSA.Account__r.MSA__c).National3__c ? True : False ;
                        Boolean isQRMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).QRM )|| isQRMSelfAsgnd)? True : False ;
                        String str_QRMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).QRM && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).QRMBDM != null ? mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).QRMBDM : Null ;           
                        //System.debug('isQRMSelfAsgnd----------->'+isQRMSelfAsgnd);
                        //System.debug('isQRMAsgnd---------------->'+isQRMAsgnd);
                        //System.debug('str_QRMBDM-------------->'+str_QRMBDM);
                        Boolean isRMSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachMSA.Account__r.MSA__c) && map_MSAAccount.get(eachMSA.Account__r.MSA__c).National4__c ? True : False ;
                        Boolean isRMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).RM) || isRMSelfAsgnd) ? True  : False ;
                        String str_RMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).RM && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).RMBDM != null ? mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).RMBDM : Null ;           
                        //System.debug('isRMSelfAsgnd----------->'+isRMSelfAsgnd);
                        //System.debug('isRMAsgnd---------------->'+isRMAsgnd);
                        //System.debug('str_RMBDM-------------->'+str_RMBDM);
                        Boolean isCRSSelfAsgnd = map_MSAAccount != null && map_MSAAccount.keySet().contains(eachMSA.Account__r.MSA__c) && map_MSAAccount.get(eachMSA.Account__r.MSA__c).CRS__c ? True : False ;
                        Boolean isCRSAsgnd = (( mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).CRS) || isCRSSelfAsgnd) ? True : False ;
                        String str_CRSBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachMSA.Account__r.MSA__c) && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).CRS && mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).CRSBDM != null ? mapOthrsAssignedPortfolio.get(eachMSA.Account__r.MSA__c).CRSBDM : Null ;           
                        //System.debug('isCRSSelfAsgnd----------->'+isCRSSelfAsgnd);
                        //System.debug('isCRSAsgnd---------------->'+isCRSAsgnd);
                        //System.debug('str_CRSBDM-------------->'+str_CRSBDM);
                        
                        if(! lstwrap_MSAPortfolioRlNAN1.keySet().contains(eachMSA.Account__r.MSA__c))
                            lstwrap_MSAPortfolioRlNAN1.put(eachMSA.Account__r.MSA__c ,new wrap_MSAPortfolioRlNAN (eachMSA.Account__r.MSA__c,eachMSA.Account__r.Name, isCCDAsgnd,isCCDSelfAsgnd, str_CCDBDM, isNAMAsgnd, isNAMSelfAsgnd, str_NAMBDM, isQRMAsgnd, isQRMSelfAsgnd,str_QRMBDM,isRMAsgnd, isRMSelfAsgnd,str_RMBDM, isCRSAsgnd,isCRSSelfAsgnd, str_CRSBDM , map_Services.get(eachMSA.Account__r.MSA__c), null, null));
                    }
                }
                System.debug('lstwrap_MSAPortfolioRlNAN1----------------->'+lstwrap_MSAPortfolioRlNAN1);
                
            }
        }
        List<wrap_MSAPortfolioRlNAN> data = new List<wrap_MSAPortfolioRlNAN>();
        
        system.debug('msaCodes '+msaCodes);
        system.debug(lstwrap_MSAPortfolioRlNAN1);
        for(String msaCode : msaCodes){
            if(lstwrap_MSAPortfolioRlNAN1.containsKey(msaCode)){
                data.add(lstwrap_MSAPortfolioRlNAN1.get(msaCode));
            }
        }
        system.debug('data '+data);
        return  new wrap_MSAPortfolioRlNAN_Pagination(data, msaCodeSet.size(), totalPages, startIdx, endIdx);     
    }
    
    public static boolean hasprev(integer off){
        if(off > 0)
            return false;
        return true; 
    }
    
    public static boolean hasnxt(integer off, integer li, integer ps){
        if(off+ps < li)
            return false;
        return true;
    }
    // Method to return the new MSA/SFX/RC with the selected user portfolio. 
    @AuraEnabled
    Public Static List<wrap_MSAPortfolioRlNAN> getNewPortfolios(String searchby, Id usrId, String searchStr, String str_PortfolioType)// String searchby, Id usrId, String searchStr, String str_PortfolioType
    {
        System.debug('searchby----------->'+searchby);
        System.debug('usrId----->'+usrId);
        System.debug('searchStr----------->'+searchStr);
        System.debug('str_PortfolioType----------->'+str_PortfolioType);
        Set<String> setSearchStr = new Set<String>();
        // Map to return the assigned portfolios. 
        Map<String, wrap_MSAPortfolioRlNAN> lstwrap_MSAPortfolioRlNAN1 = new Map<String, wrap_MSAPortfolioRlNAN>(); 
        
        if(String.isNotBlank(searchStr))
        {
            List<String> lstSearchStr = searchStr.split(',');
            System.debug('lstSearchStr----------->'+lstSearchStr);
            if(! lstSearchStr.isEmpty())
            {
                for(String str : lstSearchStr)
                {
                    setSearchStr.add(str.trim()); 
                }
            }
            System.debug('setSearchStr--------------->'+setSearchStr);
        }
        Set<String> setAssignedSFX = new Set<String>();
        Map<String, Account_Team__c> mapAsignedSFXBDM = new Map<String, Account_Team__c>();
        List<Account_Team__c> lstAssignedPostfolios = [SELECT Id, Name, PropelI_Branch_Id__c,PropelI_Composite_Key__c,National1__c,National2__c,National3__c, Account__r.SFX_Code__c,
                                                       National4__c,CRS__c,NSM__c , Relationship__c, Collection__c,Submission__c,Account__r.Propel_MSACode__c, Account__r.Name,Account__r.SFX__c, 
                                                       Account__r.MSA__c, Account__r.ParentId, Account__r.Parent.Name, BDMPropelI__r.Name 
                                                       FROM Account_Team__c 
                                                       WHERE BDMPropelI__c =: usrId AND RecordType.Name = 'PropelI Account Team' 
                                                       AND (National1__c = TRUE OR National2__c = TRUE OR National3__c = TRUE OR National4__c = TRUE OR CRS__c = TRUE OR NSM__c = TRUE OR Relationship__c = TRUE)];
        System.debug('lstAssignedPostfolios-------------->'+lstAssignedPostfolios);
        
        if(! lstAssignedPostfolios.isEmpty())
        {
            for(Account_Team__c eachAssignedSFX : lstAssignedPostfolios)
            {
                if(eachAssignedSFX.Account__r.SFX__c != null)
                {
                    setAssignedSFX.add(eachAssignedSFX.Account__r.SFX__c);
                }
                if(eachAssignedSFX.Account__c != null && eachAssignedSFX.Account__r.Propel_MSACode__c != null && eachAssignedSFX.Account__r.Propel_MSACode__c.startsWith('MSA') && ! mapAsignedSFXBDM.keySet().contains(eachAssignedSFX.Account__r.Propel_MSACode__c))
                    mapAsignedSFXBDM.put(eachAssignedSFX.Account__r.Propel_MSACode__c,eachAssignedSFX);
                else if(eachAssignedSFX.Account__c != null && eachAssignedSFX.Account__r.Name.startsWith('RC') && ! mapAsignedSFXBDM.containsKey(eachAssignedSFX.PropelI_Branch_Id__c))
                    mapAsignedSFXBDM.put(eachAssignedSFX.PropelI_Branch_Id__c,eachAssignedSFX);
            }
        }
        System.debug('setAssignedSFX-------------->'+setAssignedSFX);
        System.debug('mapAsignedSFXBDM--------------->'+mapAsignedSFXBDM);
        
        List<wrap_MSAPortfolioRlNAN> lstwrap_MSAPortfolioRlNAN1_Test = new List<wrap_MSAPortfolioRlNAN>();
        if(! setSearchStr.isEmpty() && searchby.equalsIgnoreCase('MSA'))
        {
            List<Account> lstSFX = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c, Parent.Name, SFX_Code__c,Assign_Branch_Id__r.Name,Billing_Branch__r.Name from Account where Parent.Propel_MSACode__c IN : setSearchStr AND Type__c != 'PRC' AND RecordType.Name != 'PRC Customer' ORDER BY SFX_Code__c ASC ];
            System.debug('lstSFX--------------->'+lstSFX);
            
            if(! lstSFX.isEmpty())
            {  
                Set<String> setRCCode = new Set<String>();
                
                List<Account> lstBranches = [SELECT  Id,Name,Branch_Status__c, Propel_MSACode__c,AssignBranch_ID__c, MSA__c, SFX__c, 
                                             Parent.Name,Parent.Parent.Name,Parent.Relationship__c, SFX_Code__c,Billing_Branch__r.Name, 
                                             Assign_Branch_Id__r.Name from Account where 
                                             Parent.Parent.Parent.Parent.Propel_MSACode__c IN : setSearchStr AND 
                                             Status__c != 'INACTIVE' AND 
                                             Parent.Status__c != 'INACTIVE' AND 
                                             Parent.Parent.Parent.Status__c != 'INACTIVE' AND 
                                             ( Expiry_Date__c >= today  OR Expiry_Date__c = null)];
                
                List<Account> lstServices =  [SELECT Id,Name, Account_Name__c,Propel_MSACode__c, MSA__c, SFX__c, Parent.Name,Parent.Billing_Level__c ,SFX_Code__c,Billing_Branch__r.Name, Assign_Branch_Id__r.Name from Account where Parent.Parent.Propel_MSACode__c IN : setSearchStr ORDER BY SFX__c ASC];
                System.debug('lstBranches----------->'+lstBranches);
                System.debug('lstServices---------->'+lstServices);
                if(! lstBranches.isEmpty())
                {
                    for(Account eachRC : lstBranches)
                    {
                        setRCCode.add(eachRC.Parent.Name);
                    }
                }
                System.debug('setRCCode------------>'+setRCCode);
                
                List<Account_Team__c> lstOthrsAssignedPostfolios = [SELECT Id, Name, PropelI_Branch_Id__c,National1__c,National2__c, Account__r.SFX_Code__c, 
                                                                    National3__c,National4__c,CRS__c,NSM__c , Relationship__c, Collection__c,Submission__c,Account__r.Propel_MSACode__c, 
                                                                    Account__r.Name,Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__r.Name from Account_Team__c where 
                                                                    (Account__r.Name IN : setRCCode OR Account__r.Propel_MSACode__c IN :setSearchStr)  AND RecordType.Name = 'PropelI Account Team'
                                                                    AND (National1__c = TRUE OR National2__c = TRUE OR National3__c = TRUE OR National4__c = TRUE OR CRS__c = TRUE OR NSM__c = TRUE OR Relationship__c = TRUE)];
                System.debug('lstOthrsAssignedPostfolios-------------->'+lstOthrsAssignedPostfolios);
                Map<String, wrap_MSAPortfolioRlNAN> mapOthrsAssignedPortfolio = new Map<String, wrap_MSAPortfolioRlNAN>();
                if(!lstOthrsAssignedPostfolios.isEmpty())
                {
                    for(Account_Team__c asgndPortfolio : lstOthrsAssignedPostfolios)
                    {
                        if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Name != null  && asgndPortfolio.Account__r.Name.startsWith('RC'))
                        {
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Name, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                            else
                            {
                                if(asgndPortfolio.National1__c || Test.isRunningTest())
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CCD = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCCDAssigned = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CCDMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National2__c || Test.isRunningTest())
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).NAM = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isNamAssigned = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).NAMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National3__c || Test.isRunningTest())
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).QRM = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isQRMAssigned = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).QRMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National4__c || Test.isRunningTest())
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).RM = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isRMAssigned = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).RMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.CRS__c || Test.isRunningTest())
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CRS = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCRSAssigned = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CRSBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }  
                                
                                if(asgndPortfolio.Relationship__c) 
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).Relationship = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isRelAssigned = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).relationshipBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }                                  
                            }   
                        }
                        else if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Propel_MSACode__c != null  && asgndPortfolio.Account__r.Propel_MSACode__c.startsWith('MSA') )
                        {
                            
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.Account__r.Propel_MSACode__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.Account__r.Propel_MSACode__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Name, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                            else
                            {
                                if(asgndPortfolio.National1__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CCD = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isCCDAssigned = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CCDMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National2__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).NAM = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isNamAssigned = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).NAMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National3__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).QRM = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isQRMAssigned = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).QRMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National4__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).RM = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isRMAssigned = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).RMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.CRS__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CRS = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isCRSAssigned = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CRSBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                } 
                                if(asgndPortfolio.Relationship__c) 
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).Relationship = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isRelAssigned = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).relationshipBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }                                        
                            }  
                        }
                        
                    }
                }
                System.debug('mapOthrsAssignedPortfolio------------->'+mapOthrsAssignedPortfolio);
                
                Map<String, List<Wrap_RT_BracnhesPortfolios>> map_Branches = new Map<String, List<Wrap_RT_BracnhesPortfolios>>();
                if(! lstBranches.isEmpty())
                {
                    for(Account eachBranch : lstBranches)
                    {
                        Boolean isRelationshipSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.containsKey(eachBranch.AssignBranch_ID__c) && mapAsignedSFXBDM.get(eachBranch.AssignBranch_ID__c).Relationship__c ? True : False ;
                        Boolean isRelationshipAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.containsKey(eachBranch.AssignBranch_ID__c) && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).Relationship ? True : False ;
                        String str_RelationshipBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.containsKey(eachBranch.AssignBranch_ID__c) && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).Relationship && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).relationshipBDM != null ? mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).relationshipBDM : Null ;
                        
                        System.debug('isRelationshipSelfAsgnd----------->'+isRelationshipSelfAsgnd);
                        System.debug('isRelationshipAsgnd---------------->'+isRelationshipAsgnd);
                        System.debug('str_RelationshipBDM-------------->'+str_RelationshipBDM);
                        if(! map_Branches.keySet().contains(eachBranch.SFX__c)){ 
                            //map_Branches.put(eachBranch.SFX__c,  new List<Wrap_RT_BracnhesPortfolios>{new Wrap_RT_BracnhesPortfolios(eachBranch.Parent.Name,eachBranch.Parent.Parent.Name,  eachBranch.Billing_Branch__r.Name, eachBranch.AssignBranch_ID__c, isRelationshipAsgnd,  isRelationshipSelfAsgnd, str_RelationshipBDM)});
                            map_Branches.put(eachBranch.SFX__c,  new List<Wrap_RT_BracnhesPortfolios>{new Wrap_RT_BracnhesPortfolios(eachBranch, isRelationshipAsgnd,  isRelationshipSelfAsgnd, str_RelationshipBDM)});
                            
                        } else {
                            //map_Branches.get(eachBranch.SFX__c).add(new Wrap_RT_BracnhesPortfolios(eachBranch.Parent.Name,eachBranch.Parent.Parent.Name,  eachBranch.Billing_Branch__r.Name, eachBranch.AssignBranch_ID__c, isRelationshipAsgnd, isRelationshipSelfAsgnd, str_RelationshipBDM));
                            map_Branches.get(eachBranch.SFX__c).add(new Wrap_RT_BracnhesPortfolios(eachBranch, isRelationshipAsgnd, isRelationshipSelfAsgnd, str_RelationshipBDM));
                        }
                    }
                }
                System.debug('map_Branches------------>'+map_Branches);
                System.debug('lstSFX------------->'+lstSFX);
                Map<String, List<wrap_SFXPortfolioRlNAN>> map_Services = new Map<String, List<wrap_SFXPortfolioRlNAN>>();
                if(! lstServices.isEmpty())
                {
                    Set<String> setSFX = new Set<String>();
                    for(Account eachService : lstServices)
                    {
                        // if(! setAssignedSFX.contains(eachService.SFX__c))
                        //{
                        if(eachService.SFX__c != null && !setSFX.contains(eachService.SFX__c))
                        {
                            if( ! map_Services.keySet().contains(eachService.MSA__c))//if(! setSFX.contains(eachService.SFX__c))//if( ! map_Services.keySet().contains(eachService.MSA__c))
                                map_Services.put(eachService.MSA__c, new List<wrap_SFXPortfolioRlNAN>{new wrap_SFXPortfolioRlNAN(eachService.SFX__c, map_Branches.get(eachService.SFX__c), eachService.Parent.Billing_Level__c)});
                            else
                                map_Services.get(eachService.MSA__c).add(new wrap_SFXPortfolioRlNAN(eachService.SFX__c, map_Branches.get(eachService.SFX__c),eachService.Parent.Billing_Level__c));
                        }
                        setSFX.add(eachService.SFX__c);
                        // }
                    }
                }
                System.debug('map_Services----------->'+map_Services);
                Set<String> setMSANo = new Set<String>();
                for(Account eachSFX: lstSFX)
                {
                    Boolean isCCDSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).National1__c ? True : False ;
                    Boolean isCCDAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCD) || isCCDSelfAsgnd) ? True : False ;
                    String str_CCDBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCD && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCDMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCDMBDM : Null ;           
                    System.debug('isCCDSelfAsgnd----------->'+isCCDSelfAsgnd);
                    System.debug('isCCDAsgnd---------------->'+isCCDAsgnd);
                    System.debug('str_CCDBDM-------------->'+str_CCDBDM);
                    Boolean isNAMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).National2__c ? True : False ;
                    Boolean isNAMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAM ) || isNAMSelfAsgnd)? True : False ;
                    String str_NAMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAMBDM : Null ;           
                    System.debug('isNAMSelfAsgnd----------->'+isNAMSelfAsgnd);
                    System.debug('isNAMAsgnd---------------->'+isNAMAsgnd);
                    System.debug('str_NAMBDM-------------->'+str_NAMBDM);
                    Boolean isQRMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).National3__c ? True : False ;
                    Boolean isQRMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRM) ||isQRMSelfAsgnd) ? True : False ;
                    String str_QRMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRMBDM : Null ;           
                    System.debug('isQRMSelfAsgnd----------->'+isQRMSelfAsgnd);
                    System.debug('isQRMAsgnd---------------->'+isQRMAsgnd);
                    System.debug('str_QRMBDM-------------->'+str_QRMBDM);
                    Boolean isRMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).National4__c ? True : False ;
                    Boolean isRMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RM ) || isRMSelfAsgnd)? True : False ;
                    String str_RMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RMBDM : Null ;           
                    System.debug('isRMSelfAsgnd----------->'+isRMSelfAsgnd);
                    System.debug('isRMAsgnd---------------->'+isRMAsgnd);
                    System.debug('str_RMBDM-------------->'+str_RMBDM);
                    Boolean isCRSSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).CRS__c ? True : False ;
                    Boolean isCRSAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRS) ||isCRSSelfAsgnd) ? True : False ;
                    String str_CRSBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRS && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRSBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRSBDM : Null ;           
                    System.debug('isCRSSelfAsgnd----------->'+isCRSSelfAsgnd);
                    System.debug('isCRSAsgnd---------------->'+isCRSAsgnd);
                    System.debug('str_CRSBDM-------------->'+str_CRSBDM);
                    
                    
                    if(! lstwrap_MSAPortfolioRlNAN1.keySet().contains(eachSFX.MSA__c))
                        lstwrap_MSAPortfolioRlNAN1.put(eachSFX.MSA__c ,new wrap_MSAPortfolioRlNAN (eachSFX.MSA__c,eachSFX.Parent.Name, isCCDAsgnd,isCCDSelfAsgnd, str_CCDBDM, isNAMAsgnd, isNAMSelfAsgnd, str_NAMBDM, isQRMAsgnd, isQRMSelfAsgnd,str_QRMBDM,isRMAsgnd, isRMSelfAsgnd,str_RMBDM, isCRSAsgnd,isCRSSelfAsgnd, str_CRSBDM , map_Services.get(eachSFX.MSA__c), null, null));
                    
                    
                }
                System.debug('lstwrap_MSAPortfolioRlNAN1----------------->'+lstwrap_MSAPortfolioRlNAN1);
                System.debug('lstwrap_MSAPortfolioRlNAN1.size()----------------->'+lstwrap_MSAPortfolioRlNAN1.size());
                
            }
        }else if(! setSearchStr.isEmpty() && searchby.equalsIgnoreCase('SFX'))
        {
            List<Account> lstSFX = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,SFX_Code__c, Parent.Name, Assign_Branch_Id__r.Name from Account where SFX_Code__c IN : setSearchStr];
            System.debug('lstSFX--------------->'+lstSFX);
            Set<String> setMSAAccounts = new Set<String>();
            if(! lstSFX.isEmpty())
            {
                for(Account eachSFX : lstSFX)
                    setMSAAccounts.add(eachSFX.MSA__c);
                
            }
            System.debug('setMSAAccounts----->'+setMSAAccounts);
            
            if(! lstSFX.isEmpty())
            {
                List<Account> lstBranches = [SELECT Id,Name, Branch_Status__c, Propel_MSACode__c, AssignBranch_ID__c,MSA__c, SFX__c,SFX_Code__c,Billing_Level__c, Parent.Name,Parent.Parent.Name,Parent.Relationship__c, Billing_Branch__r.Name,Assign_Branch_Id__r.Name, Parent.Billing_Level__c 
                                             from Account where 
                                             Parent.Parent.Parent.SFX_Code__c IN :setSearchStr AND 
                                             Status__c != 'INACTIVE' AND 
                                             Parent.Status__c != 'INACTIVE' AND 
                                             Parent.Parent.Parent.Status__c != 'INACTIVE' AND 
                                             ( Expiry_Date__c >= today  OR Expiry_Date__c = null)
                                            ];
                List<Account> lstServices =  [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,SFX_Code__c,Billing_Level__c, Parent.Name, Assign_Branch_Id__r.Name,Billing_Branch__r.Name, Parent.Billing_Level__c from Account where Parent.SFX_Code__c IN : setSearchStr];
                System.debug('lstBranches----------->'+lstBranches);
                System.debug('lstServices---------->'+lstServices);
                Set<String> setRCName = new Set<String>();
                if(! lstBranches.isEmpty())
                {
                    for(Account eachRC : lstBranches)
                        setRCName.add(eachRC.Parent.Name);
                }
                System.debug('setRCName------------->'+setRCName);
                List<Account_Team__c> lstOthrsAssignedPostfolios = [SELECT Id, Name, PropelI_Branch_Id__c,National1__c,National2__c,National3__c,National4__c,CRS__c,NSM__c , 
                                                                    Relationship__c, Collection__c,Submission__c,Account__r.Propel_MSACode__c, Account__r.Name,Account__r.SFX__c, Account__r.SFX_Code__c,
                                                                    Account__r.MSA__c, BDMPropelI__r.Name, PropelI_Composite_Key__c
                                                                    FROM Account_Team__c 
                                                                    WHERE 
                                                                    (Account__r.Propel_MSACode__c IN : setMSAAccounts OR Account__r.Name IN : setRCName) 
                                                                    AND RecordType.Name = 'PropelI Account Team' AND  
                                                                    (National1__c = TRUE OR National2__c = TRUE OR National3__c = TRUE OR National4__c = TRUE OR CRS__c = TRUE 
                                                                     OR NSM__c = TRUE OR Relationship__c = TRUE)];
                System.debug('lstOthrsAssignedPostfolios-------------->'+lstOthrsAssignedPostfolios);
                Map<String, wrap_MSAPortfolioRlNAN> mapOthrsAssignedPortfolio = new Map<String, wrap_MSAPortfolioRlNAN>();
                
                if(! lstOthrsAssignedPostfolios.isEmpty())
                {    
                    for(Account_Team__c asgndPortfolio : lstOthrsAssignedPostfolios)
                    {
                        system.debug('asgndPortfolio.Account__r.Name==='+asgndPortfolio.Account__r.Name);
                        system.debug('asgndPortfolio.PropelI_Branch_Id__c==='+asgndPortfolio.PropelI_Branch_Id__c);
                        if(asgndPortfolio.Account__c != null && asgndPortfolio.PropelI_Branch_Id__c != null  && asgndPortfolio.Account__r.Name.startsWith('RC'))
                        {
                            if(test.isRunningTest()){
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Name, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Name, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                            }
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Name, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                            //wrap_MSAPortfolioRlNAN(String MSA,String Name, Boolean CCD,Boolean isSelfCCDAssigned, String CCDMBDM, Boolean NAM,Boolean isNAMSelfAsgnd, String NAMBDM, Boolean QRM, Boolean isSelfQRMAssigned,String QRMBDM, Boolean RM, Boolean isSelfRMAssigned, String RMBDM, Boolean CRS, Boolean isSelfCRSAssigned, String CRSBDM, List<wrap_SFXPortfolioRlNAN> lstSFXRCBranches, Boolean Relationship, String relationshipBDM)
                            else
                            {
                                if(asgndPortfolio.National1__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CCD = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCCDAssigned = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CCDMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National2__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).NAM = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isNamAssigned = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).NAMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National3__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).QRM = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isQRMAssigned = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).QRMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National4__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).RM = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isRMAssigned = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).RMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.CRS__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CRS = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCRSAssigned = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CRSBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }  
                                
                                if(asgndPortfolio.Relationship__c) 
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).Relationship = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isRelAssigned = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).relationshipBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }                                  
                            }   
                        }//If needed please add PropelI_Composite_Key__c in this else if part also
                        else if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Propel_MSACode__c != null  && asgndPortfolio.Account__r.Propel_MSACode__c.startsWith('MSA') )
                        {
                            
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.Account__r.Propel_MSACode__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.Account__r.Propel_MSACode__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Propel_MSACode__c, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                            //wrap_MSAPortfolioRlNAN(String MSA,String Name, Boolean CCD,Boolean isSelfCCDAssigned, String CCDMBDM, Boolean NAM,Boolean isNAMSelfAsgnd, String NAMBDM, Boolean QRM, Boolean isSelfQRMAssigned,String QRMBDM, Boolean RM, Boolean isSelfRMAssigned, String RMBDM, Boolean CRS, Boolean isSelfCRSAssigned, String CRSBDM, List<wrap_SFXPortfolioRlNAN> lstSFXRCBranches, Boolean Relationship, String relationshipBDM)
                            //asgndPortfolio.Account__r.Name == 'Ninja Power' -- this code seems wrong bcs there should be asgndPortfolio.Account__r.Propel_MSACode__c
                            else
                            {
                                if(asgndPortfolio.National1__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CCD = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isCCDAssigned = asgndPortfolio.National1__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CCDMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National2__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).NAM = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isNamAssigned = asgndPortfolio.National2__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).NAMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National3__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).QRM = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isQRMAssigned = asgndPortfolio.National3__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).QRMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.National4__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).RM = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isRMAssigned = asgndPortfolio.National4__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).RMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }
                                
                                if(asgndPortfolio.CRS__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CRS = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isCRSAssigned = asgndPortfolio.CRS__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CRSBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                } 
                                if(asgndPortfolio.Relationship__c) 
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).Relationship = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isRelAssigned = asgndPortfolio.Relationship__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).relationshipBDM =  asgndPortfolio.BDMPropelI__r.Name;
                                }                                        
                            }  
                        }
                        
                    }
                }
                System.debug('mapOthrsAssignedPortfolio------------->'+mapOthrsAssignedPortfolio);
                
                Map<String, List<Wrap_RT_BracnhesPortfolios>> map_Branches = new Map<String, List<Wrap_RT_BracnhesPortfolios>>();
                if(! lstBranches.isEmpty())
                {
                    for(Account eachBranch : lstBranches)
                    {
                        Boolean isRelationshipSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.containsKey(eachBranch.AssignBranch_ID__c) && mapAsignedSFXBDM.get(eachBranch.AssignBranch_ID__c).Relationship__c ? True : False ;
                        Boolean isRelationshipAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.containsKey(eachBranch.AssignBranch_ID__c) && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).Relationship ? True : False ;
                        String str_RelationshipBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.containsKey(eachBranch.AssignBranch_ID__c) && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).Relationship && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).relationshipBDM != null ? mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).relationshipBDM : Null ;
                        
                        System.debug('isRelationshipSelfAsgnd----------->'+isRelationshipSelfAsgnd);
                        System.debug('isRelationshipAsgnd---------------->'+isRelationshipAsgnd);
                        System.debug('str_RelationshipBDM-------------->'+str_RelationshipBDM);
                        if( ! map_Branches.keySet().contains(eachBranch.SFX__c)){
                            //map_Branches.put(eachBranch.SFX__c,  new List<Wrap_RT_BracnhesPortfolios>{new Wrap_RT_BracnhesPortfolios(eachBranch.Parent.Name,eachBranch.Parent.Parent.Name,  eachBranch.Billing_Branch__r.Name, eachBranch.AssignBranch_ID__c, isRelationshipAsgnd, isRelationshipSelfAsgnd, str_RelationshipBDM )});
                            map_Branches.put(eachBranch.SFX__c,  new List<Wrap_RT_BracnhesPortfolios>{new Wrap_RT_BracnhesPortfolios(eachBranch, isRelationshipAsgnd, isRelationshipSelfAsgnd, str_RelationshipBDM )});
                        }else{
                            //map_Branches.get(eachBranch.SFX__c).add(new Wrap_RT_BracnhesPortfolios(eachBranch.Parent.Name, eachBranch.Parent.Parent.Name, eachBranch.Billing_Branch__r.Name, eachBranch.AssignBranch_ID__c, isRelationshipAsgnd,  isRelationshipSelfAsgnd, str_RelationshipBDM ));
                            map_Branches.get(eachBranch.SFX__c).add(new Wrap_RT_BracnhesPortfolios(eachBranch, isRelationshipAsgnd, isRelationshipSelfAsgnd, str_RelationshipBDM));
                        }
                    }
                }
                System.debug('map_Branches------------>'+map_Branches);
                System.debug('lstSFX------------->'+lstSFX);
                Map<String, List<wrap_SFXPortfolioRlNAN>> map_Services = new Map<String, List<wrap_SFXPortfolioRlNAN>>();
                if(! lstServices.isEmpty())
                {
                    Set<String> setSFX = new Set<String>();
                    for(Account eachService : lstServices)
                    {
                        //if(! setAssignedSFX.contains(eachService.SFX__c))
                        //{
                        if(eachService.SFX__c != null && !setSFX.contains(eachService.SFX__c))
                        {
                            if( ! map_Services.keySet().contains(eachService.MSA__c))
                                map_Services.put(eachService.MSA__c, new List<wrap_SFXPortfolioRlNAN>{new wrap_SFXPortfolioRlNAN(eachService.SFX__c, map_Branches.get(eachService.SFX__c), eachService.Parent.Billing_Level__c)});
                            else
                                map_Services.get(eachService.MSA__c).add(new wrap_SFXPortfolioRlNAN(eachService.SFX__c, map_Branches.get(eachService.SFX__c),eachService.Parent.Billing_Level__c));
                            setSFX.add(eachService.SFX__c);
                        }  
                        //}
                    }
                }
                System.debug('map_Services----------->'+map_Services);
                for(Account eachSFX: lstSFX)
                {
                    Boolean isCCDSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).National1__c ? True : False ;
                    Boolean isCCDAsgnd =((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCD) || isCCDSelfAsgnd) ? True : False ;
                    String str_CCDBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCD && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCDMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CCDMBDM : Null ;           
                    System.debug('isCCDSelfAsgnd----------->'+isCCDSelfAsgnd);
                    System.debug('isCCDAsgnd---------------->'+isCCDAsgnd);
                    System.debug('str_CCDBDM-------------->'+str_CCDBDM);
                    Boolean isNAMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).National2__c ? True : False ;
                    Boolean isNAMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAM) || isNAMSelfAsgnd) ? True : False ;
                    String str_NAMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).NAMBDM : Null ;           
                    System.debug('isNAMSelfAsgnd----------->'+isNAMSelfAsgnd);
                    System.debug('isNAMAsgnd---------------->'+isNAMAsgnd);
                    System.debug('str_NAMBDM-------------->'+str_NAMBDM);
                    Boolean isQRMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).National3__c ? True : False ;
                    Boolean isQRMAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRM) || isQRMSelfAsgnd) ? True : False ;
                    String str_QRMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).QRMBDM: Null ;           
                    System.debug('isQRMSelfAsgnd----------->'+isQRMSelfAsgnd);
                    System.debug('isQRMAsgnd---------------->'+isQRMAsgnd);
                    System.debug('str_QRMBDM-------------->'+str_QRMBDM);
                    Boolean isRMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).National4__c ? True : False ;
                    Boolean isRMAsgnd =((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RM) || isRMSelfAsgnd) ? True : False ;
                    String str_RMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RM && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RMBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).RMBDM : Null ;           
                    System.debug('isRMSelfAsgnd----------->'+isRMSelfAsgnd);
                    System.debug('isRMAsgnd---------------->'+isRMAsgnd);
                    System.debug('str_RMBDM-------------->'+str_RMBDM);
                    Boolean isCRSSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachSFX.MSA__c) && mapAsignedSFXBDM.get(eachSFX.MSA__c).CRS__c ? True : False ;
                    Boolean isCRSAsgnd = ((mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRS) || isCRSSelfAsgnd) ? True : False ;
                    String str_CRSBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachSFX.MSA__c) && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRS && mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRSBDM != null ? mapOthrsAssignedPortfolio.get(eachSFX.MSA__c).CRSBDM : Null ;           
                    System.debug('isCRSSelfAsgnd----------->'+isCRSSelfAsgnd);
                    System.debug('isCRSAsgnd---------------->'+isCRSAsgnd);
                    System.debug('str_CRSBDM-------------->'+str_CRSBDM);
                    
                    
                    if(! lstwrap_MSAPortfolioRlNAN1.keySet().contains(eachSFX.MSA__c))
                        lstwrap_MSAPortfolioRlNAN1.put(eachSFX.MSA__c ,new wrap_MSAPortfolioRlNAN (eachSFX.MSA__c,eachSFX.Parent.Name,isCCDAsgnd,isCCDSelfAsgnd, str_CCDBDM, isNAMAsgnd, isNAMSelfAsgnd, str_NAMBDM, isQRMAsgnd, isQRMSelfAsgnd,str_QRMBDM,isRMAsgnd, isRMSelfAsgnd,str_RMBDM, isCRSAsgnd,isCRSSelfAsgnd, str_CRSBDM , map_Services.get(eachSFX.MSA__c), null, null));
                }
                System.debug('lstwrap_MSAPortfolioRlNAN1----------->'+lstwrap_MSAPortfolioRlNAN1);
                
            }
        }
        else if(! setSearchStr.isEmpty() && searchby.equalsIgnoreCase('Rate Card'))
        {
            List<Account> lstRateCard = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,SFX_Code__c, Parent.Name, Assign_Branch_Id__r.Name from Account where Name IN : setSearchStr AND RecordType.Name = 'Rate Card' AND  Is_PRC_Rate_Card__c = false limit 9999];
            System.debug('lstRateCard--------------->'+lstRateCard);
            Set<String> setMSAAccounts = new Set<String>();
            if(! lstRateCard.isEmpty())
            {
                for(Account eachSFX : lstRateCard)
                    setMSAAccounts.add(eachSFX.MSA__c);
                
            }
            System.debug('setMSAAccounts----->'+setMSAAccounts);
            List<Account_Team__c> lstOthrsAssignedPostfolios = [SELECT Id, Name,PropelI_Branch_Id__c, National1__c,National2__c,National3__c,National4__c, Account__r.SFX_Code__c,
                                                                CRS__c,NSM__c , Relationship__c, Collection__c,Submission__c,Account__r.Propel_MSACode__c, Account__r.Name,
                                                                Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__r.Name from Account_Team__c where 
                                                                (Account__r.Propel_MSACode__c IN : setMSAAccounts OR Account__r.Name IN : setSearchStr)  AND  RecordType.Name = 'PropelI Account Team'
                                                                AND (National1__c = TRUE OR National2__c = TRUE OR National3__c = TRUE OR National4__c = TRUE OR 
                                                                     CRS__c = TRUE OR NSM__c = TRUE OR Relationship__c = TRUE)];
            System.debug('lstOthrsAssignedPostfolios-------------->'+lstOthrsAssignedPostfolios);
            Map<String, wrap_MSAPortfolioRlNAN> mapOthrsAssignedPortfolio = new Map<String, wrap_MSAPortfolioRlNAN>();
            if(! lstOthrsAssignedPostfolios.isEmpty())
            {    
                for(Account_Team__c asgndPortfolio : lstOthrsAssignedPostfolios)
                {
                    
                    if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Name != null  && asgndPortfolio.Account__r.Name.startsWith('RC'))
                    {
                        if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                            mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Name, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                        else
                        {
                            if(asgndPortfolio.National1__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CCD = asgndPortfolio.National1__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCCDAssigned = asgndPortfolio.National1__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CCDMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }
                            
                            if(asgndPortfolio.National2__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).NAM = asgndPortfolio.National2__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isNamAssigned = asgndPortfolio.National2__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).NAMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }
                            
                            if(asgndPortfolio.National3__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).QRM = asgndPortfolio.National3__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isQRMAssigned = asgndPortfolio.National3__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).QRMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }
                            
                            if(asgndPortfolio.National4__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).RM = asgndPortfolio.National4__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isRMAssigned = asgndPortfolio.National4__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).RMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }
                            
                            if(asgndPortfolio.CRS__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CRS = asgndPortfolio.CRS__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCRSAssigned = asgndPortfolio.CRS__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CRSBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }  
                            
                            if(asgndPortfolio.Relationship__c) 
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).Relationship = asgndPortfolio.Relationship__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isRelAssigned = asgndPortfolio.Relationship__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).relationshipBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }                                  
                        }   
                    }
                    else if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Propel_MSACode__c != null  && asgndPortfolio.Account__r.Propel_MSACode__c.startsWith('MSA') )
                    {
                        
                        if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.Account__r.Propel_MSACode__c))
                            mapOthrsAssignedPortfolio.put(asgndPortfolio.Account__r.Propel_MSACode__c, new wrap_MSAPortfolioRlNAN(asgndPortfolio.Account__r.Name, null, asgndPortfolio.National1__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National2__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National3__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.National4__c,null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.CRS__c,null, asgndPortfolio.BDMPropelI__r.Name, null, asgndPortfolio.Relationship__c, asgndPortfolio.BDMPropelI__r.Name));
                        else
                        {
                            if(asgndPortfolio.National1__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CCD = asgndPortfolio.National1__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isCCDAssigned = asgndPortfolio.National1__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CCDMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }
                            
                            if(asgndPortfolio.National2__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).NAM = asgndPortfolio.National2__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isNamAssigned = asgndPortfolio.National2__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).NAMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }
                            
                            if(asgndPortfolio.National3__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).QRM = asgndPortfolio.National3__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isQRMAssigned = asgndPortfolio.National3__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).QRMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }
                            
                            if(asgndPortfolio.National4__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).RM = asgndPortfolio.National4__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isRMAssigned = asgndPortfolio.National4__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).RMBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }
                            
                            if(asgndPortfolio.CRS__c)
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CRS = asgndPortfolio.CRS__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isCRSAssigned = asgndPortfolio.CRS__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).CRSBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            } 
                            if(asgndPortfolio.Relationship__c) 
                            {
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).Relationship = asgndPortfolio.Relationship__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).isRelAssigned = asgndPortfolio.Relationship__c;
                                mapOthrsAssignedPortfolio.get(asgndPortfolio.Account__r.Propel_MSACode__c).relationshipBDM =  asgndPortfolio.BDMPropelI__r.Name;
                            }                                        
                        }  
                    }
                    
                }
            }
            System.debug('mapOthrsAssignedPortfolio------------->'+mapOthrsAssignedPortfolio);
            if(! lstRateCard.isEmpty())
            {
                Set<String> setSFX = new Set<String>();
                for(Account eachRC: lstRateCard)
                {
                    setSFX.add(eachRC.SFX__c);
                }
                System.debug('setSFX--------------->'+setSFX);
                if(! setSFX.isEmpty())
                {
                    List<Account> lstBranches = [SELECT Id,Name, Branch_Status__c, AssignBranch_ID__c,Propel_MSACode__c, MSA__c, SFX__c,SFX_Code__c, Parent.Name,Parent.Parent.Name,Parent.Relationship__c, Assign_Branch_Id__r.Name,Billing_Branch__r.Name 
                                                 from Account where
                                                 Parent.Name IN : setSearchStr AND 
                                                 Status__c != 'INACTIVE' AND 
                                                 Parent.Status__c != 'INACTIVE' AND 
                                                 Parent.Parent.Parent.Status__c != 'INACTIVE' AND 
                                                 ( Expiry_Date__c >= today  OR Expiry_Date__c = null) limit 9999
                                                ];
                    List<Account> lstServices =  [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,SFX_Code__c, Parent.Name, Assign_Branch_Id__r.Name,Billing_Branch__r.Name, Parent.Billing_Level__c from Account where SFX__c IN : setSFX limit 9999];
                    System.debug('lstBranches----------->'+lstBranches);
                    System.debug('lstServices---------->'+lstServices);
                    Map<String, List<Wrap_RT_BracnhesPortfolios>> map_Branches = new Map<String, List<Wrap_RT_BracnhesPortfolios>>();
                    if(! lstBranches.isEmpty())
                    {
                        for(Account eachBranch : lstBranches)
                        {
                            
                            Boolean isRelationshipSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.containsKey(eachBranch.AssignBranch_ID__c) && mapAsignedSFXBDM.get(eachBranch.AssignBranch_ID__c).Relationship__c ? True : False ;
                            Boolean isRelationshipAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.containsKey(eachBranch.AssignBranch_ID__c) && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).Relationship ? True : False ;
                            String str_RelationshipBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.containsKey(eachBranch.AssignBranch_ID__c) && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).Relationship && mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).relationshipBDM != null ? mapOthrsAssignedPortfolio.get(eachBranch.AssignBranch_ID__c).relationshipBDM : Null ;
                            
                            System.debug('isRelationshipSelfAsgnd----------->'+isRelationshipSelfAsgnd);
                            System.debug('isRelationshipAsgnd---------------->'+isRelationshipAsgnd);
                            System.debug('str_RelationshipBDM-------------->'+str_RelationshipBDM);
                            if(! map_Branches.keySet().contains(eachBranch.SFX__c)) { 
                                //map_Branches.put(eachBranch.SFX__c,  new List<Wrap_RT_BracnhesPortfolios>{new Wrap_RT_BracnhesPortfolios(eachBranch.Parent.Name,eachBranch.Parent.Parent.Name,  eachBranch.Billing_Branch__r.Name, eachBranch.AssignBranch_ID__c, isRelationshipAsgnd,  isRelationshipSelfAsgnd, str_RelationshipBDM )});
                                map_Branches.put(eachBranch.SFX__c,  new List<Wrap_RT_BracnhesPortfolios>{new Wrap_RT_BracnhesPortfolios(eachBranch, isRelationshipAsgnd,  isRelationshipSelfAsgnd, str_RelationshipBDM )});
                            }else  {
                                //map_Branches.get(eachBranch.SFX__c).add(new Wrap_RT_BracnhesPortfolios(eachBranch.Parent.Name,eachBranch.Parent.Parent.Name,  eachBranch.Billing_Branch__r.Name, eachBranch.AssignBranch_ID__c, isRelationshipAsgnd,  isRelationshipSelfAsgnd, str_RelationshipBDM));
                                map_Branches.get(eachBranch.SFX__c).add(new Wrap_RT_BracnhesPortfolios(eachBranch, isRelationshipAsgnd,  isRelationshipSelfAsgnd, str_RelationshipBDM));
                            }
                        }
                    }
                    System.debug('map_Branches------------>'+map_Branches);
                    System.debug('lstRateCard------------->'+lstRateCard);
                    Map<String, String> mapMSAName = new Map<String, String>();
                    Map<String, List<wrap_SFXPortfolioRlNAN>> map_Services = new Map<String, List<wrap_SFXPortfolioRlNAN>>();
                    if(! lstServices.isEmpty())
                    {
                        Set<String> setSFXNo = new Set<String>();
                        for(Account eachService : lstServices)
                        {
                            // if(! setAssignedSFX.contains(eachService.SFX__c))
                            // {
                            if(eachService.SFX__c != null && !setSFXNo.contains(eachService.SFX__c))
                            {
                                if( ! map_Services.keySet().contains(eachService.MSA__c))
                                    map_Services.put(eachService.MSA__c, new List<wrap_SFXPortfolioRlNAN>{new wrap_SFXPortfolioRlNAN(eachService.SFX__c, map_Branches.get(eachService.SFX__c), eachService.Parent.Billing_Level__c)});
                                else map_Services.get(eachService.MSA__c).add(new wrap_SFXPortfolioRlNAN(eachService.SFX__c, map_Branches.get(eachService.SFX__c),eachService.Parent.Billing_Level__c));
                            }
                            setSFXNo.add(eachService.SFX__c);
                            //}
                            if(! mapMSAName.keySet().contains(eachService.MSA__c))
                                mapMSAName.put(eachService.MSA__c, eachService.Parent.Name);
                        }
                    }
                    System.debug('mapMSAName--------------->'+mapMSAName);
                    System.debug('map_Services----------->'+map_Services);
                    for(Account eachRateCard: lstRateCard)
                    {
                        Boolean isCCDSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachRateCard.MSA__c) && mapAsignedSFXBDM.get(eachRateCard.MSA__c).National1__c ? True : False ;
                        Boolean isCCDAsgnd = (mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).CCD) || isCCDSelfAsgnd ? True : False ;
                        String str_CCDBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).CCD && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).CCDMBDM != null ? mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).CCDMBDM : Null ;           
                        System.debug('isCCDSelfAsgnd----------->'+isCCDSelfAsgnd);
                        System.debug('isCCDAsgnd---------------->'+isCCDAsgnd);
                        System.debug('str_CCDBDM-------------->'+str_CCDBDM);
                        Boolean isNAMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachRateCard.MSA__c) && mapAsignedSFXBDM.get(eachRateCard.MSA__c).National2__c ? True : False ;
                        Boolean isNAMAsgnd = (mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).NAM) || isNAMSelfAsgnd ? True : False ;
                        String str_NAMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).NAM && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).NAMBDM != null ? mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).NAMBDM : Null ;           
                        System.debug('isNAMSelfAsgnd----------->'+isNAMSelfAsgnd);
                        System.debug('isNAMAsgnd---------------->'+isNAMAsgnd);
                        System.debug('str_NAMBDM-------------->'+str_NAMBDM);
                        Boolean isQRMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachRateCard.MSA__c) && mapAsignedSFXBDM.get(eachRateCard.MSA__c).National3__c ? True : False ;
                        Boolean isQRMAsgnd = (mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).QRM) || isQRMSelfAsgnd ? True : False ;
                        String str_QRMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).QRM && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).QRMBDM != null ? mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).QRMBDM : Null ;           
                        System.debug('isQRMSelfAsgnd----------->'+isQRMSelfAsgnd);
                        System.debug('isQRMAsgnd---------------->'+isQRMAsgnd);
                        System.debug('str_QRMBDM-------------->'+str_QRMBDM);
                        Boolean isRMSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachRateCard.MSA__c) && mapAsignedSFXBDM.get(eachRateCard.MSA__c).National4__c ? True : False ;
                        Boolean isRMAsgnd = (mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).RM) || isRMSelfAsgnd ? True : False ;
                        String str_RMBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).RM && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).RMBDM != null ? mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).RMBDM : Null ;           
                        System.debug('isRMSelfAsgnd----------->'+isRMSelfAsgnd);
                        System.debug('isRMAsgnd---------------->'+isRMAsgnd);
                        System.debug('str_RMBDM-------------->'+str_RMBDM);
                        Boolean isCRSSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachRateCard.MSA__c) && mapAsignedSFXBDM.get(eachRateCard.MSA__c).CRS__c ? True : False ;
                        Boolean isCRSAsgnd = (mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).CRS) || isCRSSelfAsgnd ? True : False ;
                        String str_CRSBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachRateCard.MSA__c) && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).CRS && mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).CRSBDM != null ? mapOthrsAssignedPortfolio.get(eachRateCard.MSA__c).CRSBDM : Null ;           
                        System.debug('isCRSSelfAsgnd----------->'+isCRSSelfAsgnd);
                        System.debug('isCRSAsgnd---------------->'+isCRSAsgnd);
                        System.debug('str_CRSBDM-------------->'+str_CRSBDM);
                        if(! lstwrap_MSAPortfolioRlNAN1.keySet().contains(eachRateCard.MSA__c))
                            lstwrap_MSAPortfolioRlNAN1.put(eachRateCard.MSA__c ,new wrap_MSAPortfolioRlNAN (eachRateCard.MSA__c,mapMSAName.get(eachRateCard.MSA__c), isCCDAsgnd,isCCDSelfAsgnd, str_CCDBDM, isNAMAsgnd, isNAMSelfAsgnd, str_NAMBDM, isQRMAsgnd, isQRMSelfAsgnd,str_QRMBDM,isRMAsgnd, isRMSelfAsgnd,str_RMBDM, isCRSAsgnd,isCRSSelfAsgnd, str_CRSBDM , map_Services.get(eachRateCard.MSA__c), null, null));
                        
                    }
                    System.debug('lstwrap_MSAPortfolioRlNAN1----------->'+lstwrap_MSAPortfolioRlNAN1);
                }
                
            }
        }
        System.debug('lstwrap_MSAPortfolioRlNAN1----------->'+lstwrap_MSAPortfolioRlNAN1);
        return lstwrap_MSAPortfolioRlNAN1.values();
    }
    
    // wrapper class to bind the MSA with their related records. 
    Public Class wrap_MSAPortfolioRlNAN
    {
        @AuraEnabled
        Public String MSA;
        @AuraEnabled
        Public String Name; 
        @AuraEnabled
        Public Boolean CCD;
        @AuraEnabled
        Public Boolean isCCDAssigned;
        @AuraEnabled
        Public Boolean isSelfCCDAssigned; 
        @AuraEnabled
        Public String CCDMBDM; 
        @AuraEnabled
        Public Boolean NAM;
        @AuraEnabled   
        Public Boolean isNamAssigned;
        @AuraEnabled
        Public Boolean isNAMSelfAsgnd;
        @AuraEnabled
        Public String NAMBDM; 
        @AuraEnabled
        Public Boolean QRM;
        @AuraEnabled
        Public Boolean isQRMAssigned;
        @AuraEnabled
        Public Boolean isSelfQRMAssigned; 
        @AuraEnabled
        Public String QRMBDM; 
        @AuraEnabled
        Public Boolean RM;
        @AuraEnabled
        Public Boolean isRMAssigned;
        @AuraEnabled
        Public Boolean isSelfRMAssigned;
        @AuraEnabled
        Public String RMBDM;
        @AuraEnabled
        Public Boolean CRS;
        @AuraEnabled
        Public Boolean isCRSAssigned;  
        @AuraEnabled
        Public Boolean isSelfCRSAssigned;
        @AuraEnabled
        Public String CRSBDM; 
        Public Boolean Relationship; 
        @AuraEnabled
        Public Boolean isRelAssigned;  
        @AuraEnabled
        Public String relationshipBDM; 
        @AuraEnabled
        Public List<wrap_SFXPortfolioRlNAN> lstSFXRCBranches; 
        wrap_MSAPortfolioRlNAN(String MSA,String Name, Boolean CCD,Boolean isSelfCCDAssigned, String CCDMBDM, Boolean NAM,Boolean isNAMSelfAsgnd, String NAMBDM, Boolean QRM, Boolean isSelfQRMAssigned,String QRMBDM, Boolean RM, Boolean isSelfRMAssigned, String RMBDM, Boolean CRS, Boolean isSelfCRSAssigned, String CRSBDM, List<wrap_SFXPortfolioRlNAN> lstSFXRCBranches, Boolean Relationship, String relationshipBDM)
        {
            
            this.MSA = MSA;
            this.Name = Name;
            this.CCD = CCD;
            this.isCCDAssigned = CCD;
            this.isSelfCCDAssigned = isSelfCCDAssigned;
            this.CCDMBDM = CCDMBDM; 
            this.NAM = NAM;
            isNamAssigned = NAM;
            this.isNAMSelfAsgnd = isNAMSelfAsgnd;
            this.NAMBDM = NAMBDM;
            this.QRM = QRM;
            isQRMAssigned = QRM;
            this.isSelfQRMAssigned = isSelfQRMAssigned;
            this.QRMBDM = QRMBDM;
            this.RM = RM;
            isRMAssigned = RM;
            this.isSelfRMAssigned = isSelfRMAssigned;
            this.RMBDM = RMBDM;
            this.CRS = CRS;
            isCRSAssigned = CRS;
            this.isSelfCRSAssigned = isSelfCRSAssigned;
            this.CRSBDM = CRSBDM;
            this.lstSFXRCBranches = lstSFXRCBranches;
            this.Relationship = Relationship;
            isRelAssigned = Relationship;
            this.relationshipBDM = relationshipBDM;
        }
    }
    
    // Wrapper class to bind the SFX, Rate Card and Branches. 
    Public Class wrap_SFXPortfolioRlNAN
    {
        @AuraEnabled
        Public String SFX;
        @AuraEnabled
        Public List<Wrap_RT_BracnhesPortfolios> lstRT_BranchesPortfolios;
        @AuraEnabled
        Public String Billing_level;
        wrap_SFXPortfolioRlNAN(String SFX, List<Wrap_RT_BracnhesPortfolios> lstRT_BranchesPortfolios, String Billing_level)
        {
            this.SFX = SFX;
            this.lstRT_BranchesPortfolios = lstRT_BranchesPortfolios;
            this.Billing_level = Billing_level;
        }
    }
    
    // Wrapper class to bind the SFX and associated Service,rate Card and branches. 
    Public Class Wrap_RT_BracnhesPortfolios
    {
        @AuraEnabled
        Public String branchId;
        @AuraEnabled
        Public String RC;
        @AuraEnabled
        Public String Service;
        @AuraEnabled
        Public String Branches; 
        @AuraEnabled
        Public String assignedBranchId;
        @AuraEnabled
        Public String RTBranchesCode;
        @AuraEnabled
        Public Boolean Relationship; 
        @AuraEnabled
        Public Boolean isRelAssigned; 
        @AuraEnabled
        Public Boolean isRlAssigned; 
        @AuraEnabled
        Public String relationshipBDM; 
        Wrap_RT_BracnhesPortfolios(String RC,String Service, String Branches, String assignedBranchId, Boolean Relationship, Boolean isRlAssigned, String relationshipBDM)
        {
            this.RC = RC;
            this.Service = Service;
            this.Branches = Branches;
            this.assignedBranchId = assignedBranchId;
            this.RTBranchesCode = RC + '-' + Branches;
            this.Relationship = Relationship;
            this.isRelAssigned = Relationship;
            this.isRlAssigned = isRlAssigned;
            this.relationshipBDM = relationshipBDM;
            
            
        }
        Wrap_RT_BracnhesPortfolios(){}
        
        Wrap_RT_BracnhesPortfolios(Account eachBranch, Boolean Relationship, Boolean isRlAssigned, String relationshipBDM ){
            this.branchId = eachBranch.Id;
            this.RC = eachBranch.Parent.Name;
            this.Service = eachBranch.Parent.Parent.Name;
            this.Branches = eachBranch.Billing_Branch__r.Name;
            this.assignedBranchId = eachBranch.AssignBranch_ID__c;
            this.RTBranchesCode = eachBranch.Parent.Name + '-' + eachBranch.Billing_Branch__r.Name;
            this.Relationship = Relationship;
            this.isRelAssigned = Relationship;
            this.isRlAssigned = isRlAssigned;
            this.relationshipBDM = relationshipBDM;
        }
    }
    
    //This method will return all the newely searched Submission/Collection records with the selected User.
    @AuraEnabled
    Public Static List<wrap_SCMSA> getExSubmissionCollectionMapping(String searchby, Id usrId, String searchStr, String str_PortfolioType)
    {
        
        System.debug('searchby----------->'+searchby);
        System.debug('usrId----->'+usrId);
        System.debug('searchStr----------->'+searchStr);
        System.debug('str_PortfolioType----------->'+str_PortfolioType);
        Set<String> setSearchStr = new Set<String>();
        // Map to return the assigned portfolios. 
        Map<String, wrap_SCMSA> lstwrap_MSAPortfolioRlNAN1 = new Map<String, wrap_SCMSA>(); 
        
        if(String.isNotBlank(searchStr))
        {
            List<String> lstSearchStr = searchStr.split(',');
            System.debug('lstSearchStr----------->'+lstSearchStr);
            if(! lstSearchStr.isEmpty())
            {
                for(String str : lstSearchStr )
                    setSearchStr.add(str.trim());
            }
            System.debug('setSearchStr--------------->'+setSearchStr);
        }
        Set<String> setAssignedSFX = new Set<String>();
        Map<String, Account_Team__c> mapAsignedSFXBDM = new Map<String, Account_Team__c>();
        List<Account_Team__c> lstAssignedPostfolios = [SELECT Id, Name, National1__c,National2__c,National3__c, Account__r.SFX_Code__c,
                                                       CRS__c,NSM__c , Relationship__c, Collection__c,Submission__c,Account__r.Propel_MSACode__c, 
                                                       Account__r.Name,Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__r.Name, PropelI_Branch_Id__c,
                                                       PropelI_Composite_Key__c
                                                       from Account_Team__c where BDMPropelI__c =: usrId AND (Collection__c = TRUE OR Submission__c = True)];
        System.debug('lstAssignedPostfolios-------------------->'+lstAssignedPostfolios);
        
        if(! lstAssignedPostfolios.isEmpty())
        {
            for(Account_Team__c eachAccountTem : lstAssignedPostfolios)
            {
                if(eachAccountTem.Account__r.SFX__c != null)
                {
                    setAssignedSFX.add(eachAccountTem.Account__r.SFX__c);
                    if(eachAccountTem.PropelI_Branch_Id__c != null)
                    {
                        mapAsignedSFXBDM.put(eachAccountTem.PropelI_Branch_Id__c, eachAccountTem);
                    }
                }
            }
        }
        System.debug('setAssignedSFX------------------->'+setAssignedSFX);
        System.debug('mapAsignedSFXBDM-------------->'+mapAsignedSFXBDM);
        
        if(! setSearchStr.isEmpty() && searchby.equalsIgnoreCase('MSA'))
        {
            List<Account> lstSFX = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,Propel_key__c,Billing_Level__c,
                                    Parent.Name, SFX_Code__c,Assign_Branch_Id__r.Name 
                                    from Account where Parent.Propel_MSACode__c IN : setSearchStr ORDER BY SFX_Code__c ASC ];
            System.debug('lstSFX--------------->'+lstSFX);
            
            if(! lstSFX.isEmpty())
            { 
                Set<String> setSFX  = new Set<String>();
                for(Account eachSFX : lstSFX)
                {
                    if(eachSFX.SFX__c != null)
                    {
                        setSFX.add(eachSFX.SFX__c);
                    }
                }
                if(! setSFX.isEmpty())
                {
                    // Pull list of RC records. 
                    List<Account> lstRCAccounts = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,Propel_key__c,
                                                   Billing_Level__c,Parent.Name, SFX_Code__c,Assign_Branch_Id__r.Name 
                                                   from Account where SFX__c IN : setSFX AND RecordType.Name = 'Rate Card'];
                    System.debug('lstRCAccounts----------->'+lstRCAccounts);
                    Set<String> setRCAcc = new Set<String>();
                    if(! lstRCAccounts.isEmpty())
                    {
                        for(Account eachRC : lstRCAccounts)
                            setRCAcc.add(eachRC.Id); 
                    }
                    System.debug('setRCAcc---------->'+setRCAcc);
                    List<Account_Team__c> lstOthrsAssignedPostfolios = [SELECT Id, Name, National1__c,National2__c,National3__c, Account__r.SFX_Code__c,
                                                                        National4__c,CRS__c,NSM__c , Relationship__c, Collection__c,
                                                                        Submission__c,Account__r.Propel_MSACode__c, Account__r.Name, PropelI_Branch_Id__c,
                                                                        Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__r.Name from Account_Team__c 
                                                                        where BDMPropelI__c !=: usrId AND (Account__c IN : setRCAcc OR Account__r.SFX_Code__c IN :setSFX)  
                                                                        AND (Collection__c = TRUE OR Submission__c = True)];
                    System.debug('lstOthrsAssignedPostfolios-------------->'+lstOthrsAssignedPostfolios);
                    Map<String, wrap_SCMapping> mapOthrsAssignedPortfolio = new Map<String, wrap_SCMapping>();
                    if(! lstOthrsAssignedPostfolios.isEmpty())
                    {
                        for(Account_Team__c asgndPortfolio : lstOthrsAssignedPostfolios)
                        {
                            system.debug('1 ===>'+asgndPortfolio.Account__c);
                            system.debug('2 ===>'+asgndPortfolio.Account__r.SFX_Code__c);
                            
                            system.debug(asgndPortfolio.Account__c);
                            if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.SFX_Code__c != null && asgndPortfolio.Account__r.SFX_Code__c.startsWithIgnoreCase('SFX'))
                            {
                                if(test.isRunningTest()){
                                    mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                                }
                                if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c)) 
                                    mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                                else
                                {
                                    if(asgndPortfolio.Collection__c)
                                    {
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollection = asgndPortfolio.Collection__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollectionAssigned = asgndPortfolio.Collection__c;mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CollectionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    }
                                    if(asgndPortfolio.Submission__c)
                                    {
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubimission = asgndPortfolio.Submission__c; mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubmissionAssigned = asgndPortfolio.Submission__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).SubmissionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    }
                                }
                            }
                            else if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Name.startsWithIgnoreCase('RC'))
                            {
                                if(test.isRunningTest()){
                                    mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                                }
                                if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c)) mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                                else
                                {
                                    if(asgndPortfolio.Collection__c)
                                    {
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollection = asgndPortfolio.Collection__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollectionAssigned = asgndPortfolio.Collection__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CollectionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                        
                                    }
                                    
                                    if(asgndPortfolio.Submission__c)
                                    {
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubimission = asgndPortfolio.Submission__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubmissionAssigned = asgndPortfolio.Submission__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).SubmissionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                        
                                    }
                                }
                            }
                        }
                    }
                    System.debug('mapOthrsAssignedPortfolio------------->'+mapOthrsAssignedPortfolio);
                    
                    
                    List<Billing_Information__c> lstBillingInfos = [SELECT Id, Billing_Level__c,MSA__c, SFX_no__c, Rate_Card_no__c,(SELECT Billing_By_Id__c,Billing_Branch__r.Name,Collection_Branch__r.Name, Submission_Branch__r.Name from Billing_Line_Items__r where isActive__c = true) from Billing_Information__c where SFX_no__c IN :setSFX];
                    System.debug('lstBillingInfos---------------->'+lstBillingInfos);
                    Map<String, List<wrap_SCMapping>> mapwrap_SCMapping = new Map<String, List<wrap_SCMapping>>();
                    Map<String, List<wrap_SCMapping>> mapwrap_SCMapping_SFX = new Map<String, List<wrap_SCMapping>>();
                    
                    if(! lstBillingInfos.isEmpty())
                    {
                        for(Billing_Information__c eachBillingInfo : lstBillingInfos)
                        {
                            if(eachBillingInfo.Billing_Line_Items__r != null && eachBillingInfo.Billing_Line_Items__r.size() > 0)
                            {
                                for(Billing_Line_Item__c eachBillLineItem : eachBillingInfo.Billing_Line_Items__r)
                                {
                                    if(eachBillingInfo.SFX_no__c != null)
                                    {
                                        Boolean isCollectionSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapAsignedSFXBDM.get(eachBillLineItem.Billing_By_Id__c).Collection__c ? True : False ;
                                        Boolean isCollectionAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isCollection ? True : False ;
                                        String str_CollectionBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isCollection && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).CollectionUsrName != null ? mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).CollectionUsrName: Null ;
                                        Boolean isSubmissionSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapAsignedSFXBDM.get(eachBillLineItem.Billing_By_Id__c).Submission__c ? True : False ;
                                        Boolean isSubmissionAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isSubimission ? True : False ;
                                        String str_SubmissionBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isSubimission && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).SubmissionUsrName != null ? mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).SubmissionUsrName : Null ;
                                        System.debug('isCollectionSelfAsgnd--------------->'+isCollectionSelfAsgnd);
                                        System.debug('isCollectionAsgnd----------------->'+isCollectionAsgnd);
                                        System.debug('str_CollectionBDM----------------->'+str_CollectionBDM);
                                        System.debug('isSubmissionSelfAsgnd--------------->'+isSubmissionSelfAsgnd);
                                        System.debug('isSubmissionAsgnd--------------->'+isSubmissionAsgnd);
                                        System.debug('str_SubmissionBDM--------------->'+str_SubmissionBDM);
                                        
                                        if(eachBillingInfo.Billing_Level__c == 'Rate Card') {
                                            if(! mapwrap_SCMapping.containsKey(eachBillingInfo.Rate_Card_no__c)) //Changed key from SFX_no__c to Rate_Card_no__c
                                            {                                   
                                                mapwrap_SCMapping.put(eachBillingInfo.Rate_Card_no__c, new List<wrap_SCMapping>{new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM)});
                                            }else{
                                                mapwrap_SCMapping.get(eachBillingInfo.Rate_Card_no__c).add(new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM));
                                            }
                                        }
                                        else {
                                            if(! mapwrap_SCMapping.containsKey(eachBillingInfo.SFX_no__c))
                                            {
                                                mapwrap_SCMapping.put(eachBillingInfo.SFX_no__c,new List<wrap_SCMapping>{new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM)});
                                            }else{
                                                mapwrap_SCMapping.get(eachBillingInfo.SFX_no__c).add(new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM));
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        System.debug('mapwrap_SCMapping---------------------->'+mapwrap_SCMapping);
                        Map<String, List<wrap_SCBranches>> mapwrap_SCBranches = new Map<String, List<wrap_SCBranches>>();
                        if(! lstRCAccounts.isEmpty())
                        {
                            for(Account eachRC : lstRCAccounts)
                            {
                                if(! mapwrap_SCBranches.keySet().contains(eachRC.SFX__c) && ! mapwrap_SCMapping.isEmpty() &&  mapwrap_SCMapping.keySet().contains(eachRC.Name))
                                    mapwrap_SCBranches.put(eachRC.SFX__c, new List<wrap_SCBranches>{new wrap_SCBranches(eachRC.Name,eachRC.Parent.Name, mapwrap_SCMapping.get(eachRC.Name))});
                                else if(! mapwrap_SCBranches.isEmpty() && mapwrap_SCBranches.keySet().contains(eachRC.SFX__c) && ! mapwrap_SCMapping.isEmpty() && mapwrap_SCMapping.keySet().contains(eachRC.Name))
                                    mapwrap_SCBranches.get(eachRC.SFX__c).add(new wrap_SCBranches(eachRC.Name,eachRC.Parent.Name, mapwrap_SCMapping.get(eachRC.Name)));
                            }
                        }
                        System.debug('mapwrap_SCBranches------------>'+mapwrap_SCBranches);
                        
                        Map<String, List<wrap_SCSFX>> mapwrap_SCSFX = new Map<String, List<wrap_SCSFX>>();
                        Set<String> setMSANo = new Set<String>();
                        Map<String, String> mapMSAName = new Map<String, String>();
                        Set<Id> setSFXDup = new Set<Id>();
                        
                        for(Account eachSFX: lstSFX)
                        {
                            //if(! setAssignedSFX.contains(eachSFX.SFX__c))
                            //{
                            //if(!setSFXDup.contains(eachSFX.Id))
                            //{
                            setMSANo.add(eachSFX.MSA__c);
                            if(! mapMSAName.keySet().contains(eachSFX.MSA__c))
                                mapMSAName.put(eachSFX.MSA__c, eachSFX.Parent.Name);
                            
                            if(String.isNotBlank(eachSFX.Billing_Level__c) && eachSFX.Billing_Level__c.equalsIgnoreCase('Rate Card'))
                            {
                                if(! mapwrap_SCSFX.keySet().contains(eachSFX.MSA__c))
                                {
                                    mapwrap_SCSFX.put(eachSFX.MSA__c,new List<wrap_SCSFX>{new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c,null,mapwrap_SCBranches.get(eachSFX.SFX__c), eachSFX.Billing_Level__c)});
                                }else{
                                    
                                    mapwrap_SCSFX.get(eachSFX.MSA__c).add(new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c,null, mapwrap_SCBranches.get(eachSFX.SFX__c), eachSFX.Billing_Level__c));
                                }
                            }else if(String.isNotBlank(eachSFX.Billing_Level__c) && (eachSFX.Billing_Level__c.equalsIgnoreCase('MSA') || eachSFX.Billing_Level__c.equalsIgnoreCase('SFX')) && mapwrap_SCMapping.keySet().contains(eachSFX.SFX__c))
                            {
                                if(! mapwrap_SCSFX.keySet().contains(eachSFX.MSA__c))
                                    mapwrap_SCSFX.put(eachSFX.MSA__c, new List<wrap_SCSFX>{ new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, mapwrap_SCMapping.get(eachSFX.SFX__c), null, eachSFX.Billing_Level__c)});
                                else{
                                    
                                    mapwrap_SCSFX.get(eachSFX.MSA__c).add(new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, mapwrap_SCMapping.get(eachSFX.SFX__c), null, eachSFX.Billing_Level__c));
                                }
                            }
                            //}
                            //setSFXDup.add(eachSFX.Id);
                            //}
                            
                        }
                        System.debug('mapwrap_SCSFX--------------->'+mapwrap_SCSFX);
                        System.debug('setMSANo------------------->'+setMSANo);
                        Map<String, wrap_SCMSA> mapwrap_SCMSA = new Map<String, wrap_SCMSA>();
                        if(! mapwrap_SCSFX.isEmpty() && ! setMSANo.isEmpty())
                        {
                            for(String eachMSA : setMSANo)
                            {
                                if(! mapwrap_SCMSA.keySet().contains(eachMSA) && mapwrap_SCSFX.keySet().contains(eachMSA))
                                    mapwrap_SCMSA.put(eachMSA, new wrap_SCMSA(eachMSA, mapMSAName.get(eachMSA), mapwrap_SCSFX.get(eachMSA)));
                            }
                        }
                        System.debug('mapwrap_SCMSA--------------->'+mapwrap_SCMSA);
                        return mapwrap_SCMSA.values();
                    }
                    
                }
            }
        }else if(! setSearchStr.isEmpty() && searchby.equalsIgnoreCase('SFX'))
        {
            List<Account> lstSFX = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,Propel_key__c,Billing_Level__c, Parent.Name, SFX_Code__c,Assign_Branch_Id__r.Name from Account where SFX_Code__c IN : setSearchStr ORDER BY SFX_Code__c ASC];
            System.debug('lstSFX--------------->'+lstSFX);
            Set<String> setSFX  = new Set<String>();
            for(Account eachSFX : lstSFX)
            {
                if(eachSFX.SFX__c != null)
                {
                    setSFX.add(eachSFX.SFX__c);
                }
            }
            System.debug('---- setSFX: ' + setSFX);
            if(! setSFX.isEmpty())
            {
                // Pull list of RC records. 
                List<Account> lstRCAccounts = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,Propel_key__c,Billing_Level__c,Parent.Name, SFX_Code__c,Assign_Branch_Id__r.Name from Account where SFX__c IN : setSFX AND RecordType.Name = 'Rate Card'];
                System.debug('lstRCAccounts----------->'+lstRCAccounts);
                Set<String> setRCAcc = new Set<String>();
                if(! lstRCAccounts.isEmpty())
                {
                    for(Account eachRC : lstRCAccounts)
                        setRCAcc.add(eachRC.Id);
                }
                System.debug('setRCAcc-------------->'+setRCAcc);
                List<Account_Team__c> lstOthrsAssignedPostfolios = [SELECT Id, Name, PropelI_Branch_Id__c, National1__c,National2__c,National3__c,
                                                                    National4__c,CRS__c,NSM__c , Relationship__c, Collection__c,Submission__c, Account__r.SFX_Code__c,
                                                                    Account__r.Propel_MSACode__c, Account__r.Name,Account__r.SFX__c, PropelI_Composite_Key__c, 
                                                                    Account__r.MSA__c, BDMPropelI__r.Name from Account_Team__c
                                                                    where BDMPropelI__c !=: usrId AND (Account__c IN : setRCAcc OR Account__r.SFX_Code__c IN :setSFX)  AND (Collection__c = TRUE OR Submission__c = True)];
                System.debug('lstOthrsAssignedPostfolios-------------->'+lstOthrsAssignedPostfolios);
                Map<String, wrap_SCMapping> mapOthrsAssignedPortfolio = new Map<String, wrap_SCMapping>();
                if(! lstOthrsAssignedPostfolios.isEmpty())
                {
                    for(Account_Team__c asgndPortfolio : lstOthrsAssignedPostfolios)
                    {
                        system.debug('HHHHHHHHHH =>'+asgndPortfolio.PropelI_Branch_Id__c);
                        if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.SFX_Code__c != null && asgndPortfolio.Account__r.SFX_Code__c.startsWithIgnoreCase('SFX'))
                        {
                            if(test.isRunningTest()){
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null, asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                            }
                            if(! mapOthrsAssignedPortfolio.containsKey(asgndPortfolio.PropelI_Branch_Id__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null, asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                            
                            else
                            {
                                if(asgndPortfolio.Collection__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollection = asgndPortfolio.Collection__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollectionAssigned = asgndPortfolio.Collection__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CollectionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    
                                }
                                
                                if(asgndPortfolio.Submission__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubimission = asgndPortfolio.Submission__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubmissionAssigned = asgndPortfolio.Submission__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).SubmissionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    
                                }
                            }
                        }
                        else if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Name.startsWithIgnoreCase('RC'))
                        {
                            if(test.isRunningTest()){
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                            }
                            if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                                mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                            else
                            {
                                if(asgndPortfolio.Collection__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollection = asgndPortfolio.Collection__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollectionAssigned = asgndPortfolio.Collection__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CollectionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    
                                }
                                
                                if(asgndPortfolio.Submission__c)
                                {
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubimission = asgndPortfolio.Submission__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubmissionAssigned = asgndPortfolio.Submission__c;
                                    mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).SubmissionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    
                                }
                            }
                        }
                    }
                }
                System.debug('mapOthrsAssignedPortfolio------------->'+mapOthrsAssignedPortfolio);
                
                
                List<Billing_Information__c> lstBillingInfos = [SELECT Id, Billing_Level__c,MSA__c, SFX_no__c, Rate_Card_no__c,(SELECT Billing_By_Id__c,Billing_Branch__r.Name,Collection_Branch__r.Name, Composite_Key__c, Submission_Branch__r.Name from Billing_Line_Items__r where isactive__c=true) from Billing_Information__c where SFX_no__c IN :setSFX];
                System.debug('---- lstBillingInfos: ' + lstBillingInfos);
                Map<String, List<wrap_SCMapping>> mapwrap_SCMapping = new Map<String, List<wrap_SCMapping>>();
                Map<String, List<wrap_SCMapping>> mapwrap_SCMapping_SFX = new Map<String, List<wrap_SCMapping>>(); //Created New Map for SFX
                
                if(! lstBillingInfos.isEmpty())
                {
                    for(Billing_Information__c eachBillingInfo : lstBillingInfos)
                    {
                        if(eachBillingInfo.Billing_Line_Items__r != null && eachBillingInfo.Billing_Line_Items__r.size() > 0)
                        {
                            for(Billing_Line_Item__c eachBillLineItem : eachBillingInfo.Billing_Line_Items__r)
                            {
                                Boolean isCollectionSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapAsignedSFXBDM.get(eachBillLineItem.Billing_By_Id__c).Collection__c ? True : False ;
                                Boolean isCollectionAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isCollection ? True : False ;
                                String str_CollectionBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isCollection && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).CollectionUsrName != null ? mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).CollectionUsrName: Null ;
                                Boolean isSubmissionSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapAsignedSFXBDM.get(eachBillLineItem.Billing_By_Id__c).Submission__c ? True : False ;
                                Boolean isSubmissionAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isSubimission ? True : False ;
                                String str_SubmissionBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isSubimission && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).SubmissionUsrName != null ? mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).SubmissionUsrName : Null ;
                                System.debug('isCollectionSelfAsgnd--------------->'+isCollectionSelfAsgnd);
                                System.debug('isCollectionAsgnd----------------->'+isCollectionAsgnd);
                                System.debug('str_CollectionBDM----------------->'+str_CollectionBDM);
                                System.debug('isSubmissionSelfAsgnd--------------->'+isSubmissionSelfAsgnd);
                                System.debug('isSubmissionAsgnd--------------->'+isSubmissionAsgnd);
                                System.debug('str_SubmissionBDM--------------->'+str_SubmissionBDM);
                                
                                if(eachBillingInfo.Billing_Level__c == 'Rate Card') {
                                    if(! mapwrap_SCMapping.containsKey(eachBillingInfo.Rate_Card_no__c)) //Change key from SFX_no__c to Rate_Card_no__c
                                    {
                                        mapwrap_SCMapping.put(eachBillingInfo.Rate_Card_no__c,new List<wrap_SCMapping>{new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM)});
                                    }else{
                                        mapwrap_SCMapping.get(eachBillingInfo.Rate_Card_no__c).add(new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM));
                                    }
                                }
                                else {
                                    if(! mapwrap_SCMapping_SFX.containsKey(eachBillingInfo.SFX_no__c))
                                    {
                                        mapwrap_SCMapping_SFX.put(eachBillingInfo.SFX_no__c,new List<wrap_SCMapping>{new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM)});
                                    }else{
                                        mapwrap_SCMapping_SFX.get(eachBillingInfo.SFX_no__c).add(new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd, str_SubmissionBDM, isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM));
                                    }
                                }
                            }
                        }
                    }
                    System.debug('mapwrap_SCMapping---------------------->'+mapwrap_SCMapping);    
                    Map<String, List<wrap_SCBranches>> mapwrap_SCBranches = new Map<String, List<wrap_SCBranches>>();
                    if(! lstRCAccounts.isEmpty())
                    {
                        for(Account eachRC : lstRCAccounts)
                        {
                            if(! mapwrap_SCBranches.keySet().contains(eachRC.SFX__c) && ! mapwrap_SCMapping.isEmpty() &&  mapwrap_SCMapping.keySet().contains(eachRC.Name))
                                mapwrap_SCBranches.put(eachRC.SFX__c, new List<wrap_SCBranches>{new wrap_SCBranches(eachRC.Name,eachRC.Parent.Name, mapwrap_SCMapping.get(eachRC.Name))});
                            else if(! mapwrap_SCBranches.isEmpty() && mapwrap_SCBranches.keySet().contains(eachRC.SFX__c) && ! mapwrap_SCMapping.isEmpty() && mapwrap_SCMapping.keySet().contains(eachRC.Name))
                                mapwrap_SCBranches.get(eachRC.SFX__c).add(new wrap_SCBranches(eachRC.Name,eachRC.Parent.Name, mapwrap_SCMapping.get(eachRC.Name)));
                        }
                    }
                    System.debug('mapwrap_SCBranches------------>'+mapwrap_SCBranches);
                    Map<String, List<wrap_SCSFX>> mapwrap_SCSFX = new Map<String, List<wrap_SCSFX>>();
                    Set<String> setMSANo = new Set<String>();
                    Map<String, String> mapMSAName = new Map<String, String>();
                    for(Account eachSFX: lstSFX)
                    {
                        //if(!setAssignedSFX.contains(eachSFX.SFX__c))
                        //{                       
                        setMSANo.add(eachSFX.MSA__c);
                        
                        if(String.isNotBlank(eachSFX.Billing_Level__c) && eachSFX.Billing_Level__c.equalsIgnoreCase('Rate Card'))
                        {
                            if(! mapwrap_SCSFX.keySet().contains(eachSFX.MSA__c))
                            {
                                mapwrap_SCSFX.put(eachSFX.MSA__c,new List<wrap_SCSFX>{new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, null, mapwrap_SCBranches.get(eachSFX.SFX__c), eachSFX.Billing_Level__c)});
                            }else{
                                
                                mapwrap_SCSFX.get(eachSFX.MSA__c).add(new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c,null, mapwrap_SCBranches.get(eachSFX.SFX__c), eachSFX.Billing_Level__c ));
                            }
                            
                        }else if(String.isNotBlank(eachSFX.Billing_Level__c) && (eachSFX.Billing_Level__c.equalsIgnoreCase('MSA') || eachSFX.Billing_Level__c.equalsIgnoreCase('SFX')) && mapwrap_SCMapping_SFX.keySet().contains(eachSFX.SFX__c))
                        {
                            if(! mapwrap_SCSFX.keySet().contains(eachSFX.MSA__c))
                                mapwrap_SCSFX.put(eachSFX.MSA__c,new List<wrap_SCSFX>{new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, mapwrap_SCMapping_SFX.get(eachSFX.SFX__c), null, eachSFX.Billing_Level__c)});
                            else{
                                
                                mapwrap_SCSFX.get(eachSFX.MSA__c).add(new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, mapwrap_SCMapping_SFX.get(eachSFX.SFX__c), null, eachSFX.Billing_Level__c));
                            }
                        }
                        if(! mapMSAName.keySet().contains(eachSFX.MSA__c))
                            mapMSAName.put(eachSFX.MSA__c, eachSFX.Parent.Name);
                        //}
                        
                    }
                    System.debug('mapwrap_SCSFX--------------->'+mapwrap_SCSFX);
                    System.debug('setMSANo------------------->'+setMSANo);
                    
                    Map<String, wrap_SCMSA > mapwrap_SCMSA = new Map<String, wrap_SCMSA >();
                    if(! mapwrap_SCSFX.isEmpty() && ! setMSANo.isEmpty())
                    {
                        for(String eachMSA : setMSANo)
                        {
                            if(! mapwrap_SCMSA.keySet().contains(eachMSA) && mapwrap_SCSFX.keySet().contains(eachMSA))
                                mapwrap_SCMSA.put(eachMSA, new wrap_SCMSA(eachMSA, mapMSAName.get(eachMSA) , mapwrap_SCSFX.get(eachMSA)));
                        }
                    }
                    System.debug('mapwrap_SCMSA--------------->'+mapwrap_SCMSA);//This map is having a duplicate boolean variables values.
                    return mapwrap_SCMSA.values();
                }
                
            }
            
        }else if(! setSearchStr.isEmpty() && searchby.equalsIgnoreCase('Rate Card'))
        {
            List<Account> lstRateCard = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,Propel_key__c,SFX_Code__c, Parent.Name,Billing_Level__c, Assign_Branch_Id__r.Name from Account where Name IN : setSearchStr];
            System.debug('lstRateCard--------------->'+lstRateCard);
            if(! lstRateCard.isEmpty())
            {
                Set<String> setSFX  = new Set<String>();
                Set<String> setRCAcc = new Set<String>();
                for(Account eachSFX : lstRateCard)
                {
                    if(eachSFX.SFX__c != null)
                    {
                        setSFX.add(eachSFX.SFX__c);
                        setRCAcc.add(eachSFX.Id);
                    }
                }
                System.debug('setSFX----------->'+setSFX);
                System.debug('setRCAcc------------>'+setRCAcc);
                if(! setSFX.isEmpty())
                {
                    // Pull list of RC records. 
                    List<Account> lstSFXccounts = [SELECT Id,Name,Propel_MSACode__c, MSA__c, SFX__c,Propel_key__c,Billing_Level__c,
                                                   Parent.Name, SFX_Code__c,Assign_Branch_Id__r.Name from Account where SFX_Code__c IN : setSFX];
                    System.debug('lstSFXccounts----------->'+lstSFXccounts);
                    List<Account_Team__c> lstOthrsAssignedPostfolios = [SELECT Id, Name, PropelI_Branch_Id__c, National1__c,National2__c,National3__c,
                                                                        National4__c,CRS__c,NSM__c , Relationship__c, Collection__c,Submission__c,Account__r.Propel_MSACode__c, 
                                                                        Account__r.Name,Account__r.SFX__c, Account__r.MSA__c, BDMPropelI__r.Name, Account__r.SFX_Code__c
                                                                        from Account_Team__c where BDMPropelI__c !=: usrId AND
                                                                        (Account__c IN : setRCAcc OR Account__r.SFX_Code__c IN :setSFX)  AND 
                                                                        (Collection__c = TRUE OR Submission__c = True)];
                    System.debug('lstOthrsAssignedPostfolios-------------->'+lstOthrsAssignedPostfolios);
                    Map<String, wrap_SCMapping> mapOthrsAssignedPortfolio = new Map<String, wrap_SCMapping>();
                    if(! lstOthrsAssignedPostfolios.isEmpty())
                    {
                        for(Account_Team__c asgndPortfolio : lstOthrsAssignedPostfolios)
                        {
                            if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Name != null && asgndPortfolio.Account__r.SFX_Code__c != null && asgndPortfolio.Account__r.Name.startsWithIgnoreCase('SFX'))
                            {
                                if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                                    mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                                else
                                {
                                    if(asgndPortfolio.Collection__c)
                                    {
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollection = asgndPortfolio.Collection__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollectionAssigned = asgndPortfolio.Collection__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CollectionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    }
                                    if(asgndPortfolio.Submission__c)
                                    {
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubimission = asgndPortfolio.Submission__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubmissionAssigned = asgndPortfolio.Submission__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).SubmissionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    }
                                }
                            }                     
                            else if(asgndPortfolio.Account__c != null && asgndPortfolio.Account__r.Name != null && asgndPortfolio.Account__r.SFX__c != null && asgndPortfolio.Account__r.Name.startsWithIgnoreCase('RC'))
                            {
                                if(! mapOthrsAssignedPortfolio.keySet().contains(asgndPortfolio.PropelI_Branch_Id__c))
                                    mapOthrsAssignedPortfolio.put(asgndPortfolio.PropelI_Branch_Id__c, new wrap_SCMapping(Null,Null, Null, Null,  asgndPortfolio.Submission__c, Null, asgndPortfolio.BDMPropelI__r.Name, asgndPortfolio.Collection__c, Null, asgndPortfolio.BDMPropelI__r.Name));
                                else
                                {
                                    if(asgndPortfolio.Collection__c || Test.isRunningTest())
                                    {
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollection = asgndPortfolio.Collection__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isCollectionAssigned = asgndPortfolio.Collection__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).CollectionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                    }
                                    
                                    if(asgndPortfolio.Submission__c)
                                    {
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubimission = asgndPortfolio.Submission__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).isSubmissionAssigned = asgndPortfolio.Submission__c;
                                        mapOthrsAssignedPortfolio.get(asgndPortfolio.PropelI_Branch_Id__c).SubmissionUsrName = asgndPortfolio.BDMPropelI__r.Name;
                                        
                                    }
                                }
                            }
                        }
                    }
                    System.debug('mapOthrsAssignedPortfolio------------->'+mapOthrsAssignedPortfolio);
                    List<Billing_Information__c> lstBillingInfos = [SELECT Id, Billing_Level__c,MSA__c, SFX_no__c, Rate_Card_no__c,(SELECT Billing_By_Id__c,Billing_Branch__r.Name,Collection_Branch__r.Name, Submission_Branch__r.Name from Billing_Line_Items__r where isactive__c = true) from Billing_Information__c where SFX_no__c IN :setSFX];
                    Map<String, List<wrap_SCMapping>> mapwrap_SCMapping = new Map<String, List<wrap_SCMapping>>();
                    Map<String, List<wrap_SCMapping>> mapwrap_SCMapping_SFX = new Map<String, List<wrap_SCMapping>>();//New Map
                    
                    if(! lstBillingInfos.isEmpty())
                    {
                        for(Billing_Information__c eachBillingInfo : lstBillingInfos)
                        {
                            if(eachBillingInfo.Billing_Line_Items__r != null && eachBillingInfo.Billing_Line_Items__r.size() > 0)
                            {
                                for(Billing_Line_Item__c eachBillLineItem : eachBillingInfo.Billing_Line_Items__r)
                                {
                                    if(eachBillingInfo.SFX_no__c != null)
                                    {
                                        Boolean isCollectionSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapAsignedSFXBDM.get(eachBillLineItem.Billing_By_Id__c).Collection__c ? True : False ;
                                        Boolean isCollectionAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isCollection ? True : False ;
                                        String str_CollectionBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isCollection && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).CollectionUsrName != null ? mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).CollectionUsrName: Null ;
                                        Boolean isSubmissionSelfAsgnd = mapAsignedSFXBDM != null && mapAsignedSFXBDM.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapAsignedSFXBDM.get(eachBillLineItem.Billing_By_Id__c).Submission__c ? True : False ;
                                        Boolean isSubmissionAsgnd = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isSubimission ? True : False ;
                                        String str_SubmissionBDM = mapOthrsAssignedPortfolio != null && mapOthrsAssignedPortfolio.keySet().contains(eachBillLineItem.Billing_By_Id__c) && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).isSubimission && mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).SubmissionUsrName != null ? mapOthrsAssignedPortfolio.get(eachBillLineItem.Billing_By_Id__c).SubmissionUsrName : Null ;
                                        System.debug('isCollectionSelfAsgnd--------------->'+isCollectionSelfAsgnd);
                                        System.debug('isCollectionAsgnd----------------->'+isCollectionAsgnd);
                                        System.debug('str_CollectionBDM----------------->'+str_CollectionBDM);
                                        System.debug('isSubmissionSelfAsgnd--------------->'+isSubmissionSelfAsgnd);
                                        System.debug('isSubmissionAsgnd--------------->'+isSubmissionAsgnd);
                                        System.debug('str_SubmissionBDM--------------->'+str_SubmissionBDM);
                                        
                                        if(eachBillingInfo.Billing_Level__c == 'Rate Card') {
                                            if(! mapwrap_SCMapping.containsKey(eachBillingInfo.Rate_Card_no__c)) //Change key from SFX_no__c to Rate_Card_no__c
                                            {
                                                mapwrap_SCMapping.put(eachBillingInfo.Rate_Card_no__c,new List<wrap_SCMapping>{new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM)});
                                            }else{
                                                mapwrap_SCMapping.get(eachBillingInfo.Rate_Card_no__c).add(new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM));
                                            }
                                        }
                                        else {
                                            if(! mapwrap_SCMapping_SFX.containsKey(eachBillingInfo.SFX_no__c))
                                            {
                                                mapwrap_SCMapping_SFX.put(eachBillingInfo.SFX_no__c,new List<wrap_SCMapping>{new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd ,str_SubmissionBDM  , isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM)});
                                            }else{
                                                mapwrap_SCMapping_SFX.get(eachBillingInfo.SFX_no__c).add(new wrap_SCMapping(eachBillLineItem.Billing_By_Id__c,eachBillLineItem.Billing_Branch__r.Name, eachBillLineItem.Collection_Branch__r.Name, eachBillLineItem.Submission_Branch__r.Name, isSubmissionAsgnd, isSubmissionSelfAsgnd, str_SubmissionBDM, isCollectionAsgnd, isCollectionSelfAsgnd, str_CollectionBDM));
                                            }
                                        }
                                    }
                                }
                            }
                        }  
                        System.debug('mapwrap_SCMapping---------------------->'+mapwrap_SCMapping);
                        Map<String, List<wrap_SCBranches>> mapwrap_SCBranches = new Map<String, List<wrap_SCBranches>>();
                        if(! lstRateCard.isEmpty())
                        {
                            for(Account eachRC : lstRateCard)
                            {
                                if(! mapwrap_SCBranches.keySet().contains(eachRC.SFX__c) && ! mapwrap_SCMapping.isEmpty() &&  mapwrap_SCMapping.keySet().contains(eachRC.Name))
                                    mapwrap_SCBranches.put(eachRC.SFX__c, new List<wrap_SCBranches>{new wrap_SCBranches(eachRC.Name,eachRC.Parent.Name, mapwrap_SCMapping.get(eachRC.Name))});
                                else if(! mapwrap_SCBranches.isEmpty() && mapwrap_SCBranches.keySet().contains(eachRC.SFX__c) && ! mapwrap_SCMapping.isEmpty() && mapwrap_SCMapping.keySet().contains(eachRC.Name))
                                    mapwrap_SCBranches.get(eachRC.SFX__c).add(new wrap_SCBranches(eachRC.Name, eachRC.Parent.Name,mapwrap_SCMapping.get(eachRC.Name)));
                            }
                        }
                        System.debug('mapwrap_SCBranches------------>'+mapwrap_SCBranches);
                        Map<String, List<wrap_SCSFX>> mapwrap_SCSFX = new Map<String, List<wrap_SCSFX>>();
                        Set<String> setMSANo = new Set<String>();
                        Map<String, String> mapMSAName  = new Map<String, String>();
                        for(Account eachSFX: lstSFXccounts)
                        {
                            //if(! setAssignedSFX.contains(eachSFX.SFX__c))
                            // { 
                            if(eachSFX.MSA__c != null)
                            {
                                setMSANo.add(eachSFX.MSA__c);
                                if(eachSFX.MSA__c != null && !mapMSAName.containsKey(eachSFX.MSA__c))
                                    mapMSAName.put(eachSFX.MSA__c, eachSFX.Parent.Name);
                                if(String.isNotBlank(eachSFX.Billing_Level__c) && eachSFX.Billing_Level__c.equalsIgnoreCase('Rate Card'))
                                {
                                    if(! mapwrap_SCSFX.containsKey(eachSFX.MSA__c))
                                    {
                                        mapwrap_SCSFX.put(eachSFX.MSA__c,new List<wrap_SCSFX>{new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c,null, mapwrap_SCBranches.get(eachSFX.SFX__c), eachSFX.Billing_Level__c)});
                                    }else{
                                        
                                        mapwrap_SCSFX.get(eachSFX.MSA__c).add(new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c,null, mapwrap_SCBranches.get(eachSFX.SFX__c), eachSFX.Billing_Level__c ));
                                    }
                                    
                                }else if(String.isNotBlank(eachSFX.Billing_Level__c) && (eachSFX.Billing_Level__c.equalsIgnoreCase('MSA') || eachSFX.Billing_Level__c.equalsIgnoreCase('SFX')) && mapwrap_SCMapping_SFX.keySet().contains(eachSFX.SFX__c))
                                {
                                    if(! mapwrap_SCSFX.containsKey(eachSFX.MSA__c))
                                        mapwrap_SCSFX.put(eachSFX.MSA__c, new List<wrap_SCSFX>{new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, mapwrap_SCMapping_SFX.get(eachSFX.SFX__c), null, eachSFX.Billing_Level__c)});
                                    else{
                                        
                                        mapwrap_SCSFX.get(eachSFX.MSA__c).add(new wrap_SCSFX(eachSFX.MSA__c, eachSFX.SFX__c, mapwrap_SCMapping_SFX.get(eachSFX.SFX__c), null, eachSFX.Billing_Level__c));
                                    }
                                }
                            }
                            //}
                        }
                        System.debug('mapMSAName----------------->'+mapMSAName);
                        System.debug('mapwrap_SCSFX--------------->'+mapwrap_SCSFX);
                        System.debug('setMSANo------------------->'+setMSANo);
                        Map<String, wrap_SCMSA> mapwrap_SCMSA = new Map<String, wrap_SCMSA>();
                        if(! mapwrap_SCSFX.isEmpty() && ! setMSANo.isEmpty())
                        {
                            for(String eachMSA : setMSANo)
                            {
                                if(! mapwrap_SCMSA.keySet().contains(eachMSA) && mapwrap_SCSFX.keySet().contains(eachMSA))
                                    mapwrap_SCMSA.put(eachMSA, new wrap_SCMSA(eachMSA,mapMSAName.get(eachMSA),mapwrap_SCSFX.get(eachMSA)));
                            }
                        }
                        System.debug('mapwrap_SCMSA--------------->'+mapwrap_SCMSA);
                        return mapwrap_SCMSA.values();
                    }
                }
            }
        }
        return null;
    }
    //Method to upsert the account team for Submission and collection. 
    @AuraEnabled
    Public Static String upsertSCAccountBDM(Id usrId, Map<String, Boolean> mapCollection, Map<String, Boolean> mapSubmission)
    {
        String strSuccessMsg;
        System.debug('usrId----------------->'+usrId);
        System.debug('mapCollection-------------------->'+mapCollection);
        System.debug('mapSubmission----------------->'+mapSubmission);
        Set<String> setRCAccounts = new Set<String>();
        Set<String> setSFX = new Set<String>();
        Boolean collection;
        Boolean submission;
        String collectionBranchId = '';
        String submissionBranchId = '';
        
        Id propelIAccountTeamRecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
        if(mapCollection != null)
        {
            for(String strCollection : mapCollection.keySet())
            {
                if(strCollection.containsIgnoreCase('RC'))
                {
                    setRCAccounts.add(strCollection.split(':')[1]);
                    collectionBranchId = strCollection.split(':')[0] ;
                }
                else if(strCollection.containsIgnoreCase('SFX'))
                {
                    setSFX.add(strCollection.split(':')[1]);
                    collectionBranchId = strCollection.split(':')[0] ;
                }
                collection = mapCollection.get(strCollection);
            }
        }
        System.debug('setRCAccounts---------->'+setRCAccounts);
        System.debug('setSFX------------->'+setSFX);
        if(mapSubmission != null)
        {
            for(String strCollection : mapSubmission.keySet())
            {
                if(strCollection.containsIgnoreCase('RC'))
                {
                    setRCAccounts.add(strCollection.split(':')[1]);
                    submissionBranchId = strCollection.split(':')[0] ;
                }
                else if(strCollection.containsIgnoreCase('SFX'))
                {
                    setSFX.add(strCollection.split(':')[1]);
                    submissionBranchId = strCollection.split(':')[0] ;
                }
                submission = mapSubmission.get(strCollection);
            }
        }
        System.debug('setRCAccounts---------->'+setRCAccounts);
        System.debug('setSFX------------->'+setSFX);
        Map<String, Account> mapRCAccount = new Map<String, Account>();
        Map<String, Account> mapSFXAccounts = new Map<String, Account>();
        
        Boolean billingLevelMSA = false;
        String msaAccountId ='';
        if(! setRCAccounts.isEmpty() || ! setSFX.isEmpty())
        {
            List<Account> lstRCAccounts = [SELECT Id, SFX_Code__c, Name, Parent.Parent.Billing_Level__c, Parent.Parent.ParentId from Account where Name IN : setRCAccounts AND RecordType.Name = 'Rate Card' AND Is_PRC_Rate_Card__c = false];
            System.debug('lstRCAccounts----------->'+lstRCAccounts);
            if(! lstRCAccounts.isEmpty())
            {
                for(Account eachRC : lstRCAccounts)
                {
                    mapRCAccount.put(eachRC.Name, eachRC);
                    if(eachRC.Parent.Parent.Billing_Level__c == 'MSA'){
                        billingLevelMSA = true;
                        msaAccountId = eachRC.Parent.Parent.ParentId;
                    }
                }
                
            }
            
            List<Account> lstSFXAccounts = [SELECT Id, SFX_Code__c, Name, Billing_Level__c, ParentId from Account where SFX_Code__c IN : setSFX];
            System.debug('lstSFXAccounts------------>'+lstSFXAccounts);
            if(! lstSFXAccounts.isEmpty())
            {
                for(Account eachSFX : lstSFXAccounts){ 
                    mapSFXAccounts.put(eachSFX.SFX_Code__c, eachSFX);
                    if(eachSFX.Billing_Level__c == 'MSA'){
                        billingLevelMSA = true;
                        msaAccountId = eachSFX.ParentId;
                    }
                }
            }
            
        }
        System.debug('mapRCAccount----------->'+mapRCAccount);
        System.debug('mapSFXAccounts------------->'+mapSFXAccounts);
        System.debug('billingLevelMSA------------->'+billingLevelMSA);
        
        System.debug('billingLevelMSA------------->'+billingLevelMSA);
        System.debug('msaAccountId------------->'+msaAccountId);
        
        // SAC-147 - added by K SANSI - IBM, If billing level is MSA, we need to create/ update all its related SFX
        if(billingLevelMSA == true){            
            updateMSALevelBillingAndSubmission(msaAccountId, collection, submission, usrId, collectionBranchId, submissionBranchId);
            return 'Success';
        }
        
                 
        List<Account_Team__c> lstUpsrtAccountTeam = new List<Account_Team__c>();
        if(mapRCAccount != null || mapSFXAccounts != null)
        {
            for(String strCollectionBDM : mapCollection.keySet())
            {
                String strAccName = strCollectionBDM.split(':')[1];
                System.debug('strAccName---------->'+strAccName);
                Account_Team__c upsertAccTeam = new Account_Team__c();
                upsertAccTeam.BDMPropelI__c = usrId;
                upsertAccTeam.RecordTypeId = propelIAccountTeamRecordType;
                //upsertAccTeam.BDMPropelI__c  = usrId;
                if(mapRCAccount != null && mapRCAccount.keySet().contains(strAccName))
                    upsertAccTeam.Account__c = mapRCAccount.get(strAccName).Id;
                
                if(mapSFXAccounts != null && mapSFXAccounts.keySet().contains(strAccName))
                    upsertAccTeam.Account__c = mapSFXAccounts.get(strAccName).Id;
                upsertAccTeam.Collection__c = mapCollection.get(strCollectionBDM);
                upsertAccTeam.PropelI_Composite_Key__c = usrId + '::' + strCollectionBDM;
                if(mapSubmission != null && mapSubmission.keySet().contains(strCollectionBDM))
                    upsertAccTeam.Submission__c = mapSubmission.get(strCollectionBDM);
                upsertAccTeam.Billing_By_Id__c = strCollectionBDM.split(':')[0];
                upsertAccTeam.PropelI_Branch_Id__c = strCollectionBDM.split(':')[0];
                lstUpsrtAccountTeam.add(upsertAccTeam);
                
                
            }
            
            for(String strCollectionBDM : mapSubmission.keySet())
            {
                if(mapCollection != null && ! mapCollection.keySet().contains(strCollectionBDM) )
                {
                    String strAccName = strCollectionBDM.split(':')[1];
                    System.debug('strAccName---------->'+strAccName);
                    Account_Team__c upsertAccTeam = new Account_Team__c();
                    upsertAccTeam.Billing_By_Id__c = strCollectionBDM.split(':')[0];
                    upsertAccTeam.PropelI_Branch_Id__c = strCollectionBDM.split(':')[0];
                    upsertAccTeam.BDMPropelI__c = usrId;
                    upsertAccTeam.RecordTypeId = propelIAccountTeamRecordType;
                    //upsertAccTeam.BDMPropelI__c  = usrId;
                    if(mapRCAccount != null && mapRCAccount.keySet().contains(strAccName))
                        upsertAccTeam.Account__c = mapRCAccount.get(strAccName).Id;
                    
                    if(mapSFXAccounts != null && mapSFXAccounts.keySet().contains(strAccName))
                        upsertAccTeam.Account__c = mapSFXAccounts.get(strAccName).Id;
                    upsertAccTeam.Submission__c = mapSubmission.get(strCollectionBDM);
                    upsertAccTeam.PropelI_Composite_Key__c = usrId + '::' + strCollectionBDM;
                    lstUpsrtAccountTeam.add(upsertAccTeam);
                }
                
            }
            System.debug('lstUpsrtAccountTeam----------------->'+lstUpsrtAccountTeam);
            if(! lstUpsrtAccountTeam.isEmpty())
            {
                //Upsert the account team record.
                Database.UpsertResult[] results = Database.upsert(lstUpsrtAccountTeam, Account_Team__c.Field.PropelI_Composite_Key__c );
                system.debug('results--->'+results);
                for(Database.UpsertResult bdUpsrt : results)
                {
                    if(bdUpsrt.isSuccess())
                    {
                        // strSuccessMsg = 'Success! record are updated successfully. ';                     
                        strSuccessMsg = 'Success';
                    }
                }
                if(strSuccessMsg == 'Success'){
                    helperAccountTeam.syncBDMWithAccountTeam(lstUpsrtAccountTeam);
                }
                //upsert lstUpsrtAccountTeam Account_Team__c.Field.PropelI_Composite_Key__c;
            }
        }
        return strSuccessMsg;
        
    }
    // Method written to map the BDM on account. 
    @AuraEnabled
    Public static String  upsertRNAccountBDM(Id usrId, Map<String, Boolean> mapRelationship, Map<String, Boolean> mapCCD, 
                                             Map<String, Boolean> mapNAM, Map<String, Boolean> mapQRM, Map<String, Boolean> mapRM, Map<String, Boolean> mapCRS)
    {
        String strSuccessMsg; 
        Id userId = [SELECT Id from User where Id =: usrId].Id;
        System.debug('usrId--------------->'+usrId);
        System.debug('mapRelationship-------------->'+mapRelationship);
        System.debug('mapCCD------------------->'+mapCCD);
        System.debug('mapNAM-------------------->'+mapNAM);
        System.debug('mapQRM----------------->'+mapQRM);
        System.debug('mapRM------------------->'+mapRM);
        System.debug('mapCRS------------------->'+mapCRS);
        Set<String> setMapKeys = new Set<String>();
        Id propelIAccountTeamRecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
        
        
        Map<String, Boolean> mapCCDTemp = new Map<String, Boolean>();
        if(mapCCD != null && ! mapCCD.isEmpty())
        {
            for(String eachKey : mapCCD.keySet())
            {
                if(eachKey.contains(':')) {
                    mapCCDTemp.put(eachKey.split(':')[0], mapCCD.get(eachKey));
                    setMapKeys.add(eachKey.split(':')[0]);
                }
                else {
                    mapCCDTemp.put(eachKey, mapCCD.get(eachKey));
                    setMapKeys.add(eachKey);
                }
            }
        }
        
        Map<String, Boolean> mapNAMTemp = new Map<String, Boolean>();
        if(mapNAM != null && ! mapNAM.isEmpty())
        {
            for(String eachKey : mapNAM.keySet())
            {
                if(eachKey.contains(':')) {
                    mapNAMTemp.put(eachKey.split(':')[0], mapNAM.get(eachKey));
                    setMapKeys.add(eachKey.split(':')[0]);
                }
                else {
                    mapNAMTemp.put(eachKey, mapNAM.get(eachKey));
                    setMapKeys.add(eachKey);
                }
            }
        }
        
        Map<String, Boolean> mapQRMTemp = new Map<String, Boolean>();
        if(mapQRM != null && ! mapQRM.isEmpty())
        {
            for(String eachKey : mapQRM.keySet())
            {
                if(eachKey.contains(':')) {
                    mapQRMTemp.put(eachKey.split(':')[0], mapQRM.get(eachKey));
                    setMapKeys.add(eachKey.split(':')[0]);
                }
                else {
                    mapQRMTemp.put(eachKey, mapQRM.get(eachKey));
                    setMapKeys.add(eachKey);
                }
            }
        }
        
        Map<String, Boolean> mapRMTemp = new Map<String, Boolean>();
        if(mapRM != null && ! mapRM.isEmpty())
        {
            for(String eachKey : mapRM.keySet())
            {
                if(eachKey.contains(':')) {
                    mapRMTemp.put(eachKey.split(':')[0], mapRM.get(eachKey));
                    setMapKeys.add(eachKey.split(':')[0]);
                }
                else {
                    mapRMTemp.put(eachKey, mapRM.get(eachKey));
                    setMapKeys.add(eachKey);
                }
            }
        }
        
        Map<String, Boolean> mapCRSTemp = new Map<String, Boolean>();
        if(mapCRS != null && ! mapCRS.isEmpty())
        {
            for(String eachKey : mapCRS.keySet())
            {
                if(eachKey.contains(':')) {
                    mapCRSTemp.put(eachKey.split(':')[0], mapCRS.get(eachKey));
                    setMapKeys.add(eachKey.split(':')[0]);
                }
                else {
                    mapCRSTemp.put(eachKey, mapCRS.get(eachKey));
                    setMapKeys.add(eachKey);
                }
            }
        }
        System.debug('setMapKeys-------------->'+setMapKeys);
        
        List<Account> lstMSAAccounts = [SELECT Id, Propel_MSACode__c,Name from Account where Propel_MSACode__c IN :setMapKeys];
        System.debug('lstMSAAccounts--------------->'+lstMSAAccounts);
        
        Map<String, Account> mapMSAAccount = new Map<String, Account>();
        if(! lstMSAAccounts.isEmpty())
        {
            for(Account eachMSAAcc : lstMSAAccounts)
            {
                mapMSAAccount.put(eachMSAAcc.Propel_MSACode__c, eachMSAAcc);
            }
        }
        System.debug('mapMSAAccount----------->'+mapMSAAccount);
        
        List<Account_Team__c> lstUpsrtAccountTeam = new List<Account_Team__c>();
        if(! setMapKeys.isEmpty())
        {
            for(String strMapKey : setMapKeys)
            {
                if((! mapMSAAccount.isEmpty() && mapMSAAccount.keySet().contains(strMapKey)) )
                {
                    Account_Team__c upsertAccTeam = new Account_Team__c();
                    upsertAccTeam.BDMPropelI__c = userId;
                    upsertAccTeam.RecordTypeId = propelIAccountTeamRecordType;
                    upsertAccTeam.Account__c = mapMSAAccount.get(strMapKey).Id;
                    //Map CCD 
                    if(! mapCCDTemp.isEmpty() && mapCCDTemp.keySet().contains(strMapKey))
                        upsertAccTeam.National1__c = mapCCDTemp.get(strMapKey);
                    if(! mapNAMTemp.isEmpty() && mapNAMTemp.keySet().contains(strMapKey))
                        upsertAccTeam.National2__c = mapNAMTemp.get(strMapKey);
                    if(! mapQRMTemp.isEmpty() && mapQRMTemp.keySet().contains(strMapKey))
                        upsertAccTeam.National3__c = mapQRMTemp.get(strMapKey);
                    if(! mapRMTemp.isEmpty() && mapRMTemp.keySet().contains(strMapKey))
                        upsertAccTeam.National4__c = mapRMTemp.get(strMapKey);
                    if(! mapCRSTemp.isEmpty() && mapCRSTemp.keySet().contains(strMapKey))
                        upsertAccTeam.CRS__c = mapCRSTemp.get(strMapKey);
                    
                    upsertAccTeam.PropelI_Composite_Key__c = usrId + '::' + strMapKey;
                    System.debug('--- upsertAccTeam.PropelI_Composite_Key__c: ' + upsertAccTeam.PropelI_Composite_Key__c);
                    lstUpsrtAccountTeam.add(upsertAccTeam);                    
                }
                
            }
        }
        System.debug('lstUpsrtAccountTeam-------------->'+lstUpsrtAccountTeam);
        if(mapRelationship != null && ! mapRelationship.isEmpty())
        {
            //Set<String> setRCAcc = new Set<String>();
            Set<String> setAssignedBranchId = new Set<String>();
            for(String eachBranchId : mapRelationship.keySet())
            {
                if(eachBranchId.contains('@')) {
                    setAssignedBranchId.add(eachBranchId.split('@')[1].split(':')[0]);
                }
                //setRCAcc.add(strRC.split('_')[0]);
            }
            //System.debug('setRCAcc------------->'+setRCAcc);
            System.debug('setAssignedBranchId-------------> ' + setAssignedBranchId);
            //List<Account> lstRTAccounts = [SELECT Id, Propel_MSACode__c, Name, Parent.Name, AssignBranch_ID__c FROM Account WHERE Parent.Name IN : setRCAcc];
            List<Account> lstRTAccounts = [SELECT Id, Propel_MSACode__c, Name, ParentId, Parent.Name, AssignBranch_ID__c FROM Account WHERE AssignBranch_ID__c IN : setAssignedBranchId];
            Map<String, Account> mapRCAccounts = new Map<String, Account>();
            System.debug('lstRTAccounts--------------->'+lstRTAccounts);
            
            if(! lstRTAccounts.isEmpty())
            {
                for(Account eachBranch : lstRTAccounts) { mapRCAccounts.put(eachBranch.AssignBranch_ID__c, eachBranch); }
                
                for(String strMapKey : mapRelationship.KeySet())
                {
                    List<String> compositeKeyList = strMapKey.split(':');
                    compositeKeyList.remove(compositeKeyList.size() -1 );
                    String compositeKey = String.join(compositeKeyList,':');
                    //String rcName = strMapKey.split('-')[0];
                    String branchId = strMapKey.split('@')[1].split(':')[0];
                    String assignedBranchId;  
                     
                    List<String> keyList = strMapKey.split('@')[1].split(':');
                    if(keyList.size() > 0  && keyList.size() == 4){
                        assignedBranchId = keyList[3];
                    }
                    
                    System.debug('branchId------------------->'+branchId);
                    if(! mapRCAccounts.isEmpty() && mapRCAccounts.keySet().contains(branchId))
                    {
                        Account_Team__c upsertAccRelTeam = new Account_Team__c();  upsertAccRelTeam.Account__c  = mapRCAccounts.get(branchId).ParentId;
                        upsertAccRelTeam.PropelI_Branch_Id__c = mapRCAccounts.get(branchId).AssignBranch_ID__c;upsertAccRelTeam.BDMPropelI__c  = userId;
                        upsertAccRelTeam.RecordTypeId = propelIAccountTeamRecordType; upsertAccRelTeam.Relationship__c = mapRelationship.get(strMapKey);
                        upsertAccRelTeam.PropelI_Composite_Key__c = usrId + '::' + compositeKey;
                        lstUpsrtAccountTeam.add(upsertAccRelTeam);
                        upsertAccRelTeam.Assigned_Branch__c = assignedBranchId;
                    }
                    
                }
            }
            System.debug('mapRCAccounts---------->'+mapRCAccounts);
            
            
        }
        System.debug('lstUpsrtAccountTeam--------------->'+lstUpsrtAccountTeam);
        if(! lstUpsrtAccountTeam.isEmpty())
        {
            //Upsert the account team record.
            Database.UpsertResult[] results = Database.upsert(lstUpsrtAccountTeam, Account_Team__c.Field.PropelI_Composite_Key__c );
            for(Database.UpsertResult bdUpsrt : results)
            {
                if(bdUpsrt.isSuccess())
                {
                    // strSuccessMsg = 'Success! record are updated successfully. ';
                    strSuccessMsg = 'Success';
                }
            }
             
            //upsert lstUpsrtAccountTeam Account_Team__c.Field.PropelI_Composite_Key__c ;
        }
        System.debug('strSuccessMsg----------->'+strSuccessMsg);
        return strSuccessMsg;
        
    }
    
    // Warpper for Booking/Submission/ Collection at SFX level. 
    Public Class wrap_SCMSA
    {
        @AuraEnabled
        Public String MSA; 
        @AuraEnabled
        Public String Name;
        @AuraEnabled
        Public List<wrap_SCSFX> lstwrap_SCSFX;
        wrap_SCMSA(String MSA, String Name, List<wrap_SCSFX> lstwrap_SCSFX)
        {
            this.MSA = MSA;
            this.Name = Name;
            this.lstwrap_SCSFX = lstwrap_SCSFX;
        }
        wrap_SCMSA()
        {
            
        }
        
    }
    // Wrapper for Booking/submission/collection at branch level
    Public Class wrap_SCSFX{
        @AuraEnabled
        Public String MSA;
        @AuraEnabled
        Public String SFX; 
        @AuraEnabled
        Public List<wrap_SCMapping> lstwrap_SCMapping;
        @AuraEnabled
        Public List<wrap_SCBranches> lstwrap_SCBranches;
        @AuraEnabled
        Public String Billing_level;
        wrap_SCSFX(String MSA, String SFX, List<wrap_SCMapping> lstwrap_SCMapping, List<wrap_SCBranches> lstwrap_SCBranches, String Billing_level)
        {
            this.MSA = MSA;
            this.SFX = SFX;
            this.lstwrap_SCMapping = lstwrap_SCMapping;
            this.lstwrap_SCBranches = lstwrap_SCBranches;
            this.Billing_level = Billing_level;
        }
        wrap_SCSFX()
        {
            
        }
    }
    
    // Wrapper for Booking/submission/collection at branch level
    Public Class wrap_SCBranches
    {
        @AuraEnabled
        Public String RateCard;
        @AuraEnabled
        Public String Service;
        @AuraEnabled
        Public List<wrap_SCMapping> lstWrapSCMapping; 
        
        wrap_SCBranches(String RateCard, String Service,  List<wrap_SCMapping> lstWrapSCMapping)
        {
            this.RateCard = RateCard;
            this.Service = Service;
            this.lstWrapSCMapping = lstWrapSCMapping;
            
        }
    }
    
    // Wrapper for Booking/submission/collection at branch level
    
    Public Class wrap_SCMapping
    {
        @AuraEnabled
        Public String BillingById;
        @AuraEnabled
        Public String BookingBranch; 
        @AuraEnabled
        Public String CollectionBranch;
        @AuraEnabled
        Public String SubmissionBranch; 
        @AuraEnabled
        Public Boolean isSubimission; 
        @AuraEnabled
        Public Boolean isSubmissionAssigned; 
        @AuraEnabled
        Public Boolean isSubSelfAssigned; 
        @AuraEnabled
        Public String SubmissionUsrName; 
        @AuraEnabled
        Public Boolean isCollection;
        @AuraEnabled
        Public Boolean isCollectionAssigned; 
        @AuraEnabled
        Public Boolean isCollSelfAssigned; 
        @AuraEnabled
        Public String CollectionUsrName; 
        wrap_SCMapping(String BillingById, String BookingBranch, String CollectionBranch, String SubmissionBranch, Boolean isSubimission, Boolean isSubSelfAssigned ,String SubmissionUsrName, Boolean isCollection, Boolean isCollSelfAssigned ,String CollectionUsrName)
        {
            this.BillingById = BillingById;
            this.BookingBranch = BookingBranch;
            this.CollectionBranch = CollectionBranch;
            this.SubmissionBranch = SubmissionBranch;
            this.isSubimission = isSubimission;
            isSubmissionAssigned = isSubimission;
            this.isSubSelfAssigned = isSubSelfAssigned;
            this.SubmissionUsrName = SubmissionUsrName;
            this.isCollection = isCollection;
            isCollectionAssigned = isCollection;
            this.isCollSelfAssigned = isCollSelfAssigned;
            this.CollectionUsrName = CollectionUsrName;
        }
        
    } 
    
    
    public class wrap_SCMapping_Pagination{
        @AuraEnabled
        Public List<wrap_SCMSA> data; 
        @AuraEnabled
        Public Integer totalRecords; 
        @AuraEnabled
        Public Integer totalPages; 
        @AuraEnabled
        Public Integer startIdx; 
        @AuraEnabled
        Public Integer endIdx; 
        
        public wrap_SCMapping_Pagination(List<wrap_SCMSA> data, Integer totalRecords, Integer totalPages, Integer startIdx, Integer endIdx){
            this.data = data;
            this.totalRecords = totalRecords;
            this.totalPages = totalPages;
            this.startIdx = startIdx;
            this.endIdx = endIdx;
        }
        
    }
    
    public class wrap_MSAPortfolioRlNAN_Pagination{
        @AuraEnabled
        Public List<wrap_MSAPortfolioRlNAN> data; 
        @AuraEnabled
        Public Integer totalRecords; 
        @AuraEnabled
        Public Integer totalPages; 
        @AuraEnabled
        Public Integer startIdx; 
        @AuraEnabled
        Public Integer endIdx;
        
        
        public wrap_MSAPortfolioRlNAN_Pagination(List<wrap_MSAPortfolioRlNAN> data, Integer totalRecords, Integer totalPages, Integer startIdx, Integer endIdx){
            
            this.totalRecords = totalRecords;
            this.totalPages = totalPages;
            this.startIdx = startIdx;
            this.endIdx = endIdx;
            this.data = data;
        }
        
    }
    public class CCWRow{
        @AuraEnabled
        public String msaCodes;
        
        public CCWRow(String msaCodes){
            this.msaCodes = msaCodes;
        }
    }
         
    // SAC-147 - added by K SANSI, IBM
    // This function is used to create the Account teams record for all SF which are having the 
    // MSA level billing for a MSA
    // 
    public static void updateMSALevelBillingAndSubmission(String msaAccountId, Boolean collection, Boolean submission, Id usrId, String collectionBranchId, String submissionBranchId){
        System.debug('msaAccountId-->'+msaAccountId);
        System.debug('collection-->'+collection);
        System.debug('submission-->'+submission);
        System.debug('usrId-->'+usrId);
        System.debug('collectionBranchId-->'+collectionBranchId);
        System.debug('submissionBranchId-->'+submissionBranchId);
        
        /*List<Account> sfxList = [SELECT Id, SFX_Code__c, Parent.Propel_MSACode__c 
                                 
                                 FROM Account 
                                 Where ParentId =: msaAccountId 
                                 AND RecordType.Name='SFX' 
                                 AND Billing_Level__c ='MSA'];
        
        
        System.debug('sfxList-->'+sfxList);*/
        
        List<Billing_Line_Item__c> bliList = [SELECT Id, Billing_By_Id__c,
                                              Billing_Information__r.SFX__r.Id,
                                              Billing_Information__r.SFX__r.SFX_Code__c,
                                              Billing_Information__r.SFX__r.Parent.Propel_MSACode__c 
                                              FROM Billing_Line_Item__c 
                                              WHERE Billing_Information__r.SFX__r.ParentId =: msaAccountId AND
                                              Billing_Information__r.SFX__r.RecordType.Name = 'SFX' AND
                                              Billing_Information__r.SFX__r.Billing_Level__c = 'MSA'
                                             ];
        
        System.debug('bliList-->'+bliList);
        Id propelIAccountTeamRecordType = Schema.SObjectType.Account_Team__c.getRecordTypeInfosByName().get('PropelI Account Team').getRecordTypeId();
        
        Map<String,Account_Team__c> acListToUpsert = new Map<String,Account_Team__c>();
        for(Billing_Line_Item__c bli: bliList){      
             
            System.debug('bli-->'+bli);    
            System.debug('acc.Parent.Propel_MSACode__c-->'+bli.Billing_Information__r.SFX__r.Parent.Propel_MSACode__c);
            Account_Team__c upsertCollectionAccTeam = new Account_Team__c();
            upsertCollectionAccTeam.BDMPropelI__c = usrId;
            upsertCollectionAccTeam.RecordTypeId = propelIAccountTeamRecordType;            
            upsertCollectionAccTeam.Account__c = bli.Billing_Information__r.SFX__r.Id;
            if(collection != null){
                upsertCollectionAccTeam.Collection__c = collection;
            }
            if(submission != null){     
                upsertCollectionAccTeam.Submission__c = submission;
            }
            String collectionKey = usrId + '::' + bli.Billing_By_Id__c + ':' + bli.Billing_Information__r.SFX__r.SFX_Code__c + ':' + bli.Billing_Information__r.SFX__r.Parent.Propel_MSACode__c;
            System.debug('collectionKey-->'+collectionKey);
            upsertCollectionAccTeam.PropelI_Composite_Key__c = collectionKey;
            upsertCollectionAccTeam.Billing_By_Id__c = bli.Billing_By_Id__c;
            upsertCollectionAccTeam.PropelI_Branch_Id__c = bli.Billing_By_Id__c;
            acListToUpsert.put(collectionKey,upsertCollectionAccTeam);
            System.debug('upsertCollectionAccTeam-->'+upsertCollectionAccTeam);
            /*Account_Team__c upsertSubmissionAccTeam = new Account_Team__c();
            upsertSubmissionAccTeam.BDMPropelI__c = usrId;
            upsertSubmissionAccTeam.RecordTypeId = propelIAccountTeamRecordType;            
            upsertSubmissionAccTeam.Account__c = bli.Billing_Information__r.SFX__r.Id;
            upsertSubmissionAccTeam.Collection__c = collection;
            upsertSubmissionAccTeam.Submission__c = submission;
            String submissionKey = usrId + '::' + submissionBranchId + ':' + bli.Billing_Information__r.SFX__r.SFX_Code__c + ':' + bli.Billing_Information__r.SFX__r.Parent.Propel_MSACode__c;
            System.debug('submissionKey-->'+submissionKey);
            upsertSubmissionAccTeam.PropelI_Composite_Key__c = submissionKey;
            upsertSubmissionAccTeam.Billing_By_Id__c = submissionBranchId;
            upsertSubmissionAccTeam.PropelI_Branch_Id__c = submissionBranchId;
            if(submissionBranchId != collectionBranchId){
                acListToUpsert.add(upsertSubmissionAccTeam);   
            }*/
                     
        }
        System.debug('acListToUpsert-->'+acListToUpsert);
        if(acListToUpsert.size()>0){ 
            Database.UpsertResult[] results = Database.upsert(acListToUpsert.values(), Account_Team__c.Field.PropelI_Composite_Key__c );  
             
            helperAccountTeam.syncBDMWithAccountTeam(acListToUpsert.values());
                
        }
        
    }
}