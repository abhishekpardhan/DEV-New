/**
* Description		:	   Test class for class:JourneyDeviceNativeId.
* Updated By       :       Raghav, IBM
* Created Date     :       7, feb, 2024
* Release          :       
* Last Modified on :       13, feb, 2024
* Jira Ticket      :       https://safexpress.atlassian.net/browse/SAC-431
**/
@IsTest
private class JourneyDeviceNativeIdTest {
    @IsTest static void getDeviceNativeIdTest (){
        Id userId =UserInfo.getUserId();
        Assert.isNull(JourneyDeviceNativeId.getDeviceNativeId(userId));
        
    }
}