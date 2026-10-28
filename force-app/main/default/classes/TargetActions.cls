//Helper class for Target Trigger to perform various operations like updating the owner of target records according to particular region, creating target records for the
//AM and BDM users etc.
Public class TargetActions
{
    public static boolean createAutoTarget = false;
    
    //Method to update the owner on the target object according to region 
    public static void changeOwner(List<Target__c> newList){
        try{
            set<string> regionSet = new set<string>();
            Map<String,List<Id>> mapRegionToUser = new Map<String,List<Id>>();
            for(Target__c  tar1 : newList)
            {
                if(string.isNotBlank(tar1.Region__c)) 
                {
                    regionSet.add(tar1.Region__c);
                }
            }
            for(User us : [Select id,Region__c from User where Region__c IN : regionSet and profile.name = 'Regional Manager']){
                if(mapRegionToUser.containsKey(us.Region__c))
                    mapRegionToUser.get(us.Region__c).add(us.id);
                else
                    mapRegionToUser.put(us.Region__c ,new List<Id>{us.id});        
            }
            System.debug('<< mapRegionToUser >> '+mapRegionToUser);
            if(mapRegionToUser.size() > 0){
                for(Target__c  tar1 : newList){
                    if(mapRegionToUser.containsKey(tar1.Region__c)){
                        tar1.ownerId = mapRegionToUser.get(tar1.Region__c)[0];
                    }
                }
            }
        }catch(Exception e){
            System.debug('<<< err message >>>'+e.getMessage());
            System.debug('<<< err line number >>>'+e.getLineNumber());
            //system.assert(false, e.getMessage());
        }
    }
    
    //Method to create the Targets for AM and BDM users as well
    public static void createAutoTarget(List<Target__c> newList)
    {
        try{
            set<string> regionSet = new set<string>();
            for(Target__c  tar1 : newList)
            {
                if(string.isNotBlank(tar1.Region__c)) 
                {
                    regionSet.add(tar1.Region__c);
                }
            }
            
            if(regionSet.size() > 0 )
            {
                List<User> userListAM = [select Id, Area__c, UserRoleId, Type__c, Region__c from USer where Region__c in : regionSet and UserRole.Name like 'AM%' ];
                List<RecordType> AreaBDMRT = [Select Id, DeveloperName from RecordType where SobjectType= 'Target__c' and DeveloperName = 'Area_BDM' limit 1] ;
                Id AreaBDMRTId = AreaBDMRT[0].Id;
                Set<Id> AMUserRoleIDSet = new set<Id>(); 
                Map<Id, Target__c> AMRoleToTargetMap = new Map<Id, Target__c>(); 
                
                List<Target__c> targetToInsert = new list<Target__c>();
                Target__c temp ;
                
                for(Target__c  tar1 : newList)
                {
                    for(User AM : userListAM)
                    {
                        if(string.isNotBlank(AM.Region__c) && AM.Region__c == tar1.Region__c && string.isNotBlank(AM.Type__c) && (AM.Type__c == tar1.Business_Type__c || AM.Type__c == 'Credit+Retail'))
                        {
                            temp  = tar1.clone(false, true, false, false);
                            temp.Level__c = 'Area Level';
                            temp.OwnerId = AM.Id;
                            temp.Area__c = AM.Area__c;
                            temp.Parent_Target__c = tar1.Id;
                            temp.IsAutoCreated__c = true;
                            temp.recordTypeId = AreaBDMRTId;
                            AMRoleToTargetMap.put(AM.UserRoleId, temp);
                            AMUserRoleIDSet.add(AM.UserRoleId);
                        }
                    }
                }
                
                if(AMRoleToTargetMap.Values().size() > 0)
                {
                    insert AMRoleToTargetMap.Values();
                }
                
                
                if(AMRoleToTargetMap.keySet().size() > 0 )
                {
                    Set<ID> childBDMRoleIds = getAllSubRoleIds(AMRoleToTargetMap.keySet());
                    
                    if(childBDMRoleIds.size() > 0 )
                    {
                        List<User> userListBDM = [select Id, Area__c, UserRole.ParentRoleID, Type__c, Region__c  from USer where Region__c in : regionSet and UserRole.Name like 'BDM%' and UserRoleId in :childBDMRoleIds ];
                        
                        for(Target__c  tar1 : newList)
                        {
                            for(User BDM : userListBDM )
                            {
                                if(string.isNotBlank(BDM.Region__c) && BDM.Region__c == tar1.Region__c && string.isNotBlank(BDM.Type__c) && (BDM.Type__c == tar1.Business_Type__c || BDM.Type__c == 'Credit+Retail'))
                                {
                                    temp  = tar1.clone(false, true, false, false);
                                    temp.Level__c = 'BDM Level';
                                    temp.OwnerId = BDM.Id;
                                    temp.BDM__c = BDM.Id;
                                    temp.Area__c = BDM.Area__c;
                                    temp.IsAutoCreated__c = true;
                                    temp.recordTypeId = AreaBDMRTId;
                                    temp.Parent_Target__c = ( BDM.UserRole.ParentRoleID != null && AMRoleToTargetMap.containsKey(BDM.UserRole.ParentRoleID)) ?
                                        AMRoleToTargetMap.get(BDM.UserRole.ParentRoleID).Id : null;
                                    targetToInsert.add(temp  );
                                }
                            }
                        }        
                    }                                                                                                                                             
                }  
                
                if(targetToInsert.size() > 0)
                {
                    insert targetToInsert;
                }  
                
            }
            
        }catch(Exception e){
            System.debug('<<< err message >>>'+e.getMessage());
            System.debug('<<< err line number >>>'+e.getLineNumber());
            //system.assert(false, e.getMessage());
        }
    }
    
    //Method to query the child role Id under parent role Ids
    public static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {
        
        Set<ID> currentRoleIds = new Set<ID>();
        
        // get all of the roles underneath the passed roles
        for(UserRole userRole :[select Id, ParentRoleId from UserRole where ParentRoleId IN :roleIds AND ParentRoleID != null])
        {
            currentRoleIds.add(userRole.Id);
        }
        
        return currentRoleIds;
    }
}