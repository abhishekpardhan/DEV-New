/**
 * Description		:		Todays Event component controller
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th jan, 2020
 * Release          :       25th jan, 2020
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
({
	doInit : function(component, event, helper) {
		var userId = $A.get("$SObjectType.CurrentUser.Id");
		var action = component.get('c.GetEventList');
		action.setParams({
			CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
		});
		action.setCallback(this, function(response){
			var responseValue = response.getReturnValue();
		 // console.log('responsevalue', responseValue);
			component.set('v.EventList', responseValue);
		});
		$A.enqueueAction(action, false);
	},

	detailPage: function(component, event, helper){
        var Identity = event.currentTarget.name;
    //  alert (Identity);
        var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": Identity
    });
    navEvt.fire(); 
   },

   gotoList : function (component, event, helper) {
    var action = component.get("c.getListViews");
    action.setCallback(this, function(response){
        var state = response.getState();
        if (state === "SUCCESS") {
            var listviews = response.getReturnValue();
            var navEvent = $A.get("e.force:navigateToList");
            navEvent.setParams({
                "listViewId": '00B7F00000DuoTjUAJ',
                "listViewName": null,
                "scope": "Event__c"
            });
            navEvent.fire();
        }
    });
    $A.enqueueAction(action);
}

})