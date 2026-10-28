//Class for Portfolio management (Creating Account Team under Account)
public class PortfolioClass {
    
    //Method to query account team records according to selected user
    @AuraEnabled
    public static List<Account_Team__c> getAccounts(String uname){
        System.debug('uname++'+uname);
        List<Account_Team__c> lstAccount = [select id, name, BDM__c, Collection__c,Relationship__c,Submission__c, Account__r.name, Account__r.SFX_Code__c,Account__r.Propel_Id__c,Account__r.Booking_Branch__r.Name,Account__r.Collection_Branch__r.Name,Account__r.Submission_Branch__r.Name,
                                            National1__c,National2__c,National3__c,National4__c,CRS__c,Account__r.Relationship__c,Account__r.Collection__c,Account__r.Submission__c,Account__r.National1__c,Account__r.National2__c,Account__r.National3__c,Account__r.National4__c from Account_Team__c where BDM__c =:uname and
                                           (Relationship__c=true or Collection__c=true or Submission__c=true or National1__c=true or
                                                            National2__c=true or National3__c=true or National4__c=true or CRS__c=true)];
        if(!lstAccount.isEmpty()){
            return lstAccount;
        }
        else{
            return null;
        }
    }     
    
    //Method to query account team records according to selected user and SFX code
    @AuraEnabled
    public static List<Account_Team__c> getAccountTeamSearch(String uname,String key){
        System.debug('uname++'+uname);
        String searchkey = key + '%';
        List<Account_Team__c> lstAccountTeam = [select id, name, BDM__c, Collection__c,Relationship__c,Submission__c, Account__r.name, Account__r.SFX_Code__c,Account__r.Propel_Id__c,Account__r.Booking_Branch__r.Name,Account__r.Collection_Branch__r.Name,Account__r.Submission_Branch__r.Name,
                                            National1__c,National2__c,National3__c,National4__c,CRS__c,Account__r.Relationship__c,Account__r.Collection__c,Account__r.Submission__c,Account__r.National1__c,Account__r.National2__c,Account__r.National3__c,Account__r.National4__c from Account_Team__c where BDM__c =:uname and
                                           (Relationship__c=true or Collection__c=true or Submission__c=true or National1__c=true or
                                                            National2__c=true or National3__c=true or National4__c=true or CRS__c=true) and (Account__r.name LIKE: searchkey or Account__r.SFX_Code__c like: searchkey)];
        if(!lstAccountTeam.isEmpty()){
            return lstAccountTeam;
        }
        else{
            return null;
        }
    }  
    
    //Method to fetch those SFX accounts which are not having account team having BDM as selected User
    @AuraEnabled
    public static List<Account> getAll(String uname){
        System.debug('uname++'+uname);
        Set<Id> setId = new Set<Id>();
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        for(Account_Team__c at:[select id,account__c from account_team__c where BDM__c =:uname])//BDM__c='0050l000000vGxE'
        {
            setId.add(at.account__c);
        }
        system.debug('setId++'+setId);
        List<account> lstAccount = [select id,name,Propel_Id__c, SFX_Code__c,Submission_Branch__r.Name, Booking_Branch__r.name,Collection_Branch__r.Name,Collection__c,Relationship__c,Submission__c,National1__c,National2__c,National3__c,National4__c                                    
                                    from account where recordtypeid =: rId and ownerid!=:uname and id NOT in: setId];//(select id,BDM__c,Collection__c,Relationship__c,Submission__c from Account_Teams__r)
                
        return lstAccount;
    }
    
    //Method to fetch those SFX accounts which are not having account team having BDM as selected User and having SFX code as search key
    @AuraEnabled
    public static List<Account> getallsearch(String key,Id uname){
        String searchkey = key + '%';
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SFX Customer').getRecordTypeId();
        Set<Id> setId = new Set<Id>();
        for(Account_Team__c at:[select id,account__c from account_team__c where BDM__c=:uname])//BDM__r.Name=:uname
        {
            setId.add(at.account__c);
        }
        List<Account> lstAccount = [select id,name,SFX_Code__c,Submission_Branch__r.Name,Booking_Branch__r.Name,Collection_Branch__r.Name,Collection__c,Relationship__c,Submission__c,National1__c,National2__c,National3__c,National4__c from account where ownerId !=: uname and recordtypeid =: rId and id NOT in: setId and (name LIKE: searchkey or SFX_Code__c LIKE: searchkey )];//where ownerid!='0050l000000vGxE' and (or Booking_Branch__r.Name LIKE: searchkey)
        if(!lstAccount.isEmpty()){
            return lstAccount;
        }
        else{
            return null;
        }
    }    
    
