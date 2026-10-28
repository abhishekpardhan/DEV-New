/**
    @Description          : This class will used as controller of finance journey view controller
    * @Author             : Shubham 
    * @Group              : Safexpress
    * @Last Modified By   : Shubham
    * @Last Modified On   : 17-Feb-21
    * @Modification Log   :
    *==============================================================================
    * Ver         Date                     Author                    Modification
    *==============================================================================
    * 1.0        17-Feb-21                Shubham                   Initial Version
    * 2.0        13-Jan-22                Shubham                   Added New Features(User heighligt, live API call)
**/
public class Finance_Journey_View_Controller{
    @AuraEnabled
    public static list<string> GetRegionList(){
        list<string> ExpenseType = new list<String>();
        schema.DescribeFieldResult fieldValue =   User.Region__c.getDescribe();
        list<schema.PicklistEntry> picklist = fieldValue.getPicklistValues();
        for(schema.PicklistEntry p : picklist){
            ExpenseType.add(p.getValue());
        }
        return ExpenseType;    
    }
    
    @AuraEnabled
    public static list<User> GetUserList(String Region){
        list<User> UserList = new list<User>();
        UserList = [select id,name, Region__c from user where IsActive = true AND Region__c =: Region ORDER BY name ASC];
        return UserList;
    }
    @AuraEnabled
    public static Id GetUserId(string userName){
        User UserList = [select id,name, Region__c from user where name =:userName];
        return UserList.id;
    }
    
    @AuraEnabled
    public static list<User> GetUserListId(){
        list<User> UserList = new list<User>();
        UserList = [select id,name,AD_Id__c, Region__c from user where IsActive = true AND AD_Id__c != null ORDER BY AD_Id__c ASC];
        return UserList;
    }
    @AuraEnabled
    public static list<Journey__c> GetJourneyList(Integer Year, Integer Month , Id CurrentUserId ){
        list<Journey__c> JourneyList = new List<Journey__c>();
        JourneyList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Finance_Remark__c,
                       Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c,Approved_Final_Amount__c,
                       Approved_Amount__c,
                       Remarks__c, Journey_Amount__c from Journey__c where ownerId =: CurrentUserId AND  Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = false
                       AND Outstation__c = false AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ORDER BY Journey_Date__c DESC];
        
