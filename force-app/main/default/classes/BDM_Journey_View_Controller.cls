/**
* Description		:		Test class to test Todays Event component controller
* Created By       :       Shubham Girdhar
* Created Date     :       10th jan, 2020
* Release          :       25th jan, 2020
* Last Modified on :
* Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
**/
public with sharing class BDM_Journey_View_Controller {
    // method to get users under a role
    public static Set<ID> getAllSubRoleIds(Set<ID> roleIds) { //AM view
        Set<ID> currentRoleIds = new Set<ID>();    
        // get all of the roles underneath the passed roles
        for(UserRole userRole :[select Id from UserRole where ParentRoleId 
                                IN :roleIds AND ParentRoleID != null]) {
                                    currentRoleIds.add(userRole.Id);
                                }    
        // go fetch some more rolls!
        if(currentRoleIds.size() > 0) {
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }    
        return currentRoleIds;
    }
    
    // method to get all team members of current user
    @AuraEnabled
    public Static List<User> getallusers(Id UserId){ //AM view
        List<User> userList = new List<User>();
        set<Id> User1 = new Set<Id>();
        User userDetail = [select id, name, userRoleId from User where Id =: UserId ];
        User1.add(UserDetail.UserRoleId);
        
        set<Id> UserRoleId = getAllSubRoleIds(User1);
        userList = [Select id, name, userRoleId from user where userRoleId IN:UserRoleId and IsActive=true ORDER BY name ASC];
        return userList;
    }
    
    // method to get number of team members of current user
    @AuraEnabled
    public static Integer getusersNumber(Id UserId){ //AM view
        integer NumberOfJourney = 0;
        List<User> userList = new List<User>();
        set<Id> User1 = new Set<Id>();
        User userDetail = [select id, name, userRoleId from User where Id =: UserId ];
        User1.add(UserDetail.UserRoleId);      
        set<Id> UserRoleId = getAllSubRoleIds(User1);
        userList = [Select id, name, userRoleId from user where userRoleId IN:UserRoleId and IsActive=true ORDER BY name ASC];
        NumberOfJourney = userList.size();
        return NumberOfJourney;
    }
    
    // Method to get list of journey between start and end date
    @AuraEnabled
    public static list<Journey__c> GetJourneyListToApprove(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyListToApprove'+CurrentUserId);
        list<Journey__c> JourneyList = new List<Journey__c>();
        JourneyList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Remarks__c,
                       Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c from Journey__c where ownerId =: CurrentUserId
                       AND Approval_Status__c IN ('Submitted for Approval','Pending from Manager','Pending from RM')
                       AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ORDER BY Journey_Date__c DESC];
        System.debug('JourneyList : '+JourneyList);
        return JourneyList;
    }
        
    
    // Start SAC-1201 || Deepika Thakur || IBM        
    // method to get all the journey of a user where status is Approved by RM, Approved by manager
    @AuraEnabled
    public static list<Journey__c> GetJourneyListApproved(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyListApproved'+CurrentUserId);
        list<Journey__c> JourneyList = new List<Journey__c>();
        JourneyList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Remarks__c,
                       Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c from Journey__c where ownerId =: CurrentUserId
                       AND Approval_Status__c IN ('Approved By RM','Approved by Manager','Auto Approved')
                       AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ORDER BY Journey_Date__c DESC];
        return JourneyList;
    }
    
    // method to get all the journey of a user where status is Rejected by RM, Rejected by manager
    @AuraEnabled
    public static list<Journey__c> GetJourneyListRejected(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyListRejected'+CurrentUserId);
        list<Journey__c> JourneyList = new List<Journey__c>();
        JourneyList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Remarks__c,
                       Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c from Journey__c where ownerId =: CurrentUserId
                       AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM')
                       AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ORDER BY Journey_Date__c DESC];
        return JourneyList;
    }
    
    // method to get all the journey of a user where Journey is checked-out and eligible to be submitted for approval
    @AuraEnabled
    public static list<Journey__c> GetJourneyListToBeSubmitted(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyListToBeSubmitted'+CurrentUserId);
        list<Journey__c> JourneyList = new List<Journey__c>();
        JourneyList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Remarks__c,
                       Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c, CheckOut_Date__c from Journey__c where CheckOut_Date__c!=null AND ownerId =: CurrentUserId
                       AND Approval_Status__c IN ('Not Submitted for Approval')
                       AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ORDER BY Journey_Date__c DESC];
        return JourneyList;
    }
    
    // method to get all the journey of a user where Journey is marked as 'Not to Be Claimed'
    @AuraEnabled
    public static list<Journey__c> GetJourneyListNotToBeClaimed(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyListNotToBeClaimed'+CurrentUserId);
        list<Journey__c> JourneyList = new List<Journey__c>();
        JourneyList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Remarks__c,
                       Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c from Journey__c where ownerId =: CurrentUserId
                       AND Approval_Status__c IN ('Not to Be Claimed')
                       AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ORDER BY Journey_Date__c DESC];
                return JourneyList;
    }    
    // End SAC-1201 || Deepika Thakur || IBM   
    
   
    // Method to get lsit of journey on the selected month
    @AuraEnabled
    public static list<Journey__c> GetJourneyListMonth(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyListMonth'+CurrentUserId);
        list<Journey__c> JourneyList = new List<Journey__c>();
        JourneyList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Remarks__c,
                       Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c from Journey__c where ownerId =: CurrentUserId
                       AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ORDER BY Journey_Date__c DESC];
        
        return JourneyList;
    }
    // Method to get total number of journeys on a selected month
    @AuraEnabled
    public static Integer GetJourneyCount(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyCount'+CurrentUserId);
        AggregateResult[] JourneyAggregate = [select COUNT(id) from Journey__c where ownerId =: CurrentUserId
                                              AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Integer JourneyCount = (Integer)JourneyAggregate[0].get('expr0');
        return JourneyCount;
    }
    // Method to get total amount of journeys in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalAmount(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyTotalAmount'+CurrentUserId);
        AggregateResult[] JourneyAggregateAmount = [select SUM(Final_Amount__c) from Journey__c where ownerId =: CurrentUserId
                                                    AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
        return JourneyTotalAmount;
    }
    // Method to get total amount of journeys in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalApprovedAmount(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyTotalApprovedAmount'+CurrentUserId);
        AggregateResult[] JourneyAggregateAmount = [select SUM(Approved_Amount__c) from Journey__c where ownerId =: CurrentUserId
                                                    AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalApprovedAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
        return JourneyTotalApprovedAmount;
    }
    // Method to get total number of events in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalEvent(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyTotalEvent'+CurrentUserId);
        AggregateResult[] JourneyAggregateEventCount = [select SUM(Number_Of_Event__c) from Journey__c where ownerId =: CurrentUserId
                                                        AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalEvent = (Decimal)JourneyAggregateEventCount[0].get('expr0');
        return JourneyTotalEvent;
    }
    // Method to get total number of distance in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalDistance(Integer Year, Integer Month , Id CurrentUserId ){
        system.debug('GetJourneyTotalDistance'+CurrentUserId);
        AggregateResult[] JourneyAggregateDistance = [select SUM(Journey_KM__c) from Journey__c where ownerId =: CurrentUserId
                                                      AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalDistance = (Decimal)JourneyAggregateDistance[0].get('expr0');
        return JourneyTotalDistance;
    }
    // Method to get List of event on selected journey
    @AuraEnabled
    public static list<Event__c> GetEventList(list<String> JourneyId){
        system.debug('GetEventList'+JourneyId);
        
        list<Event__c> EventList = new List<Event__c>();
        EventList = [select id, name,Journey__c,Status__c,Event_Purpose__c,Remarks__c,/*Virtual_Meeting__c,*/ Distance__c,Campaign__c,Campaign__r.Name,Contact__r.Name,Time_Spent_Auto__c,Contact__c from Event__c where Journey__c IN :JourneyId];   
        system.debug('@@@@@@@@@@@@'+ EventList);
        return EventList;
    }
    // Method to get list of Expense on a selected journey
    @AuraEnabled
    public static list<Expense_Item__c> GetExList(list<String> JourneyId){
        system.debug('GetExList'+JourneyId);
        list<Expense_Item__c> ExList = new List<Expense_Item__c>();
        ExList = [select id, Journey__c, name, Amount__c, Bill_Number__c,Comment__c, Expense_Type__c, Check_In_Date__c, Check_Out_Date__c from Expense_Item__c where Journey__c IN :JourneyId];   
        system.debug('@@@@@@@@@@@@'+ ExList);
        return ExList;
    }
    
    /* @AuraEnabled
public static Object GetMapData(Id JorId){
Journey__c jor = new Journey__c();
jor = [SELECT id , name,CheckIn_Location__c,Number_Of_Event__c, CheckOut_Location__c,(SELECT id, CheckIn_Location__c from Events__r) from Journey__c where id =: JorId];
list<String> Locations = new list<String>();
Integer Abc = jor.Number_Of_Event__c.intValue();
system.debug(Abc);
Locations.add(jor.CheckIn_Location__c);
system.debug('Locations fIRST'+Locations);
for(Integer i = 0; i < Abc; i++){
system.debug('IN THE FOR LOOP');
Locations.add(jor.Events__r[i].CheckIn_Location__c);
}
Locations.add(jor.CheckOut_Location__c);
system.debug('Locations@@@@'+Locations);

//JSONGenerator Json = JSON.createGenerator(true);
JSONGenerator gen = JSON.createGenerator(true);
gen.writeStartArray();
for(string ab: Locations){

string[] cd = new string[]{};
cd = ab.split(',');

gen.writeStartObject();
gen.writeFieldName('Location');
gen.writeStartObject();
gen.writeStringField('Latitude', cd[0]);
gen.writeStringField('Longitude',cd[1]);
gen.writeEndObject();
gen.writeEndObject();
}
gen.writeEndArray();
String jsonString = gen.getAsString(); 
system.debug('@@@@@'+jsonString);
return jsonString;
// system.debug('Latitude: '+cd[0]);
// system.debug('Longitude: '+cd[1]);

}
*/
    // Method to get map data on click of map icon
    @AuraEnabled
    public static list<Address> GetMapData(Id JorId){
        list<Address> addressList = new list<Address>(); 
        // Journey__c jor = new Journey__c();
        Journey__c[] jor = [SELECT ID , name,CheckIn_Location__c,Number_Of_Event__c, CheckOut_Location__c, CheckIn_Date__c, CheckOut_Date__c from Journey__c where Id =: JorId];
        List<Event__c> eventList = new list<Event__c>();
        eventList = [SELECT id, CheckIn_Location__c, Journey__c from Event__c where Journey__c =: JorId];
        list<String> Locations = new list<String>();
        Integer Abc = jor[0].Number_Of_Event__c.intValue();
        system.debug(Abc);
        Locations.add(jor[0].CheckIn_Location__c);
        system.debug('Locations fIRST'+Locations);
        for(Integer i = 0; i < Abc; i++){
            system.debug('IN THE FOR LOOP');
            // Locations.add(jor.Events__r[i].CheckIn_Location__c);
            Locations.add(eventList[i].CheckIn_Location__c);
        }
        Locations.add(jor[0].CheckOut_Location__c);
        system.debug('Locations@@@@'+Locations);
        
        //JSONGenerator Json = JSON.createGenerator(true);
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for(string ab: Locations){
            
            string[] cd = new string[]{};
                cd = ab.split(',');
            location location = new location(cd[0], cd[1]);
            addressList.add(new Address(location));
            //    gen.writeStartObject();
            // gen.writeFieldName('Location');
            // gen.writeStartObject();
            // gen.writeStringField('Latitude', cd[0]);
            // gen.writeStringField('Longitude',cd[1]);
            // gen.writeEndObject();
            //    gen.writeEndObject();
        }
        return addressList;
        // gen.writeEndArray();
        //            String jsonString = gen.getAsString(); 
        //                system.debug('@@@@@'+jsonString);
        //                return jsonString;
        // system.debug('Latitude: '+cd[0]);
        // system.debug('Longitude: '+cd[1]);
        
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> GetMapData1(Id JorId) {
        List<Map<String, Object>> addressList = new List<Map<String, Object>>(); 
        
        // Fetch Journey record with required fields
        Journey__c[] jor = [
            SELECT ID, Name, CheckIn_Location__c, CheckOut_Location__c, 
            CheckIn_Date__c, CheckOut_Date__c,CheckIn_Address__c,CheckOut_Address__c
            FROM Journey__c 
            WHERE Id = :JorId
        ];
        
        // Fetch related Events for this Journey
        List<Event__c> eventList = [
            SELECT Id, Name, CheckIn_Location__c, CheckOut_Location__c, 
            CheckIn_Date__c, CheckOut_Date__c,CheckIn_Address__c,CheckOut_Address__c
            FROM Event__c 
            WHERE Journey__c = :JorId
        ];
        
        // Add Journey's check-in location with its check-in and check-out dates
        if (jor.size() > 0) {
            Journey__c journey = jor[0];
            
            // Check-in Location
            addLocationToList(addressList, journey.CheckIn_Location__c, 'Journey-'+journey.Name+' Check-In'/*+' ('+journey.CheckIn_Date__c+')'*/, journey.CheckIn_Date__c, journey.CheckIn_Address__c);
            
            // Add Event locations with their check-in/check-out dates
            for (Event__c event : eventList) {
                if (event.CheckIn_Location__c != null) {
                    addLocationToList(addressList, event.CheckIn_Location__c, 'Event-'+event.Name+' Check-In'/*+' ('+event.CheckIn_Date__c+')'*/, event.CheckIn_Date__c, event.CheckIn_Address__c);
                }
                if (event.CheckOut_Location__c != null) {
                    addLocationToList(addressList, event.CheckOut_Location__c, 'Event-'+event.Name+' Check-Out'/*+' ('+event.CheckOut_Date__c+')'*/, event.CheckOut_Date__c, event.CheckOut_Address__c);
                }
            }
            // Check-out Location
            addLocationToList(addressList, journey.CheckOut_Location__c, 'Journey-'+journey.Name+' Check-Out'/*+' ('+journey.CheckOut_Date__c+')'*/, journey.CheckOut_Date__c, journey.CheckOut_Address__c);
        }
        return addressList;
    }
   
    // Helper method to add locations to the address list
    private static void addLocationToList(List<Map<String, Object>> addressList, String location, String title, DateTime dateVal, String addressVal) {
        if (String.isNotEmpty(location)) {
            String[] coordinates = location.split(',');
            if (coordinates.size() == 2) {
                Map<String, Object> mapMarker = new Map<String, Object>();
                mapMarker.put('location', new Map<String, Object>{
                    'Latitude' => coordinates[0],
                        'Longitude' => coordinates[1]
                        });
                mapMarker.put('title', title);
                mapMarker.put('description', '<b>Date    :</b> ' + String.valueOf(dateVal)+'<br/><b>Address : </b>'+ addressVal);
                addressList.add(mapMarker);
            }
        }
    }
    
    
    
    // Method to get expense type from backend
    @AuraEnabled
    public static list<string> GetExpeseType(){
        list<string> ExpenseType = new list<String>();
        schema.DescribeFieldResult fieldValue =   Expense_Item__c.Expense_Type__c.getDescribe();
        list<schema.PicklistEntry> picklist = fieldValue.getPicklistValues();
        for(schema.PicklistEntry p : picklist){
            ExpenseType.add(p.getValue());
        }
        return ExpenseType;
    }
    // Method to create new expense on click of save button
    @AuraEnabled
    public static Id CreateExpense(Expense_Item__c exp, String JourId){
        exp.Journey__c = JourId;
        insert exp;
        return exp.Id;
    }
    /*
@AuraEnabled  
public static List<ContentDocument> getFiles(string recordId){ 

Set<Id> recordIds=new Set<Id>{recordId};
Set<Id> documentIds = new Set<Id>(); 
List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:recordIds];  
for(ContentDocumentLink cdLink:cdl){  
documentIds.add(cdLink.ContentDocumentId);  
}      
return [SELECT Id,Title,FileType FROM ContentDocument WHERE id IN: documentIds];  
} 

@AuraEnabled  
public static void deleteFiles(string sdocumentId){ 
delete [SELECT Id,Title,FileType from ContentDocument WHERE id=:sdocumentId];       
}
*/
    // method to submit for approval on month bases
    /* @AuraEnabled
public static string submitForApproval(list<Journey__c> jour){
String returnResult = '';
List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
for(journey__c jor: jour){
if(jor.Approval_Status__c == 'Not Submitted for Approval' || jor.Approval_Status__c == 'Rejected by Manager'){
returnResult = 'All Journeys Submitted Successfully';
Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();          
req.setComments('Submitting approval from component');        
req.setObjectId(jor.id);
// Approval.ProcessResult result = Approval.process(req);      
requests.add(req);
}else{
returnResult = 'All Journeys are already submitted for Approval';
}            
}
Approval.ProcessResult[] processResults = Approval.process(requests);
return returnResult;
} */
    // method to submit for approval on single journey 
    @AuraEnabled
    public static string submitForApprovalSingle(id jorId){
        String returnResult = '';
        journey__c jor = [Select id, name, Approval_Status__c from journey__c where id =: jorId ];
        // List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        // for(journey__c jor: jour){
        if(jor.Approval_Status__c == 'Not Submitted for Approval' || jor.Approval_Status__c == 'Rejected by Manager'){            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();          
            req.setComments('Journey Submitted for approval');        
            req.setObjectId(jor.id);
            // Approval.ProcessResult result = Approval.process(req);      
            // requests.add(req);
            Approval.ProcessResult processResults = Approval.process(req);
            returnResult = 'Journey Submitted Successfully';
        }else{
            returnResult = 'This journey is already submitted for Approval';
        }
        // Approval.ProcessResult[] processResults = Approval.process(req);
        return returnResult;
    } 
    // method to get all the journey with status pending for Approval

    @AuraEnabled
    public static List<Journey__c> GetJourneyListMonthTeam(Integer pageNumber, Integer pageSize, Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        Integer offsetVal = (pageNumber - 1) * pageSize;
        
        String baseQuery = 'SELECT Id, Name, OwnerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c, ' +
            'Remarks__c, Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c, Journey_Audited__c, ' +
            'Remarks_To_be_filled_by_Auditors__c FROM Journey__c WHERE ';
        
        // Add filters
        baseQuery += 'Approval_Status__c IN (\'Submitted for Approval\', \'Pending from Manager\', \'Pending from RM\') ';
        baseQuery += 'AND CALENDAR_YEAR(Journey_Date__c) = ' + Year + ' ';
        baseQuery += 'AND CALENDAR_MONTH(Journey_Date__c) = ' + Month + ' ';
        
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = \'' + CurrentUserId + '\' ';
        }
        
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = ' + Day + ' ';
        }
        
        baseQuery += 'ORDER BY Journey_Date__c DESC LIMIT '+pageSize+' OFFSET ' + offsetVal;
        
        System.debug('Final SOQL: ' + baseQuery);
        return Database.query(baseQuery);
    }
    
    @AuraEnabled
    public static Integer GetJourneyListMonthTeamCount(Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        // Define the approval statuses for reusability
        List<String> approvalStatuses = new List<String>{
            'Submitted for Approval', 'Pending from Manager', 'Pending from RM'
                };
                    // Construct the base query
                    String baseQuery = 'SELECT COUNT() FROM Journey__c WHERE CheckOut_Date__c != null';
        
        // Add approval status condition
        baseQuery += ' AND Approval_Status__c IN :approvalStatuses';
        
        // Add year and month filters
        baseQuery += ' AND CALENDAR_YEAR(Journey_Date__c) = :Year';
        baseQuery += ' AND CALENDAR_MONTH(Journey_Date__c) = :Month';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += ' AND DAY_IN_MONTH(Journey_Date__c) = :Day';
        }
        
        // Add user filter if provided
        if (CurrentUserId != null) {
            baseQuery += ' AND OwnerId = :CurrentUserId';
        }
        
        // Execute and return count using countQuery
        return Database.countQuery(baseQuery);
    }


    // method to get all the journey of a user where status is Approved by RM, Approved by manager
    @AuraEnabled
    public static List<Journey__c> GetJourneyListMonthTeamApproved(Integer pageNumber, Integer pageSize, Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        Integer offsetVal = (pageNumber - 1) * pageSize;
        List<String> approvalStatuses = new List<String>{'Approved By RM', 'Approved by Manager', 'Auto Approved'};
            
            // Start building the query
            String baseQuery = 'SELECT Id, Name, OwnerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c, ' +
            'Remarks__c, Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c, Journey_Audited__c, ' +
            'Remarks_To_be_filled_by_Auditors__c ' +
            'FROM Journey__c ' +
            'WHERE Journey_Audited__c = false ';
        
        // Approval statuses as string for IN clause
        String statusList = '(';
        for (Integer i = 0; i < approvalStatuses.size(); i++) {
            statusList += '\'' + approvalStatuses[i] + '\'';
            if (i < approvalStatuses.size() - 1) {
                statusList += ', ';
            }
        }
        statusList += ')';
        baseQuery += 'AND Approval_Status__c IN ' + statusList + ' ';
        
        baseQuery += 'AND CALENDAR_YEAR(Journey_Date__c) = ' + Year + ' ';
        baseQuery += 'AND CALENDAR_MONTH(Journey_Date__c) = ' + Month + ' ';
        
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = \'' + CurrentUserId + '\' ';
        }
        
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = ' + Day + ' ';
        }
        
        baseQuery += 'ORDER BY Journey_Date__c DESC LIMIT '+pageSize+' OFFSET ' + offsetVal;
        
        System.debug('Final Query: ' + baseQuery);
        return Database.query(baseQuery);
    }

    @AuraEnabled
    public static Integer GetJourneyListMonthTeamApprovedCount(Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        // Define the approval statuses for reusability
        List<String> approvalStatuses = new List<String>{
            'Approved By RM', 'Approved by Manager', 'Auto Approved'
                };
                    
                    // Construct the base query
                    String baseQuery = 'SELECT COUNT() FROM Journey__c WHERE Journey_Audited__c = false';
        
        // Add approval status condition
        baseQuery += ' AND Approval_Status__c IN :approvalStatuses';
        
        // Add year and month filters
        baseQuery += ' AND CALENDAR_YEAR(Journey_Date__c) = :Year';
        baseQuery += ' AND CALENDAR_MONTH(Journey_Date__c) = :Month';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += ' AND DAY_IN_MONTH(Journey_Date__c) = :Day';
        }
        
        // Add user filter if provided
        if (CurrentUserId != null) {
            baseQuery += ' AND OwnerId = :CurrentUserId';
        }
        
        // Execute and return count using countQuery
        return Database.countQuery(baseQuery);
    }

    // method to get all the journey of a user where status is Rejected by RM, Rejected by manager
    @AuraEnabled
    public static List<Journey__c> GetJourneyListMonthTeamRejected(Integer pageNumber,Integer pageSize, Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        Integer offsetVal = (pageNumber - 1) * pageSize;
        List<String> approvalStatuses = new List<String>{'Rejected by Manager', 'Rejected By RM'};
            
            // Build initial query
            String baseQuery = 'SELECT Id, Name, OwnerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c, ' +
            'Remarks__c, Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c, Journey_Audited__c, ' +
            'Remarks_To_be_filled_by_Auditors__c ' +
            'FROM Journey__c ' +
            'WHERE Journey_Audited__c = false ';
        
        // Approval statuses
        String statusList = '(';
        for (Integer i = 0; i < approvalStatuses.size(); i++) {
            statusList += '\'' + approvalStatuses[i] + '\'';
            if (i < approvalStatuses.size() - 1) {
                statusList += ', ';
            }
        }
        statusList += ')';
        baseQuery += 'AND Approval_Status__c IN ' + statusList + ' ';
        
        baseQuery += 'AND CALENDAR_YEAR(Journey_Date__c) = ' + Year + ' ';
        baseQuery += 'AND CALENDAR_MONTH(Journey_Date__c) = ' + Month + ' ';
        
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = \'' + CurrentUserId + '\' ';
        }
        
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = ' + Day + ' ';
        }
        
        baseQuery += 'ORDER BY Journey_Date__c DESC LIMIT '+pageSize+' OFFSET ' + offsetVal;
        return Database.query(baseQuery);
    }

    @AuraEnabled
    public static Integer GetJourneyListMonthTeamRejectedCount(Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        // Define the approval statuses for reusability
        List<String> approvalStatuses = new List<String>{
            'Rejected by Manager', 'Rejected By RM'
                };
                    
                    // Construct the base query
                    String baseQuery = 'SELECT COUNT() FROM Journey__c WHERE Journey_Audited__c = false';
        
        // Add approval status condition
        baseQuery += ' AND Approval_Status__c IN :approvalStatuses';
        
        // Add year and month filters
        baseQuery += ' AND CALENDAR_YEAR(Journey_Date__c) = :Year';
        baseQuery += ' AND CALENDAR_MONTH(Journey_Date__c) = :Month';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += ' AND DAY_IN_MONTH(Journey_Date__c) = :Day';
        }
        
        // Add user filter if provided
        if (CurrentUserId != null) {
            baseQuery += ' AND OwnerId = :CurrentUserId';
        }
        
        // Execute and return count using countQuery
        return Database.countQuery(baseQuery);
    }
 
    // Start SAC-1201 || Deepika Thakur || IBM    
    // method to get all the journey of a user where Journey is checked-out and eligible to be submitted for approval
    @AuraEnabled
    public static List<Journey__c> GetJourneyListMonthTeamToBeSubmitted(Integer pageNumber,Integer pageSize, Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        Integer offsetVal = (pageNumber - 1) * pageSize;
        
        List<String> approvalStatuses = new List<String>{'Not Submitted for Approval'};
            
            // Start building the query
            String baseQuery = 'SELECT Id, Name, OwnerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c, ' +
            'Remarks__c, Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c, Journey_Audited__c, ' +
            'Remarks_To_be_filled_by_Auditors__c, CheckOut_Date__c ' +
            'FROM Journey__c ' +
            'WHERE CheckOut_Date__c != null ' +
            'AND Journey_Audited__c = false ';
        
        // Build approval status IN clause
        String statusList = '(';
        for (Integer i = 0; i < approvalStatuses.size(); i++) {
            statusList += '\'' + approvalStatuses[i] + '\'';
            if (i < approvalStatuses.size() - 1) {
                statusList += ', ';
            }
        }
        statusList += ')';
        baseQuery += 'AND Approval_Status__c IN ' + statusList + ' ';
        
        // Add date filters
        baseQuery += 'AND CALENDAR_YEAR(Journey_Date__c) = ' + Year + ' ';
        baseQuery += 'AND CALENDAR_MONTH(Journey_Date__c) = ' + Month + ' ';
        
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = \'' + CurrentUserId + '\' ';
        }
        
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = ' + Day + ' ';
        }
        
        baseQuery += 'ORDER BY Journey_Date__c DESC LIMIT '+pageSize+' OFFSET ' + offsetVal;
        
        return Database.query(baseQuery);
    }

    @AuraEnabled
    public static Integer GetJourneyListMonthTeamToBeSubmittedCount(Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        // Define the approval statuses for reusability
        List<String> approvalStatuses = new List<String>{
            'Not Submitted for Approval'
                };
                    
                    // Construct the base query
                    String baseQuery = 'SELECT COUNT() FROM Journey__c WHERE Journey_Audited__c = false AND CheckOut_Date__c != null';
        
        // Add approval status condition
        baseQuery += ' AND Approval_Status__c IN :approvalStatuses';
        
        // Add year and month filters
        baseQuery += ' AND CALENDAR_YEAR(Journey_Date__c) = :Year';
        baseQuery += ' AND CALENDAR_MONTH(Journey_Date__c) = :Month';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += ' AND DAY_IN_MONTH(Journey_Date__c) = :Day';
        }
        
        // Add user filter if provided
        if (CurrentUserId != null) {
            baseQuery += ' AND OwnerId = :CurrentUserId';
        }
        
        // Execute and return count using countQuery
        return Database.countQuery(baseQuery);
    }
    
    // method to get all the journey of a user where Journey is marked as 'Not to Be Claimed'
    @AuraEnabled
    public static List<Journey__c> GetJourneyListMonthTeamNotToBeClaimed(Integer pageNumber, Integer pageSize, Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        Integer offsetVal = (pageNumber - 1) * pageSize;
        
        String baseQuery = 'SELECT Id, Name, OwnerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c, ' +
            'Remarks__c, Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c, Journey_Audited__c, ' +
            'Remarks_To_be_filled_by_Auditors__c FROM Journey__c WHERE Journey_Audited__c = false ';
        
        baseQuery += 'AND Approval_Status__c = \'Not to Be Claimed\' ';
        baseQuery += 'AND CALENDAR_YEAR(Journey_Date__c) = ' + Year + ' ';
        baseQuery += 'AND CALENDAR_MONTH(Journey_Date__c) = ' + Month + ' ';
        
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = ' + Day + ' ';
        }
        
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = \'' + CurrentUserId + '\' ';
        }
        
        baseQuery += 'ORDER BY Journey_Date__c DESC LIMIT ' + pageSize + ' OFFSET ' + offsetVal;
        
        System.debug('Final SOQL (NotToBeClaimed): ' + baseQuery);
        return Database.query(baseQuery);
    }

    
    @AuraEnabled
    public static Integer GetJourneyListMonthTeamNotToBeClaimedCount(Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        // Define the approval statuses for reusability
        List<String> approvalStatuses = new List<String>{
            'Submitted for Approval', 'Pending from Manager', 'Pending from RM'
                };
                    
                    // Construct the base query
                    String baseQuery = 'SELECT COUNT() FROM Journey__c WHERE ';
        
        // Add approval status condition
        baseQuery += 'Approval_Status__c IN :approvalStatuses';
        
        // Add year and month filters
        baseQuery += ' AND CALENDAR_YEAR(Journey_Date__c) = :Year';
        baseQuery += ' AND CALENDAR_MONTH(Journey_Date__c) = :Month';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += ' AND DAY_IN_MONTH(Journey_Date__c) = :Day';
        }
        
        // Add user filter if provided
        if (CurrentUserId != null) {
            baseQuery += ' AND OwnerId = :CurrentUserId';
        }
        
        // Execute and return count using countQuery
        return Database.countQuery(baseQuery);
    }
    // End SAC-1201 || Deepika Thakur || IBM    
    
    // Method to get total number of journeys on a selected month
    @AuraEnabled
    public static Integer GetJourneyCountTeam(Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        // Define the approval statuses for reusability
        List<String> approvalStatuses = new List<String>{
            'Rejected by Manager', 'Rejected By RM', 'Approved By RM', 'Approved by Manager',
                'Submitted for Approval', 'Not to Be Claimed', 'Not Submitted for Approval', 
                'Auto Approved', 'Pending from Manager', 'Pending from RM'
                };
                    
                    // Construct the base query
                    String baseQuery = 'SELECT COUNT(Id) ' +
                    'FROM Journey__c ' +
                    'WHERE Journey_Audited__c = false ' +
                    'AND CheckOut_Date__c != null ' +
                    'AND Approval_Status__c IN :approvalStatuses ' +
                    'AND CALENDAR_YEAR(Journey_Date__c) = :Year ' +
                    'AND CALENDAR_MONTH(Journey_Date__c) = :Month ';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = :Day ';
        }
        
        // Add condition for CurrentUserId if provided
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = :CurrentUserId ';
        }
        
        // Execute the query and get the result
        AggregateResult[] JourneyAggregate = Database.query(baseQuery);
        
        // Extract the count from the result
        Integer JourneyCount = (Integer)JourneyAggregate[0].get('expr0');
        
        return JourneyCount;
    }

    // Method to get total amount of journeys in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalAmountTeam(Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        // Define the approval statuses for reusability
        List<String> approvalStatuses = new List<String>{
            'Rejected by Manager', 'Rejected By RM', 'Approved By RM', 'Approved by Manager',
                'Submitted for Approval', 'Not to Be Claimed', 'Not Submitted for Approval', 
                'Auto Approved', 'Pending from Manager', 'Pending from RM'
                };
                    
                    // Construct the base query
                    String baseQuery = 'SELECT SUM(Final_Amount__c) ' +
                    'FROM Journey__c ' +
                    'WHERE Journey_Audited__c = false ' +
                    'AND CheckOut_Date__c != null ' +
                    'AND Approval_Status__c IN :approvalStatuses ' +
                    'AND CALENDAR_YEAR(Journey_Date__c) = :Year ' +
                    'AND CALENDAR_MONTH(Journey_Date__c) = :Month ';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = :Day ';
        }
        
        // Add condition for CurrentUserId if provided
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = :CurrentUserId ';
        }
        
        // Execute the query and get the result
        AggregateResult[] JourneyAggregateAmount = Database.query(baseQuery);
        
        // Extract the total amount from the result
        Decimal JourneyTotalAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
        
        return JourneyTotalAmount != null ? JourneyTotalAmount : 0;  // Return 0 if the result is null
    }
    
    // Method to get total approved amount in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalApprovedAmountTeam( Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        List<String> approvalStatuses = new List<String>{
            'Rejected by Manager', 'Rejected By RM', 'Approved By RM', 'Approved by Manager',
                'Submitted for Approval', 'Not to Be Claimed', 'Not Submitted for Approval', 
                'Auto Approved', 'Pending from Manager', 'Pending from RM'
                };
                    
                    // Base query string
                    String baseQuery = 'SELECT SUM(Approved_Final_Amount__c) ' +
                    'FROM Journey__c ' +
                    'WHERE Journey_Audited__c = false ' +
                    'AND CheckOut_Date__c != null ' +
                    'AND Approval_Status__c IN :approvalStatuses ' +
                    'AND CALENDAR_YEAR(Journey_Date__c) = :Year ' +
                    'AND CALENDAR_MONTH(Journey_Date__c) = :Month ';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = :Day ';
        }
        
        // Add condition for CurrentUserId if provided
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = :CurrentUserId ';
        }
        
        // Execute the query
        AggregateResult[] JourneyAggregateAmount = Database.query(baseQuery);
        
        // Extract the total amount and return it
        Decimal JourneyTotalApprovedAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
        return JourneyTotalApprovedAmount != null ? JourneyTotalApprovedAmount : 0;
    }
    
    // Method to get total event count in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalEventTeam( Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        List<String> approvalStatuses = new List<String>{
            'Rejected by Manager', 'Rejected By RM', 'Approved By RM', 'Approved by Manager',
                'Submitted for Approval', 'Not to Be Claimed', 'Not Submitted for Approval', 
                'Auto Approved', 'Pending from Manager', 'Pending from RM'
                };
                    
                    // Base query string
                    String baseQuery = 'SELECT SUM(Number_Of_Event__c) ' +
                    'FROM Journey__c ' +
                    'WHERE Journey_Audited__c = false ' +
                    'AND CheckOut_Date__c != null ' +
                    'AND Approval_Status__c IN :approvalStatuses ' +
                    'AND CALENDAR_YEAR(Journey_Date__c) = :Year ' +
                    'AND CALENDAR_MONTH(Journey_Date__c) = :Month ';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = :Day ';
        }
        
        // Add condition for CurrentUserId if provided
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = :CurrentUserId ';
        }
        
        // Execute the query
        AggregateResult[] JourneyAggregateEventCount = Database.query(baseQuery);
        
        // Extract the total event count and return it
        Decimal JourneyTotalEvent = (Decimal)JourneyAggregateEventCount[0].get('expr0');
        return JourneyTotalEvent != null ? JourneyTotalEvent : 0;
    }
    
    // Method to get total distance in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalDistanceTeam( Integer Year, Integer Month, Integer Day, Id CurrentUserId) {
        List<String> approvalStatuses = new List<String>{
            'Rejected by Manager', 'Rejected By RM', 'Approved By RM', 'Approved by Manager',
                'Submitted for Approval', 'Not to Be Claimed', 'Not Submitted for Approval', 
                'Auto Approved', 'Pending from Manager', 'Pending from RM'
                };
                    
                    // Base query string
                    String baseQuery = 'SELECT SUM(Journey_KM__c) ' +
                    'FROM Journey__c ' +
                    'WHERE Journey_Audited__c = false ' +
                    'AND CheckOut_Date__c != null ' +
                    'AND Approval_Status__c IN :approvalStatuses ' +
                    'AND CALENDAR_YEAR(Journey_Date__c) = :Year ' +
                    'AND CALENDAR_MONTH(Journey_Date__c) = :Month ';
        
        // Add Day condition if provided
        if (Day != null) {
            baseQuery += 'AND DAY_IN_MONTH(Journey_Date__c) = :Day ';
        }
        
        // Add condition for CurrentUserId if provided
        if (CurrentUserId != null) {
            baseQuery += 'AND OwnerId = :CurrentUserId ';
        }
        
        // Execute the query
        AggregateResult[] JourneyAggregateDistance = Database.query(baseQuery);
        
        // Extract the total distance and return it
        Decimal JourneyTotalDistance = (Decimal)JourneyAggregateDistance[0].get('expr0');
        return JourneyTotalDistance != null ? JourneyTotalDistance : 0;
    }    
    
     // method to get all the journey with status pending for Approval
    @AuraEnabled
    public static List<Journey__c> GetJourneyListMonthTeamNew(Integer pageNumber, Integer pageSize, Integer year, Integer month, Id currentUserId) {
        Integer offsetSize = (pageNumber - 1) * pageSize;
        
        String baseQuery = 'SELECT Id, Name, OwnerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c, Remarks__c, ' +
            'Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c, Journey_Audited__c, Remarks_To_be_filled_by_Auditors__c ' +
            'FROM Journey__c WHERE Journey_Audited__c = false ' +
            'AND Approval_Status__c IN (\'Submitted for Approval\', \'Pending from Manager\', \'Pending from RM\') ' +
            'AND CALENDAR_YEAR(Journey_Date__c) = :year AND CALENDAR_MONTH(Journey_Date__c) = :month ';
        
        if (currentUserId != null) {
            baseQuery += 'AND OwnerId = :currentUserId ';
        }
        
        baseQuery += 'ORDER BY Journey_Date__c DESC LIMIT :pageSize OFFSET :offsetSize';
        return Database.query(baseQuery);
    }
    
    @AuraEnabled(cacheable=true)
    public static Integer getToBeSubmittedCount(String userId, Integer year, Integer month) {
        return [
            SELECT COUNT()
            FROM Journey__c
            WHERE OwnerId = :userId
            AND Journey_Audited__c = false
            AND Approval_Status__c IN ('Submitted for Approval','Pending from Manager','Pending from RM')
            AND CALENDAR_YEAR(Journey_Date__c) = :year
            AND CALENDAR_MONTH(Journey_Date__c) = :month
        ];
    }
    
    @AuraEnabled
    public static boolean setStatusNotToBeClaimed(Id record) {
        try {
            Journey__c jor = [SELECT Id, Approval_Status__c FROM Journey__c WHERE Id = :record LIMIT 1];
            jor.Approval_Status__c = 'Not to Be Claimed';
            update jor;
            return true;
        } catch (QueryException qe) {
            // Record not found or other SOQL issues
            throw new AuraHandledException('Journey record not found with the provided Id.');
        } catch (DmlException dmlEx) {
            // Handle update errors
            throw new AuraHandledException('Error updating Journey record: ' + dmlEx.getMessage());
        } catch (Exception ex) {
            // Catch-all for any other exceptions
            throw new AuraHandledException('Unexpected error: ' + ex.getMessage());
        }
    }
    
    // Method to get approval process
    @AuraEnabled
    public static String approveJourney(Id Receiver, Id record) {
        String Result;
        
        // Get the pending process instance for the record
        ProcessInstance[] proList = [
            SELECT Id, Status, TargetObjectId 
            FROM ProcessInstance 
            WHERE Status = 'Pending' AND TargetObjectId = :record
        ];
        
        if (!proList.isEmpty()) {
            // Find the work item assigned to the current user (Receiver)
            ProcessInstanceWorkitem[] workItems = [
                SELECT Id, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstanceId = :proList[0].Id 
                AND ActorId = :Receiver
            ];
            
            if (!workItems.isEmpty()) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments('Approved through Journey view');
                req.setAction('Approve');
                req.setWorkitemId(workItems[0].Id);
                
                Approval.ProcessResult approv = Approval.process(req);
                Result = 'Approved';
            } else {
                Result = 'You do not have any pending approval work item for this Journey.';
            }
        } else {
            Result = 'No pending approval process found for this Journey.';
        }
        
        return Result;
    }

    /*@AuraEnabled
    public static String approveJourney(Id Submitter, Id Receiver , Id record ){
        String Result;
        //  Set<ID> ProId = new Set<ID>();
        ProcessInstance[] Pro =  [SELECT CompletedDate, ElapsedTimeInDays,LastActorId, ElapsedTimeInHours, ElapsedTimeInMinutes, Id, ProcessDefinitionId, Status, SubmittedById, TargetObjectId FROM ProcessInstance
                                  where Status = 'Pending' AND SubmittedById =: Submitter AND TargetObjectId =: record ];
        
        if(Pro.size() > 0){
            ProcessInstanceWorkitem[]  ProWI = [SELECT CreatedById,CreatedDate,ElapsedTimeInDays,ElapsedTimeInHours,ElapsedTimeInMinutes,Id,IsDeleted,OriginalActorId,ProcessInstanceId,ActorId,SystemModstamp FROM ProcessInstanceWorkitem  where ProcessInstanceId =: Pro[0].Id AND ActorId=:Receiver];
            if( proWI.size() > 0){
                // 
                
                System.debug(proWI);
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments('Approving Through Journey view');
                req.setAction('Approve');
                req.setWorkitemId(ProWI[0].Id);
                Approval.ProcessResult appro = Approval.process(req);
                Result = 'Approved';            
            }else{
                Result = 'You dont have any approval process related to this journey.';
            }
        }else{
            Result = 'You dont have any approval process related to this journey.';
        }
        Return Result;
    }
    // Method to check If user is authorised to reject the journey
    /* @AuraEnabled
public static String RejectionCheck(Id Submitter, Id Receiver , Id record ){
String Result;
//  Set<ID> ProId = new Set<ID>();
ProcessInstance Pro =  [SELECT CompletedDate, ElapsedTimeInDays,LastActorId, ElapsedTimeInHours, ElapsedTimeInMinutes, Id, ProcessDefinitionId, Status, SubmittedById, TargetObjectId FROM ProcessInstance
where Status = 'Pending' AND SubmittedById =: Submitter AND TargetObjectId =: record ];

if(Pro != Null){
ProcessInstanceWorkitem  ProWI = [SELECT CreatedById,CreatedDate,ElapsedTimeInDays,ElapsedTimeInHours,ElapsedTimeInMinutes,Id,IsDeleted,OriginalActorId,ProcessInstanceId,ActorId,SystemModstamp FROM ProcessInstanceWorkitem  where ProcessInstanceId =: Pro.Id AND ActorId=:Receiver];
if( proWI != Null){
Result = 'Authorised.';         
}else{
Result = 'You dont have any approval process related to this journey.';
}
}else{
Result = 'You dont have any approval process related to this journey.';
}
Return Result;
}
*/
    // Method to reject the journey
    @AuraEnabled
    public static String rejectJourney(Id Receiver, Id record, String Comment) {
        String result;
        
        // Get the pending process instance for the record
        List<ProcessInstance> proList = [
            SELECT Id 
            FROM ProcessInstance 
            WHERE Status = 'Pending' 
            AND TargetObjectId = :record
        ];
        
        if (!proList.isEmpty()) {
            // Get workitem assigned to this user
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstanceId = :proList[0].Id 
                AND ActorId = :Receiver
            ];
            
            if (!workItems.isEmpty()) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments(Comment);
                req.setAction('Reject');
                req.setWorkitemId(workItems[0].Id);
                
                Approval.ProcessResult resultObj = Approval.process(req);
                result = 'Rejected';
            } else {
                result = 'You do not have any approval work item for this journey.';
            }
        } else {
            result = 'No pending approval found for this journey.';
        }
        
        return result;
    }

   /* @AuraEnabled
    public static String rejectJourney(Id Submitter, Id Receiver , Id record, String Comment ){
        String Result;
        //  Set<ID> ProId = new Set<ID>();
        ProcessInstance[] Pro =  [SELECT CompletedDate, ElapsedTimeInDays,LastActorId, ElapsedTimeInHours, ElapsedTimeInMinutes, Id, ProcessDefinitionId, Status, SubmittedById, TargetObjectId FROM ProcessInstance
                                  where Status = 'Pending' AND SubmittedById =: Submitter AND TargetObjectId =: record ];
        if(Pro.size() > 0){
            ProcessInstanceWorkitem[]  ProWI = [SELECT CreatedById,CreatedDate,ElapsedTimeInDays,ElapsedTimeInHours,ElapsedTimeInMinutes,Id,IsDeleted,OriginalActorId,ProcessInstanceId,ActorId,SystemModstamp FROM ProcessInstanceWorkitem  where ProcessInstanceId =: Pro[0].Id AND ActorId=:Receiver];
            if( proWI.size() > 0){
                // System.debug(proWI);
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments(Comment);
                req.setAction('Reject');
                req.setWorkitemId(ProWI[0].Id);
                Approval.ProcessResult appro = Approval.process(req);
                Result = 'Rejected';            
            }else{
                Result = 'You dont have any approval process related to this journey.';
            }
        }else{
            Result = 'You dont have any approval process related to this journey.';
        }
        Return Result;
    }
    
    @AuraEnabled
    public static User GetUserData( Id userId){
        User Usr = [Select Id, name, FullPhotoUrl,SmallPhotoUrl from user where id =: userId];
        Return Usr;   
    }
    */
    
    // Method to Update Audit Journey details on click of update button || Deepika Thakur || IBM
    @AuraEnabled
    public static JourneyResponse updateJourney(Id journeyId, Boolean journeyAudited, String auditorRemarks) {
        try {
            Journey__c journey = [SELECT Id, Journey_Audited__c, Remarks_To_be_filled_by_Auditors__c 
                                  FROM Journey__c WHERE Id = :journeyId LIMIT 1];
            
            journey.Journey_Audited__c = journeyAudited;
            journey.Remarks_To_be_filled_by_Auditors__c = auditorRemarks;
            
            update journey;
            return new JourneyResponse('success', 'Journey updated successfully!');
        } catch (Exception e) {
            String rawMessage = e.getMessage();
            String userFriendlyMessage = 'Error updating Journey.';
            if (rawMessage != null && rawMessage.contains('ENTITY_IS_LOCKED')) {
                userFriendlyMessage = 'This Journey is locked and cannot be edited.';
            }
            return new JourneyResponse('error', userFriendlyMessage);
        }       
    }
    
    @AuraEnabled
    public static Map<String, String>  publishEventDetails(String objectName, String objectId, String fieldName, String fieldValue, Boolean audited) {
        Map<String, String> result = new Map<String, String>();
        try {
            Update_Event__e eventData = new Update_Event__e(
                ObjectId__c = objectId,
                ObjectName__c = objectName,
                FieldName__c = fieldName,
                Field_Value__c = fieldValue,
                Audited__c = audited
            );
            System.debug(eventData);
            Database.SaveResult publishResult = EventBus.publish(eventData);
            if (publishResult.isSuccess()) {
                result.put('status', 'success');
                result.put('message', 'Details updated successfully!');
            } else {
                result.put('status', 'error');
                result.put('message', publishResult.getErrors()[0].getMessage());
            }
        } catch (Exception ex) {
            result.put('status', 'error');
            result.put('message', 'Exception: ' + ex.getMessage());
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfileName() {
       // System.debug('PROFILE: '+[SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name);
        return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
    }
    
     @AuraEnabled(cacheable=true)
    public static Boolean getCurrentUserCustomPermissions() {
        Boolean hasCustomPermission = FeatureManagement.checkPermission('Business_admin_permission');
        System.debug('hasCustomPermission '+hasCustomPermission);
        return hasCustomPermission;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Journey__c> getPaginatedRecords(Integer tabNumber, Integer pageNumber, Integer pageSize) {
        Integer offsetVal = (pageNumber - 1) * pageSize;
        
        // Adjust the query for each tab based on `tabNumber`
        List<Journey__c> records = new List<Journey__c>();
        
        // Add your logic for different tabs' queries
        if (tabNumber == 1) {
        } else if (tabNumber == 2) {
        }
        // Add more conditions for tabs 3, 4, and 5 as needed
        
        return records;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getTotalRecordsForTab(Integer tabNumber) {
        Integer totalRecords = 0;
        
        // Add your logic for each tab's total record count
        if (tabNumber == 1) {
        } else if (tabNumber == 2) {
        }
        // Add more conditions for tabs 3, 4, and 5
        
        return totalRecords;
    }
    
    public class JourneyResponse {
    @AuraEnabled public String status;
    @AuraEnabled public String message;

    public JourneyResponse(String status, String message) {
        this.status = status;
        this.message = message;
    }
}

    // wrapper for map
    public class Address {
        @AuraEnabled
        public location location;
        @AuraEnabled
        public string icon;
        @AuraEnabled
        public String title;
        @AuraEnabled
        Public String description;
        
        public address(location loc){
            location = loc;
            title = 'Geo Location';
            icon = 'standard:contact';
        }
    }
    
    
    public class location{
        @AuraEnabled
        public string Latitude;
        @AuraEnabled
        public string Longitude;
        
        public location (String lat, String longi){
            Latitude = lat;
            Longitude = longi;
        }
    }
}