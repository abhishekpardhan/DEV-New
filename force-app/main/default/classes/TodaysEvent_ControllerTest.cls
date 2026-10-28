/**
 * Description		:		Test class to test Todays Event component controller
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th jan, 2020
 * Release          :       25th jan, 2020
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 * Code Coverage    :       77%
 **/
@isTest
public class TodaysEvent_ControllerTest {
    static testMethod void testMethod1() {
        ID CurrentUserId = UserInfo.getUserId();
        list<Event__c> EveList = TodaysEvent_Controller.GetEventList(CurrentUserId);
    }
}