        return JourneyList;
    }
    @AuraEnabled
    public static list<Journey__c> GetJourneyListTravel(Integer Year, Integer Month , Id CurrentUserId ){
        list<Journey__c> JourneyList = new List<Journey__c>();
        JourneyList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Finance_Remark__c,
                       Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c,Approved_Final_Amount__c,
                       Approved_Amount__c,
                       Remarks__c, Journey_Amount__c from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = true
                       AND Outstation__c = true AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ORDER BY Journey_Date__c DESC];
        return JourneyList;
    }
    @AuraEnabled
    public static User GetUserProfile(Id userId ){
        User us = new User();
        us = [select id, name, MobilePhone, Email,Designation__c, Department, AD_id__c, Region__c,Area__c, journey_Type__c,Supplier_Num__c, Supplier_Site_Code__c, Supplier__c from user WHERE Id =: userId ]; //IsActive = true AND
        return us;
    } 
    @AuraEnabled
    public static list<Event__c> GetEventList(list<String> JourneyId){
        list<Event__c> EventList = new List<Event__c>();
        EventList = [select id, name,Journey__c,Status__c,Event_Purpose__c, /*Virtual_Meeting__c,*/  Remarks__c,
                     Distance__c,Campaign__c,Campaign__r.Name,Contact__r.Name,Time_Spent_Auto__c,Contact__c from Event__c where Journey__c IN :JourneyId];   
        system.debug('@@@@@@@@@@@@'+ EventList);
        return EventList;
    }
    //Method to get Approval history of the journey
    @AuraEnabled
    public static list<ProcessInstance> getApprovalHistory(Id JourneyId){
        list<ProcessInstance> History = new list<ProcessInstance>();
        History = [SELECT CompletedDate,CreatedById,CreatedDate,Id,LastActorId,LastModifiedById,ProcessDefinitionId,Status,SubmittedById,TargetObjectId FROM ProcessInstance where TargetObjectId =: JourneyId ];
        return History;
    }    
    @AuraEnabled
    public static list<Expense_Item__c> GetExList(list<String> JourneyId){
        list<Expense_Item__c> ExList = new List<Expense_Item__c>();
        ExList = [select id, Journey__c, name, Amount__c, Bill_Number__c,Comment__c, Expense_Type__c,Approved_Amount__c,GST_No__c, Check_In_Date__c, Check_Out_Date__c from Expense_Item__c where Journey__c IN :JourneyId];   
        system.debug('@@@@@@@@@@@@'+ ExList);
        return ExList;
    }
    // Method to get total number of journeys on a selected month
    @AuraEnabled
    public static Integer GetJourneyCountTeam(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregate = [select COUNT(id) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = false // AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                              AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Integer JourneyCount = (Integer)JourneyAggregate[0].get('expr0');
        return JourneyCount;
    }
    // Method to get total amount of journeys in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalAmountTeam(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregateAmount = [select SUM(Final_Amount__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = false// AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                                    AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
        return JourneyTotalAmount;
    }
    // Method to get total Approved Amount of journeys in selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalApprovedAmountTeam(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregateAmount = [select SUM(Approved_Final_Amount__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = false// AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                                    AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
        return JourneyTotalAmount;
    }
    // Method to get total number of events in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalEventTeam(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregateEventCount = [select SUM(Number_Of_Event__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = false// AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                                        AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalEvent = (Decimal)JourneyAggregateEventCount[0].get('expr0');
        return JourneyTotalEvent;
    }
    // Method to get total number of distance in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalDistanceTeam(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregateDistance = [select SUM(Journey_KM__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = false// AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                                      AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalDistance = (Decimal)JourneyAggregateDistance[0].get('expr0');
        return JourneyTotalDistance;
    }
    // Method to get total number of journeys on a selected month
    @AuraEnabled
    public static Integer GetJourneyCountTra(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregate = [select COUNT(id) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = true // AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                              AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Integer JourneyCount = (Integer)JourneyAggregate[0].get('expr0');
        return JourneyCount;
    }
    // Method to get total amount of journeys in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalAmountTra(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregateAmount = [select SUM(Final_Amount__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = true// AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                                    AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
        return JourneyTotalAmount;
    } 
    // Method to get total Approved amount of journeys in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalApprovedAmountTra(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregateAmount = [select SUM(Approved_Final_Amount__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = true// AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                                    AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
        return JourneyTotalAmount;
    }
    // Method to get total number of events in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalEventTra(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregateEventCount = [select SUM(Number_Of_Event__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = true// AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                                        AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalEvent = (Decimal)JourneyAggregateEventCount[0].get('expr0');
        return JourneyTotalEvent;
    }
    // Method to get total number of distance in a selected month
    @AuraEnabled
    public static Decimal GetJourneyTotalDistanceTra(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] JourneyAggregateDistance = [select SUM(Journey_KM__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = true// AND Approval_Status__c IN ('Rejected by Manager','Rejected By RM','Approved By RM','Approved by Manager')
                                                      AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        Decimal JourneyTotalDistance = (Decimal)JourneyAggregateDistance[0].get('expr0');
        return JourneyTotalDistance;
    }
    @AuraEnabled
    public static string ApproveAmmount(Decimal Amount, String Remark, id JourneyId){
        String result = '';
        journey__c jor = [select id, name, Remarks__c,Finance_Remark__c
                          ,Approved_Amount__c,Approved_Journey_Amount__c
                          from Journey__c where id =: JourneyId];
        jor.Approved_Journey_Amount__c = Amount;
        jor.Finance_Remark__c = Remark;
        update jor;
        result = 'Updated Successfully';
        return result;
    } 
    @AuraEnabled
    public static string ApproveExpenceAmmount(Integer Amount, id ExpenceId){
        String result = '';
        Expense_Item__c Exp = [SELECT Amount__c,Approved_Amount__c,Bill_Number__c,Check_In_Date__c,Check_Out_Date__c,Comment__c,CreatedById,CreatedDate,
                               Expense_Type__c,GST_No__c,Id,If_Others_Please_specify__c,Journey__c,Name
                               from Expense_Item__c where id =: ExpenceId];
        Exp.Approved_Amount__c = Amount;
        update Exp;
        result = 'Updated Successfully';
        return result;
    } 
    
    @AuraEnabled
    public static Journey__c JourneyDetail(Id jorId){
        Journey__c jor = [select id, name, journey_KM__c, Manual_Expense_Amount__c,Remarks__c,Approved_Expense_Amount__c,Approved_Journey_Amount__c,Approved_Final_Amount__c,Approved_Amount__c,Finance_Remark__c,journey_Amount__c,mode_of_transport__c, Final_Amount__c from Journey__c where id =: jorId ];
        return jor;
    }
    
    @AuraEnabled
    public static Expense_Item__c ExpenceDetail(Id ExpId){
        return [SELECT Amount__c,Approved_Amount__c,Bill_Number__c,Check_In_Date__c,Check_Out_Date__c,Comment__c,CreatedById,CreatedDate,Expense_Type__c,GST_No__c,Id,If_Others_Please_specify__c,Journey__c,Name FROM Expense_Item__c where id =:ExpId LIMIT 1 ];
        //return Exp;
    }
    
    
    // Method to search User
    @AuraEnabled
    public static Id SearchUser(String ID ){
        User serUser = [Select id, name, AD_Id__c from User where AD_Id__c =: ID ]; //AND IsActive = true
        return serUser.Id;
    }
    // Method to get total amount of expense item type Ticket Air
    @AuraEnabled
    public static Decimal GetExpenseTicketAir(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] result = [select SUM(Approved_Amount__c) from Expense_Item__c Where Expense_Type__c ='Ticket - Air' AND Journey__r.ownerId =: CurrentUserId
                                    AND Journey__r.Approval_Status__c IN ('Approved By RM','Auto Approved') AND Journey__r.Outstation__c = true AND 
                                    CALENDAR_YEAR(Journey__r.Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey__r.Journey_Date__c) =: Month];
        // system.debug('######'+ result);
        Decimal resultAmount = (Decimal)result[0].get('expr0');
        // system.debug('@@@@@'+ resultAmount);
        //    return resultAmount;
        if(resultAmount == null){
            resultAmount = 0;
            return resultAmount;
        }else{
            return resultAmount;
        }
    }
    // Method to get total amount of expense item type Ticket Train and other
    @AuraEnabled
    public static Decimal GetExpenseTicketTrain(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] result = [select SUM(Approved_Amount__c) from Expense_Item__c Where Expense_Type__c ='Ticket - Train/Other' AND Journey__r.ownerId =: CurrentUserId
                                    AND Journey__r.Approval_Status__c IN ('Approved By RM','Auto Approved') AND Journey__r.Outstation__c = true AND 
                                    CALENDAR_YEAR(Journey__r.Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey__r.Journey_Date__c) =: Month];
        // system.debug('######'+ result);
        Decimal resultAmount = (Decimal)result[0].get('expr0');
        // system.debug('@@@@@'+ resultAmount);
        //   return resultAmount;
        if(resultAmount == null){
            resultAmount = 0;
            return resultAmount;
        }else{
            return resultAmount;
        }
    }
    // Method to get total amount of expense item type Ticket Taxi & Car
    @AuraEnabled
    public static Decimal GetExpenseTaxi(Integer Year, Integer Month , Id CurrentUserId ){
        decimal joureyAmount = 0;
        system.debug('Year--------->'+ year);
        system.debug('Month--------->'+ Month);
        system.debug('UserId--------->'+ CurrentUserId);
        AggregateResult[] result = [select SUM(Approved_Amount__c) from Expense_Item__c Where Expense_Type__c ='Taxi & Car Expense' AND Journey__r.ownerId =: CurrentUserId
                                    AND Journey__r.Approval_Status__c IN ('Approved By RM','Auto Approved') AND Journey__r.Outstation__c = true AND 
                                    CALENDAR_YEAR(Journey__r.Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey__r.Journey_Date__c) =: Month];
        list<Journey__c> jorlist = [select Approved_Journey_Amount__c from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = true
                                    AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        if(jorlist.size() != 0){    
            AggregateResult[] JourneyAggregateAmount = [select SUM(Approved_Journey_Amount__c) from Journey__c where ownerId =: CurrentUserId AND Approval_Status__c IN ('Approved By RM','Auto Approved') AND Outstation__c = true
                                                        AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
            joureyAmount = (Decimal)JourneyAggregateAmount[0].get('expr0');
            //    joureyAmount = 0;
        }
        else{
            joureyAmount = 0;
        }
        system.debug('######'+ joureyAmount);
        Decimal taxiAmount = (Decimal)result[0].get('expr0');
        system.debug('@@@@@'+ taxiAmount);
        if(taxiAmount == null ){
            taxiAmount = 0;
            system.debug('in loop amaount--------->'+ taxiAmount);
            system.debug('journeyAmount--------->'+ joureyAmount);
            Decimal finalAmount = taxiAmount + joureyAmount;
            return finalAmount;        
        }else{
            Decimal finalAmount = taxiAmount + joureyAmount;
            return finalAmount;  
        }
        /* if(finalAmount != 0){
return finalAmount;
}else{
finalAmount = 0;
return finalAmount;
} */
        
    }
    // Method to get total amount of expense item type Ticket Local
    @AuraEnabled
    public static Decimal GetExpenseLocal(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] result = [select SUM(Approved_Amount__c) from Expense_Item__c Where Expense_Type__c ='Local Conveyance' AND Journey__r.ownerId =: CurrentUserId
                                    AND Journey__r.Approval_Status__c IN ('Approved By RM','Auto Approved') AND Journey__r.Outstation__c = true AND 
                                    CALENDAR_YEAR(Journey__r.Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey__r.Journey_Date__c) =: Month];
        // system.debug('######'+ result);
        Decimal resultAmount = (Decimal)result[0].get('expr0');
        // system.debug('@@@@@'+ resultAmount);
        // return resultAmount;
        if(resultAmount == null){
            resultAmount = 0;
            return resultAmount;
        }else{
            return resultAmount;
        }
    }
    // Method to get total amount of expense item type Ticket Hotel
    @AuraEnabled
    public static Decimal GetExpenseHotel(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] result = [select SUM(Approved_Amount__c) from Expense_Item__c Where Expense_Type__c ='Hotel Expenses' AND Journey__r.ownerId =: CurrentUserId
                                    AND Journey__r.Approval_Status__c IN ('Approved By RM','Auto Approved') AND Journey__r.Outstation__c = true AND 
                                    CALENDAR_YEAR(Journey__r.Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey__r.Journey_Date__c) =: Month];
        // system.debug('######'+ result);
        Decimal resultAmount = (Decimal)result[0].get('expr0');
        // system.debug('@@@@@'+ resultAmount);
        //  return resultAmount;
        if(resultAmount == null){
            resultAmount = 0;
            return resultAmount;
        }else{
            return resultAmount;
        }
    }
    // Method to get total amount of expense item type Ticket Food
    @AuraEnabled
    public static Decimal GetExpenseFood(Integer Year, Integer Month , Id CurrentUserId ){
        AggregateResult[] result = [select SUM(Approved_Amount__c) from Expense_Item__c Where Expense_Type__c ='Food Expenses' AND Journey__r.ownerId =: CurrentUserId
                                    AND Journey__r.Approval_Status__c IN ('Approved By RM','Auto Approved') AND Journey__r.Outstation__c = true AND 
                                    CALENDAR_YEAR(Journey__r.Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey__r.Journey_Date__c) =: Month];
        // system.debug('######'+ result);
        Decimal resultAmount = (Decimal)result[0].get('expr0');
        // system.debug('@@@@@'+ resultAmount);
        //  return resultAmount;
        if(resultAmount == null){
            resultAmount = 0;
            return resultAmount;
        }else{
            return resultAmount;
        }
    }
    // methoc to create conveyance Invoice
    @AuraEnabled
    public static string createConveyanceInvoice(Id UserId, Integer Year, Integer Month){
        Decimal totalAmount = GetJourneyTotalApprovedAmountTeam(Year, Month, UserId);
        system.debug('!!!!!!!!!!!!'+ totalAmount);
        //  if(totalAmount <= 0 ){
        //  return 'You cannot create an invoice for total amount 0';
        //  }else{
        Integer numberOfDays = Date.daysInMonth(Year, Month);
        system.debug('NumberofDays:'+ numberOfDays);
        Date lastDateOfMonth = Date.newInstance(Year, Month, numberOfDays);
        Date firstDateofMonth = Date.newInstance(Year, Month,1);
        Datetime DtTym = Datetime.newInstance(Year,Month,1);
        String groupMonth = DtTym.format('MMM').toUppercase();
        // integer year =  Date.Today().Year();
        string s1=string.valueof(Year).right(2);
        Integer groupYear= Integer.valueof(s1);
        //   System.debug('Date:'+ lastDateOfMonth);
        //   System.debug('Date:'+ firstDateofMonth);
        
        List<Fusion_Invoice__c> InvoiceList = new List<Fusion_Invoice__c>();
        User UserDetail = [select Id, name, Supplier_Name__c,Area__c, Region__c, Supplier_Num__c, Supplier_Site_Code__c from user where id =: UserId];
        System.debug('Site Code:'+ UserDetail.Supplier_Site_Code__c);
        Integer Company = 1;
        Integer LineOfBusiness = 0;
        Integer NaturalAccount = 420302; // Expense type code provided by fusion
        Integer Department = 0;
        Integer State = 6;
        Integer Future1 = 0;
        Integer Future2 = 0;
        string integrationUserId = system.label.branchMasterUserId;
        Branch_Master__c[] branchMaster = [select id, name, Branch_Code__c,  City__c, Fusion_Branch_Id__c from Branch_Master__c where Branch_Code__c =:UserDetail.Supplier_Site_Code__c and createdbyId =: integrationUserId limit 1];
        //     system.debug('1111111111111'+ branchMaster[0]);
        
        InvoiceList = [select id,name,Supplier__c,createdDate from Fusion_Invoice__c where Supplier__c =: UserDetail.Supplier_Name__c AND Date__c = :lastDateOfMonth AND name =: UserDetail.Name+'-CONVEY-'+Month+'-'+Year];
        //  System.debug('InvoiceList:'+ InvoiceList);
        if((totalAmount == null || totalAmount == 0) && !Test.isRunningTest() ){
            return 'You cannot create an invoice for total amount 0';   
        }
        else if(InvoiceList.size() > 0){
            return 'Invoice for this user for this month is already created' ;
        }else{
            Fusion_Invoice__c Inv = new Fusion_Invoice__c();
            Inv.Name = UserDetail.Name+'-CONVEY-'+Month+'-'+Year;
            Inv.Name__c = UserDetail.Name;
            Inv.Amount__c = totalAmount;
            Inv.UserName__c = UserDetail.Name;
            Inv.Invoice_Type__c = 'Conveyance';
            Inv.Supplier__c = UserDetail.Supplier_Name__c;
            Inv.Supplier_Site__c = UserDetail.Supplier_Site_Code__c;
            Inv.Supplier_Number__c = UserDetail.Supplier_Num__c;
            Inv.Date__c = lastDateOfMonth;
            Inv.Accounting_Date__c =  lastDateOfMonth;  
            Inv.Description__c = firstDateofMonth.format()+' TO '+lastDateOfMonth.format()+' - LOCAL CONVEYANCE' ;
            Inv.Payment_Terms__c = 'Immediate';
            Inv.PaymentMethod__c = 'Electronic';
            Inv.PayGroup__c = 'TRAVELLING';
            Inv.Area__c = UserDetail.Area__c;
            Inv.Region__c = UserDetail.Region__c;
            Inv.Type__c = 'Standard';
            Inv.Invoice_Group__c = 'TRAVELLING & CONVEYANCE '+groupMonth+'-'+groupYear;
            Insert Inv;
            
            Line_and_Distribution__c Line = new Line_and_Distribution__c();
            Line.Line_Number__c = 1;
            Line.Distribution_Line_Number__c = 1;
            Line.Distribution_Amount__c = totalAmount;
            Line.Line_Amount__c = totalAmount;
            Line.Fusion_Invoice__c = Inv.Id;
            Line.Location__c = branchMaster[0].City__c;
            Line.Type__c = 'Conveyance';
            Line.Distribution_Combination__c = String.valueOf(Company).leftPad(2,'0')+'-'+String.valueOf(LineOfBusiness).leftPad(2,'0')+'-'+branchMaster[0].Fusion_Branch_Id__c+'-'+NaturalAccount+'-'+String.valueOf(Department).leftPad(2,'0')+'-'+String.valueOf(State).leftPad(2,'0')+'-'+String.valueOf(Future1).leftPad(4,'0')+'-'+String.valueOf(Future2).leftPad(2,'0');
            Insert Line;
            if(!Test.isRunningTest())
            	FusionInvoiceAPI.invoiceFromSF(Inv.Id);
            return 'Invoice Created';
        }
        //      }
    }
    
    
    // methoc to create Travel Invoice
    @AuraEnabled
    public static string createTravelInvoices(Id UserId, Integer Year, Integer Month){
        Integer numberOfDays = Date.daysInMonth(Year, Month);
        system.debug('NumberofDays:'+ numberOfDays);
        Date lastDateOfMonth = Date.newInstance(Year, Month, numberOfDays);
        Date firstDateofMonth = Date.newInstance(Year, Month,1);
        Datetime DtTym = Datetime.newInstance(Year,Month,1);
        String groupMonth = DtTym.format('MMM').toUppercase();
        // integer year =  Date.Today().Year();
        string s1=string.valueof(Year).right(2);
        Integer groupYear= Integer.valueof(s1);    
        //system.debug('############'+str);
        //   System.debug('Date:'+ lastDateOfMonth);
        //   System.debug('Date:'+ firstDateofMonth);
        Decimal totalAmount = GetJourneyTotalApprovedAmountTra(Year, Month, UserId);
        List<Fusion_Invoice__c> InvoiceList = new List<Fusion_Invoice__c>();
        User UserDetail = [select Id, name, Supplier_Name__c,Area__c, Region__c, Supplier_Num__c, Supplier_Site_Code__c from user where id =: UserId];
        //   System.debug('User:'+ UserDetail);
        Integer Company = 1;
        Integer LineOfBusiness = 0;
        Integer TicketsAir = 420201;   // Expense type code provided by fusion 
        Integer TicketsTrain = 420202;
        Integer TaxiCar = 420203; 
        Integer LocalConveyance = 420204;
        Integer HotelExpenses = 420205;
        Integer FoodExpenses = 420206;
        Integer Department = 0;
        Integer State = 6;
        Integer Future1 = 0;
        Integer Future2 = 0;
        string integrationUserId = system.label.branchMasterUserId;
        Decimal Air = GetExpenseTicketAir(Year, Month, UserId);
        Decimal Train = GetExpenseTicketTrain(Year, Month, UserId);
        Decimal taxi = GetExpenseTaxi(Year, Month, UserId);
        Decimal Local = GetExpenseLocal(Year, Month, UserId);
        Decimal Hotel = GetExpenseHotel(Year, Month, UserId);
        Decimal Food = GetExpenseFood(Year, Month, UserId);
        Branch_Master__c branchMaster = [select id, name, Branch_Code__c,City__c, Fusion_Branch_Id__c from Branch_Master__c where Branch_Code__c =:UserDetail.Supplier_Site_Code__c and createdbyId =: integrationUserId  limit 1];
        InvoiceList = [select id,name,Supplier__c,createdDate from Fusion_Invoice__c where Supplier__c =: UserDetail.Supplier_Name__c AND Date__c = :lastDateOfMonth AND name =: UserDetail.Name+'-TRAVEL-'+Month+'-'+Year];
        //  System.debug('InvoiceList:'+ InvoiceList);
        if( (totalAmount == null || totalAmount == 0 ) && !Test.isRunningTest()){
            return 'You cannot create an invoice for total amount 0';   
        }   
        else if(InvoiceList.size() > 0){
            return 'Invoice for this user for this month is already created' ;
        }else{
            Fusion_Invoice__c Inv = new Fusion_Invoice__c();
            Inv.Name = UserDetail.Name+'-TRAVEL-'+Month+'-'+Year;
            Inv.Name__c = UserDetail.Name;
            Inv.Amount__c = totalAmount;
            Inv.UserName__c = UserDetail.Name;
            Inv.Invoice_Type__c = 'Travelling';
            Inv.Supplier__c = UserDetail.Supplier_Name__c;
            Inv.Supplier_Site__c = UserDetail.Supplier_Site_Code__c;
            Inv.Supplier_Number__c = UserDetail.Supplier_Num__c;
            Inv.Date__c = lastDateOfMonth;
            Inv.Accounting_Date__c =  lastDateOfMonth;  
            Inv.Description__c = firstDateofMonth.format()+' TO '+lastDateOfMonth.format()+' - TRAVEL' ;
            Inv.Payment_Terms__c = 'Immediate';
            Inv.Area__c = UserDetail.Area__c;
            Inv.Region__c = UserDetail.Region__c;
            Inv.PayGroup__c = 'TRAVELLING';
            Inv.PaymentMethod__c = 'Electronic';
            Inv.Type__c = 'Standard';
            Inv.Invoice_Group__c = 'TRAVELLING & CONVEYANCE '+groupMonth+'-'+groupYear;
            Insert Inv;
            
            // Line and Distribution for Ticket Air value
            Line_and_Distribution__c Line1 = new Line_and_Distribution__c();
            Line1.Line_Number__c = 1;
            Line1.Distribution_Line_Number__c = 1;
            Line1.Distribution_Amount__c = Air;
            Line1.Line_Amount__c = Air;
            Line1.Fusion_Invoice__c = Inv.Id;
            Line1.Location__c = branchMaster.City__c;
            Line1.Type__c = 'Ticket - Air';
            Line1.Distribution_Combination__c = String.valueOf(Company).leftPad(2,'0')+'-'+String.valueOf(LineOfBusiness).leftPad(2,'0')+'-'+branchMaster.Fusion_Branch_Id__c+'-'+TicketsAir+'-'+String.valueOf(Department).leftPad(2,'0')+'-'+String.valueOf(State).leftPad(2,'0')+'-'+String.valueOf(Future1).leftPad(4,'0')+'-'+String.valueOf(Future2).leftPad(2,'0');
            Insert Line1;
            
            // Line and Distribution for Ticket Train value
            Line_and_Distribution__c Line2 = new Line_and_Distribution__c();
            Line2.Line_Number__c = 2;
            Line2.Distribution_Line_Number__c = 2;
            Line2.Distribution_Amount__c = Train;
            Line2.Line_Amount__c = Train;
            Line2.Fusion_Invoice__c = Inv.Id;
            Line2.Location__c = branchMaster.City__c;
            Line2.Type__c = 'Ticket - Train/Other';
            Line2.Distribution_Combination__c = String.valueOf(Company).leftPad(2,'0')+'-'+String.valueOf(LineOfBusiness).leftPad(2,'0')+'-'+branchMaster.Fusion_Branch_Id__c+'-'+TicketsTrain+'-'+String.valueOf(Department).leftPad(2,'0')+'-'+String.valueOf(State).leftPad(2,'0')+'-'+String.valueOf(Future1).leftPad(4,'0')+'-'+String.valueOf(Future2).leftPad(2,'0');
            Insert Line2;
            
            // Line and Distribution for Taxi & Car value
            Line_and_Distribution__c Line3 = new Line_and_Distribution__c();
            Line3.Line_Number__c = 3;
            Line3.Distribution_Line_Number__c = 3;
            Line3.Distribution_Amount__c = taxi;
            Line3.Line_Amount__c = taxi;
            Line3.Fusion_Invoice__c = Inv.Id;
            Line3.Location__c = branchMaster.City__c;
            Line3.Type__c = 'Taxi & Car Expense';
            Line3.Distribution_Combination__c = String.valueOf(Company).leftPad(2,'0')+'-'+String.valueOf(LineOfBusiness).leftPad(2,'0')+'-'+branchMaster.Fusion_Branch_Id__c+'-'+TaxiCar+'-'+String.valueOf(Department).leftPad(2,'0')+'-'+String.valueOf(State).leftPad(2,'0')+'-'+String.valueOf(Future1).leftPad(4,'0')+'-'+String.valueOf(Future2).leftPad(2,'0');
            Insert Line3;
            
            // Line and Distribution for LocalConveyance value
            Line_and_Distribution__c Line4 = new Line_and_Distribution__c();
            Line4.Line_Number__c = 4;
            Line4.Distribution_Line_Number__c = 4;
            Line4.Distribution_Amount__c = Local;
            Line4.Line_Amount__c = Local;
            Line4.Fusion_Invoice__c = Inv.Id;
            Line4.Location__c = branchMaster.City__c;
            Line4.Type__c = 'Local Conveyance';
            Line4.Distribution_Combination__c = String.valueOf(Company).leftPad(2,'0')+'-'+String.valueOf(LineOfBusiness).leftPad(2,'0')+'-'+branchMaster.Fusion_Branch_Id__c+'-'+LocalConveyance+'-'+String.valueOf(Department).leftPad(2,'0')+'-'+String.valueOf(State).leftPad(2,'0')+'-'+String.valueOf(Future1).leftPad(4,'0')+'-'+String.valueOf(Future2).leftPad(2,'0');
            Insert Line4;
            
            // Line and Distribution for HotelExpenses value
            Line_and_Distribution__c Line5 = new Line_and_Distribution__c();
            Line5.Line_Number__c = 5;
            Line5.Distribution_Line_Number__c = 5;
            Line5.Distribution_Amount__c = Hotel;
            Line5.Line_Amount__c = Hotel;
            Line5.Fusion_Invoice__c = Inv.Id;
            Line5.Location__c = branchMaster.City__c;
            Line5.Type__c = 'Hotel Expenses';
            Line5.Distribution_Combination__c = String.valueOf(Company).leftPad(2,'0')+'-'+String.valueOf(LineOfBusiness).leftPad(2,'0')+'-'+branchMaster.Fusion_Branch_Id__c+'-'+HotelExpenses+'-'+String.valueOf(Department).leftPad(2,'0')+'-'+String.valueOf(State).leftPad(2,'0')+'-'+String.valueOf(Future1).leftPad(4,'0')+'-'+String.valueOf(Future2).leftPad(2,'0');
            Insert Line5;
            
            // Line and Distribution for FoodExpenses value
            Line_and_Distribution__c Line6 = new Line_and_Distribution__c();
            Line6.Line_Number__c = 6;
            Line6.Distribution_Line_Number__c = 6;
            Line6.Distribution_Amount__c = Food;
            Line6.Line_Amount__c = Food;
            Line6.Fusion_Invoice__c = Inv.Id;
            Line6.Location__c = branchMaster.City__c;
            Line6.Type__c = 'Food Expenses';        
            Line6.Distribution_Combination__c = String.valueOf(Company).leftPad(2,'0')+'-'+String.valueOf(LineOfBusiness).leftPad(2,'0')+'-'+branchMaster.Fusion_Branch_Id__c+'-'+FoodExpenses+'-'+String.valueOf(Department).leftPad(2,'0')+'-'+String.valueOf(State).leftPad(2,'0')+'-'+String.valueOf(Future1).leftPad(4,'0')+'-'+String.valueOf(Future2).leftPad(2,'0');
            Insert Line6;
            if(!Test.isRunningTest())
            	FusionInvoiceAPI.invoiceFromSF(Inv.Id);
            return 'Invoice Created';
        }
    }
    //     @AuraEnabled
    //     public static Map<String, Boolean> getUser(string Region, Integer Year, Integer Month){
    //     Map<String, Boolean> userMap = new Map<String, Boolean>();
    //         List<User> userList = [select id,name, Region__c from user where  Region__c =: Region ORDER BY name ASC ];    //IsActive = true
    //        Set<Id> Userid = new set<Id>();
    //         List<Journey__c> jorList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Finance_Remark__c,
    // Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c,Approved_Final_Amount__c,Approved_Amount__c,
    // Remarks__c, Journey_Amount__c from Journey__c where Approval_Status__c IN ('Approved By RM','Auto Approved')
    // AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ];
    
    //     if(jorList.size() > 0){
    //         for(Journey__c jor : jorList){
    //             Userid.add(jor.OwnerId);
    //         }
    //     }
    //         for(User us: userList){
    //             for(Id usId : userid){
    //                 if(us.id == usId){
    //               userMap.put(us.name, false);      
    //                 }
    //             }
    //         }
    //         if(userMap.size() > 0){
    //         List<Fusion_Invoice__c> fInvoice = [select id, name,UserName__c,Date__c, Name__c from Fusion_invoice__c where CALENDAR_YEAR(Date__c) =: Year AND CALENDAR_MONTH(Date__c) =: Month ];
    //         system.debug('%%%%%%%%%%%%%%'+fInvoice);
    //             for(String target : userMap.keySet()){
    //                 for(Fusion_invoice__c fInv : fInvoice){
    //                     if(fInv.UserName__c == target){
    //                         userMap.put(target, true);
    //                     }
    //                 }    
    //             }
    //         } 
    //     return userMap;
    //    }
    @AuraEnabled
    public static map<string, integer> getInvoiceNumber (integer Year, Integer Month){
        Map<String, Integer> userMapfalse = new Map<String, Integer>();
        Map<String, Integer> userMaptrue = new Map<String, Integer>();
        Map<String, Integer> finalMap = new Map<String, Integer>();
        List<Journey__c> jorList = [select id, name,owner.name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,
                                    Manual_Expense_Amount__c,Outstation__c, Journey_KM__c,Approved_Final_Amount__c,Approved_Amount__c,
                                    Remarks__c, Journey_Amount__c from Journey__c where Approval_Status__c IN ('Approved By RM','Auto Approved')
                                    AND Outstation__c = False AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        for(Journey__c jor : jorList){
            userMapfalse.put(jor.owner.name , 1); 
        }
        List<Journey__c> jorList1 = [select id, name, ownerId,owner.name, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,
                                     Manual_Expense_Amount__c,Outstation__c, Journey_KM__c,Approved_Final_Amount__c,Approved_Amount__c,
                                     Remarks__c, Journey_Amount__c from Journey__c where Approval_Status__c IN ('Approved By RM','Auto Approved')
                                     AND Outstation__c = true AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
        for(Journey__c jor : jorList1){
            userMaptrue.put(jor.owner.name , 1); 
        }                            
        for(String Username : userMapfalse.keySet()){
            if(userMaptrue.containsKey(Username)){
                finalMap.put(Username, 2);
            }else{
                finalMap.put(Username,1);
            }
        }
        
        for(String Username1 : userMaptrue.keySet()){
            if(!FinalMap.containsKey(Username1)){
                finalMap.put(Username1,1); 
            }
        }
        
        for(String key : finalMap.KeySet()){
            system.debug('UserName:' + key);
            system.debug('NumberOfInvoice:'+ finalMap.get(key));   
        }
        return finalMap;    
    }        
    
    /*       map<string,integer> mapLocal = new map<string, integer>(); 
map<string,integer> mapOutstation = new map<string, integer>(); 
map<string, integer> overallMap = new map<string, integer>();
List<journey__c> jorLocal = [select id, name, ownerId,owner.name, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Finance_Remark__c,
Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c,Approved_Final_Amount__c,Approved_Amount__c,
Remarks__c, Journey_Amount__c from Journey__c where Approval_Status__c IN ('Approved By RM','Auto Approved')
AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month];
system.debug('+++++++++++++>'+ jorLocal);
for(journey__c jor : jorLocal){
mapLocal.put(jor.owner.name, 1);
}
system.debug('-------Local-------->'+ mapLocal);
//  return mapLocal;
List<journey__c> jorOutstation = [select id, name, ownerId,owner.name, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Finance_Remark__c,
Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c,Approved_Final_Amount__c,Approved_Amount__c,
Remarks__c, Journey_Amount__c from Journey__c where Approval_Status__c IN ('Approved By RM','Auto Approved')
AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month AND Outstation__c = true];
system.debug('+++++++++++++>'+ jorLocal);
for(journey__c jor : jorOutstation){
mapOutstation.put(jor.owner.name, 1);
}
system.debug('-------outstation-------->'+ mapOutstation);
// return mapOutstation;
for(String localId : mapLocal.keySet()){
for(string outstationId: mapOutstation.keySet()){
if(localId == outstationId){
mapLocal.put(localId, 2);  
}
}
}
system.debug('-----endResult----->'+ mapLocal);
return mapLocal;
}*/
    
    @AuraEnabled
    public static map<string, integer> getFusionInvoiceNumber (integer Year, Integer Month){
        Map<String, Integer> mapTravel = new Map<String, Integer>();
        Map<String, Integer> mapConvey = new Map<String, Integer>();
        Map<String, Integer> finalMap = new Map<String, Integer>();
        List<Fusion_Invoice__c> fInvoiceTravel = [select id, name,UserName__c,Date__c, Name__c from Fusion_invoice__c where CALENDAR_YEAR(Date__c) =: Year AND CALENDAR_MONTH(Date__c) =: Month AND name LIKE '%TRAVEL%'];
        for(Fusion_Invoice__c Inv : fInvoiceTravel){
            mapTravel.put(Inv.UserName__c , 1); 
        }
        List<Fusion_Invoice__c> fInvoiceConvey = [select id, name,UserName__c,Date__c, Name__c from Fusion_invoice__c where CALENDAR_YEAR(Date__c) =: Year AND CALENDAR_MONTH(Date__c) =: Month AND name LIKE '%CONVEY%'];
        for(Fusion_Invoice__c Inv : fInvoiceConvey){
            mapConvey.put(Inv.UserName__c , 1); 
        }                            
        for(String Username : mapTravel.keySet()){
            if(mapConvey.containsKey(Username)){
                finalMap.put(Username, 2);
            }else{
                finalMap.put(Username,1);
            }
        }
        
        for(String Username1 : mapConvey.keySet()){
            if(!FinalMap.containsKey(Username1)){
                finalMap.put(Username1,1); 
            }
        }
        
        // for(String key : finalMap.KeySet()){
        // system.debug('UserName:' + key);
        // system.debug('NumberOfInvoice:'+ finalMap.get(key));    
        // }
        return finalMap;
    }
    
    /*    
map<string,integer> mapTravel = new map<string, integer>(); 
//  map<string,integer> mapConvey = new map<string, integer>(); 
List<Fusion_Invoice__c> fInvoiceTravel = [select id, name,UserName__c,Date__c, Name__c from Fusion_invoice__c where CALENDAR_YEAR(Date__c) =: Year AND CALENDAR_MONTH(Date__c) =: Month AND name LIKE '%TRAVEL%'];
system.debug('Travel invoice List'+ fInvoiceTravel);
List<Fusion_Invoice__c> fInvoiceConvey = [select id, name,UserName__c,Date__c, Name__c from Fusion_invoice__c where CALENDAR_YEAR(Date__c) =: Year AND CALENDAR_MONTH(Date__c) =: Month AND name LIKE '%CONVEY%'];
system.debug('Travel invoice List'+ fInvoiceConvey);

system.debug('Travel size'+ fInvoiceConvey.size());
if(fInvoiceConvey.size() >= 0){
for(Fusion_Invoice__c fi : fInvoiceConvey){
system.debug('666666666666'+ fi.UserName__c);    
mapTravel.put(fi.UserName__c , 1);
}
}else if(! fInvoiceConvey.isEmpty()){
system.debug('%%%%%%%%%%%%'+ mapTravel);
for(Fusion_Invoice__c fInv : fInvoiceTravel ){
for(string finvName : mapTravel.keySet() ){
if(finv.UserName__c == finvName){
mapTravel.put(finv.UserName__c, 2);
}
}    
}
}
system.debug('------------->'+ mapTravel);
return mapTravel;
}
*/
    @AuraEnabled 
    public static Map<String, Boolean> getUser(string Region, Integer Year, Integer Month){
        map<String, integer> mapJourney = Finance_Journey_View_Controller.getInvoiceNumber(year, Month);
        system.debug('#########'+ mapJourney);
        map<String, integer> mapFusion = Finance_Journey_View_Controller.getFusionInvoiceNumber(year, Month);
        system.debug('%%%%%%%%%%%%%%'+ mapFusion);
        Map<String, Boolean> userMap = new Map<String, Boolean>();
        List<User> userList = [select id,name, Region__c from user where  Region__c =: Region ORDER BY name ASC ];
        Set<Id> Userid = new set<Id>();
        List<Journey__c> jorList = [select id, name, ownerId, Approval_Status__c, Journey_Date__c, Mode_of_transport__c,Finance_Remark__c,
                                    Final_Amount__c, Manual_Expense_Amount__c, Journey_KM__c,Approved_Final_Amount__c,Approved_Amount__c,
                                    Remarks__c, Journey_Amount__c from Journey__c where Approval_Status__c IN ('Approved By RM','Auto Approved')
                                    AND CALENDAR_YEAR(Journey_Date__c) =: Year AND CALENDAR_MONTH(Journey_Date__c) =: Month ];
        
        if(jorList.size() > 0){
            for(Journey__c jor : jorList){
                Userid.add(jor.OwnerId);
            }
        }
        for(User us: userList){
            for(Id usId : userid){
                if(us.id == usId){
                    userMap.put(us.name, false);      
                }
            }
        }
        /* for(User us : userList){
userMap.put(us.name, false);
}*/
        for(String userData : userMap.keySet()){ 
            for(String userName : mapJourney.keySet()){
                
                if(userData == userName && mapFusion!= null && mapFusion.containsKey(userName) && mapFusion.get(userName) == mapJourney.get(userName)){
                    userMap.put(userName, true); 
                    
                }
            }
        }
        system.debug('(((((((((((((('+ userMap);
        return userMap;
    }
}