    //Method to createAccountTeam
    @AuraEnabled
    public static void CreateATeam(List<Id> lstId,Map<String,object> mp,Id uname){
        
        system.debug('++'+mp);
        map<Id,String> mapCol = new map<Id,String>();
        map<Id,String> mapSub = new map<Id,String>();
        map<Id,String> mapNat1 = new map<Id,String>();
        map<Id,String> mapNat2 = new map<Id,String>();
        map<Id,String> mapNat3 = new map<Id,String>();
        map<Id,String> mapNat4 = new map<Id,String>();
        map<Id,String> mapCRS = new map<Id,String>();
        //User u = [select id from user where name =: uname limit 1];
        Object rel = mp.get('rel');
        Object col = mp.get('col');
        Object sub = mp.get('sub');
        Object nat1 = mp.get('n1');
        Object nat2 = mp.get('n2');
        Object nat3 = mp.get('n3');
        Object nat4 = mp.get('n4');
        Object crs = mp.get('crs');
        List<Id> lrel = new List<Id>();
        List<Id> lcol = new List<Id>();
        List<Id> lsub = new List<Id>();
        List<Id> lnat1 = new List<Id>();        
        if(rel != null){
            for (Object o : (List<Object>)rel){
                lrel.add((Id)o);
            } 
        }
        if(col != null){
            for (Object o : (List<Object>)col){
                lcol.add((Id)o);
                mapCol.put((Id)o,'false');
            }
        }
        if(sub != null){
            for (Object o : (List<Object>)sub){
                lsub.add((Id)o);
                mapSub.put((Id)o,'false');
            } 
        }
        if(nat1 != null){
            for (Object o : (List<Object>)nat1){
                lnat1.add((Id)o);
                mapNat1.put((Id)o,'false');
            }
        }
        if(nat2 != null){
            for (Object o : (List<Object>)nat2){                
                mapNat2.put((Id)o,'false');
            }
        }
        if(nat3 != null){
            for (Object o : (List<Object>)nat3){                
                mapNat3.put((Id)o,'false');
            }
        }
        if(nat4 != null){
            for (Object o : (List<Object>)nat4){               
                mapNat4.put((Id)o,'false');
            }
        }
        if(crs != null){
            for (Object o : (List<Object>)crs){                
                mapCRS.put((Id)o,'false');
            }
        }
        List<Account_Team__c> lstAT = new List<Account_Team__c>();
        for(Id i:lrel){
            Account_Team__c a = new Account_Team__c();
            a.Account__c = i;
            a.BDM__c = uname; //u.Id;
            a.Relationship__c = true;
            if(mapCol.containsKey(i) && mapCol.get(i) == 'false'){                
                a.Collection__c = true;            
                mapCol.put(i,'true');
            }
            if(mapSub.containsKey(i) && mapSub.get(i) == 'false'){                
                a.Submission__c = true;            
                mapSub.put(i,'true');
            }
            if(mapNat1.containsKey(i) && mapNat1.get(i) == 'false'){                
                a.National1__c = true;            
                mapNat1.put(i,'true');
            }
            if(mapNat2.containsKey(i) && mapNat2.get(i) == 'false'){                
                a.National2__c = true;            
                mapNat2.put(i,'true');
            }
            if(mapNat3.containsKey(i) && mapNat3.get(i) == 'false'){                
                a.National3__c = true;            
                mapNat3.put(i,'true');
            }
            if(mapNat4.containsKey(i) && mapNat4.get(i) == 'false'){                
                a.National4__c = true;            
                mapNat4.put(i,'true');
            }
            if(mapCRS.containsKey(i) && mapCRS.get(i) == 'false'){                
                a.CRS__c = true;            
                mapCRS.put(i,'true');
            }
            lstAT.add(a);
        }
        for(Id i: mapCol.keySet()){
            if(mapCol.get(i) == 'false'){
                Account_Team__c a = new Account_Team__c();
                a.Account__c = i;
                a.BDM__c = uname; //u.Id;
                a.Collection__c = true;
                if(mapSub.containsKey(i) && mapSub.get(i) == 'false'){
                    a.Submission__c = true;
                    mapSub.put(i,'true');
                }
                if(mapNat1.containsKey(i) && mapNat1.get(i) == 'false'){                    
                    a.National1__c = true;            
                    mapNat1.put(i,'true');
                }
                if(mapNat2.containsKey(i) && mapNat2.get(i) == 'false'){                    
                    a.National2__c = true;            
                    mapNat2.put(i,'true');
                }
                if(mapNat3.containsKey(i) && mapNat3.get(i) == 'false'){                    
                    a.National3__c = true;            
                    mapNat3.put(i,'true');
                }
                if(mapNat4.containsKey(i) && mapNat4.get(i) == 'false'){                    
                    a.National4__c = true;            
                    mapNat4.put(i,'true');
                }
                if(mapCRS.containsKey(i) && mapCRS.get(i) == 'false'){                    
                    a.CRS__c = true;            
                    mapCRS.put(i,'true');
                }
                lstAT.add(a);
            }
        }
        for(Id i: mapSub.keySet()){
            if(mapSub.get(i) == 'false'){
                Account_Team__c a = new Account_Team__c();
                a.Account__c = i;
                a.BDM__c = uname; //u.Id;
                a.Submission__c = true;
                if(mapNat1.containsKey(i) && mapNat1.get(i) == 'false'){
                    a.National1__c = true;
                    mapNat1.put(i,'true');
                }
                if(mapNat2.containsKey(i) && mapNat2.get(i) == 'false'){                    
                    a.National2__c = true;            
                    mapNat2.put(i,'true');
                }
                if(mapNat3.containsKey(i) && mapNat3.get(i) == 'false'){                    
                    a.National3__c = true;            
                    mapNat3.put(i,'true');
                }
                if(mapNat4.containsKey(i) && mapNat4.get(i) == 'false'){                    
                    a.National4__c = true;            
                    mapNat4.put(i,'true');
                }
                if(mapCRS.containsKey(i) && mapCRS.get(i) == 'false'){                    
                    a.CRS__c = true;            
                    mapCRS.put(i,'true');
                }
                lstAT.add(a);
            }
        }
        
        for(Id i: mapNat1.keySet()){
            if(mapNat1.get(i) == 'false'){
                Account_Team__c a = new Account_Team__c();
                a.Account__c = i;
                a.BDM__c = uname; //u.Id;
                a.National1__c = true;
                if(mapNat2.containsKey(i) && mapNat2.get(i) == 'false'){                    
                    a.National2__c = true;            
                    mapNat2.put(i,'true');
                }
                if(mapNat3.containsKey(i) && mapNat3.get(i) == 'false'){                    
                    a.National3__c = true;            
                    mapNat3.put(i,'true');
                }
                if(mapNat4.containsKey(i) && mapNat4.get(i) == 'false'){                    
                    a.National4__c = true;            
                    mapNat4.put(i,'true');
                }
                if(mapCRS.containsKey(i) && mapCRS.get(i) == 'false'){                    
                    a.CRS__c = true;            
                    mapCRS.put(i,'true');
                }
                lstAT.add(a);
            }
        }
        for(Id i: mapNat2.keySet()){
            if(mapNat2.get(i) == 'false'){
                Account_Team__c a = new Account_Team__c();
                a.Account__c = i;
                a.BDM__c = uname; //u.Id;
                a.National2__c = true;
                if(mapNat3.containsKey(i) && mapNat3.get(i) == 'false'){                    
                    a.National3__c = true;            
                    mapNat3.put(i,'true');
                }
                if(mapNat4.containsKey(i) && mapNat4.get(i) == 'false'){                    
                    a.National4__c = true;            
                    mapNat4.put(i,'true');
                }
                if(mapCRS.containsKey(i) && mapCRS.get(i) == 'false'){                    
                    a.CRS__c = true;            
                    mapCRS.put(i,'true');
                }
                lstAT.add(a);
            }
        }
        
        for(Id i: mapNat3.keySet()){
            if(mapNat3.get(i) == 'false'){
                Account_Team__c a = new Account_Team__c();
                a.Account__c = i;
                a.BDM__c = uname; //u.Id; 
                a.National3__c = true;
                if(mapNat4.containsKey(i) && mapNat4.get(i) == 'false'){
                    system.debug('else++');
                    a.National4__c = true;            
                    mapNat4.put(i,'true');
                }
                if(mapCRS.containsKey(i) && mapCRS.get(i) == 'false'){
                    system.debug('else++');
                    a.CRS__c = true;            
                    mapCRS.put(i,'true');
                }
                lstAT.add(a);
            }
        }       
        for(Id i: mapNat4.keySet()){
            if(mapNat4.get(i) == 'false'){
                Account_Team__c a = new Account_Team__c();
                a.Account__c = i;
                a.BDM__c = uname; //u.Id; 
                a.National4__c = true;                
                
                if(mapCRS.containsKey(i) && mapCRS.get(i) == 'false'){                    
                    a.CRS__c = true;            
                    mapCRS.put(i,'true');
                }
                lstAT.add(a);
            }
            
        }     
        for(Id i: mapCRS.keySet()){
            if(mapCRS.get(i) == 'false'){
                Account_Team__c a = new Account_Team__c();
                a.Account__c = i;
                a.BDM__c = uname; //u.Id;
                a.CRS__c = true;                
                lstAT.add(a);
            }
            
        }   
        if(!lstAT.isEmpty()){
            insert lstAT;
        }
    }
    
    //Method to update the 
    @AuraEnabled
    public static void removeATeam(List<Account_Team__c> lstAT,String uname){        
        if(!lstAT.isEmpty()){
            update lstAT;
        }
    }
    
    //Returning list of user according to selected department
    @AuraEnabled
    public static List<user> getUsers(String dept){        
        List<user> lstUser = [select Id,name,AD_Id__c from user where designation__c =: dept AND isActive= True]; //Added by Monika on 20-12-2019
        lstUser.sort(); //Added by Monika on 20-12-2019
        return lstUser;
    }
    
    //Method to get the values of Designation picklist
    @AuraEnabled
    public static List<string> getDepartment(){
        List<String> lstDepartment = new List<String>();
        Schema.DescribeFieldResult fieldResult = User.Designation__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            lstDepartment.add(f.getValue());
        } 
        return lstDepartment;
    }
}