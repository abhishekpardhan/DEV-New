/**
 * Description		:		Test class to test Journey view component controller class
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th jan, 2020
 * Release          :       25th jan, 2020
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 * Code Coverage    :       80%
 **/
@isTest
public class BDM_Journey_View_ControllerTest {
    static testMethod void testMethod1() {
        date StartDate = date.today();
        date EndDate = date.today();
        ID CurrentUserId = UserInfo.getUserId();
        Integer Year = 2019;
        Integer Month = 10;
        Integer pageNumber = 1;
        Integer pageSize = 1;
        Integer day = 1;
        list<Journey__c> jorlist1 = BDM_Journey_View_Controller.GetJourneyListMonth(Year, Month, CurrentUserId);
        Integer JorCount = BDM_Journey_View_Controller.GetJourneyCount(Year, Month, CurrentUserId);
        Decimal TotalAmount = BDM_Journey_View_Controller.GetJourneyTotalAmount(Year, Month, CurrentUserId);
        Decimal TotalEvent = BDM_Journey_View_Controller.GetJourneyTotalEvent(Year, Month, CurrentUserId);
        Decimal TotalDistance = BDM_Journey_View_Controller.GetJourneyTotalDistance(Year, Month, CurrentUserId);
        List<User> UserList = BDM_Journey_View_Controller.getallusers(CurrentUserId);
        Integer UserNumber = BDM_Journey_View_Controller.getusersNumber(CurrentUserId);
        list<journey__c> jorlist2 = BDM_Journey_View_Controller.GetJourneyListMonthTeam(pageNumber,pageSize,Year, Month,day, CurrentUserId);
        list<journey__c> jorlist3 = BDM_Journey_View_Controller.GetJourneyListMonthTeamApproved(pageNumber,pageSize,Year, Month,day, CurrentUserId);
        list<journey__c> jorlist4 = BDM_Journey_View_Controller.GetJourneyListMonthTeamRejected(pageNumber,pageSize,Year, Month,day, CurrentUserId);
        Integer jorlist5 = BDM_Journey_View_Controller.GetJourneyCountTeam(Year, Month,day, CurrentUserId);
        Decimal jorlist6 = BDM_Journey_View_Controller.GetJourneyTotalAmountTeam(Year, Month,day, CurrentUserId);
        Decimal jorlist7 = BDM_Journey_View_Controller.GetJourneyTotalEventTeam(Year, Month,day, CurrentUserId); 
        Decimal jorlist8 = BDM_Journey_View_Controller.GetJourneyTotalDistanceTeam(Year, Month,day, CurrentUserId);         
        list<journey__c> jorlist9 = BDM_Journey_View_Controller.GetJourneyListMonthTeamToBeSubmitted(pageNumber,pageSize,Year, Month,day, CurrentUserId);
        list<journey__c> jorlist10 = BDM_Journey_View_Controller.GetJourneyListMonthTeamNotToBeClaimed(pageNumber,pageSize,Year, Month,day, CurrentUserId);
        Decimal jorlist11 = BDM_Journey_View_Controller.GetJourneyTotalApprovedAmountTeam(Year, Month,day, CurrentUserId);         
        list<Journey__c> jorlist16 = BDM_Journey_View_Controller.GetJourneyListToApprove(Year, Month, CurrentUserId);
        list<Journey__c> jorlist12 = BDM_Journey_View_Controller.GetJourneyListApproved(Year, Month, CurrentUserId);
        list<Journey__c> jorlist13 = BDM_Journey_View_Controller.GetJourneyListRejected(Year, Month, CurrentUserId);
        list<Journey__c> jorlist14 = BDM_Journey_View_Controller.GetJourneyListToBeSubmitted(Year, Month, CurrentUserId);
        list<Journey__c> jorlist15 = BDM_Journey_View_Controller.GetJourneyListNotToBeClaimed(Year, Month, CurrentUserId);
        Decimal jorlist17 = BDM_Journey_View_Controller.GetJourneyTotalApprovedAmount(Year, Month, CurrentUserId);
        BDM_Journey_View_Controller.GetJourneyListMonthTeamApprovedCount(Year, Month,day, CurrentUserId);
        BDM_Journey_View_Controller.GetJourneyListMonthTeamRejectedCount(Year, Month,day, CurrentUserId);
        BDM_Journey_View_Controller.GetJourneyListMonthTeamToBeSubmittedCount(Year, Month,day, CurrentUserId);
        BDM_Journey_View_Controller.GetJourneyListMonthTeamNotToBeClaimedCount(Year, Month,day, CurrentUserId);
        BDM_Journey_View_Controller.GetJourneyListMonthTeamNew( pageNumber,  pageSize, Year,  Month,  currentUserId);
        BDM_Journey_View_Controller.GetJourneyListMonthTeamCount(Year, Month,day, CurrentUserId);
        //BDM_Journey_View_Controller.GetUserData(CurrentUserId);
        
        List<Journey__c> jor = new List<Journey__c>();
        jor = [Select id, name from Journey__c where ownerid =: CurrentUserId ];
        list<String> IdList = new list<String>();
        for(Journey__c jur : jor){
            Idlist.add(jur.id);
        }
        List<Event__c> EventList = BDM_Journey_View_Controller.GetEventList(IdList);
        list<Expense_Item__c> ExpenseList = BDM_Journey_View_Controller.GetExList(IdList);
       // Journey__c jor1 = CommonDataTest.getJourney();
       // jor1.Approval_Status__c = 'Not Submitted for Approval';
       // insert jor1;
        Journey__c objJ = new Journey__c();
        objJ.Journey_Date__c    = System.TODAY()+1;
        objJ.CheckIn_Date__c = SYstem.now() +1;
        objJ.CheckIn_Location__c = '28.4595,77.0266';
       //  objJ.CheckOut_Date__c = SYstem.now() +1;
       //  objJ.CheckOut_Location__c = '28.4595,77.0266';
        objJ.Mode_of_transport__c = 'Public';
        objJ.Approval_Status__c = 'Not Submitted for Approval';
        Insert objJ;
        BDM_Journey_View_Controller.GetMapData1(objJ.Id);

       // list<Journey__c> getjourney = new list<Journey__c>();
       // getjourney.add(jor1);
      //  Event__c Even = CommonDataTest.getEvent();
      //  Even.Journey__c = jor1.Id;
      //  insert Even;    
       
        Event__c objEve = new Event__c();
        objEve.Start__c = System.now()+1;
        objEve.End__c = System.now()+1;
        objEve.CheckIn_Date__c = System.now()+1;
        objEve.CheckIn_Location__c = '24.4089,77.3178';
        objEve.CheckOut_Date__c = System.now()+1 ; 
        objEve.CheckOut_Location__c = '28.63,77.25';
        objEve.Is_Claim__c = false;
        objEve.Journey__c = objJ.Id;
        objEve.Activity__c = 'Others';
        objEve.If_Others_Please_Specify__c = 'Test';
        Insert objEve;
        objJ.CheckOut_Date__c = SYstem.now() +1;
         objJ.CheckOut_Location__c = '28.4595,77.0266';
        update objJ;
        /*
Journey__c objJ = new Journey__c();
        objJ.Journey_Date__c    = System.TODAY()+1;
        objJ.CheckIn_Date__c = SYstem.now() +1;
        objJ.CheckIn_Location__c = '28.4595,77.0266';
        // objJ.CheckOut_Date__c = SYstem.now() +1;
        // objJ.CheckOut_Location__c = '28.4595,77.0266';
        objJ.Mode_of_transport__c = 'Public';
        Insert objJ;
        
       // list<Journey__c> getjourney = new list<Journey__c>();
       // getjourney.add(jor1);
      //  Event__c Even = CommonDataTest.getEvent();
      //  Even.Journey__c = jor1.Id;
      //  insert Even;    
       
        Event__c objEve = new Event__c();
        objEve.Start__c = System.now()+1;
        objEve.End__c = System.now()+1;
        objEve.CheckIn_Date__c = System.now()+1;
        objEve.CheckIn_Location__c = '24.4089,77.3178';
       // objEve.CheckOut_Date__c = System.now()+1 ; 
       // objEve.CheckOut_Location__c = '28.63,77.25';
        objEve.Is_Claim__c = false;
        objEve.Journey__c = objJ.Id;
        Insert objEve;

*/
        list<BDM_Journey_View_Controller.Address> AddressList = BDM_Journey_View_Controller.GetMapData(objJ.Id);
        
        list<String> stringlist = BDM_Journey_View_Controller.GetExpeseType();
        String profileName = BDM_Journey_View_Controller.getCurrentUserProfileName();
      //  String submitApproval = BDM_Journey_View_Controller.submitForApprovalSingle(objJ.Id);
        String ResultReturn = BDM_Journey_View_Controller.approveJourney(CurrentUserId,objJ.id);
		String ResultReturn1 = BDM_Journey_View_Controller.rejectJourney(CurrentUserId,objJ.id,'Testing');
        BDM_Journey_View_Controller.updateJourney(objJ.id,  true,  'auditorRemarks');
            }
   
}