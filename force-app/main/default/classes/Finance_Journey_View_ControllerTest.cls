@isTest(SeeAllData=true)
public class Finance_Journey_View_ControllerTest {
static testMethod void testMethod1() {
    Journey__c objJ = CommonDataTest.getJourney();
            insert objJ;
     
        date StartDate = date.today();
        date EndDate = date.today();
    ID CurrentUserId = UserInfo.getUserId();
   // string Username=UserInfo.getUserName();
        Integer Year = StartDate.year();
        Integer Month = StartDate.month();
    	//String User_Name=UserInfo.getUserName();
    String Region = 'Delhi';
    list<String> jorlist = Finance_Journey_View_Controller.GetRegionList();
    list<User> userList = Finance_Journey_View_Controller.GetUserList(Region);
    list<User> userList1 = Finance_Journey_View_Controller.GetUserListId();
	//string userList2 = Finance_Journey_View_Controller.GetUserId(User_name);    
    list<Journey__c> jor = Finance_Journey_View_Controller.GetJourneyList(Year, Month, CurrentUserId);
    list<Journey__c> jor1 = Finance_Journey_View_Controller.GetJourneyListTravel(Year, Month, CurrentUserId);
list<Event__c> eveList = Finance_Journey_View_Controller.GetEventList(jorlist);
    list<Expense_Item__c> expList = Finance_Journey_View_Controller.GetExList(jorlist);
   Integer totjor =  Finance_Journey_View_Controller.GetJourneyCountTeam(Year, Month, CurrentUserId);
   Decimal totjor1 =  Finance_Journey_View_Controller.GetJourneyTotalAmountTeam(Year, Month, CurrentUserId);
    Decimal totjor2 =  Finance_Journey_View_Controller.GetJourneyTotalEventTeam(Year, Month, CurrentUserId);
        Decimal totjor3 =  Finance_Journey_View_Controller.GetJourneyTotalDistanceTeam(Year, Month, CurrentUserId);
    Integer totjor4 =  Finance_Journey_View_Controller.GetJourneyCountTra(Year, Month, CurrentUserId);
   Decimal totjor5 =  Finance_Journey_View_Controller.GetJourneyTotalAmountTra(Year, Month, CurrentUserId);
    Decimal totjor6 =  Finance_Journey_View_Controller.GetJourneyTotalEventTra(Year, Month, CurrentUserId);
        Decimal totjor7 =  Finance_Journey_View_Controller.GetJourneyTotalDistanceTra(Year, Month, CurrentUserId);
    Decimal ticketair = Finance_Journey_View_Controller.GetExpenseTicketAir(Year, Month, CurrentUserId);
    Decimal ticketTrain = Finance_Journey_View_Controller.GetExpenseTicketTrain(Year, Month, CurrentUserId);
    Decimal Taxi = Finance_Journey_View_Controller.GetExpenseTaxi(Year, Month, CurrentUserId);
    Decimal Local = Finance_Journey_View_Controller.GetExpenseLocal(Year, Month, CurrentUserId);
    Decimal Hotel = Finance_Journey_View_Controller.GetExpenseHotel(Year, Month, CurrentUserId);
    Decimal Food = Finance_Journey_View_Controller.GetExpenseFood(Year, Month, CurrentUserId);
    //Journey__c jor3 = Finance_Journey_View_Controller.JourneyDetail(jor.id);
//   User testUser = CommonDataTest.getUserBdm();
// user userdetail = [Select Id, name, Supplier_Name__c, Supplier_Num__c, Supplier_Site_Code__c from user where id=:CurrentUserId];       
// system.debug('@@@@@@@@'+ testUser.Supplier_Site_Code__c);
//    System.runAs(testUser) {
//    Branch_Master__c BM =new Branch_Master__c(Name = 'DELHI-10', 
//                         Branch_Code__c = 'DLI10', 
//                                Fusion_Branch_Id__c  = 10101005
//                                         ); 
  String Invoice1 = Finance_Journey_View_Controller.createConveyanceInvoice(CurrentUserId, Year, Month);
   String Invoice2 = Finance_Journey_View_Controller.createTravelInvoices(CurrentUserId, Year, Month);
     
    map<String, Boolean> map_user= Finance_Journey_View_Controller.getUser(Region, Year, Month);
    
    
    Finance_Journey_View_Controller.GetUserId(UserInfo.getName());
    
    Finance_Journey_View_Controller.GetUserProfile(UserInfo.getUserId());
    
    Finance_Journey_View_Controller.ApproveAmmount(100,'test',objJ.Id);
    
    Finance_Journey_View_Controller.JourneyDetail(objJ.Id);
    
     
    
    }
}
// }
//