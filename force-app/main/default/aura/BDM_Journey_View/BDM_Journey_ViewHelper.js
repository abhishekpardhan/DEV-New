/**
 * Description		:		Journey View component controller Helper
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th jan, 2020
 * Release          :       25th jan, 2020
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
({
    MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
	LoadEvent : function(component, event, helper) {
var action = component.get('c.GetEventList');
        action.setParams({            
            JourneyId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
           console.log('responsevalue', responseValue);
            component.set('v.EventList', responseValue);
        });
        $A.enqueueAction(action, false);
    },
    // Method to load all the journeys of the selected month and to get total number of journey, Amount, event,distance
    LoadTableMonth1 : function(component, event, helper){
        component.set("v.OpenIf", true);             
        var StDate = component.get('v.Month');
        var result = new Date();
        var CurrentDate = $A.localizationService.formatDate(result, "YYYY-MM"); 
        
        // var arra = StDate.split('-');
        // var arr = CurrentDate.split('-');
        //  alert(StDate+" and "+CurrentDate);
        if(StDate < CurrentDate){
            component.set("v.ButtonDisable", false);
            // alert('Done');
        }else{
            component.set("v.ButtonDisable", true);
        // alert('Note Done');
        }
         // alert(arra[1]+" and "+arr[1]);
        // if(arra[1] >= arr[1]){
        //     alert("in the loop");
        //     $A.util.addClass(component.find("hideThis"), "Hide"); 
            
            
        // }
        // alert(StDate);
        var array = StDate.split('-');
        // alert (array[0]);
        // alert (array[1]);
        var Yeara = array[0];
        var Montha = array[1];
        // alert (typeof "Yeara1");
        // alert(Montha);
        
                 var action = component.get('c.GetJourneyListMonth');
                        action.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        action.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.JourneyList', responseValue);
                        });
                        $A.enqueueAction(action, false);
                     
                        var act = component.get('c.GetJourneyCount');
                        // alert('2nd method');
                        act.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalJourney', responseValue);
                        });
                        $A.enqueueAction(act, false);

                        
                        var act1 = component.get('c.GetJourneyTotalAmount');
                        // alert('2nd method');
                        act1.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act1.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalAmount', responseValue);
                        });
                        $A.enqueueAction(act1, false);

                        var act2 = component.get('c.GetJourneyTotalEvent');
                        // alert('2nd method');
                        act2.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act2.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalEvent', responseValue);
                        });
                        $A.enqueueAction(act2, false);
                    
                    var act3 = component.get('c.GetJourneyTotalDistance');
                        // alert('2nd method');
                        act3.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act3.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalDistance', responseValue);
                        });
                        $A.enqueueAction(act3, false);
        
        var act4 = component.get('c.GetJourneyTotalApprovedAmount');
                        // alert('2nd method');
                        act4.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act4.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalApprovedAmount', responseValue);
                        });
                        $A.enqueueAction(act4, false);
                    },
                    LoadTableMonthTeam : function(component, event, helper){
                    var StDate = component.get('v.Month1');
        var array = StDate.split('-');
        var Yeara = array[0];
        var Montha = array[1];
     //   alert(Yeara);
     //   alert(Montha);
             var action = component.get('c.GetJourneyListMonthTeam');
                        action.setParams({
                            Year : Yeara,
                            Month : Montha,
                          //  CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                           CurrentUserId : component.get('v.SelectedUser')  
                        });
                        action.setCallback(this, function(response){
                            var state = response.getState();
                       //     alert('State: '+ state);
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.JourneyListTeam', responseValue);
                        });
                        $A.enqueueAction(action, false);

                        var action = component.get('c.GetJourneyListMonthTeamApproved');
                        action.setParams({
                            Year : Yeara,
                            Month : Montha,
                          //  CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                           CurrentUserId : component.get('v.SelectedUser')  
                        });
                        action.setCallback(this, function(response){
                            var state = response.getState();
                       //     alert('State: '+ state);
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.JourneyListApproved', responseValue);
                        });
                        $A.enqueueAction(action, false);

                        var action = component.get('c.GetJourneyListMonthTeamRejected');
                        action.setParams({
                            Year : Yeara,
                            Month : Montha,
                          //  CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                           CurrentUserId : component.get('v.SelectedUser')  
                        });
                        action.setCallback(this, function(response){
                            var state = response.getState();
                       //     alert('State: '+ state);
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.JourneyListRejected', responseValue);
                        });
                        $A.enqueueAction(action, false);
                        
                      var act = component.get('c.GetJourneyCountTeam');   
                        // alert('2nd method');
                        act.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalJourneyTeam', responseValue);
                        });
                        $A.enqueueAction(act, false);

                        
                        var act1 = component.get('c.GetJourneyTotalAmountTeam');
                        // alert('2nd method');
                        act1.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act1.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalAmountTeam', responseValue);
                        });
                        $A.enqueueAction(act1, false);

                        var act2 = component.get('c.GetJourneyTotalEventTeam');
                        // alert('2nd method');
                        act2.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act2.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalEventTeam', responseValue);
                        });
                        $A.enqueueAction(act2, false);
                    
                    var act3 = component.get('c.GetJourneyTotalDistanceTeam');
                        // alert('2nd method');
                        act3.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act3.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalDistanceTeam', responseValue);
                        });
                        $A.enqueueAction(act3, false);  

                        var act4 = component.get('c.GetUserData');
                        // alert('2nd method');
                        act4.setParams({
                            userId : component.get('v.SelectedUser')
                        });
                        act4.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.SelectedUserProfile', responseValue);
                        });
                        $A.enqueueAction(act4, false);
                        
                        var act5 = component.get('c.GetJourneyTotalApprovedAmountTeam');
                        // alert('2nd method');
                        act5.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act5.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalApprovedAmountTeam', responseValue);
                        });
                        $A.enqueueAction(act5, false);  
                        
                    },
                    
})